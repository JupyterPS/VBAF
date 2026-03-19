<#
#Requires -Version 5.1
.SYNOPSIS
    VBAF Tutorial 05 - Real-World Project: Anomaly Detection
    Real-World Projects | Estimated time: 30 minutes
.DESCRIPTION
    Build an anomaly detection system using clustering and statistics:
      - Train a KMeans model on normal data
      - Use reconstruction distance as anomaly score
      - Set threshold from training distribution
      - Detect anomalies in production data
      - Monitor anomaly rate over time
    Real use case: detect unusual sensor readings, fraud, etc.
#>

Write-Host ""
Write-Host "+--------------------------------------------------+" -ForegroundColor Cyan
Write-Host "¦  VBAF Tutorial 05 - Anomaly Detection Project    ¦" -ForegroundColor Cyan
Write-Host "¦  Detect unusual patterns in production data      ¦" -ForegroundColor Cyan
Write-Host "+--------------------------------------------------+" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# STEP 1: Generate normal training data
# ============================================================
Write-Host "--- Step 1: Training Data (normal patterns) ---" -ForegroundColor Yellow

$rng = [System.Random]::new(42)

# Simulate sensor readings: temperature, pressure, vibration
# Normal operating range: well-defined clusters
$normalData = @()
for ($i = 0; $i -lt 80; $i++) {
    $cluster = $i % 3
    [double] $r1 = $rng.NextDouble()
    [double] $r2 = $rng.NextDouble()
    [double] $r3 = $rng.NextDouble()
    if ($cluster -eq 0) {
        [double]$v1=70.0+$r1*5.0; [double]$v2=1.0+$r2*0.1; [double]$v3=50.0+$r3*5.0
        $sample = [double[]]@($v1,$v2,$v3)
    } elseif ($cluster -eq 1) {
        [double]$v1=85.0+$r1*5.0; [double]$v2=1.5+$r2*0.1; [double]$v3=80.0+$r3*5.0
        $sample = [double[]]@($v1,$v2,$v3)
    } else {
        [double]$v1=95.0+$r1*5.0; [double]$v2=2.0+$r2*0.1; [double]$v3=120.0+$r3*5.0
        $sample = [double[]]@($v1,$v2,$v3)
    }
    $normalData += ,$sample
}

Write-Host "  Normal samples: $($normalData.Length)" -ForegroundColor White
Write-Host "  Features: temperature, pressure, vibration" -ForegroundColor White

# ============================================================
# STEP 2: Train KMeans on normal data
# ============================================================
Write-Host "--- Step 2: Train KMeans on Normal Data ---" -ForegroundColor Yellow

$scaler = [StandardScaler]::new()
$Xs     = $scaler.FitTransform($normalData)

$km = [KMeans]::new(3)
$km.Fit($Xs)
$km.PrintSummary()

# ============================================================
# STEP 3: Compute anomaly threshold from training data
# ============================================================
Write-Host "--- Step 3: Compute Anomaly Threshold ---" -ForegroundColor Yellow

# Anomaly score = distance to nearest centroid
function Get-AnomalyScore {
    param([double[]]$x, [object]$KMeansModel)
    $minDist = [double]::MaxValue
    foreach ($centroid in $KMeansModel.Centroids) {
        $dist = 0.0
        for ($i = 0; $i -lt $x.Length; $i++) {
            $diff  = $x[$i] - $centroid[$i]
            $dist += $diff * $diff
        }
        $d = [Math]::Sqrt($dist)
        if ($d -lt $minDist) { $minDist = $d }
    }
    return $minDist
}

$trainScores = @()
foreach ($x in $Xs) {
    $trainScores += Get-AnomalyScore -x ([double[]]$x) -KMeansModel $km
}

$mean      = ($trainScores | Measure-Object -Average).Average
$std       = [Math]::Sqrt((($trainScores | ForEach-Object { ($_ - $mean)*($_ - $mean) } | Measure-Object -Sum).Sum / $trainScores.Count))
$threshold = $mean + 3.0 * $std   # 3-sigma rule

Write-Host ("  Training score: mean={0:F3}  std={1:F3}" -f $mean, $std) -ForegroundColor White
Write-Host ("  Threshold (3s): {0:F3}" -f $threshold) -ForegroundColor Yellow
Write-Host ""

