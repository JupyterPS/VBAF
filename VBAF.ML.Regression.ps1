#Requires -Version 5.1
<#
.SYNOPSIS
    Classic Regression Algorithms for Machine Learning
.DESCRIPTION
    Implements classic regression algorithms from scratch.
    Designed as a TEACHING resource - every step explained.
    Algorithms included:
      - Linear Regression  (OLS - Ordinary Least Squares)
      - Ridge Regression   (L2 regularization)
      - Lasso Regression   (L1 regularization)
      - Logistic Regression (binary & multiclass)
    Utilities included:
      - Feature scaling    (StandardScaler, MinMaxScaler)
      - Cross-validation   (k-fold)
      - Metrics            (MSE, RMSE, MAE, R2, Accuracy)
    Standalone - no external VBAF dependencies required.
.NOTES
    Part of VBAF - Phase 4 Machine Learning Module
    PS 5.1 compatible
    Teaching project - math shown explicitly, no black boxes!
#>
$basePath = $PSScriptRoot

# ============================================================
# TEACHING NOTE: What is Regression?
# Regression finds the relationship between:
#   - Input features X (what we know)
#   - Output target  y (what we want to predict)
# We find weights W such that: y_hat = X * W
# Then minimize the error between y_hat and y.
# ============================================================

# ============================================================
# FEATURE SCALING UTILITIES
# ============================================================
# TEACHING NOTE: Why scale features?
# If one feature is 0-1 and another is 0-1000000,
# the large feature dominates learning.
# Scaling puts all features on equal footing.
# ============================================================

class StandardScaler {
    # Transforms features to mean=0, std=1
    # Formula: z = (x - mean) / std
    [double[]] $Mean
    [double[]] $Std
    [bool]     $IsFitted = $false

    [void] Fit([double[][]]$X) {
        $nFeatures  = $X[0].Length
        $this.Mean  = @(0.0) * $nFeatures
        $this.Std   = @(1.0) * $nFeatures
        $nSamples   = $X.Length

        # Calculate mean for each feature
        for ($f = 0; $f -lt $nFeatures; $f++) {
            $sum = 0.0
            foreach ($row in $X) { $sum += $row[$f] }
            $this.Mean[$f] = $sum / $nSamples
        }

        # Calculate std for each feature
        for ($f = 0; $f -lt $nFeatures; $f++) {
            $sumSq = 0.0
            foreach ($row in $X) {
                $diff   = $row[$f] - $this.Mean[$f]
                $sumSq += $diff * $diff
            }
            $variance       = $sumSq / $nSamples
            $this.Std[$f]   = [Math]::Max([Math]::Sqrt($variance), 1e-8)
        }
        $this.IsFitted = $true
    }

    [double[][]] Transform([double[][]]$X) {
        $result = @()
        foreach ($row in $X) {
            $scaled = @(0.0) * $row.Length
            for ($f = 0; $f -lt $row.Length; $f++) {
                $scaled[$f] = ($row[$f] - $this.Mean[$f]) / $this.Std[$f]
            }
            $result += ,$scaled
        }
        return $result
    }

    [double[][]] FitTransform([double[][]]$X) {
        $this.Fit($X)
        return $this.Transform($X)
    }

    [double[]] InverseTransform([double[]]$y) {
        $result = @(0.0) * $y.Length
        for ($i = 0; $i -lt $y.Length; $i++) {
            $result[$i] = $y[$i] * $this.Std[0] + $this.Mean[0]
        }
        return $result
    }
}

class MinMaxScaler {
    # Transforms features to range [0, 1]
    # Formula: z = (x - min) / (max - min)
    [double[]] $Min
    [double[]] $Max
    [bool]     $IsFitted = $false

    [void] Fit([double[][]]$X) {
        $nFeatures = $X[0].Length
        $this.Min  = @(0.0) * $nFeatures
        $this.Max  = @(1.0) * $nFeatures

        for ($f = 0; $f -lt $nFeatures; $f++) {
            $minVal = [double]::MaxValue
            $maxVal = [double]::MinValue
            foreach ($row in $X) {
                if ($row[$f] -lt $minVal) { $minVal = $row[$f] }
                if ($row[$f] -gt $maxVal) { $maxVal = $row[$f] }
            }
            $this.Min[$f] = $minVal
            $this.Max[$f] = $maxVal
        }
        $this.IsFitted = $true
    }

