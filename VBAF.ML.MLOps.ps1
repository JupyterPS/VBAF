#Requires -Version 5.1
<#
.SYNOPSIS
    MLOps - Experiment Tracking, Drift Detection, Retraining, CI/CD
.DESCRIPTION
    Implements MLOps workflows from scratch.
    Designed as a TEACHING resource - every step explained.
    Features included:
      - Experiment tracking  : log runs, params, metrics (MLflow-like)
      - Model monitoring     : track performance over time
      - Data drift detection : detect when input data changes
      - Retraining triggers  : auto-flag when model needs retraining
      - CI/CD examples       : pipeline scripts for automation
    Standalone - works with all VBAF ML modules.
.NOTES
    Part of VBAF - Phase 7 Production Features - v2.1.0
    PS 5.1 compatible
    Teaching project - MLOps concepts explained step by step!
#>

# ============================================================
# TEACHING NOTE: What is MLOps?
# MLOps = ML + DevOps. It applies software engineering practices
# to the ML lifecycle:
#
#   DEVELOP  : experiment tracking (what did I try?)
#   DEPLOY   : model registry + serving (already built!)
#   MONITOR  : is the model still working well in production?
#   RETRAIN  : trigger retraining when performance degrades
#   AUTOMATE : CI/CD pipelines for the whole cycle
#
# Without MLOps:
#   "Which hyperparams gave us R2=0.998?"  -> nobody knows!
#   "Why did accuracy drop last Tuesday?"  -> nobody knows!
#
# With MLOps: everything is tracked, versioned, auditable.
# ============================================================

$script:ExperimentStorePath = Join-Path $env:USERPROFILE "VBAFRegistry\experiments"
$script:ActiveExperiment    = $null
$script:ActiveRun           = $null

# ============================================================
# EXPERIMENT TRACKING (MLflow-like)
# ============================================================
# TEACHING NOTE: MLflow is the industry standard for experiment
# tracking. Our version has the same concepts:
#
#   EXPERIMENT : a project (e.g. "HousePricePrediction")
#   RUN        : one training attempt within the experiment
#   PARAMS     : hyperparameters used (lr=0.01, epochs=100)
#   METRICS    : results achieved (R2=0.998, RMSE=2.1)
#   ARTIFACTS  : files produced (model.json, plot.png)
#
# You can compare runs to find what worked best!
# ============================================================

function New-VBAFExperiment {
    param([string]$Name, [string]$Description = "")

    if (-not (Test-Path $script:ExperimentStorePath)) {
        New-Item -ItemType Directory -Path $script:ExperimentStorePath -Force | Out-Null
    }

    $expPath = Join-Path $script:ExperimentStorePath $Name
    if (-not (Test-Path $expPath)) {
        New-Item -ItemType Directory -Path $expPath -Force | Out-Null
    }

    $indexPath = Join-Path $expPath "experiment.json"
    if (-not (Test-Path $indexPath)) {
        @{
            Name        = $Name
            Description = $Description
            Created     = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            Runs        = @{}
        } | ConvertTo-Json -Depth 5 | Set-Content $indexPath -Encoding UTF8
    }

    $script:ActiveExperiment = $Name
    Write-Host ("🧪 Experiment: {0}" -f $Name) -ForegroundColor Green
    if ($Description -ne "") { Write-Host ("   {0}" -f $Description) -ForegroundColor DarkGray }
    return $Name
}

function Start-VBAFRun {
    param(
        [string]    $RunName   = "",
        [string]    $ModelType = "",
        [hashtable] $Params    = @{}
    )

    if ($null -eq $script:ActiveExperiment) {
        Write-Host "❌ No active experiment. Call New-VBAFExperiment first." -ForegroundColor Red
        return $null
    }

    $runId   = (Get-Date).ToString("yyyyMMdd_HHmmss")
    $name    = if ($RunName -ne "") { $RunName } else { "run_$runId" }

    $script:ActiveRun = @{
        RunId     = $runId
        RunName   = $name
        ModelType = $ModelType
        Started   = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        Ended     = $null
        Params    = $Params
        Metrics   = @{}
        Tags      = @{}
        Artifacts = @()
        Status    = "running"
    }

    Write-Host ("▶️  Run started: {0}" -f $name) -ForegroundColor Cyan
    if ($Params.Count -gt 0) {
        Write-Host "   Params: " -NoNewline -ForegroundColor DarkGray
        foreach ($k in $Params.Keys) { Write-Host ("{0}={1}  " -f $k, $Params[$k]) -NoNewline -ForegroundColor White }
        Write-Host ""
    }
    return $runId
}

