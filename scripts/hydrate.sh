#!/usr/bin/env bash
# labkit hydrate — install external dependencies for skills
# Usage: scripts/hydrate.sh [skill-name] [--dry-run]
#
# Two layers:
#   A) Vendored skills — runs each .claude/skills/*/hydrate.sh to install the
#      underlying CLI binary (it2, playwright-cli, …).
#   B) Marketplace skills — if skills-lock.json exists, restores the pinned
#      skills into .agents/skills/ via `npx skills experimental_install`.
#      Refresh them later with `npx skills update`.
#
# Passing a [skill-name] targets a single Layer-A skill and skips Layer B.
set -euo pipefail

LABKIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="$LABKIT_DIR/.claude/skills"
LOCK_FILE="$LABKIT_DIR/skills-lock.json"
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

FAILED=0

# ── Layer A: vendored skills (CLI dependencies) ───────────────────────────────
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

# ── Layer B: marketplace skills (restored from skills-lock.json) ──────────────
# Skipped when targeting a single Layer-A skill via [skill-name].
if [[ -z "$SKILL_FILTER" && -f "$LOCK_FILE" ]]; then
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "[dry-run] would run: npx skills experimental_install -y (from $LOCK_FILE)"
  elif ! command -v npx &>/dev/null; then
    echo "── marketplace skills ──"
    echo "  skipped (npx not found — install Node.js to restore skills-lock.json)"
    echo ""
    FAILED=1
  else
    echo "── marketplace skills ──"
    if (cd "$LABKIT_DIR" && npx -y skills@latest experimental_install -y); then
      echo ""
    else
      echo "  FAILED (exit $?)"
      echo ""
      FAILED=1
    fi
  fi
fi

# ── Summary ───────────────────────────────────────────────────────────────────
if [[ $DRY_RUN -eq 1 ]]; then
  exit 0
fi

if [[ ${#SCRIPTS[@]} -eq 0 && ! ( -z "$SKILL_FILTER" && -f "$LOCK_FILE" ) ]]; then
  echo "Nothing to hydrate."
  exit 0
fi

if [[ $FAILED -eq 1 ]]; then
  echo "Some skills failed to hydrate. See output above."
  exit 1
fi

echo "All skills hydrated."