    [double[][]] Transform([double[][]]$X) {
        $result = @()
        foreach ($row in $X) {
            $scaled = @(0.0) * $row.Length
            for ($f = 0; $f -lt $row.Length; $f++) {
                $range      = [Math]::Max($this.Max[$f] - $this.Min[$f], 1e-8)
                $scaled[$f] = ($row[$f] - $this.Min[$f]) / $range
            }
            $result += ,$scaled
        }
        return $result
    }

    [double[][]] FitTransform([double[][]]$X) {
        $this.Fit($X)
        return $this.Transform($X)
    }
}

# ============================================================
# METRICS
# ============================================================
# TEACHING NOTE: How do we measure how good our model is?
# MSE  = Mean Squared Error       - penalizes large errors heavily
# RMSE = Root Mean Squared Error  - same units as target
# MAE  = Mean Absolute Error      - robust to outliers
# R2   = R-squared                - 1.0 = perfect, 0.0 = baseline
# ============================================================

function Get-RegressionMetrics {
    param([double[]]$yTrue, [double[]]$yPred)

    $n      = $yTrue.Length
    $mse    = 0.0
    $mae    = 0.0
    $yMean  = ($yTrue | Measure-Object -Average).Average

    $ssTot  = 0.0
    $ssRes  = 0.0

    for ($i = 0; $i -lt $n; $i++) {
        $err    = $yTrue[$i] - $yPred[$i]
        $mse   += $err * $err
        $mae   += [Math]::Abs($err)
        $ssRes += $err * $err
        $ssTot += ($yTrue[$i] - $yMean) * ($yTrue[$i] - $yMean)
    }

    $mse  = $mse / $n
    $rmse = [Math]::Sqrt($mse)
    $mae  = $mae / $n
    $r2   = if ($ssTot -gt 1e-10) { 1.0 - ($ssRes / $ssTot) } else { 0.0 }

    return @{
        MSE  = [Math]::Round($mse,  6)
        RMSE = [Math]::Round($rmse, 6)
        MAE  = [Math]::Round($mae,  6)
        R2   = [Math]::Round($r2,   6)
    }
}

function Get-ClassificationMetrics {
    param([int[]]$yTrue, [int[]]$yPred)

    $n       = $yTrue.Length
    $correct = 0
    for ($i = 0; $i -lt $n; $i++) {
        if ($yTrue[$i] -eq $yPred[$i]) { $correct++ }
    }
    $accuracy = $correct / $n

    return @{
        Accuracy = [Math]::Round($accuracy, 6)
        Correct  = $correct
        Total    = $n
    }
}

# ============================================================
# LINEAR REGRESSION (OLS)
# ============================================================
# TEACHING NOTE: Linear Regression finds weights W such that:
#   y_hat = X*W + bias
# We minimize: Loss = (1/n) * sum((y - y_hat)^2)  <- MSE
# Using gradient descent:
#   W = W - learningRate * dLoss/dW
#   dLoss/dW = (2/n) * X^T * (y_hat - y)
# ============================================================

class LinearRegression {
    [double[]] $Weights
    [double]   $Bias
    [double]   $LearningRate
    [int]      $MaxIter
    [bool]     $IsFitted = $false
    [System.Collections.Generic.List[double]] $LossHistory

    LinearRegression() {
        $this.LearningRate = 0.0001
        $this.MaxIter      = 1000
        $this.LossHistory  = [System.Collections.Generic.List[double]]::new()
    }

    LinearRegression([double]$learningRate, [int]$maxIter) {
        $this.LearningRate = $learningRate
        $this.MaxIter      = $maxIter
        $this.LossHistory  = [System.Collections.Generic.List[double]]::new()
    }

