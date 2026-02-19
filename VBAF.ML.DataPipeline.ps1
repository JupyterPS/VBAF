#Requires -Version 5.1
<#
.SYNOPSIS
    Data Pipeline - Comprehensive Data Preprocessing Utilities
.DESCRIPTION
    Implements data preprocessing from scratch.
    Designed as a TEACHING resource - every step explained.
    Features included:
      - Missing value handling  : mean, median, mode, constant imputation
      - Outlier detection       : IQR method, Z-score method
      - Normalization           : StandardScaler, MinMaxScaler, RobustScaler
      - Categorical encoding    : OneHot, Label, Target encoding
      - Train/Test splitting    : random and stratified
      - Stratified sampling     : preserves class distribution
      - Pipeline chaining       : apply steps in sequence
    Standalone - no external VBAF dependencies required.
.NOTES
    Part of VBAF - Phase 5 Data Pipeline Module
    PS 5.1 compatible
    Teaching project - every transformation explained!
#>
$basePath = $PSScriptRoot

# ============================================================
# TEACHING NOTE: Why Data Preprocessing?
# Real-world data is MESSY:
#   - Missing values    : sensors fail, people skip questions
#   - Outliers          : typos, rare events, measurement errors
#   - Different scales  : age (0-100) vs salary (0-1000000)
#   - Text categories   : "red","green","blue" -> numbers
# ML algorithms expect clean, numeric, similarly-scaled data.
# Preprocessing is often 80% of the actual ML work!
# ============================================================

# ============================================================
# MISSING VALUE IMPUTATION
# ============================================================
# TEACHING NOTE: What to do with missing values?
#   Mean   : replace with average - good for symmetric data
#   Median : replace with middle value - robust to outliers
#   Mode   : replace with most common - good for categories
#   Constant: replace with fixed value (e.g. 0, "Unknown")
# Never just DELETE rows - you lose information!
# ============================================================

class MissingValueImputer {
    [string]   $Strategy     # "mean", "median", "mode", "constant"
    [object]   $ConstValue   # used when Strategy = "constant"
    [double[]] $FillValues   # learned fill values per feature
    [bool]     $IsFitted = $false

    MissingValueImputer() { $this.Strategy = "mean" }
    MissingValueImputer([string]$strategy) { $this.Strategy = $strategy }
    MissingValueImputer([string]$strategy, [object]$constValue) {
        $this.Strategy   = $strategy
        $this.ConstValue = $constValue
    }

    # Check if a value is missing (null, empty, NaN, or sentinel -999)
    hidden [bool] IsMissing([object]$val) {
        if ($null -eq $val) { return $true }
        if ("$val" -eq "" -or "$val" -eq "NA" -or "$val" -eq "?") { return $true }
        $d = 0.0
        if ([double]::TryParse("$val", [ref]$d)) {
            return [double]::IsNaN($d)
        }
        return $false
    }

    [void] Fit([object[][]]$X) {
        $nFeatures       = $X[0].Length
        $this.FillValues = @(0.0) * $nFeatures

        for ($f = 0; $f -lt $nFeatures; $f++) {
            $vals = @()
            foreach ($row in $X) {
                if (-not $this.IsMissing($row[$f])) { $vals += [double]$row[$f] }
            }

            if ($vals.Length -eq 0) { $this.FillValues[$f] = 0.0; continue }

            switch ($this.Strategy) {
                "mean"   { $this.FillValues[$f] = ($vals | Measure-Object -Average).Average }
                "median" {
                    $sorted = $vals | Sort-Object
                    $mid    = [int]($sorted.Length / 2)
                    $this.FillValues[$f] = if ($sorted.Length % 2 -eq 0) {
                        ($sorted[$mid-1] + $sorted[$mid]) / 2.0
                    } else { $sorted[$mid] }
                }
                "mode"   {
                    $counts = @{}
                    foreach ($v in $vals) {
                        $k = "$v"
                        if ($counts.ContainsKey($k)) { $counts[$k]++ } else { $counts[$k] = 1 }
                    }
                    $best = 0.0; $bestCount = -1
                    foreach ($kv in $counts.GetEnumerator()) {
                        if ($kv.Value -gt $bestCount) { $bestCount=$kv.Value; $best=[double]$kv.Key }
                    }
                    $this.FillValues[$f] = $best
                }
                "constant" { $this.FillValues[$f] = [double]$this.ConstValue }
            }
        }
        $this.IsFitted = $true
    }

