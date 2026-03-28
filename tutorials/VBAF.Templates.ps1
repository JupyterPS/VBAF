<#
#Requires -Version 5.1
.SYNOPSIS
    VBAF Templates & Recipes - Reusable workflow patterns
.DESCRIPTION
    A cookbook of copy-paste ready templates for common ML tasks.
    Sections:
      1. Common workflow templates
      2. Industry-specific examples
      3. Performance optimization recipes
      4. Troubleshooting cookbook
      5. Best practices guide
    Each recipe is self-contained and runnable after VBAF.LoadAll.ps1
.NOTES
    Part of VBAF - Phase 8 Community & Ecosystem
    PS 5.1 compatible
#>

# ============================================================
# HOW TO USE THIS FILE
# ============================================================
# 1. Run VBAF.LoadAll.ps1 first
# 2. Find the recipe you need (Ctrl+F the section name)
# 3. Copy the code block into your script or console
# 4. Adapt to your data and run!
# ============================================================

Write-Host ""
Write-Host "+--------------------------------------------------+" -ForegroundColor Cyan
Write-Host "¦       VBAF Templates & Recipes Cookbook          ¦" -ForegroundColor Cyan
Write-Host "¦--------------------------------------------------¦" -ForegroundColor Cyan
Write-Host "¦  1. Common Workflow Templates                    ¦" -ForegroundColor White
Write-Host "¦     - Regression pipeline                        ¦" -ForegroundColor DarkGray
Write-Host "¦     - Classification pipeline                    ¦" -ForegroundColor DarkGray
Write-Host "¦     - Clustering pipeline                        ¦" -ForegroundColor DarkGray
Write-Host "¦     - Time series pipeline                       ¦" -ForegroundColor DarkGray
Write-Host "¦  2. Industry-Specific Examples                   ¦" -ForegroundColor White
Write-Host "¦     - Real estate pricing                        ¦" -ForegroundColor DarkGray
Write-Host "¦     - Customer segmentation                      ¦" -ForegroundColor DarkGray
Write-Host "¦     - Text spam classification                   ¦" -ForegroundColor DarkGray
Write-Host "¦     - Sales forecasting                          ¦" -ForegroundColor DarkGray
Write-Host "¦  3. Performance Optimization Recipes             ¦" -ForegroundColor White
Write-Host "¦     - Feature selection before training          ¦" -ForegroundColor DarkGray
Write-Host "¦     - Cross-validation strategy                  ¦" -ForegroundColor DarkGray
Write-Host "¦     - Scaler selection guide                     ¦" -ForegroundColor DarkGray
Write-Host "¦  4. Troubleshooting Cookbook                     ¦" -ForegroundColor White
Write-Host "¦     - Model not improving                        ¦" -ForegroundColor DarkGray
Write-Host "¦     - Overfitting / underfitting                 ¦" -ForegroundColor DarkGray
Write-Host "¦     - Data quality issues                        ¦" -ForegroundColor DarkGray
Write-Host "¦  5. Best Practices Guide                         ¦" -ForegroundColor White
Write-Host "+--------------------------------------------------+" -ForegroundColor Cyan
Write-Host ""
Write-Host "Run individual sections below or source this file." -ForegroundColor DarkGray
Write-Host ""

# ============================================================
# SECTION 1: COMMON WORKFLOW TEMPLATES
# ============================================================

function Invoke-RegressionTemplate {
    <#
    .SYNOPSIS Recipe: Standard regression pipeline - copy and adapt!
    #>
    param(
        [double[][]] $X,
        [double[]]   $y,
        [string[]]   $FeatureNames = @(),
        [double]     $TestSize     = 0.2,
        [double]     $Lambda       = 0.1
    )

    Write-Host "?? [Template] Regression Pipeline" -ForegroundColor Cyan

    # 1. Split
    $split = Split-TrainTest -X $X -y $y -TestSize $TestSize -Seed 42

    # 2. Scale
    $scaler  = [StandardScaler]::new()
    $trainXs = $scaler.FitTransform($split.TrainX)
    $testXs  = $scaler.Transform($split.TestX)

    # 3. Train
    $model = [RidgeRegression]::new($Lambda)
    $model.Fit($trainXs, $split.TrainY)

    # 4. Evaluate
    $preds   = $model.Predict($testXs)
    $metrics = Get-RegressionMetrics $split.TestY $preds

    Write-Host ("   R2={0:F4}  RMSE={1:F4}  MAE={2:F4}" -f $metrics.R2, $metrics.RMSE, $metrics.MAE) -ForegroundColor Green
    return @{ Model=$model; Scaler=$scaler; Metrics=$metrics }
}

