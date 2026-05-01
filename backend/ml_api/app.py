from __future__ import annotations

from dataclasses import dataclass
from typing import Literal

import numpy as np
from fastapi import FastAPI
from pydantic import BaseModel, Field
from sklearn.ensemble import RandomForestRegressor


RitualType = Literal["tawaf", "sai"]
AbilityLevel = Literal["low", "medium", "high"]


class PredictionRequest(BaseModel):
    ritualType: RitualType
    age: int = Field(ge=12, le=100)
    abilityLevel: AbilityLevel
    healthConditions: str = ""


class PredictionResponse(BaseModel):
    ritualType: RitualType
    distanceMinMeters: float
    distanceMaxMeters: float
    paceMinMps: float
    paceMaxMps: float
    timeMinMinutes: float
    timeMaxMinutes: float
    restEveryMinutes: int
    label: str
    advice: str


@dataclass(frozen=True)
class ModelBundle:
    model: RandomForestRegressor


app = FastAPI(title="MyUmrahGuide ML API")
bundle = ModelBundle(model=RandomForestRegressor(n_estimators=180, random_state=42))


def _ability_score(level: AbilityLevel) -> int:
    return {"low": 0, "medium": 1, "high": 2}[level]


def _ritual_score(ritual: RitualType) -> int:
    return 0 if ritual == "tawaf" else 1


def _has_health_condition(value: str) -> int:
    return 1 if value.strip() else 0


def _baseline(age: int, ability: AbilityLevel, health: bool, ritual: RitualType) -> tuple[float, float, float, int]:
    base_distance = 2800.0 if ritual == "tawaf" else 3100.0
    age_factor = 0.68 if age >= 60 else 0.8 if age >= 45 else 1.0
    ability_factor = {"low": 0.72, "medium": 0.88, "high": 1.05}[ability]
    health_factor = 0.82 if health else 1.0
    pace = 1.0 * age_factor * ability_factor * health_factor
    duration = base_distance / (pace * 60)
    rest = 8 if pace < 0.7 else 12 if pace < 0.9 else 15
    return base_distance, pace, duration, rest


def _make_training_data() -> tuple[np.ndarray, np.ndarray]:
    rows: list[list[float]] = []
    targets: list[list[float]] = []
    for ritual in ("tawaf", "sai"):
        for age in range(18, 86):
            for ability in ("low", "medium", "high"):
                for health in (False, True):
                    distance, pace, duration, rest = _baseline(age, ability, health, ritual)
                    rows.append([
                        float(_ritual_score(ritual)),
                        float(age),
                        float(_ability_score(ability)),
                        1.0 if health else 0.0,
                    ])
                    targets.append([distance, pace, duration, float(rest)])
    return np.array(rows), np.array(targets)


@app.on_event("startup")
def train_model() -> None:
    features, targets = _make_training_data()
    bundle.model.fit(features, targets)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/predict", response_model=PredictionResponse)
def predict(payload: PredictionRequest) -> PredictionResponse:
    features = np.array([[
        float(_ritual_score(payload.ritualType)),
        float(payload.age),
        float(_ability_score(payload.abilityLevel)),
        float(_has_health_condition(payload.healthConditions)),
    ]])
    distance, pace, duration, rest = bundle.model.predict(features)[0]
    label = "Assisted pace" if pace < 0.7 else "Balanced pace" if pace < 0.95 else "Active pace"
    advice = (
        "Move slowly, use frequent short rests, and avoid rushing the ritual."
        if pace < 0.7
        else "Keep a steady rhythm and take a short pause when breathing becomes heavy."
        if pace < 0.95
        else "Maintain a controlled pace and avoid overexertion even if you feel strong."
    )
    return PredictionResponse(
        ritualType=payload.ritualType,
        distanceMinMeters=round(distance * 0.92, 1),
        distanceMaxMeters=round(distance * 1.08, 1),
        paceMinMps=round(pace * 0.88, 2),
        paceMaxMps=round(pace * 1.12, 2),
        timeMinMinutes=round(duration * 0.9, 1),
        timeMaxMinutes=round(duration * 1.2, 1),
        restEveryMinutes=int(round(rest)),
        label=label,
        advice=advice,
    )
