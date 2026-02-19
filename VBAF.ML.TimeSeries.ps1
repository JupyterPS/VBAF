#Requires -Version 5.1
<#
.SYNOPSIS
    Time Series - Datetime Processing and Feature Engineering
.DESCRIPTION
    Implements time series processing from scratch.
    Designed as a TEACHING resource - every step explained.
    Features included:
      - Datetime parsing      : flexible format detection
      - Lag features          : yesterday's value as today's feature
      - Rolling windows       : moving average, std, min, max
      - Seasonal decomposition: trend + seasonal + residual
      - Resampling            : daily -> weekly -> monthly aggregation
      - Built-in datasets     : synthetic sales and temperature series
    Standalone - no external VBAF dependencies required.
.NOTES
    Part of VBAF - Phase 5 Time Series Module
    PS 5.1 compatible
    Teaching project - every time series concept explained!
#>
$basePath = $PSScriptRoot

# ============================================================
# TEACHING NOTE: What is Time Series data?
# Data where ORDER MATTERS - each point depends on time.
# Examples: stock prices, temperature, sales, heart rate.
#
# Key concepts:
#   Trend     : long-term direction (going up/down over years)
#   Seasonality: repeating pattern (sales up every December)
#   Noise      : random fluctuation around the pattern
#   Lag        : past values used to predict future values
#   Window     : a sliding "view" over recent history
# ============================================================

# ============================================================
# TIME SERIES DATA STRUCTURE
# ============================================================

class TimeSeries {
    [datetime[]] $Timestamps
    [double[]]   $Values
    [string]     $Name
    [string]     $Frequency   # "daily", "weekly", "monthly"

    TimeSeries([datetime[]]$timestamps, [double[]]$values, [string]$name) {
        $this.Timestamps = $timestamps
        $this.Values     = $values
        $this.Name       = $name
        $this.Frequency  = "daily"
    }

    [int] Length() { return $this.Values.Length }

    [void] PrintSummary() {
        Write-Host ""
        Write-Host "╔══════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║         Time Series Summary          ║" -ForegroundColor Cyan
        Write-Host "╠══════════════════════════════════════╣" -ForegroundColor Cyan
        Write-Host ("║  Name      : {0,-24}║" -f $this.Name)           -ForegroundColor White
        Write-Host ("║  Points    : {0,-24}║" -f $this.Values.Length)  -ForegroundColor White
        Write-Host ("║  Start     : {0,-24}║" -f $this.Timestamps[0].ToString("yyyy-MM-dd"))  -ForegroundColor White
        Write-Host ("║  End       : {0,-24}║" -f $this.Timestamps[-1].ToString("yyyy-MM-dd")) -ForegroundColor White
        $min  = ($this.Values | Measure-Object -Minimum).Minimum
        $max  = ($this.Values | Measure-Object -Maximum).Maximum
        $mean = ($this.Values | Measure-Object -Average).Average
        Write-Host ("║  Min       : {0,-24}║" -f [Math]::Round($min,  2)) -ForegroundColor White
        Write-Host ("║  Max       : {0,-24}║" -f [Math]::Round($max,  2)) -ForegroundColor White
        Write-Host ("║  Mean      : {0,-24}║" -f [Math]::Round($mean, 2)) -ForegroundColor White
        Write-Host "╚══════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
    }

    # ASCII sparkline visualization
    [void] Plot([int]$width) {
        $n    = $this.Values.Length
        $step = [Math]::Max(1, [int]($n / $width))
        $min  = ($this.Values | Measure-Object -Minimum).Minimum
        $max  = ($this.Values | Measure-Object -Maximum).Maximum
        $range = [Math]::Max($max - $min, 1e-8)
        $bars  = "▁▂▃▄▅▆▇█"

        Write-Host ""
        Write-Host ("📈 {0}" -f $this.Name) -ForegroundColor Green
        Write-Host ("   [{0:yyyy-MM-dd} → {1:yyyy-MM-dd}]" -f $this.Timestamps[0], $this.Timestamps[-1]) -ForegroundColor DarkGray

        $line = "   "
        for ($i = 0; $i -lt $n; $i += $step) {
            $normalized = ($this.Values[$i] - $min) / $range
            $barIdx     = [int]($normalized * 7)
            $barIdx     = [Math]::Max(0, [Math]::Min(7, $barIdx))
            $line      += $bars[$barIdx]
        }
        Write-Host $line -ForegroundColor Cyan
        Write-Host ("   min={0:F1}  max={1:F1}  mean={2:F1}" -f $min, $max,
            ($this.Values | Measure-Object -Average).Average) -ForegroundColor DarkGray
        Write-Host ""
    }