    # Predict: y_hat = X*W + bias
    [double[]] Predict([double[][]]$X) {
        $yHat = @(0.0) * $X.Length
        for ($i = 0; $i -lt $X.Length; $i++) {
            $dot = $this.Bias
            for ($j = 0; $j -lt $X[$i].Length; $j++) {
                $dot += $X[$i][$j] * $this.Weights[$j]
            }
            $yHat[$i] = $dot
        }
        return $yHat
    }

    # Train using gradient descent
    [void] Fit([double[][]]$X, [double[]]$y) {
        $n          = $X.Length
        $nFeatures  = $X[0].Length
        $this.Weights = @(0.0) * $nFeatures
        $this.Bias    = 0.0

        for ($iter = 0; $iter -lt $this.MaxIter; $iter++) {
            $yHat = $this.Predict($X)

            # Compute gradients
            $dW   = @(0.0) * $nFeatures
            $dB   = 0.0
            $loss = 0.0

            for ($i = 0; $i -lt $n; $i++) {
                $err   = $yHat[$i] - $y[$i]
                $loss += $err * $err
                $dB   += $err
                for ($j = 0; $j -lt $nFeatures; $j++) {
                    $dW[$j] += $err * $X[$i][$j]
                }
            }

            $loss = $loss / $n
            $this.LossHistory.Add($loss)

            # Update weights
            $this.Bias -= $this.LearningRate * (2.0 / $n) * $dB
            for ($j = 0; $j -lt $nFeatures; $j++) {
                $this.Weights[$j] -= $this.LearningRate * (2.0 / $n) * $dW[$j]
            }
        }
        $this.IsFitted = $true
    }

    [void] PrintSummary() {
        Write-Host ""
        Write-Host "╔══════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║       Linear Regression Summary      ║" -ForegroundColor Cyan
        Write-Host "╠══════════════════════════════════════╣" -ForegroundColor Cyan
        Write-Host ("║  Bias      : {0,-24}║" -f [Math]::Round($this.Bias, 6))   -ForegroundColor White
        for ($j = 0; $j -lt $this.Weights.Length; $j++) {
            Write-Host ("║  Weight[{0}] : {1,-24}║" -f $j, [Math]::Round($this.Weights[$j], 6)) -ForegroundColor White
        }
        $finalLoss = if ($this.LossHistory.Count -gt 0) { $this.LossHistory[-1] } else { 0.0 }
        Write-Host ("║  Final Loss: {0,-24}║" -f [Math]::Round($finalLoss, 6))  -ForegroundColor Magenta
        Write-Host "╚══════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
    }
}

# ============================================================
# RIDGE REGRESSION (L2 Regularization)
# ============================================================
# TEACHING NOTE: Ridge adds a penalty for large weights:
#   Loss = MSE + lambda * sum(W^2)   <- L2 penalty
# This SHRINKS weights toward zero but never to exactly zero.
# Use Ridge when: many features, all somewhat useful.
# Lambda controls strength: larger = more shrinkage.
# ============================================================

class RidgeRegression : LinearRegression {
    [double] $Lambda   # Regularization strength

    RidgeRegression([double]$lambda) : base(0.01, 1000) {
        $this.Lambda = $lambda
    }

    RidgeRegression([double]$lambda, [double]$lr, [int]$maxIter) : base($lr, $maxIter) {
        $this.Lambda = $lambda
    }

