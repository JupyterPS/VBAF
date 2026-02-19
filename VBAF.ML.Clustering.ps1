#Requires -Version 5.1
<#
.SYNOPSIS
    Clustering Algorithms for Machine Learning
.DESCRIPTION
    Implements clustering algorithms from scratch.
    Designed as a TEACHING resource - every step explained.
    Algorithms included:
      - K-Means       : partition into k clusters by centroid distance
      - Hierarchical  : bottom-up merging of closest clusters (agglomerative)
      - DBSCAN        : density-based, finds clusters of any shape
    Utilities included:
      - Silhouette score  : how well separated are the clusters?
      - Inertia           : how tight are the clusters?
      - Elbow method      : ASCII plot to find optimal k
      - Built-in datasets
    Standalone - no external VBAF dependencies required.
.NOTES
    Part of VBAF - Phase 4 Machine Learning Module
    PS 5.1 compatible
    Teaching project - each algorithm explained step by step!
#>
$basePath = $PSScriptRoot

# ============================================================
# TEACHING NOTE: What is Clustering?
# Clustering finds GROUPS in data WITHOUT labels.
# This is UNSUPERVISED learning - we don't tell the algorithm
# what the groups should be, it discovers them on its own!
#
# Three very different approaches:
#   K-Means     : "Put points near the same center together"
#   Hierarchical: "Merge the two closest groups, repeat"
#   DBSCAN      : "Points in dense regions belong together"
# ============================================================

# ============================================================
# DISTANCE UTILITIES
# ============================================================
# TEACHING: Euclidean distance = straight line between two points
# d = sqrt( sum( (a_i - b_i)^2 ) )
# ============================================================

function Get-EuclideanDistance {
    param([double[]]$a, [double[]]$b)
    $sum = 0.0
    for ($i = 0; $i -lt $a.Length; $i++) {
        $diff = $a[$i] - $b[$i]
        $sum += $diff * $diff
    }
    return [Math]::Sqrt($sum)
}

function Get-Centroid {
    param([double[][]]$points)
    $n    = $points.Length
    $dim  = $points[0].Length
    $cent = @(0.0) * $dim
    foreach ($p in $points) {
        for ($i = 0; $i -lt $dim; $i++) { $cent[$i] += $p[$i] }
    }
    for ($i = 0; $i -lt $dim; $i++) { $cent[$i] /= $n }
    return $cent
}

# ============================================================
# K-MEANS CLUSTERING
# ============================================================
# TEACHING NOTE: K-Means algorithm:
#   1. Pick k random points as initial centroids
#   2. Assign each point to nearest centroid
#   3. Move each centroid to mean of its assigned points
#   4. Repeat 2-3 until centroids stop moving (converged)
#
# Weakness: must choose k in advance, sensitive to init,
#           only finds spherical clusters.
# ============================================================

class KMeans {
    [int]      $K               # Number of clusters
    [int]      $MaxIter         # Maximum iterations
    [double]   $Tolerance       # Convergence threshold
    [double[][]] $Centroids     # Current centroid positions
    [int[]]    $Labels          # Cluster assignment per point
    [double]   $Inertia         # Sum of squared distances to centroids
    [int]      $IterationsRun   # How many iterations until convergence
    [bool]     $IsFitted = $false
    [System.Collections.Generic.List[double]] $InertiaHistory

    hidden [System.Random] $Rng

    KMeans([int]$k) {
        $this.K          = $k
        $this.MaxIter    = 100
        $this.Tolerance  = 1e-4
        $this.Rng        = [System.Random]::new()
        $this.InertiaHistory = [System.Collections.Generic.List[double]]::new()
    }

    KMeans([int]$k, [int]$maxIter) {
        $this.K          = $k
        $this.MaxIter    = $maxIter
        $this.Tolerance  = 1e-4
        $this.Rng        = [System.Random]::new()
        $this.InertiaHistory = [System.Collections.Generic.List[double]]::new()
    }