    [double[][]] Transform([object[][]]$X) {
        $result = @()
        foreach ($row in $X) {
            $newRow = @(0.0) * $row.Length
            for ($f = 0; $f -lt $row.Length; $f++) {
                $newRow[$f] = if ($this.IsMissing($row[$f])) {
                    $this.FillValues[$f]
                } else { [double]$row[$f] }
            }
            $result += ,$newRow
        }
        return $result
    }

    [double[][]] FitTransform([object[][]]$X) {
        $this.Fit($X)
        return $this.Transform($X)
    }

    [void] PrintSummary() {
        Write-Host ""
        Write-Host "╔══════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║      Missing Value Imputer           ║" -ForegroundColor Cyan
        Write-Host "╠══════════════════════════════════════╣" -ForegroundColor Cyan
        Write-Host ("║  Strategy  : {0,-24}║" -f $this.Strategy) -ForegroundColor Yellow
        for ($f = 0; $f -lt $this.FillValues.Length; $f++) {
            Write-Host ("║  f{0} fill   : {1,-24}║" -f $f, [Math]::Round($this.FillValues[$f],4)) -ForegroundColor White
        }
        Write-Host "╚══════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
    }
}

# ============================================================
# OUTLIER DETECTION AND TREATMENT
# ============================================================
# TEACHING NOTE: What is an outlier?
# A value far from the rest - could be error or rare event.
#
# IQR Method (Interquartile Range):
#   Q1 = 25th percentile, Q3 = 75th percentile
#   IQR = Q3 - Q1
#   Outlier if: x < Q1 - 1.5*IQR  OR  x > Q3 + 1.5*IQR
#   This is ROBUST - not affected by the outliers themselves!
#
# Z-Score Method:
#   z = (x - mean) / std
#   Outlier if |z| > threshold (usually 3)
#   Assumes normal distribution!
#
# Treatment options:
#   Remove : delete the row entirely
#   Clip   : cap to the boundary value (Winsorizing)
#   Flag   : add a column marking outliers (keep data!)
# ============================================================

class OutlierDetector {
    [string]   $Method      # "iqr" or "zscore"
    [string]   $Treatment   # "remove", "clip", "flag"
    [double]   $Threshold   # IQR multiplier or Z-score threshold
    [double[]] $LowerBounds # per feature
    [double[]] $UpperBounds # per feature
    [bool]     $IsFitted = $false

    OutlierDetector() {
        $this.Method    = "iqr"
        $this.Treatment = "clip"
        $this.Threshold = 1.5
    }

    OutlierDetector([string]$method, [string]$treatment, [double]$threshold) {
        $this.Method    = $method
        $this.Treatment = $treatment
        $this.Threshold = $threshold
    }

    hidden [double] Percentile([double[]]$sorted, [double]$p) {
        $idx = $p / 100.0 * ($sorted.Length - 1)
        $lo  = [int][Math]::Floor($idx)
        $hi  = [int][Math]::Ceiling($idx)
        if ($lo -eq $hi) { return $sorted[$lo] }
        return $sorted[$lo] + ($idx - $lo) * ($sorted[$hi] - $sorted[$lo])
    }

