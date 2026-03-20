#!/usr/bin/env bash
set -euo pipefail

BUILDX_NAME="${BUILDX_NAME:-multiarch}"

if docker buildx inspect "${BUILDX_NAME}" >/dev/null 2>&1; then
	docker buildx use "${BUILDX_NAME}" >/dev/null
else
	docker buildx create --name "${BUILDX_NAME}" --driver docker-container --use >/dev/null
fi

docker buildx inspect --bootstrap >/dev/null