function Invoke-ClassificationTemplate {
    <#
    .SYNOPSIS Recipe: Standard classification pipeline - copy and adapt!
    #>
    param(
        [double[][]] $X,
        [double[]]   $y,
        [int]        $MaxDepth = 4
    )

    Write-Host "?? [Template] Classification Pipeline" -ForegroundColor Cyan

    # 1. Split
    $split = Split-TrainTest -X $X -y $y -TestSize 0.2 -Seed 42

    # 2. Scale
    $scaler  = [StandardScaler]::new()
    $trainXs = $scaler.FitTransform($split.TrainX)
    $testXs  = $scaler.Transform($split.TestX)

    # 3. Train (try multiple, pick best)
    $candidates = @(
        @{ Name="GaussianNB";    Model=[GaussianNaiveBayes]::new() },
        @{ Name="DecisionTree";  Model=[DecisionTree]::new("classification", $MaxDepth, 2) },
        @{ Name="LogisticReg";   Model=[LogisticRegression]::new() }
    )

    $best = $null; $bestAcc = 0.0
    foreach ($c in $candidates) {
        $c.Model.Fit($trainXs, $split.TrainY)
        $preds  = $c.Model.Predict($testXs)
        $m      = Get-ClassificationMetrics $split.TestY $preds
        $marker = if ($m.Accuracy -gt $bestAcc) { $bestAcc=$m.Accuracy; $best=$c; "?" } else { "" }
        Write-Host ("   {0,-15} Acc={1:P1} {2}" -f $c.Name, $m.Accuracy, $marker) -ForegroundColor White
    }

    Write-Host ("   Best: {0} (Acc={1:P1})" -f $best.Name, $bestAcc) -ForegroundColor Green
    return @{ Model=$best.Model; Scaler=$scaler; Accuracy=$bestAcc }
}

function Invoke-ClusteringTemplate {
    <#
    .SYNOPSIS Recipe: Clustering pipeline with elbow method - copy and adapt!
    #>
    param(
        [double[][]] $X,
        [int]        $MaxK = 8
    )

    Write-Host "?? [Template] Clustering Pipeline" -ForegroundColor Cyan

    # 1. Scale
    $scaler = [StandardScaler]::new()
    $Xs     = $scaler.FitTransform($X)

    # 2. Find optimal K with elbow method
    Write-Host "   Finding optimal K..." -ForegroundColor DarkGray
    $elbowResult = Invoke-ElbowMethod -X $Xs -MaxK $MaxK

    # 3. Train with best K
    $km = [KMeans]::new($elbowResult.OptimalK)
    $km.Fit($Xs)

    # 4. Evaluate with silhouette score
    $sil = Get-SilhouetteScore -X $Xs -Labels $km.Labels
    Write-Host ("   K={0}  Silhouette={1:F4}" -f $elbowResult.OptimalK, $sil) -ForegroundColor Green
    return @{ Model=$km; Scaler=$scaler; K=$elbowResult.OptimalK; Silhouette=$sil }
}