    [void] Fit([double[][]]$X, [double[]]$y) {
        $n         = $X.Length
        $nFeatures = $X[0].Length
        $this.Weights = @(0.0) * $nFeatures
        $this.Bias    = 0.0

        for ($iter = 0; $iter -lt $this.MaxIter; $iter++) {
            $yHat = $this.Predict($X)

            $dW   = @(0.0) * $nFeatures
            $dB   = 0.0
            $loss = 0.0

            for ($i = 0; $i -lt $n; $i++) {
                $err   = $yHat[$i] - $y[$i]
                $loss += $err * $err
                $dB   += $err
                for ($j = 0; $j -lt $nFeatures; $j++) {
                    $dW[$j] += $err * $X[$i][$j]
                }
            }

            # L2 regularization term added to loss and gradient
            $l2Loss = 0.0
            for ($j = 0; $j -lt $nFeatures; $j++) {
                $l2Loss += $this.Weights[$j] * $this.Weights[$j]
            }
            $loss = ($loss / $n) + $this.Lambda * $l2Loss
            $this.LossHistory.Add($loss)

            $this.Bias -= $this.LearningRate * (2.0 / $n) * $dB
            for ($j = 0; $j -lt $nFeatures; $j++) {
                # Ridge gradient: add 2*lambda*W to weight gradient
                $ridgeGrad = (2.0 / $n) * $dW[$j] + 2.0 * $this.Lambda * $this.Weights[$j]
                $this.Weights[$j] -= $this.LearningRate * $ridgeGrad
            }
        }
        $this.IsFitted = $true
    }

    [void] PrintSummary() {
        Write-Host ""
        Write-Host "╔══════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║       Ridge Regression Summary       ║" -ForegroundColor Cyan
        Write-Host "╠══════════════════════════════════════╣" -ForegroundColor Cyan
        Write-Host ("║  Lambda    : {0,-24}║" -f $this.Lambda)                   -ForegroundColor Yellow
        Write-Host ("║  Bias      : {0,-24}║" -f [Math]::Round($this.Bias, 6))   -ForegroundColor White
        for ($j = 0; $j -lt $this.Weights.Length; $j++) {
            Write-Host ("║  Weight[{0}] : {1,-24}║" -f $j, [Math]::Round($this.Weights[$j], 6)) -ForegroundColor White
        }
        $finalLoss = if ($this.LossHistory.Count -gt 0) { $this.LossHistory[-1] } else { 0.0 }
        Write-Host ("║  Final Loss: {0,-24}║" -f [Math]::Round($finalLoss, 6))  -ForegroundColor Magenta
        Write-Host "╚══════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
    }
}

# ============================================================
# LASSO REGRESSION (L1 Regularization)
# ============================================================
# TEACHING NOTE: Lasso adds a different penalty:
#   Loss = MSE + lambda * sum(|W|)   <- L1 penalty
# This can shrink weights to EXACTLY zero = feature selection!
# Use Lasso when: many features, only some are useful.
# Lasso automatically picks the most important features.
# ============================================================

class LassoRegression : LinearRegression {
    [double] $Lambda

    LassoRegression([double]$lambda) : base(0.01, 1000) {
        $this.Lambda = $lambda
    }

    LassoRegression([double]$lambda, [double]$lr, [int]$maxIter) : base($lr, $maxIter) {
        $this.Lambda = $lambda
    }

    [void] Fit([double[][]]$X, [double[]]$y) {
        $n         = $X.Length
        $nFeatures = $X[0].Length
        $this.Weights = @(0.0) * $nFeatures
        $this.Bias    = 0.0

        for ($iter = 0; $iter -lt $this.MaxIter; $iter++) {
            $yHat = $this.Predict($X)

            $dW   = @(0.0) * $nFeatures
            $dB   = 0.0
            $loss = 0.0

            for ($i = 0; $i -lt $n; $i++) {
                $err   = $yHat[$i] - $y[$i]
                $loss += $err * $err
                $dB   += $err
                for ($j = 0; $j -lt $nFeatures; $j++) {
                    $dW[$j] += $err * $X[$i][$j]
                }
            }

            # L1 regularization
            $l1Loss = 0.0
            for ($j = 0; $j -lt $nFeatures; $j++) {
                $l1Loss += [Math]::Abs($this.Weights[$j])
            }
            $loss = ($loss / $n) + $this.Lambda * $l1Loss
            $this.LossHistory.Add($loss)

            $this.Bias -= $this.LearningRate * (2.0 / $n) * $dB
            for ($j = 0; $j -lt $nFeatures; $j++) {
                # Lasso gradient: sign(W)*lambda (subgradient)
                $sign     = if ($this.Weights[$j] -gt 0) { 1.0 } elseif ($this.Weights[$j] -lt 0) { -1.0 } else { 0.0 }
                $lassoGrad = (2.0 / $n) * $dW[$j] + $this.Lambda * $sign
                $this.Weights[$j] -= $this.LearningRate * $lassoGrad
            }
        }
        $this.IsFitted = $true
    }

