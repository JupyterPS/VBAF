#Requires -Version 5.1
<#
.SYNOPSIS
    AutoML - Automated Machine Learning for VBAF
.DESCRIPTION
    Implements AutoML workflows from scratch.
    Designed as a TEACHING resource - every step explained.
    Features included:
      - Hyperparameter optimization : Grid, Random, Bayesian search
      - Algorithm selection         : auto-select best model type
      - Feature selection           : auto-select best features
      - Pipeline automation         : chain steps automatically
    Neural Architecture Search: skipped - requires repeated neural
    network backprop which is not reliable in PS 5.1 class methods.
    All other features are pure math/loops - fully PS 5.1 compatible!
.NOTES
    Part of VBAF - Phase 7 Production Features - v2.1.0
    PS 5.1 compatible
    Teaching project - AutoML concepts explained step by step!
#>

# ============================================================
# TEACHING NOTE: What is AutoML?
# AutoML = Automated Machine Learning.
# Instead of manually tuning hyperparameters, AutoML searches
# the space of possible configurations automatically!
#
# Three main search strategies:
#   GRID SEARCH    : try every combination (exhaustive, slow)
#   RANDOM SEARCH  : try random combinations (faster, surprisingly good!)
#   BAYESIAN OPT   : use past results to guide next try (smartest!)
#
# Bayesian optimization key insight:
#   After each trial, we build a model of "which configs are promising"
#   and sample from promising regions rather than randomly.
#   This converges much faster than random search!
# ============================================================

# ============================================================
# CROSS-VALIDATION HELPER (shared by all search methods)
# ============================================================

function Invoke-AutoMLCrossVal {
    param(
        [object]     $Model,
        [double[][]] $X,
        [double[]]   $y,
        [int]        $Folds   = 5,
        [string]     $Metric  = "R2"   # R2, RMSE, Accuracy
    )

    $n       = $X.Length
    $foldSz  = [int]([Math]::Floor($n / $Folds))
    $scores  = @()

    for ($f = 0; $f -lt $Folds; $f++) {
        $valStart = $f * $foldSz
        $valEnd   = [Math]::Min($valStart + $foldSz - 1, $n - 1)

        $trainX = @(); $trainY = @(); $valX = @(); $valY = @()
        for ($i = 0; $i -lt $n; $i++) {
            if ($i -ge $valStart -and $i -le $valEnd) {
                $valX += ,[double[]]$X[$i]; $valY += $y[$i]
            } else {
                $trainX += ,[double[]]$X[$i]; $trainY += $y[$i]
            }
        }

        if ($trainX.Count -eq 0 -or $valX.Count -eq 0) { continue }

        try {
            $Model.Fit($trainX, $trainY)
            $preds = $Model.Predict($valX)

            $score = switch ($Metric) {
                "R2" {
                    $mean  = ($valY | Measure-Object -Average).Average
                    $ssTot = ($valY | ForEach-Object { ($_ - $mean)*($_ - $mean) } | Measure-Object -Sum).Sum
                    $ssRes = 0.0
                    for ($i = 0; $i -lt $valY.Count; $i++) { $ssRes += ($valY[$i] - $preds[$i]) * ($valY[$i] - $preds[$i]) }
                    if ($ssTot -gt 0) { 1.0 - $ssRes / $ssTot } else { 1.0 }
                }
                "RMSE" {
                    $mse = 0.0
                    for ($i = 0; $i -lt $valY.Count; $i++) { $mse += ($valY[$i] - $preds[$i]) * ($valY[$i] - $preds[$i]) }
                    -[Math]::Sqrt($mse / $valY.Count)   # negative so higher=better
                }
                "Accuracy" {
                    $correct = 0
                    for ($i = 0; $i -lt $valY.Count; $i++) { if ([int]$preds[$i] -eq [int]$valY[$i]) { $correct++ } }
                    $correct / $valY.Count
                }
                default { 0.0 }
            }
            $scores += $score
        } catch { }
    }

    if ($scores.Count -eq 0) { return 0.0 }
    return ($scores | Measure-Object -Average).Average
}