    # -------------------------------------------------------
    # Initialize centroids by picking k random data points
    # -------------------------------------------------------
    hidden [void] InitCentroids([double[][]]$X) {
        $n = $X.Length
        $indices = 0..($n-1) | Sort-Object { $this.Rng.Next() }
        $this.Centroids = @()
        for ($i = 0; $i -lt $this.K; $i++) {
            $this.Centroids += ,$X[$indices[$i]].Clone()
        }
    }

    # -------------------------------------------------------
    # Assign each point to nearest centroid
    # -------------------------------------------------------
    hidden [int[]] AssignClusters([double[][]]$X) {
        $result = @(0) * $X.Length
        for ($i = 0; $i -lt $X.Length; $i++) {
            $bestDist  = [double]::MaxValue
            $bestClust = 0
            for ($c = 0; $c -lt $this.K; $c++) {
                $dist = Get-EuclideanDistance $X[$i] $this.Centroids[$c]
                if ($dist -lt $bestDist) {
                    $bestDist  = $dist
                    $bestClust = $c
                }
            }
            $result[$i] = $bestClust
        }
        return $result
    }

    # -------------------------------------------------------
    # Recompute centroids as mean of assigned points
    # -------------------------------------------------------
    hidden [double[][]] UpdateCentroids([double[][]]$X, [int[]]$labels) {
        $dim          = $X[0].Length
        $newCentroids = @()
        for ($c = 0; $c -lt $this.K; $c++) {
            $clusterPoints = @()
            for ($i = 0; $i -lt $X.Length; $i++) {
                if ($labels[$i] -eq $c) { $clusterPoints += ,$X[$i] }
            }
            if ($clusterPoints.Length -gt 0) {
                $newCentroids += ,( Get-Centroid $clusterPoints )
            } else {
                # Empty cluster - keep old centroid
                $newCentroids += ,$this.Centroids[$c].Clone()
            }
        }
        return $newCentroids
    }

    # -------------------------------------------------------
    # Compute inertia = sum of squared distances to centroids
    # -------------------------------------------------------
    hidden [double] ComputeInertia([double[][]]$X, [int[]]$labels) {
        $total = 0.0
        for ($i = 0; $i -lt $X.Length; $i++) {
            $dist   = Get-EuclideanDistance $X[$i] $this.Centroids[$labels[$i]]
            $total += $dist * $dist
        }
        return $total
    }

    # -------------------------------------------------------
    # Check convergence: did centroids move much?
    # -------------------------------------------------------
    hidden [bool] HasConverged([double[][]]$oldCentroids) {
        for ($c = 0; $c -lt $this.K; $c++) {
            $move = Get-EuclideanDistance $oldCentroids[$c] $this.Centroids[$c]
            if ($move -gt $this.Tolerance) { return $false }
        }
        return $true
    }

    # -------------------------------------------------------
    # Main training loop
    # -------------------------------------------------------
    [void] Fit([double[][]]$X) {
        $this.InitCentroids($X)
        $this.InertiaHistory.Clear()

        for ($iter = 0; $iter -lt $this.MaxIter; $iter++) {
            $oldCentroids   = $this.Centroids
            $this.Labels    = $this.AssignClusters($X)
            $this.Centroids = $this.UpdateCentroids($X, $this.Labels)
            $this.Inertia   = $this.ComputeInertia($X, $this.Labels)
            $this.InertiaHistory.Add($this.Inertia)
            $this.IterationsRun = $iter + 1

            if ($this.HasConverged($oldCentroids)) { break }
        }
        $this.IsFitted = $true
    }

    # Predict cluster for new points
    [int[]] Predict([double[][]]$X) {
        return $this.AssignClusters($X)
    }

    [void] PrintSummary() {
        Write-Host ""
        Write-Host "╔══════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║         K-Means Summary              ║" -ForegroundColor Cyan
        Write-Host "╠══════════════════════════════════════╣" -ForegroundColor Cyan
        Write-Host ("║  K           : {0,-22}║" -f $this.K)              -ForegroundColor White
        Write-Host ("║  Iterations  : {0,-22}║" -f $this.IterationsRun)  -ForegroundColor White
        Write-Host ("║  Inertia     : {0,-22}║" -f [Math]::Round($this.Inertia, 4)) -ForegroundColor Magenta
        Write-Host "╠══════════════════════════════════════╣" -ForegroundColor Cyan
        for ($c = 0; $c -lt $this.K; $c++) {
            $centStr = ($this.Centroids[$c] | ForEach-Object { [Math]::Round($_, 2) }) -join ", "
            $count   = ($this.Labels | Where-Object { $_ -eq $c }).Count
            Write-Host ("║  Cluster {0}   : n={1,-4} @ [{2}]" -f $c, $count, $centStr) -ForegroundColor White
        }
        Write-Host "╚══════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
    }
}