    [void] PrintSummary() {
        Write-Host ""
        Write-Host "╔══════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║       Lasso Regression Summary       ║" -ForegroundColor Cyan
        Write-Host "╠══════════════════════════════════════╣" -ForegroundColor Cyan
        Write-Host ("║  Lambda    : {0,-24}║" -f $this.Lambda)                   -ForegroundColor Yellow
        Write-Host ("║  Bias      : {0,-24}║" -f [Math]::Round($this.Bias, 6))   -ForegroundColor White
        for ($j = 0; $j -lt $this.Weights.Length; $j++) {
            $w    = [Math]::Round($this.Weights[$j], 6)
            $color = if ([Math]::Abs($w) -lt 0.001) { "DarkGray" } else { "White" }
            Write-Host ("║  Weight[{0}] : {1,-24}║" -f $j, $w) -ForegroundColor $color
        }
        $finalLoss = if ($this.LossHistory.Count -gt 0) { $this.LossHistory[-1] } else { 0.0 }
        Write-Host ("║  Final Loss: {0,-24}║" -f [Math]::Round($finalLoss, 6))  -ForegroundColor Magenta
        Write-Host "   (DarkGray weights ≈ 0 = Lasso eliminated them!)" -ForegroundColor DarkGray
        Write-Host "╚══════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
    }
}

# ============================================================
# LOGISTIC REGRESSION
# ============================================================
# TEACHING NOTE: Logistic Regression is for CLASSIFICATION.
# Instead of predicting a number, it predicts a probability.
# Uses the sigmoid function: sigma(z) = 1 / (1 + e^-z)
# Output is always between 0 and 1.
# If probability > 0.5 -> class 1, else class 0
# Loss function: Binary Cross-Entropy
#   Loss = -(y*log(p) + (1-y)*log(1-p))
# ============================================================

class LogisticRegression {
    [double[]] $Weights
    [double]   $Bias
    [double]   $LearningRate
    [int]      $MaxIter
    [double]   $Lambda        # Regularization (0 = none)
    [bool]     $IsFitted = $false
    [System.Collections.Generic.List[double]] $LossHistory

    LogisticRegression() {
        $this.LearningRate = 0.1
        $this.MaxIter      = 1000
        $this.Lambda       = 0.0
        $this.LossHistory  = [System.Collections.Generic.List[double]]::new()
    }

    LogisticRegression([double]$learningRate, [int]$maxIter, [double]$lambda) {
        $this.LearningRate = $learningRate
        $this.MaxIter      = $maxIter
        $this.Lambda       = $lambda
        $this.LossHistory  = [System.Collections.Generic.List[double]]::new()
    }

    # Sigmoid: maps any number to [0,1]
    hidden [double] Sigmoid([double]$z) {
        return 1.0 / (1.0 + [Math]::Exp(-[Math]::Max(-500, [Math]::Min(500, $z))))
    }

    # Predict probabilities
    [double[]] PredictProba([double[][]]$X) {
        $proba = @(0.0) * $X.Length
        for ($i = 0; $i -lt $X.Length; $i++) {
            $z = $this.Bias
            for ($j = 0; $j -lt $X[$i].Length; $j++) {
                $z += $X[$i][$j] * $this.Weights[$j]
            }
            $proba[$i] = $this.Sigmoid($z)
        }
        return $proba
    }

    # Predict class labels (0 or 1)
    [int[]] Predict([double[][]]$X) {
        $proba  = $this.PredictProba($X)
        $labels = @(0) * $X.Length
        for ($i = 0; $i -lt $proba.Length; $i++) {
            $labels[$i] = if ($proba[$i] -ge 0.5) { 1 } else { 0 }
        }
        return $labels
    }

