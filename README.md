# labkit

**Build your own toolkit** of agentic patterns for AI coding assistants.

Cherry-pick exactly what you need — commands, skills, and rules for Claude Code, Cursor, Windsurf, and GitHub Copilot. Pull from GitHub, configure once, sync anytime.

## What's included

### Platform Support

| Feature | Claude | Cursor | Windsurf | Copilot |
|---------|--------|--------|----------|---------|
| **Skills** (`SKILL.md` dirs) | `.claude/skills/` | `.cursor/skills/` | `.windsurf/skills/` | `.github/skills/` |
| **Commands** (slash) | `.claude/commands/*.md` | `.cursor/commands/*.md` | — | — |
| **Rules** (passive context) | — | `.cursor/rules/*.mdc` | `.windsurf/rules/*.md` | `.github/copilot-instructions.md` |

**Skills strategy:** All platforms support the SKILL.md standard. labkit installs skills to each platform's native directory for maximum compatibility and zero configuration.

### Available Patterns

**Commands** (Claude, Cursor):
| Command | Description |
|---|---|
| `/commit` | Conventional commit from staged changes |
| `/create-pr` | PR with structured summary via `gh` |
| `/spawn <branch> [task]` | Create worktree + iTerm2 pane + launch agent |
| `/focus <branch>` | Focus the iTerm2 pane for a branch |
| `/worktrees` | List all worktrees + sessions side-by-side |
| `/teardown <branch>` | Close iTerm2 pane + remove worktree |
| `/research <topic>` | Parallel codebase + web research → plan file |

**Skills** (all platforms via `.claude/skills/`):
- `playwright-cli` — browser automation for testing, screenshots, data extraction
- `it2` — iTerm2 control for multi-pane agent orchestration

**Rules** (Cursor, Windsurf, Copilot):
- `commit-conventions` — Conventional commit format and patterns
- `agentic-workflow` — Multi-agent orchestration patterns
- `pr-workflow` — PR creation and review conventions

**Settings** (`.claude/settings.json`):
- Enables `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`
- Pre-approves `wt`, `it2`, `playwright-cli`, core git, and `gh` commands
- Enables the `worktrunk` plugin

## Quick Start

### npm package (recommended)

Interactive setup with rich prompts:

```bash
# Run from your project directory
npx labkit init

# Update patterns later
npx labkit sync
```

The `init` command walks you through:
1. Platform selection (Claude, Cursor, Windsurf, Copilot)
2. Skills to install (installed to each platform's native skills directory)
3. Commands to install (Claude + Cursor only)
4. Rules to install (platform-specific formats)

It creates a `.labkitrc` config file and pulls the selected patterns from GitHub using `tiged`.

### Shell script alternative

For environments where you prefer a standalone bash script:

```bash
# Fetch the script once
npx tiged dallen4/labkit/labkit.sh ./labkit.sh
chmod +x labkit.sh

# Interactive setup
./labkit.sh init

# Sync from config
./labkit.sh sync
```

Or run directly without saving:

```bash
curl -fsSL https://raw.githubusercontent.com/dallen4/labkit/main/labkit.sh | bash -s -- init
```

### Config format: `.labkitrc`

Both the npm package and shell script use the same config file:

```yaml
source: dallen4/labkit

platforms:
  - claude
  - cursor

skills:
  - playwright-cli
  - it2

commands:
  - spawn
  - commit
  - create-pr

rules:
  - commit-conventions
  - agentic-workflow
```

**Syncing updates:** Run `npx labkit sync` (or `./labkit.sh sync`) anytime to pull the latest versions from the source repo. Your `.labkitrc` config determines what gets updated.

## Post-Install: Hydration

Skills that depend on external tooling (like `playwright-cli` and `it2`) ship with hydration scripts. After installing skills, run:

```bash
# Install all external dependencies
scripts/hydrate.sh

# Single skill only
scripts/hydrate.sh playwright-cli

# Preview what would run
scripts/hydrate.sh --dry-run
```

Each skill's `hydrate.sh` is idempotent — safe to run multiple times.

## How It Works

labkit uses a **tiged + cpx** strategy to selectively pull patterns from GitHub:

1. **Stage** — `tiged` (maintained fork of `degit`) fetches relevant directories from the source repo to a temporary `.labkit-tmp/` directory
2. **Copy** — `cpx` selectively copies files matching your `.labkitrc` config (supports glob patterns)
3. **Clean** — Remove staging directory

This enables cherry-picking individual files and syncing updates without cloning the entire repo.

## External Dependencies

**Required for labkit CLI:**
- Node.js >=18 — Required for `tiged`, `cpx`, YAML parsing
- `npx` — Used to run `tiged` and `cpx2`

**Required for specific commands:**
- `/spawn`, `/focus`, `/worktrees`, `/teardown` → [`wt`](https://github.com/nicholasgasior/wt) (git worktree manager) + [`it2`](https://iterm2.com/documentation-scripting-fundamentals.html) (iTerm2 CLI)
- `/create-pr`, `/research` → [`gh`](https://cli.github.com/) (GitHub CLI)

**Required for specific skills:**
- `playwright-cli` skill → `npm install -g playwright-cli`
- `it2` skill → iTerm2 app with CLI tools enabled

## Contributing

Want to add your own patterns or improve existing ones? See [CLAUDE.md](CLAUDE.md) for development guidelines and architecture details.
