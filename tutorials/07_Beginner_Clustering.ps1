<#
#Requires -Version 5.1
.SYNOPSIS
    VBAF Tutorial 07 - Your First Clustering Model
    Beginner Series | Estimated time: 20 minutes
.DESCRIPTION
    Learn how to:
      - Understand unsupervised learning (no labels needed!)
      - Train a KMeans clustering model
      - Visualise clusters with ASCII art
      - Use clustering for anomaly detection
      - Choose the right number of clusters (K)
    Run this script section by section in PowerShell ISE
    or paste blocks into the PS console.
#>

# ============================================================
# SECTION 1: Load the framework
# ============================================================
. .\VBAF.LoadAll.ps1

Write-Host "=== VBAF Tutorial 07: Your First Clustering Model ===" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# SECTION 2: What is clustering?
# ============================================================
# TEACHING: Classification needs labels (we tell it the answer).
#           Clustering finds natural groups WITH NO LABELS.
#           KMeans asks: "given K groups, which points belong together?"

Write-Host "--- What is clustering? ---" -ForegroundColor Yellow
Write-Host "  No labels needed — finds hidden structure in data" -ForegroundColor White
Write-Host "  Use case: customer segments, anomaly detection, compression" -ForegroundColor White
Write-Host ""

# ============================================================
# SECTION 3: Generate sensor data (3 operating modes)
# ============================================================
# TEACHING: We simulate 3 machine states: idle, normal, high load
# Each has different temperature, pressure, vibration patterns.

Write-Host "--- Generating sensor data ---" -ForegroundColor Yellow

$rng = [System.Random]::new(42)
$sensorData = @()
$trueLabels = @()

for ($i = 0; $i -lt 60; $i++) {
    $mode = $i % 3
    [double]$r1 = $rng.NextDouble()
    [double]$r2 = $rng.NextDouble()
    [double]$r3 = $rng.NextDouble()
    if ($mode -eq 0) {
        [double]$v1 = 70.0 + $r1*5.0
        [double]$v2 = 1.0  + $r2*0.1
        [double]$v3 = 50.0 + $r3*5.0
        $label = "Idle"
    } elseif ($mode -eq 1) {
        [double]$v1 = 85.0 + $r1*5.0
        [double]$v2 = 1.5  + $r2*0.1
        [double]$v3 = 80.0 + $r3*5.0
        $label = "Normal"
    } else {
        [double]$v1 = 95.0 + $r1*5.0
        [double]$v2 = 2.0  + $r2*0.1
        [double]$v3 = 120.0 + $r3*5.0
        $label = "HighLoad"
    }
    $sensorData += ,[double[]]@($v1,$v2,$v3)
    $trueLabels += $label
}

Write-Host "  Generated $($sensorData.Length) sensor readings" -ForegroundColor White
Write-Host "  Features: temperature, pressure, vibration" -ForegroundColor White
Write-Host "  True modes: Idle / Normal / HighLoad (hidden from model!)" -ForegroundColor White
Write-Host ""

# ============================================================
# SECTION 4: Scale and train KMeans
# ============================================================
# TEACHING: KMeans uses distances — ALWAYS scale first!
# Without scaling, vibration (50-120) dominates temperature (70-100).

Write-Host "--- Scaling and Training KMeans (K=3) ---" -ForegroundColor Yellow

$scaler = [StandardScaler]::new()
$Xs     = $scaler.FitTransform($sensorData)

$km = [KMeans]::new(3)
$km.Fit($Xs)
$km.PrintSummary()

# ============================================================
# SECTION 5: Inspect cluster assignments
# ============================================================
Write-Host "--- Cluster Assignments ---" -ForegroundColor Yellow
Write-Host ("  {0,-10} {1,-10} {2}" -f "TrueMode", "Cluster", "Match") -ForegroundColor Yellow
Write-Host ("  {0}" -f ("-" * 35)) -ForegroundColor DarkGray

$labels  = $km.Predict($Xs)
$correct = 0
$counts  = @{}

for ($i = 0; $i -lt [Math]::Min(15, $sensorData.Length); $i++) {
    $trueMode = $trueLabels[$i]
    $pred  = $labels[$i]
    $key   = "$true->C$pred"
    if (-not $counts.ContainsKey($key)) { $counts[$key] = 0 }
    $counts[$key]++
    Write-Host ("  {0,-10} Cluster {1,-4}" -f $trueMode, $pred) -ForegroundColor White
}

Write-Host ""
Write-Host "--- Cluster Distribution ---" -ForegroundColor Yellow
for ($k = 0; $k -lt 3; $k++) {
    $n   = ($labels | Where-Object { $_ -eq $k }).Count
    $bar = "█" * $n
    Write-Host ("  Cluster {0}: {1,3} samples  {2}" -f $k, $n, $bar) -ForegroundColor Cyan
}
Write-Host ""

