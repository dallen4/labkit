# Commit Conventions

## Format

```
<type>: <succinct description>
```

**Types:**
- `feat:` — new feature or enhancement
- `fix:` — bug fix
- `chore:` — maintenance, deps, config updates
- `refactor:` — restructuring without behaviour changes
- `docs:` — documentation only
- `test:` — test additions or updates
- `style:` — formatting, whitespace

## Rules

- Use imperative mood: "add" not "added" or "adds"
- Keep under 72 characters
- No period at the end
- No "🤖 Generated with Claude Code" or Co-Authored-By trailers
- Focus on *what* and *why*, not *how*

## Examples

```
feat: add track navigation & improve stream URL support
fix: disable caching on admin pages for real-time updates
chore: update dependencies to latest patch versions
refactor: extract auth middleware into shared utility
docs: add worktree setup to README
test: add unit tests for crypto key derivation
```

## Before committing

1. Stage only relevant files (`git add <specific files>`)
2. Review staged diff: `git diff --cached`
3. Check recent history for style: `git log --oneline -10`