    [void] Plot() { $this.Plot(60) }
}

# ============================================================
# DATETIME PARSING
# ============================================================
# TEACHING NOTE: Real data has dates in many formats:
#   "2024-01-15"  ISO format (best!)
#   "15/01/2024"  European
#   "01/15/2024"  American
#   "Jan 15 2024" Text format
# Always standardise to ISO format internally.
# ============================================================

function ConvertTo-VBAFDateTime {
    param([string[]]$dateStrings, [string]$Format = "auto")

    $formats = @(
        "yyyy-MM-dd", "yyyy/MM/dd", "dd-MM-yyyy", "dd/MM/yyyy",
        "MM/dd/yyyy", "MM-dd-yyyy", "yyyy-MM-dd HH:mm:ss",
        "dd MMM yyyy", "MMM dd yyyy", "yyyyMMdd"
    )

    $results = @()
    foreach ($ds in $dateStrings) {
        $parsed = $null
        if ($Format -ne "auto") {
            $dt = [datetime]::MinValue
            if ([datetime]::TryParseExact($ds.Trim(), $Format,
                [System.Globalization.CultureInfo]::InvariantCulture,
                [System.Globalization.DateTimeStyles]::None, [ref]$dt)) {
                $parsed = $dt
            }
        } else {
            foreach ($fmt in $formats) {
                $dt = [datetime]::MinValue
                if ([datetime]::TryParseExact($ds.Trim(), $fmt,
                    [System.Globalization.CultureInfo]::InvariantCulture,
                    [System.Globalization.DateTimeStyles]::None, [ref]$dt)) {
                    $parsed = $dt
                    break
                }
            }
        }
        if ($null -eq $parsed) {
            Write-Host "⚠️  Could not parse date: '$ds'" -ForegroundColor Yellow
            $results += [datetime]::MinValue
        } else {
            $results += $parsed
        }
    }
    return $results
}

# Extract datetime features as ML-ready numeric columns
function Get-DatetimeFeatures {
    param([datetime[]]$timestamps)

    # TEACHING: Calendar features are VERY useful for ML!
    # The model can learn: "sales spike every Friday"
    # or "temperature drops every January"

    $features = @()
    foreach ($dt in $timestamps) {
        $features += @{
            Year        = $dt.Year
            Month       = $dt.Month
            Day         = $dt.Day
            DayOfWeek   = [int]$dt.DayOfWeek   # 0=Sunday, 6=Saturday
            DayOfYear   = $dt.DayOfYear
            WeekOfYear  = [System.Globalization.CultureInfo]::CurrentCulture.Calendar.GetWeekOfYear(
                          $dt, [System.Globalization.CalendarWeekRule]::FirstDay,
                          [System.DayOfWeek]::Monday)
            Quarter     = [int](($dt.Month - 1) / 3) + 1
            IsWeekend   = if ($dt.DayOfWeek -eq "Saturday" -or $dt.DayOfWeek -eq "Sunday") { 1.0 } else { 0.0 }
            # Cyclical encoding: sin/cos transforms preserve circular nature
            # e.g. month 12 and month 1 are CLOSE, not far apart!
            MonthSin    = [Math]::Round([Math]::Sin(2 * [Math]::PI * $dt.Month / 12), 4)
            MonthCos    = [Math]::Round([Math]::Cos(2 * [Math]::PI * $dt.Month / 12), 4)
            DowSin      = [Math]::Round([Math]::Sin(2 * [Math]::PI * [int]$dt.DayOfWeek / 7), 4)
            DowCos      = [Math]::Round([Math]::Cos(2 * [Math]::PI * [int]$dt.DayOfWeek / 7), 4)
        }
    }
    return $features
}

