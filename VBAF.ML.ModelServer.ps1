#Requires -Version 5.1
<#
.SYNOPSIS
    Model Server - Serve VBAF models via HTTP REST API
.DESCRIPTION
    Implements model serving from scratch using .NET HttpListener.
    Designed as a TEACHING resource - every step explained.
    Features included:
      - REST API wrapper    : serve any VBAF model over HTTP
      - Batch prediction    : send multiple inputs, get multiple outputs
      - Real-time inference : single prediction with latency tracking
      - Model monitoring    : log predictions, latency, errors
      - A/B testing         : split traffic between two model versions
    No external dependencies - uses built-in .NET HttpListener!
.NOTES
    Part of VBAF - Phase 7 Production Features - v2.1.0
    PS 5.1 compatible
    Teaching project - MLOps serving concepts explained!

    ENDPOINTS (default port 8080):
      GET  /health              - server health check
      GET  /info                - model info and stats
      POST /predict             - single prediction
      POST /predict/batch       - batch predictions
      GET  /metrics             - monitoring metrics
      GET  /ab/stats            - A/B test statistics
#>

# ============================================================
# TEACHING NOTE: What is model serving?
# Training is offline - you train once, save the model.
# Serving is online  - you expose the model as an API so
# applications can call it in real time!
#
# REST API pattern:
#   Client sends: POST /predict {"features": [120, 3, 5]}
#   Server returns: {"prediction": 245.3, "latency_ms": 2.1}
#
# Key concepts:
#   Latency    : how fast is each prediction? (ms)
#   Throughput : how many predictions per second?
#   Monitoring : are predictions drifting? Any errors?
#   A/B testing: which model version performs better in prod?
# ============================================================

# ============================================================
# SERVER STATE (script-scope so it persists)
# ============================================================
$script:ServerRunning  = $false
$script:ServerJob      = $null
$script:MonitoringLog  = [System.Collections.ArrayList]::new()
$script:ABLog          = [System.Collections.ArrayList]::new()

# ============================================================
# PREDICTION ENGINE
# ============================================================
# TEACHING NOTE: The prediction engine wraps any VBAF model.
# It handles the conversion from JSON input -> model input -> JSON output.
# ============================================================

function Invoke-VBAFPrediction {
    param(
        [object]   $Model,
        [string]   $ModelType,
        [double[]] $Features,
        [object]   $Scaler = $null
    )

    $start = [System.Diagnostics.Stopwatch]::StartNew()

    # Scale features if scaler provided
    $input = $Features
    if ($null -ne $Scaler) {
        $input = $Scaler.Transform(@(,$Features))
        $input = $input[0]
    }

    $prediction = switch ($ModelType) {
        "LinearRegression"  { $Model.Predict(@(,$input))[0] }
        "RidgeRegression"   { $Model.Predict(@(,$input))[0] }
        "LassoRegression"   { $Model.Predict(@(,$input))[0] }
        "LogisticRegression"{ $Model.Predict(@(,$input))[0] }
        "DecisionTree"      { $Model.Predict(@(,$input))[0] }
        "RandomForest"      { $Model.Predict(@(,$input))[0] }
        "GaussianNaiveBayes"{ $Model.Predict(@(,$input))[0] }
        "KMeans"            { $Model.Predict(@(,$input))[0] }
        default             { $Model.Predict(@(,$input))[0] }
    }

    $start.Stop()
    return @{
        Prediction = $prediction
        LatencyMs  = [Math]::Round($start.Elapsed.TotalMilliseconds, 3)
    }
}

function Invoke-VBAFBatchPrediction {
    param(
        [object]     $Model,
        [string]     $ModelType,
        [double[][]] $FeatureMatrix,
        [object]     $Scaler = $null
    )

    $start   = [System.Diagnostics.Stopwatch]::StartNew()
    $results = @()

    foreach ($features in $FeatureMatrix) {
        $input = $features
        if ($null -ne $Scaler) {
            $scaled = $Scaler.Transform(@(,([double[]]$features)))
            $input  = [double[]]$scaled[0]
        }
        $pred    = $Model.Predict(@(,$input))[0]
        $results += $pred
    }

    $start.Stop()
    return @{
        Predictions = $results
        Count       = $results.Length
        LatencyMs   = [Math]::Round($start.Elapsed.TotalMilliseconds, 3)
        AvgLatencyMs= [Math]::Round($start.Elapsed.TotalMilliseconds / [Math]::Max(1,$results.Length), 3)
    }
}

