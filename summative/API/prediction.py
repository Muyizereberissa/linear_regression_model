
from fastapi import FastAPI
from pydantic import BaseModel, Field
from fastapi.middleware.cors import CORSMiddleware
import numpy as np
import joblib
import os

app = FastAPI()


origins = [
    "http://localhost",
    "http://127.0.0.1:3000"
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


MODEL_PATH = "../linear_regression/best_climate_model.pkl"
SCALER_PATH = "../linear_regression/scaler.pkl"

model = None
scaler = None



@app.on_event("startup")
def load_model_and_scaler():
    global model, scaler
    if os.path.exists(MODEL_PATH):
        model = joblib.load(MODEL_PATH)
        print(f"Loaded model from {MODEL_PATH}")
    if os.path.exists(SCALER_PATH):
        scaler = joblib.load(SCALER_PATH)
        print(f"Loaded scaler from {SCALER_PATH}")


class ClimateInput(BaseModel):
    CO2: float = Field(..., ge=0, le=50)
    Sea_Level: float = Field(..., ge=0, le=100)
    Rainfall: float = Field(..., ge=0, le=5000)
    Population: int = Field(..., ge=1000, le=1_000_000_000)
    Renewable: float = Field(..., ge=0, le=100)
    Extreme_Weather: int = Field(..., ge=0, le=1000)
    Forest: float = Field(..., ge=0, le=100)


@app.post("/predict")
def predict(data: ClimateInput):
    global model, scaler
    if model is None:
        return {"error": "Model not loaded. Please provide a trained model first."}

    features = np.array([[data.CO2, data.Sea_Level, data.Rainfall,
                          data.Population, data.Renewable,
                          data.Extreme_Weather, data.Forest]])

    if scaler is not None:
        features = scaler.transform(features)

    prediction = model.predict(features)
    return {"predicted_temperature": float(prediction[0])}


class RetrainInput(BaseModel):
    data: list[ClimateInput]  
    target: list[float]       

@app.post("/retrain")
def retrain_model(payload: RetrainInput):
    global model, scaler
    import pandas as pd
    from sklearn.linear_model import LinearRegression
    from sklearn.preprocessing import StandardScaler


    df = pd.DataFrame([vars(d) for d in payload.data])
    y = pd.Series(payload.target)

    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(df)

    model = LinearRegression()
    model.fit(X_scaled, y)

 
    joblib.dump(model, MODEL_PATH)
    joblib.dump(scaler, SCALER_PATH)

    return {"message": "Model retrained successfully", "num_samples": len(df)}