function Set-VBAFRunParam {
    param([string]$Key, [object]$Value)
    if ($null -eq $script:ActiveRun) { Write-Host "❌ No active run" -ForegroundColor Red; return }
    $script:ActiveRun.Params[$Key] = $Value
}

function Set-VBAFRunMetric {
    param([string]$Key, [double]$Value, [int]$Step = -1)
    if ($null -eq $script:ActiveRun) { Write-Host "❌ No active run" -ForegroundColor Red; return }
    if (-not $script:ActiveRun.Metrics.ContainsKey($Key)) {
        $script:ActiveRun.Metrics[$Key] = @()
    }
    $script:ActiveRun.Metrics[$Key] += @{ Value=$Value; Step=$Step; Time=(Get-Date).ToString("HH:mm:ss") }
}

function Set-VBAFRunTag {
    param([string]$Key, [string]$Value)
    if ($null -eq $script:ActiveRun) { Write-Host "❌ No active run" -ForegroundColor Red; return }
    $script:ActiveRun.Tags[$Key] = $Value
}

function Add-VBAFRunArtifact {
    param([string]$Path, [string]$Description = "")
    if ($null -eq $script:ActiveRun) { Write-Host "❌ No active run" -ForegroundColor Red; return }
    $script:ActiveRun.Artifacts += @{ Path=$Path; Description=$Description }
}

function Stop-VBAFRun {
    param([string]$Status = "completed")  # completed, failed, cancelled

    if ($null -eq $script:ActiveRun) { Write-Host "❌ No active run" -ForegroundColor Red; return }

    $script:ActiveRun.Ended  = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $script:ActiveRun.Status = $Status

    # Save run to experiment store
    $expPath = Join-Path $script:ExperimentStorePath $script:ActiveExperiment
    $runPath = Join-Path $expPath "$($script:ActiveRun.RunId).json"
    $script:ActiveRun | ConvertTo-Json -Depth 10 | Set-Content $runPath -Encoding UTF8

    # Update experiment index
    $indexPath = Join-Path $expPath "experiment.json"
    $index     = Get-Content $indexPath -Raw | ConvertFrom-Json
    $runSummary = [PSCustomObject]@{
        RunName   = $script:ActiveRun.RunName
        ModelType = $script:ActiveRun.ModelType
        Started   = $script:ActiveRun.Started
        Status    = $Status
        Path      = $runPath
    }
    $index.Runs | Add-Member -NotePropertyName $script:ActiveRun.RunId -NotePropertyValue $runSummary -Force
    $index | ConvertTo-Json -Depth 10 | Set-Content $indexPath -Encoding UTF8

    $color = switch ($Status) { "completed" {"Green"} "failed" {"Red"} default {"Yellow"} }
    Write-Host ("⏹️  Run {0}: {1}" -f $Status, $script:ActiveRun.RunName) -ForegroundColor $color

    # Print final metrics
    if ($script:ActiveRun.Metrics.Count -gt 0) {
        Write-Host "   Final metrics: " -NoNewline -ForegroundColor DarkGray
        foreach ($k in $script:ActiveRun.Metrics.Keys) {
            $vals = $script:ActiveRun.Metrics[$k]
            $last = $vals[-1].Value
            Write-Host ("{0}={1}  " -f $k, [Math]::Round($last, 4)) -NoNewline -ForegroundColor White
        }
        Write-Host ""
    }

    $script:ActiveRun = $null
}

