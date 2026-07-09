---
name: run-tablet-acceptance
description: Boot a landscape Android tablet emulator and run this app's integration_test end-to-end acceptance suite — the manual gate that release checks and CI skip. Invoke before cutting a release or when verifying a full-device run.
disable-model-invocation: true
---

# Run Tablet Acceptance

Drive the on-device acceptance test for this CTS inspection app on a landscape tablet emulator. This spins up hardware and takes minutes — it is a user-invoked, artifact-producing action. Never claim success you did not observe in the output.

## 0. Preconditions

```bash
flutter devices        # is a device already attached?
echo "$ANDROID_HOME"   # must be set for avdmanager / emulator
```

If a tablet emulator is already running and shows in `flutter devices`, skip to step 3 with its device id.

## 1. Create a tablet AVD (once)

```bash
"$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager" create avd --force \
  --name CTS_Tablet_API_36 \
  --package 'system-images;android-36;google_apis_playstore;arm64-v8a' \
  --device pixel_tablet
```

If the system image isn't installed, install it with `sdkmanager` first, or fall back to an API level that is present (`sdkmanager --list | grep system-images`).

## 2. Boot it in landscape

```bash
"$ANDROID_HOME/emulator/emulator" -avd CTS_Tablet_API_36 \
  -wipe-data -no-snapshot -no-audio -no-boot-anim -gpu swiftshader_indirect &
adb wait-for-device
# Force landscape (these apps are landscape-first):
adb -s emulator-5554 shell settings put system accelerometer_rotation 0
adb -s emulator-5554 shell settings put system user_rotation 1
```

Wait until `adb -s emulator-5554 shell getprop sys.boot_completed` returns `1` before running the test.

## 3. Run the acceptance suite

```bash
flutter pub get
# Run this app's integration_test entrypoint (e.g. integration_test/app_flow_test.dart):
flutter test integration_test/app_flow_test.dart -d emulator-5554
```

Use the actual device id from `flutter devices` if it isn't `emulator-5554`. If the app has more than one integration_test file (e.g. a matrix suite), run each.

## 4. Report

- ✅ / ❌ for the integration run, with the failing excerpt on ❌.
- Confirm the app launched, the core inspection flow completed, and any PDF / share steps in the test passed.
- If no emulator or `ANDROID_HOME` is available, stop and report **not run — needs a device/emulator**; do not mark the gate green.

Do not fix failures unless asked — this skill runs the gate and reports it.
