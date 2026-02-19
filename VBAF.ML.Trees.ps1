#Requires -Version 5.1
<#
.SYNOPSIS
    Tree-Based Learning Algorithms for Machine Learning
.DESCRIPTION
    Implements tree-based algorithms from scratch.
    Designed as a TEACHING resource - every step explained.
    Algorithms included:
      - Decision Tree  (classifier and regressor)
      - Random Forest  (ensemble of decision trees)
    Utilities included:
      - Feature importance calculation
      - ASCII tree visualization
      - Pruning (max depth, min samples)
      - Built-in datasets
    Standalone - no external VBAF dependencies required.
.NOTES
    Part of VBAF - Phase 4 Machine Learning Module
    PS 5.1 compatible
    Teaching project - split criteria shown explicitly!
#>
$basePath = $PSScriptRoot

# ============================================================
# TEACHING NOTE: How does a Decision Tree work?
# A tree asks a series of YES/NO questions about features:
#   "Is size_sqm > 100?"
#     YES -> "Is age > 10?" -> predict 200
#     NO  -> predict 150
# At each node we pick the question that best splits the data.
# "Best" means the two groups after splitting are most PURE
# (all same class, or similar values).
#
# Two split criteria:
#   GINI     : measures impurity for classification
#              Gini = 1 - sum(p_i^2)  (0=pure, 0.5=worst)
#   VARIANCE : measures spread for regression
#              Variance = mean((y - mean(y))^2)
# ============================================================

# ============================================================
# TREE NODE - one decision or leaf in the tree
# ============================================================
class TreeNode {
    [int]      $FeatureIndex  = -1      # Which feature to split on
    [double]   $Threshold     = 0.0     # Split value
    [object]   $Left          = $null   # Left child (feature <= threshold)
    [object]   $Right         = $null   # Right child (feature > threshold)
    [bool]     $IsLeaf        = $false  # True if this is a leaf node
    [double]   $Prediction    = 0.0     # Value to predict (leaf only)
    [int]      $Depth         = 0       # Depth in tree
    [int]      $NSamples      = 0       # Samples reaching this node
    [double]   $Impurity      = 0.0     # Gini or variance at this node
    [string]   $FeatureName   = ""      # For visualization
}

# ============================================================
# DECISION TREE
# ============================================================
class DecisionTree {
    [string]   $Task          # "classification" or "regression"
    [int]      $MaxDepth      # Maximum tree depth (pruning)
    [int]      $MinSamples    # Minimum samples to split (pruning)
    [int]      $MaxFeatures   # Features to consider per split (-1 = all)
    [object]   $Root          # Root TreeNode
    [bool]     $IsFitted      = $false
    [string[]] $FeatureNames  # Optional names for visualization
    [System.Collections.Generic.List[double]] $FeatureImportances

    hidden [System.Random] $Rng

    DecisionTree() {
        $this.Task         = "classification"
        $this.MaxDepth     = 5
        $this.MinSamples   = 2
        $this.MaxFeatures  = -1
        $this.Rng          = [System.Random]::new()
    }

    DecisionTree([string]$task, [int]$maxDepth, [int]$minSamples) {
        $this.Task         = $task
        $this.MaxDepth     = $maxDepth
        $this.MinSamples   = $minSamples
        $this.MaxFeatures  = -1
        $this.Rng          = [System.Random]::new()
    }

    DecisionTree([string]$task, [int]$maxDepth, [int]$minSamples, [int]$maxFeatures, [int]$seed) {
        $this.Task         = $task
        $this.MaxDepth     = $maxDepth
        $this.MinSamples   = $minSamples
        $this.MaxFeatures  = $maxFeatures
        $this.Rng          = [System.Random]::new($seed)
    }

    # -------------------------------------------------------
    # GINI IMPURITY for classification
    # TEACHING: Gini = 1 - sum(p_class^2)
    # Pure node (all same class) = 0
    # Worst case (equal split)   = 0.5
    # -------------------------------------------------------
    hidden [double] GiniImpurity([object[]]$y) {
        if ($y.Length -eq 0) { return 0.0 }
        $counts = @{}
        foreach ($label in $y) {
            $key = "$label"
            if ($counts.ContainsKey($key)) { $counts[$key]++ } else { $counts[$key] = 1 }
        }
        $gini = 1.0
        foreach ($count in $counts.Values) {
            $p     = $count / $y.Length
            $gini -= $p * $p
        }
        return $gini
    }

