#Requires -Version 5.1
<#
.SYNOPSIS
    Feature Engineering - Create Better Features for ML
.DESCRIPTION
    Implements feature engineering from scratch.
    Designed as a TEACHING resource - every step explained.
    Features included:
      - Polynomial features   : x, x^2, x^3, x1*x2 combinations
      - Interaction terms     : explicit pairwise feature products
      - Feature binning       : continuous -> discrete buckets
      - Feature selection     : variance, correlation, mutual info
      - PCA                   : dimensionality reduction
      - Pipeline              : chain transformers in sequence
    Standalone - no external VBAF dependencies required.
.NOTES
    Part of VBAF - Phase 5 Feature Engineering Module
    PS 5.1 compatible
    Teaching project - why and how of each transformation!
#>
$basePath = $PSScriptRoot

# ============================================================
# TEACHING NOTE: What is Feature Engineering?
# "Better features = better models" - this is often MORE
# important than choosing the right algorithm!
#
# Raw features are what you measure. Engineered features
# capture RELATIONSHIPS and PATTERNS that algorithms can't
# discover on their own.
#
# Example: predicting house price
#   Raw     : [size, floors]
#   Engineered: [size, floors, size^2, size*floors, size_per_floor]
# The model can now find non-linear relationships!
# ============================================================

# ============================================================
# POLYNOMIAL FEATURES
# ============================================================
# TEACHING NOTE: Linear models can only find straight-line
# relationships. Polynomial features let linear models fit CURVES!
#
# For features [x1, x2] with degree=2:
#   Output: [1, x1, x2, x1^2, x1*x2, x2^2]
#   The model learns: y = a + b*x1 + c*x2 + d*x1^2 + e*x1*x2 + f*x2^2
#
# WARNING: degree=3 with 10 features -> 286 columns!
# More features = more risk of overfitting!
# ============================================================

class PolynomialFeatures {
    [int]    $Degree
    [bool]   $IncludeBias        # include column of 1s
    [bool]   $InteractionOnly    # only x1*x2, skip x1^2
    [int]    $NInputFeatures
    [int]    $NOutputFeatures
    [bool]   $IsFitted = $false
    [string[]] $FeatureNames

    PolynomialFeatures() {
        $this.Degree          = 2
        $this.IncludeBias     = $false
        $this.InteractionOnly = $false
    }

    PolynomialFeatures([int]$degree) {
        $this.Degree          = $degree
        $this.IncludeBias     = $false
        $this.InteractionOnly = $false
    }

    PolynomialFeatures([int]$degree, [bool]$interactionOnly) {
        $this.Degree          = $degree
        $this.IncludeBias     = $false
        $this.InteractionOnly = $interactionOnly
    }

    # Generate all combinations of feature indices up to given degree
    hidden [System.Collections.ArrayList] GetCombinations([int]$nFeatures) {
        $combos = [System.Collections.ArrayList]::new()

        if ($this.IncludeBias) { $combos.Add(@()) | Out-Null }

        # Degree 1: original features
        for ($i = 0; $i -lt $nFeatures; $i++) {
            $combos.Add(@($i)) | Out-Null
        }

        # Degree 2+
        for ($d = 2; $d -le $this.Degree; $d++) {
            for ($i = 0; $i -lt $nFeatures; $i++) {
                for ($j = $i; $j -lt $nFeatures; $j++) {
                    if ($this.InteractionOnly -and $i -eq $j) { continue }
                    $combo = @($i, $j)
                    $combos.Add($combo) | Out-Null
                }
            }
        }
        return $combos
    }

    [void] Fit([double[][]]$X, [string[]]$featureNames) {
        $this.NInputFeatures = $X[0].Length
        $combos              = $this.GetCombinations($this.NInputFeatures)
        $this.NOutputFeatures = $combos.Count

        # Build feature names
        $names = [System.Collections.ArrayList]::new()
        foreach ($combo in $combos) {
            if ($combo.Length -eq 0) { $names.Add("1") | Out-Null; continue }
            $parts = @()
            $prev  = -1; $exp = 1
            for ($k = 0; $k -lt $combo.Length; $k++) {
                $fi = $combo[$k]
                $fn = if ($fi -lt $featureNames.Length) { $featureNames[$fi] } else { "f$fi" }
                if ($fi -eq $prev) { $exp++ } else {
                    if ($prev -ge 0) {
                        $pfn = if ($prev -lt $featureNames.Length) { $featureNames[$prev] } else { "f$prev" }
                        $parts += if ($exp -gt 1) { "${pfn}^$exp" } else { $pfn }
                    }
                    $prev = $fi; $exp = 1
                }
            }
            $fi  = $combo[-1]
            $pfn = if ($fi -lt $featureNames.Length) { $featureNames[$fi] } else { "f$fi" }
            $parts += if ($exp -gt 1) { "${pfn}^$exp" } else { $pfn }
            $names.Add($parts -join "*") | Out-Null
        }
        $this.FeatureNames = $names.ToArray()
        $this.IsFitted     = $true
    }

