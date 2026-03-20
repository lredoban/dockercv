#!/usr/bin/env sh
set -e

INTRO_DIR="${INTRO_DIR:-}"
if [ -n "${INTRO_DIR}" ] && [ -d "${INTRO_DIR}" ]; then
	LC_ALL=C
	for file in "${INTRO_DIR}"/*.neo; do
		[ -e "${file}" ] || continue
		if [ -f "${file}" ]; then
			splitans -f neotex -F ansi -V "${file}"
		fi
	done
fi

termfolio --config dockercv.yaml