# ============================================================
# HIERARCHICAL CLUSTERING (Agglomerative)
# ============================================================
# TEACHING NOTE: Hierarchical clustering builds a TREE of clusters:
#   1. Start: every point is its own cluster
#   2. Find the two CLOSEST clusters
#   3. Merge them into one cluster
#   4. Repeat until only k clusters remain
#
# Linkage types (how to measure cluster distance):
#   Single   : distance between CLOSEST points in each cluster
#   Complete : distance between FARTHEST points in each cluster
#   Average  : average distance between ALL pairs of points
#
# Advantage: no need to choose k in advance!
# Disadvantage: slow for large datasets (O(n^2) memory)
# ============================================================

class HierarchicalClustering {
    [int]    $K           # Target number of clusters
    [string] $Linkage     # "single", "complete", or "average"
    [int[]]  $Labels      # Final cluster assignment
    [bool]   $IsFitted = $false
    [System.Collections.ArrayList] $MergeHistory  # Record of merges

    HierarchicalClustering([int]$k) {
        $this.K          = $k
        $this.Linkage    = "average"
        $this.MergeHistory = [System.Collections.ArrayList]::new()
    }

    HierarchicalClustering([int]$k, [string]$linkage) {
        $this.K          = $k
        $this.Linkage    = $linkage
        $this.MergeHistory = [System.Collections.ArrayList]::new()
    }

    # Distance between two clusters based on linkage type
    hidden [double] ClusterDistance([System.Collections.ArrayList]$clusterA,
                                    [System.Collections.ArrayList]$clusterB,
                                    [double[][]]$X) {
        $dists = @()
        foreach ($i in $clusterA) {
            foreach ($j in $clusterB) {
                $dists += Get-EuclideanDistance $X[$i] $X[$j]
            }
        }
        switch ($this.Linkage) {
            "single"   { return ($dists | Measure-Object -Minimum).Minimum }
            "complete" { return ($dists | Measure-Object -Maximum).Maximum }
            "average"  { return ($dists | Measure-Object -Average).Average }
        }
        return ($dists | Measure-Object -Average).Average
    }

    [void] Fit([double[][]]$X) {
        $n = $X.Length
        $this.MergeHistory.Clear()

        # Start: each point is its own cluster
        $clusters = [System.Collections.ArrayList]::new()
        for ($i = 0; $i -lt $n; $i++) {
            $c = [System.Collections.ArrayList]::new()
            $c.Add($i) | Out-Null
            $clusters.Add($c) | Out-Null
        }

        # Merge until we have k clusters
        while ($clusters.Count -gt $this.K) {
            $bestDist = [double]::MaxValue
            $bestA    = 0
            $bestB    = 1

            # Find closest pair of clusters
            for ($a = 0; $a -lt $clusters.Count; $a++) {
                for ($b = $a + 1; $b -lt $clusters.Count; $b++) {
                    $dist = $this.ClusterDistance($clusters[$a], $clusters[$b], $X)
                    if ($dist -lt $bestDist) {
                        $bestDist = $dist
                        $bestA    = $a
                        $bestB    = $b
                    }
                }
            }

            # Merge clusters bestA and bestB
            $merged = [System.Collections.ArrayList]::new()
            foreach ($idx in $clusters[$bestA]) { $merged.Add($idx) | Out-Null }
            foreach ($idx in $clusters[$bestB]) { $merged.Add($idx) | Out-Null }

            $this.MergeHistory.Add(@{
                ClusterA = $bestA
                ClusterB = $bestB
                Distance = [Math]::Round($bestDist, 4)
                Remaining = $clusters.Count - 1
            }) | Out-Null

            # Remove old clusters (higher index first to preserve indices)
            if ($bestB -gt $bestA) {
                $clusters.RemoveAt($bestB)
                $clusters.RemoveAt($bestA)
            } else {
                $clusters.RemoveAt($bestA)
                $clusters.RemoveAt($bestB)
            }
            $clusters.Add($merged) | Out-Null
        }

        # Assign labels
        $this.Labels = @(0) * $n
        for ($c = 0; $c -lt $clusters.Count; $c++) {
            foreach ($idx in $clusters[$c]) { $this.Labels[$idx] = $c }
        }
        $this.IsFitted = $true
    }

