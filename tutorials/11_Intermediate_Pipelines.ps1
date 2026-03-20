<#
#Requires -Version 5.1
.SYNOPSIS
    VBAF Tutorial 11 - ML Pipelines
    Intermediate Series | Estimated time: 25 minutes
.DESCRIPTION
    Learn how to:
      - Chain preprocessing steps into a clean pipeline
      - Avoid data leakage (a common and costly mistake)
      - Apply the same pipeline to training and test data correctly
      - Save and reuse a pipeline for production predictions
      - Compare pipeline approaches side by side
#>

# ============================================================
# SECTION 1: Load the framework
# ============================================================
. .\VBAF.LoadAll.ps1

Write-Host "=== VBAF Tutorial 11: ML Pipelines ===" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# SECTION 2: What is a pipeline?
# ============================================================
# TEACHING: A pipeline chains steps in the correct order.
# Without a pipeline it is easy to make mistakes — especially
# data leakage: accidentally using test data to fit the scaler!

Write-Host "--- What is a pipeline? ---" -ForegroundColor Yellow
Write-Host "  Pipeline = ordered chain of: preprocess -> model" -ForegroundColor White
Write-Host "  Key rule : fit ALL steps on TRAIN data only!" -ForegroundColor White
Write-Host "  Key rule : transform TEST data with already-fitted steps!" -ForegroundColor White
Write-Host ""

# ============================================================
# SECTION 3: The WRONG way — data leakage
# ============================================================
# TEACHING: This is the most common ML mistake!
# Fitting the scaler on ALL data before splitting leaks test info.

Write-Host "--- The WRONG way (data leakage) ---" -ForegroundColor Red

$data   = Get-VBAFDataset -Name "HousePrice"

# WRONG: fit scaler on ALL data BEFORE splitting
$scalerBad = [StandardScaler]::new()
$XsBad     = $scalerBad.FitTransform($data.X)   # leaks test data!
$splitBad  = Split-TrainTest -X $XsBad -y $data.y -TestSize 0.2 -Seed 42
$mBad      = [RidgeRegression]::new(0.01)
$mBad.Fit($splitBad.XTrain, $splitBad.yTrain)
$metBad    = Get-RegressionMetrics $splitBad.yTest ($mBad.Predict($splitBad.XTest))
Write-Host ("  R2={0:F4} RMSE={1:F2}  <- looks good but CHEATING!" -f $metBad.R2, $metBad.RMSE) -ForegroundColor Red
Write-Host "  The scaler saw test data — results are optimistic!" -ForegroundColor Yellow
Write-Host ""

# ============================================================
# SECTION 4: The RIGHT way — fit on train, transform test
# ============================================================
# TEACHING: Split FIRST, then fit scaler on train only.
# Transform test using the already-fitted scaler.

Write-Host "--- The RIGHT way (no leakage) ---" -ForegroundColor Green

# RIGHT: split first, then fit scaler on train only
$splitGood  = Split-TrainTest -X $data.X -y $data.y -TestSize 0.2 -Seed 42
$scalerGood = [StandardScaler]::new()
$trainXs    = $scalerGood.FitTransform($splitGood.XTrain)  # fit on train only
$testXs     = $scalerGood.Transform($splitGood.XTest)      # transform test
$mGood      = [RidgeRegression]::new(0.01)
$mGood.Fit($trainXs, $splitGood.yTrain)
$metGood    = Get-RegressionMetrics $splitGood.yTest ($mGood.Predict($testXs))
Write-Host ("  R2={0:F4} RMSE={1:F2}  <- honest estimate" -f $metGood.R2, $metGood.RMSE) -ForegroundColor Green
Write-Host ""

# ============================================================
# SECTION 5: Full pipeline — impute, clip, scale, poly, model
# ============================================================
# TEACHING: Each step fitted on train, applied to test.
# This is the production-ready pattern.

Write-Host "--- Full Pipeline: Impute -> Clip -> Scale -> Poly -> Model ---" -ForegroundColor Yellow

$dataMess  = Get-VBAFPipelineDataset -Name "MessyHousePrice"
$splitP    = Split-TrainTest -X $dataMess.X -y $dataMess.y -TestSize 0.2 -Seed 42

