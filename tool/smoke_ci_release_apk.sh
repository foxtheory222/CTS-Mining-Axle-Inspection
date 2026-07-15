#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
base_apk="${RUNNER_TEMP:-/tmp}/CTS-Mining-Axle-Inspection-v1.1.0.apk"

cd "$repo_root"
curl --fail --location --silent --show-error \
  https://github.com/foxtheory222/CTS-Mining-Axle-Inspection/releases/download/v1.1.0/CTS-Mining-Axle-Inspection-v1.1.0.apk \
  --output "$base_apk"

CTS_SMOKE_BASE_APK="$base_apk" tool/smoke_release_apk.sh
