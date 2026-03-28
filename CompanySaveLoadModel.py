import joblib

# Save model
model_name = "Company_SalesForecast_Model_v1.pkl"
joblib.dump(model, f"models/{model_name}")

# Load model
model = joblib.load(f"models/{model_name}")
