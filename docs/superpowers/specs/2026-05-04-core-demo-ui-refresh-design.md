# Design Spec: Core Demo UI Refresh

## Context
All functional requirements for MyUmrahGuide are complete. The next pass focuses on the core FYP demo flow only: Welcome/Login entry, Dashboard, Tawaf Simulator, Sa'i Simulator, Guidance Sheet, and ML Recommendation Sheet.

This refresh follows the approved **Pilgrim Companion Refresh** direction: warm, premium, calm, and demo-ready without changing completed geofence, Firebase, ML, offline sync, or ritual progression logic.

## Goals
- Make the first demo impression stronger and less placeholder-like.
- Make the dashboard's next action obvious for presentation flow.
- Preserve the map-first simulator experience while making overlays and demo controls more polished.
- Make ML recommendations and ritual guidance feel like intentional presentation moments.
- Keep the UI system consistent across the core demo flow.

## Non-Goals
- No changes to auth, Firebase, Firestore, ML API, offline sync, geofence, notification, or ritual progression logic.
- No admin analytics dashboard changes.
- No profile, privacy consent, login form, or register form redesign in this pass.
- No new package dependency.
- No new font requirement.
- No required bitmap asset; the welcome hero must work with existing Flutter icons and can later accept a generated/mockup asset.

## Scope
Primary files:
- `lib/features/practice/presentation/widgets/practice_ui.dart`
- `lib/features/practice/presentation/pages/login_guest_view.dart`
- `lib/features/practice/presentation/pages/dashboard_view.dart`
- `lib/features/practice/presentation/pages/tawaf_simulator_view.dart`
- `lib/features/practice/presentation/pages/sai_simulator_view.dart`
- `lib/features/practice/presentation/widgets/recommendation_panel.dart`
- `lib/features/practice/presentation/guidance/ritual_guidance_sheet.dart`

## Visual Direction
- Palette: keep Mecca Gold, Zinc-50/off-white, ink gray, muted body gray, and soft green.
- Gold means primary action, active guidance, and sacred/directional emphasis.
- Green means complete, safe, or ready.
- Orange/red only mean waiting, warning, paused, or outside-zone states.
- Surfaces should feel warm and premium, not decorative-heavy.
- Cards and overlays should have consistent radius, border, padding, and shadow.
- Simulators stay full-map and unframed; controls float as compact overlays.

## Shared UI System
Extend `PracticeUi` with reusable demo-flow primitives where useful:
- App background gradient for welcome-style entry screens.
- Overlay surface decoration for map overlays and command bars.
- Consistent compact pill/chip styling for status, GPS, target, and mode states.
- Shared primary/secondary button styling helpers only if this reduces repeated style code.

Avoid over-abstracting. Add only primitives used by at least two core screens or clearly improving consistency.

## Screen Design

### Welcome / Login Entry
Keep existing actions:
- `Log in`
- `Create an Account`
- `Enter as Guest`

Planned changes:
- Replace the current placeholder hero feel with a polished pilgrim companion hero panel.
- Use a mosque/Kaabah-inspired icon badge, app name, `Pilgrim Companion`, and a short benefit line.
- Keep trust cues, but make them shorter and less bulky.
- Keep the guest-mode note subtle because guest entry is important for demo flow.
- Preserve all existing navigation and guest-session behavior.

### Dashboard
Planned changes:
- Header becomes `Your Umrah Practice`, with profile and practice-mode status visible.
- Add or emphasize a `Next Step` area so the presenter knows what to tap next.
- Keep ritual timeline: Miqat/Niyyah -> Tawaf -> Sa'i.
- Make ready, locked, and completed states visually obvious with consistent chips and icons.
- Move Mode Selector, Background Geofence Readiness, and Adaptive Scheduling lower and make them visually quieter.
- Preserve all current actions:
  - mode switching
  - reset in location-based mode
  - mark Niyyah done
  - open Tawaf
  - open Sa'i
  - background monitoring toggle
  - adaptive scheduling refresh
  - sign out

### Tawaf Simulator
Planned changes:
- Keep full-screen map as the primary surface.
- Top overlay stack:
  - GPS or Tawaf zone status pill
  - compact round progress card
  - ML suggestion button
- Bottom overlay:
  - show `Set Kaabah Here` as primary action only when Kaabah is not set
  - compact demo command bar with `Enter`, `Exit`, and `Next Round`
- Map marker treatment:
  - Kaabah marker should feel distinct and anchored
  - user marker remains clearly visible
  - geofence radius uses gold/green emphasis based on current state
- Preserve all current map behavior, auto-follow behavior, guidance triggers, recovery dialog, and completion logging.

### Sa'i Simulator
Planned changes:
- Match Tawaf overlay structure for product consistency.
- Top overlay stack:
  - GPS or pin-mode status pill
  - next-target pill
  - compact lap progress card
  - ML suggestion button
- Bottom command bar:
  - `Pin Safa`
  - `Pin Marwa`
  - `Reach Target`
- Corridor line remains visible but softer and more intentional.
- Safa and Marwa markers should be easier to scan at demo distance.
- Preserve all current pinning, tracking, target switching, guidance, and completion logging behavior.

### Guidance Sheet
Planned changes:
- Treat guidance as a focused ritual support panel:
  - title and icon
  - short explanation
  - ritual text block when available
  - checklist steps
  - single `Got it` CTA
- Improve spacing, hierarchy, and surface warmth.
- Preserve existing guidance content and dismissal behavior.

### ML Recommendation Sheet
Planned changes:
- Treat ML suggestion as a polished personalized insight panel:
  - clear recommendation title
  - profile basis line
  - four metric tiles: Distance, Pace, Time, Rest
  - advice paragraph
  - small cache/sync status note when relevant
- Improve metric tile density and visual hierarchy.
- Preserve refresh, loading, empty, cached, and sync states.

## Data Flow
No data-flow change.

The UI must continue reading from existing controllers/providers:
- `GuestSessionController`
- `RitualProgressController`
- `BackgroundGeofenceController`
- `AdaptiveScheduleController`
- `GeofenceProvider`
- `SaiProvider`
- `RecommendationController`

## Error Handling
No behavioral changes.

Existing error and fallback states must remain visible:
- GPS pending
- outside/inside/paused Tawaf state
- recommendation loading/empty/cached/sync note
- adaptive scheduling error text
- locked ritual steps

## Accessibility And Responsiveness
- Text must fit on mobile-width Flutter web and Android layouts.
- Buttons and command chips must not overflow horizontally.
- Simulator overlays must not block critical map usage or each other.
- Bottom command bars may scroll horizontally only where necessary.
- Status labels must be understandable without relying on color alone.

## Testing
Automated checks after implementation:
- `dart format`
- `flutter analyze --no-pub`
- `flutter test --no-pub`

Manual smoke test after implementation:
- Welcome screen renders with all three actions.
- Guest entry reaches Dashboard.
- Dashboard opens Tawaf and Sa'i according to current ritual progression rules.
- Tawaf: set Kaabah, simulate Enter, Exit, Next Round, ML sheet, guidance sheet.
- Sa'i: pin Safa, pin Marwa, Reach Target, ML sheet, guidance sheet.
- Verify overlays do not hide important controls on narrow width.

## Acceptance Criteria
- Core demo flow looks visually consistent and presentation-ready.
- No functional requirement regresses.
- No implementation touches admin dashboard, auth forms, profile setup, privacy consent, Firebase, ML API, or provider logic unless required for compile safety.
- Verification commands pass, or any environment-specific blocker is documented clearly.