function Get-VBAFExperimentRuns {
    param([string]$ExperimentName = "", [int]$TopN = 10)

    $expName = if ($ExperimentName -ne "") { $ExperimentName } else { $script:ActiveExperiment }
    if ($null -eq $expName) { Write-Host "❌ No experiment specified" -ForegroundColor Red; return }

    $indexPath = Join-Path $script:ExperimentStorePath "$expName\experiment.json"
    if (-not (Test-Path $indexPath)) { Write-Host "❌ Experiment not found: $expName" -ForegroundColor Red; return }

    $index = Get-Content $indexPath -Raw | ConvertFrom-Json
    $runs  = $index.Runs.PSObject.Properties

    Write-Host ""
    Write-Host ("📋 Experiment: {0}" -f $expName) -ForegroundColor Green
    Write-Host ("   {0,-20} {1,-15} {2,-10} {3}" -f "Run Name","Model","Status","Started") -ForegroundColor Yellow
    Write-Host ("   {0}" -f ("-" * 65)) -ForegroundColor DarkGray

    $count = 0
    foreach ($run in ($runs | Sort-Object Name -Descending)) {
        if ($count -ge $TopN) { break }
        $r     = $run.Value
        $color = switch ($r.Status) { "completed" {"White"} "failed" {"Red"} default {"Yellow"} }
        Write-Host ("   {0,-20} {1,-15} {2,-10} {3}" -f $r.RunName, $r.ModelType, $r.Status, $r.Started) -ForegroundColor $color
        $count++
    }
    Write-Host ""
}

function Compare-VBAFRuns {
    param([string]$ExperimentName = "", [string]$MetricKey = "")

    $expName = if ($ExperimentName -ne "") { $ExperimentName } else { $script:ActiveExperiment }
    $expPath = Join-Path $script:ExperimentStorePath $expName

    $runFiles = Get-ChildItem $expPath -Filter "*.json" | Where-Object { $_.Name -ne "experiment.json" }
    if ($runFiles.Count -eq 0) { Write-Host "No runs found" -ForegroundColor Yellow; return }

    Write-Host ""
    Write-Host ("🏆 Run Comparison: {0}" -f $expName) -ForegroundColor Green

    $rows = @()
    foreach ($f in $runFiles) {
        $run = Get-Content $f.FullName -Raw | ConvertFrom-Json
        if ($run.Status -ne "completed") { continue }
        $metricStr = ""
        if ($null -ne $run.Metrics) {
            $run.Metrics.PSObject.Properties | ForEach-Object {
                $vals = $_.Value
                if ($vals -is [array] -and $vals.Count -gt 0) {
                    $last = $vals[-1].Value
                    $metricStr += "{0}={1}  " -f $_.Name, [Math]::Round($last,4)
                }
            }
        }
        $paramStr = ""
        if ($null -ne $run.Params) {
            $run.Params.PSObject.Properties | ForEach-Object {
                $paramStr += "{0}={1} " -f $_.Name, $_.Value
            }
        }
        $rows += @{ Name=$run.RunName; Model=$run.ModelType; Metrics=$metricStr.Trim(); Params=$paramStr.Trim() }
    }

    Write-Host ("   {0,-20} {1,-20} {2,-30} {3}" -f "Run","Model","Metrics","Params") -ForegroundColor Yellow
    Write-Host ("   {0}" -f ("-" * 85)) -ForegroundColor DarkGray
    foreach ($row in $rows) {
        Write-Host ("   {0,-20} {1,-20} {2,-30} {3}" -f $row.Name, $row.Model, $row.Metrics, $row.Params) -ForegroundColor White
    }
    Write-Host ""
}

# ============================================================
# DATA DRIFT DETECTION
# ============================================================
# TEACHING NOTE: Data drift = input data in production is
# different from training data!
#
# Example: You trained on house prices from 2020.
# In 2026, houses are larger on average. The model gets
# inputs it never saw during training -> predictions degrade!
#
# Detection methods:
#   Mean drift   : is the average feature value shifting?
#   Std drift    : is the variance changing?
#   KS statistic : statistical test for distribution change
#   PSI          : Population Stability Index (industry standard)
#
# PSI interpretation:
#   PSI < 0.1  : no significant change (green)
#   PSI < 0.2  : moderate change (yellow) - monitor closely
#   PSI >= 0.2 : significant drift (red) - consider retraining!
# ============================================================

