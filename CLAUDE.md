# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

labkit is a reusable kit of agentic patterns for AI coding assistants. Primary target is Claude Code (full commands, skills, settings), with rule-file adapters for Windsurf, Cursor, and GitHub Copilot. There is no application code to build or test — this is a collection of config/pattern files plus an install script.

## Repository Layout

```
.claude/commands/       Slash commands (commit, create-pr, spawn, focus, worktrees, teardown, research)
.claude/skills/         Skills with reference docs (playwright-cli, it2)
.claude/settings.json  Recommended permissions + agent teams env var
.windsurf/rules/        Windsurf rule files (.md)
.cursor/rules/          Cursor rule files (.mdc with frontmatter)
.github/copilot-instructions.md  GitHub Copilot instructions
install.sh              Interactive installer — copies patterns into a target project
scripts/hydrate.sh      Orchestrator — discovers and runs all skill hydration scripts
```

## install.sh

The only executable. Copies the appropriate dotfile directories into a target project:

```bash
./install.sh [TARGET_DIR] [--claude] [--windsurf] [--cursor] [--copilot] [--all] [--force]
```

- Interactive picker when no flags are passed
- `--force` overwrites existing files; default is `--ignore-existing` via rsync
- Claude settings are **merged** (not overwritten) using `jq` when `.claude/settings.json` already exists in the target
## Pattern Parity

The Windsurf, Cursor, and Copilot files encode the same conventions as the Claude Code commands but as passive rule/instruction files (those editors don't support slash commands or skills). When updating a convention (e.g., commit format), update all four surfaces:

1. `.claude/commands/commit.md`
2. `.windsurf/rules/commit-conventions.md`
3. `.cursor/rules/commit-conventions.mdc`
4. `.github/copilot-instructions.md`

## External Dependencies

Commands assume these CLIs are available on `$PATH`:

| CLI | Used by |
|---|---|
| `wt` | spawn, teardown, worktrees |
| `it2` | spawn, focus, teardown, worktrees |
| `playwright-cli` | playwright-cli skill |
| `gh` | create-pr, research |
| `jq` | install.sh settings merge |

## Hydration

Skills that wrap external CLIs include a `hydrate.sh` script in their directory (e.g., `.claude/skills/playwright-cli/hydrate.sh`). The top-level orchestrator `scripts/hydrate.sh` discovers and runs them all. Each hydration script is idempotent, checks if the dependency is already installed, and exits non-zero on failure.

When adding a new skill that depends on external tooling, create a `hydrate.sh` in the skill's directory following the same pattern.

## Conventions

- Commit format: `<type>: <description>` — imperative mood, under 72 chars, no AI attribution trailers
- No AI-generated Co-Authored-By or tool attribution in commits or PRs
- Prefer editing existing pattern files over creating new ones
- Keep commands generic/project-agnostic — project-specific commands belong in the target repo
