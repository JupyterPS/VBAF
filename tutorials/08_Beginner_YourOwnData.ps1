<#
#Requires -Version 5.1
.SYNOPSIS
    VBAF Tutorial 08 - Load Your Own Data
    Beginner Series | Estimated time: 25 minutes
.DESCRIPTION
    Learn how to:
      - Load any CSV file into VBAF
      - Handle missing values and data types
      - Encode categorical columns
      - Feed your own data into any VBAF model
      - Save predictions back to CSV
    This is the bridge between tutorials and real work!
#>

# ============================================================
# SECTION 1: Load the framework
# ============================================================
. .\VBAF.LoadAll.ps1

Write-Host "=== VBAF Tutorial 08: Load Your Own Data ===" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# SECTION 2: Create a sample CSV to work with
# ============================================================
# TEACHING: We create a realistic CSV so you can follow along.
# Replace this with your own CSV path when ready!

Write-Host "--- Creating sample CSV ---" -ForegroundColor Yellow

$csvPath = Join-Path $env:TEMP "vbaf_sample.csv"
$csvData = @"
size_sqm,bedrooms,age_years,location,price
85,3,5,urban,320
120,4,10,suburban,410
60,2,20,rural,180
95,3,8,urban,350
140,5,2,suburban,520
75,2,15,rural,220
110,4,6,urban,430
55,1,25,rural,160
130,4,12,suburban,480
90,3,7,urban,340
,3,5,urban,310
100,4,,suburban,390
80,2,18,rural,200
115,4,9,urban,445
70,3,22,,240
"@
Set-Content $csvPath -Value $csvData -Encoding UTF8
Write-Host "  Sample CSV created: $csvPath" -ForegroundColor White
Write-Host "  15 rows, 5 columns, intentional missing values" -ForegroundColor White
Write-Host ""

# ============================================================
# SECTION 3: Load and inspect the CSV
# ============================================================
Write-Host "--- Loading CSV ---" -ForegroundColor Yellow

$raw = Import-Csv $csvPath
Write-Host "  Rows loaded : $($raw.Count)" -ForegroundColor White
Write-Host "  Columns     : $($raw[0].PSObject.Properties.Name -join ', ')" -ForegroundColor White
Write-Host ""

# Show first 5 rows
Write-Host "  First 5 rows:" -ForegroundColor Yellow
Write-Host ("  {0,-10} {1,-10} {2,-10} {3,-10} {4}" -f "size_sqm","bedrooms","age_years","location","price") -ForegroundColor Cyan
for ($i = 0; $i -lt [Math]::Min(5, $raw.Count); $i++) {
    $r = $raw[$i]
    Write-Host ("  {0,-10} {1,-10} {2,-10} {3,-10} {4}" -f $r.size_sqm, $r.bedrooms, $r.age_years, $r.location, $r.price) -ForegroundColor White
}
Write-Host ""

# ============================================================
# SECTION 4: Convert to numeric arrays
# ============================================================
# TEACHING: VBAF needs double[][] for X and double[] for y.
# Steps: parse numbers, handle missing, encode categories.

Write-Host "--- Converting to VBAF format ---" -ForegroundColor Yellow

# Encode location: urban=2, suburban=1, rural=0
$locationMap = @{ "urban"=2.0; "suburban"=1.0; "rural"=0.0 }

$X = @()
$y = @()
$skipped = 0

foreach ($row in $raw) {
    # Parse each field — use median fallback for missing
    [double]$size = if ($row.size_sqm -ne "") { [double]$row.size_sqm } else { 95.0 }
    [double]$beds = if ($row.bedrooms -ne "")  { [double]$row.bedrooms } else { 3.0 }
    [double]$age  = if ($row.age_years -ne "")  { [double]$row.age_years } else { 10.0 }
    [double]$loc  = if ($row.location -ne "" -and $locationMap.ContainsKey($row.location)) { $locationMap[$row.location] } else { 1.0 }
    [double]$price= if ($row.price -ne "")     { [double]$row.price } else { $skipped++; continue }

    $X += ,[double[]]@($size, $beds, $age, $loc)
    $y += $price
}

