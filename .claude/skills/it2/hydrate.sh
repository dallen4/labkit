#!/usr/bin/env bash
# Hydrate it2 skill — verify iTerm2 and it2 CLI are available
set -euo pipefail

SKILL_NAME="it2"

# Check iTerm2 is installed
if [[ ! -d "/Applications/iTerm.app" ]]; then
  echo "$SKILL_NAME: iTerm2 not found at /Applications/iTerm.app"
  echo "  Install from https://iterm2.com or: brew install --cask iterm2"
  exit 1
fi

# Check it2 binary is on PATH
if command -v it2 &>/dev/null; then
  echo "$SKILL_NAME: already available ($(it2 --version 2>/dev/null || echo 'found on PATH'))"
  exit 0
fi

# it2 ships inside iTerm2 — check common locations
IT2_BUNDLED="/Applications/iTerm.app/Contents/Resources/it2"
if [[ -x "$IT2_BUNDLED" ]]; then
  echo "$SKILL_NAME: found bundled it2 at $IT2_BUNDLED but it's not on PATH"
  echo "  Add to PATH: export PATH=\"/Applications/iTerm.app/Contents/Resources:\$PATH\""
  echo "  Or symlink:  ln -s \"$IT2_BUNDLED\" /usr/local/bin/it2"
  exit 1
fi

echo "$SKILL_NAME: it2 binary not found"
echo "  Ensure you're running inside iTerm2 and it2 is on your PATH"
echo "  See: https://iterm2.com/documentation-scripting-fundamentals.html"
exit 1
