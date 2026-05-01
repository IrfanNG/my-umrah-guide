# Mish Umrah Guide: Requirement & Progress Checklist
*Based on Methodchap3.pdf (DSR & Agile Framework)*

Legend:
- `[x]` done in the current system
- `[~]` partially implemented
- `[ ]` pending

## Phase 1: Core Geofencing & Simulation Engine
*Objective: Stabilize location tracking, map rendering, and basic geofence boundaries.*

- [x] **Geofence Engine Initialization**: Setup `geolocator` stream and base provider.
- [x] **Tawaf Zone Configuration**: Set strict 75m radius for Mataf/Tawaf area.
- [x] **Web/Emulator Stabilization**: Fix `AbortError`, tile buffering, and viewport scaling.
- [x] **GPS Optimization**: Implement 0.5m movement throttle to prevent UI jitter/infinite loops.
- [x] **Instant Pinning UX**: Use cached position for 0-delay manual Kaabah pinning.
- [x] **Auto-Follow Camera**: Map smoothly tracks user movement during Tawaf and Sa'i.
- [x] **Local Notifications (Basic)**: Trigger alerts on Entry/Exit of Tawaf Zone, Miqat, Tawaf rounds, and Sa'i progress.
- [x] **Sa'i Zone Implementation**: Configure Safa & Marwa points with target radius and corridor visualization.
- [x] **Miqat Detection**: Configure 150m early detection zone and guidance trigger.

---

## Phase 2: Dual-Mode Architecture & Ritual Progression (Current Focus)
*Objective: Enforce the rules of Umrah based on the user's selected mode.*

- [x] **Firebase Email/Password Login**: Replace guest-only entry with registration, login, logout, and auth-state routing.
- [x] **User Profile Foundation**: Collect age, ability level, and optional health condition notes for recommendation logic.
- [x] **Mode Selection State**: Toggle between `Manual` and `Location-Based`.
- [x] **Manual Mode Logic**: Manual mode unlocks Miqat, Tawaf, and Sa'i for demo/revision flow.
- [x] **Location-Based Enforcement**:
  - [x] Block Tawaf access until Miqat/Niyyah is cleared.
  - [x] Block Sa'i access until Tawaf checkpoint is completed.
- [x] **Tawaf Persistence & Recovery**: If user exits radius, prompt `Continue/End`; save state when pausing and allow restore.
- [x] **Sa'i Trip Logic**: User must reach both Safa and Marwa to count as 1 lap.
- [x] **Ritual Guidance UI**: Auto-display contextual Du'a, Niyyah, and step-by-step instructions when a geofence/ritual event is triggered.
- [x] **ML Recommendation Panel**: Show personalized Tawaf and Sa'i distance, pace, time, and rest suggestions based on profile.

---

## Phase 3: Backend Integration (Firebase + Local ML API)
*Objective: Connect the Flutter frontend to Firebase data services and the local Random Forest recommendation API.*

- [x] **Firebase Project Binding**: Existing `.firebaserc` targets `myumrahguide-nisa`; `firebase.json` now includes Firestore rules.
- [x] **Firebase App Configuration**: Web and Android Firebase apps registered; Flutter web/android options added.
- [x] **Auth & Profile Module**: Firebase Auth email/password plus Firestore `users/{uid}` profile storage.
- [x] **Recommendation Storage**: Save recommendation snapshots under `recommendations`.
- [x] **Session Analytics Logging**: Save completed Tawaf/Sa'i analytics under `ritual_sessions`.
- [x] **Firestore Security Rules**: Restrict users to their profile/recommendations and admin-only analytics reads.
- [x] **Local Random Forest API**: FastAPI + scikit-learn service scaffolded under `backend/ml_api`.
- [~] **Offline Caching**: Tawaf progress is cached locally with `shared_preferences`; mode preferences and backend sync caching are not implemented.

---

## Phase 4: Advanced Optimizations & Polish (FYP2 Prep)
*Objective: Ensure production readiness, battery efficiency, and edge-case handling.*

- [ ] **Background Geofencing**: Integrate native Android/iOS background tracking for battery efficiency.
- [ ] **Adaptive Scheduling**: Fetch crowd density API to suggest rerouting.
- [ ] **Privacy & Consent**: Implement PDPA/GDPR compliant location permission onboarding.
- [~] **UI Polish (Rank S)**: Mecca Gold, Zinc-50, dashboard, simulator cards, and guidance sheets exist; final consistency pass is still pending.
- [x] **Admin Analytics Dashboard**: Aggregate-only Flutter admin screen with age distribution, pace by age group, distance by ability, and pace-vs-distance graph.
- [x] **Seeded Demo Analytics**: Admin can seed demo aggregate session data for FYP presentation.

---

## Implementation Evidence From Current System

- `lib/features/practice/presentation/geofence_provider.dart`: Tawaf 75m geofence, Miqat 150m detection, GPS throttling, notifications, Tawaf lap state, pause/recovery, and local persistence.
- `lib/features/practice/presentation/pages/tawaf_simulator_view.dart`: Tawaf map, manual Kaabah pinning, Enter/Exit/Next simulation controls, recovery dialog, guidance bottom sheet, and auto-follow camera.
- `lib/features/practice/presentation/sai_provider.dart`: Safa/Marwa target tracking, pair-based Sa'i lap logic, notifications, guidance queue, and reset logic.
- `lib/features/practice/presentation/pages/sai_simulator_view.dart`: Sa'i map, Safa/Marwa pinning, target banner, lap progress UI, and simulation controls.
- `lib/features/practice/presentation/guidance/ritual_guidance.dart`: Miqat, Tawaf, and Sa'i contextual guidance content.
- `test/geofence_provider_test.dart`: Covers Tawaf pause/recovery, save/restore, completion cleanup, and guidance behavior.
- `test/sai_provider_test.dart`: Covers Sa'i pair logic, completion, reset, and guidance behavior.
- `lib/features/practice/data/`: Firebase Auth, profile, recommendation, and analytics repositories.
- `lib/features/practice/presentation/pages/admin_dashboard_view.dart`: Aggregate-only admin analytics dashboard.
- `backend/ml_api/app.py`: Local Random Forest prediction API.
- `lib/features/practice/presentation/ritual_progress_controller.dart`: Persisted Manual/Location-Based mode and ritual checkpoint enforcement.
- `test/ritual_progress_controller_test.dart`: Covers Manual unlocks, Location-Based locking, checkpoint persistence, and reset.

## Verification Notes

- `flutter analyze --no-pub` passed with no issues.
- `flutter test --no-pub` passed all tests.
- `flutter build web --no-pub` passed.
- `python -m py_compile backend\ml_api\app.py` passed.
- Firebase deploy completed: Firestore API enabled, default Firestore database created, Firestore rules released, and Email/Password auth provider enabled.
- Windows Flutter plugin symlink support still requires Developer Mode for normal plugin builds if not already enabled.

---

*Last Updated: 01 May 2026 by Jargon (Squad)*
