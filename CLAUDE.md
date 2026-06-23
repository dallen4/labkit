# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

labkit is a reusable kit of agentic patterns for AI coding assistants — both a pattern library AND an npm package CLI for installing them. Users can cherry-pick exactly what they want (commands, skills, rules) for their chosen platforms (Claude Code, Cursor, Windsurf, GitHub Copilot).

The project has two distribution layers:
1. **npm package** (`labkit`) — Interactive CLI with rich prompts using @clack/prompts
2. **Shell script** (`labkit.sh`) — Portable bash alternative requiring only Node.js

Both use a tiged-based fetch strategy to pull patterns from GitHub without cloning the repo, and both read `.labkitrc` for configuration.

## Repository Layout

```
src/
  index.ts              CLI entry point — subcommand routing (init/sync)
  init.ts               Interactive init flow with @clack/prompts
  sync.ts               Config-based sync logic
  tiged.ts              tiged wrapper — staging + cpx copy strategy
  config.ts             cosmiconfig-based .labkitrc read/write
  manifest.ts           Single source of truth for available patterns

.claude/
  commands/             Slash commands (commit, create-pr, spawn, focus, worktrees, teardown, research)
  skills/               Skills with SKILL.md (playwright-cli, it2)
  settings.json         Recommended permissions + agent teams env var

.agents/
  skills/               Marketplace skills, restored from skills-lock.json (gitignored)

.cursor/
  commands/             Mirror of .claude/commands/ (Cursor supports slash commands too)
  rules/                Rule files (.mdc with frontmatter)

.windsurf/
  rules/                Rule files (.md)

.github/
  copilot-instructions.md  Combined instructions file

scripts/
  hydrate.sh            Orchestrator — Layer A (vendored CLI deps) + Layer B (marketplace skills)

labkit.sh               Portable bash alternative to npm package
package.json            npm package config + build scripts
tsconfig.json           TypeScript config
tsdown.config.ts        Build config (uses tsdown, not tsup)
skills-lock.json        Pinned manifest of marketplace skills (find-skills, gh-cli, worktrunk)
```

## Architecture

### Distribution Strategy

**tiged + cpx approach:**
1. **Stage** — tiged fetches relevant directories from GitHub to `.labkit-tmp/`
2. **Copy** — cpx selectively copies files matching the config (supports glob patterns)
3. **Clean** — Remove staging directory

This enables cherry-picking individual files and syncing updates without cloning the entire repo.

### CLI Usage

**npm package:**
```bash
npx labkit init    # Interactive setup → creates .labkitrc + pulls patterns
npx labkit sync    # Re-pull everything in .labkitrc from source
```

**Shell script:**
```bash
./labkit.sh init   # Bash select menus → creates .labkitrc + pulls patterns
./labkit.sh sync   # Re-pull from .labkitrc using tiged + shell globs
```

### Config Format: `.labkitrc`

YAML syntax, no extension. Example:

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

rules:
  - commit-conventions
```

Resolved via cosmiconfig in the npm package; parsed via `node -e` in `labkit.sh`.

### Platform Capabilities

| Feature | Claude | Cursor | Windsurf | Copilot |
|---------|--------|--------|----------|---------|
| **Skills** | `.claude/skills/` | `.cursor/skills/` | `.windsurf/skills/` | `.github/skills/` |
| **Commands** | `.claude/commands/` | `.cursor/commands/` | — | — |
| **Rules** | — | `.cursor/rules/*.mdc` | `.windsurf/rules/*.md` | `.github/copilot-instructions.md` |

**Skills strategy:** All platforms support SKILL.md. labkit installs skills to each platform's native directory for maximum compatibility. While some platforms can read from `.claude/skills/` as a fallback, we install to platform-specific directories to avoid requiring users to enable cross-compat settings.

## Pattern Parity

When updating conventions (e.g., commit format), maintain parity across platforms:

1. **Commands** — Update both `.claude/commands/` and `.cursor/commands/` (Cursor supports slash commands too)
2. **Rules** — Update `.cursor/rules/`, `.windsurf/rules/`, and `.github/copilot-instructions.md`
3. **Manifest** — Update `src/manifest.ts` if adding/removing patterns

## External Dependencies

**Runtime (npm package & shell script):**
- Node.js >=18 — Required for tiged, cpx, YAML parsing
- `npx` — Used to run tiged and cpx2

**Commands assume these CLIs are on `$PATH`:**

| CLI | Used by |
|---|---|
| `wt` | spawn, teardown, worktrees |
| `it2` | spawn, focus, teardown, worktrees |
| `playwright-cli` | playwright-cli skill |
| `gh` | create-pr, research |

**Development:**
- `tsdown` — TypeScript bundler (replaces deprecated tsup)
- `nexe` — (optional) Creates standalone executable from built CLI

## Hydration

`scripts/hydrate.sh` is the orchestrator. It handles two layers:

**Layer A — vendored skills (CLI dependencies).** Skills that wrap external CLIs include a `hydrate.sh` script in their directory (e.g., `.claude/skills/playwright-cli/hydrate.sh`). The orchestrator discovers and runs them all. Each is idempotent, checks if the dependency is already installed, and exits non-zero on failure. When adding a new skill that depends on external tooling, create a `hydrate.sh` in the skill's directory following the same pattern.

**Layer B — marketplace skills (declared, not vendored).** Generic skills from the [skills.sh](https://skills.sh) ecosystem are pinned in `skills-lock.json` rather than committed. The orchestrator restores them into `.agents/skills/` with `npx skills experimental_install` (idempotent). This avoids one-off `npx skills add` followed by manual maintenance — refresh everything with `npx skills update`.

- **`.agents/skills/` is the canonical cross-agent location** (not per-agent `.claude/skills/`). Add new marketplace skills with `npx skills add <owner/repo> --skill <name> -a universal` so they land in `.agents/skills/` without spraying per-agent mirrors, then commit the updated `skills-lock.json`.
- The restored skill directories are gitignored; `skills-lock.json` is the source of truth.
- Currently pinned: `find-skills` (`vercel-labs/skills`), `gh-cli` (`trailofbits/skills`), `worktrunk` (`max-sixty/worktrunk`).

`install.sh` ships `skills-lock.json` into the target and adds `/.agents/skills/` to its `.gitignore`. Passing a single `[skill-name]` to `scripts/hydrate.sh` targets one Layer-A skill and skips Layer B.

## Development

**Build:**
```bash
npm run build          # Compile TypeScript to dist/
npm run build:binary   # Create standalone executable with nexe
npm run typecheck      # Type check without building
```

**Testing locally:**
```bash
# Test npm package
node dist/index.js init
node dist/index.js sync

# Test shell script
./labkit.sh init
./labkit.sh sync
```

## Conventions

- Commit format: `<type>: <description>` — imperative mood, under 72 chars, no AI attribution trailers
- No AI-generated Co-Authored-By or tool attribution in commits or PRs
- Prefer editing existing pattern files over creating new ones
- Keep patterns generic/project-agnostic — project-specific commands belong in target repos
- When adding patterns, update `src/manifest.ts` to keep it in sync
