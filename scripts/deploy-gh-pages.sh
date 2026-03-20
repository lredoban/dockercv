#!/usr/bin/env bash
set -euo pipefail

PUBLISH_DIR="${PUBLISH_DIR:-exported-html}"
PUBLISH_BRANCH="${PUBLISH_BRANCH:-gh-pages}"
COMMIT_MESSAGE="${COMMIT_MESSAGE:-chore: deploy gh-pages}"

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ ! -d "${repo_root}/${PUBLISH_DIR}" ]; then
	printf '%s\n' "Publish dir not found: ${PUBLISH_DIR}" >&2
	exit 1
fi

if [ -n "${GITHUB_TOKEN:-}" ] && [ -n "${GITHUB_REPOSITORY:-}" ]; then
	git -C "${repo_root}" remote set-url origin "https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
fi

if [ -n "${GITHUB_TOKEN:-}" ]; then
	git -C "${repo_root}" config user.name "${GIT_USER_NAME:-github-actions[bot]}"
	git -C "${repo_root}" config user.email "${GIT_USER_EMAIL:-github-actions[bot]@users.noreply.github.com}"
fi

temp_dir="$(mktemp -d)"
cleanup() {
	git -C "${repo_root}" worktree remove -f "${temp_dir}" >/dev/null 2>&1 || true
	rm -rf "${temp_dir}"
}
trap cleanup EXIT

if git -C "${repo_root}" show-ref --verify --quiet "refs/heads/${PUBLISH_BRANCH}"; then
	git -C "${repo_root}" worktree add -B "${PUBLISH_BRANCH}" "${temp_dir}" "${PUBLISH_BRANCH}"
elif git -C "${repo_root}" ls-remote --exit-code --heads origin "${PUBLISH_BRANCH}" >/dev/null 2>&1; then
	git -C "${repo_root}" fetch origin "${PUBLISH_BRANCH}:${PUBLISH_BRANCH}"
	git -C "${repo_root}" worktree add -B "${PUBLISH_BRANCH}" "${temp_dir}" "${PUBLISH_BRANCH}"
else
	git -C "${repo_root}" worktree add --detach "${temp_dir}"
	git -C "${temp_dir}" checkout --orphan "${PUBLISH_BRANCH}"
fi

shopt -s dotglob
for entry in "${temp_dir}"/*; do
	[ "$(basename "${entry}")" = ".git" ] && continue
	rm -rf "${entry}"
done
shopt -u dotglob

cp -a "${repo_root}/${PUBLISH_DIR}/." "${temp_dir}/"

git -C "${temp_dir}" add -A
if git -C "${temp_dir}" diff --cached --quiet; then
	printf '%s\n' "No changes to deploy."
	exit 0
fi

git -C "${temp_dir}" commit -m "${COMMIT_MESSAGE}"
git -C "${temp_dir}" push origin "${PUBLISH_BRANCH}"