    [void] Fit([double[][]]$X) {
        $names = @(); for ($i = 0; $i -lt $X[0].Length; $i++) { $names += "x$i" }
        $this.Fit($X, $names)
    }

    [double[][]] Transform([double[][]]$X) {
        $combos = $this.GetCombinations($X[0].Length)
        $result = @()
        foreach ($row in $X) {
            $newRow = @(0.0) * $combos.Count
            for ($c = 0; $c -lt $combos.Count; $c++) {
                $combo = $combos[$c]
                if ($combo.Length -eq 0) { $newRow[$c] = 1.0; continue }
                $val = 1.0
                foreach ($fi in $combo) { $val *= $row[$fi] }
                $newRow[$c] = $val
            }
            $result += ,$newRow
        }
        return $result
    }

    [double[][]] FitTransform([double[][]]$X) {
        $this.Fit($X)
        return $this.Transform($X)
    }

    [double[][]] FitTransform([double[][]]$X, [string[]]$featureNames) {
        $this.Fit($X, $featureNames)
        return $this.Transform($X)
    }

    [void] PrintSummary() {
        Write-Host ""
        Write-Host "╔══════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║       Polynomial Features            ║" -ForegroundColor Cyan
        Write-Host "╠══════════════════════════════════════╣" -ForegroundColor Cyan
        Write-Host ("║  Degree          : {0,-18}║" -f $this.Degree)             -ForegroundColor Yellow
        Write-Host ("║  Interaction only: {0,-18}║" -f $this.InteractionOnly)    -ForegroundColor Yellow
        Write-Host ("║  Input features  : {0,-18}║" -f $this.NInputFeatures)     -ForegroundColor White
        Write-Host ("║  Output features : {0,-18}║" -f $this.NOutputFeatures)    -ForegroundColor Green
        Write-Host "╠══════════════════════════════════════╣" -ForegroundColor Cyan
        foreach ($name in $this.FeatureNames) {
            Write-Host ("║  {0,-36}║" -f $name) -ForegroundColor White
        }
        Write-Host "╚══════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
    }
}

# ============================================================
# INTERACTION TERMS (explicit, readable)
# ============================================================
# TEACHING NOTE: Interactions capture COMBINED effects.
# e.g. size*age: big old house behaves differently than
# big new house or small old house.
# More interpretable than full polynomial expansion!
# ============================================================

class InteractionFeatures {
    [string[]] $FeatureNames
    [bool]     $IsFitted = $false

    InteractionFeatures() {}

    # Add all pairwise products to feature matrix
    [double[][]] FitTransform([double[][]]$X, [string[]]$featureNames) {
        $this.FeatureNames = $featureNames
        $n          = $X.Length
        $nF         = $X[0].Length
        $result     = @()

        foreach ($row in $X) {
            $extras = @()
            for ($i = 0; $i -lt $nF; $i++) {
                for ($j = $i + 1; $j -lt $nF; $j++) {
                    $extras += $row[$i] * $row[$j]
                }
            }
            $newRow = @(0.0) * ($nF + $extras.Length)
            for ($k = 0; $k -lt $nF; $k++) { $newRow[$k] = $row[$k] }
            for ($k = 0; $k -lt $extras.Length; $k++) { $newRow[$nF + $k] = $extras[$k] }
            $result += ,$newRow
        }

        # Build output feature names
        $allNames = [System.Collections.ArrayList]::new()
        foreach ($n2 in $featureNames) { $allNames.Add($n2) | Out-Null }
        for ($i = 0; $i -lt $nF; $i++) {
            for ($j = $i + 1; $j -lt $nF; $j++) {
                $allNames.Add("$($featureNames[$i])*$($featureNames[$j])") | Out-Null
            }
        }
        $this.FeatureNames = $allNames.ToArray()
        $this.IsFitted     = $true
        return $result
    }