    # -------------------------------------------------------
    # VARIANCE for regression
    # TEACHING: Variance = mean((y - mean(y))^2)
    # Low variance = values are similar = good split
    # -------------------------------------------------------
    hidden [double] Variance([double[]]$y) {
        if ($y.Length -eq 0) { return 0.0 }
        $mean = ($y | Measure-Object -Average).Average
        $sumSq = 0.0
        foreach ($val in $y) { $sumSq += ($val - $mean) * ($val - $mean) }
        return $sumSq / $y.Length
    }

    # -------------------------------------------------------
    # Leaf prediction value
    # Classification: most common class
    # Regression: mean value
    # -------------------------------------------------------
    hidden [double] LeafValue([object[]]$y) {
        if ($this.Task -eq "regression") {
            return ($y | Measure-Object -Average).Average
        }
        # Most common class
        $counts = @{}
        foreach ($label in $y) {
            $key = "$label"
            if ($counts.ContainsKey($key)) { $counts[$key]++ } else { $counts[$key] = 1 }
        }
        $best = 0.0
        $bestCount = -1
        foreach ($kv in $counts.GetEnumerator()) {
            if ($kv.Value -gt $bestCount) {
                $bestCount = $kv.Value
                $best      = [double]$kv.Key
            }
        }
        return $best
    }

    # -------------------------------------------------------
    # Find best split for a node
    # Try all features and all thresholds
    # Return: @{FeatureIndex, Threshold, Gain}
    # -------------------------------------------------------
    hidden [hashtable] BestSplit([double[][]]$X, [object[]]$y) {
        $nSamples  = $X.Length
        $nFeatures = $X[0].Length
        $bestGain  = -1.0
        $bestFeat  = -1
        $bestThresh = 0.0

        # Current impurity before split
        $currentImpurity = if ($this.Task -eq "regression") {
            $this.Variance([double[]]$y)
        } else {
            $this.GiniImpurity($y)
        }

        # Which features to consider?
        $featureIndices = 0..($nFeatures - 1)
        if ($this.MaxFeatures -gt 0 -and $this.MaxFeatures -lt $nFeatures) {
            # Random subset of features (used by Random Forest)
            $shuffled = $featureIndices | Sort-Object { $this.Rng.Next() }
            $featureIndices = $shuffled[0..($this.MaxFeatures - 1)]
        }

        foreach ($f in $featureIndices) {
            # Get unique thresholds for this feature
            $vals = $X | ForEach-Object { $_[$f] }
            $thresholds = $vals | Sort-Object -Unique

            foreach ($thresh in $thresholds) {
                # Split data
                $leftY  = @()
                $rightY = @()
                for ($i = 0; $i -lt $nSamples; $i++) {
                    if ($X[$i][$f] -le $thresh) { $leftY  += $y[$i] }
                    else                          { $rightY += $y[$i] }
                }

                if ($leftY.Length -eq 0 -or $rightY.Length -eq 0) { continue }

                # Weighted impurity after split
                $leftImp  = if ($this.Task -eq "regression") {
                    $this.Variance([double[]]$leftY)
                } else { $this.GiniImpurity($leftY) }

                $rightImp = if ($this.Task -eq "regression") {
                    $this.Variance([double[]]$rightY)
                } else { $this.GiniImpurity($rightY) }

                $wLeft  = $leftY.Length  / $nSamples
                $wRight = $rightY.Length / $nSamples
                $gain   = $currentImpurity - ($wLeft * $leftImp + $wRight * $rightImp)

                if ($gain -gt $bestGain) {
                    $bestGain   = $gain
                    $bestFeat   = $f
                    $bestThresh = $thresh
                }
            }
        }

        return @{ FeatureIndex = $bestFeat; Threshold = $bestThresh; Gain = $bestGain }
    }

