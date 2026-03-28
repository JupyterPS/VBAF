import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_absolute_error
import joblib

# Load data
data = pd.read_csv('Company_SalesData.csv')  # Adjust the filename if needed

# Define features (X) and target (y)
X = data[['Date', 'Product', 'Region']]  # Example feature columns; adjust as necessary
y = data['SalesAmount']  # Target column

# Preprocess and split data (this may require encoding for categorical data in X)
X = pd.get_dummies(X)  # One-hot encode categorical columns if needed
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=0)

# Train model
model = RandomForestRegressor(random_state=0)
model.fit(X_train, y_train)

# Evaluate model
predictions = model.predict(X_test)
mae = mean_absolute_error(y_test, predictions)
print(f"Mean Absolute Error: {mae}")

# Save the model
joblib.dump(model, 'Company_SalesForecast_Model.pkl')
print("Model saved as Company_SalesForecast_Model.pkl") 
 
# $wpPath = "C:\Users\Henning\OneDrive\Personlige\WindowsPowerShell"
# cd $wpPath
# python CompanyTrainSalesForecastModel.py

 
 