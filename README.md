# labkit

Agentic patterns I find handy and reliable — optimized for Claude Code, with adapters for Windsurf, Cursor, and GitHub Copilot.

## What's included

### Claude Code (`.claude/`)
Full agentic tooling — slash commands, skills, and recommended settings.

**Commands** (`.claude/commands/`):
| Command | Description |
|---|---|
| `/commit` | Conventional commit from staged changes |
| `/create-pr` | PR with structured summary via `gh` |
| `/spawn <branch> [task]` | Create worktree + iTerm2 pane + launch agent |
| `/focus <branch>` | Focus the iTerm2 pane for a branch |
| `/worktrees` | List all worktrees + sessions side-by-side |
| `/teardown <branch>` | Close iTerm2 pane + remove worktree |
| `/research <topic>` | Parallel codebase + web research → plan file |

**Skills** (`.claude/skills/`):
- `playwright-cli` — browser automation for visual verification
- `it2` — iTerm2 control for multi-pane agent orchestration

**Settings** (`.claude/settings.json`):
- Enables `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`
- Pre-approves `wt`, `it2`, `playwright-cli`, core git, and `gh` commands

### Windsurf (`.windsurf/rules/`)
Three rule files covering agentic workflow, commit conventions, and PR format.

### Cursor (`.cursor/rules/`)
Same content as Windsurf rules, in `.mdc` format with frontmatter.

### GitHub Copilot (`.github/copilot-instructions.md`)
Single instructions file combining all three rule areas.

## Install

Run from inside your target project, or pass a path:

```bash
# interactive
/path/to/labkit/install.sh

# specific tool(s)
/path/to/labkit/install.sh --claude
/path/to/labkit/install.sh --windsurf --cursor
/path/to/labkit/install.sh --all

# into a specific project directory
/path/to/labkit/install.sh /path/to/my-project --claude

# overwrite existing files
/path/to/labkit/install.sh --claude --force
```

Claude settings are **merged** (not overwritten) if `.claude/settings.json` already exists. Requires `jq` for automatic merging; otherwise you'll get a manual-merge prompt.

## Hydration

Skills that depend on external tooling ship with hydration scripts. After installing, run:

```bash
# install all external dependencies
/path/to/labkit/scripts/hydrate.sh

# single skill only
/path/to/labkit/scripts/hydrate.sh playwright-cli

# preview what would run
/path/to/labkit/scripts/hydrate.sh --dry-run
```

Each skill's `hydrate.sh` is idempotent — safe to run multiple times.

## Dependencies

The `spawn`, `focus`, `worktrees`, and `teardown` commands require:

- [`wt`](https://github.com/nicholasgasior/wt) — git worktree manager CLI
- [`it2`](https://iterm2.com/documentation-scripting-fundamentals.html) — iTerm2 CLI control

The `playwright-cli` skill requires:

```bash
npm install -g playwright-cli
```