# ============================================================
# LAG FEATURES
# ============================================================
# TEACHING NOTE: The most powerful time series feature!
# "What was the value 1 day ago? 7 days ago? 30 days ago?"
# These become features for predicting TODAY's value.
#
# Example with lag=1,2,7:
#   Date        Value  Lag1  Lag2  Lag7
#   2024-01-08   105   103   101    98
#   2024-01-09   107   105   103   100
#
# The model learns: "today ~ yesterday + last week"
# ============================================================

function Add-LagFeatures {
    param(
        [TimeSeries] $Series,
        [int[]]      $Lags = @(1, 2, 7)
    )

    $n      = $Series.Length()
    $result = @()

    for ($i = 0; $i -lt $n; $i++) {
        $row = @{
            Timestamp = $Series.Timestamps[$i]
            Value     = $Series.Values[$i]
        }
        foreach ($lag in $Lags) {
            $lagVal = if ($i -ge $lag) { $Series.Values[$i - $lag] } else { [double]::NaN }
            $row["Lag$lag"] = $lagVal
        }
        $result += $row
    }

    Write-Host "🔁 Lag features added: {$($Lags -join ', ')}" -ForegroundColor Green
    Write-Host ("   Valid rows (no NaN): {0}/{1}" -f ($n - ($Lags | Measure-Object -Maximum).Maximum), $n) -ForegroundColor Cyan
    return $result
}

# ============================================================
# ROLLING WINDOW STATISTICS
# ============================================================
# TEACHING NOTE: A rolling window computes statistics over
# the last N observations.
#
# Rolling mean (window=7):
#   smooths out noise, reveals the trend
#   "average of last 7 days"
#
# Rolling std:
#   measures volatility/uncertainty
#   "how much did the last 7 days vary?"
#
# Rolling min/max:
#   "what was the worst/best of the last 7 days?"
# ============================================================

function Add-RollingFeatures {
    param(
        [TimeSeries] $Series,
        [int[]]      $Windows  = @(7, 14, 30),
        [string[]]   $Stats    = @("mean", "std", "min", "max")
    )

    $n      = $Series.Length()
    $result = @()

    for ($i = 0; $i -lt $n; $i++) {
        $row = @{
            Timestamp = $Series.Timestamps[$i]
            Value     = $Series.Values[$i]
        }

        foreach ($w in $Windows) {
            $startIdx = [Math]::Max(0, $i - $w + 1)
            $window   = $Series.Values[$startIdx..$i]

            foreach ($stat in $Stats) {
                $colName = "Roll${w}_${stat}"
                $val     = switch ($stat) {
                    "mean" { ($window | Measure-Object -Average).Average }
                    "std"  {
                        $mu    = ($window | Measure-Object -Average).Average
                        $sumSq = 0.0
                        foreach ($v in $window) { $sumSq += ($v - $mu) * ($v - $mu) }
                        if ($window.Length -gt 1) { [Math]::Sqrt($sumSq / ($window.Length-1)) } else { 0.0 }
                    }
                    "min"  { ($window | Measure-Object -Minimum).Minimum }
                    "max"  { ($window | Measure-Object -Maximum).Maximum }
                    "sum"  { ($window | Measure-Object -Sum).Sum }
                }
                $row[$colName] = [Math]::Round($val, 4)
            }
        }
        $result += $row
    }

    Write-Host "🪟 Rolling features added:" -ForegroundColor Green
    foreach ($w in $Windows) {
        Write-Host ("   Window {0,2}: {1}" -f $w, ($Stats -join ", ")) -ForegroundColor Cyan
    }
    return $result
}

# ============================================================
# SEASONAL DECOMPOSITION
# ============================================================
# TEACHING NOTE: Any time series can be decomposed into:
#   Value = Trend + Seasonal + Residual
#
#   Trend    : the long-term direction (linear or smooth)
#   Seasonal : repeating pattern with fixed period
#              (period=7 for weekly, period=12 for monthly)
#   Residual : what's left after removing trend and seasonal
#              (noise, anomalies, unexplained variation)
#
# We use a simple approach:
#   Trend    = centered moving average (window=period)
#   Seasonal = average deviation from trend per period position
#   Residual = Value - Trend - Seasonal
# ============================================================