Write-Host "  Usable rows : $($X.Length)" -ForegroundColor Green
Write-Host "  Skipped     : $skipped (missing target)" -ForegroundColor Yellow
Write-Host "  Features    : size_sqm, bedrooms, age_years, location(encoded)" -ForegroundColor White
Write-Host ""

# ============================================================
# SECTION 5: Train a model on your data
# ============================================================
Write-Host "--- Training Ridge Regression on your data ---" -ForegroundColor Yellow

$scaler = [StandardScaler]::new()
$Xs     = $scaler.FitTransform($X)
$split  = Split-TrainTest -X $Xs -y $y -TestSize 0.2 -Seed 42

$model = [RidgeRegression]::new(0.1)
$model.Fit($split.XTrain, $split.yTrain)

$preds   = $model.Predict($split.XTest)
$metrics = Get-RegressionMetrics $split.yTest $preds

Write-Host "  Train samples : $($split.XTrain.Length)" -ForegroundColor White
Write-Host "  Test  samples : $($split.XTest.Length)"  -ForegroundColor White
Write-Host ("  R2            : {0:F4}" -f $metrics.R2)   -ForegroundColor Green
Write-Host ("  RMSE          : {0:F2}" -f $metrics.RMSE) -ForegroundColor White
Write-Host ""

# ============================================================
# SECTION 6: Make predictions on new houses
# ============================================================
Write-Host "--- Predicting prices for new houses ---" -ForegroundColor Yellow

$newHouses = @(
    @{ Desc="100sqm 3bed 5yr urban";    X=[double[]]@(100.0, 3.0, 5.0,  2.0) },
    @{ Desc="150sqm 5bed 1yr suburban"; X=[double[]]@(150.0, 5.0, 1.0,  1.0) },
    @{ Desc="60sqm  1bed 30yr rural";   X=[double[]]@(60.0,  1.0, 30.0, 0.0) }
)

Write-Host ("  {0,-30} {1}" -f "House", "Predicted Price") -ForegroundColor Yellow
Write-Host ("  {0}" -f ("-" * 45)) -ForegroundColor DarkGray

foreach ($h in $newHouses) {
    $xs   = $scaler.Transform(@(,$h.X))
    $pred = $model.Predict($xs)
    Write-Host ("  {0,-30} {1:F0}k" -f $h.Desc, $pred[0]) -ForegroundColor White
}
Write-Host ""

# ============================================================
# SECTION 7: Save predictions to CSV
# ============================================================
Write-Host "--- Saving predictions to CSV ---" -ForegroundColor Yellow

$outPath = Join-Path $env:TEMP "vbaf_predictions.csv"
$allPreds = $model.Predict($Xs)

$output = @()
for ($i = 0; $i -lt $X.Length; $i++) {
    $output += [PSCustomObject]@{
        size_sqm    = $X[$i][0]
        bedrooms    = $X[$i][1]
        age_years   = $X[$i][2]
        location    = ($locationMap.GetEnumerator() | Where-Object { $_.Value -eq $X[$i][3] } | Select-Object -First 1).Key
        actual_price = $y[$i]
        predicted   = [Math]::Round($allPreds[$i], 1)
        error       = [Math]::Round([Math]::Abs($y[$i] - $allPreds[$i]), 1)
    }
}
$output | Export-Csv $outPath -NoTypeInformation -Encoding UTF8
Write-Host "  Predictions saved: $outPath" -ForegroundColor Green
Write-Host "  Open in Excel to inspect results!" -ForegroundColor White
Write-Host ""

Write-Host "=== Key Takeaways ===" -ForegroundColor Cyan
Write-Host "  Import-Csv loads any CSV into PowerShell" -ForegroundColor White
Write-Host "  Parse each column to [double] — handle missing with fallback values" -ForegroundColor White
Write-Host "  Encode categories: urban=2, suburban=1, rural=0" -ForegroundColor White
Write-Host "  VBAF needs: X as double[][], y as double[]" -ForegroundColor White
Write-Host "  Export-Csv saves predictions back to file" -ForegroundColor White
Write-Host ""
Write-Host "  NEXT STEP: Replace `$csvPath with YOUR own CSV file path!" -ForegroundColor Yellow
Write-Host ""
Write-Host "Tutorial 08 complete! Try Tutorial 09 next: Feature Engineering." -ForegroundColor Green