function Invoke-TimeSeriesTemplate {
    <#
    .SYNOPSIS Recipe: Time series analysis pipeline - copy and adapt!
    #>
    param([string]$DatasetName = "Sales")

    Write-Host "?? [Template] Time Series Pipeline" -ForegroundColor Cyan

    $ts = Get-VBAFTimeSeriesDataset -Name $DatasetName
    $ts.PrintSummary()

    # Lag features for ML
    $lagged = Add-LagFeatures -TimeSeries $ts -Lags @(1, 7, 30)

    # Rolling statistics
    $rolled = Add-RollingFeatures -TimeSeries $ts -Windows @(7, 30) -Stats @("mean","std")

    # Seasonal decomposition
    Invoke-SeasonalDecomposition -TimeSeries $ts -Period 7

    Write-Host "   Time series template complete" -ForegroundColor Green
    return @{ TimeSeries=$ts; Lagged=$lagged; Rolled=$rolled }
}

# ============================================================
# SECTION 2: INDUSTRY-SPECIFIC EXAMPLES
# ============================================================

function Invoke-RealEstatePricingExample {
    <#
    .SYNOPSIS Industry: Real estate automated valuation model (AVM)
    #>
    Write-Host "?? [Industry] Real Estate Pricing (AVM)" -ForegroundColor Cyan

    $data = Get-VBAFDataset -Name "HousePrice"

    # AutoML finds best model automatically
    $scaler = [StandardScaler]::new()
    $Xs     = $scaler.FitTransform($data.X)

    $auto = Invoke-VBAFAutoML -X $Xs -y $data.y `
        -FeatureNames $data.Features `
        -Task "regression" -OptMethod "bayesian" -HPOTrials 10

    # Save to registry for serving
    Initialize-VBAFRegistry | Out-Null
    Save-VBAFModel -ModelName "AVM_Model" -Model $auto.Model `
        -ModelType $auto.Algorithm -Metrics @{ R2=[Math]::Round($auto.BestScore,4) } `
        -DatasetName "HousePrice" -Description "Automated Valuation Model" | Out-Null

    Write-Host ("   AVM R2={0:F4}  Algorithm={1}" -f $auto.BestScore, $auto.Algorithm) -ForegroundColor Green
    return $auto
}

function Invoke-CustomerSegmentationExample {
    <#
    .SYNOPSIS Industry: Customer segmentation for marketing
    .DESCRIPTION
        Segments customers into groups for targeted campaigns.
        Features: recency, frequency, monetary value (RFM)
    #>
    Write-Host "?? [Industry] Customer Segmentation (RFM)" -ForegroundColor Cyan

    # Simulate RFM data: recency (days), frequency (orders), monetary (£)
    $rng = [System.Random]::new(42)
    $rfm = @()
    for ($i = 0; $i -lt 60; $i++) {
        $segment = $i % 4
        $sample  = switch ($segment) {
            0 { @(5.0  + $rng.NextDouble()*10,  20.0 + $rng.NextDouble()*10, 500.0 + $rng.NextDouble()*200) }  # Champions
            1 { @(30.0 + $rng.NextDouble()*20,  10.0 + $rng.NextDouble()*5,  200.0 + $rng.NextDouble()*100) }  # Loyal
            2 { @(90.0 + $rng.NextDouble()*30,   3.0 + $rng.NextDouble()*3,   80.0 + $rng.NextDouble()*50)  }  # At risk
            3 { @(200.0+ $rng.NextDouble()*50,   1.0 + $rng.NextDouble()*2,   30.0 + $rng.NextDouble()*20)  }  # Lost
        }
        $rfm += ,$sample
    }

    $scaler = [MinMaxScaler]::new()
    $rfmS   = $scaler.FitTransform($rfm)

    $km  = [KMeans]::new(4)
    $km.Fit($rfmS)
    $sil = Get-SilhouetteScore -X $rfmS -Labels $km.Labels

    $segmentNames = @("Champions","Loyal","At Risk","Lost")
    Write-Host ("   4 segments found  Silhouette={0:F4}" -f $sil) -ForegroundColor Green
    Write-Host "   Recommended actions:" -ForegroundColor Yellow
    Write-Host "     Champions : Reward them, ask for reviews"   -ForegroundColor White
    Write-Host "     Loyal     : Upsell higher value products"   -ForegroundColor White
    Write-Host "     At Risk   : Send win-back campaign"         -ForegroundColor White
    Write-Host "     Lost      : Ignore or minimal spend"        -ForegroundColor White
    return @{ Model=$km; Silhouette=$sil }
}

