#!/usr/bin/env bash
# PostToolUse hook: auto-format Dart files after Claude edits them.
# Mirrors step 2 of the AGENTS.md fix-test-fix loop (`dart format .`).
# Never blocks — always exits 0 so a formatting hiccup can't stall an edit.
set -uo pipefail

input=$(cat)
file=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
[ -z "$file" ] && exit 0

case "$file" in
  *.dart)
    if command -v dart >/dev/null 2>&1 && [ -f "$file" ]; then
      dart format "$file" >/dev/null 2>&1 || true
    fi
    ;;
esac

exit 0