# ============================================================
# MONITORING
# ============================================================
# TEACHING NOTE: Monitoring in production means tracking:
#   - Prediction distribution: is the model returning unusual values?
#   - Latency: is inference getting slower over time?
#   - Error rate: how many requests are failing?
#   - Input drift: are incoming features different from training data?
# ============================================================

function Write-VBAFMonitoringLog {
    param(
        [string] $ModelName,
        [string] $ModelVersion,
        [string] $Endpoint,
        [double] $LatencyMs,
        [object] $Prediction,
        [bool]   $IsError = $false
    )
    $entry = @{
        Timestamp    = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss.fff")
        ModelName    = $ModelName
        ModelVersion = $ModelVersion
        Endpoint     = $Endpoint
        LatencyMs    = $LatencyMs
        Prediction   = $Prediction
        IsError      = $IsError
    }
    $script:MonitoringLog.Add($entry) | Out-Null
}

function Get-VBAFMonitoringStats {
    param([string]$ModelName = "", [int]$LastN = 100)

    $log = $script:MonitoringLog
    if ($ModelName -ne "") { $log = $log | Where-Object { $_.ModelName -eq $ModelName } }
    if ($log.Count -eq 0) {
        Write-Host "📊 No monitoring data yet" -ForegroundColor Yellow
        return
    }

    $recent    = @($log | Select-Object -Last $LastN)
    $errors    = @($recent | Where-Object { $_.IsError }).Count
    $latencies = $recent | ForEach-Object { $_.LatencyMs }
    $avgLat    = [Math]::Round(($latencies | Measure-Object -Average).Average, 2)
    $maxLat    = [Math]::Round(($latencies | Measure-Object -Maximum).Maximum, 2)
    $preds     = $recent | Where-Object { -not $_.IsError } | ForEach-Object { [double]$_.Prediction }

    Write-Host ""
    Write-Host "📊 Monitoring Stats" -ForegroundColor Green
    if ($ModelName -ne "") { Write-Host ("   Model    : {0}" -f $ModelName) -ForegroundColor Cyan }
    Write-Host ("   Requests : {0}  (last {1})" -f $recent.Count, $LastN) -ForegroundColor White
    Write-Host ("   Errors   : {0}  ({1:F1}%)" -f $errors, (100.0*$errors/$recent.Count)) -ForegroundColor $(if ($errors -gt 0) {"Red"} else {"Green"})
    Write-Host ("   Latency  : avg={0}ms  max={1}ms" -f $avgLat, $maxLat) -ForegroundColor White
    if ($preds.Count -gt 0) {
        $avgPred = [Math]::Round(($preds | Measure-Object -Average).Average, 4)
        $minPred = [Math]::Round(($preds | Measure-Object -Minimum).Minimum, 4)
        $maxPred = [Math]::Round(($preds | Measure-Object -Maximum).Maximum, 4)
        Write-Host ("   Preds    : avg={0}  min={1}  max={2}" -f $avgPred, $minPred, $maxPred) -ForegroundColor White
    }
    Write-Host ""
}