# ============================================================
# GRID SEARCH
# ============================================================
# TEACHING NOTE: Grid search = exhaustive search.
# You define a grid of hyperparameter values:
#   LearningRate: [0.001, 0.01, 0.1]
#   Lambda:       [0.0,   0.1,  1.0]
# Grid search tries ALL 3x3=9 combinations.
# Great for small grids, impractical for large ones!
# 10 params x 10 values each = 10^10 combinations (impossible!)
# ============================================================

function Invoke-VBAFGridSearch {
    param(
        [scriptblock] $ModelFactory,   # { param($params) return [Model]::new($params.Lambda) }
        [hashtable]   $ParamGrid,      # @{ Lambda=@(0.0,0.1,1.0); Lr=@(0.001,0.01) }
        [double[][]]  $X,
        [double[]]    $y,
        [int]         $Folds  = 5,
        [string]      $Metric = "R2"
    )

    # Build all combinations
    $keys   = @($ParamGrid.Keys)
    $combos = @(@{})
    foreach ($key in $keys) {
        $newCombos = @()
        foreach ($existing in $combos) {
            foreach ($val in $ParamGrid[$key]) {
                $newCombo = @{}
                foreach ($k in $existing.Keys) { $newCombo[$k] = $existing[$k] }
                $newCombo[$key] = $val
                $newCombos += $newCombo
            }
        }
        $combos = $newCombos
    }

    Write-Host ""
    Write-Host ("🔲 Grid Search: {0} combinations x {1} folds = {2} fits" -f $combos.Count, $Folds, ($combos.Count * $Folds)) -ForegroundColor Green

    $results  = @()
    $best     = $null
    $bestScore= [double]::MinValue
    $trial    = 0

    foreach ($combo in $combos) {
        $trial++
        try {
            $model = & $ModelFactory $combo
            $score = Invoke-AutoMLCrossVal -Model $model -X $X -y $y -Folds $Folds -Metric $Metric
        } catch { $score = [double]::MinValue }

        $paramStr = ($combo.Keys | ForEach-Object { "{0}={1}" -f $_, $combo[$_] }) -join "  "
        $isBest   = $score -gt $bestScore
        if ($isBest) { $bestScore = $score; $best = $combo }
        $marker = if ($isBest) { " ★" } else { "" }
        $color  = if ($isBest) { "Green" } else { "DarkGray" }
        Write-Host ("  [{0,3}/{1}] {2,-35} {3}={4:F4}{5}" -f $trial, $combos.Count, $paramStr, $Metric, $score, $marker) -ForegroundColor $color

        $results += @{ Params=$combo; Score=$score }
    }

    Write-Host ""
    Write-Host ("✅ Best: {0}={1:F4}" -f $Metric, $bestScore) -ForegroundColor Green
    $paramStr = ($best.Keys | ForEach-Object { "{0}={1}" -f $_, $best[$_] }) -join "  "
    Write-Host ("   Params: {0}" -f $paramStr) -ForegroundColor White
    Write-Host ""

    return @{ BestParams=$best; BestScore=$bestScore; AllResults=$results }
}

# ============================================================
# RANDOM SEARCH
# ============================================================
# TEACHING NOTE: Random search = sample random combinations.
# Key insight from Bergstra & Bengio (2012):
#   Random search finds good configs faster than grid search
#   because not all hyperparameters matter equally!
#   If only 2 of 10 params matter, grid search wastes time
#   on the unimportant 8. Random search covers all 10 better
#   with the same number of trials.
# ============================================================