    [void] PrintSummary() {
        Write-Host ""
        Write-Host "🔗 Interaction Features:" -ForegroundColor Green
        foreach ($name in $this.FeatureNames) {
            $color = if ($name -match '\*') { "Yellow" } else { "White" }
            Write-Host ("   {0}" -f $name) -ForegroundColor $color
        }
        Write-Host ""
    }
}

# ============================================================
# FEATURE BINNING
# ============================================================
# TEACHING NOTE: Binning converts continuous numbers to categories.
# Why bin?
#   - Makes non-linear patterns easier to learn
#   - Reduces sensitivity to small measurement errors
#   - "Age 25-35" might matter more than exact age
#
# Two strategies:
#   Uniform  : equal-width bins (e.g. 0-10, 10-20, 20-30)
#   Quantile : equal-frequency bins (same number of points each)
#              More robust when data is skewed!
# ============================================================

class FeatureBinner {
    [string]   $Strategy    # "uniform" or "quantile"
    [int]      $NBins
    [double[][]] $BinEdges  # one array of edges per feature
    [bool]     $IsFitted = $false

    FeatureBinner([int]$nBins) {
        $this.NBins    = $nBins
        $this.Strategy = "quantile"
    }

    FeatureBinner([int]$nBins, [string]$strategy) {
        $this.NBins    = $nBins
        $this.Strategy = $strategy
    }

    hidden [double] Percentile([double[]]$sorted, [double]$p) {
        $idx = $p / 100.0 * ($sorted.Length - 1)
        $lo  = [int][Math]::Floor($idx)
        $hi  = [int][Math]::Ceiling($idx)
        if ($lo -eq $hi) { return $sorted[$lo] }
        return $sorted[$lo] + ($idx - $lo) * ($sorted[$hi] - $sorted[$lo])
    }

    [void] Fit([double[][]]$X) {
        $nFeatures      = $X[0].Length
        $this.BinEdges  = @()

        for ($f = 0; $f -lt $nFeatures; $f++) {
            $vals = ($X | ForEach-Object { $_[$f] }) | Sort-Object

            if ($this.Strategy -eq "uniform") {
                $minV  = $vals[0]
                $maxV  = $vals[-1]
                $step  = ($maxV - $minV) / $this.NBins
                $edges = @($minV)
                for ($b = 1; $b -le $this.NBins; $b++) {
                    $edges += $minV + $b * $step
                }
            } else {
                # Quantile edges
                $edges = @()
                for ($b = 0; $b -le $this.NBins; $b++) {
                    $p = $b * 100.0 / $this.NBins
                    $edges += $this.Percentile($vals, $p)
                }
            }
            $this.BinEdges += ,$edges
        }
        $this.IsFitted = $true
    }

    [double[][]] Transform([double[][]]$X) {
        $result = @()
        foreach ($row in $X) {
            $binned = @(0.0) * $row.Length
            for ($f = 0; $f -lt $row.Length; $f++) {
                $edges  = $this.BinEdges[$f]
                $binIdx = $this.NBins - 1  # default to last bin
                for ($b = 1; $b -lt $edges.Length; $b++) {
                    if ($row[$f] -le $edges[$b]) { $binIdx = $b - 1; break }
                }
                $binned[$f] = $binIdx
            }
            $result += ,$binned
        }
        return $result
    }

    [double[][]] FitTransform([double[][]]$X) {
        $this.Fit($X)
        return $this.Transform($X)
    }

    [void] PrintBins([string[]]$featureNames) {
        Write-Host ""
        Write-Host "🗂️  Feature Bins ($($this.Strategy), k=$($this.NBins)):" -ForegroundColor Green
        for ($f = 0; $f -lt $this.BinEdges.Length; $f++) {
            $name  = if ($f -lt $featureNames.Length) { $featureNames[$f] } else { "f$f" }
            $edges = $this.BinEdges[$f]
            Write-Host ("  {0,-14}:" -f $name) -ForegroundColor Cyan -NoNewline
            for ($b = 0; $b -lt $this.NBins; $b++) {
                Write-Host (" [{0:F1},{1:F1})" -f $edges[$b], $edges[$b+1]) -ForegroundColor White -NoNewline
            }
            Write-Host ""
        }
        Write-Host ""
    }
}

