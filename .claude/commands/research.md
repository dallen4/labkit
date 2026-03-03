---
description: Research a topic across the codebase and the web, then write a structured implementation plan. Usage: /research <topic> [--scope <area>]
allowed-tools: Bash(grep:*), Bash(find:*), Bash(git:*), Bash(gh:*), Bash(mkdir:*), WebFetch(*), WebSearch(*), Glob(*), Grep(*), Read(*), Agent(*), Write(*)
---

## User Input

```text
$ARGUMENTS
```

## Goal

Research a feature, problem, or technology by gathering evidence from the codebase and the web in parallel via agent teams, then synthesise the findings into a structured implementation plan.

## Arguments

- **topic** (required): What to research (feature name, bug description, technology question)
- **--scope <area>** (optional): Narrow the codebase search to a specific directory or layer (e.g., `--scope api`, `--scope web/src`)

## Phase 1 — Parse & orient

Parse `$ARGUMENTS`:
- Extract the topic (everything before any `--` flags)
- Detect `--scope <area>` if present; default scope is the entire repo
- Derive a short slug from the topic (lowercase, hyphens) for the output file name

Confirm the parse to the user in one line before continuing.

## Phase 2 — Parallel research via agent teams

Launch two agents in parallel using the `Agent` tool. Do not wait for one before starting the other.

### Agent A — Codebase reconnaissance (subagent_type: Explore)

Instruct this agent to:

1. **Keyword search** — find all source files mentioning the topic:
   ```bash
   grep -r "<topic>" . --include="*.ts" --include="*.tsx" --include="*.js" --include="*.py" -l \
     --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist --exclude-dir=build
   ```

2. **Directory map** — read key config files to understand the project structure:
   - `package.json` / `pyproject.toml` / `go.mod` (whichever applies) to list available packages/deps
   - Top-level `src/` or equivalent to map the codebase layers

3. **Scope search** — if `--scope` was specified, read the files in that area more deeply

4. **Gap analysis** — identify what already exists for the topic vs what's missing:

   | Capability | File / Module | Status |
   |---|---|---|
   | ... | ... | exists / missing / partial |

5. **Dependency check** — note any existing packages that could serve the feature before proposing new ones

### Agent B — External research (subagent_type: general-purpose)

Instruct this agent to answer open questions the codebase alone cannot resolve. Limit to 5 web searches. Prioritise:

1. Official docs / specs for any API or library involved
2. Runtime constraints (Node.js, browser, edge, etc.) relevant to the topic
3. Best practices and known pitfalls
4. Prior art in this repo's GitHub issues/PRs via `gh issue list` / `gh pr list`

Return findings as a numbered list — one sentence per source — with the URL cited.

## Phase 3 — Synthesise

After both agents return, merge their findings:
- Resolve conflicts between what the codebase says and what external docs say
- Confirm all proposed changes work within the project's existing tech stack and tooling
- Flag any new dependencies explicitly (with justification)

## Phase 4 — Implementation plan

Produce a plan with the following sections:

### Summary
2–3 sentence overview of the change and its impact.

### Codebase findings
What already exists, what needs to change, what's missing.

### Implementation steps
Ordered steps, each with:
- What to do
- Which file(s) are affected
- Any dependency or prerequisite

### Testing
How to verify the change works — unit tests, integration tests, manual checks.

### Open questions
Anything still unresolved after both agent passes.

## Phase 5 — Write plan file

Create the output directory if needed:
```bash
mkdir -p docs/plans
```

Use the `Write` tool to create `docs/plans/<slug>-plan.md` containing the full plan from Phase 4.

Confirm the file path and line count to the user.

## Output

Return a brief summary:
- Topic and scope
- Number of codebase files analysed (from Agent A)
- Number of external sources consulted (from Agent B)
- Key gap(s) identified
- Path to the written plan file

## Example Usage

```
/research authentication refresh tokens
```

```
/research websocket reconnection --scope src/lib/realtime
```