function Invoke-VBAFRandomSearch {
    param(
        [scriptblock] $ModelFactory,
        [hashtable]   $ParamSpace,   # @{ Lambda=@(0.0,0.1,1.0); Lr=@(0.001,0.01,0.1) }
        [double[][]]  $X,
        [double[]]    $y,
        [int]         $NTrials = 20,
        [int]         $Folds   = 5,
        [string]      $Metric  = "R2",
        [int]         $Seed    = 42
    )

    $rng  = [System.Random]::new($Seed)
    $keys = @($ParamSpace.Keys)

    Write-Host ""
    Write-Host ("🎲 Random Search: {0} trials x {1} folds = {2} fits" -f $NTrials, $Folds, ($NTrials * $Folds)) -ForegroundColor Green

    $results   = @()
    $best      = $null
    $bestScore = [double]::MinValue

    for ($trial = 1; $trial -le $NTrials; $trial++) {
        # Sample random config
        $combo = @{}
        foreach ($key in $keys) {
            $vals       = $ParamSpace[$key]
            $combo[$key]= $vals[$rng.Next(0, $vals.Count)]
        }

        try {
            $model = & $ModelFactory $combo
            $score = Invoke-AutoMLCrossVal -Model $model -X $X -y $y -Folds $Folds -Metric $Metric
        } catch { $score = [double]::MinValue }

        $paramStr = ($combo.Keys | ForEach-Object { "{0}={1}" -f $_, $combo[$_] }) -join "  "
        $isBest   = $score -gt $bestScore
        if ($isBest) { $bestScore = $score; $best = $combo }
        $marker = if ($isBest) { " ★" } else { "" }
        $color  = if ($isBest) { "Green" } else { "DarkGray" }
        Write-Host ("  [{0,3}/{1}] {2,-35} {3}={4:F4}{5}" -f $trial, $NTrials, $paramStr, $Metric, $score, $marker) -ForegroundColor $color

        $results += @{ Params=$combo; Score=$score }
    }

    Write-Host ""
    Write-Host ("✅ Best: {0}={1:F4}" -f $Metric, $bestScore) -ForegroundColor Green
    $paramStr = ($best.Keys | ForEach-Object { "{0}={1}" -f $_, $best[$_] }) -join "  "
    Write-Host ("   Params: {0}" -f $paramStr) -ForegroundColor White
    Write-Host ""

    return @{ BestParams=$best; BestScore=$bestScore; AllResults=$results }
}

# ============================================================
# BAYESIAN OPTIMIZATION
# ============================================================
# TEACHING NOTE: Bayesian optimization is much smarter!
# It maintains a SURROGATE MODEL of the objective function
# (approximating "what score will I get for this config?")
# and uses an ACQUISITION FUNCTION to pick the next config.
#
# Our simplified version:
#   1. Run a few random trials to warm up
#   2. Fit a simple surrogate: weighted average of past results
#   3. Use Upper Confidence Bound (UCB) acquisition:
#      score_estimate + exploration_bonus
#   4. Pick config with highest UCB, evaluate it
#   5. Update surrogate and repeat
#
# This balances EXPLOITATION (try configs near good ones)
# and EXPLORATION (try configs we haven't seen yet)!
# ============================================================

