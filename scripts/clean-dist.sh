#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${OUT_DIR:-}"
if [ -z "${OUT_DIR}" ]; then
	printf '%s\n' "OUT_DIR is empty; refusing to remove." >&2
	exit 1
fi

root_dir="$(cd "$(dirname "$0")/.." && pwd -P)"
case "${OUT_DIR}" in
/*) target_dir="$(realpath -m "${OUT_DIR}")" ;;
*) target_dir="$(realpath -m "${root_dir}/${OUT_DIR}")" ;;
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
