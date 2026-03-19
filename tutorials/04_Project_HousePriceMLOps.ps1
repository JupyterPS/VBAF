<#
#Requires -Version 5.1
.SYNOPSIS
    VBAF Tutorial 04 - Real-World Project: House Price MLOps
    Real-World Projects | Estimated time: 45 minutes
.DESCRIPTION
    A complete real-world ML project from raw data to production:
      - Problem definition
      - Exploratory data analysis (EDA)
      - Feature engineering
      - Experiment tracking
      - Model training and comparison
      - Drift monitoring
      - Automated retraining policy
    This is how a professional ML engineer would approach the problem!
#>

Write-Host ""
Write-Host "+--------------------------------------------------+" -ForegroundColor Cyan
Write-Host "¦  VBAF Tutorial 04 - House Price MLOps Project    ¦" -ForegroundColor Cyan
Write-Host "¦  From raw data to monitored production model     ¦" -ForegroundColor Cyan
Write-Host "+--------------------------------------------------+" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# PROBLEM DEFINITION
# ============================================================
# Goal: predict house prices given size, bedrooms and age.
# Success metric: R2 >= 0.95 on held-out test set.
# Production requirement: retrain if R2 drops below 0.90.
# ============================================================

# ============================================================
# STEP 1: Exploratory Data Analysis
# ============================================================
Write-Host "--- Step 1: Exploratory Data Analysis ---" -ForegroundColor Yellow

$data = Get-VBAFDataset -Name "HousePrice"
Get-DataSummary -X $data.X -y $data.y -FeatureNames $data.Features

# Feature correlations with target
Write-Host "Feature correlations with price:" -ForegroundColor Cyan
Get-FeatureCorrelations -X $data.X -y $data.y -FeatureNames $data.Features

# ============================================================
# STEP 2: Set up experiment tracking
# ============================================================
Write-Host "--- Step 2: Experiment Tracking ---" -ForegroundColor Yellow

New-VBAFExperiment -Name "HousePriceMLOps" `
    -Description "Predict house prices - production model" | Out-Null

$scaler = [StandardScaler]::new()
$Xs     = $scaler.FitTransform($data.X)
$split  = Split-TrainTest -X $Xs -y $data.y -TestSize 0.2 -Seed 42

# ============================================================
# STEP 3: Baseline model
# ============================================================
Write-Host "--- Step 3: Baseline Model ---" -ForegroundColor Yellow

Start-VBAFRun -RunName "baseline_linear" -ModelType "LinearRegression" `
    -Params @{ scaler="Standard"; testSize=0.2 } | Out-Null

$baseline = [LinearRegression]::new()
$baseline.Fit($split.TrainX, $split.TrainY)
$basePreds   = $baseline.Predict($split.TestX)
$baseMetrics = Get-RegressionMetrics $split.TestY $basePreds

Set-VBAFRunMetric -Key "R2"   -Value $baseMetrics.R2
Set-VBAFRunMetric -Key "RMSE" -Value $baseMetrics.RMSE
Stop-VBAFRun

# ============================================================
# STEP 4: Improved model with Ridge + polynomial features
# ============================================================
Write-Host "--- Step 4: Improved Model ---" -ForegroundColor Yellow

Start-VBAFRun -RunName "ridge_poly2" -ModelType "RidgeRegression" `
    -Params @{ scaler="Standard"; poly=2; lambda=0.01 } | Out-Null

$poly    = [PolynomialFeatures]::new(2)
$trainXp = $poly.FitTransform($split.TrainX, $data.Features)
$testXp  = $poly.FitTransform($split.TestX,  $data.Features)

$improved = [RidgeRegression]::new(0.01)
$improved.Fit($trainXp, $split.TrainY)
$impPreds   = $improved.Predict($testXp)
$impMetrics = Get-RegressionMetrics $split.TestY $impPreds

Set-VBAFRunMetric -Key "R2"   -Value $impMetrics.R2
Set-VBAFRunMetric -Key "RMSE" -Value $impMetrics.RMSE
Set-VBAFRunTag    -Key "promoted" -Value "true"
Stop-VBAFRun

# ============================================================
# STEP 5: Compare runs
# ============================================================
Write-Host "--- Step 5: Compare Experiments ---" -ForegroundColor Yellow
Compare-VBAFRuns -ExperimentName "HousePriceMLOps"

# ============================================================
# STEP 6: Save winning model to registry
# ============================================================
Write-Host "--- Step 6: Save to Registry ---" -ForegroundColor Yellow

Initialize-VBAFRegistry | Out-Null
Save-VBAFModel `
    -ModelName   "HousePriceProduction" `
    -Model       $improved `
    -ModelType   "RidgeRegression" `
    -Metrics     @{ R2=[Math]::Round($impMetrics.R2,4); RMSE=[Math]::Round($impMetrics.RMSE,2) } `
    -Params      @{ Lambda=0.01; PolyDegree=2 } `
    -DatasetName "HousePrice" `
    -Description "Production model - Ridge + Polynomial features" | Out-Null

# ============================================================
# STEP 7: Set up monitoring and retraining policy
# ============================================================
Write-Host "--- Step 7: Monitoring & Retraining Policy ---" -ForegroundColor Yellow

$policy = New-VBAFRetrainingPolicy `
    -ModelName    "HousePriceProduction" `
    -MinAccuracy  0.90 `
    -MaxDriftPSI  0.20 `
    -MaxAgeDays   30 `
    -MinNewSamples 50

# Simulate drift detection: production data with slightly larger houses
$prodData = @($data.X | ForEach-Object {
    ,@([double]($_[0] * 1.1), [double]$_[1], [double]$_[2])
})
$driftResults = Get-VBAFDriftReport `
    -ReferenceData  $data.X `
    -ProductionData $prodData `
    -FeatureNames   $data.Features
$maxPSI = ($driftResults | ForEach-Object { $_.PSI } | Measure-Object -Maximum).Maximum

# Check if retraining needed
Test-VBAFRetrainingNeeded `
    -Policy            $policy `
    -CurrentAccuracy   $impMetrics.R2 `
    -CurrentMaxPSI     $maxPSI `
    -ModelTrainedDate  (Get-Date).AddDays(-5) `
    -NewSamplesCount   20

# ============================================================
# SUMMARY
# ============================================================
Write-Host ""
Write-Host "+--------------------------------------------------+" -ForegroundColor Green
Write-Host "¦            Project Summary                       ¦" -ForegroundColor Green
Write-Host ("¦  Baseline R2    : {0,-31}¦" -f [Math]::Round($baseMetrics.R2, 4)) -ForegroundColor White
Write-Host ("¦  Improved R2    : {0,-31}¦" -f [Math]::Round($impMetrics.R2, 4))  -ForegroundColor White
Write-Host ("¦  Improvement    : +{0,-30}¦" -f [Math]::Round($impMetrics.R2 - $baseMetrics.R2, 4)) -ForegroundColor White
Write-Host ("¦  Model saved    : HousePriceProduction v1.0.0   ¦") -ForegroundColor White
Write-Host ("¦  Monitoring     : Active ?                     ¦") -ForegroundColor White
Write-Host "+--------------------------------------------------+" -ForegroundColor Green
Write-Host ""
Write-Host "Try Tutorial 05 next: Anomaly Detection project!" -ForegroundColor Cyan