# ============================================================
# FEATURE SELECTION
# ============================================================
# TEACHING NOTE: More features is NOT always better!
# Irrelevant features add noise and slow learning.
#
# Three simple selection methods:
#   Variance threshold : remove features with low variance
#     (if a feature is nearly constant, it carries no info!)
#   Correlation filter : remove features highly correlated
#     with each other (they carry the same info - redundant!)
#   Mutual Information : how much does each feature tell us
#     about the target? Higher = more useful.
# ============================================================

class VarianceSelector {
    [double]   $Threshold
    [bool[]]   $SelectedMask
    [int[]]    $SelectedIndices
    [bool]     $IsFitted = $false

    VarianceSelector([double]$threshold) { $this.Threshold = $threshold }

    [void] Fit([double[][]]$X) {
        $nFeatures           = $X[0].Length
        $this.SelectedMask   = @($false) * $nFeatures
        $selectedList        = [System.Collections.ArrayList]::new()

        for ($f = 0; $f -lt $nFeatures; $f++) {
            $vals = $X | ForEach-Object { $_[$f] }
            $mean = ($vals | Measure-Object -Average).Average
            $sumSq = 0.0
            foreach ($v in $vals) { $sumSq += ($v - $mean) * ($v - $mean) }
            $variance = $sumSq / $vals.Count

            if ($variance -ge $this.Threshold) {
                $this.SelectedMask[$f] = $true
                $selectedList.Add($f) | Out-Null
            }
        }
        $this.SelectedIndices = $selectedList.ToArray()
        $this.IsFitted        = $true
    }

    [double[][]] Transform([double[][]]$X) {
        $result = @()
        foreach ($row in $X) {
            $newRow = @(0.0) * $this.SelectedIndices.Length
            for ($k = 0; $k -lt $this.SelectedIndices.Length; $k++) {
                $newRow[$k] = $row[$this.SelectedIndices[$k]]
            }
            $result += ,$newRow
        }
        return $result
    }

    [double[][]] FitTransform([double[][]]$X) {
        $this.Fit($X)
        return $this.Transform($X)
    }

    [void] PrintSummary([string[]]$featureNames) {
        Write-Host ""
        Write-Host "🎯 Variance Feature Selection (threshold=$($this.Threshold)):" -ForegroundColor Green
        for ($f = 0; $f -lt $this.SelectedMask.Length; $f++) {
            $name  = if ($f -lt $featureNames.Length) { $featureNames[$f] } else { "f$f" }
            $kept  = $this.SelectedMask[$f]
            $icon  = if ($kept) { "✅" } else { "❌" }
            $color = if ($kept) { "White" } else { "DarkGray" }
            Write-Host ("  $icon {0,-20}" -f $name) -ForegroundColor $color
        }
        Write-Host ("  Kept: {0}/{1} features" -f $this.SelectedIndices.Length, $this.SelectedMask.Length) -ForegroundColor Cyan
        Write-Host ""
    }
}

# Compute Pearson correlation between two feature vectors
function Get-Correlation {
    param([double[]]$a, [double[]]$b)
    $n    = $a.Length
    $meanA = ($a | Measure-Object -Average).Average
    $meanB = ($b | Measure-Object -Average).Average
    $num  = 0.0; $da = 0.0; $db = 0.0
    for ($i = 0; $i -lt $n; $i++) {
        $num += ($a[$i] - $meanA) * ($b[$i] - $meanB)
        $da  += ($a[$i] - $meanA) * ($a[$i] - $meanA)
        $db  += ($b[$i] - $meanB) * ($b[$i] - $meanB)
    }
    $denom = [Math]::Sqrt($da * $db)
    $corrVal = if ($denom -gt 1e-10) { $num / $denom } else { 0.0 }
    return $corrVal
}

function Get-FeatureCorrelations {
    param([double[][]]$X, [double[]]$y, [string[]]$featureNames)

    $nF = $X[0].Length
    Write-Host ""
    Write-Host "📈 Feature-Target Correlations:" -ForegroundColor Green
    Write-Host ""

    $results = @()
    for ($f = 0; $f -lt $nF; $f++) {
        $vals = $X | ForEach-Object { $_[$f] }
        $corr = Get-Correlation -a $vals -b $y
        $name = if ($f -lt $featureNames.Length) { $featureNames[$f] } else { "f$f" }
        $abs  = [Math]::Abs($corr)
        $bar  = "█" * [int]($abs * 20)
        $color = if ($abs -gt 0.7) { "Green" } elseif ($abs -gt 0.4) { "Yellow" } else { "White" }
        Write-Host ("  {0,-15} {1,7:F4}  {2}" -f $name, $corr, $bar) -ForegroundColor $color
        $results += @{ Name=$name; Correlation=$corr; AbsCorr=$abs }
    }
    Write-Host ""
    Write-Host "  Green=strong (>0.7), Yellow=moderate (>0.4), White=weak" -ForegroundColor DarkGray
    Write-Host ""
    return $results
}

