#Requires -Version 5.1
<#
.SYNOPSIS
    Model Explainability - SHAP, LIME, PDP, Feature Importance
.DESCRIPTION
    Implements model explainability from scratch.
    Designed as a TEACHING resource - every step explained.
    Features included:
      - SHAP values          : Shapley values for feature attribution
      - Feature importance   : permutation importance (model-agnostic)
      - Partial dependence   : how predictions change with one feature
      - LIME explanations    : local linear approximations
      - Model-agnostic       : works with ANY VBAF model via Predict()
    All methods only call model.Predict() - no access to internals needed!
.NOTES
    Part of VBAF - Phase 7 Production Features - v2.1.0
    PS 5.1 compatible
    Teaching project - XAI concepts explained step by step!
#>

# ============================================================
# TEACHING NOTE: Why explainability?
# "A model that cannot be explained cannot be trusted."
#
# BLACK BOX problem: complex models (Random Forest, Neural Net)
# give great predictions but we don't know WHY.
#
# EXPLAINABILITY answers:
#   "Why did the model predict £245k for this house?"
#   -> size_sqm contributed +£80k
#   -> bedrooms contributed +£20k
#   -> age_years contributed -£15k
#
# Three levels of explanation:
#   GLOBAL  : which features matter most overall?
#   LOCAL   : why this specific prediction?
#   WHAT-IF : how does changing one feature affect predictions?
# ============================================================

# ============================================================
# PERMUTATION FEATURE IMPORTANCE (global)
# ============================================================
# TEACHING NOTE: Permutation importance answers:
# "If I randomly shuffle feature X, how much does accuracy drop?"
#
# Algorithm:
#   1. Compute baseline score on all data
#   2. For each feature:
#      a. Shuffle that feature randomly
#      b. Recompute score with shuffled data
#      c. Importance = baseline - shuffled score
#   Large drop = feature was important!
#   Small drop = feature was not being used much
#
# Key advantage: works with ANY model!
# Key disadvantage: correlated features share importance.
# ============================================================

function Get-VBAFPermutationImportance {
    param(
        [object]     $Model,
        [string]     $ModelType,
        [double[][]] $X,
        [double[]]   $y,
        [string[]]   $FeatureNames = @(),
        [int]        $NRepeats     = 10,
        [string]     $Metric       = "R2",
        [int]        $Seed         = 42
    )

    $rng       = [System.Random]::new($Seed)
    $nFeatures = $X[0].Length
    $n         = $X.Length

    if ($FeatureNames.Length -eq 0) {
        $FeatureNames = 0..($nFeatures-1) | ForEach-Object { "feature$_" }
    }

    # Baseline score
    $baseline = Get-VBAFScore -Model $Model -X $X -y $y -Metric $Metric

    Write-Host ""
    Write-Host "🔀 Permutation Feature Importance" -ForegroundColor Green
    Write-Host ("   Model   : {0}" -f $ModelType)   -ForegroundColor Cyan
    Write-Host ("   Baseline: {0}={1:F4}" -f $Metric, $baseline) -ForegroundColor Cyan
    Write-Host ("   Repeats : {0}" -f $NRepeats)    -ForegroundColor Cyan
    Write-Host ""
    Write-Host ("   {0,-15} {1,10} {2,10}  {3}" -f "Feature", "Importance", "Std", "Bar") -ForegroundColor Yellow
    Write-Host ("   {0}" -f ("-" * 55)) -ForegroundColor DarkGray

    $results = @()
    for ($f = 0; $f -lt $nFeatures; $f++) {
        $scores = @()
        for ($r = 0; $r -lt $NRepeats; $r++) {
            # Shuffle feature f
            $Xshuffled = @()
            $colVals   = @($X | ForEach-Object { $_[$f] })
            # Fisher-Yates shuffle
            for ($i = $colVals.Length - 1; $i -gt 0; $i--) {
                $j = $rng.Next(0, $i + 1)
                $tmp = $colVals[$i]; $colVals[$i] = $colVals[$j]; $colVals[$j] = $tmp
            }
            for ($i = 0; $i -lt $n; $i++) {
                $row = [double[]]$X[$i].Clone()
                $row[$f] = $colVals[$i]
                $Xshuffled += ,$row
            }
            $scores += Get-VBAFScore -Model $Model -X $Xshuffled -y $y -Metric $Metric
        }
        $avgScore  = ($scores | Measure-Object -Average).Average
        $importance= [Math]::Round($baseline - $avgScore, 4)
        $mean      = ($scores | Measure-Object -Average).Average
        $std       = [Math]::Round([Math]::Sqrt((($scores | ForEach-Object { ($_ - $mean)*($_ - $mean) } | Measure-Object -Sum).Sum / $scores.Count)), 4)
        $bar       = "█" * [int]([Math]::Max(0, $importance * 30))
        $color     = if ($importance -gt 0.05) { "Green" } elseif ($importance -gt 0) { "Yellow" } else { "DarkGray" }
        Write-Host ("   {0,-15} {1,10:F4} {2,10:F4}  {3}" -f $FeatureNames[$f], $importance, $std, $bar) -ForegroundColor $color
        $results += @{ Feature=$FeatureNames[$f]; Importance=$importance; Std=$std; Index=$f }
    }

    $sorted = $results | Sort-Object { $_.Importance } -Descending
    Write-Host ""
    Write-Host ("   Most important: {0} (Δ{1}={2:F4})" -f $sorted[0].Feature, $Metric, $sorted[0].Importance) -ForegroundColor Green
    Write-Host ""
    return $results
}

