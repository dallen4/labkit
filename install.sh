#!/usr/bin/env bash
# labkit install — copy agentic patterns into a target project
# Usage: ./install.sh [TARGET_DIR] [--claude] [--windsurf] [--cursor] [--copilot] [--all] [--force]
#   TARGET_DIR defaults to $PWD (run from inside your project)
set -euo pipefail

LABKIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$PWD"
FORCE=0
TOOLS=()

# ── Parse arguments ───────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --claude)   TOOLS+=("claude");  shift ;;
    --windsurf) TOOLS+=("windsurf"); shift ;;
    --cursor)   TOOLS+=("cursor");  shift ;;
    --copilot)  TOOLS+=("copilot"); shift ;;
    --all)      TOOLS=("claude" "windsurf" "cursor" "copilot"); shift ;;
    --force)    FORCE=1; shift ;;
    -*)         echo "Unknown option: $1" >&2; exit 1 ;;
    *)          TARGET_DIR="$1"; shift ;;
  esac
done

# ── Interactive picker (if no tools specified) ─────────────────────────────────
if [[ ${#TOOLS[@]} -eq 0 ]]; then
  echo ""
  echo "labkit — agentic patterns"
  echo ""
  echo "Install for which tool(s)?"
  echo "  1  Claude Code   (commands, skills, settings)"
  echo "  2  Windsurf      (.windsurf/rules/)"
  echo "  3  Cursor        (.cursor/rules/)"
  echo "  4  GitHub Copilot (.github/copilot-instructions.md)"
  echo "  all              all of the above"
  echo ""
  read -rp "Choice (space-separated numbers or 'all'): " RAW_CHOICE

  if [[ "$RAW_CHOICE" == "all" ]]; then
    TOOLS=("claude" "windsurf" "cursor" "copilot")
  else
    [[ "$RAW_CHOICE" == *1* ]] && TOOLS+=("claude")
    [[ "$RAW_CHOICE" == *2* ]] && TOOLS+=("windsurf")
    [[ "$RAW_CHOICE" == *3* ]] && TOOLS+=("cursor")
    [[ "$RAW_CHOICE" == *4* ]] && TOOLS+=("copilot")
  fi

  if [[ ${#TOOLS[@]} -eq 0 ]]; then
    echo "Nothing selected. Exiting."
    exit 0
  fi
fi

echo ""
echo "Installing into: $TARGET_DIR"
echo "Tools:           ${TOOLS[*]}"
echo ""

# ── Helpers ───────────────────────────────────────────────────────────────────
copy_dir() {
  # copy_dir <src_dir> <dst_dir>
  local src="$1" dst="$2"
  mkdir -p "$dst"
  if [[ $FORCE -eq 1 ]]; then
    rsync -a "$src/" "$dst/"
  else
    rsync -a --ignore-existing "$src/" "$dst/"
  fi
}

# Merge labkit settings into target .claude/settings.local.json
merge_claude_settings() {
  local src="$LABKIT_DIR/.claude/settings.local.json"
  local dst="$TARGET_DIR/.claude/settings.local.json"

  if [[ ! -f "$dst" ]]; then
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    echo "  created  .claude/settings.local.json"
    return
  fi

  if command -v jq &>/dev/null; then
    local merged
    merged=$(jq -s '
      .[0] as $e | .[1] as $n |
      {
        env: (($e.env // {}) + ($n.env // {})),
        permissions: {
          allow: ((($e.permissions.allow // []) + ($n.permissions.allow // [])) | unique),
          deny:  (($e.permissions.deny  // []) + ($n.permissions.deny  // []) | unique),
          ask:   (($e.permissions.ask   // []) + ($n.permissions.ask   // []) | unique)
        }
      }
    ' "$dst" "$src")
    echo "$merged" > "$dst"
    echo "  merged   .claude/settings.local.json"
  else
    echo "  skipped  .claude/settings.local.json (already exists — install jq for auto-merge)"
    echo "           manually merge from: $LABKIT_DIR/.claude/settings.local.json"
  fi
}

# ── Install each tool ─────────────────────────────────────────────────────────
for TOOL in "${TOOLS[@]}"; do
  case "$TOOL" in

    claude)
      echo "Claude Code:"
      copy_dir "$LABKIT_DIR/.claude/commands" "$TARGET_DIR/.claude/commands"
      echo "  copied   .claude/commands/"
      copy_dir "$LABKIT_DIR/.claude/skills"   "$TARGET_DIR/.claude/skills"
      echo "  copied   .claude/skills/"
      merge_claude_settings
      ;;

    windsurf)
      echo "Windsurf:"
      copy_dir "$LABKIT_DIR/.windsurf/rules" "$TARGET_DIR/.windsurf/rules"
      echo "  copied   .windsurf/rules/"
      ;;

    cursor)
      echo "Cursor:"
      copy_dir "$LABKIT_DIR/.cursor/rules" "$TARGET_DIR/.cursor/rules"
      echo "  copied   .cursor/rules/"
      ;;

    copilot)
      echo "GitHub Copilot:"
      dst="$TARGET_DIR/.github/copilot-instructions.md"
      mkdir -p "$(dirname "$dst")"
      if [[ -f "$dst" && $FORCE -eq 0 ]]; then
        echo "  skipped  .github/copilot-instructions.md (already exists — use --force to overwrite)"
      else
        cp "$LABKIT_DIR/.github/copilot-instructions.md" "$dst"
        echo "  copied   .github/copilot-instructions.md"
      fi
      ;;

  esac
  echo ""
done

echo "Done. Patterns installed into $TARGET_DIR"

# ── Hydration hint ────────────────────────────────────────────────────────────
if [[ " ${TOOLS[*]} " == *" claude "* ]]; then
  echo ""
  echo "Hint: run scripts/hydrate.sh to install external dependencies (playwright-cli, it2, etc.)"
fi

# ── Offer to commit ───────────────────────────────────────────────────────────
if git -C "$TARGET_DIR" rev-parse --git-dir &>/dev/null; then
  echo ""
  read -rp "Commit installed files? [y/N] " COMMIT_CHOICE
  if [[ "$COMMIT_CHOICE" =~ ^[Yy]$ ]]; then
    STAGE_PATHS=()
    for TOOL in "${TOOLS[@]}"; do
      case "$TOOL" in
        claude)   STAGE_PATHS+=(".claude/commands" ".claude/skills") ;;
        windsurf) STAGE_PATHS+=(".windsurf") ;;
        cursor)   STAGE_PATHS+=(".cursor") ;;
        copilot)  STAGE_PATHS+=(".github/copilot-instructions.md") ;;
      esac
    done
    git -C "$TARGET_DIR" add "${STAGE_PATHS[@]}"
    TOOL_LABELS="${TOOLS[*]}"
    git -C "$TARGET_DIR" commit -m "chore: add labkit agentic patterns (${TOOL_LABELS// /, })"
    echo "Committed."
  fi
fi