function Invoke-SpamClassificationExample {
    <#
    .SYNOPSIS Industry: Text spam classification using Bernoulli NB
    #>
    Write-Host "?? [Industry] Spam Classification" -ForegroundColor Cyan

    $data = Get-VBAFNBDataset -Name "SpamHam"
    Write-Host ("   Samples: {0}  Classes: {1}" -f $data.X.Length, ($data.ClassNames -join ", ")) -ForegroundColor White

    $split  = Split-TrainTest -X $data.X -y $data.y -TestSize 0.2 -Seed 42
    $bnb    = [BernoulliNaiveBayes]::new()
    $bnb.Fit($split.TrainX, $split.TrainY)

    $preds   = $bnb.Predict($split.TestX)
    $metrics = Get-ClassificationMetrics $split.TestY $preds

    Write-Host ("   Accuracy={0:P1}  (spam filter performance)" -f $metrics.Accuracy) -ForegroundColor Green
    return @{ Model=$bnb; Accuracy=$metrics.Accuracy }
}

function Invoke-SalesForecastingExample {
    <#
    .SYNOPSIS Industry: Sales forecasting with lag features + regression
    #>
    Write-Host "?? [Industry] Sales Forecasting" -ForegroundColor Cyan

    $ts = Get-VBAFTimeSeriesDataset -Name "Sales"

    # Create supervised dataset with lag features
    $lagged = Add-LagFeatures -TimeSeries $ts -Lags @(1, 7)
    $rolled = Add-RollingFeatures -TimeSeries $ts -Windows @(7) -Stats @("mean")

    Write-Host "   Lag and rolling features created" -ForegroundColor White
    Write-Host "   Use Invoke-RegressionTemplate with lagged features" -ForegroundColor DarkGray
    Write-Host "   to train a forecast model on this data" -ForegroundColor DarkGray
    return @{ TimeSeries=$ts; Lagged=$lagged }
}

# ============================================================
# SECTION 3: PERFORMANCE OPTIMIZATION RECIPES
# ============================================================

function Get-VBAFScalerGuide {
    <#
    .SYNOPSIS Recipe: Which scaler to use and when?
    #>
    Write-Host ""
    Write-Host "? Scaler Selection Guide:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   StandardScaler  (z-score normalization)" -ForegroundColor Yellow
    Write-Host "     When: most cases, especially linear models and SVM" -ForegroundColor White
    Write-Host "     How:  (x - mean) / std ? mean=0, std=1" -ForegroundColor DarkGray
    Write-Host "     Avoid: when data has heavy outliers" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "   MinMaxScaler    (0-1 normalization)" -ForegroundColor Yellow
    Write-Host "     When: neural networks, distance-based models (KMeans)" -ForegroundColor White
    Write-Host "     How:  (x - min) / (max - min) ? [0, 1]" -ForegroundColor DarkGray
    Write-Host "     Avoid: when outliers exist (they compress everything else)" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "   RobustScaler    (median/IQR normalization)" -ForegroundColor Yellow
    Write-Host "     When: data with significant outliers" -ForegroundColor White
    Write-Host "     How:  (x - median) / IQR ? robust to extremes" -ForegroundColor DarkGray
    Write-Host "     Best: messy real-world data" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "   No scaling" -ForegroundColor Yellow
    Write-Host "     When: tree-based models (DecisionTree, RandomForest)" -ForegroundColor White
    Write-Host "     Why:  trees split on thresholds, scale doesn't matter" -ForegroundColor DarkGray
    Write-Host ""
}