function Invoke-VBAFBayesianSearch {
    param(
        [scriptblock] $ModelFactory,
        [hashtable]   $ParamSpace,
        [double[][]]  $X,
        [double[]]    $y,
        [int]         $NTrials     = 20,
        [int]         $WarmupTrials= 5,    # random trials before Bayesian kicks in
        [int]         $Folds       = 5,
        [string]      $Metric      = "R2",
        [double]       $Kappa       = 2.0,  # exploration weight in UCB
        [int]         $Seed        = 42
    )

    $rng      = [System.Random]::new($Seed)
    $keys     = @($ParamSpace.Keys)
    $history  = @()   # @{ Params=@{}; Score=double; Vector=double[] }
    $best     = $null
    $bestScore= [double]::MinValue

    Write-Host ""
    Write-Host ("🧠 Bayesian Search: {0} trials ({1} warmup) x {2} folds" -f $NTrials, $WarmupTrials, $Folds) -ForegroundColor Green
    Write-Host ("   Kappa (exploration)={0}" -f $Kappa) -ForegroundColor DarkGray

    # Build candidate pool (all combinations, or large random sample)
    $allCombos  = @(@{})
    foreach ($key in $keys) {
        $newCombos = @()
        foreach ($existing in $allCombos) {
            foreach ($val in $ParamSpace[$key]) {
                $newCombo = @{}
                foreach ($k in $existing.Keys) { $newCombo[$k] = $existing[$k] }
                $newCombo[$key] = $val
                $newCombos += $newCombo
            }
        }
        $allCombos = $newCombos
    }

    # Encode combos as numeric vectors for surrogate
    function Get-ComboVector {
        param([hashtable]$combo)
        $vec = @()
        foreach ($key in $keys) {
            $vals  = $ParamSpace[$key]
            $idx   = [array]::IndexOf($vals, $combo[$key])
            $vec  += [double]$idx / [Math]::Max(1, $vals.Count - 1)
        }
        return $vec
    }

    for ($trial = 1; $trial -le $NTrials; $trial++) {
        $isWarmup = $trial -le $WarmupTrials
        $combo    = $null

        if ($isWarmup -or $history.Count -lt 2) {
            # Random warmup
            $combo = @{}
            foreach ($key in $keys) {
                $vals       = $ParamSpace[$key]
                $combo[$key]= $vals[$rng.Next(0, $vals.Count)]
            }
        } else {
            # Bayesian: use UCB acquisition over all candidates
            $bestUCB   = [double]::MinValue
            $bestCombo = $allCombos[0]

            foreach ($cand in $allCombos) {
                $candVec = Get-ComboVector $cand

                # Surrogate: weighted mean of past scores (closer = higher weight)
                $weightedSum = 0.0; $totalWeight = 0.0
                foreach ($h in $history) {
                    $dist = 0.0
                    for ($d = 0; $d -lt $candVec.Length; $d++) {
                        $diff  = $candVec[$d] - $h.Vector[$d]
                        $dist += $diff * $diff
                    }
                    $w            = [Math]::Exp(-5.0 * $dist)
                    $weightedSum += $w * $h.Score
                    $totalWeight += $w
                }
                $mu  = if ($totalWeight -gt 0) { $weightedSum / $totalWeight } else { 0.0 }

                # Uncertainty: distance from nearest observed point
                $minDist = [double]::MaxValue
                foreach ($h in $history) {
                    $dist = 0.0
                    for ($d = 0; $d -lt $candVec.Length; $d++) {
                        $diff  = $candVec[$d] - $h.Vector[$d]
                        $dist += $diff * $diff
                    }
                    if ($dist -lt $minDist) { $minDist = $dist }
                }
                $sigma = [Math]::Sqrt($minDist)
                $ucb   = $mu + $Kappa * $sigma

                if ($ucb -gt $bestUCB) { $bestUCB = $ucb; $bestCombo = $cand }
            }
            $combo = $bestCombo
        }

        try {
            $model = & $ModelFactory $combo
            $score = Invoke-AutoMLCrossVal -Model $model -X $X -y $y -Folds $Folds -Metric $Metric
        } catch { $score = [double]::MinValue }

        $vec     = Get-ComboVector $combo
        $history += @{ Params=$combo; Score=$score; Vector=$vec }

        $isBest  = $score -gt $bestScore
        if ($isBest) { $bestScore = $score; $best = $combo }
        $marker  = if ($isBest) { " ★" } else { "" }
        $mode    = if ($isWarmup) { "warmup" } else { "bayes " }
        $color   = if ($isBest) { "Green" } elseif ($isWarmup) { "DarkGray" } else { "White" }
        $paramStr= ($combo.Keys | ForEach-Object { "{0}={1}" -f $_, $combo[$_] }) -join "  "
        Write-Host ("  [{0,3}/{1}] [{2}] {3,-30} {4}={5:F4}{6}" -f $trial, $NTrials, $mode, $paramStr, $Metric, $score, $marker) -ForegroundColor $color
    }

    Write-Host ""
    Write-Host ("✅ Best: {0}={1:F4}" -f $Metric, $bestScore) -ForegroundColor Green
    $paramStr = ($best.Keys | ForEach-Object { "{0}={1}" -f $_, $best[$_] }) -join "  "
    Write-Host ("   Params: {0}" -f $paramStr) -ForegroundColor White
    Write-Host ""

    return @{ BestParams=$best; BestScore=$bestScore; History=$history }
}

# ============================================================
# ALGORITHM SELECTION
# ============================================================
# TEACHING NOTE: Why try multiple algorithms?
# No Free Lunch theorem: no single algorithm is best for all problems!
# AutoML tests multiple candidates and picks the winner.
#
# For regression: Linear, Ridge, Lasso
# For classification: Logistic, GaussianNB, DecisionTree
# ============================================================

