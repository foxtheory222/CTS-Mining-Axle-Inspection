#!/usr/bin/env bash
# PreToolUse hook: enforce two hard AGENTS.md rules mechanically.
#   1. Never hand-edit generated lock files (pubspec.lock) — use `flutter pub get`.
#   2. "Do not leave TODOs" — block edits that introduce TODO/FIXME/XXX/HACK markers.
# Exit 2 = block the tool call and surface the message (on stderr) back to Claude.
# Note: the word "placeholder" is intentionally NOT blocked — AGENTS.md permits
# placeholder sample assets, so flagging it would create false positives.
set -uo pipefail

input=$(cat)
file=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
base=$(basename "${file:-}")

# 1) Protect generated lock files.
case "$base" in
  pubspec.lock)
    echo "Blocked: pubspec.lock is generated. Run 'flutter pub get' instead of editing it by hand." >&2
    exit 2
    ;;
esac

# 2) Collect the new content this tool call would write (Edit, Write, MultiEdit).
new_content=$(printf '%s' "$input" | jq -r '
  [
    (.tool_input.new_string // empty),
    (.tool_input.content // empty),
    ((.tool_input.edits // []) | map(.new_string // empty) | join("\n"))
  ] | join("\n")
' 2>/dev/null)

if printf '%s' "$new_content" | grep -Eq '\b(TODO|FIXME|XXX|HACK)\b'; then
  echo "Blocked: AGENTS.md forbids leaving TODO/FIXME/XXX/HACK markers. Implement the change fully or track it in an issue." >&2
  exit 2
fi

exit 0