# ============================================================
# SHAP VALUES (local + global)
# ============================================================
# TEACHING NOTE: SHAP = SHapley Additive exPlanations
# Based on game theory! Imagine features are "players" in a game
# where the "payout" is the model prediction.
# SHAP fairly distributes the payout among players.
#
# Shapley value formula (simplified):
#   For each feature, average its marginal contribution
#   across ALL possible subsets of other features.
#
# Property: SHAP values always sum to:
#   prediction - expected_prediction (baseline)
# This is the EFFICIENCY property - SHAP is fully faithful!
#
# Exact SHAP is exponential in features. We use sampling:
#   - Sample random subsets
#   - Measure marginal contribution of each feature
#   - Average across samples
# ============================================================

function Get-VBAFSHAPValues {
    param(
        [object]     $Model,
        [double[]]   $Instance,       # single sample to explain
        [double[][]] $Background,     # reference distribution (training data)
        [string[]]   $FeatureNames = @(),
        [int]        $NSamples     = 50,
        [int]        $Seed         = 42
    )

    $rng       = [System.Random]::new($Seed)
    $nFeatures = $Instance.Length
    if ($FeatureNames.Length -eq 0) {
        $FeatureNames = 0..($nFeatures-1) | ForEach-Object { "f$_" }
    }

    # Expected prediction (baseline)
    $bgPreds  = @($Background | ForEach-Object { $Model.Predict(@(,[double[]]$_))[0] })
    $baseline = ($bgPreds | Measure-Object -Average).Average

    # Instance prediction
    $instancePred = $Model.Predict(@(,$Instance))[0]

    # Estimate Shapley values via sampling
    $shapValues = @(0.0) * $nFeatures

    for ($s = 0; $s -lt $NSamples; $s++) {
        # Pick random background sample
        $bgSample = [double[]]$Background[$rng.Next(0, $Background.Length)]

        # Random feature ordering
        $order = @(0..($nFeatures-1))
        for ($i = $order.Length - 1; $i -gt 0; $i--) {
            $j = $rng.Next(0, $i+1); $tmp = $order[$i]; $order[$i] = $order[$j]; $order[$j] = $tmp
        }

        # Walk through order, compute marginal contribution of each feature
        $current = [double[]]$bgSample.Clone()
        foreach ($f in $order) {
            $before      = $Model.Predict(@(,$current))[0]
            $current[$f] = $Instance[$f]
            $after       = $Model.Predict(@(,$current))[0]
            $shapValues[$f] += ($after - $before)
        }
    }

    # Average over samples
    for ($f = 0; $f -lt $nFeatures; $f++) { $shapValues[$f] /= $NSamples }

    return @{
        Values       = $shapValues
        Baseline     = $baseline
        Prediction   = $instancePred
        FeatureNames = $FeatureNames
        Instance     = $Instance
    }
}