function Get-VBAFDriftReport {
    param(
        [double[][]] $ReferenceData,   # training data distribution
        [double[][]] $ProductionData,  # recent production inputs
        [string[]]   $FeatureNames = @(),
        [double]     $WarnThreshold  = 0.1,
        [double]     $AlertThreshold = 0.2
    )

    $nFeatures = $ReferenceData[0].Length
    if ($FeatureNames.Length -eq 0) {
        $FeatureNames = 0..($nFeatures-1) | ForEach-Object { "feature$_" }
    }

    Write-Host ""
    Write-Host "🌊 Data Drift Report" -ForegroundColor Green
    Write-Host ("   Reference samples : {0}" -f $ReferenceData.Length)  -ForegroundColor Cyan
    Write-Host ("   Production samples: {0}" -f $ProductionData.Length) -ForegroundColor Cyan
    Write-Host ""
    Write-Host ("   {0,-15} {1,8} {2,8} {3,8} {4,8} {5,8}  {6}" -f "Feature","Ref Mean","Prod Mean","Ref Std","Prod Std","PSI","Status") -ForegroundColor Yellow
    Write-Host ("   {0}" -f ("-" * 75)) -ForegroundColor DarkGray

    $driftResults = @()
    for ($f = 0; $f -lt $nFeatures; $f++) {
        $refVals  = $ReferenceData  | ForEach-Object { [double]$_[$f] }
        $prodVals = $ProductionData | ForEach-Object { [double]$_[$f] }

        $refMean  = ($refVals  | Measure-Object -Average).Average
        $prodMean = ($prodVals | Measure-Object -Average).Average
        $refStd   = [Math]::Sqrt((($refVals  | ForEach-Object { ($_ - $refMean) * ($_ - $refMean) } | Measure-Object -Sum).Sum / $refVals.Count))
        $prodStd  = [Math]::Sqrt((($prodVals | ForEach-Object { ($_ - $prodMean) * ($_ - $prodMean) } | Measure-Object -Sum).Sum / $prodVals.Count))

        # PSI: Population Stability Index
        $psi    = 0.0
        $nBins  = 10
        $minVal = [Math]::Min(($refVals | Measure-Object -Minimum).Minimum, ($prodVals | Measure-Object -Minimum).Minimum)
        $maxVal = [Math]::Max(($refVals | Measure-Object -Maximum).Maximum, ($prodVals | Measure-Object -Maximum).Maximum)
        $binW   = ($maxVal - $minVal) / $nBins
        if ($binW -gt 0) {
            for ($b = 0; $b -lt $nBins; $b++) {
                $lo   = $minVal + $b * $binW
                $hi   = $lo + $binW
                $refP = [Math]::Max(0.0001, (@($refVals  | Where-Object { $_ -ge $lo -and $_ -lt $hi }).Count / $refVals.Count))
                $proP = [Math]::Max(0.0001, (@($prodVals | Where-Object { $_ -ge $lo -and $_ -lt $hi }).Count / $prodVals.Count))
                $psi += ($proP - $refP) * [Math]::Log($proP / $refP)
            }
        }

        $status = if ($psi -ge $AlertThreshold) { "🔴 DRIFT"  }
                  elseif ($psi -ge $WarnThreshold) { "🟡 WARN" }
                  else { "🟢 OK" }

        $color  = if ($psi -ge $AlertThreshold) { "Red" } elseif ($psi -ge $WarnThreshold) { "Yellow" } else { "Green" }
        Write-Host ("   {0,-15} {1,8:F2} {2,8:F2} {3,8:F2} {4,8:F2} {5,8:F4}  {6}" -f `
            $FeatureNames[$f], $refMean, $prodMean, $refStd, $prodStd, $psi, $status) -ForegroundColor $color

        $driftResults += @{ Feature=$FeatureNames[$f]; PSI=$psi; Status=$status; RefMean=$refMean; ProdMean=$prodMean }
    }

    $maxPSI   = ($driftResults | ForEach-Object { $_.PSI } | Measure-Object -Maximum).Maximum
    $drifted  = @($driftResults | Where-Object { $_.PSI -ge $AlertThreshold }).Count
    Write-Host ""
    Write-Host ("   Max PSI: {0:F4}  Drifted features: {1}/{2}" -f $maxPSI, $drifted, $nFeatures) -ForegroundColor White
    if ($drifted -gt 0) {
        Write-Host "   ⚠️  Retraining recommended!" -ForegroundColor Red
    } else {
        Write-Host "   ✅ No significant drift detected" -ForegroundColor Green
    }
    Write-Host ""
    return $driftResults
}

# ============================================================
# AUTOMATED RETRAINING TRIGGERS
# ============================================================
# TEACHING NOTE: When should you retrain a model?
#   1. Performance degradation: accuracy drops below threshold
#   2. Data drift: input distribution shifts significantly
#   3. Schedule: retrain every N days regardless
#   4. Volume: retrain after N new labeled samples available
#
# VBAF implements all four trigger types!
# ============================================================

function New-VBAFRetrainingPolicy {
    param(
        [string] $ModelName,
        [double] $MinAccuracy      = 0.90,  # retrain if accuracy drops below this
        [double] $MaxDriftPSI      = 0.20,  # retrain if PSI exceeds this
        [int]    $MaxAgeDays       = 30,    # retrain if model is older than this
        [int]    $MinNewSamples    = 100    # retrain when this many new samples available
    )
    $policy = @{
        ModelName      = $ModelName
        MinAccuracy    = $MinAccuracy
        MaxDriftPSI    = $MaxDriftPSI
        MaxAgeDays     = $MaxAgeDays
        MinNewSamples  = $MinNewSamples
        Created        = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }
    Write-Host ("📋 Retraining policy created for: {0}" -f $ModelName) -ForegroundColor Green
    Write-Host ("   Accuracy threshold : < {0}"   -f $MinAccuracy)  -ForegroundColor White
    Write-Host ("   Max drift PSI      : > {0}"   -f $MaxDriftPSI)  -ForegroundColor White
    Write-Host ("   Max model age      : {0} days" -f $MaxAgeDays)   -ForegroundColor White
    Write-Host ("   New samples needed : {0}"      -f $MinNewSamples) -ForegroundColor White
    return $policy
}

function Test-VBAFRetrainingNeeded {
    param(
        [hashtable] $Policy,
        [double]    $CurrentAccuracy  = 1.0,
        [double]    $CurrentMaxPSI    = 0.0,
        [datetime]  $ModelTrainedDate = [datetime]::Now,
        [int]       $NewSamplesCount  = 0
    )

    $triggers = @()
    $needed   = $false

    if ($CurrentAccuracy -lt $Policy.MinAccuracy) {
        $triggers += "Accuracy {0:F4} below threshold {1}" -f $CurrentAccuracy, $Policy.MinAccuracy
        $needed = $true
    }
    if ($CurrentMaxPSI -gt $Policy.MaxDriftPSI) {
        $triggers += "Drift PSI {0:F4} exceeds threshold {1}" -f $CurrentMaxPSI, $Policy.MaxDriftPSI
        $needed = $true
    }
    $ageDays = ([datetime]::Now - $ModelTrainedDate).TotalDays
    if ($ageDays -gt $Policy.MaxAgeDays) {
        $triggers += "Model age {0:F0} days exceeds {1} day limit" -f $ageDays, $Policy.MaxAgeDays
        $needed = $true
    }
    if ($NewSamplesCount -ge $Policy.MinNewSamples) {
        $triggers += "{0} new samples available (threshold: {1})" -f $NewSamplesCount, $Policy.MinNewSamples
        $needed = $true
    }

    Write-Host ""
    Write-Host ("🔄 Retraining Check: {0}" -f $Policy.ModelName) -ForegroundColor Green
    Write-Host ("   Accuracy  : {0:F4}  (min: {1})" -f $CurrentAccuracy, $Policy.MinAccuracy) -ForegroundColor White
    Write-Host ("   Max PSI   : {0:F4}  (max: {1})" -f $CurrentMaxPSI, $Policy.MaxDriftPSI)   -ForegroundColor White
    Write-Host ("   Model age : {0:F0} days  (max: {1})" -f $ageDays, $Policy.MaxAgeDays)      -ForegroundColor White
    Write-Host ("   New samples: {0}  (min: {1})"    -f $NewSamplesCount, $Policy.MinNewSamples) -ForegroundColor White
    Write-Host ""

    if ($needed) {
        Write-Host "   ⚠️  RETRAINING TRIGGERED:" -ForegroundColor Red
        foreach ($t in $triggers) { Write-Host ("     - {0}" -f $t) -ForegroundColor Yellow }
    } else {
        Write-Host "   ✅ No retraining needed" -ForegroundColor Green
    }
    Write-Host ""
    return @{ Needed=$needed; Triggers=$triggers }
}

# ============================================================
# CI/CD INTEGRATION
# ============================================================
# TEACHING NOTE: CI/CD for ML means automating the pipeline:
#   Commit code -> Run tests -> Train model -> Evaluate ->
#   Compare to baseline -> Promote if better -> Deploy
#
# Our implementation provides:
#   - Invoke-VBAFMLPipeline : full train/eval/compare/save pipeline
#   - Export-VBAFPipelineScript : generate a .ps1 CI script
#   - Test-VBAFModelGate : pass/fail gate for promotion decisions
# ============================================================

function Invoke-VBAFMLPipeline {
    param(
        [string]     $PipelineName,
        [string]     $ExperimentName,
        [scriptblock]$TrainBlock,        # { param($data) ... return $model }
        [scriptblock]$EvalBlock,         # { param($model, $data) ... return @{R2=...; RMSE=...} }
        [object]     $TrainData,
        [hashtable]  $BaselineMetrics = @{},
        [hashtable]  $Params          = @{},
        [string]     $ModelName       = "",
        [string]     $ModelType       = ""
    )

    Write-Host ""
    Write-Host ("🏗️  ML Pipeline: {0}" -f $PipelineName) -ForegroundColor Green
    Write-Host ("   {0}" -f ("-" * 45)) -ForegroundColor DarkGray

    # Step 1: Start experiment run
    New-VBAFExperiment -Name $ExperimentName | Out-Null
    Start-VBAFRun -RunName $PipelineName -ModelType $ModelType -Params $Params | Out-Null

    $pipelineResult = @{ Success=$false; Model=$null; Metrics=@{}; Promoted=$false }

    try {
        # Step 2: Train
        Write-Host "   [1/4] Training..." -ForegroundColor Cyan
        $sw    = [System.Diagnostics.Stopwatch]::StartNew()
        $model = & $TrainBlock $TrainData
        $sw.Stop()
        $trainTime = [Math]::Round($sw.Elapsed.TotalSeconds, 2)
        Set-VBAFRunMetric -Key "train_time_s" -Value $trainTime
        Write-Host ("         Done in {0}s" -f $trainTime) -ForegroundColor DarkGray

        # Step 3: Evaluate
        Write-Host "   [2/4] Evaluating..." -ForegroundColor Cyan
        $metrics = & $EvalBlock $model $TrainData
        foreach ($k in $metrics.Keys) {
            Set-VBAFRunMetric -Key $k -Value $metrics[$k]
            Write-Host ("         {0} = {1}" -f $k, [Math]::Round($metrics[$k],4)) -ForegroundColor White
        }
        $pipelineResult.Metrics = $metrics

        # Step 4: Compare to baseline
        Write-Host "   [3/4] Comparing to baseline..." -ForegroundColor Cyan
        $promoted = $true
        if ($BaselineMetrics.Count -gt 0) {
            foreach ($k in $BaselineMetrics.Keys) {
                if ($metrics.ContainsKey($k)) {
                    $isR2Like  = $k -match "R2|accuracy|f1|auc"
                    $isBetter  = if ($isR2Like) { $metrics[$k] -ge $BaselineMetrics[$k] } `
                                 else { $metrics[$k] -le $BaselineMetrics[$k] }
                    $arrow     = if ($isBetter) { "✅" } else { "❌" }
                    Write-Host ("         {0} {1}: {2:F4} vs baseline {3:F4}" -f $arrow, $k, $metrics[$k], $BaselineMetrics[$k]) -ForegroundColor $(if ($isBetter) {"Green"} else {"Red"})
                    if (-not $isBetter) { $promoted = $false }
                }
            }
        }
        $pipelineResult.Promoted = $promoted
        Set-VBAFRunTag -Key "promoted" -Value "$promoted"

        # Step 5: Save if promoted
        Write-Host "   [4/4] Saving..." -ForegroundColor Cyan
        if ($promoted -and $ModelName -ne "") {
            Write-Host "         Model promoted! ✅" -ForegroundColor Green
        } else {
            Write-Host "         Model NOT promoted (below baseline)" -ForegroundColor Yellow
        }

        $pipelineResult.Model   = $model
        $pipelineResult.Success = $true
        Stop-VBAFRun -Status "completed"

    } catch {
        Write-Host ("   ❌ Pipeline failed: {0}" -f $_.Exception.Message) -ForegroundColor Red
        Stop-VBAFRun -Status "failed"
    }

    Write-Host ""
    $statusMsg = if ($pipelineResult.Promoted) { "✅ PASSED - model promoted" } else { "⚠️  NOT PROMOTED - below baseline" }
    Write-Host ("🏁 Pipeline {0}: {1}" -f $PipelineName, $statusMsg) -ForegroundColor $(if ($pipelineResult.Promoted) {"Green"} else {"Yellow"})
    Write-Host ""
    return $pipelineResult
}

