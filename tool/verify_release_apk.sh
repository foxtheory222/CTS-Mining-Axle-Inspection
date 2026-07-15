#!/usr/bin/env bash
set -euo pipefail

apk_path="${1:-build/app/outputs/flutter-apk/app-release.apk}"

if [[ ! -f "$apk_path" ]]; then
  echo "Release APK not found: $apk_path" >&2
  exit 1
fi

android_sdk="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}"
apkanalyzer_bin="${APKANALYZER:-$android_sdk/cmdline-tools/latest/bin/apkanalyzer}"
if [[ ! -x "$apkanalyzer_bin" ]]; then
  for candidate in "$android_sdk"/cmdline-tools/*/bin/apkanalyzer; do
    if [[ -x "$candidate" ]]; then
      apkanalyzer_bin="$candidate"
      break
    fi
  done
fi
if [[ ! -x "$apkanalyzer_bin" ]]; then
  apkanalyzer_bin="$(command -v apkanalyzer || true)"
fi
if [[ -z "$apkanalyzer_bin" || ! -x "$apkanalyzer_bin" ]]; then
  echo "apkanalyzer was not found. Set ANDROID_SDK_ROOT or APKANALYZER." >&2
  exit 1
fi

if [[ "${SKIP_SIGNER_CHECK:-0}" != "1" ]]; then
  apksigner_bin="${APKSIGNER:-}"
  if [[ ! -x "$apksigner_bin" ]]; then
    for candidate in "$android_sdk"/build-tools/*/apksigner; do
      if [[ -x "$candidate" ]]; then
        apksigner_bin="$candidate"
      fi
    done
  fi
  if [[ ! -x "$apksigner_bin" ]]; then
    apksigner_bin="$(command -v apksigner || true)"
  fi
  if [[ -z "$apksigner_bin" || ! -x "$apksigner_bin" ]]; then
    echo "apksigner was not found. Set ANDROID_SDK_ROOT or APKSIGNER." >&2
    exit 1
  fi

  expected_signer_sha256="${EXPECTED_SIGNER_SHA256:-dc43296456fcc7d11f07a80477d844a43034fc262f4da3bdca281108a679f762}"
  signer_output="$(
    "$apksigner_bin" verify --print-certs-pem "$apk_path" 2>&1
  )"
  certificate_pem="$(
    awk '
      /-----BEGIN CERTIFICATE-----/ { capture = 1 }
      capture { print }
      /-----END CERTIFICATE-----/ { exit }
    ' <<<"$signer_output"
  )"
  actual_signer_sha256=""
  if [[ -n "$certificate_pem" ]]; then
    actual_signer_sha256="$(
      openssl x509 -noout -fingerprint -sha256 <<<"$certificate_pem" \
        | sed 's/.*=//' \
        | tr -d ':' \
        | tr '[:upper:]' '[:lower:]'
    )"
  fi
  if [[ "$actual_signer_sha256" != "$expected_signer_sha256" ]]; then
    echo "Release APK signer does not match installed CTS Axle builds." >&2
    echo "Expected: $expected_signer_sha256" >&2
    echo "Actual:   ${actual_signer_sha256:-missing}" >&2
    exit 1
  fi
fi

dex_packages="$("$apkanalyzer_bin" dex packages --defined-only "$apk_path")"

require_class() {
  local class_name="$1"
  if ! grep -Eq "^C d .*${class_name//./\\.}$" <<<"$dex_packages"; then
    echo "Required Android class is missing from release APK: $class_name" >&2
    exit 1
  fi
}

require_class "io.flutter.plugins.GeneratedPluginRegistrant"
require_class "com.github.dart_lang.jni.JniPlugin"
require_class "com.github.dart_lang.jni_flutter.JniFlutterPlugin"

dex_strings="$(unzip -p "$apk_path" 'classes*.dex' | strings)"
if ! grep -Fq 'com.tekartik.sqflite.SqflitePlugin' <<<"$dex_strings"; then
  echo "Sqflite registration is missing from the release APK." >&2
  exit 1
fi

if grep -Eq \
  'dev\.flutter\.plugins\.integration_test|plugins\.flutter\.io/integration_test|Error registering plugin integration_test' \
  <<<"$dex_strings"; then
  echo "Integration-test classes must not ship in the release APK." >&2
  exit 1
fi

echo "Release APK plugin registration verified: $apk_path"