# ============================================================
# PCA - PRINCIPAL COMPONENT ANALYSIS
# ============================================================
# TEACHING NOTE: PCA finds the directions of MAXIMUM VARIANCE.
# Imagine 3D data shaped like a flat pancake - most variation
# is in 2D, so we can represent it in 2D without losing much!
#
# How it works:
#   1. Center data (subtract mean)
#   2. Find eigenvectors of covariance matrix
#      (eigenvectors = directions of maximum variance)
#   3. Project data onto top k eigenvectors
#
# Result: fewer dimensions, most information preserved!
# Explained variance tells us how much info we kept.
# ============================================================

class PCA {
    [int]      $NComponents
    [double[][]] $Components    # eigenvectors (principal axes)
    [double[]] $ExplainedVarianceRatio
    [double[]] $Mean
    [bool]     $IsFitted = $false

    PCA([int]$nComponents) { $this.NComponents = $nComponents }

    # Compute covariance matrix
    hidden [double[][]] CovMatrix([double[][]]$X) {
        $n  = $X.Length
        $nF = $X[0].Length
        $cov = @()
        for ($i = 0; $i -lt $nF; $i++) {
            $row = @(0.0) * $nF
            $cov += ,$row
        }
        for ($i = 0; $i -lt $nF; $i++) {
            for ($j = $i; $j -lt $nF; $j++) {
                $sum = 0.0
                for ($k = 0; $k -lt $n; $k++) {
                    $sum += $X[$k][$i] * $X[$k][$j]
                }
                $val          = $sum / ($n - 1)
                $cov[$i][$j]  = $val
                $cov[$j][$i]  = $val
            }
        }
        return $cov
    }

    # Power iteration to find dominant eigenvector
    hidden [double[]] PowerIteration([double[][]]$cov, [int]$maxIter) {
        $n   = $cov.Length
        $rng = [System.Random]::new(42)
        $vec = @(0.0) * $n
        for ($i = 0; $i -lt $n; $i++) { $vec[$i] = $rng.NextDouble() }

        for ($iter = 0; $iter -lt $maxIter; $iter++) {
            $newVec = @(0.0) * $n
            for ($i = 0; $i -lt $n; $i++) {
                for ($j = 0; $j -lt $n; $j++) {
                    $newVec[$i] += $cov[$i][$j] * $vec[$j]
                }
            }
            # Normalize
            $norm = 0.0
            foreach ($v in $newVec) { $norm += $v * $v }
            $norm = [Math]::Sqrt($norm)
            if ($norm -gt 1e-10) {
                for ($i = 0; $i -lt $n; $i++) { $newVec[$i] /= $norm }
            }
            $vec = $newVec
        }
        return $vec
    }

    # Deflate covariance matrix (remove component of found eigenvector)
    hidden [double[][]] Deflate([double[][]]$cov, [double[]]$eigenvec) {
        $n      = $cov.Length
        $newCov = @()
        # Compute eigenvalue = v^T * cov * v
        $lambda = 0.0
        $Av     = @(0.0) * $n
        for ($i = 0; $i -lt $n; $i++) {
            for ($j = 0; $j -lt $n; $j++) { $Av[$i] += $cov[$i][$j] * $eigenvec[$j] }
        }
        for ($i = 0; $i -lt $n; $i++) { $lambda += $eigenvec[$i] * $Av[$i] }

        for ($i = 0; $i -lt $n; $i++) {
            $row = @(0.0) * $n
            for ($j = 0; $j -lt $n; $j++) {
                $row[$j] = $cov[$i][$j] - $lambda * $eigenvec[$i] * $eigenvec[$j]
            }
            $newCov += ,$row
        }
        return $newCov
    }