    # -------------------------------------------------------
    # Recursively build the tree
    # -------------------------------------------------------
    hidden [object] BuildTree([double[][]]$X, [object[]]$y, [int]$depth) {
        $node           = [TreeNode]::new()
        $node.Depth     = $depth
        $node.NSamples  = $X.Length
        $node.Impurity  = if ($this.Task -eq "regression") {
            $this.Variance([double[]]$y)
        } else { $this.GiniImpurity($y) }

        # Stopping conditions (pruning)
        $shouldStop = ($depth -ge $this.MaxDepth) -or
                      ($X.Length -lt $this.MinSamples) -or
                      ($node.Impurity -lt 1e-7)

        if ($shouldStop) {
            $node.IsLeaf    = $true
            $node.Prediction = $this.LeafValue($y)
            return $node
        }

        $split = $this.BestSplit($X, $y)

        if ($split.Gain -le 0 -or $split.FeatureIndex -lt 0) {
            $node.IsLeaf    = $true
            $node.Prediction = $this.LeafValue($y)
            return $node
        }

        $node.FeatureIndex = $split.FeatureIndex
        $node.Threshold    = $split.Threshold
        $node.FeatureName  = if ($this.FeatureNames -and
                                 $split.FeatureIndex -lt $this.FeatureNames.Length) {
            $this.FeatureNames[$split.FeatureIndex]
        } else { "f$($split.FeatureIndex)" }

        # Update feature importance
        $importanceGain = $split.Gain * $X.Length
        if ($this.FeatureImportances -and
            $split.FeatureIndex -lt $this.FeatureImportances.Count) {
            $current = $this.FeatureImportances[$split.FeatureIndex]
            $this.FeatureImportances[$split.FeatureIndex] = $current + $importanceGain
        }

        # Split data for children
        $leftX = @(); $leftY = @()
        $rightX = @(); $rightY = @()
        for ($i = 0; $i -lt $X.Length; $i++) {
            if ($X[$i][$split.FeatureIndex] -le $split.Threshold) {
                $leftX += ,$X[$i]; $leftY += $y[$i]
            } else {
                $rightX += ,$X[$i]; $rightY += $y[$i]
            }
        }

        $node.Left  = $this.BuildTree($leftX,  $leftY,  $depth + 1)
        $node.Right = $this.BuildTree($rightX, $rightY, $depth + 1)
        return $node
    }

    # -------------------------------------------------------
    # Train the tree
    # -------------------------------------------------------
    [void] Fit([double[][]]$X, [object[]]$y, [string[]]$featureNames) {
        $this.FeatureNames       = $featureNames
        $nFeatures               = $X[0].Length
        $this.FeatureImportances = [System.Collections.Generic.List[double]]::new()
        for ($i = 0; $i -lt $nFeatures; $i++) { $this.FeatureImportances.Add(0.0) }

        $this.Root     = $this.BuildTree($X, $y, 0)
        $this.IsFitted = $true

        # Normalize feature importances
        $total = ($this.FeatureImportances | Measure-Object -Sum).Sum
        if ($total -gt 0) {
            for ($i = 0; $i -lt $this.FeatureImportances.Count; $i++) {
                $this.FeatureImportances[$i] = $this.FeatureImportances[$i] / $total
            }
        }
    }

    [void] Fit([double[][]]$X, [object[]]$y) {
        $names = @()
        for ($i = 0; $i -lt $X[0].Length; $i++) { $names += "f$i" }
        $this.Fit($X, $y, $names)
    }

    # -------------------------------------------------------
    # Predict one sample
    # -------------------------------------------------------
    hidden [double] PredictOne([double[]]$x, [object]$node) {
        if ($node.IsLeaf) { return $node.Prediction }
        if ($x[$node.FeatureIndex] -le $node.Threshold) {
            return $this.PredictOne($x, $node.Left)
        } else {
            return $this.PredictOne($x, $node.Right)
        }
    }

    # -------------------------------------------------------
    # Predict all samples
    # -------------------------------------------------------
    [double[]] Predict([double[][]]$X) {
        $yHat = @(0.0) * $X.Length
        for ($i = 0; $i -lt $X.Length; $i++) {
            $yHat[$i] = $this.PredictOne($X[$i], $this.Root)
        }
        return $yHat
    }

    # -------------------------------------------------------
    # ASCII Tree Visualization
    # -------------------------------------------------------
    [void] PrintTree() {
        Write-Host ""
        Write-Host "🌳 Decision Tree" -ForegroundColor Green
        Write-Host ""
        $this.PrintNode($this.Root, "", $true)
        Write-Host ""
    }

