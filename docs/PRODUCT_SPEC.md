# Product Spec

## Product
CTS Mining Axle Inspection is a production-ready Android tablet app for Combined Technical Services mining axle inspection reporting. It replaces a manual field workflow with an offline inspection, photo capture, signoff, PDF generation, and email handoff flow.

## Implementation Direction
- Flutter stable on Android tablets.
- Riverpod for state management.
- `go_router` for navigation.
- Local SQLite storage for indexed inspection data.
- JSON aggregate bundles for export/import and inspection restore.
- Local file storage for photos, signatures, and generated PDFs.
- Default brand and sample assets live in `assets/logo/` and `assets/demo/`.

## V1 Goals
- Create new inspections.
- Edit previous inspections.
- Duplicate previous inspections without copying photos or signatures.
- Save all data locally.
- Search inspections locally.
- Generate a professional PDF report.
- Export and import individual inspections.
- Hand off the PDF through the device email or share flow.

## V1 Scope
### In Scope
- Offline-only operation.
- Local document numbering in `YYYYMMDD-0001` format.
- Dashboard with draft, in-progress, complete, emailed, and critical counts.
- Fixed inspection form with ten mining axle sections.
- Required comments, photos, and action items for Poor, defect Yes, Not Acceptable, Not Operational, and Critical responses.
- CTS inspector signoff with typed name, drawn signature, and timestamp.
- Optional customer representative signature or unavailable/declined note.
- Local recent-recipient and customer-email mapping storage.
- Local export/import of inspection bundles.

### Out Of Scope
- Login or accounts.
- Cloud sync.
- Web dashboard.
- GPS capture.
- Score calculation.
- Multi-template editing in V1.
- Manager approval workflow in V1.

## Status Model
- Draft: created but not meaningfully started or missing required details.
- In Progress: saved responses exist but completion validation is not satisfied.
- Complete: completion validation passes and signoff is captured.
- Emailed: the PDF was handed off and the user confirmed it was emailed or sent.

## Core Rules
- Editing an emailed inspection clears emailed status and timestamp until it is sent again.
- Critical / Out of Service items require comment, photo, action item, and lockout/tagout acknowledgement.
- Rating rows use Good, Fair, Poor, N/A, and Not Inspected.
- Defect rows use Yes, No, N/A, and Not Inspected.
- Critical / Out of Service is a separate acknowledgement-gated state.
- The app must never require internet access to work.
- Duplicate inspections must receive a new document number and new created timestamp.

## Inspection Flow
1. Create inspection and auto-generate document number.
2. Enter customer, equipment, machine, and axle header details.
3. Select inspection purpose.
4. Complete each fixed inspection section.
5. Capture photos, comments, and action items where required.
6. Review validation issues and the health assessment.
7. Capture CTS inspector name and signature.
8. Complete the inspection.
9. Generate the PDF.
10. Hand off the PDF for email or sharing.
11. Optionally mark the report as emailed after confirmation.

## Success Criteria
- The inspection can be completed end to end on an Android tablet.
- Required validation blocks incomplete records.
- Photos, signatures, PDFs, export bundles, and imports all work offline.
- Search and duplicate behaviors are correct and deterministic.