    [void] PrintSummary() {
        Write-Host ""
        Write-Host "╔══════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║    Hierarchical Clustering Summary   ║" -ForegroundColor Cyan
        Write-Host "╠══════════════════════════════════════╣" -ForegroundColor Cyan
        Write-Host ("║  K           : {0,-22}║" -f $this.K)        -ForegroundColor White
        Write-Host ("║  Linkage     : {0,-22}║" -f $this.Linkage)  -ForegroundColor White
        Write-Host ("║  Merges done : {0,-22}║" -f $this.MergeHistory.Count) -ForegroundColor White
        Write-Host "╠══════════════════════════════════════╣" -ForegroundColor Cyan
        $counts = @{}
        foreach ($l in $this.Labels) {
            if ($counts.ContainsKey($l)) { $counts[$l]++ } else { $counts[$l] = 1 }
        }
        foreach ($kv in $counts.GetEnumerator() | Sort-Object Key) {
            Write-Host ("║  Cluster {0}   : n={1,-22}║" -f $kv.Key, $kv.Value) -ForegroundColor White
        }
        Write-Host "╚══════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
    }

    [void] PrintDendrogram() {
        Write-Host ""
        Write-Host "🌿 Last 10 merges (dendrogram tail):" -ForegroundColor Green
        $start = [Math]::Max(0, $this.MergeHistory.Count - 10)
        for ($i = $start; $i -lt $this.MergeHistory.Count; $i++) {
            $m = $this.MergeHistory[$i]
            Write-Host ("  Step {0,2}: merge clusters {1}+{2}  dist={3}  remaining={4}" -f
                ($i+1), $m.ClusterA, $m.ClusterB, $m.Distance, $m.Remaining) -ForegroundColor White
        }
        Write-Host ""
    }
}

# ============================================================
# DBSCAN
# ============================================================
# TEACHING NOTE: DBSCAN = Density-Based Spatial Clustering
# Key insight: clusters are DENSE regions separated by sparse regions.
# Two parameters:
#   Epsilon  : neighbourhood radius - how close is "nearby"?
#   MinPoints: minimum points to form a dense region
#
# Three types of points:
#   CORE    : has >= MinPoints neighbours within Epsilon
#   BORDER  : within Epsilon of a core point, but not core itself
#   NOISE   : not near any core point -> label = -1
#
# Advantage: finds clusters of ANY shape, handles noise/outliers!
# Disadvantage: sensitive to Epsilon and MinPoints choices.
# ============================================================

class DBSCAN {
    [double] $Epsilon    # Neighbourhood radius
    [int]    $MinPoints  # Minimum points for dense region
    [int[]]  $Labels     # -1=noise, 0,1,2...=cluster id
    [int]    $NClusters  # Number of clusters found
    [int]    $NNoise     # Number of noise points
    [bool]   $IsFitted = $false

    DBSCAN([double]$epsilon, [int]$minPoints) {
        $this.Epsilon   = $epsilon
        $this.MinPoints = $minPoints
    }

    # Find all points within Epsilon of point i
    hidden [int[]] GetNeighbours([double[][]]$X, [int]$i) {
        $neighbours = @()
        for ($j = 0; $j -lt $X.Length; $j++) {
            if ($j -eq $i) { continue }
            if ((Get-EuclideanDistance $X[$i] $X[$j]) -le $this.Epsilon) {
                $neighbours += $j
            }
        }
        return $neighbours
    }

