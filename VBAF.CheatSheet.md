[← Back to README](README.md)

# VBAF Cheat Sheet — Quick Reference Card
> v4.0.0 · PowerShell 5.1 · All functions, all parameters, all valid values

---

## 1. Load Everything First
```powershell
. .\VBAF.LoadAll.ps1
```

---

## 2. Datasets

```powershell
# Classification datasets
$data = Get-VBAFNBDataset -Name "Iris3Class"
# Returns: $data.X, $data.y, $data.ClassNames, $data.Features

# Regression datasets
$data = Get-VBAFDataset -Name "HousePrice"
# Returns: $data.X, $data.y, $data.Features

# Pipeline datasets (with missing values + outliers)
$data = Get-VBAFPipelineDataset -Name "MessyHousePrice"
# Returns: $data.X, $data.y, $data.Features

# Available names:
# Classification : "Iris3Class"
# Regression     : "HousePrice"
# Pipeline       : "MessyHousePrice"
```

---

## 3. Train/Test Split

```powershell
$split = Split-TrainTest -X $data.X -y $data.y -TestSize 0.2 -Seed 42
# Parameters:
#   -X          double[][]   feature matrix
#   -y          double[]     target array
#   -TestSize   double       fraction for test (default 0.2)
#   -Seed       int          random seed for reproducibility

# Returns hashtable — use these exact keys:
$split.XTrain    # training features
$split.yTrain    # training labels
$split.XTest     # test features
$split.yTest     # test labels
```

---

## 4. Scalers / Preprocessors

```powershell
# StandardScaler — zero mean, unit variance
$scaler = [StandardScaler]::new()
$Xs     = $scaler.FitTransform($X)        # fit + transform training data
$Xtest  = $scaler.Transform($Xtest)       # transform test data (no refit!)

# RobustScaler — median/IQR, robust to outliers
$scaler = [RobustScaler]::new()
$Xs     = $scaler.FitTransform($X)
$Xtest  = $scaler.Transform($Xtest)

# MissingValueImputer — fill missing values
$imp  = [MissingValueImputer]::new("median")   # "median" | "mean" | "zero"
$Ximp = $imp.FitTransform($X)

# OutlierDetector — clip or remove outliers
$out   = [OutlierDetector]::new("iqr", "clip", 1.5)
# Parameters: method="iqr", treatment="clip"|"remove", threshold=1.5
$out.Fit($Ximp)
$Xclip = $out.Transform($Ximp)         # NOTE: returns hashtable!
$Xclean = $Xclip.Data                  # <-- always use .Data

# PolynomialFeatures — add interaction terms
$poly = [PolynomialFeatures]::new(2)   # degree: 2 or 3
$Xp   = $poly.FitTransform($X, $data.Features)
$Xptest = $poly.FitTransform($Xtest, $data.Features)
```

---

## 5. Classification Models

```powershell
# Gaussian Naive Bayes
$gnb = [GaussianNaiveBayes]::new()
$gnb.Fit($Xtrain, $ytrain)
$preds = $gnb.Predict($Xtest)
$gnb.PrintSummary()

# Logistic Regression
$lr = [LogisticRegression]::new()
$lr.Fit($Xtrain, $ytrain)
$preds = $lr.Predict($Xtest)

# Decision Tree (classification)
$dt = [DecisionTree]::new("classification", 3, 2)
# Parameters: task="classification"|"regression", maxDepth=3, minSamples=2
$dt.Fit($Xtrain, $ytrain)
$preds = $dt.Predict($Xtest)
```

---

## 6. Regression Models

```powershell
# Linear Regression
$lr = [LinearRegression]::new()
$lr.Fit($Xtrain, $ytrain)
$preds = $lr.Predict($Xtest)

# Ridge Regression (L2 regularisation)
$ridge = [RidgeRegression]::new(0.01)   # parameter: lambda (try 0.001–5.0)
$ridge.Fit($Xtrain, $ytrain)
$preds = $ridge.Predict($Xtest)

# Lasso Regression (L1 regularisation)
$lasso = [LassoRegression]::new(0.01)   # parameter: lambda
$lasso.Fit($Xtrain, $ytrain)
$preds = $lasso.Predict($Xtest)

# Decision Tree (regression)
$dt = [DecisionTree]::new("regression", 5, 2)
$dt.Fit($Xtrain, $ytrain)
$preds = $dt.Predict($Xtest)
```

---

## 7. Clustering

```powershell
# KMeans
$km = [KMeans]::new(3)    # parameter: k (number of clusters)
$km.Fit($X)
$labels = $km.Predict($X)
$km.PrintSummary()
# $km.Centroids  — array of centroid vectors
```

---

## 8. Metrics

```powershell
# Classification metrics
$m = Get-ClassificationMetrics $ytrue $ypred
$m.Accuracy      # 0.0 - 1.0

# Regression metrics
$m = Get-RegressionMetrics $ytrue $ypred
$m.R2            # R-squared (1.0 = perfect)
$m.RMSE          # root mean squared error
$m.MAE           # mean absolute error

# Feature correlations
Get-FeatureCorrelations -X $X -y $y -FeatureNames $data.Features

# Data summary
Get-DataSummary -X $X -y $y -FeatureNames $data.Features
```

---

## 9. Model Selection & Tuning

```powershell
# Automatic algorithm selection (cross-validation)
$result = Invoke-VBAFAlgorithmSelection -X $X -y $y `
    -Task "regression" `
    -Folds 5 `
    -Metric "R2"
# -Task   : "regression" | "classification"
# -Folds  : number of CV folds
# -Metric : "R2" | "Accuracy"