    [void] Fit([double[][]]$X) {
        $n  = $X.Length
        $nF = $X[0].Length

        # Center data
        $this.Mean = @(0.0) * $nF
        for ($f = 0; $f -lt $nF; $f++) {
            $vals = $X | ForEach-Object { $_[$f] }
            $this.Mean[$f] = ($vals | Measure-Object -Average).Average
        }

        $Xc = @()
        foreach ($row in $X) {
            $centered = @(0.0) * $nF
            for ($f = 0; $f -lt $nF; $f++) { $centered[$f] = $row[$f] - $this.Mean[$f] }
            $Xc += ,$centered
        }

        # Covariance matrix
        $cov = $this.CovMatrix($Xc)

        # Find top k eigenvectors via power iteration + deflation
        $this.Components = @()
        $eigenvalues     = @()
        $currentCov      = $cov

        $k = [Math]::Min($this.NComponents, $nF)
        for ($c = 0; $c -lt $k; $c++) {
            $evec        = $this.PowerIteration($currentCov, 100)
            $this.Components += ,$evec

            # Eigenvalue = v^T * cov * v
            $Av     = @(0.0) * $nF
            for ($i = 0; $i -lt $nF; $i++) {
                for ($j = 0; $j -lt $nF; $j++) { $Av[$i] += $currentCov[$i][$j] * $evec[$j] }
            }
            $lam = 0.0
            for ($i = 0; $i -lt $nF; $i++) { $lam += $evec[$i] * $Av[$i] }
            $eigenvalues += [Math]::Abs($lam)

            $currentCov = $this.Deflate($currentCov, $evec)
        }

        # Explained variance ratio
        $totalVar = ($eigenvalues | Measure-Object -Sum).Sum
        $this.ExplainedVarianceRatio = @(0.0) * $eigenvalues.Length
        for ($c = 0; $c -lt $eigenvalues.Length; $c++) {
            $this.ExplainedVarianceRatio[$c] = if ($totalVar -gt 0) {
                $eigenvalues[$c] / $totalVar
            } else { 0.0 }
        }

        $this.IsFitted = $true
    }

    [double[][]] Transform([double[][]]$X) {
        $result = @()
        foreach ($row in $X) {
            $centered = @(0.0) * $row.Length
            for ($f = 0; $f -lt $row.Length; $f++) { $centered[$f] = $row[$f] - $this.Mean[$f] }

            $projected = @(0.0) * $this.Components.Length
            for ($c = 0; $c -lt $this.Components.Length; $c++) {
                $dot = 0.0
                for ($f = 0; $f -lt $centered.Length; $f++) {
                    $dot += $centered[$f] * $this.Components[$c][$f]
                }
                $projected[$c] = $dot
            }
            $result += ,$projected
        }
        return $result
    }

    [double[][]] FitTransform([double[][]]$X) {
        $this.Fit($X)
        return $this.Transform($X)
    }

    [void] PrintSummary() {
        Write-Host ""
        Write-Host "╔══════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║         PCA Summary                  ║" -ForegroundColor Cyan
        Write-Host "╠══════════════════════════════════════╣" -ForegroundColor Cyan
        Write-Host ("║  Components: {0,-24}║" -f $this.NComponents) -ForegroundColor Yellow
        Write-Host "╠══════════════════════════════════════╣" -ForegroundColor Cyan
        $cumulative = 0.0
        for ($c = 0; $c -lt $this.ExplainedVarianceRatio.Length; $c++) {
            $evr        = [Math]::Round($this.ExplainedVarianceRatio[$c], 4)
            $cumulative += $evr
            $bar        = "█" * [int]($evr * 30)
            Write-Host ("║  PC{0}: {1,6:F1}%  cum={2,5:F1}%  {3,-10}║" -f
                ($c+1), ($evr*100), ($cumulative*100), $bar) -ForegroundColor White
        }
        Write-Host ("║  Total explained: {0,5:F1}%            ║" -f ($cumulative*100)) -ForegroundColor Green
        Write-Host "╚══════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
    }
}

# ============================================================
# TRANSFORMER PIPELINE
# ============================================================
# TEACHING NOTE: A pipeline chains transformers so you don't
# have to manually call each one. It also prevents DATA LEAKAGE:
# fitting scalers on test data would cheat!
# Pipeline ensures: fit on train, transform both train and test.
# ============================================================

class TransformerPipeline {
    [System.Collections.ArrayList] $Steps
    [bool] $IsFitted = $false

    TransformerPipeline() {
        $this.Steps = [System.Collections.ArrayList]::new()
    }