    [void] Fit([double[][]]$X) {
        $nFeatures       = $X[0].Length
        $this.LowerBounds = @(0.0) * $nFeatures
        $this.UpperBounds = @(0.0) * $nFeatures

        for ($f = 0; $f -lt $nFeatures; $f++) {
            $vals   = $X | ForEach-Object { $_[$f] }
            $sorted = $vals | Sort-Object

            if ($this.Method -eq "iqr") {
                $q1  = $this.Percentile($sorted, 25)
                $q3  = $this.Percentile($sorted, 75)
                $iqr = $q3 - $q1
                $this.LowerBounds[$f] = $q1 - $this.Threshold * $iqr
                $this.UpperBounds[$f] = $q3 + $this.Threshold * $iqr
            } else {
                # Z-score
                $mean  = ($vals | Measure-Object -Average).Average
                $sumSq = 0.0
                foreach ($v in $vals) { $sumSq += ($v - $mean) * ($v - $mean) }
                $std   = [Math]::Sqrt($sumSq / $vals.Count)
                $std   = [Math]::Max($std, 1e-8)
                $this.LowerBounds[$f] = $mean - $this.Threshold * $std
                $this.UpperBounds[$f] = $mean + $this.Threshold * $std
            }
        }
        $this.IsFitted = $true
    }

    # Returns: @{ Data = cleaned data; OutlierMask = bool[] per row }
    [hashtable] Transform([double[][]]$X) {
        $result      = @()
        $outlierMask = @()

        foreach ($row in $X) {
            $isOutlier = $false
            $newRow    = $row.Clone()

            for ($f = 0; $f -lt $row.Length; $f++) {
                if ($row[$f] -lt $this.LowerBounds[$f] -or $row[$f] -gt $this.UpperBounds[$f]) {
                    $isOutlier = $true
                    if ($this.Treatment -eq "clip") {
                        $newRow[$f] = [Math]::Max($this.LowerBounds[$f],
                                      [Math]::Min($this.UpperBounds[$f], $row[$f]))
                    }
                }
            }

            $outlierMask += $isOutlier
            if ($this.Treatment -ne "remove" -or -not $isOutlier) {
                $result += ,$newRow
            }
        }

        return @{ Data = $result; OutlierMask = $outlierMask }
    }

    [void] PrintSummary() {
        Write-Host ""
        Write-Host "╔══════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║        Outlier Detector              ║" -ForegroundColor Cyan
        Write-Host "╠══════════════════════════════════════╣" -ForegroundColor Cyan
        Write-Host ("║  Method    : {0,-24}║" -f $this.Method)    -ForegroundColor Yellow
        Write-Host ("║  Treatment : {0,-24}║" -f $this.Treatment) -ForegroundColor Yellow
        Write-Host ("║  Threshold : {0,-24}║" -f $this.Threshold) -ForegroundColor Yellow
        Write-Host "╠══════════════════════════════════════╣" -ForegroundColor Cyan
        for ($f = 0; $f -lt $this.LowerBounds.Length; $f++) {
            Write-Host ("║  f{0} bounds : [{1,8:F2}, {2,8:F2}]     ║" -f $f,
                $this.LowerBounds[$f], $this.UpperBounds[$f]) -ForegroundColor White
        }
        Write-Host "╚══════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
    }
}

# ============================================================
# ROBUST SCALER
# ============================================================
# TEACHING NOTE: StandardScaler uses mean and std -
# both are sensitive to outliers!
# RobustScaler uses MEDIAN and IQR instead:
#   z = (x - median) / IQR
# Much more robust when data has outliers!
# ============================================================

class RobustScaler {
    [double[]] $Medians
    [double[]] $IQRs
    [bool]     $IsFitted = $false

    RobustScaler() {}

    hidden [double] Percentile([double[]]$sorted, [double]$p) {
        $idx = $p / 100.0 * ($sorted.Length - 1)
        $lo  = [int][Math]::Floor($idx)
        $hi  = [int][Math]::Ceiling($idx)
        if ($lo -eq $hi) { return $sorted[$lo] }
        return $sorted[$lo] + ($idx - $lo) * ($sorted[$hi] - $sorted[$lo])
    }

