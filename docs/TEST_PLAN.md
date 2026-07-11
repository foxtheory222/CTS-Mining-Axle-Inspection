# Test Plan

## Strategy
Use a fix-test-fix loop:
1. Write or update the smallest test that describes the behavior.
2. Implement the change.
3. Re-run the same test.
4. Expand to related regression coverage.
5. Run the full suite before release.

## Required Command Set
- `flutter pub get`
- `dart format .`
- `flutter analyze`
- `flutter test`
- `flutter test --coverage` when practical
- `flutter build apk --debug`
- `flutter build apk --release` when the environment supports it
- `cd android && ./gradlew lintRelease`
- `flutter test integration_test` on an Android tablet emulator

## Execution Order
1. Run `flutter pub get` after dependency changes.
2. Run `dart format .` before review.
3. Run `flutter analyze` to catch static issues early.
4. Run targeted `flutter test` files first.
5. Run `flutter test --coverage` when regression scope is broad enough to justify it.
6. Run the integration flow on a connected Android tablet emulator.
7. Run APK builds once tests are green.
8. Render the production editor at 412x915 portrait plus 1024x600, 1280x800,
   and 1600x1000 logical-pixel tablet viewports and fail on layout exceptions.
9. Navigate the 412x915 production shell from Dashboard to Settings and fail
   on any layout exception.
10. Run Android release lint and require zero app errors and warnings.

## Coverage Areas
### Unit Tests
- Document numbering.
- Validation rules.
- Status transitions.
- Action item creation and updates.
- Search and duplicate rules.
- Export/import metadata handling.

### Widget Tests
- Dashboard state rendering.
- Section navigation.
- Required-field and flagged-item prompts.
- Review screen validation summaries.
- Signature and completion UI.
- Explicit unanswered states, Critical / Out of Service selection, and sent-confirmation UI.

### Integration Tests
- New inspection to completion.
- Photo capture or photo service fallback.
- PDF generation and file existence.
- Email/share handoff confirmation.
- Duplicate, export, and import flow.

### Regression Tests
- Clean pass inspection.
- Inspection with At Risk items.
- Inspection with Unsatisfactory items.
- Inspection with Critical / Out of Service items.
- Inspection with many photos.
- Inspection with abnormal axle findings and recommendations.
- Exported and re-imported inspection.
- Placeholder logo and sample media asset availability.

## Emulator Acceptance Flow
1. Launch the app.
2. Open the dashboard.
3. Create a new inspection.
4. Fill the required header fields.
5. Complete each fixed section.
6. Add a photo.
7. Trigger an At Risk validation path.
8. Trigger a Critical validation path and acknowledge lockout/tagout.
9. Add a recommendation/action item.
10. Capture mechanical measurements and temperature information.
11. Add review notes.
12. Enter CTS inspector name and signature.
13. Complete the inspection.
14. Generate the PDF.
15. Open or share the PDF.
16. Confirm emailed status.
17. Return to the dashboard and verify counts.
18. Search, duplicate, export, and import the inspection.

## Regression Fixture Expectations
- Seeded fixtures should exercise clean, flagged, critical, and export/import states.
- Fixtures should include local photos, a drawn signature, and at least one generated PDF path.
- Fixture data should be deterministic so document-number assertions remain stable.