    [void] Fit([double[][]]$X) {
        $n            = $X.Length
        $this.Labels  = @(-2) * $n   # -2 = unvisited
        $clusterId    = 0

        for ($i = 0; $i -lt $n; $i++) {
            if ($this.Labels[$i] -ne -2) { continue }  # already visited

            $neighbours = $this.GetNeighbours($X, $i)

            if ($neighbours.Length -lt $this.MinPoints) {
                # Not enough neighbours -> noise (for now)
                $this.Labels[$i] = -1
                continue
            }

            # Start a new cluster
            $this.Labels[$i] = $clusterId
            $queue = [System.Collections.ArrayList]::new()
            foreach ($nb in $neighbours) { $queue.Add($nb) | Out-Null }

            # Expand cluster
            $qi = 0
            while ($qi -lt $queue.Count) {
                $j = $queue[$qi]
                $qi++

                if ($this.Labels[$j] -eq -1) {
                    # Border point - add to cluster
                    $this.Labels[$j] = $clusterId
                }

                if ($this.Labels[$j] -ne -2) { continue }
                $this.Labels[$j] = $clusterId

                $jNeighbours = $this.GetNeighbours($X, $j)
                if ($jNeighbours.Length -ge $this.MinPoints) {
                    foreach ($nb in $jNeighbours) {
                        if ($this.Labels[$nb] -eq -2 -or $this.Labels[$nb] -eq -1) {
                            $queue.Add($nb) | Out-Null
                        }
                    }
                }
            }
            $clusterId++
        }

        $this.NClusters = $clusterId
        $this.NNoise    = ($this.Labels | Where-Object { $_ -eq -1 }).Count
        $this.IsFitted  = $true
    }

    [void] PrintSummary() {
        Write-Host ""
        Write-Host "╔══════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          DBSCAN Summary              ║" -ForegroundColor Cyan
        Write-Host "╠══════════════════════════════════════╣" -ForegroundColor Cyan
        Write-Host ("║  Epsilon     : {0,-22}║" -f $this.Epsilon)    -ForegroundColor White
        Write-Host ("║  MinPoints   : {0,-22}║" -f $this.MinPoints)  -ForegroundColor White
        Write-Host ("║  Clusters    : {0,-22}║" -f $this.NClusters)  -ForegroundColor Green
        Write-Host ("║  Noise pts   : {0,-22}║" -f $this.NNoise)     -ForegroundColor Yellow
        Write-Host "╠══════════════════════════════════════╣" -ForegroundColor Cyan
        $counts = @{}
        foreach ($l in $this.Labels) {
            $key = if ($l -eq -1) { "Noise" } else { "Cluster $l" }
            if ($counts.ContainsKey($key)) { $counts[$key]++ } else { $counts[$key] = 1 }
        }
        foreach ($kv in $counts.GetEnumerator() | Sort-Object Key) {
            $color = if ($kv.Key -eq "Noise") { "DarkGray" } else { "White" }
            Write-Host ("║  {0,-14}: n={1,-20}║" -f $kv.Key, $kv.Value) -ForegroundColor $color
        }
        Write-Host "╚══════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
    }
}

# ============================================================
# CLUSTER EVALUATION METRICS
# ============================================================
# TEACHING NOTE: How do we know if clustering is good?
#
# INERTIA (K-Means only):
#   Sum of squared distances to cluster centroids.
#   Lower = tighter clusters. But always decreases with more k!
#
# SILHOUETTE SCORE (-1 to +1):
#   For each point: how similar to own cluster vs nearest other?
#   +1 = perfectly placed, 0 = on boundary, -1 = wrong cluster
#   Average silhouette = overall quality.
# ============================================================

