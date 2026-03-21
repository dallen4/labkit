# labkit CLI Redesign: degit-based "Build Your Own Toolkit"

## Context

labkit currently uses `install.sh` (rsync-based) to copy agentic patterns into target projects. The goal is to replace this with a degit-based approach so users can:
1. Pull patterns from GitHub without cloning the repo
2. Cherry-pick exactly what they want ("build your own toolkit")
3. Re-sync later as labkit evolves

Two distribution layers: a **shell script** (`labkit.sh`) for portability and a **npm package** (`labkit`) for the interactive experience. Both read `.labkitrc`.

## Platform Capabilities

Skills and commands are no longer Claude-exclusive. All platforms now support the SKILL.md standard, and multiple platforms read from `.claude/skills/` as a cross-compatibility path.

| Feature | Claude | Cursor | Windsurf | Copilot |
|---------|--------|--------|----------|---------|
| **Skills** (`SKILL.md` dirs) | `.claude/skills/` | `.cursor/skills/` or `.claude/skills/` | `.windsurf/skills/` or `.claude/skills/` | `.github/skills/` or `.claude/skills/` |
| **Commands** (slash) | `.claude/commands/*.md` | `.cursor/commands/*.md` | — | — |
| **Rules** (passive context) | — | `.cursor/rules/*.mdc` | `.windsurf/rules/*.md` | `.github/copilot-instructions.md` |

Key insight: `.claude/skills/` is a cross-compat path for Cursor, Windsurf, and Copilot. So a single skills install covers all platforms. Commands need per-platform copies (Claude + Cursor). Rules are platform-specific formats.

## CLI Design

### Subcommands

**`labkit init`** (or `./labkit.sh init`)
- Platforms first → then show what's available for those platforms
- Generates `.labkitrc` in the project root with selections
- Runs initial degit pulls based on selections
- Offers to git commit the result

**`labkit sync`** (or `./labkit.sh sync`)
- Reads `.labkitrc`, pulls latest versions of everything listed
- Equivalent to `--force` — overwrites with upstream
- Reports what changed

### Config: `.labkitrc`

Single file, clean name (no extension), YAML syntax. Resolved via cosmiconfig in the npm package; parsed via a `node -e` one-liner in `labkit.sh` (Node is already required for npx/degit).

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
  - pr-workflow
```

- `source` — GitHub user/repo for degit. Defaults to `dallen4/labkit`
- `platforms` — Which platforms you use. Determines where files get placed and what's available
- `skills` — Skill directories to pull. Placed in `.claude/skills/` (cross-compat path covers all platforms). If platform-specific skill dirs exist in labkit, those are pulled too
- `commands` — Slash commands to pull. Placed in `.claude/commands/` and `.cursor/commands/` if those platforms are selected
- `rules` — Passive rule files. Placed in `.cursor/rules/`, `.windsurf/rules/`, `.github/` per selected platforms

### Fetch Strategy: degit (bulk) → cpx (glob patterns)

degit pulls entire directories — no individual files or wildcards. So the CLI uses a **stage → pattern-copy → clean** approach:

1. **Stage** — `degit` fetches relevant directories from the source repo to a hidden temp dir
2. **Copy** — `cpx` (cross-platform glob copy) selectively copies files matching the config
3. **Clean up** — Remove temp dir

`cpx` is the key — it supports glob patterns for system-agnostic file copying, so we can express things like "copy `{spawn,commit}.md` from staged commands to `.claude/commands/`".

```
# Step 1: degit pulls relevant dirs in bulk to staging
npx degit dallen4/labkit/.claude .labkit-tmp/.claude --force
npx degit dallen4/labkit/.cursor .labkit-tmp/.cursor --force
# (only fetch dirs for selected platforms)

# Step 2: cpx copies with glob patterns based on config

# Skills → .claude/skills/ (cross-compat path for all platforms)
cpx ".labkit-tmp/.claude/skills/playwright-cli/**" ".claude/skills/playwright-cli/"

# Commands → per-platform
# config says commands: [spawn, commit], platforms: [claude, cursor]
cpx ".labkit-tmp/.claude/commands/{spawn,commit}.md" ".claude/commands/"
cpx ".labkit-tmp/.cursor/commands/{spawn,commit}.md" ".cursor/commands/"

# Rules → per-platform
# config says rules: [commit-conventions, agentic-workflow], platforms: [cursor]
cpx ".labkit-tmp/.cursor/rules/{commit-conventions,agentic-workflow}.mdc" ".cursor/rules/"