    [void] Fit([double[][]]$X, [int[]]$y) {
        $n         = $X.Length
        $nFeatures = $X[0].Length
        $this.Weights = @(0.0) * $nFeatures
        $this.Bias    = 0.0

        for ($iter = 0; $iter -lt $this.MaxIter; $iter++) {
            $proba = $this.PredictProba($X)

            $dW   = @(0.0) * $nFeatures
            $dB   = 0.0
            $loss = 0.0

            for ($i = 0; $i -lt $n; $i++) {
                $err   = $proba[$i] - $y[$i]
                $dB   += $err
                # Binary cross-entropy loss
                $p     = [Math]::Max(1e-10, [Math]::Min(1 - 1e-10, $proba[$i]))
                $loss -= $y[$i] * [Math]::Log($p) + (1 - $y[$i]) * [Math]::Log(1 - $p)
                for ($j = 0; $j -lt $nFeatures; $j++) {
                    $dW[$j] += $err * $X[$i][$j]
                }
            }

            $loss = $loss / $n
            $this.LossHistory.Add($loss)

            $this.Bias -= $this.LearningRate * $dB / $n
            for ($j = 0; $j -lt $nFeatures; $j++) {
                $regTerm = $this.Lambda * $this.Weights[$j]
                $this.Weights[$j] -= $this.LearningRate * ($dW[$j] / $n + $regTerm)
            }
        }
        $this.IsFitted = $true
    }

    [void] PrintSummary() {
        Write-Host ""
        Write-Host "╔══════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║     Logistic Regression Summary      ║" -ForegroundColor Cyan
        Write-Host "╠══════════════════════════════════════╣" -ForegroundColor Cyan
        Write-Host ("║  Lambda    : {0,-24}║" -f $this.Lambda)                   -ForegroundColor Yellow
        Write-Host ("║  Bias      : {0,-24}║" -f [Math]::Round($this.Bias, 6))   -ForegroundColor White
        for ($j = 0; $j -lt $this.Weights.Length; $j++) {
            Write-Host ("║  Weight[{0}] : {1,-24}║" -f $j, [Math]::Round($this.Weights[$j], 6)) -ForegroundColor White
        }
        $finalLoss = if ($this.LossHistory.Count -gt 0) { $this.LossHistory[-1] } else { 0.0 }
        Write-Host ("║  Final Loss: {0,-24}║" -f [Math]::Round($finalLoss, 6))  -ForegroundColor Magenta
        Write-Host "╚══════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
    }
}

# ============================================================
# CROSS VALIDATION
# ============================================================
# TEACHING NOTE: Why cross-validate?
# If we test on the same data we trained on, we cheat!
# k-fold splits data into k parts:
#   - Train on k-1 parts, test on 1 part
#   - Repeat k times, each part gets a turn as test set
#   - Average the scores = honest estimate of performance
# ============================================================