# ============================================================
# SECTION 6: Try different values of K
# ============================================================
# TEACHING: How do we know K=3 is right?
# Inertia = sum of distances to nearest centroid.
# Lower inertia = tighter clusters. But more K always = lower inertia!
# Look for the "elbow" — where adding K stops helping much.

Write-Host "--- Choosing K: Inertia by number of clusters ---" -ForegroundColor Yellow
Write-Host ("  {0,-5} {1,10}  {2}" -f "K", "Inertia", "Bar") -ForegroundColor Yellow
Write-Host ("  {0}" -f ("-" * 45)) -ForegroundColor DarkGray

for ($k = 1; $k -le 6; $k++) {
    $kmTest = [KMeans]::new($k)
    $kmTest.Fit($Xs)
    [double]$inertia = $kmTest.Inertia
    $bar = "█" * [int]($inertia * 2)
    $marker = if ($k -eq 3) { " <- elbow (best K)" } else { "" }
    Write-Host ("  K={0,-3} {1,10:F2}  {2}{3}" -f $k, $inertia, $bar, $marker) -ForegroundColor $(if ($k -eq 3) { "Green" } else { "White" })
}

Write-Host ""

# ============================================================
# SECTION 7: Use clustering for anomaly detection
# ============================================================
# TEACHING: Points far from ALL centroids are anomalies!
# Distance to nearest centroid = anomaly score.

Write-Host "--- Anomaly Detection with Clustering ---" -ForegroundColor Yellow

function Get-ClusterAnomalyScore {
    param([double[]]$x, [object]$model)
    $minDist = [double]::MaxValue
    foreach ($c in $model.Centroids) {
        $dist = 0.0
        for ($i = 0; $i -lt $x.Length; $i++) {
            [double]$diff = $x[$i] - $c[$i]
            $dist += $diff * $diff
        }
        [double]$d = [Math]::Sqrt($dist)
        if ($d -lt $minDist) { $minDist = $d }
    }
    return $minDist
}

# Compute threshold from training data
$scores = @()
foreach ($x in $Xs) { $scores += Get-ClusterAnomalyScore -x ([double[]]$x) -model $km }
$mean      = ($scores | Measure-Object -Average).Average
$std       = [Math]::Sqrt((($scores | ForEach-Object { ($_ - $mean)*($_ - $mean) } | Measure-Object -Sum).Sum / $scores.Count))
$threshold = $mean + 3.0 * $std

Write-Host ("  Normal score range : {0:F3} ± {1:F3}" -f $mean, $std) -ForegroundColor White
Write-Host ("  Anomaly threshold  : {0:F3} (3-sigma)" -f $threshold) -ForegroundColor Yellow
Write-Host ""

# Test with normal + anomalous readings
$testPoints = @(
    @{ Name="Normal-Idle";    X=[double[]]@(71.0, 1.02, 51.0) },
    @{ Name="Normal-Load";    X=[double[]]@(87.0, 1.53, 82.0) },
    @{ Name="OVERHEATING";    X=[double[]]@(140.0, 3.5, 200.0) },
    @{ Name="SENSOR-FAILURE"; X=[double[]]@(30.0, 0.2, 5.0) }
)

Write-Host ("  {0,-16} {1,8}  {2}" -f "Sample", "Score", "Status") -ForegroundColor Yellow
Write-Host ("  {0}" -f ("-" * 40)) -ForegroundColor DarkGray

foreach ($tp in $testPoints) {
    $xs    = $scaler.Transform(@(,$tp.X))
    $score = Get-ClusterAnomalyScore -x ([double[]]$xs[0]) -model $km
    $isAnom = $score -gt $threshold
    $status = if ($isAnom) { "ANOMALY!" } else { "Normal" }
    $color  = if ($isAnom) { "Red" } else { "Green" }
    Write-Host ("  {0,-16} {1,8:F3}  {2}" -f $tp.Name, $score, $status) -ForegroundColor $color
}

Write-Host ""
Write-Host "=== Key Takeaways ===" -ForegroundColor Cyan
Write-Host "  KMeans needs K upfront — use the elbow method to choose" -ForegroundColor White
Write-Host "  Always scale before clustering — distances are scale-sensitive" -ForegroundColor White
Write-Host "  Clustering + distance = simple but powerful anomaly detector" -ForegroundColor White
Write-Host "  No labels needed — perfect for exploratory analysis" -ForegroundColor White
Write-Host ""
Write-Host "Tutorial 07 complete! Try Tutorial 08 next: Load Your Own Data." -ForegroundColor Green