function Invoke-VBAFAlgorithmSelection {
    param(
        [double[][]] $X,
        [double[]]   $y,
        [string]     $Task   = "regression",   # regression, classification
        [int]        $Folds  = 5,
        [string]     $Metric = "R2"
    )

    $candidates = if ($Task -eq "regression") {
        @(
            @{ Name="LinearRegression";  Factory={ [LinearRegression]::new() } },
            @{ Name="RidgeRegression_01"; Factory={ [RidgeRegression]::new(0.1) } },
            @{ Name="RidgeRegression_1";  Factory={ [RidgeRegression]::new(1.0) } },
            @{ Name="LassoRegression_01"; Factory={ [LassoRegression]::new(0.1) } },
            @{ Name="DecisionTree_d3";    Factory={ [DecisionTree]::new("regression", 3, 2) } },
            @{ Name="DecisionTree_d5";    Factory={ [DecisionTree]::new("regression", 5, 2) } }
        )
    } else {
        @(
            @{ Name="LogisticRegression"; Factory={ [LogisticRegression]::new() } },
            @{ Name="GaussianNaiveBayes"; Factory={ [GaussianNaiveBayes]::new() } },
            @{ Name="DecisionTree_d3";    Factory={ [DecisionTree]::new("classification", 3, 2) } },
            @{ Name="DecisionTree_d5";    Factory={ [DecisionTree]::new("classification", 5, 2) } }
        )
    }

    Write-Host ""
    Write-Host ("🤖 Algorithm Selection: {0} task, {1} candidates" -f $Task, $candidates.Count) -ForegroundColor Green
    Write-Host ("   {0,-25} {1,10}  {2}" -f "Algorithm", $Metric, "Bar") -ForegroundColor Yellow
    Write-Host ("   {0}" -f ("-" * 55)) -ForegroundColor DarkGray

    $results   = @()
    $best      = $null
    $bestScore = [double]::MinValue

    foreach ($cand in $candidates) {
        try {
            $model = & $cand.Factory
            $score = Invoke-AutoMLCrossVal -Model $model -X $X -y $y -Folds $Folds -Metric $Metric
        } catch { $score = [double]::MinValue }

        $isBest = $score -gt $bestScore
        if ($isBest) { $bestScore = $score; $best = $cand.Name }
        $bar    = "█" * [int]([Math]::Max(0, $score * 20))
        $marker = if ($isBest) { " ★" } else { "" }
        $color  = if ($isBest) { "Green" } else { "White" }
        Write-Host ("   {0,-25} {1,10:F4}  {2}{3}" -f $cand.Name, $score, $bar, $marker) -ForegroundColor $color
        $results += @{ Name=$cand.Name; Score=$score }
    }

    Write-Host ""
    Write-Host ("✅ Best algorithm: {0} ({1}={2:F4})" -f $best, $Metric, $bestScore) -ForegroundColor Green
    Write-Host ""
    return @{ BestAlgorithm=$best; BestScore=$bestScore; AllResults=$results }
}

# ============================================================
# FEATURE SELECTION
# ============================================================
# TEACHING NOTE: Feature selection = automatically remove
# irrelevant or redundant features.
#
# Methods:
#   Filter  : rank features by correlation with target (fast, model-agnostic)
#   Wrapper : try subsets, pick best (slow, model-aware)
#   RFE     : Recursive Feature Elimination - remove weakest one by one
#
# We implement Filter and a simple greedy forward selection.
# ============================================================

