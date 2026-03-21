#!/usr/bin/env bash
# labkit hydrate — install external dependencies for skills
# Usage: scripts/hydrate.sh [skill-name] [--dry-run]
set -euo pipefail

LABKIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="$LABKIT_DIR/.claude/skills"
DRY_RUN=0
SKILL_FILTER=""

# ── Parse arguments ───────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    -*)        echo "Unknown option: $1" >&2; exit 1 ;;
    *)         SKILL_FILTER="$1"; shift ;;
  esac
done

# ── Discover hydration scripts ────────────────────────────────────────────────
SCRIPTS=()
if [[ -n "$SKILL_FILTER" ]]; then
  target="$SKILLS_DIR/$SKILL_FILTER/hydrate.sh"
  if [[ -f "$target" ]]; then
    SCRIPTS+=("$target")
  else
    echo "No hydrate.sh found for skill: $SKILL_FILTER" >&2
    exit 1
  fi
else
  for script in "$SKILLS_DIR"/*/hydrate.sh; do
    [[ -f "$script" ]] && SCRIPTS+=("$script")
  done
fi

if [[ ${#SCRIPTS[@]} -eq 0 ]]; then
  echo "No hydration scripts found."
  exit 0
fi

# ── Run ───────────────────────────────────────────────────────────────────────
FAILED=0

for script in "${SCRIPTS[@]}"; do
  skill="$(basename "$(dirname "$script")")"

  if [[ $DRY_RUN -eq 1 ]]; then
    echo "[dry-run] would run: $script"
    continue
  fi

  echo "── $skill ──"
  if bash "$script"; then
    echo ""
  else
    echo "  FAILED (exit $?)"
    echo ""
    FAILED=1
  fi
done

if [[ $DRY_RUN -eq 1 ]]; then
  exit 0
fi

if [[ $FAILED -eq 1 ]]; then
  echo "Some skills failed to hydrate. See output above."
  exit 1
fi

echo "All skills hydrated."
