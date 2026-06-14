# MyUmrahGuide Code Guide

Panduan ringkas untuk tahu **UI dekat file mana** dan **function utama app dekat mana**.

## Struktur utama

| Bahagian | Folder/File | Fungsi |
|---|---|---|
| App start + route | `lib/main.dart` | Setup Firebase, Provider state, theme, dan route screen. |
| UI pages | `lib/features/practice/presentation/pages/` | Semua screen utama app. |
| Shared UI style | `lib/features/practice/presentation/widgets/practice_ui.dart` | Warna, card style, button style, chip, distance formatter. |
| ML suggestion UI | `lib/features/practice/presentation/widgets/recommendation_panel.dart` | Bottom sheet ML suggestion untuk Tawaf/Sa'i. |
| App logic/state | `lib/features/practice/presentation/*controller.dart` + providers | Logic yang UI guna melalui Provider. |
| Data/Firebase/API | `lib/features/practice/data/` | Auth, Firestore profile/session, ML API, offline cache. |
| Model/data shape | `lib/features/practice/domain/` | Class data macam user profile, recommendation, ritual mode. |

## UI file map

| Screen/UI | File |
|---|---|
| Login / guest entry | `pages/login_guest_view.dart` |
| Login form | `pages/login_form_view.dart` |
| Register | `pages/register_view.dart` |
| Auth route checker | `pages/auth_gate.dart` |
| Privacy consent | `pages/privacy_consent_view.dart` |
| Profile setup | `pages/profile_setup_view.dart` |
| Dashboard | `pages/dashboard_view.dart` |
| Tawaf simulator | `pages/tawaf_simulator_view.dart` |
| Sa'i simulator | `pages/sai_simulator_view.dart` |
| Session history | `pages/session_history_view.dart` |
| Admin dashboard | `pages/admin_dashboard_view.dart` |
| Ritual guidance bottom sheet | `guidance/ritual_guidance_sheet.dart` |

## Function / logic map

| Feature | File | Main role |
|---|---|---|
| Tawaf GPS, Kaabah pin, distance, zone status, lap count | `geofence_provider.dart` | Handles Tawaf live tracking. |
| Sa'i GPS, Safa/Marwa pins, next target, lap count, distance | `sai_provider.dart` | Handles Sa'i live tracking. |
| Login/register/logout state | `auth_controller.dart` | Connects UI to auth repository. |
| Guest mode | `guest_session_controller.dart` | Allows app use without login. |
| User profile form/state | `profile_controller.dart` | Stores age, ability, health, BMI data. |
| Manual vs location mode + ritual lock | `ritual_progress_controller.dart` | Controls access: Niyyah → Tawaf → Sa'i. |
| ML suggestion + session logging | `recommendation_controller.dart` | Gets recommendation and saves completed sessions. |
| Privacy consent | `privacy_consent_controller.dart` | Checks if location consent accepted. |
| Adaptive crowd schedule | `adaptive_schedule_controller.dart` | Gets crowd-density timing advice. |
| Background geofence setting | `background_geofence_controller.dart` | Stores foreground/background tracking preference. |

## Data / backend file map

| Data feature | File |
|---|---|
| Firebase Auth | `data/auth_repository.dart` |
| Firestore user profile | `data/profile_repository.dart` |
| ML recommendation API + local fallback | `data/recommendation_repository.dart` |
| Session analytics/history | `data/analytics_repository.dart` |
| Offline cache + pending sync queue | `data/offline_sync_store.dart` |
| Crowd density API/fallback | `data/crowd_density_repository.dart` |

## Recent distance feature

| Item | File | Notes |
|---|---|---|
| Format distance text | `widgets/practice_ui.dart` | `PracticeUi.formatDistance()` returns `42 m`, `1.25 km`, or `Jarak belum tersedia`. |
| Tawaf distance to Kaabah | `pages/tawaf_simulator_view.dart` | Shows `Jarak ke Kaabah` inside Tawaf Rounds card. Uses `geofence.distance`. |
| Sa'i distance to Safa/Marwa | `sai_provider.dart` | `distanceToNextTarget` calculates distance to active next target. |
| Sa'i distance UI | `pages/sai_simulator_view.dart` | Shows `Jarak ke MARWA/SAFA` inside Sa'i Laps card. |
| Sa'i distance tests | `test/sai_provider_test.dart` | Tests null state, distance available, and target switch. |

## Flow ringkas app

1. `main.dart` starts app, initializes Firebase, registers Providers.
2. `AuthGate` decides user masuk dashboard, profile setup, login, or admin.
3. Dashboard opens Tawaf or Sa'i simulator.
4. Simulator UI reads Provider state:
   - Tawaf reads `GeofenceProvider`.
   - Sa'i reads `SaiProvider`.
5. ML sheet reads `RecommendationController`.
6. Completed ritual session is logged for history.

## Kalau nak ubah UI

- Ubah screen-specific layout dalam `pages/[screen_name].dart`.
- Ubah reusable style/card/chip/button dalam `widgets/practice_ui.dart`.
- Ubah ML bottom sheet dalam `widgets/recommendation_panel.dart`.
- Jangan letak business logic berat dalam UI file; letak dalam provider/controller.

## Kalau nak ubah function

- Tawaf logic → `geofence_provider.dart`.
- Sa'i logic → `sai_provider.dart`.
- Login/profile/history/ML → controller dulu, then repository kalau involve Firebase/API.
- Add/update tests dalam `test/` ikut feature yang diubah.

## Verification biasa

Run sebelum commit:

```bash
flutter analyze --no-pub
flutter test --no-pub
```