function Show-VBAFSHAPExplanation {
    param([hashtable]$SHAP, [string]$ModelType = "")

    Write-Host ""
    Write-Host "🎯 SHAP Explanation" -ForegroundColor Green
    if ($ModelType -ne "") { Write-Host ("   Model: {0}" -f $ModelType) -ForegroundColor Cyan }
    Write-Host ("   Baseline prediction : {0:F4}" -f $SHAP.Baseline)   -ForegroundColor DarkGray
    Write-Host ("   Actual prediction   : {0:F4}" -f $SHAP.Prediction) -ForegroundColor White
    Write-Host ("   SHAP sum            : {0:F4}" -f ($SHAP.Values | Measure-Object -Sum).Sum) -ForegroundColor DarkGray
    Write-Host ""
    Write-Host ("   {0,-15} {1,8}  {2,10}  {3}" -f "Feature", "Value", "SHAP", "Contribution") -ForegroundColor Yellow
    Write-Host ("   {0}" -f ("-" * 60)) -ForegroundColor DarkGray

    $sorted = @()
    for ($f = 0; $f -lt $SHAP.Values.Length; $f++) {
        $sorted += @{ Name=$SHAP.FeatureNames[$f]; Value=$SHAP.Instance[$f]; SHAP=$SHAP.Values[$f] }
    }
    $sorted = $sorted | Sort-Object { [Math]::Abs($_.SHAP) } -Descending

    foreach ($s in $sorted) {
        $bar   = "█" * [int]([Math]::Min(20, [Math]::Abs($s.SHAP) * 5))
        $sign  = if ($s.SHAP -ge 0) { "+" } else { "-" }
        $color = if ($s.SHAP -gt 0) { "Green" } elseif ($s.SHAP -lt 0) { "Red" } else { "DarkGray" }
        Write-Host ("   {0,-15} {1,8:F2}  {2}{3,9:F4}  {4}{5}" -f $s.Name, $s.Value, $sign, [Math]::Abs($s.SHAP), $bar, $sign) -ForegroundColor $color
    }
    Write-Host ""
}

# ============================================================
# PARTIAL DEPENDENCE PLOTS (PDP)
# ============================================================
# TEACHING NOTE: PDP answers "how does prediction change
# when I vary feature X, holding everything else constant?"
#
# Algorithm:
#   For each value v in feature X's range:
#     1. Replace feature X with v for ALL samples
#     2. Compute mean prediction
#     3. Plot mean prediction vs v
#
# This marginalizes out all other features!
# Shows the pure effect of X on predictions.
# ============================================================