    [void] Add([string]$name, [object]$transformer) {
        $this.Steps.Add(@{ Name=$name; Transformer=$transformer }) | Out-Null
    }

    [double[][]] FitTransform([double[][]]$X) {
        $current = $X
        foreach ($step in $this.Steps) {
            Write-Host ("  ⚙️  $($step.Name)...") -ForegroundColor DarkGray
            $current = $step.Transformer.FitTransform($current)
        }
        $this.IsFitted = $true
        return $current
    }

    [double[][]] Transform([double[][]]$X) {
        $current = $X
        foreach ($step in $this.Steps) {
            $current = $step.Transformer.Transform($current)
        }
        return $current
    }

    [void] PrintSteps() {
        Write-Host ""
        Write-Host "🔧 Transformer Pipeline:" -ForegroundColor Green
        $i = 1
        foreach ($step in $this.Steps) {
            Write-Host ("  Step {0}: {1} [{2}]" -f $i, $step.Name, $step.Transformer.GetType().Name) -ForegroundColor White
            $i++
        }
        Write-Host ""
    }
}

# ============================================================
# TEST
# 1. Run VBAF.LoadAll.ps1
#
# --- Polynomial Features ---
# 2. $X    = @(@(2.0, 3.0), @(4.0, 5.0), @(1.0, 2.0))
#    $poly  = [PolynomialFeatures]::new(2)
#    $Xpoly = $poly.FitTransform($X, @("size","age"))
#    $poly.PrintSummary()
#
# --- Interaction Terms ---
# 3. $inter = [InteractionFeatures]::new()
#    $Xint  = $inter.FitTransform($X, @("size","age"))
#    $inter.PrintSummary()
#
# --- Feature Binning ---
# 4. $data  = Get-VBAFTreeDataset -Name "HousePrice"  # from Trees module
#    $binner = [FeatureBinner]::new(4, "quantile")
#    $binner.Fit($data.X)
#    $binner.PrintBins($data.Features)
#    $Xbinned = $binner.Transform($data.X)
#
# --- Feature Correlations ---
# 5. Get-FeatureCorrelations -X $data.X -y $data.yRaw -featureNames $data.Features
#
# --- Variance Selection ---
# 6. $vs    = [VarianceSelector]::new(0.5)
#    $Xsel  = $vs.FitTransform($data.X)
#    $vs.PrintSummary($data.Features)
#
# --- PCA ---
# 7. $pca   = [PCA]::new(2)
#    $Xpca  = $pca.FitTransform($data.X)
#    $pca.PrintSummary()
#    Write-Host "Shape: $($data.X[0].Length) features -> $($Xpca[0].Length) components"
#
# --- Full Pipeline ---
# 8. $pipe = [TransformerPipeline]::new()
#    $pipe.Add("Imputer",  [MissingValueImputer]::new("median"))  # needs DataPipeline
#    $pipe.Add("Scaler",   [RobustScaler]::new())                 # needs DataPipeline
#    $pipe.Add("Poly",     [PolynomialFeatures]::new(2))
#    $pipe.PrintSteps()
#    $Xout = $pipe.FitTransform($data.X)
# ============================================================
Write-Host "📦 VBAF.ML.FeatureEngineering.ps1 loaded" -ForegroundColor Green
Write-Host "   Classes   : PolynomialFeatures"              -ForegroundColor Cyan
Write-Host "              InteractionFeatures"              -ForegroundColor Cyan
Write-Host "              FeatureBinner"                    -ForegroundColor Cyan
Write-Host "              VarianceSelector"                 -ForegroundColor Cyan
Write-Host "              PCA"                              -ForegroundColor Cyan
Write-Host "              TransformerPipeline"             -ForegroundColor Cyan
Write-Host "   Functions : Get-Correlation"                -ForegroundColor Cyan
Write-Host "              Get-FeatureCorrelations"         -ForegroundColor Cyan
Write-Host ""
Write-Host "   Quick start:" -ForegroundColor Yellow
Write-Host '   $X    = @(@(2.0,3.0),@(4.0,5.0),@(1.0,2.0))'     -ForegroundColor White
Write-Host '   $poly = [PolynomialFeatures]::new(2)'              -ForegroundColor White
Write-Host '   $Xp   = $poly.FitTransform($X, @("size","age"))'   -ForegroundColor White
Write-Host '   $poly.PrintSummary()'                              -ForegroundColor White
Write-Host ""