function Invoke-VBAFFeatureSelection {
    param(
        [double[][]] $X,
        [double[]]   $y,
        [string[]]   $FeatureNames = @(),
        [int]        $MaxFeatures  = -1,   # -1 = auto
        [string]     $Method       = "filter",  # filter, forward
        [int]        $Folds        = 5
    )

    $nFeatures = $X[0].Length
    if ($FeatureNames.Length -eq 0) {
        $FeatureNames = 0..($nFeatures-1) | ForEach-Object { "f$_" }
    }
    if ($MaxFeatures -le 0) { $MaxFeatures = [Math]::Max(1, [int]($nFeatures * 0.7)) }

    Write-Host ""
    Write-Host ("🔍 Feature Selection: {0} method, {1} -> max {2} features" -f $Method, $nFeatures, $MaxFeatures) -ForegroundColor Green

    if ($Method -eq "filter") {
        # Correlation-based filter
        $scores = @()
        for ($f = 0; $f -lt $nFeatures; $f++) {
            $xVals = $X | ForEach-Object { [double]$_[$f] }
            $xMean = ($xVals | Measure-Object -Average).Average
            $yMean = ($y     | Measure-Object -Average).Average
            $num   = 0.0; $dx2 = 0.0; $dy2 = 0.0
            for ($i = 0; $i -lt $y.Length; $i++) {
                $num  += ($xVals[$i] - $xMean) * ($y[$i] - $yMean)
                $dx2  += ($xVals[$i] - $xMean) * ($xVals[$i] - $xMean)
                $dy2  += ($y[$i]     - $yMean) * ($y[$i] - $yMean)
            }
            $corr = if ($dx2 -gt 0 -and $dy2 -gt 0) { [Math]::Abs($num / [Math]::Sqrt($dx2 * $dy2)) } else { 0.0 }
            $scores += @{ Index=$f; Name=$FeatureNames[$f]; Correlation=$corr }
        }

        $ranked   = $scores | Sort-Object { $_.Correlation } -Descending
        $selected = @($ranked | Select-Object -First $MaxFeatures)

        Write-Host ("   {0,-15} {1,10}  {2}" -f "Feature", "|Corr|", "Bar") -ForegroundColor Yellow
        Write-Host ("   {0}" -f ("-" * 40)) -ForegroundColor DarkGray
        foreach ($s in $ranked) {
            $bar     = "█" * [int]($s.Correlation * 20)
            $kept    = $selected | Where-Object { $_.Index -eq $s.Index }
            $marker  = if ($null -ne $kept) { " ✅" } else { " ❌" }
            $color   = if ($null -ne $kept) { "Green" } else { "DarkGray" }
            Write-Host ("   {0,-15} {1,10:F4}  {2}{3}" -f $s.Name, $s.Correlation, $bar, $marker) -ForegroundColor $color
        }

        $selectedIdx = @($selected | ForEach-Object { $_.Index } | Sort-Object)

    } elseif ($Method -eq "forward") {
        # Greedy forward selection
        $remaining   = @(0..($nFeatures-1))
        $selectedIdx = @()
        $bestOverall = [double]::MinValue

        Write-Host "   Greedy forward selection:" -ForegroundColor DarkGray

        while ($selectedIdx.Length -lt $MaxFeatures -and $remaining.Length -gt 0) {
            $bestScore  = [double]::MinValue
            $bestFeature= -1

            foreach ($f in $remaining) {
                $trySet = @($selectedIdx) + @($f)
                $Xsub   = @($X | ForEach-Object { $row = $_; ,([double[]]($trySet | ForEach-Object { $row[$_] })) })
                $yArr   = [double[]]$y

                try {
                    $model = [LinearRegression]::new()
                    $score = Invoke-AutoMLCrossVal -Model $model -X $Xsub -y $yArr -Folds $Folds -Metric "R2"
                } catch { $score = [double]::MinValue }

                if ($score -gt $bestScore) { $bestScore = $score; $bestFeature = $f }
            }

            if ($bestFeature -ge 0 -and $bestScore -gt $bestOverall - 0.001) {
                $selectedIdx  += $bestFeature
                $remaining     = @($remaining | Where-Object { $_ -ne $bestFeature })
                $bestOverall   = $bestScore
                Write-Host ("   + {0,-15}  R2={1:F4}  (set: {2})" -f $FeatureNames[$bestFeature], $bestScore, ($selectedIdx | ForEach-Object { $FeatureNames[$_] }) -join ",") -ForegroundColor Green
            } else {
                break  # adding more features doesn't help
            }
        }
    }

    Write-Host ""
    Write-Host ("✅ Selected {0}/{1} features: {2}" -f $selectedIdx.Length, $nFeatures, ($selectedIdx | ForEach-Object { $FeatureNames[$_] }) -join ", ") -ForegroundColor Green

    # Return reduced dataset
    $Xreduced = @($X | ForEach-Object { $row = $_; ,([double[]]($selectedIdx | ForEach-Object { $row[$_] })) })
    Write-Host ""
    return @{ SelectedIndices=$selectedIdx; SelectedNames=($selectedIdx | ForEach-Object { $FeatureNames[$_] }); X=$Xreduced }
}

# ============================================================
# PIPELINE AUTOMATION
# ============================================================
# TEACHING NOTE: An AutoML pipeline chains:
#   1. Data preprocessing (imputation, scaling)
#   2. Feature selection
#   3. Algorithm selection
#   4. Hyperparameter optimization
#   5. Final model training + evaluation
#
# This is what tools like Auto-sklearn and H2O AutoML do!
# ============================================================

