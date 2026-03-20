<#
#Requires -Version 5.1
.SYNOPSIS
    VBAF Tutorial 06 - Your First Regression Model
    Beginner Series | Estimated time: 20 minutes
.DESCRIPTION
    Learn how to:
      - Understand the difference between classification and regression
      - Train a Linear Regression model
      - Evaluate with R2, RMSE and MAE
      - Compare multiple regression models
      - Understand when to use Ridge vs Linear vs Decision Tree
    Run this script section by section in PowerShell ISE
    or paste blocks into the PS console.
#>

# ============================================================
# SECTION 1: Load the framework
# ============================================================
. .\VBAF.LoadAll.ps1

Write-Host "=== VBAF Tutorial 06: Your First Regression Model ===" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# SECTION 2: What is regression?
# ============================================================
# TEACHING: Classification predicts a CATEGORY (Setosa/Versicolor)
#           Regression predicts a NUMBER (house price, temperature)
#           Same workflow — different models and metrics!

Write-Host "--- What are we predicting? ---" -ForegroundColor Yellow
Write-Host "  Task    : Predict house prices from size, bedrooms, age" -ForegroundColor White
Write-Host "  Input X : [size_sqm, bedrooms, age_years]" -ForegroundColor White
Write-Host "  Output y: price in 1000s (a number, not a category)" -ForegroundColor White
Write-Host ""

# ============================================================
# SECTION 3: Load dataset
# ============================================================
$data = Get-VBAFDataset -Name "HousePrice"

Write-Host "Dataset loaded!" -ForegroundColor Green
Write-Host "  Samples  : $($data.X.Length)" -ForegroundColor White
Write-Host "  Features : $($data.Features -join ', ')" -ForegroundColor White
Write-Host ""

# ============================================================
# SECTION 4: Explore the data
# ============================================================
Write-Host "--- Data Summary ---" -ForegroundColor Yellow
Get-DataSummary -X $data.X -y $data.y -FeatureNames $data.Features

Write-Host ""
Write-Host "--- Feature Correlations with Price ---" -ForegroundColor Yellow
Get-FeatureCorrelations -X $data.X -y $data.y -FeatureNames $data.Features
Write-Host ""

# ============================================================
# SECTION 5: Split and scale
# ============================================================
# TEACHING: Always scale before regression!
# Features on different scales (sqm vs age) confuse the model.

$scaler = [StandardScaler]::new()
$Xs     = $scaler.FitTransform($data.X)
$split  = Split-TrainTest -X $Xs -y $data.y -TestSize 0.2 -Seed 42

Write-Host "Train samples: $($split.XTrain.Length)" -ForegroundColor White
Write-Host "Test  samples: $($split.XTest.Length)"  -ForegroundColor White
Write-Host ""

# ============================================================
# SECTION 6: Train a Linear Regression model
# ============================================================
# TEACHING: Linear Regression fits a straight line through the data.
# Formula: price = w1*size + w2*bedrooms + w3*age + bias
# Simple, fast, interpretable — always try this first!

Write-Host "--- Training Linear Regression ---" -ForegroundColor Yellow
$lr = [LinearRegression]::new()
$lr.Fit($split.XTrain, $split.yTrain)

$preds   = $lr.Predict($split.XTest)
$metrics = Get-RegressionMetrics $split.yTest $preds

Write-Host "Results:" -ForegroundColor Green
Write-Host ("  R2   : {0:F4}  (1.0 = perfect, 0.0 = no better than mean)" -f $metrics.R2)   -ForegroundColor White
Write-Host ("  RMSE : {0:F2}  (average error in same units as target)"      -f $metrics.RMSE) -ForegroundColor White
Write-Host ("  MAE  : {0:F2}  (median error in same units as target)"       -f $metrics.MAE)  -ForegroundColor White
Write-Host ""

# ============================================================
# SECTION 7: Compare regression models
# ============================================================
# TEACHING: Always compare against baselines!
# Ridge adds regularisation — reduces overfitting on small datasets.
# Decision Tree can capture non-linear patterns.

Write-Host "=== Regression Model Comparison ===" -ForegroundColor Cyan
Write-Host ""

$models = @(
    @{ Name="LinearRegression";      Model=[LinearRegression]::new() },
    @{ Name="RidgeRegression(0.01)"; Model=[RidgeRegression]::new(0.01) },
    @{ Name="RidgeRegression(1.0)";  Model=[RidgeRegression]::new(1.0) },
    @{ Name="DecisionTree(d=3)";     Model=[DecisionTree]::new("regression", 3, 2) },
    @{ Name="DecisionTree(d=5)";     Model=[DecisionTree]::new("regression", 5, 2) }
)

foreach ($m in $models) {
    $m.Model.Fit($split.XTrain, $split.yTrain)
    $p   = $m.Model.Predict($split.XTest)
    $met = Get-RegressionMetrics $split.yTest $p
    $bar = "█" * [int]([Math]::Max(0, $met.R2) * 20)
    Write-Host ("  {0,-25} R2={1:F4}  RMSE={2:F2}  {3}" -f $m.Name, $met.R2, $met.RMSE, $bar) -ForegroundColor White
}

Write-Host ""
Write-Host "=== Key Takeaways ===" -ForegroundColor Cyan
Write-Host "  R2 close to 1.0  = model explains most of the variance" -ForegroundColor White
Write-Host "  R2 close to 0.0  = model is no better than predicting the mean" -ForegroundColor White
Write-Host "  R2 negative      = model is WORSE than predicting the mean!" -ForegroundColor White
Write-Host "  RMSE/MAE         = error in the same units as your target" -ForegroundColor White
Write-Host ""
Write-Host "  When to use Ridge: small datasets, many features, overfitting" -ForegroundColor Yellow
Write-Host "  When to use Tree : non-linear relationships, mixed feature types" -ForegroundColor Yellow
Write-Host "  Always try Linear first — simple wins when data is linear!" -ForegroundColor Yellow
Write-Host ""
Write-Host "Tutorial 06 complete! Try Tutorial 07 next: Clustering." -ForegroundColor Green
