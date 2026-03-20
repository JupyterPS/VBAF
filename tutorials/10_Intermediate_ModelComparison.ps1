<#
#Requires -Version 5.1
.SYNOPSIS
    VBAF Tutorial 10 - Model Comparison & Selection
    Intermediate Series | Estimated time: 25 minutes
.DESCRIPTION
    Learn how to:
      - Compare multiple models fairly using cross-validation
      - Use grid search to tune hyperparameters
      - Read and interpret comparison results
      - Choose the right model for your problem
      - Avoid common mistakes like overfitting to test set
#>

# ============================================================
# SECTION 1: Load the framework
# ============================================================
. .\VBAF.LoadAll.ps1

Write-Host "=== VBAF Tutorial 10: Model Comparison & Selection ===" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# SECTION 2: Why compare models?
# ============================================================
# TEACHING: No single model is best for all problems.
# Always try several and let the data decide!
# Cross-validation gives honest estimates — no peeking at test data.

Write-Host "--- Why compare models? ---" -ForegroundColor Yellow
Write-Host "  No free lunch theorem: no model wins on all datasets" -ForegroundColor White
Write-Host "  Cross-validation: split data K times, average the results" -ForegroundColor White
Write-Host "  Grid search: try all parameter combinations, pick the best" -ForegroundColor White
Write-Host ""

# ============================================================
# SECTION 3: Load and prepare data
# ============================================================
$data   = Get-VBAFDataset -Name "HousePrice"
$scaler = [StandardScaler]::new()
$Xs     = $scaler.FitTransform($data.X)
$split  = Split-TrainTest -X $Xs -y $data.y -TestSize 0.2 -Seed 42

Write-Host "  Dataset : HousePrice ($($data.X.Length) samples)" -ForegroundColor White
Write-Host "  Scaled  : StandardScaler applied" -ForegroundColor White
Write-Host ""

# ============================================================
# SECTION 4: Manual model comparison
# ============================================================
# TEACHING: Train each model, evaluate on the SAME test split.
# This is fair because all models see the same training and test data.

Write-Host "--- Manual Model Comparison ---" -ForegroundColor Yellow
Write-Host ("  {0,-28} {1,8}  {2,8}  {3}" -f "Model", "R2", "RMSE", "Bar") -ForegroundColor Yellow
Write-Host ("  {0}" -f ("-" * 60)) -ForegroundColor DarkGray

$models = @(
    @{ Name="LinearRegression";       Model=[LinearRegression]::new() },
    @{ Name="RidgeRegression(0.001)"; Model=[RidgeRegression]::new(0.001) },
    @{ Name="RidgeRegression(0.01)";  Model=[RidgeRegression]::new(0.01) },
    @{ Name="RidgeRegression(0.1)";   Model=[RidgeRegression]::new(0.1) },
    @{ Name="RidgeRegression(1.0)";   Model=[RidgeRegression]::new(1.0) },
    @{ Name="LassoRegression(0.01)";  Model=[LassoRegression]::new(0.01) },
    @{ Name="DecisionTree(depth=2)";  Model=[DecisionTree]::new("regression",2,2) },
    @{ Name="DecisionTree(depth=3)";  Model=[DecisionTree]::new("regression",3,2) },
    @{ Name="DecisionTree(depth=5)";  Model=[DecisionTree]::new("regression",5,2) }
)

$best = $null
$bestR2 = -999

foreach ($m in $models) {
    $m.Model.Fit($split.XTrain, $split.yTrain)
    $preds  = $m.Model.Predict($split.XTest)
    $met    = Get-RegressionMetrics $split.yTest $preds
    [double]$r2safe = if ([double]::IsNaN($met.R2)) { 0.0 } else { $met.R2 }
    $bar    = "█" * [int]([Math]::Max(0.0,$r2safe) * 20)
    $color  = if ($met.R2 -gt 0.95) { "Green" } elseif ($met.R2 -gt 0.8) { "Yellow" } else { "White" }
    Write-Host ("  {0,-28} {1,8:F4}  {2,8:F2}  {3}" -f $m.Name, $met.R2, $met.RMSE, $bar) -ForegroundColor $color
    if ($r2safe -gt $bestR2) { $bestR2 = $r2safe; $best = $m.Name }
}