function Get-VBAFPartialDependence {
    param(
        [object]     $Model,
        [double[][]] $X,
        [int]        $FeatureIndex,
        [string]     $FeatureName  = "",
        [int]        $NGrid        = 20    # number of values to evaluate
    )

    $name    = if ($FeatureName -ne "") { $FeatureName } else { "feature$FeatureIndex" }
    $colVals = @($X | ForEach-Object { [double]$_[$FeatureIndex] })
    $minVal  = ($colVals | Measure-Object -Minimum).Minimum
    $maxVal  = ($colVals | Measure-Object -Maximum).Maximum
    $step    = ($maxVal - $minVal) / ($NGrid - 1)

    $gridVals = @()
    $pdpMeans = @()

    for ($g = 0; $g -lt $NGrid; $g++) {
        $val    = $minVal + $g * $step
        $gridVals += $val
        # Replace feature with val for all samples
        $Xmod   = @($X | ForEach-Object {
            $row = [double[]]$_.Clone()
            $row[$FeatureIndex] = $val
            ,$row
        })
        $preds    = @($Xmod | ForEach-Object { $Model.Predict(@(,[double[]]$_))[0] })
        $pdpMeans += ($preds | Measure-Object -Average).Average
    }

    # ASCII plot
    $minPDP = ($pdpMeans | Measure-Object -Minimum).Minimum
    $maxPDP = ($pdpMeans | Measure-Object -Maximum).Maximum
    $range  = [Math]::Max($maxPDP - $minPDP, 0.001)
    $height = 8

    Write-Host ""
    Write-Host ("📈 Partial Dependence: {0}" -f $name) -ForegroundColor Green
    Write-Host ("   Range: [{0:F1}, {1:F1}]  PDP: [{2:F2}, {3:F2}]" -f $minVal, $maxVal, $minPDP, $maxPDP) -ForegroundColor DarkGray
    Write-Host ""

    # Build grid
    $grid = @()
    for ($row = 0; $row -lt $height; $row++) { $grid += ,(@(" ") * $NGrid) }
    for ($g = 0; $g -lt $NGrid; $g++) {
        $row = $height - 1 - [int](($pdpMeans[$g] - $minPDP) / $range * ($height - 1))
        $row = [Math]::Max(0, [Math]::Min($height-1, $row))
        $grid[$row][$g] = "●"
    }

    $yLabels = @($maxPDP, ($maxPDP+$minPDP)/2, $minPDP)
    for ($row = 0; $row -lt $height; $row++) {
        $yLabel = if ($row -eq 0) { "{0,7:F1} " -f $maxPDP }
                  elseif ($row -eq [int]($height/2)) { "{0,7:F1} " -f (($maxPDP+$minPDP)/2) }
                  elseif ($row -eq $height-1) { "{0,7:F1} " -f $minPDP }
                  else { "        " }
        Write-Host ("{0}│{1}" -f $yLabel, ($grid[$row] -join "")) -ForegroundColor Cyan
    }
    Write-Host ("        └{0}" -f ("─" * $NGrid)) -ForegroundColor Cyan
    Write-Host ("         {0,-10} {1,10}" -f ("{0:F1}" -f $minVal), ("{0:F1}" -f $maxVal)) -ForegroundColor DarkGray
    Write-Host ("         {0}" -f $name) -ForegroundColor DarkGray
    Write-Host ""

    return @{ GridValues=$gridVals; PDPMeans=$pdpMeans; FeatureName=$name }
}

# ============================================================
# LIME EXPLANATIONS (local)
# ============================================================
# TEACHING NOTE: LIME = Local Interpretable Model-agnostic Explanations
# Key idea: even if the global model is complex and non-linear,
# it's approximately LINEAR in a small neighbourhood!
#
# Algorithm for one instance x:
#   1. Sample N perturbed versions of x (add small noise)
#   2. Get predictions from the black-box model for all perturbed samples
#   3. Weight samples by similarity to x (closer = higher weight)
#   4. Fit a SIMPLE LINEAR MODEL on the weighted samples
#   5. The linear model's coefficients = LIME explanation!
#
# The linear model is the explanation - easy to understand!
# ============================================================