function Invoke-KFoldCV {
    param(
        [object]     $Model,
        [double[][]] $X,
        [object[]]   $y,
        [int]        $K        = 5,
        [string]     $Task     = "regression",  # or "classification"
        [switch]     $Verbose
    )

    $n       = $X.Length
    $foldSize = [Math]::Floor($n / $K)
    $scores  = [System.Collections.Generic.List[double]]::new()

    Write-Host ""
    Write-Host "🔄 $K-Fold Cross Validation" -ForegroundColor Yellow
    Write-Host "   Samples : $n" -ForegroundColor Cyan
    Write-Host "   Fold size: $foldSize" -ForegroundColor Cyan
    Write-Host ""

    for ($fold = 0; $fold -lt $K; $fold++) {
        $testStart = $fold * $foldSize
        $testEnd   = [Math]::Min($testStart + $foldSize, $n) - 1

        # Split into train/test
        $XTrain = @(); $yTrain = @()
        $XTest  = @(); $yTest  = @()

        for ($i = 0; $i -lt $n; $i++) {
            if ($i -ge $testStart -and $i -le $testEnd) {
                $XTest  += ,$X[$i]
                $yTest  += $y[$i]
            } else {
                $XTrain += ,$X[$i]
                $yTrain += $y[$i]
            }
        }

        # Create fresh model instance same type
        $foldModel = $Model.GetType()::new()

        # Train
        if ($Task -eq "classification") {
            $foldModel.Fit($XTrain, [int[]]$yTrain)
            $yPred  = $foldModel.Predict($XTest)
            $metrics = Get-ClassificationMetrics -yTrue ([int[]]$yTest) -yPred ([int[]]$yPred)
            $score  = $metrics.Accuracy
            $label  = "Accuracy"
        } else {
            $foldModel.Fit($XTrain, [double[]]$yTrain)
            $yPred  = $foldModel.Predict($XTest)
            $metrics = Get-RegressionMetrics -yTrue ([double[]]$yTest) -yPred ([double[]]$yPred)
            $score  = $metrics.R2
            $label  = "R2"
        }

        $scores.Add($score)
        if ($Verbose) {
            Write-Host ("  Fold {0}: {1} = {2:F4}" -f ($fold+1), $label, $score) -ForegroundColor White
        }
    }

    $avgScore = ($scores | Measure-Object -Average).Average
    $minScore = ($scores | Measure-Object -Minimum).Minimum
    $maxScore = ($scores | Measure-Object -Maximum).Maximum

    Write-Host ""
    Write-Host "╔══════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "║     Cross Validation Results         ║" -ForegroundColor Yellow
    Write-Host "╠══════════════════════════════════════╣" -ForegroundColor Yellow
    Write-Host ("║  Folds     : {0,-24}║" -f $K)                              -ForegroundColor White
    Write-Host ("║  Avg Score : {0,-24}║" -f [Math]::Round($avgScore, 4))     -ForegroundColor Green
    Write-Host ("║  Min Score : {0,-24}║" -f [Math]::Round($minScore, 4))     -ForegroundColor White
    Write-Host ("║  Max Score : {0,-24}║" -f [Math]::Round($maxScore, 4))     -ForegroundColor White
    Write-Host "╚══════════════════════════════════════╝" -ForegroundColor Yellow
    Write-Host ""

    return @{ AvgScore = $avgScore; MinScore = $minScore; MaxScore = $maxScore; Scores = $scores }
}

# ============================================================
# BUILT-IN DEMO DATASETS
# ============================================================
function Get-VBAFDataset {
    param([string]$Name = "HousePrice")

    switch ($Name) {
        "HousePrice" {
            # Simple house price dataset
            # Features: [size_sqm, bedrooms, age_years]
            # Target: price in 1000s
            Write-Host "📊 Dataset: HousePrice (20 samples)" -ForegroundColor Cyan
            Write-Host "   Features: [size_sqm, bedrooms, age_years]" -ForegroundColor Cyan
            Write-Host "   Target  : price (1000s)" -ForegroundColor Cyan
            $X = @(
                @(50.0,  1.0, 20.0), @(75.0,  2.0, 15.0), @(100.0, 3.0, 10.0),
                @(120.0, 3.0,  5.0), @(150.0, 4.0,  2.0), @(60.0,  2.0, 25.0),
                @(80.0,  2.0, 18.0), @(90.0,  3.0, 12.0), @(110.0, 3.0,  8.0),
                @(130.0, 4.0,  3.0), @(55.0,  1.0, 22.0), @(70.0,  2.0, 16.0),
                @(95.0,  3.0, 11.0), @(115.0, 3.0,  6.0), @(140.0, 4.0,  1.0),
                @(65.0,  2.0, 19.0), @(85.0,  2.0, 14.0), @(105.0, 3.0,  9.0),
                @(125.0, 4.0,  4.0), @(160.0, 5.0,  1.0)
            )
            $y = @(
                150.0, 220.0, 310.0, 370.0, 450.0, 175.0, 240.0, 270.0, 340.0, 400.0,
                160.0, 210.0, 290.0, 355.0, 430.0, 195.0, 255.0, 320.0, 385.0, 500.0
            )
            return @{ X = $X; y = $y; Task = "regression" }
        }
        "Iris2Class" {
            # Simplified 2-class Iris (Setosa vs Versicolor)
            # Features: [sepal_length, petal_length]
            # Target: 0=Setosa, 1=Versicolor
            Write-Host "📊 Dataset: Iris2Class (20 samples)" -ForegroundColor Cyan
            Write-Host "   Features: [sepal_length, petal_length]" -ForegroundColor Cyan
            Write-Host "   Target  : 0=Setosa, 1=Versicolor" -ForegroundColor Cyan
            $X = @(
                @(5.1, 1.4), @(4.9, 1.4), @(4.7, 1.3), @(4.6, 1.5), @(5.0, 1.4),
                @(5.4, 1.7), @(4.6, 1.4), @(5.0, 1.5), @(4.4, 1.4), @(4.9, 1.5),
                @(7.0, 4.7), @(6.4, 4.5), @(6.9, 4.9), @(5.5, 4.0), @(6.5, 4.6),
                @(5.7, 4.5), @(6.3, 4.7), @(4.9, 3.3), @(6.6, 4.6), @(5.2, 3.9)
            )
            $y = @(0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1)
            return @{ X = $X; y = $y; Task = "classification" }
        }
        default {
            Write-Host "❌ Unknown dataset: $Name" -ForegroundColor Red
            Write-Host "   Available: HousePrice, Iris2Class" -ForegroundColor Yellow
            return $null
        }
    }
}

