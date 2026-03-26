# API Reference

Complete function and class reference for VBAF v4.0.0.
See also [VBAF.CheatSheet.md](../VBAF.CheatSheet.md) for a quick one-page summary.

## Datasets

### Get-VBAFDataset
Load a clean regression or classification dataset.
```powershell
$data = Get-VBAFDataset -Name "HousePrice"
# Returns: $data.X (double[][]), $data.y (double[]), $data.Features (string[])
# Available: "HousePrice"
```

### Get-VBAFNBDataset
Load a classification dataset for Naive Bayes.
```powershell
$data = Get-VBAFNBDataset -Name "Iris3Class"
# Available: "Iris3Class"
```

### Get-VBAFPipelineDataset
Load a messy dataset with missing values and outliers.
```powershell
$data = Get-VBAFPipelineDataset -Name "MessyHousePrice"
```

## Preprocessing

### Split-TrainTest
Split data into training and test sets.
```powershell
$split = Split-TrainTest -X $data.X -y $data.y -TestSize 0.2 -Seed 42
# Returns hashtable: $split.XTrain, $split.yTrain, $split.XTest, $split.yTest
```

### StandardScaler
Zero mean, unit variance scaling.
```powershell
$sc = [StandardScaler]::new()
$Xs = $sc.FitTransform($X)       # fit on train
$Xt = $sc.Transform($Xtest)      # apply to test
```

### RobustScaler
Median/IQR scaling, robust to outliers.
```powershell
$sc = [RobustScaler]::new()
$Xs = $sc.FitTransform($X)
```

### MissingValueImputer
Fill missing values with median, mean or zero.
```powershell
$imp = [MissingValueImputer]::new("median")  # "median"|"mean"|"zero"
$Xi  = $imp.FitTransform($X)
```

### OutlierDetector
Detect and clip outliers using IQR method.
```powershell
$out = [OutlierDetector]::new("iqr", "clip", 1.5)
$out.Fit($X)
$Xc  = ($out.Transform($X)).Data   # always use .Data
```

### PolynomialFeatures
Add polynomial and interaction features.
```powershell
$poly = [PolynomialFeatures]::new(2)   # degree 2 or 3
$Xp   = $poly.FitTransform($X, $featureNames)
```

## Classification Models
```powershell
$gnb = [GaussianNaiveBayes]::new()
$lr  = [LogisticRegression]::new()
$dt  = [DecisionTree]::new("classification", 3, 2)  # task, maxDepth, minSamples
# All: .Fit($Xtrain, $ytrain)  .Predict($Xtest)
```

## Regression Models
```powershell
$lr    = [LinearRegression]::new()
$ridge = [RidgeRegression]::new(0.01)    # lambda
$lasso = [LassoRegression]::new(0.01)    # lambda
$dt    = [DecisionTree]::new("regression", 3, 2)
# All: .Fit($Xtrain, $ytrain)  .Predict($Xtest)
```

## Clustering
```powershell
$km = [KMeans]::new(3)    # k
$km.Fit($X)
$labels    = $km.Predict($X)
$centroids = $km.Centroids
```

## Metrics
```powershell
$m = Get-ClassificationMetrics $ytrue $ypred   # $m.Accuracy
$m = Get-RegressionMetrics $ytrue $ypred       # $m.R2, $m.RMSE, $m.MAE
```

## Model Selection
```powershell
$r = Invoke-VBAFAlgorithmSelection -X $X -y $y -Task "regression" -Folds 5 -Metric "R2"
$r = Invoke-VBAFRandomSearch -ModelFactory { param($p) [RidgeRegression]::new($p.Lambda) } `
     -ParamSpace @{ Lambda=@(0.001,0.01,0.1,1.0) } -X $X -y $y -NTrials 8 -Folds 5 -Metric "R2"
```

## Enterprise Agents (Phases 14-27)
```powershell
$r = Invoke-VBAFAutoPilotTraining          -Episodes 100 -PrintEvery 10 -SimMode
$r = Invoke-VBAFEnergyOptimizerTraining    -Episodes 100 -PrintEvery 10 -SimMode
$r = Invoke-VBAFPatchIntelligenceTraining  -Episodes 100 -PrintEvery 10 -SimMode
# Same pattern for all 14 enterprise training functions
# Returns: $r.Agent, $r.Baseline.Avg, $r.Trained.Avg
```
