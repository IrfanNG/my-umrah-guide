# MyUmrahGuide

MyUmrahGuide is a Flutter-based Umrah practice and guidance app for FYP demonstration, combining geofencing simulation, ritual progression, Firebase authentication, offline caching, and ML-assisted Tawaf/Sa'i recommendations.

## Quick Start

```bash
git clone https://github.com/IrfanNG/my-umrah-guide.git
cd my-umrah-guide
flutter pub get
flutter run -d chrome
```

For local ML recommendations and crowd-density demo data:

```bash
cd backend/ml_api
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\Activate.ps1
pip install -r requirements.txt
uvicorn app:app --reload --host 127.0.0.1 --port 8000
```

## Features

- Firebase email/password login, registration, logout, guest entry, and auth-state routing.
- Manual and Location-Based ritual modes for demo practice or GPS-gated access.
- Tawaf simulator with OpenStreetMap, Kaabah radius detection, pause/resume recovery, notifications, and auto-lap tracking.
- Sa'i simulator with Safa/Marwa target detection and pair-based lap counting.
- Ritual access enforcement: Miqat/Niyyah before Tawaf, Tawaf completion before Sa'i.
- Contextual ritual guidance sheets for Niyyah, Tawaf, Sa'i, and geofence events.
- ML recommendation panel for pace, distance, time, and rest suggestions based on profile data.
- Offline caching for progress, mode selection, recommendations, and pending backend sync writes.
- Admin analytics dashboard with aggregate ritual session insights for FYP presentation.

## Tech Stack

| Layer | Tools |
|---|---|
| App | Flutter, Dart, Provider, Material 3 |
| Maps & Location | `flutter_map`, OpenStreetMap, `geolocator`, `latlong2` |
| Backend | Firebase Auth, Cloud Firestore, Firestore Rules |
| Local ML API | FastAPI, scikit-learn, Uvicorn |
| Storage | `shared_preferences`, Firestore |
| Charts | `fl_chart` |

## Project Structure

```text
lib/
  core/services/                 # notification service
  features/practice/data/        # Firebase, analytics, profile, offline sync, ML clients
  features/practice/domain/      # ritual/profile/recommendation models
  features/practice/presentation/# controllers, providers, UI pages, widgets
backend/ml_api/                  # local FastAPI ML and crowd-density API
docs/                            # requirement checklist and design references
test/                            # provider/controller/repository tests
```

## Usage

### Run Flutter web

```bash
flutter pub get
flutter run -d chrome
```

### Run checks

```bash
flutter analyze --no-pub
flutter test --no-pub
flutter build web --no-pub
python -m py_compile backend/ml_api/app.py
```

### Firebase

The project is configured for Firebase project `myumrahguide-nisa`.

```bash
firebase deploy --only firestore:rules
```

Email/password authentication must be enabled in Firebase Console before login/register flows are used.

## ML API Reference

### `POST /predict`

```json
{
  "ritualType": "tawaf",
  "age": 65,
  "abilityLevel": "low",
  "healthConditions": "knee pain"
}
```

Returns demo recommendation data for ritual distance, pace, estimated time, and rest guidance.

### `GET /crowd-density`

```text
/crowd-density?ritualType=tawaf
/crowd-density?ritualType=sai&hour=13
```

Returns demo-safe crowd level, density score, recommended timing window, and rerouting advice.

## Notes

- For Flutter web after adding plugins, stop the running app fully before `flutter clean`, `flutter pub get`, and rerun.
- Windows plugin builds may require Developer Mode for symlink support.
- Local ML API is intended for FYP demo use, not production deployment.

## License

Private academic/client project. All rights reserved unless a separate license is added.
