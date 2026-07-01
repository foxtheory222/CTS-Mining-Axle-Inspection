---
name: release-check
description: Run the CTS Mining Axle Inspection release gate — dart format, flutter analyze, flutter test, and the APK builds — then report each result against docs/RELEASE_CHECKLIST.md and the AGENTS.md Definition of Done.
disable-model-invocation: true
---

# Release Check

Run the automated quality gate for a CTS Mining Axle Inspection release and report the outcome against `docs/RELEASE_CHECKLIST.md` and the AGENTS.md "Definition Of Done".

## Steps

Run these from the repo root, in order. Capture pass/fail for each — do NOT stop at the first failure; run them all so the report is complete.

1. `flutter pub get`
2. `dart format --output=none --set-exit-if-changed .`  — fails if any file is unformatted.
3. `flutter analyze`
4. `flutter test`
5. `flutter test --coverage` (optional, if the user wants a coverage number)
6. `flutter build apk --debug`
7. `flutter build apk --release`  — may be unsupported in some environments; note that rather than failing the gate.

`flutter test integration_test/app_flow_test.dart` requires a connected tablet emulator, so only run it if a device is attached (`flutter devices`); otherwise flag it as "manual, needs emulator".

## Report

Produce a checklist mapped to `docs/RELEASE_CHECKLIST.md` → **Quality** and **Release Artifacts** sections:

- ✅ / ❌ per command above, with the failing output excerpt for any ❌.
- Call out anything that blocks the Definition of Done (build failed, tests failed, formatting dirty).
- List the remaining **manual** checks the user still owns (offline-only verification, PDF opens locally, email/share handoff, end-to-end tablet run, docs current).

Do not attempt to fix failures unless the user asks — this skill reports the gate, it does not change code.
