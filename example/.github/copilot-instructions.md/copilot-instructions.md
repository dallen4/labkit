# GitHub Copilot Instructions

## Commit conventions

Format: `<type>: <succinct description>`

Types: `feat`, `fix`, `chore`, `refactor`, `docs`, `test`, `style`

Rules:
- Imperative mood ("add" not "added")
- Under 72 characters
- No period at the end
- No AI tool attribution in the message

Examples:
```
feat: add track navigation & improve stream URL support
fix: disable caching on admin pages for real-time updates
chore: update dependencies to latest patch versions
```

## Pull request format

Title: short (under 70 chars), imperative mood, matches primary change type.

Body:
```markdown
## Summary
<2-3 sentence overview>

## Changes
- <changes grouped by feature/fix>

## Testing
- [ ] <manual checks>
- [ ] <automated tests pass>
```

No AI tool attribution in PR bodies.

## Agentic workflow

- Feature work happens in isolated git worktrees (`wt` CLI)
- Multi-agent parallelism via iTerm2 panes (`it2` CLI)
- Visual verification via `playwright-cli` against the running dev server
- Research before implementing: grep the codebase, check GitHub issues/PRs, review existing deps before adding new ones

## Code quality

- Edit existing files over creating new ones
- Implement the minimum needed — no speculative features
- Don't add error handling for scenarios that can't happen in normal usage
- Don't add backwards-compat hacks for removed code
- No docstrings or comments on code you didn't change
