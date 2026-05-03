# Design Spec: Splash + AuthGate Loading (Primary Direction)

## Context
We are polishing the remaining untouched screens in the user journey. This spec covers the Splash screen and the AuthGate loading state, aligned to the Pilgrim Companion Primary Direction (warm gold, soft neutrals, calm premium feel).

## Goals
- Match the Primary Direction mockups and existing Practice UI tokens.
- Keep the flow unchanged (Splash auto-navigates after 2 seconds).
- Improve perceived quality during loading with a premium, calm presentation.

## Non-Goals
- No changes to navigation logic or auth flow.
- No new assets, fonts, or dependencies.
- No changes to Firebase, profile, or consent logic.

## Visual Direction
- Background: warm gradient (gold -> off-white -> soft sage tint).
- Surface: use `PracticeSurfaceCard` and existing tokens for consistency.
- Iconography: mosque icon inside a circular badge.
- Typography: bold title, soft subtitle, calm support line.

## Components
### Splash Screen
- Fullscreen gradient background.
- Centered column with:
  - Logo badge (circular, subtle gold fill, mosque icon).
  - Title: "MyUmrahGuide".
  - Subtitle: "Pilgrim Companion".
  - Optional micro-benefit chips (Trusted, Offline-ready, Safe guidance).
  - Progress indicator + "Preparing your journey..." line.

### AuthGate Loading
- Off-white background.
- Centered `PracticeSurfaceCard` with:
  - Icon badge + title "Syncing your profile".
  - Short supporting line.
  - Linear progress indicator.
  - Status chip ("Secure sync" or similar) using `PracticeStatusChip`.

## Data Flow
- Unchanged. Visual-only adjustments.

## Error Handling
- Unchanged. Loading stays present until auth/profile/consent completes.

## Testing
- Manual verification only:
  - Run app and confirm splash auto-redirect after 2 seconds.
  - Trigger loading by forcing auth state load and verify UI renders.

## Files
- lib/features/practice/presentation/pages/splash_view.dart
- lib/features/practice/presentation/pages/auth_gate.dart
- (Optional) lib/features/practice/presentation/widgets/practice_ui.dart
