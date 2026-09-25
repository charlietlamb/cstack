#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
agents_skills="${CSTACK_AGENTS_SKILLS:-$HOME/.agents/skills}"
claude_skills="${CSTACK_CLAUDE_SKILLS:-$HOME/.claude/skills}"
claude_agents="${CSTACK_CLAUDE_AGENTS:-$HOME/.claude/agents}"

skill_dirs() {
  find "$repo_dir" -name SKILL.md \
    -not -path "$repo_dir/.git/*" \
    -not -path "$repo_dir/scripts/*" \
    -not -path "*/upstream/*" \
    -exec dirname {} \; | sort | awk '
      { for (i = 1; i <= n; i++) if (index($0, roots[i] "/") == 1) next; roots[++n] = $0; print }'
}

agent_files() {
  find "$repo_dir" -mindepth 3 -maxdepth 3 -path "*/agents/*.md" -not -path "$repo_dir/.git/*" | while read -r file; do
    [ -f "$(dirname "$(dirname "$file")")/SKILL.md" ] || echo "$file"
  done | sort
}

link() {
  local source="$1" target="$2"
  if [ -L "$target" ]; then
    case "$(readlink "$target")" in
      "$repo_dir"/*) ln -sfn "$source" "$target"; return 0 ;;
      *) echo "skip  $target (symlink owned by something else)"; return 1 ;;
    esac
  fi
  if [ -e "$target" ]; then
    echo "skip  $target (exists and is not a symlink)"
    return 1
  fi
  ln -s "$source" "$target"
}

prune() {
  local dir="$1"
  for entry in "$dir"/*; do
    [ -L "$entry" ] || continue
    case "$(readlink "$entry")" in
      "$repo_dir"/*) [ -e "$entry" ] || { rm "$entry"; echo "prune $entry"; } ;;
    esac
  done
}

duplicates="$(skill_dirs | xargs -n1 basename | sort | uniq -d)"
if [ -n "$duplicates" ]; then
  echo "duplicate skill names, rename before installing:" >&2
  echo "$duplicates" >&2
  exit 1
fi

mkdir -p "$agents_skills" "$claude_skills" "$claude_agents"

skills=0
while read -r dir; do
  name="$(basename "$dir")"
  link "$dir" "$agents_skills/$name" && link "$dir" "$claude_skills/$name" && skills=$((skills + 1))
done < <(skill_dirs)

agents=0
while read -r file; do
  link "$file" "$claude_agents/$(basename "$file")" && agents=$((agents + 1))
done < <(agent_files)

prune "$agents_skills"
prune "$claude_skills"
prune "$claude_agents"

chmod +x "$repo_dir/pstack/poteto/scripts/pstack-panel"
echo "linked $skills skills into $agents_skills and $claude_skills, $agents agents into $claude_agents"
