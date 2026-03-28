import pandas as pd
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_absolute_error
import joblib  # Ensure this line is included to import joblib

# Example data
data = pd.DataFrame({
    'Metric1': [100, 200, 300, 400],
    'Metric2': [10, 20, 30, 40],
    'Target': [1, 0, 1, 0]
})

# Split data
X = data[['Metric1', 'Metric2']]
y = data['Target']
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=0)

# Train the model
model = RandomForestRegressor()
model.fit(X_train, y_train)

# Evaluate the model
predictions = model.predict(X_test)
mae = mean_absolute_error(y_test, predictions)
print(f"Mean Absolute Error: {mae}")

# Save the model as 'Company_Prediction_Model.pkl'
joblib.dump(model, 'Company_Prediction_Model.pkl')  # This line saves the model

# Start with >> python
 
# $wpPath = "C:\Users\Henning\OneDrive\Personlige\WindowsPowerShell"
# cd $wpPath
# python CompanyModelTraining.py     OBS
# End with >>  exit()

 


 


 