# ============================================================
# STEP 4: Detect anomalies in production data
# ============================================================
Write-Host "--- Step 4: Production Anomaly Detection ---" -ForegroundColor Yellow

# Mix of normal and anomalous readings
$productionData = @(
    @(72.0, 1.05, 52.0),   # normal - idle
    @(87.0, 1.52, 82.0),   # normal - load
    @(96.0, 2.02, 122.0),  # normal - high
    @(71.0, 1.03, 51.0),   # normal
    @(130.0, 3.5, 200.0),  # ANOMALY - overheating!
    @(88.0, 1.55, 85.0),   # normal
    @(40.0, 0.3, 10.0),    # ANOMALY - sensor failure!
    @(93.0, 1.98, 118.0),  # normal
    @(150.0, 4.0, 250.0),  # ANOMALY - critical!
    @(75.0, 1.08, 55.0)    # normal
)

$prodLabels = @("idle","load","high","idle","OVERHEAT","load","SENSOR_FAIL","high","CRITICAL","idle")

Write-Host ("  {0,-12} {1,8} {2,10}  {3}" -f "Sample", "Score", "Threshold", "Status") -ForegroundColor Yellow
Write-Host ("  {0}" -f ("-" * 45)) -ForegroundColor DarkGray

$anomalyCount = 0
for ($i = 0; $i -lt $productionData.Length; $i++) {
    $xs    = $scaler.Transform(@(,$productionData[$i]))
    $score = Get-AnomalyScore -x ([double[]]$xs[0]) -KMeansModel $km
    $isAnomaly = $score -gt $threshold
    if ($isAnomaly) { $anomalyCount++ }
    $status = if ($isAnomaly) { "??  ANOMALY" } else { "? Normal" }
    $color  = if ($isAnomaly) { "Red" } else { "White" }
    Write-Host ("  {0,-12} {1,8:F3} {2,10:F3}  {3}" -f $prodLabels[$i], $score, $threshold, $status) -ForegroundColor $color
}

Write-Host ""
Write-Host ("  Detected {0}/{1} anomalies ?" -f $anomalyCount, $productionData.Length) -ForegroundColor Green

# ============================================================
# STEP 5: Monitor anomaly rate over time
# ============================================================
Write-Host ""
Write-Host "--- Step 5: Anomaly Rate Monitoring ---" -ForegroundColor Yellow

# Simulate daily anomaly rates
$dailyRates = @(0.02, 0.03, 0.02, 0.04, 0.03, 0.02, 0.25, 0.30, 0.28)
$days       = @("Mon","Tue","Wed","Thu","Fri","Sat","Sun+1","Mon+1","Tue+1")
$alertThreshold = 0.10

Write-Host ("  {0,-8} {1,8}  {2}" -f "Day", "Rate", "Status") -ForegroundColor Yellow
Write-Host ("  {0}" -f ("-" * 35)) -ForegroundColor DarkGray

for ($d = 0; $d -lt $dailyRates.Length; $d++) {
    $rate    = $dailyRates[$d]
    $isAlert = $rate -gt $alertThreshold
    $bar     = "¦" * [int]($rate * 100)
    $status  = if ($isAlert) { "?? ALERT" } else { "OK" }
    $color   = if ($isAlert) { "Red" } else { "White" }
    Write-Host ("  {0,-8} {1,7:P1}  {2} {3}" -f $days[$d], $rate, $bar, $status) -ForegroundColor $color
}

Write-Host ""
Write-Host "+--------------------------------------------------+" -ForegroundColor Green
Write-Host "¦            Project Summary                       ¦" -ForegroundColor Green
Write-Host ("¦  Normal samples  : 80 (3 clusters)              ¦") -ForegroundColor White
Write-Host ("¦  Threshold (3s)  : {0,-31}¦" -f ("{0:F3}" -f $threshold)) -ForegroundColor White
Write-Host ("¦  Anomalies found : {0}/10 (3 injected)           ¦" -f $anomalyCount) -ForegroundColor White
Write-Host ("¦  Rate spike      : Detected day 7-9 ?          ¦") -ForegroundColor White
Write-Host "+--------------------------------------------------+" -ForegroundColor Green
Write-Host ""
Write-Host "Tutorials complete! Check the VBAF GitHub for more examples." -ForegroundColor Cyan



