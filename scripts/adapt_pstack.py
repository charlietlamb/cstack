import re
import sys
from pathlib import Path

CURSOR_ONLY_KEYS = {"mode", "icon", "color", "reminder"}
TEXT_SUFFIXES = {".md", ".sh", ".ts", ".mjs", ".json", ".tsv", ".yaml"}

PATH_REWRITES = [
    ("~/.cursor/rules/pstack-models.mdc", "~/.agents/pstack-models.md"),
    ("~/.cursor/projects/<slug>/agent-transcripts/<uuid>/<uuid>.jsonl", "~/.claude/projects/<slug>/<uuid>.jsonl"),
    ("~/.cursor/projects/<slugified-repo-path>/agent-transcripts", "~/.claude/projects/<slugified-repo-path>"),
    ('$HOME/.cursor/projects/$slug/agent-transcripts', '$HOME/.claude/projects/$slug'),
    ("~/.cursor/projects/", "~/.claude/projects/"),
    ("~/.cursor/plugins/", "~/.agents/skills/"),
    ("~/.cursor/skills/", "~/.agents/skills/"),
    (".cursor/worktrees/", ".claude/worktrees/"),
    (".cursor/skills/", ".agents/skills/"),
    ("git show origin/main:pstack/skills/", "cat ~/.agents/skills/"),
    ("pstack/skills/", "~/.agents/skills/"),
]

BANNER = (
    "> **Claude Code (cstack):** vendored pstack skill, written for Cursor. "
    "Before acting on it, read `~/.agents/skills/poteto/references/claude-code.md` "
    "and apply its translations for tools, models, and paths. "
    "Every pstack skill lives at `~/.agents/skills/<name>/SKILL.md`.\n"
)

COMMENT_SICKO_FRONTMATTER = """---
name: comment-sicko
description: Read-only comment reviewer from pstack. Flags comments to delete and symbols to reshape (MUST KILL). Invoke through the no-comments skill, or directly with a diff or file scope.
tools: Read, Grep, Glob, Bash
model: sonnet
---
"""


def split_frontmatter(text: str) -> tuple[list[str], str]:
    match = re.match(r"^---\n(.*?)\n---\n", text, re.DOTALL)
    if not match:
        raise ValueError("missing frontmatter")
    return match.group(1).split("\n"), text[match.end():]


def adapt_frontmatter(lines: list[str], skill_name: str) -> list[str]:
    adapted = []
    skipping_block = False
    for line in lines:
        key_match = re.match(r"^([a-z_-]+):", line)
        if key_match:
            key = key_match.group(1)
            skipping_block = key in CURSOR_ONLY_KEYS
            if skipping_block:
                continue
            if key == "name":
                adapted.append(f"name: {skill_name}")
                continue
        elif skipping_block:
            continue
        adapted.append(line)
    return adapted


def rewrite_paths(text: str) -> str:
    for cursor_path, agents_path in PATH_REWRITES:
        text = text.replace(cursor_path, agents_path)
    return text


def adapt_skill_dir(skill_dir: Path) -> None:
    for path in skill_dir.rglob("*"):
        if path.is_file() and path.suffix in TEXT_SUFFIXES:
            path.write_text(rewrite_paths(path.read_text()))
    skill_file = skill_dir / "SKILL.md"
    lines, body = split_frontmatter(skill_file.read_text())
    frontmatter = adapt_frontmatter(lines, skill_dir.name)
    skill_file.write_text("---\n" + "\n".join(frontmatter) + "\n---\n\n" + BANNER + "\n" + body.lstrip("\n"))


def build_comment_sicko(pstack_dir: Path, upstream_agent: Path) -> None:
    _, body = split_frontmatter(upstream_agent.read_text())
    (pstack_dir / "agents" / "comment-sicko.md").write_text(COMMENT_SICKO_FRONTMATTER + "\n" + rewrite_paths(body.lstrip("\n")))


def main() -> None:
    pstack_dir = Path(sys.argv[1])
    upstream_agent = Path(sys.argv[2])
    for name in (pstack_dir / "upstream" / "skills.txt").read_text().split():
        adapt_skill_dir(pstack_dir / name)
    build_comment_sicko(pstack_dir, upstream_agent)


if __name__ == "__main__":
    main()
