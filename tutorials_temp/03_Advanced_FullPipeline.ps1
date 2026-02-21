#Requires -Version 5.1
<#
.SYNOPSIS
    VBAF Tutorial 03 - Advanced: Full ML Pipeline
    Advanced Series | Estimated time: 30 minutes
.DESCRIPTION
    Learn how to build a production-quality ML pipeline:
      - Data loading and validation
      - Preprocessing: imputation, scaling, encoding
      - Feature engineering: polynomial, PCA
      - Model training with cross-validation
      - Hyperparameter tuning with grid search
      - Model saving to registry
      - Serving predictions via API
    This is the complete end-to-end workflow!
#>

Write-Host ""
Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  VBAF Tutorial 03 - Full ML Pipeline     ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# STAGE 1: Load and validate data
# ============================================================
Write-Host "[Stage 1/6] Data Loading & Validation" -ForegroundColor Yellow

$data = Get-VBAFPipelineDataset -Name "MessyHousePrice"
Write-Host "  Loaded $($data.X.Length) samples with missing values and outliers" -ForegroundColor White

# ============================================================
# STAGE 2: Preprocessing pipeline
# ============================================================
Write-Host "[Stage 2/6] Preprocessing" -ForegroundColor Yellow

# Impute missing values with median
$imputer = [MissingValueImputer]::new("median")
$Ximp    = $imputer.FitTransform($data.X)
Write-Host "  Missing values imputed (median)" -ForegroundColor White

# Detect and clip outliers
$outlier = [OutlierDetector]::new("iqr", 1.5)
$Xclip   = $outlier.FitTransform($Ximp)
Write-Host "  Outliers clipped (IQR method)" -ForegroundColor White

# Scale features
$scaler  = [RobustScaler]::new()
$Xs      = $scaler.FitTransform($Xclip)
Write-Host "  Features scaled (RobustScaler)" -ForegroundColor White

# ============================================================
# STAGE 3: Feature Engineering
# ============================================================
Write-Host "[Stage 3/6] Feature Engineering" -ForegroundColor Yellow

$poly = [PolynomialFeatures]::new(2)
$Xp   = $poly.FitTransform($Xs, $data.Features)
Write-Host ("  Polynomial features: {0} -> {1} columns" -f $Xs[0].Length, $Xp[0].Length) -ForegroundColor White

# ============================================================
# STAGE 4: Model selection + cross-validation
# ============================================================
Write-Host "[Stage 4/6] Model Selection" -ForegroundColor Yellow

$algoResult = Invoke-VBAFAlgorithmSelection -X $Xp -y $data.y `
    -Task "regression" -Folds 5 -Metric "R2"

# ============================================================
# STAGE 5: Hyperparameter tuning
# ============================================================
Write-Host "[Stage 5/6] Hyperparameter Tuning" -ForegroundColor Yellow

$hpoResult = Invoke-VBAFRandomSearch `
    -ModelFactory { param($p) [RidgeRegression]::new($p.Lambda) } `
    -ParamSpace @{ Lambda=@(0.001, 0.01, 0.1, 0.5, 1.0, 5.0) } `
    -X $Xp -y $data.y -NTrials 12 -Folds 5 -Metric "R2"

# Train final model
$bestModel = [RidgeRegression]::new($hpoResult.BestParams.Lambda)
$bestModel.Fit($Xp, $data.y)

# ============================================================
# STAGE 6: Save to registry
# ============================================================
Write-Host "[Stage 6/6] Saving to Registry" -ForegroundColor Yellow

Initialize-VBAFRegistry | Out-Null
Save-VBAFModel `
    -ModelName   "Tutorial_HousePrice" `
    -Model       $bestModel `
    -ModelType   "RidgeRegression" `
    -Metrics     @{ R2=[Math]::Round($hpoResult.BestScore, 4) } `
    -Params      @{ Lambda=$hpoResult.BestParams.Lambda; Features="Polynomial(2)" } `
    -DatasetName "MessyHousePrice" `
    -Description "Tutorial 03 - full pipeline" | Out-Null

Write-Host ""
Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║         Pipeline Complete! ✅            ║" -ForegroundColor Green
Write-Host ("║  Best R2     : {0,-27}║" -f [Math]::Round($hpoResult.BestScore, 4)) -ForegroundColor White
Write-Host ("║  Best Lambda : {0,-27}║" -f $hpoResult.BestParams.Lambda)            -ForegroundColor White
Write-Host ("║  Features    : {0,-27}║" -f $Xp[0].Length)                          -ForegroundColor White
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "Try Tutorial 04 next: Real-world House Price MLOps project!" -ForegroundColor Cyan