function Invoke-SeasonalDecomposition {
    param(
        [TimeSeries] $Series,
        [int]        $Period = 7    # 7=weekly, 12=monthly, 4=quarterly
    )

    $n      = $Series.Length()
    $values = $Series.Values

    # Step 1: Trend via centered moving average
    $trend = @([double]::NaN) * $n
    $half  = [int]($Period / 2)
    for ($i = $half; $i -lt ($n - $half); $i++) {
        $window    = $values[($i - $half)..($i + $half)]
        $trend[$i] = ($window | Measure-Object -Average).Average
    }

    # Step 2: Detrended = Value - Trend
    $detrended = @(0.0) * $n
    for ($i = 0; $i -lt $n; $i++) {
        $detrended[$i] = if ([double]::IsNaN($trend[$i])) { 0.0 } else { $values[$i] - $trend[$i] }
    }

    # Step 3: Seasonal = average detrended value per period position
    $seasonal = @(0.0) * $n
    for ($p = 0; $p -lt $Period; $p++) {
        $periodVals = @()
        for ($i = $p; $i -lt $n; $i += $Period) {
            if (-not [double]::IsNaN($trend[$i])) { $periodVals += $detrended[$i] }
        }
        $avgSeasonal = if ($periodVals.Length -gt 0) {
            ($periodVals | Measure-Object -Average).Average
        } else { 0.0 }

        for ($i = $p; $i -lt $n; $i += $Period) {
            $seasonal[$i] = $avgSeasonal
        }
    }

    # Step 4: Residual = Value - Trend - Seasonal
    $residual = @(0.0) * $n
    for ($i = 0; $i -lt $n; $i++) {
        $t = if ([double]::IsNaN($trend[$i])) { 0.0 } else { $trend[$i] }
        $residual[$i] = $values[$i] - $t - $seasonal[$i]
    }

    # Print decomposition summary
    $seasonalAmp = ($seasonal | Measure-Object -Maximum).Maximum - ($seasonal | Measure-Object -Minimum).Minimum
    $residualStd = 0.0
    $resMean     = ($residual | Measure-Object -Average).Average
    foreach ($r in $residual) { $residualStd += ($r - $resMean) * ($r - $resMean) }
    $residualStd = [Math]::Sqrt($residualStd / $n)

    Write-Host ""
    Write-Host "🔬 Seasonal Decomposition" -ForegroundColor Green
    Write-Host ("   Period          : {0}" -f $Period)                           -ForegroundColor Cyan
    Write-Host ("   Seasonal ampl.  : {0:F2}" -f $seasonalAmp)                  -ForegroundColor White
    Write-Host ("   Residual std    : {0:F2}" -f $residualStd)                   -ForegroundColor White

    # Plot each component
    $trendTS    = [TimeSeries]::new($Series.Timestamps, [double[]]($trend    | ForEach-Object { if ([double]::IsNaN($_)) { 0.0 } else { $_ } }), "Trend")
    $seasonalTS = [TimeSeries]::new($Series.Timestamps, [double[]]$seasonal, "Seasonal")
    $residualTS = [TimeSeries]::new($Series.Timestamps, [double[]]$residual, "Residual")

    $trendTS.Plot(50)
    $seasonalTS.Plot(50)
    $residualTS.Plot(50)

    return @{
        Trend    = $trend
        Seasonal = $seasonal
        Residual = $residual
        Period   = $Period
    }
}

# ============================================================
# RESAMPLING
# ============================================================
# TEACHING NOTE: Resampling changes the frequency of data.
# Downsampling: daily -> weekly -> monthly (aggregate)
# Upsampling  : monthly -> daily (interpolate - not covered here)
#
# When aggregating, choose the right statistic:
#   Sales    -> SUM   (total sold per week)
#   Price    -> MEAN  (average price per week)
#   Rainfall -> SUM   (total rain per week)
#   Temp     -> MEAN  (average temp per week)
# ============================================================