function Get-VBAFLIMEExplanation {
    param(
        [object]     $Model,
        [double[]]   $Instance,
        [double[][]] $X,             # training data for feature statistics
        [string[]]   $FeatureNames = @(),
        [int]        $NSamples     = 100,
        [double]     $KernelWidth  = 0.75,
        [int]        $Seed         = 42
    )

    $rng       = [System.Random]::new($Seed)
    $nFeatures = $Instance.Length
    if ($FeatureNames.Length -eq 0) {
        $FeatureNames = 0..($nFeatures-1) | ForEach-Object { "f$_" }
    }

    # Feature statistics for perturbation
    $means = @(0.0) * $nFeatures
    $stds  = @(0.0) * $nFeatures
    for ($f = 0; $f -lt $nFeatures; $f++) {
        $vals     = @($X | ForEach-Object { [double]$_[$f] })
        $means[$f]= ($vals | Measure-Object -Average).Average
        $variance = ($vals | ForEach-Object { ($_ - $means[$f])*($_ - $means[$f]) } | Measure-Object -Sum).Sum / $vals.Count
        $stds[$f] = [Math]::Max(0.001, [Math]::Sqrt($variance))
    }

    # Generate perturbed samples
    $perturbedX    = @()
    $perturbedPred = @()
    $weights       = @()

    for ($s = 0; $s -lt $NSamples; $s++) {
        $sample = @(0.0) * $nFeatures
        for ($f = 0; $f -lt $nFeatures; $f++) {
            # Box-Muller Gaussian noise
            $u1       = [Math]::Max(1e-10, $rng.NextDouble())
            $u2       = $rng.NextDouble()
            $gauss    = [Math]::Sqrt(-2.0 * [Math]::Log($u1)) * [Math]::Cos(2.0 * [Math]::PI * $u2)
            $sample[$f] = $Instance[$f] + $gauss * $stds[$f] * 0.5
        }
        $pred = $Model.Predict(@(,[double[]]$sample))[0]
        $perturbedX    += ,$sample
        $perturbedPred += $pred

        # Kernel weight: similarity to instance
        $dist = 0.0
        for ($f = 0; $f -lt $nFeatures; $f++) {
            $d     = ($sample[$f] - $Instance[$f]) / $stds[$f]
            $dist += $d * $d
        }
        $weights += [Math]::Exp(-$dist / (2.0 * $KernelWidth * $KernelWidth))
    }

    # Fit weighted linear model (WLS: weighted least squares)
    # Normal equations: (X'WX)^-1 X'Wy (simplified for small feature sets)
    $coeffs = Get-VBAFWeightedLinearFit -X $perturbedX -y $perturbedPred -W $weights

    # Intercept = instance prediction for reference
    $instancePred = $Model.Predict(@(,$Instance))[0]

    Write-Host ""
    Write-Host "🍋 LIME Explanation" -ForegroundColor Green
    Write-Host ("   Instance prediction: {0:F4}" -f $instancePred) -ForegroundColor White
    Write-Host ("   Local model R2     : ~approx") -ForegroundColor DarkGray
    Write-Host ""
    Write-Host ("   {0,-15} {1,8}  {2,10}  {3}" -f "Feature", "Value", "Coefficient", "Impact") -ForegroundColor Yellow
    Write-Host ("   {0}" -f ("-" * 58)) -ForegroundColor DarkGray

    $sorted = @()
    for ($f = 0; $f -lt $nFeatures; $f++) {
        $impact = $coeffs[$f] * $Instance[$f]
        $sorted += @{ Name=$FeatureNames[$f]; Value=$Instance[$f]; Coeff=$coeffs[$f]; Impact=$impact }
    }
    $sorted = $sorted | Sort-Object { [Math]::Abs($_.Impact) } -Descending

    foreach ($s in $sorted) {
        $bar   = "█" * [int]([Math]::Min(15, [Math]::Abs($s.Impact) / [Math]::Max(0.001, [Math]::Abs($instancePred)) * 15))
        $sign  = if ($s.Impact -ge 0) { "+" } else { "-" }
        $color = if ($s.Impact -gt 0) { "Green" } elseif ($s.Impact -lt 0) { "Red" } else { "DarkGray" }
        Write-Host ("   {0,-15} {1,8:F2}  {2,10:F4}  {3}{4}" -f $s.Name, $s.Value, $s.Coeff, $bar, $sign) -ForegroundColor $color
    }
    Write-Host ""

    return @{ Coefficients=$coeffs; FeatureNames=$FeatureNames; Instance=$Instance; Prediction=$instancePred }
}

# Weighted least squares helper
function Get-VBAFWeightedLinearFit {
    param([double[][]]$X, [double[]]$y, [double[]]$W)

    $n = $X.Length; $p = $X[0].Length
    # Gradient descent on weighted MSE (simple, PS 5.1 safe)
    $coeffs = @(0.0) * $p
    $lr     = 0.01
    $totalW = ($W | Measure-Object -Sum).Sum

    for ($iter = 0; $iter -lt 200; $iter++) {
        $grad = @(0.0) * $p
        for ($i = 0; $i -lt $n; $i++) {
            $xi   = [double[]]$X[$i]
            $pred = 0.0
            for ($f = 0; $f -lt $p; $f++) { $pred += $coeffs[$f] * $xi[$f] }
            $err  = $pred - $y[$i]
            for ($f = 0; $f -lt $p; $f++) {
                $grad[$f] += $W[$i] * $err * $xi[$f]
            }
        }
        for ($f = 0; $f -lt $p; $f++) {
            $coeffs[$f] = $coeffs[$f] - $lr * $grad[$f] / $totalW
        }
    }
    return $coeffs
}

# ============================================================
# SCORING HELPER (model-agnostic)
# ============================================================