function Invoke-VBAFAutoML {
    param(
        [double[][]] $X,
        [double[]]   $y,
        [string[]]   $FeatureNames  = @(),
        [string]     $Task          = "regression",
        [string]     $OptMethod     = "random",   # grid, random, bayesian
        [int]        $HPOTrials     = 15,
        [int]        $Folds         = 5,
        [string]     $Metric        = "R2"
    )

    Write-Host ""
    Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║         VBAF AutoML Pipeline             ║" -ForegroundColor Cyan
    Write-Host ("║  Task: {0,-35}║" -f $Task)    -ForegroundColor White
    Write-Host ("║  HPO:  {0,-35}║" -f $OptMethod) -ForegroundColor White
    Write-Host ("║  Metric: {0,-33}║" -f $Metric)  -ForegroundColor White
    Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan

    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    # Step 1: Feature selection
    Write-Host "`n[Step 1/3] Feature Selection" -ForegroundColor Yellow
    $fsResult    = Invoke-VBAFFeatureSelection -X $X -y $y -FeatureNames $FeatureNames -Method "filter" -Folds $Folds
    $Xselected   = $fsResult.X
    $selectedIdx = $fsResult.SelectedIndices

    # Step 2: Algorithm selection
    Write-Host "[Step 2/3] Algorithm Selection" -ForegroundColor Yellow
    $algoResult = Invoke-VBAFAlgorithmSelection -X $Xselected -y $y -Task $Task -Folds $Folds -Metric $Metric
    $bestAlgo   = $algoResult.BestAlgorithm

    # Step 3: Hyperparameter optimization for best algorithm
    Write-Host "[Step 3/3] Hyperparameter Optimization ($bestAlgo)" -ForegroundColor Yellow

    $paramSpace = switch -Wildcard ($bestAlgo) {
        "Ridge*"  { @{ Lambda=@(0.001, 0.01, 0.1, 0.5, 1.0, 5.0, 10.0) } }
        "Lasso*"  { @{ Lambda=@(0.001, 0.01, 0.1, 0.5, 1.0) } }
        "Decision*" { @{ MaxDepth=@(2,3,4,5,6); MinSamples=@(1,2,3) } }
        default   { @{ Dummy=@(1) } }   # linear has no hyperparams
    }

    $modelFactory = switch -Wildcard ($bestAlgo) {
        "LinearRegression"  { { param($p) [LinearRegression]::new() } }
        "Ridge*"            { { param($p) [RidgeRegression]::new($p.Lambda) } }
        "Lasso*"            { { param($p) [LassoRegression]::new($p.Lambda) } }
        "DecisionTree*"     { { param($p) [DecisionTree]::new($Task, [int]$p.MaxDepth, [int]$p.MinSamples) } }
        "GaussianNaiveBayes"{ { param($p) [GaussianNaiveBayes]::new() } }
        "LogisticRegression"{ { param($p) [LogisticRegression]::new() } }
        default             { { param($p) [LinearRegression]::new() } }
    }

    $hpoResult = switch ($OptMethod) {
        "grid"     { Invoke-VBAFGridSearch     -ModelFactory $modelFactory -ParamGrid  $paramSpace -X $Xselected -y $y -Folds $Folds -Metric $Metric }
        "bayesian" { Invoke-VBAFBayesianSearch -ModelFactory $modelFactory -ParamSpace $paramSpace -X $Xselected -y $y -NTrials $HPOTrials -Folds $Folds -Metric $Metric }
        default    { Invoke-VBAFRandomSearch   -ModelFactory $modelFactory -ParamSpace $paramSpace -X $Xselected -y $y -NTrials $HPOTrials -Folds $Folds -Metric $Metric }
    }

    $sw.Stop()

    # Train final model on all data with best params
    $finalModel = & $modelFactory $hpoResult.BestParams
    $finalModel.Fit($Xselected, $y)

    Write-Host ""
    Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║           AutoML Results                 ║" -ForegroundColor Green
    Write-Host ("║  Best algorithm : {0,-23}║" -f $bestAlgo)              -ForegroundColor White
    Write-Host ("║  Features used  : {0,-23}║" -f $selectedIdx.Length)    -ForegroundColor White
    Write-Host ("║  Best {0,-7}   : {1,-23:F4}║" -f $Metric, $hpoResult.BestScore) -ForegroundColor White
    Write-Host ("║  Total time     : {0,-23}║" -f ("{0:F1}s" -f $sw.Elapsed.TotalSeconds)) -ForegroundColor White
    Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""

    return @{
        Model          = $finalModel
        Algorithm      = $bestAlgo
        BestParams     = $hpoResult.BestParams
        BestScore      = $hpoResult.BestScore
        SelectedFeatures = $fsResult.SelectedNames
        SelectedIndices  = $selectedIdx
        TotalSeconds   = $sw.Elapsed.TotalSeconds
    }
}