    hidden [void] PrintNode([object]$node, [string]$prefix, [bool]$isLeft) {
        if ($null -eq $node) { return }

        $connector = if ($isLeft) { "├── " } else { "└── " }
        $childPfx  = if ($isLeft) { "│   " } else { "    " }

        if ($node.IsLeaf) {
            $pred = [Math]::Round($node.Prediction, 3)
            Write-Host "$prefix$connector PREDICT: $pred  (n=$($node.NSamples))" -ForegroundColor Yellow
        } else {
            $thresh = [Math]::Round($node.Threshold, 3)
            Write-Host "$prefix$connector [$($node.FeatureName) <= $thresh]  (n=$($node.NSamples))" -ForegroundColor Cyan
            $this.PrintNode($node.Left,  "$prefix$childPfx", $true)
            $this.PrintNode($node.Right, "$prefix$childPfx", $false)
        }
    }

    # -------------------------------------------------------
    # Feature Importance
    # -------------------------------------------------------
    [void] PrintFeatureImportance() {
        Write-Host ""
        Write-Host "📊 Feature Importance" -ForegroundColor Green
        Write-Host ""
        for ($i = 0; $i -lt $this.FeatureImportances.Count; $i++) {
            $imp   = [Math]::Round($this.FeatureImportances[$i], 4)
            $name  = if ($this.FeatureNames -and $i -lt $this.FeatureNames.Length) {
                $this.FeatureNames[$i]
            } else { "f$i" }
            $bars  = [Math]::Round($imp * 30)
            $bar   = "█" * $bars
            Write-Host ("  {0,-15} {1,-6} {2}" -f $name, $imp, $bar) -ForegroundColor White
        }
        Write-Host ""
    }
}

# ============================================================
# RANDOM FOREST
# ============================================================
# TEACHING NOTE: Why Random Forest?
# A single decision tree can OVERFIT - it memorizes training data.
# Random Forest fixes this by:
#   1. Bootstrap sampling: each tree trains on a RANDOM subset of data
#   2. Feature randomness: each split considers a RANDOM subset of features
#   3. Averaging: final prediction = average/vote of ALL trees
# This is called ENSEMBLE LEARNING - many weak learners = one strong learner!
# ============================================================

class RandomForest {
    [string]  $Task
    [int]     $NTrees
    [int]     $MaxDepth
    [int]     $MinSamples
    [int]     $MaxFeatures
    [bool]    $IsFitted   = $false
    [string[]] $FeatureNames
    [System.Collections.ArrayList] $Trees
    [System.Collections.Generic.List[double]] $FeatureImportances

    hidden [System.Random] $Rng

    RandomForest() {
        $this.Task        = "classification"
        $this.NTrees      = 10
        $this.MaxDepth    = 5
        $this.MinSamples  = 2
        $this.MaxFeatures = -1   # will be set to sqrt(nFeatures) in Fit
        $this.Rng         = [System.Random]::new()
        $this.Trees       = [System.Collections.ArrayList]::new()
    }

    RandomForest([string]$task, [int]$nTrees, [int]$maxDepth) {
        $this.Task        = $task
        $this.NTrees      = $nTrees
        $this.MaxDepth    = $maxDepth
        $this.MinSamples  = 2
        $this.MaxFeatures = -1
        $this.Rng         = [System.Random]::new()
        $this.Trees       = [System.Collections.ArrayList]::new()
    }

    # Bootstrap sample: random rows WITH replacement
    hidden [hashtable] BootstrapSample([double[][]]$X, [object[]]$y) {
        $n      = $X.Length
        $Xboot  = @()
        $yboot  = @()
        for ($i = 0; $i -lt $n; $i++) {
            $idx    = $this.Rng.Next(0, $n)
            $Xboot += ,$X[$idx]
            $yboot += $y[$idx]
        }
        return @{ X = $Xboot; y = $yboot }
    }

