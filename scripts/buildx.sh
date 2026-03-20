#!/usr/bin/env bash
set -euo pipefail

: "${GO_TOOLS:?Set GO_TOOLS to a space-separated list like 'github.com/foo/bar@v1.2.3'}"

MODE="${MODE:-image}"
IMAGE_TAG="${IMAGE_TAG:-badele/dockercv:latest}"
IMAGE_TAGS="${IMAGE_TAGS:-${IMAGE_TAG}}"
IMAGE_LABELS="${IMAGE_LABELS:-}"
OUT_DIR="${OUT_DIR:-dist}"
IMAGE_PLATFORMS="${IMAGE_PLATFORMS:-linux/amd64,linux/arm64}"
BIN_PLATFORMS="${BIN_PLATFORMS:-darwin/amd64,darwin/arm64,linux/amd64,linux/arm64}"
GO_VERSION="${GO_VERSION:-1.26.1}"
BIT_REPO="${BIT_REPO:-}"
BIT_REF="${BIT_REF:-feat/cli-fit-mode}"
BUILDX_CACHE_DIR="${BUILDX_CACHE_DIR:-.buildx-cache}"
LOCAL_PLATFORM="${LOCAL_PLATFORM:-$(docker version --format '{{.Server.Os}}/{{.Server.Arch}}')}"

mkdir -p "${BUILDX_CACHE_DIR}"

tag_args=()
if [ -n "${IMAGE_TAGS}" ]; then
	while IFS= read -r tag; do
		[ -n "${tag}" ] && tag_args+=(-t "${tag}")
	done <<<"${IMAGE_TAGS}"
fi

label_args=()
if [ -n "${IMAGE_LABELS}" ]; then
	while IFS= read -r label; do
		[ -n "${label}" ] && label_args+=(--label "${label}")
	done <<<"${IMAGE_LABELS}"
fi

case "${MODE}" in
local-image)
	cmd=(
		docker buildx build
		--platform "${LOCAL_PLATFORM}"
		--build-arg "GO_VERSION=${GO_VERSION}"
		--build-arg "GO_TOOLS=${GO_TOOLS}"
		--build-arg "BIT_REPO=${BIT_REPO}"
		--build-arg "BIT_REF=${BIT_REF}"
		--load
		"${label_args[@]}"
		"${tag_args[@]}"
		.
	)
	;;
image)
	cmd=(
		docker buildx build
		--platform "${IMAGE_PLATFORMS}"
		--cache-from "type=local,src=${BUILDX_CACHE_DIR}"
		--cache-to "type=local,dest=${BUILDX_CACHE_DIR},mode=max"
		--build-arg "GO_VERSION=${GO_VERSION}"
		--build-arg "GO_TOOLS=${GO_TOOLS}"
		--build-arg "BIT_REPO=${BIT_REPO}"
		--build-arg "BIT_REF=${BIT_REF}"
		"${label_args[@]}"
		"${tag_args[@]}"
		.
	)
	;;
push)
	cmd=(
		docker buildx build
		--platform "${IMAGE_PLATFORMS}"
		--cache-from "type=local,src=${BUILDX_CACHE_DIR}"
		--cache-to "type=local,dest=${BUILDX_CACHE_DIR},mode=max"
		--build-arg "GO_VERSION=${GO_VERSION}"
		--build-arg "GO_TOOLS=${GO_TOOLS}"
		--build-arg "BIT_REPO=${BIT_REPO}"
		--build-arg "BIT_REF=${BIT_REF}"
		--push
		"${label_args[@]}"
		"${tag_args[@]}"
		.
	)
	;;
bins)
	cmd=(
		docker buildx build
		--target artifacts
		--platform "${BIN_PLATFORMS}"
		--cache-from "type=local,src=${BUILDX_CACHE_DIR}"
		--cache-to "type=local,dest=${BUILDX_CACHE_DIR},mode=max"
		--build-arg "GO_VERSION=${GO_VERSION}"
		--build-arg "GO_TOOLS=${GO_TOOLS}"
		--build-arg "BIT_REPO=${BIT_REPO}"
		--build-arg "BIT_REF=${BIT_REF}"
		--output "type=local,dest=${OUT_DIR}"
		"${label_args[@]}"
		"${tag_args[@]}"
		.
	)
	;;
*)
	printf '%s\n' "Unknown MODE=${MODE}. Expected build-local-image, image, push, or bins." >&2
	exit 1
	;;
esac

"${cmd[@]}"