function Test-VBAFModelGate {
    param(
        [hashtable] $Metrics,
        [hashtable] $Gates   # e.g. @{R2=0.95; RMSE=5.0}
    )
    $passed = $true
    $fails  = @()
    Write-Host ""
    Write-Host "🚦 Model Quality Gate:" -ForegroundColor Green
    foreach ($k in $Gates.Keys) {
        if (-not $Metrics.ContainsKey($k)) {
            Write-Host ("   ⚠️  Missing metric: {0}" -f $k) -ForegroundColor Yellow
            continue
        }
        $isR2Like = $k -match "R2|accuracy|f1|auc"
        $ok = if ($isR2Like) { $Metrics[$k] -ge $Gates[$k] } else { $Metrics[$k] -le $Gates[$k] }
        $sym = if ($ok) { "✅" } else { "❌" }
        $col = if ($ok) { "Green" } else { "Red" }
        Write-Host ("   {0} {1}: {2:F4} (gate: {3})" -f $sym, $k, $Metrics[$k], $Gates[$k]) -ForegroundColor $col
        if (-not $ok) { $passed = $false; $fails += $k }
    }
    $result = if ($passed) { "PASSED ✅" } else { "FAILED ❌ ($($fails -join ', '))" }
    Write-Host ("   Gate result: {0}" -f $result) -ForegroundColor $(if ($passed) {"Green"} else {"Red"})
    Write-Host ""
    return $passed
}