function Get-SilhouetteScore {
    param([double[][]]$X, [int[]]$labels)

    $n      = $X.Length
    $scores = @(0.0) * $n

    for ($i = 0; $i -lt $n; $i++) {
        if ($labels[$i] -eq -1) { $scores[$i] = 0.0; continue }  # DBSCAN noise

        # Average distance to points in SAME cluster (a)
        $sameCluster = @()
        for ($j = 0; $j -lt $n; $j++) {
            if ($j -ne $i -and $labels[$j] -eq $labels[$i]) {
                $sameCluster += Get-EuclideanDistance $X[$i] $X[$j]
            }
        }
        $a = if ($sameCluster.Length -gt 0) {
            ($sameCluster | Measure-Object -Average).Average
        } else { 0.0 }

        # Average distance to points in NEAREST OTHER cluster (b)
        $otherClusters = $labels | Select-Object -Unique | Where-Object { $_ -ne $labels[$i] -and $_ -ne -1 }
        $bValues = @()
        foreach ($c in $otherClusters) {
            $dists = @()
            for ($j = 0; $j -lt $n; $j++) {
                if ($labels[$j] -eq $c) {
                    $dists += Get-EuclideanDistance $X[$i] $X[$j]
                }
            }
            if ($dists.Length -gt 0) {
                $bValues += ($dists | Measure-Object -Average).Average
            }
        }
        $b = if ($bValues.Length -gt 0) { ($bValues | Measure-Object -Minimum).Minimum } else { 0.0 }

        $maxAB       = [Math]::Max($a, $b)
        $scores[$i]  = if ($maxAB -gt 0) { ($b - $a) / $maxAB } else { 0.0 }
    }

    $avg = ($scores | Measure-Object -Average).Average
    return @{
        AvgScore = [Math]::Round($avg, 4)
        Scores   = $scores
    }
}

# ============================================================
# ELBOW METHOD - ASCII visualization
# ============================================================
# TEACHING NOTE: How to choose k for K-Means?
# The Elbow Method plots inertia vs k.
# As k increases, inertia drops. But there's usually an "elbow"
# where the improvement slows down suddenly.
# That elbow point = good choice for k!
# ============================================================

function Invoke-ElbowMethod {
    param(
        [double[][]] $X,
        [int]        $MaxK     = 8,
        [int]        $MaxIter  = 50
    )

    Write-Host ""
    Write-Host "📐 Elbow Method (k=1 to $MaxK)" -ForegroundColor Yellow
    Write-Host ""

    $inertias = @()
    for ($k = 1; $k -le $MaxK; $k++) {
        $km = [KMeans]::new($k, $MaxIter)
        $km.Fit($X)
        $inertias += $km.Inertia
        Write-Host ("  k={0}: inertia={1:F2}" -f $k, $km.Inertia) -ForegroundColor DarkGray
    }

    # ASCII bar chart
    $maxInertia = ($inertias | Measure-Object -Maximum).Maximum
    Write-Host ""
    Write-Host "  Inertia vs K (look for the elbow!):" -ForegroundColor Yellow
    Write-Host ""
    for ($k = 0; $k -lt $inertias.Length; $k++) {
        $barLen = if ($maxInertia -gt 0) { [int](($inertias[$k] / $maxInertia) * 30) } else { 0 }
        $bar    = "█" * $barLen
        Write-Host ("  k={0}  {1,-32} {2:F1}" -f ($k+1), $bar, $inertias[$k]) -ForegroundColor White
    }
    Write-Host ""
    Write-Host "  💡 Look for where the bar length drop SLOWS DOWN = elbow = best k" -ForegroundColor Yellow
    Write-Host ""

    return $inertias
}