function Get-VBAFScore {
    param([object]$Model, [double[][]]$X, [double[]]$y, [string]$Metric = "R2")

    $preds = @($X | ForEach-Object { $Model.Predict(@(,[double[]]$_))[0] })
    $mean  = ($y | Measure-Object -Average).Average

    switch ($Metric) {
        "R2" {
            $ssTot = ($y | ForEach-Object { ($_ - $mean)*($_ - $mean) } | Measure-Object -Sum).Sum
            $ssRes = 0.0
            for ($i = 0; $i -lt $y.Length; $i++) { $ssRes += ($y[$i] - $preds[$i]) * ($y[$i] - $preds[$i]) }
            if ($ssTot -gt 0) { return 1.0 - $ssRes / $ssTot } else { return 1.0 }
        }
        "RMSE" {
            $mse = 0.0
            for ($i = 0; $i -lt $y.Length; $i++) { $mse += ($y[$i] - $preds[$i]) * ($y[$i] - $preds[$i]) }
            return [Math]::Sqrt($mse / $y.Length)
        }
        "Accuracy" {
            $correct = 0
            for ($i = 0; $i -lt $y.Length; $i++) { if ([int]$preds[$i] -eq [int]$y[$i]) { $correct++ } }
            return $correct / $y.Length
        }
    }
    return 0.0
}

# ============================================================
# TEST
# 1. Run VBAF.LoadAll.ps1
#
# --- Train a model ---
# 2. $data   = Get-VBAFDataset -Name "HousePrice"
#    $scaler = [StandardScaler]::new()
#    $Xs     = $scaler.FitTransform($data.X)
#    $model  = [LinearRegression]::new()
#    $model.Fit($Xs, $data.y)
#
# --- Permutation importance ---
# 3. Get-VBAFPermutationImportance -Model $model -ModelType "LinearRegression" `
#        -X $Xs -y $data.y -FeatureNames @("size_sqm","bedrooms","age_years")
#
# --- SHAP values ---
# 4. $instance = [double[]]$Xs[0]
#    $shap = Get-VBAFSHAPValues -Model $model -Instance $instance -Background $Xs `
#                -FeatureNames @("size_sqm","bedrooms","age_years")
#    Show-VBAFSHAPExplanation -SHAP $shap -ModelType "LinearRegression"
#
# --- Partial dependence ---
# 5. Get-VBAFPartialDependence -Model $model -X $Xs -FeatureIndex 0 `
#        -FeatureName "size_sqm"
#
# --- LIME ---
# 6. Get-VBAFLIMEExplanation -Model $model -Instance $instance -X $Xs `
#        -FeatureNames @("size_sqm","bedrooms","age_years")
# ============================================================
Write-Host "📦 VBAF.ML.Explainability.ps1 loaded  [v2.1.0 🔍]" -ForegroundColor Green
Write-Host "   Functions : Get-VBAFPermutationImportance"      -ForegroundColor Cyan
Write-Host "              Get-VBAFSHAPValues"                   -ForegroundColor Cyan
Write-Host "              Show-VBAFSHAPExplanation"             -ForegroundColor Cyan
Write-Host "              Get-VBAFPartialDependence"            -ForegroundColor Cyan
Write-Host "              Get-VBAFLIMEExplanation"              -ForegroundColor Cyan
Write-Host "              Get-VBAFScore"                        -ForegroundColor Cyan
Write-Host ""
Write-Host "   Quick start:" -ForegroundColor Yellow
Write-Host '   $data   = Get-VBAFDataset -Name "HousePrice"'   -ForegroundColor White
Write-Host '   $scaler = [StandardScaler]::new()'              -ForegroundColor White
Write-Host '   $Xs     = $scaler.FitTransform($data.X)'        -ForegroundColor White
Write-Host '   $model  = [LinearRegression]::new()'            -ForegroundColor White
Write-Host '   $model.Fit($Xs, $data.y)'                       -ForegroundColor White
Write-Host '   Get-VBAFPermutationImportance -Model $model -ModelType "LinearRegression" -X $Xs -y $data.y -FeatureNames @("size_sqm","bedrooms","age_years")' -ForegroundColor White
Write-Host ""