function Export-VBAFMonitoringLog {
    param([string]$Path = ".\vbaf_monitoring.csv")
    if ($script:MonitoringLog.Count -eq 0) {
        Write-Host "No monitoring data to export" -ForegroundColor Yellow
        return
    }
    $lines = @("Timestamp,ModelName,ModelVersion,Endpoint,LatencyMs,Prediction,IsError")
    foreach ($e in $script:MonitoringLog) {
        $lines += '"{0}","{1}","{2}","{3}",{4},{5},{6}' -f `
            $e.Timestamp, $e.ModelName, $e.ModelVersion, $e.Endpoint, $e.LatencyMs, $e.Prediction, $e.IsError
    }
    $lines | Set-Content $Path -Encoding UTF8
    Write-Host ("📄 Monitoring log exported: {0} ({1} rows)" -f $Path, $script:MonitoringLog.Count) -ForegroundColor Green
}

# ============================================================
# A/B TESTING FRAMEWORK
# ============================================================
# TEACHING NOTE: A/B testing in ML means:
#   - Model A (control)   : current production model
#   - Model B (treatment) : new candidate model
#   - Split traffic 50/50 (or configurable)
#   - Compare predictions and latency
#   - Decide which model to promote to 100% traffic
#
# Example: HousePricePredictor v1.0 vs v1.1
#   After 1000 requests: v1.1 has lower RMSE -> promote!
# ============================================================

$script:ABConfig = $null

function Start-VBAFABTest {
    param(
        [string] $TestName,
        [object] $ModelA,
        [string] $ModelAName,
        [string] $ModelAVersion,
        [string] $ModelAType,
        [object] $ModelB,
        [string] $ModelBName,
        [string] $ModelBVersion,
        [string] $ModelBType,
        [double] $TrafficSplitA = 0.5,   # fraction sent to A (0.5 = 50/50)
        [object] $ScalerA = $null,
        [object] $ScalerB = $null
    )

    $script:ABConfig = @{
        TestName      = $TestName
        Started       = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        ModelA        = $ModelA
        ModelAName    = $ModelAName
        ModelAVersion = $ModelAVersion
        ModelAType    = $ModelAType
        ModelB        = $ModelB
        ModelBName    = $ModelBName
        ModelBVersion = $ModelBVersion
        ModelBType    = $ModelBType
        TrafficSplitA = $TrafficSplitA
        ScalerA       = $ScalerA
        ScalerB       = $ScalerB
        Rng           = [System.Random]::new(42)
        StatsA        = @{ Count=0; TotalLatency=0.0; Predictions=@() }
        StatsB        = @{ Count=0; TotalLatency=0.0; Predictions=@() }
    }
    $script:ABLog.Clear()

    Write-Host ""
    Write-Host ("🧪 A/B Test started: {0}" -f $TestName) -ForegroundColor Green
    Write-Host ("   Model A : {0} v{1} ({2:P0} traffic)" -f $ModelAName, $ModelAVersion, $TrafficSplitA) -ForegroundColor Cyan
    Write-Host ("   Model B : {0} v{1} ({2:P0} traffic)" -f $ModelBName, $ModelBVersion, (1-$TrafficSplitA)) -ForegroundColor Yellow
    Write-Host ""
}

function Invoke-VBAFABPredict {
    param([double[]]$Features)

    if ($null -eq $script:ABConfig) {
        Write-Host "❌ No A/B test running. Call Start-VBAFABTest first." -ForegroundColor Red
        return $null
    }

    $cfg   = $script:ABConfig
    $useA  = $cfg.Rng.NextDouble() -lt $cfg.TrafficSplitA
    $model = if ($useA) { $cfg.ModelA }    else { $cfg.ModelB }
    $type  = if ($useA) { $cfg.ModelAType } else { $cfg.ModelBType }
    $scaler= if ($useA) { $cfg.ScalerA }   else { $cfg.ScalerB }
    $name  = if ($useA) { "A" }            else { "B" }

    $result = Invoke-VBAFPrediction -Model $model -ModelType $type -Features $Features -Scaler $scaler

    # Log
    $stats = if ($useA) { $cfg.StatsA } else { $cfg.StatsB }
    $stats.Count++
    $stats.TotalLatency += $result.LatencyMs
    $stats.Predictions  += $result.Prediction

    $logEntry = @{
        Timestamp  = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss.fff")
        Model      = $name
        Prediction = $result.Prediction
        LatencyMs  = $result.LatencyMs
    }
    $script:ABLog.Add($logEntry) | Out-Null

    return @{
        Model      = $name
        Prediction = $result.Prediction
        LatencyMs  = $result.LatencyMs
    }
}

function Get-VBAFABStats {
    if ($null -eq $script:ABConfig) {
        Write-Host "❌ No A/B test running" -ForegroundColor Red
        return
    }

    $cfg = $script:ABConfig
    $sA  = $cfg.StatsA
    $sB  = $cfg.StatsB

    Write-Host ""
    Write-Host ("🧪 A/B Test Results: {0}" -f $cfg.TestName) -ForegroundColor Green
    Write-Host ("   Started : {0}" -f $cfg.Started) -ForegroundColor DarkGray
    Write-Host ""
    Write-Host ("   {0,-12} {1,8} {2,12} {3,12} {4,12}" -f "Model","Requests","Avg Latency","Avg Pred","StdDev Pred") -ForegroundColor Yellow
    Write-Host ("   {0}" -f ("-" * 60)) -ForegroundColor DarkGray

    foreach ($nm in @("A","B")) {
        $s     = if ($nm -eq "A") { $sA } else { $sB }
        $mName = if ($nm -eq "A") { "$($cfg.ModelAName) v$($cfg.ModelAVersion)" } else { "$($cfg.ModelBName) v$($cfg.ModelBVersion)" }
        if ($s.Count -eq 0) {
            Write-Host ("   {0,-12} {1,8}" -f "Model $nm", 0) -ForegroundColor DarkGray
            continue
        }
        $avgLat  = [Math]::Round($s.TotalLatency / $s.Count, 3)
        $preds   = $s.Predictions
        $avgPred = [Math]::Round(($preds | Measure-Object -Average).Average, 4)
        $mean    = ($preds | Measure-Object -Average).Average
        $stdDev  = [Math]::Round([Math]::Sqrt((($preds | ForEach-Object { ($_ - $mean)*($_ - $mean) } | Measure-Object -Sum).Sum / $preds.Count)), 4)
        $color   = if ($nm -eq "A") { "Cyan" } else { "Yellow" }
        $shortName = if ($mName.Length -gt 12) { $mName.Substring(0,12) } else { $mName }
        Write-Host ("   {0,-12} {1,8} {2,11}ms {3,12} {4,12}" -f "Model $nm ($shortName)", $s.Count, $avgLat, $avgPred, $stdDev) -ForegroundColor $color
    }

    # Recommendation
    Write-Host ""
    if ($sA.Count -gt 0 -and $sB.Count -gt 0) {
        $latA = $sA.TotalLatency / $sA.Count
        $latB = $sB.TotalLatency / $sB.Count
        $winner = if ($latB -lt $latA) { "B ($($cfg.ModelBName) v$($cfg.ModelBVersion))" } else { "A ($($cfg.ModelAName) v$($cfg.ModelAVersion))" }
        Write-Host ("   💡 Faster model: {0}" -f $winner) -ForegroundColor Green
    }
    Write-Host ""
}

function Stop-VBAFABTest {
    if ($null -eq $script:ABConfig) { Write-Host "No A/B test running" -ForegroundColor Yellow; return }
    $name = $script:ABConfig.TestName
    Get-VBAFABStats
    $script:ABConfig = $null
    Write-Host ("🛑 A/B Test stopped: {0}" -f $name) -ForegroundColor Yellow
}

# ============================================================
# HTTP SERVER (runs in background job)
# ============================================================
# TEACHING NOTE: HttpListener is a built-in .NET class that
# listens for HTTP requests on a port. It's not as fast as
# nginx or IIS, but it works in pure PS 5.1!
#
# Request flow:
#   1. Client sends HTTP POST to http://localhost:8080/predict
#   2. HttpListener receives the request
#   3. We parse the JSON body
#   4. Call the model's Predict method
#   5. Return JSON response with prediction + latency
# ============================================================

function Start-VBAFModelServer {
    param(
        [object] $Model,
        [string] $ModelName,
        [string] $ModelVersion = "1.0.0",
        [string] $ModelType,
        [object] $Scaler     = $null,
        [int]    $Port       = 8080,
        [string] $Prefix     = ""
    )

    if ($script:ServerRunning) {
        Write-Host "⚠️  Server already running. Call Stop-VBAFModelServer first." -ForegroundColor Yellow
        return
    }

    $urlPrefix = if ($Prefix -ne "") { $Prefix } else { "http://localhost:$Port/" }

    # Serialize model for the background job
    $modelJson = @{
        ModelName    = $ModelName
        ModelVersion = $ModelVersion
        ModelType    = $ModelType
        Port         = $Port
        UrlPrefix    = $urlPrefix
    } | ConvertTo-Json

    Write-Host ""
    Write-Host ("🚀 Starting VBAF Model Server...") -ForegroundColor Green
    Write-Host ("   Model   : {0} v{1}" -f $ModelName, $ModelVersion) -ForegroundColor Cyan
    Write-Host ("   Type    : {0}" -f $ModelType)   -ForegroundColor Cyan
    Write-Host ("   URL     : {0}" -f $urlPrefix)   -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   Endpoints:" -ForegroundColor White
    Write-Host ("   GET  {0}health         - health check" -f $urlPrefix)   -ForegroundColor DarkGray
    Write-Host ("   GET  {0}info           - model info"   -f $urlPrefix)   -ForegroundColor DarkGray
    Write-Host ("   POST {0}predict        - single prediction" -f $urlPrefix) -ForegroundColor DarkGray
    Write-Host ("   POST {0}predict/batch  - batch predictions" -f $urlPrefix) -ForegroundColor DarkGray
    Write-Host ("   GET  {0}metrics        - monitoring metrics" -f $urlPrefix) -ForegroundColor DarkGray
    Write-Host ""

    # Store model reference in script scope for the sync server
    $script:ServedModel        = $Model
    $script:ServedModelName    = $ModelName
    $script:ServedModelVersion = $ModelVersion
    $script:ServedModelType    = $ModelType
    $script:ServedScaler       = $Scaler
    $script:ServedPort         = $Port
    $script:ServedPrefix       = $urlPrefix
    $script:ServerRunning      = $true
    $script:RequestCount       = 0

    Write-Host "✅ Server ready! Press Ctrl+C or call Stop-VBAFModelServer to stop." -ForegroundColor Green
    Write-Host "   (Server runs synchronously - open a new PS window to send requests)" -ForegroundColor DarkGray
    Write-Host ""

    # Start synchronous listener
    $listener = [System.Net.HttpListener]::new()
    $listener.Prefixes.Add($urlPrefix)

    try {
        $listener.Start()
        Write-Host "🟢 Listening on $urlPrefix" -ForegroundColor Green

        while ($script:ServerRunning) {
            # Non-blocking check with timeout
            $contextTask = $listener.GetContextAsync()
            $waited = 0
            while (-not $contextTask.IsCompleted -and $script:ServerRunning) {
                Start-Sleep -Milliseconds 100
                $waited += 100
                if ($waited -ge 30000) { break }  # 30s timeout, loop again
            }
            if (-not $contextTask.IsCompleted) { continue }

            $context  = $contextTask.Result
            $request  = $context.Request
            $response = $context.Response
            $script:RequestCount++

            $method = $request.HttpMethod
            $path   = $request.Url.AbsolutePath.ToLower().TrimEnd('/')

            $body = ""
            if ($request.HasEntityBody) {
                $reader = [System.IO.StreamReader]::new($request.InputStream)
                $body   = $reader.ReadToEnd()
                $reader.Close()
            }

            $responseBody = ""
            $statusCode   = 200

            try {
                if ($path -eq "/health" -or $path -eq "") {
                    $responseBody = (@{
                        status  = "healthy"
                        model   = $script:ServedModelName
                        version = $script:ServedModelVersion
                        requests= $script:RequestCount
                        uptime  = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                    } | ConvertTo-Json)

                } elseif ($path -eq "/info") {
                    $responseBody = (@{
                        model   = $script:ServedModelName
                        version = $script:ServedModelVersion
                        type    = $script:ServedModelType
                        port    = $script:ServedPort
                        endpoints = @("/health","/info","/predict","/predict/batch","/metrics")
                    } | ConvertTo-Json)

                } elseif ($path -eq "/predict" -and $method -eq "POST") {
                    $payload  = $body | ConvertFrom-Json
                    $features = [double[]]$payload.features
                    $result   = Invoke-VBAFPrediction -Model $script:ServedModel -ModelType $script:ServedModelType `
                                    -Features $features -Scaler $script:ServedScaler
                    Write-VBAFMonitoringLog -ModelName $script:ServedModelName -ModelVersion $script:ServedModelVersion `
                        -Endpoint "/predict" -LatencyMs $result.LatencyMs -Prediction $result.Prediction
                    $responseBody = (@{
                        model      = $script:ServedModelName
                        version    = $script:ServedModelVersion
                        prediction = $result.Prediction
                        latency_ms = $result.LatencyMs
                    } | ConvertTo-Json)

                } elseif ($path -eq "/predict/batch" -and $method -eq "POST") {
                    $payload = $body | ConvertFrom-Json
                    $matrix  = @()
                    foreach ($row in $payload.features) { $matrix += ,[double[]]$row }
                    $result  = Invoke-VBAFBatchPrediction -Model $script:ServedModel -ModelType $script:ServedModelType `
                                   -FeatureMatrix $matrix -Scaler $script:ServedScaler
                    $responseBody = (@{
                        model          = $script:ServedModelName
                        version        = $script:ServedModelVersion
                        predictions    = $result.Predictions
                        count          = $result.Count
                        latency_ms     = $result.LatencyMs
                        avg_latency_ms = $result.AvgLatencyMs
                    } | ConvertTo-Json)

                } elseif ($path -eq "/metrics") {
                    $log    = $script:MonitoringLog | Where-Object { $_.ModelName -eq $script:ServedModelName }
                    $errors = @($log | Where-Object { $_.IsError }).Count
                    $lats   = @($log | ForEach-Object { $_.LatencyMs })
                    $avgLat = if ($lats.Count -gt 0) { ($lats | Measure-Object -Average).Average } else { 0 }
                    $responseBody = (@{
                        model         = $script:ServedModelName
                        total_requests= $script:RequestCount
                        logged_preds  = $log.Count
                        error_count   = $errors
                        avg_latency_ms= [Math]::Round($avgLat, 3)
                    } | ConvertTo-Json)

                } else {
                    $statusCode   = 404
                    $responseBody = (@{ error="Not found"; path=$path } | ConvertTo-Json)
                }

            } catch {
                $statusCode   = 500
                $responseBody = (@{ error=$_.Exception.Message } | ConvertTo-Json)
                Write-VBAFMonitoringLog -ModelName $script:ServedModelName -ModelVersion $script:ServedModelVersion `
                    -Endpoint $path -LatencyMs 0 -Prediction $null -IsError $true
            }

            $bytes = [System.Text.Encoding]::UTF8.GetBytes($responseBody)
            $response.StatusCode        = $statusCode
            $response.ContentType       = "application/json"
            $response.ContentLength64   = $bytes.Length
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
            $response.OutputStream.Close()

            Write-Host ("{0}  {1,-6} {2,-25} {3}" -f (Get-Date).ToString("HH:mm:ss"), $method, $path, $statusCode) -ForegroundColor DarkGray
        }
    } finally {
        $listener.Stop()
        $script:ServerRunning = $false
        Write-Host "🔴 Server stopped" -ForegroundColor Yellow
    }
}

function Stop-VBAFModelServer {
    $script:ServerRunning = $false
    Write-Host "🛑 Stop signal sent" -ForegroundColor Yellow
}

# ============================================================
# CLIENT HELPERS (call the server from PowerShell)
# ============================================================

function Invoke-VBAFServerPredict {
    param(
        [double[]] $Features,
        [int]      $Port = 8080
    )
    $body    = @{ features=$Features } | ConvertTo-Json
    $result  = Invoke-RestMethod -Uri "http://localhost:$Port/predict" -Method POST `
                   -Body $body -ContentType "application/json"
    return $result
}