function Invoke-TimeSeriesResample {
    param(
        [TimeSeries] $Series,
        [string]     $Frequency = "weekly",   # "weekly", "monthly", "quarterly"
        [string]     $Aggregation = "mean"    # "mean", "sum", "min", "max", "last"
    )

    $n       = $Series.Length()
    $buckets = @{}

    for ($i = 0; $i -lt $n; $i++) {
        $dt  = $Series.Timestamps[$i]
        $key = switch ($Frequency) {
            "weekly"    { "{0}-W{1:D2}" -f $dt.Year,
                          [System.Globalization.CultureInfo]::CurrentCulture.Calendar.GetWeekOfYear(
                          $dt, [System.Globalization.CalendarWeekRule]::FirstDay, [System.DayOfWeek]::Monday) }
            "monthly"   { "{0}-{1:D2}" -f $dt.Year, $dt.Month }
            "quarterly" { "{0}-Q{1}"   -f $dt.Year, ([int](($dt.Month-1)/3)+1) }
            default     { "{0}-{1:D2}" -f $dt.Year, $dt.Month }
        }

        if (-not $buckets.ContainsKey($key)) {
            $buckets[$key] = @{ Values=@(); FirstDate=$dt }
        }
        $buckets[$key].Values += $Series.Values[$i]
    }

    # Aggregate each bucket
    $newTimestamps = @()
    $newValues     = @()

    foreach ($key in ($buckets.Keys | Sort-Object)) {
        $bucket = $buckets[$key]
        $agg    = switch ($Aggregation) {
            "mean" { ($bucket.Values | Measure-Object -Average).Average }
            "sum"  { ($bucket.Values | Measure-Object -Sum).Sum }
            "min"  { ($bucket.Values | Measure-Object -Minimum).Minimum }
            "max"  { ($bucket.Values | Measure-Object -Maximum).Maximum }
            "last" { $bucket.Values[-1] }
        }
        $newTimestamps += $bucket.FirstDate
        $newValues     += [Math]::Round($agg, 4)
    }

    $resampled = [TimeSeries]::new($newTimestamps, $newValues, "$($Series.Name)_$Frequency")
    $resampled.Frequency = $Frequency

    Write-Host "📅 Resampled: $($Series.Name) -> $Frequency ($Aggregation)" -ForegroundColor Green
    Write-Host ("   Before: {0} points" -f $n)                             -ForegroundColor Cyan
    Write-Host ("   After : {0} points" -f $resampled.Length())            -ForegroundColor Cyan
    return $resampled
}

# ============================================================
# BUILT-IN DATASETS
# ============================================================

function Get-VBAFTimeSeriesDataset {
    param([string]$Name = "Sales")

    $rng = [System.Random]::new(42)

    switch ($Name) {
        "Sales" {
            Write-Host "📊 Dataset: Daily Sales (365 days)" -ForegroundColor Cyan
            Write-Host "   Has: weekly seasonality, upward trend, noise" -ForegroundColor Cyan

            $timestamps = @()
            $values     = @()
            $start      = [datetime]"2023-01-01"

            for ($d = 0; $d -lt 365; $d++) {
                $dt   = $start.AddDays($d)
                # Trend: slowly increasing sales
                $trend    = 100 + $d * 0.1
                # Weekly seasonality: weekends are lower
                $dow      = [int]$dt.DayOfWeek
                $seasonal = if ($dow -eq 0 -or $dow -eq 6) { -20 } else { 10 + $dow * 2 }
                # Monthly bump in December
                $monthly  = if ($dt.Month -eq 12) { 30 } else { 0 }
                # Noise
                $noise    = ($rng.NextDouble() - 0.5) * 20
                $val      = [Math]::Max(0, $trend + $seasonal + $monthly + $noise)
                $timestamps += $dt
                $values     += [Math]::Round($val, 1)
            }
            return [TimeSeries]::new($timestamps, $values, "DailySales")
        }
        "Temperature" {
            Write-Host "📊 Dataset: Daily Temperature (2 years)" -ForegroundColor Cyan
            Write-Host "   Has: annual seasonality, random weather noise" -ForegroundColor Cyan

            $timestamps = @()
            $values     = @()
            $start      = [datetime]"2022-01-01"

            for ($d = 0; $d -lt 730; $d++) {
                $dt       = $start.AddDays($d)
                # Annual cycle: cold in winter, warm in summer (Denmark!)
                $seasonal = -15 * [Math]::Cos(2 * [Math]::PI * $dt.DayOfYear / 365)
                $baseline = 10  # mean annual temp
                $noise    = ($rng.NextDouble() - 0.5) * 8
                $val      = $baseline + $seasonal + $noise
                $timestamps += $dt
                $values     += [Math]::Round($val, 1)
            }
            return [TimeSeries]::new($timestamps, $values, "DailyTemperature")
        }
        default {
            Write-Host "❌ Unknown dataset: $Name" -ForegroundColor Red
            Write-Host "   Available: Sales, Temperature" -ForegroundColor Yellow
            return $null
        }
    }
}

