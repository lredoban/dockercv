#!/usr/bin/env bash
set -euo pipefail

BUILDX_CACHE_DIR="${BUILDX_CACHE_DIR:-}"
if [ -z "${BUILDX_CACHE_DIR}" ]; then
	printf '%s\n' "BUILDX_CACHE_DIR is empty; refusing to remove." >&2
	exit 1
fi

root_dir="$(cd "$(dirname "$0")/.." && pwd -P)"
case "${BUILDX_CACHE_DIR}" in
/*) target_dir="$(realpath -m "${BUILDX_CACHE_DIR}")" ;;
*) target_dir="$(realpath -m "${root_dir}/${BUILDX_CACHE_DIR}")" ;;
esac

if [ "${target_dir}" = "/" ]; then
	printf '%s\n' "Refusing to remove '/'" >&2
	exit 1
fi

case "${target_dir}" in
"${root_dir}" | "${root_dir}/"*)
	rm -rf "${target_dir}"
	;;
*)
	printf '%s\n' "Refusing to remove outside repo: ${target_dir}" >&2
	exit 1
	;;
esac