function Invoke-VBAFServerBatchPredict {
    param(
        [double[][]] $FeatureMatrix,
        [int]        $Port = 8080
    )
    $body   = @{ features=$FeatureMatrix } | ConvertTo-Json -Depth 5
    $result = Invoke-RestMethod -Uri "http://localhost:$Port/predict/batch" -Method POST `
                  -Body $body -ContentType "application/json"
    return $result
}

function Get-VBAFServerHealth {
    param([int]$Port = 8080)
    return Invoke-RestMethod -Uri "http://localhost:$Port/health" -Method GET
}

function Get-VBAFServerMetrics {
    param([int]$Port = 8080)
    return Invoke-RestMethod -Uri "http://localhost:$Port/metrics" -Method GET
}

# ============================================================
# TEST
# 1. Run VBAF.LoadAll.ps1
#
# --- Train a model ---
# 2. $data   = Get-VBAFDataset -Name "HousePrice"
#    $scaler = [StandardScaler]::new()
#    $Xs     = $scaler.FitTransform($data.X)
#    $model  = [LinearRegression]::new()
#    $model.Fit($Xs, $data.y)
#
# --- Single prediction (no server) ---
# 3. $result = Invoke-VBAFPrediction -Model $model -ModelType "LinearRegression" `
#                  -Features @(120.0, 3.0, 5.0) -Scaler $scaler
#    Write-Host "Prediction: $($result.Prediction)  Latency: $($result.LatencyMs)ms"
#
# --- Batch prediction ---
# 4. $batch = Invoke-VBAFBatchPrediction -Model $model -ModelType "LinearRegression" `
#                 -FeatureMatrix @(@(120.0,3.0,5.0),@(80.0,2.0,10.0),@(200.0,4.0,2.0)) `
#                 -Scaler $scaler
#    Write-Host "Predictions: $($batch.Predictions -join ', ')"
#    Write-Host "Total: $($batch.LatencyMs)ms  Per-item: $($batch.AvgLatencyMs)ms"
#
# --- A/B Test ---
# 5. $model2 = [RidgeRegression]::new(0.1)
#    $model2.Fit($Xs, $data.y)
#    Start-VBAFABTest -TestName "LinearVsRidge" `
#        -ModelA $model  -ModelAName "HousePricePredictor" -ModelAVersion "1.0.0" -ModelAType "LinearRegression" -ScalerA $scaler `
#        -ModelB $model2 -ModelBName "HousePricePredictor" -ModelBVersion "1.1.0" -ModelBType "RidgeRegression"  -ScalerB $scaler
#    # Simulate 20 requests
#    for ($i=0; $i -lt 20; $i++) {
#        $feat = @([double](80+$i*5), [double](2+$i%3), [double](1+$i%10))
#        Invoke-VBAFABPredict -Features $feat | Out-Null
#    }
#    Get-VBAFABStats
#    Stop-VBAFABTest
#
# --- Monitoring ---
# 6. Get-VBAFMonitoringStats
#    Export-VBAFMonitoringLog -Path "C:\Temp\vbaf_log.csv"
#
# --- HTTP Server (open a regular PowerShell console to test) ---
# Note: Only one ISE can run at a time. Start server in ISE, then open
# a regular PowerShell console (not ISE) for Window 2 commands.
# 7. Start-VBAFModelServer -Model $model -ModelName "HousePricePredictor" `
#        -ModelVersion "1.0.0" -ModelType "LinearRegression" -Scaler $scaler -Port 8080
#    # In another PS window:
#    # Invoke-VBAFServerPredict -Features @(120.0, 3.0, 5.0)
#    # Get-VBAFServerHealth
# ============================================================
Write-Host "📦 VBAF.ML.ModelServer.ps1 loaded  [v2.1.0 🏭]" -ForegroundColor Green
Write-Host "   Functions : Invoke-VBAFPrediction"            -ForegroundColor Cyan
Write-Host "              Invoke-VBAFBatchPrediction"        -ForegroundColor Cyan
Write-Host "              Start-VBAFModelServer"             -ForegroundColor Cyan
Write-Host "              Stop-VBAFModelServer"              -ForegroundColor Cyan
Write-Host "              Start-VBAFABTest"                  -ForegroundColor Cyan
Write-Host "              Invoke-VBAFABPredict"              -ForegroundColor Cyan
Write-Host "              Get-VBAFABStats"                   -ForegroundColor Cyan
Write-Host "              Stop-VBAFABTest"                   -ForegroundColor Cyan
Write-Host "              Get-VBAFMonitoringStats"           -ForegroundColor Cyan
Write-Host "              Export-VBAFMonitoringLog"          -ForegroundColor Cyan
Write-Host "              Invoke-VBAFServerPredict"          -ForegroundColor Cyan
Write-Host "              Get-VBAFServerHealth"              -ForegroundColor Cyan
Write-Host ""
Write-Host "   Quick start:" -ForegroundColor Yellow
Write-Host '   $r = Invoke-VBAFPrediction -Model $model -ModelType "LinearRegression" -Features @(120.0,3.0,5.0) -Scaler $scaler' -ForegroundColor White
Write-Host '   Write-Host "Prediction: $($r.Prediction)  Latency: $($r.LatencyMs)ms"'  -ForegroundColor White
Write-Host '   Start-VBAFABTest -TestName "v1vsv2" -ModelA $m1 -ModelAName "HP" -ModelAVersion "1.0" -ModelAType "LinearRegression" -ModelB $m2 -ModelBName "HP" -ModelBVersion "1.1" -ModelBType "RidgeRegression"' -ForegroundColor White
Write-Host ""