function Export-VBAFPipelineScript {
    param(
        [string] $OutputPath  = ".\vbaf_pipeline.ps1",
        [string] $ModelName   = "MyModel",
        [string] $ModelType   = "LinearRegression",
        [string] $DatasetName = "HousePrice"
    )

    $script = @"
#Requires -Version 5.1
# VBAF CI/CD Pipeline Script - Generated $(Get-Date -Format "yyyy-MM-dd HH:mm")
# Run this script to train, evaluate and promote a model automatically.

param(
    [string]`$Environment = "dev",   # dev, staging, prod
    [switch]`$ForceRetrain = `$false
)

Write-Host "🚀 VBAF ML Pipeline - Environment: `$Environment" -ForegroundColor Green

# 1. Load framework
`$scriptPath = Split-Path -Parent `$MyInvocation.MyCommand.Definition
. (Join-Path `$scriptPath "VBAF.LoadAll.ps1")

# 2. Load data
`$data = Get-VBAFDataset -Name "$DatasetName"
`$scaler = [StandardScaler]::new()
`$Xs = `$scaler.FitTransform(`$data.X)

# 3. Run pipeline
`$result = Invoke-VBAFMLPipeline ``
    -PipelineName  "CI_`$(Get-Date -Format 'yyyyMMdd_HHmm')" ``
    -ExperimentName "$ModelName" ``
    -ModelType     "$ModelType" ``
    -TrainData     `$data ``
    -BaselineMetrics @{ R2=0.95; RMSE=5.0 } ``
    -Params @{ scaler="StandardScaler" } ``
    -ModelName     "$ModelName" ``
    -TrainBlock {
        param(`$d)
        `$m = [LinearRegression]::new()
        `$m.Fit(`$Xs, `$d.y)
        return `$m
    } ``
    -EvalBlock {
        param(`$m, `$d)
        `$preds = `$m.Predict(`$Xs)
        `$metrics = Get-RegressionMetrics `$d.y `$preds
        return @{ R2=`$metrics.R2; RMSE=`$metrics.RMSE }
    }

# 4. Quality gate
`$gateResult = Test-VBAFModelGate -Metrics `$result.Metrics -Gates @{ R2=0.95; RMSE=5.0 }

# 5. Save if gate passed
if (`$gateResult -and `$result.Promoted) {
    Save-VBAFModel -ModelName "$ModelName" -Model `$result.Model ``
        -ModelType "$ModelType" -Metrics `$result.Metrics ``
        -DatasetName "$DatasetName" -BumpType "patch"
    Write-Host "✅ Model saved to registry" -ForegroundColor Green
    exit 0
} else {
    Write-Host "❌ Model did not pass quality gate - not saved" -ForegroundColor Red
    exit 1
}
"@

    $script | Set-Content $OutputPath -Encoding UTF8
    Write-Host ("📄 Pipeline script exported: {0}" -f $OutputPath) -ForegroundColor Green
    return $OutputPath
}

# ============================================================
# TEST
# 1. Run VBAF.LoadAll.ps1
#
# --- Experiment tracking ---
# 2. New-VBAFExperiment -Name "HousePriceExperiments" -Description "Compare regression models"
#    Start-VBAFRun -RunName "linear_baseline" -ModelType "LinearRegression" -Params @{scaler="Standard"}
#    Set-VBAFRunMetric -Key "R2"   -Value 0.998
#    Set-VBAFRunMetric -Key "RMSE" -Value 2.1
#    Stop-VBAFRun
#    Start-VBAFRun -RunName "ridge_v1" -ModelType "RidgeRegression" -Params @{scaler="Standard"; lambda=0.1}
#    Set-VBAFRunMetric -Key "R2"   -Value 0.999
#    Set-VBAFRunMetric -Key "RMSE" -Value 1.8
#    Stop-VBAFRun
#    Get-VBAFExperimentRuns
#    Compare-VBAFRuns
#
# --- Drift detection ---
# 3. $data = Get-VBAFDataset -Name "HousePrice"
#    $ref  = $data.X   # training distribution
#    # Simulate production drift: larger houses
#    $prod = $data.X | ForEach-Object { @([double]($_[0]*1.5), [double]$_[1], [double]$_[2]) }
#    Get-VBAFDriftReport -ReferenceData $ref -ProductionData $prod `
#        -FeatureNames @("size_sqm","bedrooms","age_years")
#
# --- Retraining policy ---
# 4. $policy = New-VBAFRetrainingPolicy -ModelName "HousePricePredictor" `
#                  -MinAccuracy 0.95 -MaxDriftPSI 0.2 -MaxAgeDays 30
#    Test-VBAFRetrainingNeeded -Policy $policy -CurrentAccuracy 0.92 `
#        -CurrentMaxPSI 0.05 -ModelTrainedDate (Get-Date).AddDays(-10)
#
# --- Export CI/CD script ---
# 5. Export-VBAFPipelineScript -OutputPath "C:\Temp\vbaf_pipeline.ps1"
# ============================================================
Write-Host "📦 VBAF.ML.MLOps.ps1 loaded  [v2.1.0 🏭]" -ForegroundColor Green
Write-Host "   Experiment Tracking:" -ForegroundColor Cyan
Write-Host "              New-VBAFExperiment"          -ForegroundColor Cyan
Write-Host "              Start-VBAFRun / Stop-VBAFRun" -ForegroundColor Cyan
Write-Host "              Set-VBAFRunMetric / Param / Tag" -ForegroundColor Cyan
Write-Host "              Get-VBAFExperimentRuns"      -ForegroundColor Cyan
Write-Host "              Compare-VBAFRuns"            -ForegroundColor Cyan
Write-Host "   Drift Detection:"                       -ForegroundColor Cyan
Write-Host "              Get-VBAFDriftReport"         -ForegroundColor Cyan
Write-Host "   Retraining:"                            -ForegroundColor Cyan
Write-Host "              New-VBAFRetrainingPolicy"    -ForegroundColor Cyan
Write-Host "              Test-VBAFRetrainingNeeded"   -ForegroundColor Cyan
Write-Host "   CI/CD:"                                 -ForegroundColor Cyan
Write-Host "              Invoke-VBAFMLPipeline"       -ForegroundColor Cyan
Write-Host "              Test-VBAFModelGate"          -ForegroundColor Cyan
Write-Host "              Export-VBAFPipelineScript"   -ForegroundColor Cyan
Write-Host ""
Write-Host "   Quick start:" -ForegroundColor Yellow
Write-Host '   New-VBAFExperiment -Name "MyExperiment"'  -ForegroundColor White
Write-Host '   Start-VBAFRun -RunName "run1" -ModelType "LinearRegression" -Params @{lr=0.01}' -ForegroundColor White
Write-Host '   Set-VBAFRunMetric -Key "R2" -Value 0.998' -ForegroundColor White
Write-Host '   Stop-VBAFRun'                             -ForegroundColor White
Write-Host '   Compare-VBAFRuns'                         -ForegroundColor White
Write-Host ""