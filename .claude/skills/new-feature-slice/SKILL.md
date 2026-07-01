---
name: new-feature-slice
description: Scaffold a new feature under lib/features/<name>/ following this repo's Riverpod + go_router structure, wired into the app shell with a matching test. Use when adding a new screen/feature area to the CTS Mining Axle Inspection app.
disable-model-invocation: true
---

# New Feature Slice

Scaffold a new feature that matches the existing structure of this app. The argument is the feature name in snake_case (e.g. `inspection_notes`).

## Study the existing pattern first

Before writing, read one or two current slices to copy their idioms exactly:

- `lib/features/inspection_list/inspection_list_screen.dart`
- `lib/features/dashboard/dashboard_screen.dart`
- `lib/features/settings/settings_screen.dart`

Also read:
- `lib/app.dart` — how routes are registered with `go_router`.
- `lib/widgets/app_shell.dart` and `lib/widgets/section_card.dart` — the landscape/tablet shell and shared widgets to reuse.
- `lib/core/workspace_providers.dart` — how Riverpod providers are exposed.

## Create

1. `lib/features/<name>/<name>_screen.dart` — a `ConsumerWidget`/`ConsumerStatefulWidget` using the existing theme (`lib/core/theme.dart`), tablet-first and readable in landscape. Reuse `AppShell`/`SectionCard`; do not hand-roll layout that already exists.
2. If the feature owns state, add providers in the feature folder (or extend `lib/core/workspace_providers.dart`) — match how other features expose state.
3. Register the route in `lib/app.dart` via `go_router`, following the existing route naming.
4. `test/widget/<name>_screen_test.dart` — a widget test using the tablet harness in `test/support/spec_tablet_harness.dart`.

## Rules (from AGENTS.md)

- Tablet-first, wide landscape layout.
- No network / cloud / login / GPS. Local-only.
- No TODOs, placeholders, or dead flows — wire the screen into real navigation.
- Centralize document-number, status, validation, and file-path logic (do not duplicate it in the new screen).

## Finish

Run the new test and `flutter analyze`, then report what was created and the results.