    [void] Fit([double[][]]$X, [object[]]$y, [string[]]$featureNames) {
        $this.FeatureNames = $featureNames
        $nFeatures         = $X[0].Length

        # sqrt(nFeatures) is the standard for Random Forest
        $mf = if ($this.MaxFeatures -le 0) {
            [Math]::Max(1, [int][Math]::Sqrt($nFeatures))
        } else { $this.MaxFeatures }

        $this.FeatureImportances = [System.Collections.Generic.List[double]]::new()
        for ($i = 0; $i -lt $nFeatures; $i++) { $this.FeatureImportances.Add(0.0) }

        $this.Trees.Clear()

        Write-Host "🌲 Training Random Forest ($($this.NTrees) trees)..." -ForegroundColor Green

        for ($t = 0; $t -lt $this.NTrees; $t++) {
            $sample = $this.BootstrapSample($X, $y)
            $tree   = [DecisionTree]::new($this.Task, $this.MaxDepth, $this.MinSamples, $mf, $t * 7 + 1)
            $tree.Fit($sample.X, $sample.y, $featureNames)
            $this.Trees.Add($tree) | Out-Null

            # Accumulate feature importances
            for ($i = 0; $i -lt $nFeatures; $i++) {
                $current = $this.FeatureImportances[$i]
                $this.FeatureImportances[$i] = $current + $tree.FeatureImportances[$i]
            }

            if (($t + 1) % [Math]::Max(1, [int]($this.NTrees / 5)) -eq 0) {
                Write-Host "   Tree $($t+1)/$($this.NTrees) done" -ForegroundColor DarkGray
            }
        }

        # Average feature importances across trees
        for ($i = 0; $i -lt $nFeatures; $i++) {
            $this.FeatureImportances[$i] = $this.FeatureImportances[$i] / $this.NTrees
        }

        # Renormalize
        $total = ($this.FeatureImportances | Measure-Object -Sum).Sum
        if ($total -gt 0) {
            for ($i = 0; $i -lt $this.FeatureImportances.Count; $i++) {
                $this.FeatureImportances[$i] = $this.FeatureImportances[$i] / $total
            }
        }

        $this.IsFitted = $true
        Write-Host "✅ Random Forest ready! ($($this.NTrees) trees, max_depth=$($this.MaxDepth))" -ForegroundColor Green
    }

    [void] Fit([double[][]]$X, [object[]]$y) {
        $names = @()
        for ($i = 0; $i -lt $X[0].Length; $i++) { $names += "f$i" }
        $this.Fit($X, $y, $names)
    }

    # Predict: average for regression, majority vote for classification
    [double[]] Predict([double[][]]$X) {
        $nSamples    = $X.Length
        $allPreds    = @()

        foreach ($tree in $this.Trees) {
            $allPreds += ,$tree.Predict($X)
        }

        $finalPreds = @(0.0) * $nSamples

        for ($i = 0; $i -lt $nSamples; $i++) {
            if ($this.Task -eq "regression") {
                # Average all tree predictions
                $sum = 0.0
                foreach ($pred in $allPreds) { $sum += $pred[$i] }
                $finalPreds[$i] = $sum / $this.Trees.Count
            } else {
                # Majority vote
                $votes = @{}
                foreach ($pred in $allPreds) {
                    $key = "$($pred[$i])"
                    if ($votes.ContainsKey($key)) { $votes[$key]++ } else { $votes[$key] = 1 }
                }
                $bestVote  = 0.0
                $bestCount = -1
                foreach ($kv in $votes.GetEnumerator()) {
                    if ($kv.Value -gt $bestCount) {
                        $bestCount = $kv.Value
                        $bestVote  = [double]$kv.Key
                    }
                }
                $finalPreds[$i] = $bestVote
            }
        }
        return $finalPreds
    }

    [void] PrintFeatureImportance() {
        Write-Host ""
        Write-Host "📊 Random Forest Feature Importance (avg over $($this.Trees.Count) trees)" -ForegroundColor Green
        Write-Host ""
        for ($i = 0; $i -lt $this.FeatureImportances.Count; $i++) {
            $imp  = [Math]::Round($this.FeatureImportances[$i], 4)
            $name = if ($this.FeatureNames -and $i -lt $this.FeatureNames.Length) {
                $this.FeatureNames[$i]
            } else { "f$i" }
            $bars = [Math]::Round($imp * 30)
            $bar  = "█" * $bars
            Write-Host ("  {0,-15} {1,-6} {2}" -f $name, $imp, $bar) -ForegroundColor White
        }
        Write-Host ""
    }
}

