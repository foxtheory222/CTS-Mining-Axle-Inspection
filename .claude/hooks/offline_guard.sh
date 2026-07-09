#!/usr/bin/env bash
# PreToolUse hook: mechanically enforce the offline-only / local-only invariant.
# Blocks Edit/Write/MultiEdit that would introduce a network, cloud, auth, or
# location dependency into Dart source or pubspec.yaml — the one product rule
# that must never regress (see AGENTS.md / README.md). Exit 2 = block + explain.
#
# Local I/O (sqflite, path_provider, file_picker, image_picker, printing,
# share_plus, archive, open_filex) is expected and intentionally NOT flagged.
set -uo pipefail

input=$(cat)
file=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
base=$(basename "${file:-}")

# Tests/tooling may legitimately mention these tokens.
case "$file" in
  */test/*|*/integration_test/*|*/tool/*) exit 0 ;;
esac

# Only guard Dart source and the dependency manifest.
case "$file" in
  *.dart) ;;
  *) [ "$base" = "pubspec.yaml" ] || exit 0 ;;
esac

new_content=$(printf '%s' "$input" | jq -r '
  [ (.tool_input.new_string // empty),
    (.tool_input.content // empty),
    ((.tool_input.edits // []) | map(.new_string // empty) | join("\n")) ] | join("\n")
' 2>/dev/null)

violations=""
flag() { printf '%s' "$new_content" | grep -Eq "$1" && violations="${violations}  - $2"$'\n'; }

# Network primitives (Dart source)
flag 'package:http/|package:dio/|\bHttpClient\b|\bWebSocket\b|\bSocket\.(connect|startConnect)|Uri\.https?\(' \
     'network call — http/dio/HttpClient/WebSocket/Socket/Uri.http'
# Cloud / backend SDKs
flag 'package:(firebase|firebase_[a-z_]+|cloud_firestore|supabase[a-z_]*|amplify[a-z_]*|aws[a-z_]*)/|google_sign_in' \
     'cloud/backend SDK — firebase/supabase/aws/google_sign_in'
# Location / GPS
flag 'package:(geolocator|location|geocoding)/|\bGeolocator\b' \
     'location/GPS — geolocator/location/geocoding'
# Remote analytics / crash uploaders
flag 'package:(firebase_analytics|firebase_crashlytics|sentry[a-z_]*|posthog|mixpanel)' \
     'remote analytics / crash uploader'
# Banned dependency lines added to pubspec.yaml
flag '^[[:space:]]+(http|dio|firebase[a-z_]*|cloud_firestore|supabase[a-z_]*|amplify[a-z_]*|geolocator|location|geocoding|google_sign_in|sentry[a-z_]*|posthog|mixpanel)[[:space:]]*:' \
     'banned dependency added to pubspec.yaml'

if [ -n "$violations" ]; then
  {
    printf "Blocked: this edit to %s breaks the offline-only / local-only invariant:\n" "$file"
    printf "%s" "$violations"
    printf "V1 is offline-first: no network, cloud, login, or GPS. Use a local-only alternative, or have the user lift the invariant explicitly in AGENTS.md.\n"
  } >&2
  exit 2
fi

exit 0