# Step 3: Clean up
rm -rf .labkit-tmp
```

In the npm package, `degit` and `cpx` are used as JS libraries. In `labkit.sh`, degit runs via npx and copies use shell globs.

### Shell Script: `labkit.sh`

Lives in labkit repo root. Users fetch it once:
```bash
npx degit dallen4/labkit/labkit.sh ./labkit.sh
```

Or run it directly without saving:
```bash
curl -fsSL https://raw.githubusercontent.com/dallen4/labkit/main/labkit.sh | bash -s -- sync
```

**Capabilities:**
- `./labkit.sh init` — Full interactive mode using bash `select` / `read` menus. Same platforms-first flow as the npm package: pick platforms → skills → commands → rules. Generates `.labkitrc`, then stages + copies files via degit + shell globs
- `./labkit.sh sync` — Reads `.labkitrc` via `node -e` YAML parsing, stages + copies latest from source
- Both subcommands are fully interactive when run without a config present
- No npm required beyond npx for degit (Node is the only real dependency)

### npm Package: `labkit`

Published to npm (name TBD, using `labkit` for now).

```bash
npx labkit init    # Rich interactive prompts (inquirer/prompts)
npx labkit sync    # Read .labkitrc, pull latest
```

**Advantages over shell script:**
- Richer prompts (checkboxes, grouped selections, colors)
- Can use degit as a JS library (`import degit from 'degit'`) instead of spawning npx
- Easier to add future subcommands

**Implementation:**
- TypeScript at repo root (`src/`), compiled via tsup or similar
- `package.json` at repo root with `bin` field — labkit publishes as both toolkit and CLI
- Uses `degit` npm package programmatically
- Uses `@clack/prompts` for interactive UI
- Uses `cosmiconfig` for config resolution
- Writes `.labkitrc` (YAML syntax, no extension) on init

### Interactive Init Flow

Platforms first — then show what's available based on your selection.

```
┌  labkit — build your own toolkit
│
◇  Source repo?
│  dallen4/labkit (enter to confirm, or type custom)
│
◆  Which platforms do you use?
│  ◼ Claude Code
│  ◼ Cursor
│  ◻ Windsurf
│  ◻ GitHub Copilot
│
◆  Which skills? (available for: Claude, Cursor)
│  ◼ playwright-cli — browser automation
│  ◻ it2 — iTerm2 terminal control
│
◆  Which commands? (available for: Claude, Cursor)
│  ◻ spawn — create worktree + iTerm2 pane + agent
│  ◼ commit — conventional commits from staged changes
│  ◼ create-pr — structured PR creation
│  ◻ focus — focus iTerm2 pane by branch
│  ◻ worktrees — list worktrees + sessions
│  ◻ teardown — close pane + remove worktree
│  ◻ research — parallel codebase + web investigation
│
◆  Which rules? (available for: Cursor)
│  ◼ commit-conventions
│  ◼ agentic-workflow
│  ◼ pr-workflow
│
◇  Written .labkitrc
◇  Pulling for 2 platforms...
│  ✓ .claude/skills/playwright-cli/
│  ✓ .claude/commands/commit.md
│  ✓ .claude/commands/create-pr.md
│  ✓ .cursor/commands/commit.md
│  ✓ .cursor/commands/create-pr.md
│  ✓ .cursor/rules/commit-conventions.mdc
│  ✓ .cursor/rules/agentic-workflow.mdc
│  ✓ .cursor/rules/pr-workflow.mdc
│
└  Done! Run `labkit sync` anytime to update.
```

The prompts are **conditional** — skills and commands only show if at least one selected platform supports them. Rules only show for platforms that have rule files.

### settings.json Handling

Out of scope for v1. Settings merge is a separate flow / fast follow. The CLI only deals with commands, skills, and platform rule files. If `claude` is in platforms, the CLI pulls commands and skills but does **not** touch `.claude/settings.json`.

### Post-sync: Hydration

After sync completes, if any skills were pulled, print:
```
Skills installed. Run hydration to set up external dependencies:
  scripts/hydrate.sh
```

The hydrate.sh scripts stay as-is — they're already idempotent and skill-local.

## Files to Create/Modify

labkit is the toolkit AND the CLI — no nested subproject. The npm package publishes from the repo root.

### New files:
- `package.json` — npm package config (name TBD, `bin` field points to built output)
- `tsconfig.json`
- `src/index.ts` — Entry point, subcommand routing (init / sync)
- `src/init.ts` — Interactive init flow (@clack/prompts)
- `src/sync.ts` — Config-based sync logic
- `src/degit.ts` — degit wrapper with mapping logic
- `src/config.ts` — cosmiconfig-based .labkitrc read/write
- `src/manifest.ts` — Available commands/skills/platforms (single source of truth)
- `labkit.sh` — Shell script alternative (replaces install.sh for non-npm users)

### New content files (in labkit repo, to support multi-platform commands):
- `.cursor/commands/*.md` — Mirror of `.claude/commands/` for Cursor slash command support

### Modified files:
- `README.md` — Update installation docs, document multi-platform skill/command support
- `CLAUDE.md` — Update architecture section, platform capabilities table
- `install.sh` — Deprecate or remove (replaced by labkit.sh + npm package)

## Verification

1. Run `npx labkit init` in a fresh directory → should prompt, generate `.labkitrc`, pull selected files
2. Run `npx labkit sync` → should re-pull everything in `.labkitrc`
3. Run `./labkit.sh init` → same flow via bash
4. Run `./labkit.sh sync` with existing `.labkitrc` → should pull from config
5. Verify `.labkitrc` source field works with custom GitHub usernames