function Get-VBAFCrossValGuide {
    <#
    .SYNOPSIS Recipe: Cross-validation strategy selection
    #>
    Write-Host ""
    Write-Host "? Cross-Validation Strategy Guide:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   Small dataset (< 100 samples):" -ForegroundColor Yellow
    Write-Host "     Use k=10 folds or leave-one-out" -ForegroundColor White
    Write-Host "     VBAF: Invoke-KFoldCV -Folds 10" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "   Medium dataset (100-10000 samples):" -ForegroundColor Yellow
    Write-Host "     Use k=5 folds (good speed/variance tradeoff)" -ForegroundColor White
    Write-Host "     VBAF: Invoke-KFoldCV -Folds 5" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "   Imbalanced classes:" -ForegroundColor Yellow
    Write-Host "     Ensure each fold has all classes represented" -ForegroundColor White
    Write-Host "     Check: are rare classes present in validation folds?" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "   Time series:" -ForegroundColor Yellow
    Write-Host "     NEVER shuffle! Use walk-forward validation" -ForegroundColor White
    Write-Host "     Train on past, validate on future only" -ForegroundColor DarkGray
    Write-Host ""
}

function Get-VBAFFeatureSelectionRecipe {
    <#
    .SYNOPSIS Recipe: When and how to do feature selection
    #>
    param([double[][]]$X, [double[]]$y, [string[]]$FeatureNames = @())

    Write-Host "? Feature Selection Recipe" -ForegroundColor Cyan

    # Step 1: Remove zero-variance features
    $scaler  = [StandardScaler]::new()
    $selector= [VarianceSelector]::new(0.01)
    $Xvar    = $selector.FitTransform($X)
    Write-Host ("   After variance filter: {0} -> {1} features" -f $X[0].Length, $Xvar[0].Length) -ForegroundColor White

    # Step 2: Correlation filter
    if ($FeatureNames.Length -gt 0) {
        $fsResult = Invoke-VBAFFeatureSelection -X $Xvar -y $y `
            -FeatureNames $FeatureNames -Method "filter"
        return $fsResult
    }

    return @{ X=$Xvar }
}

# ============================================================
# SECTION 4: TROUBLESHOOTING COOKBOOK
# ============================================================

function Get-VBAFTroubleshootingGuide {
    Write-Host ""
    Write-Host "?? VBAF Troubleshooting Cookbook" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "PROBLEM: Model R2 is negative or very low" -ForegroundColor Red
    Write-Host "  CAUSE 1: Features not scaled for linear models" -ForegroundColor Yellow
    Write-Host "    FIX:  Add StandardScaler before training" -ForegroundColor White
    Write-Host "  CAUSE 2: Wrong model for the task" -ForegroundColor Yellow
    Write-Host "    FIX:  Use Invoke-VBAFAlgorithmSelection to compare" -ForegroundColor White
    Write-Host "  CAUSE 3: Evaluating on training data (data leakage)" -ForegroundColor Yellow
    Write-Host "    FIX:  Always use Split-TrainTest before fitting" -ForegroundColor White
    Write-Host ""

    Write-Host "PROBLEM: Model memorizes training data (overfitting)" -ForegroundColor Red
    Write-Host "  SIGNS:  Train R2=0.99 but Test R2=0.50" -ForegroundColor DarkGray
    Write-Host "  FIX 1:  Add regularization (use Ridge/Lasso, increase Lambda)" -ForegroundColor White
    Write-Host "  FIX 2:  Reduce model complexity (smaller MaxDepth in trees)" -ForegroundColor White
    Write-Host "  FIX 3:  Get more training data" -ForegroundColor White
    Write-Host "  FIX 4:  Feature selection - remove irrelevant features" -ForegroundColor White
    Write-Host ""

    Write-Host "PROBLEM: Model too simple (underfitting)" -ForegroundColor Red
    Write-Host "  SIGNS:  Both Train and Test R2 are low (~0.5)" -ForegroundColor DarkGray
    Write-Host "  FIX 1:  Add polynomial features (PolynomialFeatures)" -ForegroundColor White
    Write-Host "  FIX 2:  Try more complex model (RandomForest, higher depth)" -ForegroundColor White
    Write-Host "  FIX 3:  Add more features / feature engineering" -ForegroundColor White
    Write-Host "  FIX 4:  Reduce Lambda (less regularization)" -ForegroundColor White
    Write-Host ""

    Write-Host "PROBLEM: Pipeline crashes with null array errors" -ForegroundColor Red
    Write-Host "  CAUSE:  PS 5.1 unrolls single-row arrays" -ForegroundColor Yellow
    Write-Host "  FIX:    Wrap single rows: @(,`$row) not @(`$row)" -ForegroundColor White
    Write-Host "  FIX:    Cast explicitly: [double[]]`$X[0]" -ForegroundColor White
    Write-Host ""

    Write-Host "PROBLEM: Clustering gives poor results" -ForegroundColor Red
    Write-Host "  FIX 1:  Scale features first! (KMeans is distance-based)" -ForegroundColor White
    Write-Host "  FIX 2:  Use Invoke-ElbowMethod to find optimal K" -ForegroundColor White
    Write-Host "  FIX 3:  Try different random seeds (Seed parameter)" -ForegroundColor White
    Write-Host "  FIX 4:  Check Silhouette score - below 0.3 means poor fit" -ForegroundColor White
    Write-Host ""
}

# ============================================================
# SECTION 5: BEST PRACTICES GUIDE
# ============================================================

function Get-VBAFBestPractices {
    Write-Host ""
    Write-Host "? VBAF Best Practices" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "DATA PRACTICES:" -ForegroundColor Yellow
    Write-Host "  ? Always split train/test BEFORE any preprocessing" -ForegroundColor White
    Write-Host "  ? Fit scalers on TRAIN only, transform both train and test" -ForegroundColor White
    Write-Host "  ? Check for missing values before training" -ForegroundColor White
    Write-Host "  ? Understand your data with Get-DataSummary first" -ForegroundColor White
    Write-Host ""

    Write-Host "MODEL PRACTICES:" -ForegroundColor Yellow
    Write-Host "  ? Start with the simplest model (linear regression/NB)" -ForegroundColor White
    Write-Host "  ? Use cross-validation, not a single train/test split" -ForegroundColor White
    Write-Host "  ? Always compare against a baseline" -ForegroundColor White
    Write-Host "  ? Track all experiments with New-VBAFExperiment" -ForegroundColor White
    Write-Host ""

    Write-Host "PRODUCTION PRACTICES:" -ForegroundColor Yellow
    Write-Host "  ? Save every model with Save-VBAFModel (don't retrain from memory!)" -ForegroundColor White
    Write-Host "  ? Set retraining policy with New-VBAFRetrainingPolicy" -ForegroundColor White
    Write-Host "  ? Monitor for data drift with Get-VBAFDriftReport" -ForegroundColor White
    Write-Host "  ? Use Compare-VBAFModels before promoting a new version" -ForegroundColor White
    Write-Host ""

    Write-Host "PS 5.1 GOTCHAS:" -ForegroundColor Yellow
    Write-Host "  ??  foreach over double[][] unrolls - use index loops" -ForegroundColor White
    Write-Host "  ??  Class method returns can unroll - cast [double[]] explicitly" -ForegroundColor White
    Write-Host "  ??  Single-element arrays need comma: ,@(1.0) not @(1.0)" -ForegroundColor White
    Write-Host "  ??  ArrayList indexer returns [object] - always cast explicitly" -ForegroundColor White
    Write-Host ""
}

# ============================================================
# QUICK REFERENCE CARD
# ============================================================

function Show-VBAFQuickReference {
    Write-Host ""
    Write-Host "+----------------------------------------------------------+" -ForegroundColor Green
    Write-Host "¦                VBAF Quick Reference                     ¦" -ForegroundColor Green
    Write-Host "¦----------------------------------------------------------¦" -ForegroundColor Green
    Write-Host "¦  DATASETS                                               ¦" -ForegroundColor Yellow
    Write-Host "¦  Get-VBAFDataset        -Name HousePrice/Sine/Linear    ¦" -ForegroundColor White
    Write-Host "¦  Get-VBAFNBDataset      -Name Iris3Class/SpamHam        ¦" -ForegroundColor White
    Write-Host "¦  Get-VBAFClusterDataset -Name Blobs/Moons               ¦" -ForegroundColor White
    Write-Host "¦  Get-VBAFTreeDataset    -Name HousePrice/Titanic        ¦" -ForegroundColor White
    Write-Host "¦----------------------------------------------------------¦" -ForegroundColor Green
    Write-Host "¦  PREPROCESSING                                          ¦" -ForegroundColor Yellow
    Write-Host "¦  [StandardScaler]::new()     .FitTransform() .Transform ¦" -ForegroundColor White
    Write-Host "¦  [MinMaxScaler]::new()       .FitTransform() .Transform ¦" -ForegroundColor White
    Write-Host "¦  [RobustScaler]::new()       .FitTransform() .Transform ¦" -ForegroundColor White
    Write-Host "¦  [MissingValueImputer]::new(strategy)                   ¦" -ForegroundColor White
    Write-Host "¦  [PolynomialFeatures]::new(degree)                      ¦" -ForegroundColor White
    Write-Host "¦----------------------------------------------------------¦" -ForegroundColor Green
    Write-Host "¦  MODELS                                                 ¦" -ForegroundColor Yellow
    Write-Host "¦  [LinearRegression]::new()                              ¦" -ForegroundColor White
    Write-Host "¦  [RidgeRegression]::new(lambda)                         ¦" -ForegroundColor White
    Write-Host "¦  [LogisticRegression]::new()                            ¦" -ForegroundColor White
    Write-Host "¦  [DecisionTree]::new(task, maxDepth, minSamples)        ¦" -ForegroundColor White
    Write-Host "¦  [RandomForest]::new(nTrees, maxDepth, minSamples)      ¦" -ForegroundColor White
    Write-Host "¦  [GaussianNaiveBayes]::new()                            ¦" -ForegroundColor White
    Write-Host "¦  [KMeans]::new(k)                                       ¦" -ForegroundColor White
    Write-Host "¦----------------------------------------------------------¦" -ForegroundColor Green
    Write-Host "¦  EVALUATION                                             ¦" -ForegroundColor Yellow
    Write-Host "¦  Get-RegressionMetrics      $y $preds                  ¦" -ForegroundColor White
    Write-Host "¦  Get-ClassificationMetrics  $y $preds                  ¦" -ForegroundColor White
    Write-Host "¦  Get-SilhouetteScore  -X $Xs -Labels $km.Labels        ¦" -ForegroundColor White
    Write-Host "¦  Invoke-KFoldCV  -Model $m -X $X -y $y -Folds 5        ¦" -ForegroundColor White
    Write-Host "¦----------------------------------------------------------¦" -ForegroundColor Green
    Write-Host "¦  AUTOML / HPO                                           ¦" -ForegroundColor Yellow
    Write-Host "¦  Invoke-VBAFGridSearch / RandomSearch / BayesianSearch  ¦" -ForegroundColor White
    Write-Host "¦  Invoke-VBAFAlgorithmSelection  -Task regression        ¦" -ForegroundColor White
    Write-Host "¦  Invoke-VBAFAutoML  -OptMethod bayesian                 ¦" -ForegroundColor White
    Write-Host "¦----------------------------------------------------------¦" -ForegroundColor Green
    Write-Host "¦  MLOPS                                                  ¦" -ForegroundColor Yellow
    Write-Host "¦  Save-VBAFModel / Load-VBAFModel / Compare-VBAFModels   ¦" -ForegroundColor White
    Write-Host "¦  New-VBAFExperiment / Start-VBAFRun / Stop-VBAFRun      ¦" -ForegroundColor White
    Write-Host "¦  Get-VBAFDriftReport  -ReferenceData $ref               ¦" -ForegroundColor White
    Write-Host "¦  New-VBAFRetrainingPolicy / Test-VBAFRetrainingNeeded   ¦" -ForegroundColor White
    Write-Host "+----------------------------------------------------------+" -ForegroundColor Green
    Write-Host ""
}

# Auto-show quick reference on load
Show-VBAFQuickReference