# Random hyperparameter search
$hpo = Invoke-VBAFRandomSearch `
    -ModelFactory { param($p) [RidgeRegression]::new($p.Lambda) } `
    -ParamSpace @{ Lambda=@(0.001, 0.01, 0.1, 0.5, 1.0, 5.0) } `
    -X $X -y $y `
    -NTrials 12 `             # number of random trials
    -Folds 5 `
    -Metric "R2"

$hpo.BestScore               # best metric value
$hpo.BestParams.Lambda       # best parameter found
```

---

## 10. Experiment Tracking (MLOps)

```powershell
# Initialise experiment store (run once per session)
$script:ExperimentStorePath = Join-Path $env:USERPROFILE "VBAFRegistry\experiments"

# Create experiment
New-VBAFExperiment -Name "MyExperiment" -Description "What I am testing"

# Start a run
Start-VBAFRun -RunName "run_01" -ModelType "RidgeRegression" `
    -Params @{ lambda=0.01; poly=2 }

# Log metrics during run
Set-VBAFRunMetric -Key "R2"   -Value 0.95
Set-VBAFRunMetric -Key "RMSE" -Value 5.2

# Tag a run
Set-VBAFRunTag -Key "promoted" -Value "true"

# End run
Stop-VBAFRun

# Compare all runs in an experiment
Compare-VBAFRuns -ExperimentName "MyExperiment"
```

---

## 11. Model Registry

```powershell
# Initialise registry (run once per session)
Initialize-VBAFRegistry -Path "C:\Users\henni\VBAFRegistry"

# Save a model
Save-VBAFModel `
    -ModelName   "MyModel" `
    -Model       $trainedModel `
    -ModelType   "RidgeRegression" `
    -Metrics     @{ R2=0.95; RMSE=5.2 } `
    -Params      @{ Lambda=0.01; PolyDegree=2 } `
    -DatasetName "HousePrice" `
    -Description "My production model"

# Load a model
$loaded = Load-VBAFModel -ModelName "MyModel"
```

---

## 12. Drift Monitoring & Retraining Policy

```powershell
# Drift report
$drift = Get-VBAFDriftReport `
    -ReferenceData  $trainX `
    -ProductionData $prodX `
    -FeatureNames   $data.Features
# $drift[i].PSI     — Population Stability Index (>0.2 = drift)
# $drift[i].Status  — "OK" | "DRIFT"

# Retraining policy
$policy = New-VBAFRetrainingPolicy `
    -ModelName     "MyModel" `
    -MinAccuracy   0.90 `
    -MaxDriftPSI   0.20 `
    -MaxAgeDays    30 `
    -MinNewSamples 50
# -MinAccuracy   : retrain if R2 drops below this
# -MaxDriftPSI   : retrain if PSI exceeds this
# -MaxAgeDays    : retrain if model older than this
# -MinNewSamples : retrain if enough new data

# Check if retraining needed
Test-VBAFRetrainingNeeded `
    -Policy           $policy `
    -CurrentAccuracy  0.94 `
    -CurrentMaxPSI    0.15 `
    -ModelTrainedDate (Get-Date).AddDays(-10) `
    -NewSamplesCount  30
```

---

## 13. DQN / Reinforcement Learning (Enterprise Phases)

```powershell
# Run any enterprise agent
$r = Invoke-VBAFAutoPilotTraining         -Episodes 100 -PrintEvery 10 -SimMode
$r = Invoke-VBAFEnergyOptimizerTraining   -Episodes 100 -PrintEvery 10 -SimMode
$r = Invoke-VBAFPatchIntelligenceTraining -Episodes 100 -PrintEvery 10 -SimMode
$r = Invoke-VBAFBackupOptimizerTraining   -Episodes 100 -PrintEvery 10 -SimMode
# ... same pattern for all Phase 14-27 agents

# Parameters (same for all):
#   -Episodes    int     number of training episodes (default 100)
#   -PrintEvery  int     print progress every N episodes (default 10)
#   -SimMode     switch  use simulated data (omit for real Windows data)
#   -FastMode    switch  cap at 30 episodes for quick test

# Returns hashtable:
$r.Agent       # trained DQNAgent object
$r.Results     # list of episode results
$r.Baseline    # @{ Avg = baseline_reward }
$r.Trained     # @{ Avg = trained_reward }
```

---

## 14. Common Gotchas (PS 5.1)

| Problem | Fix |
|---------|-----|
| `Cannot index into null array` | Previous step returned null — check output of each step |
| `Split-TrainTest` returns null | Use `$split.XTrain` not `$split.TrainX` |
| `OutlierDetector.Transform` returns Hashtable | Use `$result.Data` not `$result` directly |
| `op_Multiply not found` | Pre-compute values: `[double]$v = $x * 5.0` then use `$v` |
| Registry path null | Call `Initialize-VBAFRegistry -Path "C:\Users\henni\VBAFRegistry"` first |
| MLOps path null | Set `$script:ExperimentStorePath` before `New-VBAFExperiment` |
| Class cached after edit | Close and reopen ISE — PS 5.1 cannot redefine classes |

---

## 15. Full Minimal Example

```powershell
# Load
. .\VBAF.LoadAll.ps1

# Data
$data   = Get-VBAFDataset -Name "HousePrice"
$scaler = [StandardScaler]::new()
$Xs     = $scaler.FitTransform($data.X)
$split  = Split-TrainTest -X $Xs -y $data.y -TestSize 0.2 -Seed 42

# Train
$model = [RidgeRegression]::new(0.01)
$model.Fit($split.XTrain, $split.yTrain)

# Evaluate
$preds = $model.Predict($split.XTest)
$m     = Get-RegressionMetrics $split.yTest $preds
Write-Host "R2: $($m.R2)"
```