# ============================================================
# BUILT-IN DATASETS
# ============================================================
function Get-VBAFClusterDataset {
    param([string]$Name = "Blobs")

    switch ($Name) {
        "Blobs" {
            # Three clear clusters
            Write-Host "📊 Dataset: Blobs (30 samples, 3 clusters)" -ForegroundColor Cyan
            Write-Host "   Features: [x, y]" -ForegroundColor Cyan
            $X = @(
                # Cluster 0 - bottom left
                @(1.0,1.0),@(1.5,1.2),@(0.8,1.8),@(1.2,0.7),@(0.9,1.4),
                @(1.3,1.6),@(0.7,0.9),@(1.6,1.1),@(1.1,1.9),@(0.6,1.3),
                # Cluster 1 - top middle
                @(5.0,8.0),@(5.5,7.8),@(4.8,8.5),@(5.2,7.5),@(4.9,8.2),
                @(5.3,8.7),@(4.7,7.9),@(5.6,8.1),@(5.1,7.6),@(4.6,8.4),
                # Cluster 2 - right
                @(9.0,4.0),@(9.5,4.2),@(8.8,3.8),@(9.2,4.7),@(8.9,3.5),
                @(9.3,4.5),@(8.7,4.1),@(9.6,3.9),@(9.1,4.3),@(8.6,4.6)
            )
            $trueLabels = @(0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2)
            return @{ X=$X; TrueLabels=$trueLabels; K=3 }
        }
        "Moons" {
            # Two interleaved half-circles - DBSCAN handles, K-Means struggles!
            Write-Host "📊 Dataset: Moons (20 samples)" -ForegroundColor Cyan
            Write-Host "   Features: [x, y]  - two crescent shapes" -ForegroundColor Cyan
            Write-Host "   💡 K-Means struggles here, DBSCAN handles it!" -ForegroundColor Yellow
            $X = @(
                @(0.0,0.5),@(0.3,0.8),@(0.6,0.9),@(0.9,0.8),@(1.0,0.5),
                @(0.9,0.2),@(0.6,0.1),@(0.3,0.2),@(0.15,0.45),@(0.75,0.95),
                @(1.0,0.0),@(1.3,-0.3),@(1.6,-0.4),@(1.9,-0.3),@(2.0,0.0),
                @(1.9,0.3),@(1.6,0.4),@(1.3,0.3),@(1.15,-0.05),@(1.75,-0.35)
            )
            $trueLabels = @(0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1)
            return @{ X=$X; TrueLabels=$trueLabels; K=2 }
        }
        default {
            Write-Host "❌ Unknown dataset: $Name" -ForegroundColor Red
            Write-Host "   Available: Blobs, Moons" -ForegroundColor Yellow
            return $null
        }
    }
}

# ============================================================
# TEST
# 1. Run VBAF.LoadAll.ps1
#
# --- K-Means ---
# 2. $data = Get-VBAFClusterDataset -Name "Blobs"
#    $km   = [KMeans]::new(3)
#    $km.Fit($data.X)
#    $km.PrintSummary()
#    Get-SilhouetteScore -X $data.X -labels $km.Labels
#
# --- Elbow Method ---
# 3. Invoke-ElbowMethod -X $data.X -MaxK 6
#    (look for elbow at k=3 for the Blobs dataset!)
#
# --- Hierarchical ---
# 4. $hc = [HierarchicalClustering]::new(3, "average")
#    $hc.Fit($data.X)
#    $hc.PrintSummary()
#    $hc.PrintDendrogram()
#
# --- DBSCAN ---
# 5. $db = [DBSCAN]::new(1.5, 3)
#    $db.Fit($data.X)
#    $db.PrintSummary()
#
# --- DBSCAN on Moons (K-Means weakness demo) ---
# 6. $moons = Get-VBAFClusterDataset -Name "Moons"
#    $km2   = [KMeans]::new(2)
#    $km2.Fit($moons.X)
#    $km2.PrintSummary()
#    $db2   = [DBSCAN]::new(0.4, 3)
#    $db2.Fit($moons.X)
#    $db2.PrintSummary()
#    (Compare: K-Means fails on crescents, DBSCAN finds them!)
# ============================================================
Write-Host "📦 VBAF.ML.Clustering.ps1 loaded" -ForegroundColor Green
Write-Host "   Classes   : KMeans, HierarchicalClustering, DBSCAN" -ForegroundColor Cyan
Write-Host "   Functions : Get-SilhouetteScore"                    -ForegroundColor Cyan
Write-Host "              Invoke-ElbowMethod"                      -ForegroundColor Cyan
Write-Host "              Get-VBAFClusterDataset"                  -ForegroundColor Cyan
Write-Host ""
Write-Host "   Quick start:" -ForegroundColor Yellow
Write-Host '   $data = Get-VBAFClusterDataset -Name "Blobs"'   -ForegroundColor White
Write-Host '   $km   = [KMeans]::new(3)'                       -ForegroundColor White
Write-Host '   $km.Fit($data.X)'                               -ForegroundColor White
Write-Host '   $km.PrintSummary()'                             -ForegroundColor White
Write-Host ""