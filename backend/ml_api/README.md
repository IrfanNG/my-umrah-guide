# MyUmrahGuide ML API

Local FastAPI service for Phase 2 recommendation demos.

## Run

```powershell
cd backend/ml_api
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements.txt
uvicorn app:app --reload --host 127.0.0.1 --port 8000
```

## Predict

```json
POST /predict
{
  "ritualType": "tawaf",
  "age": 65,
  "abilityLevel": "low",
  "healthConditions": "knee pain"
}
```