# Step 1: Impute — fit on train
$imp       = [MissingValueImputer]::new("median")
$trainImp  = $imp.FitTransform($splitP.XTrain)
$testImp   = $imp.Transform($splitP.XTest)
Write-Host "  [1/4] Imputed missing values" -ForegroundColor White

# Step 2: Clip outliers — fit on train
$out       = [OutlierDetector]::new("iqr", "clip", 1.5)
$out.Fit($trainImp)
$trainClip = ($out.Transform($trainImp)).Data
$testClip  = ($out.Transform($testImp)).Data
Write-Host "  [2/4] Clipped outliers" -ForegroundColor White

# Step 3: Scale — fit on train
$sc        = [StandardScaler]::new()
$trainSc   = $sc.FitTransform($trainClip)
$testSc    = $sc.Transform($testClip)
Write-Host "  [3/4] Scaled features" -ForegroundColor White

# Step 4: Polynomial features — fit on train
$poly      = [PolynomialFeatures]::new(2)
$trainPoly = $poly.FitTransform($trainSc, $dataMess.Features)
$testPoly  = $poly.FitTransform($testSc,  $dataMess.Features)
Write-Host ("  [4/4] Polynomial features: {0} -> {1} columns" -f $trainSc[0].Length, $trainPoly[0].Length) -ForegroundColor White

# Train final model
$mPipe     = [RidgeRegression]::new(0.1)
$mPipe.Fit($trainPoly, $splitP.yTrain)
$metPipe   = Get-RegressionMetrics $splitP.yTest ($mPipe.Predict($testPoly))
Write-Host ("  Result: R2={0:F4}  RMSE={1:F2}" -f $metPipe.R2, $metPipe.RMSE) -ForegroundColor Green
Write-Host ""

# ============================================================
# SECTION 6: Reuse pipeline for new predictions
# ============================================================
# TEACHING: The fitted pipeline objects (imp, out, sc, poly)
# can be reused on any new data — this is production serving!

Write-Host "--- Reusing Pipeline for New Predictions ---" -ForegroundColor Yellow

$newHouses = @(
    [double[]]@(100.0, 3.0, 8.0),
    [double[]]@(150.0, 5.0, 2.0),
    [double[]]@(65.0,  2.0, 20.0)
)
$newLabels = @("100sqm 3bed 8yr", "150sqm 5bed 2yr", "65sqm 2bed 20yr")

Write-Host ("  {0,-20} {1}" -f "House", "Predicted Price") -ForegroundColor Yellow
Write-Host ("  {0}" -f ("-" * 38)) -ForegroundColor DarkGray

foreach ($i in 0..($newHouses.Length-1)) {
    $xNew  = $imp.Transform(@(,$newHouses[$i]))
    $xNew  = ($out.Transform($xNew)).Data
    $xNew  = $sc.Transform($xNew)
    $xNew  = $poly.FitTransform($xNew, $dataMess.Features)
    $pred  = $mPipe.Predict($xNew)
    Write-Host ("  {0,-20} {1:F0}k" -f $newLabels[$i], $pred[0]) -ForegroundColor White
}

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Pipeline Summary                                ║" -ForegroundColor Cyan
Write-Host "╠══════════════════════════════════════════════════╣" -ForegroundColor Cyan
Write-Host ("║  Wrong way (leakage) R2   : {0,-21}║" -f ("{0:F4}" -f $metBad.R2))  -ForegroundColor Red
Write-Host ("║  Right way (no leak) R2   : {0,-21}║" -f ("{0:F4}" -f $metGood.R2)) -ForegroundColor Green
Write-Host ("║  Full pipeline R2         : {0,-21}║" -f ("{0:F4}" -f $metPipe.R2)) -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "=== Key Takeaways ===" -ForegroundColor Cyan
Write-Host "  ALWAYS split before fitting any preprocessor" -ForegroundColor White
Write-Host "  FitTransform on train, Transform on test — never the reverse" -ForegroundColor White
Write-Host "  Save your fitted pipeline objects to reuse for predictions" -ForegroundColor White
Write-Host "  Pipeline order matters: impute -> clip -> scale -> poly -> model" -ForegroundColor White
Write-Host ""
Write-Host "Tutorial 11 complete! Try Tutorial 12 next: Your First DQN Agent." -ForegroundColor Green
