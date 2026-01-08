#!/usr/bin/env sh
set -eu

# Determine commits to compare
BASE_SHA="${CI_MERGE_REQUEST_DIFF_BASE_SHA:-${CI_COMMIT_BEFORE_SHA:-}}"
HEAD_SHA="${CI_COMMIT_SHA:-}"

[ -n "$HEAD_SHA" ] || HEAD_SHA="$(git rev-parse HEAD)"
[ -n "$BASE_SHA" ] || BASE_SHA="$(git rev-parse HEAD~1)"

# List changed markdown files
CHANGED_DOCS="$(git diff --name-only "$BASE_SHA" "$HEAD_SHA" -- | grep -E '\.md$' || true)"
[ -z "$CHANGED_DOCS" ] && exit 0

for doc in $CHANGED_DOCS; do
  # Skip deleted files
  [ -f "$doc" ] || continue

  # If file did not exist before, it must have a version
  if ! git cat-file -e "$BASE_SHA:$doc" 2>/dev/null; then
    NEW_VER="$(grep -m1 '^version:' "$doc" | sed 's/^version:[[:space:]]*//' || true)"
    if [ -z "$NEW_VER" ]; then
      echo "ERROR: Missing version field in new file: $doc"
      exit 1
    fi
    continue
  fi

  OLD_VER="$(git show "$BASE_SHA:$doc" | grep -m1 '^version:' | sed 's/^version:[[:space:]]*//' || true)"
  NEW_VER="$(grep -m1 '^version:' "$doc" | sed 's/^version:[[:space:]]*//' || true)"

  if [ -z "$OLD_VER" ] || [ -z "$NEW_VER" ]; then
    echo "ERROR: Missing version field in: $doc"
    exit 1
  fi

  if [ "$OLD_VER" = "$NEW_VER" ]; then
    echo "ERROR: Version not updated in: $doc (still $NEW_VER)"
    exit 1
  fi
done

