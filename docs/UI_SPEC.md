# UI Spec

## Design Principles
- Landscape-first tablet layout.
- Large touch targets and clear section navigation.
- High contrast, industrial, professional styling.
- Minimal clutter and fast field use.
- Clear status badges and required-field indicators.
- Brand area uses the local logo asset at `assets/logo/cts_logo.png` until a final logo is supplied.
- Preserve a wide-tablet layout so technicians can see navigation, form content, and summary state at the same time.
- Support Android 16 adaptive portrait at 412x915 with compact bottom
  navigation and stacked signature controls instead of forcing landscape.

## App Shell
- Left panel: dashboard navigation, inspection list, search, and status filters.
- Center panel: active form or detail content.
- Right panel: validation summary, photo summary, action items, and shortcuts where space allows.
- Navigation is router-driven so tablet sections can be opened directly and restored consistently.
- At compact widths the left rail becomes a bottom navigation bar so the
  active screen retains usable form width.

## Screens
### Home / Dashboard
- Brand area with app title and logo.
- New Inspection button.
- Draft, In Progress, Complete, Emailed, and Critical summary cards.
- Search by document number, customer, site, equipment model/serial, axle serial, inspector, status, or document number.
- Recent inspections and duplicate shortcut.

### Inspection Editor
- Fixed section navigation for all ten mining axle sections.
- Persistent save state and completion state.
- Required-field indicators and flagged-item markers.
- No condition, defect, reliability, overall-condition, or health-score value is preselected; the inspector must make every required choice explicitly.
- Inline photo areas and comments.
- Section cards should be spaced for tablet hands and stylus use, not phone-sized density.

### Inspection Detail
- Readable summary of header data, section results, action items, photos, signature, and PDF actions.
- Edit, duplicate, export, PDF, and email handoff actions.

### Review And Completion
- Missing-field list with tap-to-jump behavior.
- Flagged items needing comments or photos.
- Critical acknowledgement prompt.
- Adverse checklist responses expose a separate Critical / Out of Service control before the lockout/tagout acknowledgement is shown.
- Signature capture and completion action.

### PDF And Email
- Generated PDF preview or handoff summary.
- Recipient suggestions from recent recipients and customer mappings.
- Confirmation step before marking emailed.
- Closing or cancelling the device share sheet leaves the inspection Complete; Emailed status is applied only after the inspector confirms the report was sent.

### Export And Import
- Export a self-contained inspection bundle.
- Import a bundle and resolve document-number conflicts safely.
- The export bundle is a local restore package built from the inspection record, photos, and generated PDF.

## Section Layout
1. Inspection Purpose
2. Visual Inspection
3. Lubrication Assessment
4. Differential Inspection
5. Planetary Hub Inspection
6. Mechanical Measurements
7. Temperature Assessment
8. Condition Monitoring Findings
9. Recommendations
10. Overall Axle Health Assessment

## Interaction Rules
- Keep navigation shallow and obvious.
- Show completion and validation state at all times.
- Use clear empty states for photos, actions, and export history.
- Preserve entered data automatically and visibly.
- Keep customer-facing labels plain and operational.
- Keep critical warning states unmistakable and high contrast.