# ============================================================
# BUILT-IN DATASETS (reuse HousePrice and Iris from Regression)
# ============================================================
function Get-VBAFTreeDataset {
    param([string]$Name = "HousePrice")

    switch ($Name) {
        "HousePrice" {
            Write-Host "📊 Dataset: HousePrice (20 samples)" -ForegroundColor Cyan
            Write-Host "   Features: [size_sqm, bedrooms, age_years]" -ForegroundColor Cyan
            Write-Host "   Target  : price (1000s)" -ForegroundColor Cyan
            $X = @(
                @(50.0,1.0,20.0), @(75.0,2.0,15.0), @(100.0,3.0,10.0),
                @(120.0,3.0,5.0), @(150.0,4.0,2.0), @(60.0,2.0,25.0),
                @(80.0,2.0,18.0), @(90.0,3.0,12.0), @(110.0,3.0,8.0),
                @(130.0,4.0,3.0), @(55.0,1.0,22.0), @(70.0,2.0,16.0),
                @(95.0,3.0,11.0), @(115.0,3.0,6.0), @(140.0,4.0,1.0),
                @(65.0,2.0,19.0), @(85.0,2.0,14.0), @(105.0,3.0,9.0),
                @(125.0,4.0,4.0), @(160.0,5.0,1.0)
            )
            $y = @(150.0,220.0,310.0,370.0,450.0,175.0,240.0,270.0,340.0,400.0,
                   160.0,210.0,290.0,355.0,430.0,195.0,255.0,320.0,385.0,500.0)
            return @{ X=$X; y=[object[]]$y; yRaw=$y;
                      Features=@("size_sqm","bedrooms","age_years"); Task="regression" }
        }
        "Iris2Class" {
            Write-Host "📊 Dataset: Iris2Class (20 samples)" -ForegroundColor Cyan
            Write-Host "   Features: [sepal_length, petal_length]" -ForegroundColor Cyan
            Write-Host "   Target  : 0=Setosa, 1=Versicolor" -ForegroundColor Cyan
            $X = @(
                @(5.1,1.4),@(4.9,1.4),@(4.7,1.3),@(4.6,1.5),@(5.0,1.4),
                @(5.4,1.7),@(4.6,1.4),@(5.0,1.5),@(4.4,1.4),@(4.9,1.5),
                @(7.0,4.7),@(6.4,4.5),@(6.9,4.9),@(5.5,4.0),@(6.5,4.6),
                @(5.7,4.5),@(6.3,4.7),@(4.9,3.3),@(6.6,4.6),@(5.2,3.9)
            )
            $y = @(0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1)
            return @{ X=$X; y=[object[]]$y; yRaw=[int[]]$y;
                      Features=@("sepal_length","petal_length"); Task="classification" }
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
#
# --- Decision Tree Regression ---
# 2. $data  = Get-VBAFTreeDataset -Name "HousePrice"
#    $tree  = [DecisionTree]::new("regression", 3, 2)
#    $tree.Fit($data.X, $data.y, $data.Features)
#    $tree.PrintTree()
#    $tree.PrintFeatureImportance()
#
# --- Decision Tree Classification ---
# 3. $data2 = Get-VBAFTreeDataset -Name "Iris2Class"
#    $tree2 = [DecisionTree]::new("classification", 3, 2)
#    $tree2.Fit($data2.X, $data2.y, $data2.Features)
#    $tree2.PrintTree()
#    $yPred = [int[]]$tree2.Predict($data2.X)
#    Get-ClassificationMetrics -yTrue $data2.yRaw -yPred $yPred
#    NOTE: Get-ClassificationMetrics is in VBAF.ML.Regression.ps1
#
# --- Random Forest ---
# 4. $rf   = [RandomForest]::new("regression", 10, 4)
#    $rf.Fit($data.X, $data.y, $data.Features)
#    $rf.PrintFeatureImportance()
#    $yPred = $rf.Predict($data.X)
# ============================================================
Write-Host "📦 VBAF.ML.Trees.ps1 loaded" -ForegroundColor Green
Write-Host "   Classes   : TreeNode, DecisionTree, RandomForest" -ForegroundColor Cyan
Write-Host "   Functions : Get-VBAFTreeDataset"                  -ForegroundColor Cyan
Write-Host ""
Write-Host "   Quick start:" -ForegroundColor Yellow
Write-Host '   $data = Get-VBAFTreeDataset -Name "HousePrice"'              -ForegroundColor White
Write-Host '   $tree = [DecisionTree]::new("regression", 3, 2)'             -ForegroundColor White
Write-Host '   $tree.Fit($data.X, $data.y, $data.Features)'                 -ForegroundColor White
Write-Host '   $tree.PrintTree()'                                            -ForegroundColor White
Write-Host '   $tree.PrintFeatureImportance()'                               -ForegroundColor White
Write-Host ""