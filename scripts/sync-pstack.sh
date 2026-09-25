#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
pstack_dir="$repo_dir/pstack"
upstream_url="https://github.com/cursor/plugins.git"
ref="${1:-main}"
cstack_owned=(poteto agents upstream)

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

git -C "$work_dir" init -q upstream
git -C "$work_dir/upstream" remote add origin "$upstream_url"
git -C "$work_dir/upstream" fetch -q --depth 1 origin "$ref"
git -C "$work_dir/upstream" checkout -q FETCH_HEAD
sha="$(git -C "$work_dir/upstream" rev-parse HEAD)"
src="$work_dir/upstream/pstack"

manifest="$pstack_dir/upstream/skills.txt"
if [ -f "$manifest" ]; then
  while IFS= read -r name; do
    [ -n "$name" ] && rm -rf "${pstack_dir:?}/$name"
  done < "$manifest"
fi
rm -rf "$pstack_dir/upstream"
mkdir -p "$pstack_dir/upstream" "$pstack_dir/agents"

: > "$manifest"
for skill in "$src"/skills/*/; do
  name="$(basename "$skill")"
  for owned in "${cstack_owned[@]}"; do
    if [ "$name" = "$owned" ]; then
      echo "upstream ships a skill named $name, which cstack owns; refusing to overwrite" >&2
      exit 1
    fi
  done
  cp -R "$skill" "$pstack_dir/$name"
  echo "$name" >> "$manifest"
done

cp -R "$src/docs" "$src/automations" "$src/assets" "$pstack_dir/upstream/"
cp "$src/README.md" "$pstack_dir/upstream/README.md"
cp "$src/LICENSE" "$pstack_dir/LICENSE"
cp "$src/agents/comment-sicko.md" "$work_dir/comment-sicko.md"

python3 "$repo_dir/scripts/adapt_pstack.py" "$pstack_dir" "$work_dir/comment-sicko.md"

cat > "$pstack_dir/upstream/UPSTREAM" <<EOF
repo: $upstream_url
path: pstack
ref: $ref
sha: $sha
synced: $(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF

if grep -rn "\.cursor/" "$pstack_dir" --include='*.md' --include='*.sh' --include='*.ts' --include='*.mjs' \
  | grep -v "^$pstack_dir/upstream/" | grep -v "^$pstack_dir/poteto/"; then
  echo "unmapped .cursor paths remain; add a rewrite to scripts/adapt_pstack.py" >&2
  exit 1
fi

echo "synced pstack @ $sha ($(wc -l < "$manifest" | tr -d ' ') skills)"
