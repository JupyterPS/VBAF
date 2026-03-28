function CompanyGetPrediction {
    param (
        [int]$metric1,
        [int]$metric2
    )
    Write-Host "CompanyGetPrediction function loaded."

    # Command to call Python with DataFrame containing feature names
    $command = "python -c ""import joblib; model = joblib.load('Company_Prediction_Model.pkl'); import pandas as pd; data = pd.DataFrame([[ $metric1, $metric2 ]], columns=['Metric1', 'Metric2']); print(model.predict(data)[0])"""

    # Execute the command
    $prediction = & cmd /c $command

    Write-Host "Prediction result: $prediction"
}

CompanyGetPrediction -metric1 200 -metric2 20


 
 