# ============================================================
# TEST
# 1. Run VBAF.LoadAll.ps1
#
# --- Basic time series ---
# 2. $ts = Get-VBAFTimeSeriesDataset -Name "Sales"
#    $ts.PrintSummary()
#    $ts.Plot()
#
# --- Datetime features ---
# 3. $dtFeatures = Get-DatetimeFeatures -timestamps $ts.Timestamps
#    $dtFeatures[0]   # see all features for first day
#
# --- Lag features ---
# 4. $lagged = Add-LagFeatures -Series $ts -Lags @(1, 7, 14)
#    $lagged[14]  # first row with all lags valid
#
# --- Rolling windows ---
# 5. $rolled = Add-RollingFeatures -Series $ts -Windows @(7, 30) -Stats @("mean","std")
#    $rolled[30]  # see rolling features
#
# --- Seasonal decomposition ---
# 6. $decomp = Invoke-SeasonalDecomposition -Series $ts -Period 7
#    Write-Host "Trend range: $([Math]::Round(($decomp.Trend | Where-Object {-not [double]::IsNaN($_)} | Measure-Object -Minimum).Minimum,1)) to $([Math]::Round(($decomp.Trend | Where-Object {-not [double]::IsNaN($_)} | Measure-Object -Maximum).Maximum,1))"
#
# --- Resampling ---
# 7. $weekly  = Invoke-TimeSeriesResample -Series $ts -Frequency "weekly"  -Aggregation "sum"
#    $monthly = Invoke-TimeSeriesResample -Series $ts -Frequency "monthly" -Aggregation "mean"
#    $weekly.Plot()
#    $monthly.Plot()
#
# --- Temperature dataset ---
# 8. $temp   = Get-VBAFTimeSeriesDataset -Name "Temperature"
#    $decomp2 = Invoke-SeasonalDecomposition -Series $temp -Period 365
#    $annual  = Invoke-TimeSeriesResample -Series $temp -Frequency "monthly" -Aggregation "mean"
#    $annual.Plot()
# ============================================================
Write-Host "📦 VBAF.ML.TimeSeries.ps1 loaded" -ForegroundColor Green
Write-Host "   Classes   : TimeSeries"                        -ForegroundColor Cyan
Write-Host "   Functions : ConvertTo-VBAFDateTime"            -ForegroundColor Cyan
Write-Host "              Get-DatetimeFeatures"               -ForegroundColor Cyan
Write-Host "              Add-LagFeatures"                    -ForegroundColor Cyan
Write-Host "              Add-RollingFeatures"                -ForegroundColor Cyan
Write-Host "              Invoke-SeasonalDecomposition"       -ForegroundColor Cyan
Write-Host "              Invoke-TimeSeriesResample"          -ForegroundColor Cyan
Write-Host "              Get-VBAFTimeSeriesDataset"          -ForegroundColor Cyan
Write-Host ""
Write-Host "   Quick start:" -ForegroundColor Yellow
Write-Host '   $ts = Get-VBAFTimeSeriesDataset -Name "Sales"' -ForegroundColor White
Write-Host '   $ts.PrintSummary()'                            -ForegroundColor White
Write-Host '   $ts.Plot()'                                    -ForegroundColor White
Write-Host ""