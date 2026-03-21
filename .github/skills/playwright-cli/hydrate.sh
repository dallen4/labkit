#!/usr/bin/env bash
# Hydrate playwright-cli skill — install playwright-cli and browsers
set -euo pipefail

SKILL_NAME="playwright-cli"

if command -v playwright-cli &>/dev/null; then
  echo "$SKILL_NAME: already installed ($(playwright-cli --version 2>/dev/null || echo 'unknown version'))"
  exit 0
fi

echo "$SKILL_NAME: installing via npm..."
npm install -g playwright-cli

echo "$SKILL_NAME: installing browsers..."
npx playwright install

echo "$SKILL_NAME: done"
