#!/usr/bin/env bash
set -euo pipefail

apk_path="${1:-build/app/outputs/flutter-apk/app-release.apk}"
base_apk="${CTS_SMOKE_BASE_APK:-}"
package_name="com.combinedtechnicalservices.miningaxleinspection"
adb_bin="${ADB:-adb}"
remote_dump="/sdcard/cts_axle_smoke_window.xml"
local_dump="$(mktemp -t cts_axle_smoke.XXXXXX.xml)"
trap 'rm -f "$local_dump"' EXIT

if [[ ! -f "$apk_path" ]]; then
  echo "Release APK not found: $apk_path" >&2
  exit 1
fi
if ! command -v "$adb_bin" >/dev/null 2>&1; then
  echo "adb was not found. Set ADB or add it to PATH." >&2
  exit 1
fi

dump_ui() {
  rm -f "$local_dump"
  "$adb_bin" shell rm -f "$remote_dump" >/dev/null 2>&1 || return 1
  "$adb_bin" shell uiautomator dump "$remote_dump" >/dev/null 2>&1 || return 1
  "$adb_bin" pull "$remote_dump" "$local_dump" >/dev/null 2>&1 || return 1
}

wait_for_description() {
  local description="$1"
  local attempts="${2:-30}"
  local attempt
  for ((attempt = 1; attempt <= attempts; attempt++)); do
    if dump_ui && grep -Fq "content-desc=\"$description\"" "$local_dump"; then
      return 0
    fi
    sleep 1
  done
  echo "Timed out waiting for UI text: $description" >&2
  cat "$local_dump" >&2 || true
  return 1
}

tap_description() {
  local description="$1"
  dump_ui
  local coordinates
  coordinates="$(python3 - "$local_dump" "$description" <<'PY'
import re
import sys
import xml.etree.ElementTree as ET

root = ET.parse(sys.argv[1]).getroot()
description = sys.argv[2]
for node in root.iter('node'):
    if node.attrib.get('content-desc') != description:
        continue
    match = re.fullmatch(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]', node.attrib['bounds'])
    if match:
        left, top, right, bottom = map(int, match.groups())
        print((left + right) // 2, (top + bottom) // 2)
        break
else:
    raise SystemExit(f'Clickable UI text was not found: {description}')
PY
)"
  read -r x y <<<"$coordinates"
  "$adb_bin" shell input tap "$x" "$y"
}

"$adb_bin" wait-for-device
"$adb_bin" uninstall "$package_name" >/dev/null 2>&1 || true
if [[ -n "$base_apk" ]]; then
  if [[ ! -f "$base_apk" ]]; then
    echo "Base APK not found: $base_apk" >&2
    exit 1
  fi
  "$adb_bin" install "$base_apk" >/dev/null
  "$adb_bin" install -r "$apk_path" >/dev/null
else
  "$adb_bin" install "$apk_path" >/dev/null
fi
"$adb_bin" logcat -c
"$adb_bin" shell am start -W -n "$package_name/.MainActivity" >/dev/null

wait_for_description "Mining Axle Dashboard" 45
tap_description "New Inspection"
wait_for_description "New Mining Axle Inspection" 45

dump_ui
if grep -Eq 'Unable to start a new inspection|Inspection record was not found' \
  "$local_dump"; then
  echo "The release APK reached the new-inspection failure state." >&2
  exit 1
fi

app_log="$("$adb_bin" logcat -d -v brief)"
if grep -Eq \
  'No JNI instance is available|could not find or invoke the GeneratedPluginRegistrant|ClassNotFoundException: io\.flutter\.plugins\.GeneratedPluginRegistrant' \
  <<<"$app_log"; then
  echo "The release APK logged a native plugin registration failure." >&2
  exit 1
fi

echo "Release APK Start New Inspection smoke passed: $apk_path"