    [void] Fit([double[][]]$X) {
        $nFeatures    = $X[0].Length
        $this.Medians = @(0.0) * $nFeatures
        $this.IQRs    = @(1.0) * $nFeatures

        for ($f = 0; $f -lt $nFeatures; $f++) {
            $vals   = $X | ForEach-Object { $_[$f] }
            $sorted = $vals | Sort-Object
            $q1     = $this.Percentile($sorted, 25)
            $q3     = $this.Percentile($sorted, 75)
            $this.Medians[$f] = $this.Percentile($sorted, 50)
            $this.IQRs[$f]    = [Math]::Max($q3 - $q1, 1e-8)
        }
        $this.IsFitted = $true
    }

    [double[][]] Transform([double[][]]$X) {
        $result = @()
        foreach ($row in $X) {
            $scaled = @(0.0) * $row.Length
            for ($f = 0; $f -lt $row.Length; $f++) {
                $scaled[$f] = ($row[$f] - $this.Medians[$f]) / $this.IQRs[$f]
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
# CATEGORICAL ENCODING
# ============================================================
# TEACHING NOTE: ML algorithms need NUMBERS, not text.
# Three ways to encode categories:
#
# Label Encoding: "red"=0, "green"=1, "blue"=2
#   PROBLEM: implies red < green < blue (false ordering!)
#   Use ONLY for ordinal categories (small, medium, large)
#
# One-Hot Encoding: "red" -> [1,0,0], "green" -> [0,1,0]
#   Each category gets its own binary column
#   No false ordering! But adds many columns.
#
# Target Encoding: replace category with mean of target
#   "red" -> mean(y) for all red rows
#   Powerful but can OVERFIT - use carefully!
# ============================================================

class LabelEncoder {
    [hashtable] $Mapping        # category -> integer
    [hashtable] $InverseMapping # integer -> category
    [bool]      $IsFitted = $false

    LabelEncoder() {}

    [void] Fit([string[]]$categories) {
        $this.Mapping        = @{}
        $this.InverseMapping = @{}
        $unique = $categories | Select-Object -Unique | Sort-Object
        $idx    = 0
        foreach ($cat in $unique) {
            $this.Mapping[$cat]        = $idx
            $this.InverseMapping[$idx] = $cat
            $idx++
        }
        $this.IsFitted = $true
    }

    [int[]] Transform([string[]]$categories) {
        $result = @(0) * $categories.Length
        for ($i = 0; $i -lt $categories.Length; $i++) {
            $result[$i] = if ($this.Mapping.ContainsKey($categories[$i])) {
                $this.Mapping[$categories[$i]]
            } else { -1 }  # unknown category
        }
        return $result
    }

    [int[]] FitTransform([string[]]$categories) {
        $this.Fit($categories)
        return $this.Transform($categories)
    }

    [string[]] InverseTransform([int[]]$labels) {
        $result = @("") * $labels.Length
        for ($i = 0; $i -lt $labels.Length; $i++) {
            $result[$i] = if ($this.InverseMapping.ContainsKey($labels[$i])) {
                $this.InverseMapping[$labels[$i]]
            } else { "unknown" }
        }
        return $result
    }

    [void] PrintMapping() {
        Write-Host ""
        Write-Host "🏷️  Label Encoder Mapping:" -ForegroundColor Green
        foreach ($kv in $this.Mapping.GetEnumerator() | Sort-Object Value) {
            Write-Host ("   '{0}' -> {1}" -f $kv.Key, $kv.Value) -ForegroundColor White
        }
        Write-Host ""
    }
}

class OneHotEncoder {
    [string[]]  $Categories    # unique categories learned
    [bool]      $IsFitted = $false

    OneHotEncoder() {}

    [void] Fit([string[]]$categories) {
        $this.Categories = $categories | Select-Object -Unique | Sort-Object
        $this.IsFitted   = $true
    }

    [double[][]] Transform([string[]]$categories) {
        $result = @()
        foreach ($cat in $categories) {
            $vec = @(0.0) * $this.Categories.Length
            for ($i = 0; $i -lt $this.Categories.Length; $i++) {
                if ($this.Categories[$i] -eq $cat) { $vec[$i] = 1.0 }
            }
            $result += ,$vec
        }
        return $result
    }

    [double[][]] FitTransform([string[]]$categories) {
        $this.Fit($categories)
        return $this.Transform($categories)
    }

    [void] PrintMapping() {
        Write-Host ""
        Write-Host "🔢 One-Hot Encoder Mapping:" -ForegroundColor Green
        Write-Host ("   Columns: [{0}]" -f ($this.Categories -join ", ")) -ForegroundColor Cyan
        foreach ($cat in $this.Categories) {
            $vec = $this.Transform(@($cat))[0]
            Write-Host ("   '{0}' -> [{1}]" -f $cat, ($vec -join ", ")) -ForegroundColor White
        }
        Write-Host ""
    }
}

class TargetEncoder {
    [hashtable] $Mapping      # category -> mean target value
    [double]    $GlobalMean   # fallback for unseen categories
    [bool]      $IsFitted = $false

    TargetEncoder() {}

    [void] Fit([string[]]$categories, [double[]]$y) {
        $this.Mapping    = @{}
        $this.GlobalMean = ($y | Measure-Object -Average).Average

        $unique = $categories | Select-Object -Unique
        foreach ($cat in $unique) {
            $vals = @()
            for ($i = 0; $i -lt $categories.Length; $i++) {
                if ($categories[$i] -eq $cat) { $vals += $y[$i] }
            }
            $this.Mapping[$cat] = ($vals | Measure-Object -Average).Average
        }
        $this.IsFitted = $true
    }

    [double[]] Transform([string[]]$categories) {
        $result = @(0.0) * $categories.Length
        for ($i = 0; $i -lt $categories.Length; $i++) {
            $result[$i] = if ($this.Mapping.ContainsKey($categories[$i])) {
                $this.Mapping[$categories[$i]]
            } else { $this.GlobalMean }
        }
        return $result
    }

    [double[]] FitTransform([string[]]$categories, [double[]]$y) {
        $this.Fit($categories, $y)
        return $this.Transform($categories)
    }

    [void] PrintMapping() {
        Write-Host ""
        Write-Host "🎯 Target Encoder Mapping:" -ForegroundColor Green
        foreach ($kv in $this.Mapping.GetEnumerator() | Sort-Object Value) {
            Write-Host ("   '{0}' -> {1:F4}" -f $kv.Key, $kv.Value) -ForegroundColor White
        }
        Write-Host ""
    }
}

# ============================================================
# TRAIN/TEST SPLIT
# ============================================================
# TEACHING NOTE: Why split data?
# We train on one part and TEST on another part we haven't seen.
# This gives an HONEST estimate of how well our model generalises.
# Typical split: 80% train, 20% test
#
# Stratified split: ensures SAME CLASS RATIO in both sets.
# e.g. if 30% spam in full data -> 30% spam in train AND test
# ============================================================

function Split-TrainTest {
    param(
        [double[][]] $X,
        [object[]]   $y,
        [double]     $TestSize  = 0.2,
        [bool]       $Stratify  = $false,
        [int]        $Seed      = 42
    )

    $rng = [System.Random]::new($Seed)
    $n   = $X.Length

    if ($Stratify) {
        # Stratified: split within each class
        $classes  = $y | Select-Object -Unique
        $trainIdx = [System.Collections.ArrayList]::new()
        $testIdx  = [System.Collections.ArrayList]::new()

        foreach ($c in $classes) {
            $classIdx = @()
            for ($i = 0; $i -lt $n; $i++) {
                if ("$($y[$i])" -eq "$c") { $classIdx += $i }
            }
            $shuffled  = $classIdx | Sort-Object { $rng.Next() }
            $nTest     = [Math]::Max(1, [int]([Math]::Round($classIdx.Length * $TestSize)))
            for ($i = 0; $i -lt $shuffled.Length; $i++) {
                if ($i -lt $nTest) { $testIdx.Add($shuffled[$i])  | Out-Null }
                else               { $trainIdx.Add($shuffled[$i]) | Out-Null }
            }
        }
    } else {
        # Random split
        $shuffled  = 0..($n-1) | Sort-Object { $rng.Next() }
        $nTest     = [int]([Math]::Round($n * $TestSize))
        $trainIdx  = [System.Collections.ArrayList]::new()
        $testIdx   = [System.Collections.ArrayList]::new()
        for ($i = 0; $i -lt $shuffled.Length; $i++) {
            if ($i -lt $nTest) { $testIdx.Add($shuffled[$i])  | Out-Null }
            else               { $trainIdx.Add($shuffled[$i]) | Out-Null }
        }
    }

    $XTrain = @(); $yTrain = @()
    $XTest  = @(); $yTest  = @()

    foreach ($i in $trainIdx) { $XTrain += ,$X[$i]; $yTrain += $y[$i] }
    foreach ($i in $testIdx)  { $XTest  += ,$X[$i]; $yTest  += $y[$i] }

    Write-Host ""
    Write-Host "✂️  Train/Test Split" -ForegroundColor Green
    Write-Host ("   Total   : {0} samples" -f $n)             -ForegroundColor Cyan
    Write-Host ("   Train   : {0} samples ({1:F0}%)" -f $XTrain.Length, (100*(1-$TestSize))) -ForegroundColor White
    Write-Host ("   Test    : {0} samples ({1:F0}%)" -f $XTest.Length,  (100*$TestSize))     -ForegroundColor White
    Write-Host ("   Stratify: {0}" -f $Stratify)              -ForegroundColor White
    Write-Host ""

    return @{ XTrain=$XTrain; yTrain=$yTrain; XTest=$XTest; yTest=$yTest }
}

# ============================================================
# DATA SUMMARY UTILITY
# ============================================================
# TEACHING NOTE: Always LOOK at your data before modelling!
# Check: ranges, missing values, distributions.
# ============================================================

function Get-DataSummary {
    param(
        [double[][]] $X,
        [string[]]   $FeatureNames = @()
    )

    $n         = $X.Length
    $nFeatures = $X[0].Length

    Write-Host ""
    Write-Host "📋 Data Summary" -ForegroundColor Green
    Write-Host ("   Samples  : {0}" -f $n)         -ForegroundColor Cyan
    Write-Host ("   Features : {0}" -f $nFeatures) -ForegroundColor Cyan
    Write-Host ""
    Write-Host ("  {0,-12} {1,8} {2,8} {3,8} {4,8} {5,8}" -f "Feature","Min","Max","Mean","Std","Missing") -ForegroundColor Yellow
    Write-Host ("  {0}" -f ("-" * 58)) -ForegroundColor DarkGray

    for ($f = 0; $f -lt $nFeatures; $f++) {
        $vals    = $X | ForEach-Object { $_[$f] }
        $name    = if ($f -lt $FeatureNames.Length) { $FeatureNames[$f] } else { "f$f" }
        $min     = ($vals | Measure-Object -Minimum).Minimum
        $max     = ($vals | Measure-Object -Maximum).Maximum
        $mean    = ($vals | Measure-Object -Average).Average
        $sumSq   = 0.0
        foreach ($v in $vals) { $sumSq += ($v - $mean) * ($v - $mean) }
        $std     = [Math]::Sqrt($sumSq / $vals.Count)
        $missing = ($vals | Where-Object { [double]::IsNaN($_) }).Count

        $color = if ($missing -gt 0) { "Yellow" } else { "White" }
        Write-Host ("  {0,-12} {1,8:F2} {2,8:F2} {3,8:F2} {4,8:F2} {5,8}" -f
            $name, $min, $max, $mean, $std, $missing) -ForegroundColor $color
    }
    Write-Host ""
}

# ============================================================
# BUILT-IN DEMO DATASET WITH ISSUES
# ============================================================
function Get-VBAFPipelineDataset {
    param([string]$Name = "MestyHousePrice")

    switch ($Name) {
        "MessyHousePrice" {
            Write-Host "📊 Dataset: MessyHousePrice (messy version!)" -ForegroundColor Cyan
            Write-Host "   Has: missing values, outliers, categories" -ForegroundColor Yellow
            # Features: size_sqm, bedrooms, age_years, condition (cat), price
            $rawData = @(
                @{size=50.0;  beds=1.0;   age=20.0; cond="good";      price=150.0},
                @{size=75.0;  beds=2.0;   age=15.0; cond="good";      price=220.0},
                @{size=$null; beds=3.0;   age=10.0; cond="excellent";  price=310.0},  # missing size
                @{size=120.0; beds=3.0;   age=5.0;  cond="excellent";  price=370.0},
                @{size=150.0; beds=4.0;   age=2.0;  cond="excellent";  price=450.0},
                @{size=60.0;  beds=2.0;   age=25.0; cond="fair";       price=175.0},
                @{size=80.0;  beds=$null; age=18.0; cond="good";       price=240.0},  # missing beds
                @{size=90.0;  beds=3.0;   age=12.0; cond="good";       price=270.0},
                @{size=999.0; beds=3.0;   age=8.0;  cond="good";       price=340.0},  # outlier size!
                @{size=130.0; beds=4.0;   age=3.0;  cond="excellent";  price=400.0},
                @{size=55.0;  beds=1.0;   age=22.0; cond="fair";       price=160.0},
                @{size=70.0;  beds=2.0;   age=16.0; cond="good";       price=210.0},
                @{size=95.0;  beds=3.0;   age=11.0; cond="good";       price=290.0},
                @{size=115.0; beds=3.0;   age=6.0;  cond="excellent";  price=355.0},
                @{size=140.0; beds=4.0;   age=1.0;  cond="excellent";  price=430.0},
                @{size=65.0;  beds=2.0;   age=19.0; cond="fair";       price=$null},  # missing price
                @{size=85.0;  beds=2.0;   age=14.0; cond="good";       price=255.0},
                @{size=105.0; beds=3.0;   age=9.0;  cond="good";       price=320.0},
                @{size=125.0; beds=4.0;   age=4.0;  cond="excellent";  price=385.0},
                @{size=160.0; beds=5.0;   age=1.0;  cond="excellent";  price=500.0}
            )

            $X    = @(); $y = @(); $conditions = @()
            foreach ($row in $rawData) {
                $X           += ,@($row.size, $row.beds, $row.age)
                $y           += $row.price
                $conditions  += $row.cond
            }
            return @{ X=$X; y=$y; Conditions=$conditions
                      Features=@("size_sqm","bedrooms","age_years") }
        }
        "IrisWithCategories" {
            Write-Host "📊 Dataset: IrisWithCategories" -ForegroundColor Cyan
            Write-Host "   Has: numeric features + text labels" -ForegroundColor Yellow
            $X = @(
                @(5.1,3.5,1.4,0.2),@(4.9,3.0,1.4,0.2),@(4.7,3.2,1.3,0.2),
                @(5.0,3.6,1.4,0.2),@(5.4,3.9,1.7,0.4),@(4.6,3.4,1.4,0.3),
                @(7.0,3.2,4.7,1.4),@(6.4,3.2,4.5,1.5),@(6.9,3.1,4.9,1.5),
                @(5.5,2.3,4.0,1.3),@(6.5,2.8,4.6,1.5),@(5.7,2.8,4.5,1.3),
                @(6.3,3.3,6.0,2.5),@(5.8,2.7,5.1,1.9),@(7.1,3.0,5.9,2.1)
            )
            $labels = @("setosa","setosa","setosa","setosa","setosa","setosa",
                        "versicolor","versicolor","versicolor","versicolor","versicolor","versicolor",
                        "virginica","virginica","virginica")
            return @{ X=$X; Labels=$labels; Features=@("sepal_l","sepal_w","petal_l","petal_w") }
        }
        default {
            Write-Host "❌ Unknown dataset: $Name" -ForegroundColor Red
            Write-Host "   Available: MessyHousePrice, IrisWithCategories" -ForegroundColor Yellow
            return $null
        }
    }
}

# ============================================================
# TEST
# 1. Run VBAF.LoadAll.ps1
#
# --- Full pipeline on messy data ---
# 2. $data = Get-VBAFPipelineDataset -Name "MessyHousePrice"
#
# 3. # Step 1: Look at raw data
#    Get-DataSummary -X $data.X -FeatureNames $data.Features
#
# 4. # Step 2: Impute missing values
#    $imp  = [MissingValueImputer]::new("median")
#    $Ximp = $imp.FitTransform($data.X)
#    $imp.PrintSummary()
#
# 5. # Step 3: Detect and clip outliers
#    $od      = [OutlierDetector]::new("iqr", "clip", 1.5)
#    $od.Fit($Ximp)
#    $od.PrintSummary()
#    $result  = $od.Transform($Ximp)
#    $Xclean  = $result.Data
#    Write-Host "Outliers found: $(($result.OutlierMask | Where-Object {$_}).Count)"
#
# 6. # Step 4: Encode categories
#    $ohe    = [OneHotEncoder]::new()
#    $Xcond  = $ohe.FitTransform($data.Conditions)
#    $ohe.PrintMapping()
#
# 7. # Step 5: Scale features
#    $scaler = [RobustScaler]::new()
#    $Xscaled = $scaler.FitTransform($Xclean)
#    Get-DataSummary -X $Xscaled -FeatureNames $data.Features
#
# 8. # Step 6: Train/Test split (stratified not needed for regression)
#    $split = Split-TrainTest -X $Xscaled -y $data.y -TestSize 0.2
#
# --- Label and Target encoding ---
# 9. $le  = [LabelEncoder]::new()
#    $enc = $le.FitTransform($data.Conditions)
#    $le.PrintMapping()
#
# 10. $te   = [TargetEncoder]::new()
#     $tenc = $te.FitTransform($data.Conditions, [double[]]$data.y)
#     $te.PrintMapping()
# ============================================================
Write-Host "📦 VBAF.ML.DataPipeline.ps1 loaded" -ForegroundColor Green
Write-Host "   Classes   : MissingValueImputer"              -ForegroundColor Cyan
Write-Host "              OutlierDetector"                   -ForegroundColor Cyan
Write-Host "              RobustScaler"                      -ForegroundColor Cyan
Write-Host "              LabelEncoder"                      -ForegroundColor Cyan
Write-Host "              OneHotEncoder"                     -ForegroundColor Cyan
Write-Host "              TargetEncoder"                     -ForegroundColor Cyan
Write-Host "   Functions : Split-TrainTest"                  -ForegroundColor Cyan
Write-Host "              Get-DataSummary"                   -ForegroundColor Cyan
Write-Host "              Get-VBAFPipelineDataset"           -ForegroundColor Cyan
Write-Host ""
Write-Host "   Quick start:" -ForegroundColor Yellow
Write-Host '   $data = Get-VBAFPipelineDataset -Name "MessyHousePrice"' -ForegroundColor White
Write-Host '   $imp  = [MissingValueImputer]::new("median")'            -ForegroundColor White
Write-Host '   $Ximp = $imp.FitTransform($data.X)'                      -ForegroundColor White
Write-Host '   $imp.PrintSummary()'                                     -ForegroundColor White
Write-Host ""