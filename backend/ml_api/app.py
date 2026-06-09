from __future__ import annotations

import math
from dataclasses import dataclass
from typing import Literal

import numpy as np
from fastapi import FastAPI, Query
from pydantic import BaseModel, Field
from sklearn.ensemble import RandomForestRegressor


RitualType = Literal["tawaf", "sai"]
AbilityLevel = Literal["low", "medium", "high"]


class PredictionRequest(BaseModel):
    ritualType: RitualType
    age: int = Field(ge=12, le=100)
    abilityLevel: AbilityLevel
    healthConditions: str = ""
    heightCm: float | None = None
    weightKg: float | None = None
    bmi: float | None = None
    currentRadius: float | None = None  # Tawaf distance from Kaabah


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


class CrowdDensityResponse(BaseModel):
    ritualType: RitualType
    crowdLevel: Literal["low", "moderate", "high"]
    densityScore: float
    recommendedWindow: str
    rerouteAdvice: str
    generatedAt: str


@dataclass(frozen=True)
class ModelBundle:
    model: RandomForestRegressor


app = FastAPI(title="MyUmrahGuide ML API")
bundle = ModelBundle(model=RandomForestRegressor(n_estimators=180, random_state=42))


_TAWAF_FALLBACK_RADIUS = 64.0
_TAWAF_MIN_RADIUS = 15.0
_TAWAF_MAX_RADIUS = 75.0
_SAI_FIXED_DISTANCE = 3100.0
_TAWAF_PACE_MULTIPLIER = 0.90
_SAI_PACE_MULTIPLIER = 0.95


def _ability_score(level: AbilityLevel) -> int:
    return {"low": 0, "medium": 1, "high": 2}[level]


def _ritual_score(ritual: RitualType) -> int:
    return 0 if ritual == "tawaf" else 1


def _has_health_condition(value: str) -> int:
    return 1 if value.strip() else 0


def _bmi_factor(bmi: float | None) -> float:
    """BMI factor using CDC BMI categories as a screening reference.
    https://www.cdc.gov/bmi/adult-calculator/bmi-categories.html"""
    if bmi is None:
        return 1.0
    if bmi < 18.5:
        return 0.85
    if bmi < 25.0:
        return 1.0
    if bmi < 30.0:
        return 0.92
    if bmi < 35.0:
        return 0.82
    return 0.72


def _baseline(
    age: int,
    ability: AbilityLevel,
    health: bool,
    ritual: RitualType,
    bmi: float | None = None,
    radius: float | None = None,
) -> tuple[float, float, float, int]:
    age_factor = 0.68 if age >= 60 else 0.8 if age >= 45 else 1.0
    ability_factor = {"low": 0.72, "medium": 0.88, "high": 1.05}[ability]
    health_factor = 0.82 if health else 1.0
    bmi_f = _bmi_factor(bmi)
    body_pace = 1.0 * age_factor * ability_factor * health_factor * bmi_f

    if ritual == "tawaf":
        effective_radius = (
            radius if radius is not None else _TAWAF_FALLBACK_RADIUS
        )
        effective_radius = max(_TAWAF_MIN_RADIUS, min(_TAWAF_MAX_RADIUS, effective_radius))
        distance = 7 * 2 * math.pi * effective_radius
        pace = body_pace * _TAWAF_PACE_MULTIPLIER
    else:
        distance = _SAI_FIXED_DISTANCE
        pace = body_pace * _SAI_PACE_MULTIPLIER

    duration = distance / (pace * 60)
    rest = 8 if body_pace < 0.7 else 10 if body_pace < 0.95 else 14
    return distance, pace, duration, rest


def _crowd_score(hour: int, ritual: RitualType) -> float:
    base = 0.82 if 10 <= hour <= 14 else 0.76 if 19 <= hour <= 23 else 0.58 if 5 <= hour <= 8 else 0.32
    ritual_adjustment = 0.04 if ritual == "tawaf" else 0.0
    return min(round(base + ritual_adjustment, 2), 0.95)


def _crowd_level(score: float) -> Literal["low", "moderate", "high"]:
    if score >= 0.72:
        return "high"
    if score >= 0.45:
        return "moderate"
    return "low"


def _crowd_window(level: str) -> str:
    if level == "high":
        return "Delay if possible; retry during early morning or late night"
    if level == "moderate":
        return "Proceed slowly or wait 30-45 minutes"
    return "Current window is suitable"


def _crowd_advice(ritual: RitualType, level: str) -> str:
    ritual_label = "Sa'i corridor" if ritual == "sai" else "Tawaf area"
    if level == "high":
        return f"{ritual_label} is crowded. Use outer lanes, pause at safe edges, or delay the ritual window."
    if level == "moderate":
        return f"{ritual_label} is moderately crowded. Use steady pacing and avoid dense clusters."
    return f"{ritual_label} crowd pressure is low. Continue with normal pacing."


def _make_training_data() -> tuple[np.ndarray, np.ndarray]:
    rows: list[list[float]] = []
    targets: list[list[float]] = []
    bmi_values = [None, 17.0, 22.0, 27.0, 32.0, 38.0]

    for ritual in ("tawaf", "sai"):
        for age in range(18, 86):
            for ability in ("low", "medium", "high"):
                for health in (False, True):
                    for bmi in bmi_values:
                        radius = None
                        if ritual == "tawaf":
                            for rad in [20.0, 40.0, 64.0]:
                                distance, pace, duration, rest = _baseline(
                                    age, ability, health, ritual, bmi, rad
                                )
                                rows.append([
                                    float(_ritual_score(ritual)),
                                    float(age),
                                    float(_ability_score(ability)),
                                    1.0 if health else 0.0,
                                    float(bmi) if bmi is not None else 22.0,
                                    float(rad),
                                ])
                                targets.append([distance, pace, duration, float(rest)])
                        else:
                            distance, pace, duration, rest = _baseline(
                                age, ability, health, ritual, bmi
                            )
                            rows.append([
                                float(_ritual_score(ritual)),
                                float(age),
                                float(_ability_score(ability)),
                                1.0 if health else 0.0,
                                float(bmi) if bmi is not None else 22.0,
                                0.0,  # radius not used for sai
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
    if payload.bmi is None and payload.heightCm is not None and payload.weightKg is not None:
        computed_bmi = payload.weightKg / ((payload.heightCm / 100) ** 2)
    else:
        computed_bmi = payload.bmi

    features = np.array([[
        float(_ritual_score(payload.ritualType)),
        float(payload.age),
        float(_ability_score(payload.abilityLevel)),
        float(_has_health_condition(payload.healthConditions)),
        float(computed_bmi) if computed_bmi is not None else 22.0,
        float(payload.currentRadius) if payload.currentRadius is not None else 0.0,
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


@app.get("/crowd-density", response_model=CrowdDensityResponse)
def crowd_density(
    ritualType: RitualType = Query(default="tawaf"),
    hour: int | None = Query(default=None, ge=0, le=23),
) -> CrowdDensityResponse:
    from datetime import datetime, timezone

    generated_at = datetime.now(timezone.utc)
    effective_hour = generated_at.hour if hour is None else hour
    score = _crowd_score(effective_hour, ritualType)
    level = _crowd_level(score)
    return CrowdDensityResponse(
        ritualType=ritualType,
        crowdLevel=level,
        densityScore=score,
        recommendedWindow=_crowd_window(level),
        rerouteAdvice=_crowd_advice(ritualType, level),
        generatedAt=generated_at.isoformat(),
    )