Write-Host ""
Write-Host ("  Best model: {0} (R2={1:F4})" -f $best, $bestR2) -ForegroundColor Green
Write-Host ""

# ============================================================
# SECTION 5: Automatic algorithm selection
# ============================================================
# TEACHING: Invoke-VBAFAlgorithmSelection does cross-validation
# across all candidates automatically — no manual loop needed!

Write-Host "--- Automatic Algorithm Selection (cross-validation) ---" -ForegroundColor Yellow
$result = Invoke-VBAFAlgorithmSelection -X $Xs -y $data.y `
    -Task "regression" -Folds 5 -Metric "R2"
Write-Host ""

# ============================================================
# SECTION 6: Hyperparameter tuning with random search
# ============================================================
# TEACHING: Lambda controls regularisation strength in Ridge.
# Too small = overfits training data. Too large = underfits.
# Random search tries random combinations — faster than grid search!

Write-Host "--- Hyperparameter Tuning (Random Search) ---" -ForegroundColor Yellow
$hpo = Invoke-VBAFRandomSearch `
    -ModelFactory { param($p) [RidgeRegression]::new($p.Lambda) } `
    -ParamSpace @{ Lambda=@(0.0001, 0.001, 0.01, 0.05, 0.1, 0.5, 1.0, 5.0, 10.0) } `
    -X $Xs -y $data.y -NTrials 9 -Folds 5 -Metric "R2"

Write-Host ""
Write-Host ("  Best Lambda : {0}" -f $hpo.BestParams.Lambda) -ForegroundColor Green
Write-Host ("  Best R2     : {0:F4}" -f $hpo.BestScore)      -ForegroundColor Green
Write-Host ""

# ============================================================
# SECTION 7: Train final model with best params
# ============================================================
Write-Host "--- Final Model with Best Parameters ---" -ForegroundColor Yellow

$finalModel = [RidgeRegression]::new($hpo.BestParams.Lambda)
$finalModel.Fit($split.XTrain, $split.yTrain)
$finalPreds  = $finalModel.Predict($split.XTest)
$finalMet    = Get-RegressionMetrics $split.yTest $finalPreds

Write-Host ("  R2   : {0:F4}" -f $finalMet.R2)   -ForegroundColor Green
Write-Host ("  RMSE : {0:F2}" -f $finalMet.RMSE) -ForegroundColor White
Write-Host ""

# ============================================================
# SECTION 8: Summary
# ============================================================
Write-Host "╔══════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Model Selection Summary                         ║" -ForegroundColor Cyan
Write-Host "╠══════════════════════════════════════════════════╣" -ForegroundColor Cyan
Write-Host ("║  Best manual model  : {0,-27}║" -f $best)                          -ForegroundColor White
Write-Host ("║  Best lambda (HPO)  : {0,-27}║" -f $hpo.BestParams.Lambda)         -ForegroundColor White
Write-Host ("║  Final R2           : {0,-27}║" -f ("{0:F4}" -f $finalMet.R2))     -ForegroundColor Green
Write-Host ("║  Final RMSE         : {0,-27}║" -f ("{0:F2}" -f $finalMet.RMSE))   -ForegroundColor White
Write-Host "╚══════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "=== Key Takeaways ===" -ForegroundColor Cyan
Write-Host "  Compare models on the SAME test split for fairness" -ForegroundColor White
Write-Host "  Cross-validation gives more reliable estimates than one split" -ForegroundColor White
Write-Host "  Tune hyperparameters AFTER choosing your model family" -ForegroundColor White
Write-Host "  Never tune on the test set — that is cheating!" -ForegroundColor White
Write-Host "  Simpler model with good CV score beats complex overfitted model" -ForegroundColor White
Write-Host ""
Write-Host "Tutorial 10 complete! Try Tutorial 11 next: Pipelines." -ForegroundColor Green
