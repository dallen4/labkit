# Pull Request Workflow

## Creating a PR

1. **Confirm you're on the right branch** — never PR from main/master directly
2. **Review all commits** since the base branch: `git log <base>..<head> --oneline`
3. **Check diff stats**: `git diff <base>...<head> --stat`
4. **Create via GitHub CLI**:
   ```bash
   gh pr create --base <target> --head <current> --title "<title>" --body "<body>"
   ```

## PR title

- Short (under 70 characters)
- Imperative mood: "Add auth refresh" not "Adding auth refresh"
- Matches the primary conventional commit type of the changes

## PR body structure

```markdown
## Summary
<2-3 sentence overview of what changed and why>

## Changes
- <grouped by feature/fix with commit references>
- <specific files or components affected>

## Testing
- [ ] <manual check 1>
- [ ] <automated tests pass>
```

## Rules

- Do NOT include "Co-Authored-By" or "Generated with Claude Code" in the PR body
- Default target branch is `main` unless the repo uses a different convention
- Review PR history for format: `gh pr list --state merged --limit 5`
