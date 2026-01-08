#!/usr/bin/env sh
set -eu

# Determine the two commits to compare:
# - In GitLab MR pipelines: CI_MERGE_REQUEST_DIFF_BASE_SHA vs CI_COMMIT_SHA
# - Otherwise: CI_COMMIT_BEFORE_SHA vs CI_COMMIT_SHA
# - Local fallback: HEAD~1 vs HEAD
BASE_SHA="${CI_MERGE_REQUEST_DIFF_BASE_SHA:-${CI_COMMIT_BEFORE_SHA:-}}"
HEAD_SHA="${CI_COMMIT_SHA:-}"

[ -n "$HEAD_SHA" ] || HEAD_SHA="$(git rev-parse HEAD)"
[ -n "$BASE_SHA" ] || BASE_SHA="$(git rev-parse HEAD~1)"

# Extract the first version token from a file content.
# Accepts:
#   Version: V1.3.4
#   version:V1.3.4
#   Version:    1.3.4
extract_version() {
  awk '
    match($0,/^[Vv]ersion:[[:space:]]*([^[:space:]]+)/,a) { print a[1]; exit }
  '
}

# List changed markdown files between base and head
CHANGED_DOCS="$(git diff --name-only "$BASE_SHA" "$HEAD_SHA" -- | grep -E '\.md$' || true)"
[ -z "$CHANGED_DOCS" ] && exit 0

for doc in $CHANGED_DOCS; do
  # If file was deleted in HEAD, skip it
  [ -f "$doc" ] || continue

  # Check if file existed in BASE (git cat-file is faster/cleaner than git show for existence test)
  if ! git cat-file -e "$BASE_SHA:$doc" 2>/dev/null; then
    # New file -> must have Version:
    NEW_VER="$(extract_version < "$doc" || true)"
    if [ -z "$NEW_VER" ]; then
      echo "ERROR: Missing Version field in new file: $doc"
      exit 1
    fi
    continue
  fi

  OLD_VER="$(git show "$BASE_SHA:$doc" | extract_version || true)"
  NEW_VER="$(extract_version < "$doc" || true)"

  if [ -z "$OLD_VER" ] || [ -z "$NEW_VER" ]; then
    echo "ERROR: Missing Version field in: $doc"
    exit 1
  fi

  if [ "$OLD_VER" = "$NEW_VER" ]; then
    echo "ERROR: Version not updated in: $doc (still $NEW_VER)"
    exit 1
  fi
done
