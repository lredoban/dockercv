# syntax=docker/dockerfile:1.7
ARG GO_VERSION=1.26.1

FROM --platform=$BUILDPLATFORM golang:${GO_VERSION}-alpine AS builder
ARG TARGETOS
ARG TARGETARCH
ARG GO_TOOLS=""
ARG BIT_REPO=""
ARG BIT_REF="feat/cli-fit-mode"

ENV CGO_ENABLED=0 \
  GOOS=$TARGETOS \
  GOARCH=$TARGETARCH

RUN apk add --no-cache ca-certificates git
RUN mkdir -p /out
RUN if [ -n "$GO_TOOLS" ]; then \
  unset GOBIN; \
  for tool in $GO_TOOLS; do \
  go install "$tool"; \
  done; \
  fi
RUN if [ -n "$GO_TOOLS" ]; then \
  bin_dir="$(go env GOPATH)/bin"; \
  if [ -d "${bin_dir}/${GOOS}_${GOARCH}" ]; then \
  cp -a "${bin_dir}/${GOOS}_${GOARCH}/." /out/; \
  elif [ -d "${bin_dir}" ]; then \
  cp -a "${bin_dir}/." /out/; \
  fi; \
  fi
RUN if [ -n "$BIT_REPO" ]; then \
  git clone --depth 1 --branch "$BIT_REF" "$BIT_REPO" /tmp/bit-src; \
  (cd /tmp/bit-src && go build -o /out/bit ./cmd/bit); \
  rm -rf /tmp/bit-src; \
  fi

FROM scratch AS artifacts
COPY --from=builder /out/ /

FROM alpine:3.20 AS runtime
ENV INTRO_DIR="assets/intro"

RUN apk add --no-cache ca-certificates less
COPY --from=builder /out/ /usr/local/bin/
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY assets/ /assets/
COPY dockercv.yaml dockercv.yaml
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