# ============================================================
# TEST
# 1. Run VBAF.LoadAll.ps1
# 2. $data = Get-VBAFDataset -Name "HousePrice"
# 3. $scaler = [StandardScaler]::new()
#    $Xs = $scaler.FitTransform($data.X)
# 4. $model = [LinearRegression]::new()
#    $model.Fit($Xs, $data.y)
#    $model.PrintSummary()
# 5. $yPred = $model.Predict($Xs)
#    Get-RegressionMetrics -yTrue $data.y -yPred $yPred
# 6. Compare Ridge vs Lasso:
#    $ridge = [RidgeRegression]::new(0.1)
#    $ridge.Fit($Xs, $data.y)
#    $ridge.PrintSummary()
#    $lasso = [LassoRegression]::new(0.1)
#    $lasso.Fit($Xs, $data.y)
#    $lasso.PrintSummary()
# 7. Classification:
#    $data2 = Get-VBAFDataset -Name "Iris2Class"
#    $logit = [LogisticRegression]::new()
#    $logit.Fit($data2.X, [int[]]$data2.y)
#    $logit.PrintSummary()
#    Get-ClassificationMetrics -yTrue $data2.y -yPred $logit.Predict($data2.X)
# ============================================================
Write-Host "📦 VBAF.ML.Regression.ps1 loaded" -ForegroundColor Green
Write-Host "   Classes   : StandardScaler, MinMaxScaler"        -ForegroundColor Cyan
Write-Host "              LinearRegression, RidgeRegression"    -ForegroundColor Cyan
Write-Host "              LassoRegression, LogisticRegression"  -ForegroundColor Cyan
Write-Host "   Functions : Get-RegressionMetrics"               -ForegroundColor Cyan
Write-Host "              Get-ClassificationMetrics"            -ForegroundColor Cyan
Write-Host "              Invoke-KFoldCV"                       -ForegroundColor Cyan
Write-Host "              Get-VBAFDataset"                      -ForegroundColor Cyan
Write-Host ""
Write-Host "   Quick start:" -ForegroundColor Yellow
Write-Host '   $data   = Get-VBAFDataset -Name "HousePrice"'                  -ForegroundColor White
Write-Host '   $scaler = [StandardScaler]::new()'                             -ForegroundColor White
Write-Host '   $Xs     = $scaler.FitTransform($data.X)'                       -ForegroundColor White
Write-Host '   $model  = [LinearRegression]::new()'                           -ForegroundColor White
Write-Host '   $model.Fit($Xs, $data.y)'                                      -ForegroundColor White
Write-Host '   $model.PrintSummary()'                                         -ForegroundColor White
Write-Host ""