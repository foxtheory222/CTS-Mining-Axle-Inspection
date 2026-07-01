# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Read this first
The authoritative working rules, architecture direction, and Definition of Done live in **[AGENTS.md](AGENTS.md)**. Follow it. Product/UI/data specs are under [`docs/`](docs/).

## Non-negotiable invariant
This is an **offline-only, local-only** Android tablet app. **No** cloud, login, GPS, network calls, or API keys in any V1 workflow. Local I/O (`sqflite`, `path_provider`, `file_picker`, `image_picker`, `printing`, `share_plus`) is expected; remote I/O is not.

## Stack
Flutter (stable) · Dart `^3.10.4` · Riverpod · go_router · SQLite (`sqflite`) · local file storage · `pdf`/`printing` for reports.

## Commands
```
flutter pub get
dart format .
flutter analyze
flutter test
flutter test --coverage
flutter test integration_test/app_flow_test.dart   # needs a tablet emulator
flutter build apk --debug
flutter build apk --release
```

## Workflow expectations
- Small, reviewable changes. Write the smallest test first, then implement (see AGENTS.md "Fix-Test-Fix Loop").
- No TODOs, placeholders, dead flows, or untested paths in committed code.
- Keep `docs/` aligned with code. Preserve document numbers permanently.

## Claude Code helpers in this repo
- `/release-check` — run the full release gate against `docs/RELEASE_CHECKLIST.md`.
- `/new-feature-slice` — scaffold a `lib/features/<name>/` slice with a test.
- Subagents: `offline-first-reviewer` (guards the offline invariant), `flutter-test-writer` (writes tests in the repo's style).
- Hooks auto-run `dart format` on save and block TODO markers / `pubspec.lock` edits.
