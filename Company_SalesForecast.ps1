function Get-SalesForecast {
    param (
        [int]$year,
        [int]$month,
        [int]$day,
        [int]$product_encoded,  # Use encoded value
        [int]$region_encoded,   # Use encoded value
        [int]$metric1 = 0,
        [int]$metric2 = 0,
        [int]$metric3 = 0,
        [int]$metric4 = 0,
        [int]$metric5 = 0,
        [int]$metric6 = 0
    )
    
    Write-Host "Get-SalesForecast function loaded."

    # Command with encoded values for product and region
    $command = "python -c `"import joblib; model = joblib.load('Company_SalesForecast_Model.pkl'); print(model.predict([[ $year, $month, $day, $product_encoded, $region_encoded, $metric1, $metric2, $metric3, $metric4, $metric5, $metric6 ]])[0])`""
    $forecast = & cmd /c $command

    Write-Host "Sales Forecast for $($year)-$($month)-$($day) (Encoded Product: $product_encoded in Encoded Region: $region_encoded): $forecast"
}

# Example usage with encoded values
Get-SalesForecast -year 2024 -month 5 -day 15 -product_encoded 1 -region_encoded 2 -metric1 100 -metric2 200 -metric3 300 -metric4 400 -metric5 500 -metric6 600

# OBS OBS Gives a warning BUT that's OK






