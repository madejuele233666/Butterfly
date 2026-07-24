#!/usr/bin/env bash
set -euo pipefail

readonly EXPECTED_BASELINE="a10a9787fd4fdc51c9426ead83ff063136015fb2"

mode="${1:-sync}"
remote="${NOTEA_SYNC_REMOTE:-mirror}"
branch="${2:-$(git branch --show-current)}"

case "$mode" in
  pull|push|sync) ;;
  *)
    echo "Usage: $0 [pull|push|sync] [branch]" >&2
    exit 2
    ;;
esac

if [[ -z "$branch" ]]; then
  echo "Refusing to sync a detached HEAD." >&2
  exit 1
fi

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

if ! git remote get-url "$remote" >/dev/null 2>&1; then
  echo "Git remote '$remote' is not configured." >&2
  exit 1
fi

baseline="$(git rev-parse refs/heads/baseline/v2.5.3-pristine 2>/dev/null || true)"
if [[ "$baseline" != "$EXPECTED_BASELINE" ]]; then
  echo "Baseline ref mismatch: expected $EXPECTED_BASELINE, got ${baseline:-missing}." >&2
  exit 1
fi

if [[ -n "$(git status --porcelain --untracked-files=normal)" ]]; then
  echo "Working tree is not clean. Commit or intentionally discard changes before syncing." >&2
  git status --short >&2
  exit 1
fi

git fetch "$remote" --prune

remote_ref="refs/remotes/$remote/$branch"
if [[ "$mode" == "pull" || "$mode" == "sync" ]]; then
  if git show-ref --verify --quiet "$remote_ref"; then
    git merge --ff-only "$remote_ref"
  elif [[ "$mode" == "pull" ]]; then
    echo "Remote branch '$remote/$branch' does not exist." >&2
    exit 1
  fi
fi

if [[ "$mode" == "push" || "$mode" == "sync" ]]; then
  git push "$remote" "HEAD:refs/heads/$branch"
fi

printf 'Synced %s at %s via %s (%s).\n' "$branch" "$(git rev-parse --short=12 HEAD)" "$remote" "$mode"

