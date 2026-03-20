<#
#Requires -Version 5.1
.SYNOPSIS
    VBAF Tutorial 09 - Feature Engineering
    Intermediate Series | Estimated time: 25 minutes
.DESCRIPTION
    Learn how feature engineering steps impact model performance:
      - Baseline: no preprocessing
      - Step 1: Standard scaling
      - Step 2: Robust scaling
      - Step 3: Polynomial features
      - Step 4: Full pipeline combined
    Each step measured — see exactly what helps!
#>

# ============================================================
# SECTION 1: Load the framework
# ============================================================
. .\VBAF.LoadAll.ps1

Write-Host "=== VBAF Tutorial 09: Feature Engineering ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "--- Why feature engineering? ---" -ForegroundColor Yellow
Write-Host "  Raw features  -> model sees noise and scale problems" -ForegroundColor White
Write-Host "  Engineered    -> model sees clean, informative signals" -ForegroundColor White
Write-Host "  Rule of thumb : 80% of ML work is data preparation!" -ForegroundColor White
Write-Host ""

# ============================================================
# SECTION 2: Load dataset
# ============================================================
$data  = Get-VBAFDataset -Name "HousePrice"
$split = Split-TrainTest -X $data.X -y $data.y -TestSize 0.2 -Seed 42
Write-Host "  Loaded $($data.X.Length) samples" -ForegroundColor White
Write-Host ""

# ============================================================
# SECTION 3: Baseline — no scaling
# ============================================================
Write-Host "--- Baseline: No Preprocessing ---" -ForegroundColor Yellow
# TEACHING: Without scaling, size_sqm (50-160) dominates age_years (1-25).
# Ridge can still work but is handicapped by the scale differences.
$m0   = [RidgeRegression]::new(0.1)
$m0.Fit($split.XTrain, $split.yTrain)
$met0 = Get-RegressionMetrics $split.yTest ($m0.Predict($split.XTest))
Write-Host ("  R2={0:F4}  RMSE={1:F2}" -f $met0.R2, $met0.RMSE) -ForegroundColor White
Write-Host ""

# ============================================================
# SECTION 4: Step 1 — Standard Scaling
# ============================================================
Write-Host "--- Step 1: Standard Scaling ---" -ForegroundColor Yellow
# TEACHING: StandardScaler: zero mean, unit variance.
# Now all features contribute equally to the model.
$sc1   = [StandardScaler]::new()
$Xs1   = $sc1.FitTransform($data.X)
$sp1   = Split-TrainTest -X $Xs1 -y $data.y -TestSize 0.2 -Seed 42
$m1    = [RidgeRegression]::new(0.1)
$m1.Fit($sp1.XTrain, $sp1.yTrain)
$met1  = Get-RegressionMetrics $sp1.yTest ($m1.Predict($sp1.XTest))
Write-Host ("  R2={0:F4}  RMSE={1:F2}  (+standard scaling)" -f $met1.R2, $met1.RMSE) -ForegroundColor White
Write-Host ""

# ============================================================
# SECTION 5: Step 2 — Robust Scaling
# ============================================================
Write-Host "--- Step 2: Robust Scaling ---" -ForegroundColor Yellow
# TEACHING: RobustScaler uses median/IQR instead of mean/std.
# Better when data has outliers — not thrown off by extreme values.
$sc2   = [RobustScaler]::new()
$Xs2   = $sc2.FitTransform($data.X)
$sp2   = Split-TrainTest -X $Xs2 -y $data.y -TestSize 0.2 -Seed 42
$m2    = [RidgeRegression]::new(0.1)
$m2.Fit($sp2.XTrain, $sp2.yTrain)
$met2  = Get-RegressionMetrics $sp2.yTest ($m2.Predict($sp2.XTest))
Write-Host ("  R2={0:F4}  RMSE={1:F2}  (+robust scaling)" -f $met2.R2, $met2.RMSE) -ForegroundColor White
Write-Host ""

# ============================================================
# SECTION 6: Step 3 — Polynomial Features
# ============================================================
Write-Host "--- Step 3: Polynomial Features (degree=2) ---" -ForegroundColor Yellow
# TEACHING: Adds interactions: size*bedrooms, size^2 etc.
# Captures non-linear relationships the model can not see otherwise.
$poly  = [PolynomialFeatures]::new(2)
$Xs3   = $poly.FitTransform($Xs1, $data.Features)
Write-Host ("  Features: {0} -> {1} columns" -f $Xs1[0].Length, $Xs3[0].Length) -ForegroundColor White
$sp3   = Split-TrainTest -X $Xs3 -y $data.y -TestSize 0.2 -Seed 42
$m3    = [RidgeRegression]::new(0.1)
$m3.Fit($sp3.XTrain, $sp3.yTrain)
$met3  = Get-RegressionMetrics $sp3.yTest ($m3.Predict($sp3.XTest))
Write-Host ("  R2={0:F4}  RMSE={1:F2}  (+polynomial features)" -f $met3.R2, $met3.RMSE) -ForegroundColor White
Write-Host ""

# ============================================================
# SECTION 7: Feature correlations
# ============================================================
Write-Host "--- Feature Correlations ---" -ForegroundColor Yellow
Get-FeatureCorrelations -X $data.X -y $data.y -FeatureNames $data.Features
Write-Host ""

# ============================================================
# SECTION 8: Summary
# ============================================================
Write-Host "╔══════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Feature Engineering Impact Summary              ║" -ForegroundColor Cyan
Write-Host "╠══════════════════════════════════════════════════╣" -ForegroundColor Cyan

$steps = @(
    @{ Name="No preprocessing";       R2=$met0.R2; RMSE=$met0.RMSE },
    @{ Name="+Standard scaling";      R2=$met1.R2; RMSE=$met1.RMSE },
    @{ Name="+Robust scaling";        R2=$met2.R2; RMSE=$met2.RMSE },
    @{ Name="+Polynomial features";   R2=$met3.R2; RMSE=$met3.RMSE }
)

foreach ($s in $steps) {
    [double]$r2safe = if ([double]::IsNaN($s.R2)) { 0.0 } else { [Math]::Max(0.0, $s.R2) }
    $bar   = "█" * [int]($r2safe * 15)
    $color = if ($s.R2 -gt 0.8) { "Green" } elseif ($s.R2 -gt 0.0) { "Yellow" } else { "Red" }
    Write-Host ("║  {0,-28} R2={1:F4}  {2}" -f $s.Name, $s.R2, $bar) -ForegroundColor $color
}

Write-Host "╚══════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "=== Key Takeaways ===" -ForegroundColor Cyan
Write-Host "  Always scale — it almost always helps" -ForegroundColor White
Write-Host "  RobustScaler beats StandardScaler when outliers are present" -ForegroundColor White
Write-Host "  Polynomial features: powerful but adds many columns" -ForegroundColor White
Write-Host "  Measure each step — if R2 drops, skip that step!" -ForegroundColor White
Write-Host ""
Write-Host "Tutorial 09 complete! Try Tutorial 10 next: Model Comparison." -ForegroundColor Green