# ============================================================
# TEST
# 1. Run VBAF.LoadAll.ps1
#
# --- Grid Search ---
# 2. $data   = Get-VBAFDataset -Name "HousePrice"
#    $scaler = [StandardScaler]::new()
#    $Xs     = $scaler.FitTransform($data.X)
#    $result = Invoke-VBAFGridSearch `
#        -ModelFactory { param($p) [RidgeRegression]::new($p.Lambda) } `
#        -ParamGrid @{ Lambda=@(0.001, 0.01, 0.1, 1.0, 10.0) } `
#        -X $Xs -y $data.y -Metric "R2"
#    Write-Host "Best Lambda: $($result.BestParams.Lambda)"
#
# --- Random Search ---
# 3. $result2 = Invoke-VBAFRandomSearch `
#        -ModelFactory { param($p) [RidgeRegression]::new($p.Lambda) } `
#        -ParamSpace @{ Lambda=@(0.001,0.01,0.1,0.5,1.0,5.0,10.0) } `
#        -X $Xs -y $data.y -NTrials 10 -Metric "R2"
#
# --- Bayesian Search ---
# 4. $result3 = Invoke-VBAFBayesianSearch `
#        -ModelFactory { param($p) [RidgeRegression]::new($p.Lambda) } `
#        -ParamSpace @{ Lambda=@(0.001,0.01,0.1,0.5,1.0,5.0,10.0) } `
#        -X $Xs -y $data.y -NTrials 15 -WarmupTrials 5 -Metric "R2"
#
# --- Algorithm Selection ---
# 5. Invoke-VBAFAlgorithmSelection -X $Xs -y $data.y -Task "regression"
#
# --- Feature Selection ---
# 6. Invoke-VBAFFeatureSelection -X $Xs -y $data.y `
#        -FeatureNames @("size_sqm","bedrooms","age_years") -Method "filter"
#
# --- Full AutoML Pipeline ---
# 7. $auto = Invoke-VBAFAutoML -X $Xs -y $data.y `
#        -FeatureNames @("size_sqm","bedrooms","age_years") `
#        -Task "regression" -OptMethod "bayesian" -HPOTrials 15
#    Write-Host "Best model: $($auto.Algorithm)  R2=$($auto.BestScore)"
# ============================================================
Write-Host "📦 VBAF.ML.AutoML.ps1 loaded  [v2.1.0 🤖]" -ForegroundColor Green
Write-Host "   HPO       : Invoke-VBAFGridSearch"       -ForegroundColor Cyan
Write-Host "              Invoke-VBAFRandomSearch"      -ForegroundColor Cyan
Write-Host "              Invoke-VBAFBayesianSearch"    -ForegroundColor Cyan
Write-Host "   Selection : Invoke-VBAFAlgorithmSelection" -ForegroundColor Cyan
Write-Host "              Invoke-VBAFFeatureSelection"  -ForegroundColor Cyan
Write-Host "   Pipeline  : Invoke-VBAFAutoML"           -ForegroundColor Cyan
Write-Host "   Note: NAS skipped - neural net backprop not reliable in PS 5.1" -ForegroundColor DarkGray
Write-Host ""
Write-Host "   Quick start:" -ForegroundColor Yellow
Write-Host '   $data   = Get-VBAFDataset -Name "HousePrice"'                      -ForegroundColor White
Write-Host '   $scaler = [StandardScaler]::new()'                                 -ForegroundColor White
Write-Host '   $Xs     = $scaler.FitTransform($data.X)'                           -ForegroundColor White
Write-Host '   $auto   = Invoke-VBAFAutoML -X $Xs -y $data.y -FeatureNames @("size_sqm","bedrooms","age_years") -OptMethod "bayesian"' -ForegroundColor White
Write-Host ""