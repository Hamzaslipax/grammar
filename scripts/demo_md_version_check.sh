#!/usr/bin/env sh
set -eu

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

git -C "$tmp_dir" init -q
git -C "$tmp_dir" config user.email "ci@example.com"
git -C "$tmp_dir" config user.name "CI Demo"
mkdir -p "$tmp_dir/scripts"
cp "$(pwd)/scripts/check_md_versions.sh" "$tmp_dir/scripts/check_md_versions.sh"
chmod +x "$tmp_dir/scripts/check_md_versions.sh"

cat <<'DOC' > "$tmp_dir/assessment.md"
# Assessment

Version: 1.0.0
DOC

git -C "$tmp_dir" add assessment.md scripts/check_md_versions.sh
git -C "$tmp_dir" commit -m "Add assessment" -q
base_sha="$(git -C "$tmp_dir" rev-parse HEAD)"

cat <<'DOC' > "$tmp_dir/assessment.md"
# Assessment

Version: 1.0.0

New line without bump.
DOC

git -C "$tmp_dir" add assessment.md
git -C "$tmp_dir" commit -m "Update assessment without bump" -q
head_sha="$(git -C "$tmp_dir" rev-parse HEAD)"

echo "Running expected failure check (no version bump)..."
if (cd "$tmp_dir" && CI_COMMIT_BEFORE_SHA="$base_sha" CI_COMMIT_SHA="$head_sha" \
  ./scripts/check_md_versions.sh); then
  echo "ERROR: Expected failure but check passed."
  exit 1
else
  echo "Expected failure observed."
fi

cat <<'DOC' > "$tmp_dir/assessment.md"
# Assessment

Version: 1.0.1

New line with bump.
DOC

git -C "$tmp_dir" add assessment.md
git -C "$tmp_dir" commit -m "Update assessment with bump" -q
new_head_sha="$(git -C "$tmp_dir" rev-parse HEAD)"

echo "Running expected success check (version bumped)..."
(cd "$tmp_dir" && CI_COMMIT_BEFORE_SHA="$head_sha" CI_COMMIT_SHA="$new_head_sha" \
  ./scripts/check_md_versions.sh)

echo "Demo complete."
