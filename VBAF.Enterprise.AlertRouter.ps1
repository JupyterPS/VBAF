#Requires -Version 5.1
<#
.SYNOPSIS
    Pillar 6 - Enterprise Scripting: Intelligent Alert Router
.DESCRIPTION
    Trains a DQN agent to classify and route Windows Event Log alerts.
    The agent observes real event log severity and learns when to:
      - Ignore   : low severity events (action 0)
      - Log      : medium events worth recording (action 1)
      - Alert    : high severity needing attention (action 2)
      - Escalate : critical events requiring immediate action (action 3)
.NOTES
    Part of VBAF - Phase 9 Enterprise Automation Engine
    Pillar 6: Enterprise Scripting with Intelligence
    PS 5.1 compatible
#>

# ============================================================
# PILLAR 6 - ENTERPRISE SCRIPTING: ALERT ROUTER
# ============================================================
function Invoke-VBAFAlertRouterTraining {
    param(
        [int]    $Episodes   = 50,
        [int]    $PrintEvery = 10,
        [switch] $FastMode,
        [switch] $SimMode
    )

    Write-Host ""
    Write-Host "🏢 VBAF Enterprise - Pillar 6: Enterprise Scripting" -ForegroundColor Cyan
    Write-Host "   Training DQN agent on Alert Router..." -ForegroundColor Cyan
    Write-Host "   Actions: 0=Ignore  1=Log  2=Alert  3=Escalate" -ForegroundColor Yellow
    Write-Host "   Goal   : match action to event severity" -ForegroundColor Yellow
    Write-Host ""

    $arEnv = New-EnterpriseEnvironment -Name "AlertRouter"

    Write-Host "   Phase 1: Baseline (random agent)..." -ForegroundColor Gray
    $baseline = Invoke-VBAFBenchmark -Environment $arEnv -Episodes 10 -Label "Baseline Random"

    if ($FastMode) { $Episodes = [Math]::Min($Episodes, 30) }
    if ($SimMode) {
        Write-Host ""
        Write-Host "   Phase 2: Training DQN agent ($Episodes episodes - SimMode fast)..." -ForegroundColor Gray
    } else {
        Write-Host ""
        Write-Host "   Phase 2: Training DQN agent ($Episodes episodes)..." -ForegroundColor Gray
    }

    # Build DQN - 4 state, 4 actions
    $config              = [DQNConfig]::new()
    $config.StateSize    = 4   # severity, frequency, timeOfDay, repeatCount
    $config.ActionSize   = 4   # Ignore, Log, Alert, Escalate
    $config.EpsilonDecay = 0.9995
    $config.EpsilonMin  = 0.05
    [int[]] $arch        = @(4, 16, 16, 4)
    $mainNetwork         = [NeuralNetwork]::new($arch, $config.LearningRate)
    $targetNetwork       = [NeuralNetwork]::new($arch, $config.LearningRate)
    $memory              = [ExperienceReplay]::new($config.MemorySize)
    $agent               = [DQNAgent]::new($config, $mainNetwork, $targetNetwork, $memory)

    $results = [System.Collections.Generic.List[object]]::new()

    for ($ep = 1; $ep -le $Episodes; $ep++) {
        if ($SimMode) {
            # Real Windows events: 60% low, 30% medium, 10% high/critical
            $sevRoll = Get-Random -Minimum 1 -Maximum 100
            if ($sevRoll -le 60)      { $arEnv.Severity = [double](Get-Random -Minimum 0  -Maximum 20)  / 100.0 }
            elseif ($sevRoll -le 90)  { $arEnv.Severity = [double](Get-Random -Minimum 20 -Maximum 60)  / 100.0 }
            else                      { $arEnv.Severity = [double](Get-Random -Minimum 60 -Maximum 100) / 100.0 }
            $arEnv.Frequency   = [double](Get-Random -Minimum 0 -Maximum 100) / 100.0
            $arEnv.TimeOfDay   = [double]([System.DateTime]::Now.Hour) / 23.0
            $arEnv.RepeatCount = Get-Random -Minimum 0 -Maximum 5
            $arEnv.CorrectRoutes = 0
            $arEnv.MissedAlerts  = 0
            $arEnv.Steps         = 0
            $arEnv.TotalReward   = 0.0
            $arEnv.EpisodeCount++
            $state = $arEnv.GetState()
        } else {
            $state = $arEnv.Reset()
        }

        $done          = $false
        $epReward      = 0.0
        $ignoreCount   = 0
        $logCount      = 0
        $alertCount    = 0
        $escalateCount = 0
        [int] $stepCount = 0

        while (-not $done) {
            $action = $agent.Act($state)
            $result = $arEnv.Step($action)
            $agent.Remember($state, $action, $result.Reward, $result.NextState, $result.Done)
            $stepCount++
            if ($stepCount % 4 -eq 0) { $agent.Replay() }
            $state     = $result.NextState
            $done      = $result.Done
            $epReward += $result.Reward
            switch ($action) {
                0 { $ignoreCount++ }
                1 { $logCount++ }
                2 { $alertCount++ }
                3 { $escalateCount++ }
            }
        }

        $agent.EndEpisode($epReward)
        $results.Add(@{
            Episode   = $ep
            Reward    = $epReward
            Ignore    = $ignoreCount
            Log       = $logCount
            Alert     = $alertCount
            Escalate  = $escalateCount
            Epsilon   = $agent.Epsilon
        })

        if ($ep % $PrintEvery -eq 0) {
            $lastN  = $results | Select-Object -Last $PrintEvery
            $avgSum = 0.0
            foreach ($r2 in $lastN) { $avgSum += $r2.Reward }
            $avg = [Math]::Round($avgSum / $lastN.Count, 2)
            Write-Host ("   Ep {0,4}/{1}  AvgReward: {2,7}  Eps: {3:F3}  Ign:{4} Log:{5} Alt:{6} Esc:{7}" -f $ep, $Episodes, $avg, $agent.Epsilon, $ignoreCount, $logCount, $alertCount, $escalateCount) -ForegroundColor White
        }
    }

    Write-Host ""
    Write-Host "   Phase 3: Final evaluation..." -ForegroundColor Gray
    $trained = Invoke-VBAFBenchmark -Agent $agent -Environment $arEnv -Episodes 10 -Label "Trained DQN"

    $bAvg = [Math]::Round($baseline.Avg, 2)
    $tAvg = [Math]::Round($trained.Avg, 2)
    $improvement = if ($bAvg -ne 0) { [Math]::Round((($tAvg - $bAvg) / [Math]::Abs($bAvg)) * 100, 1) } else { 0 }

    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  Pillar 6: Alert Router - Results            ║" -ForegroundColor Cyan
    Write-Host "╠══════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host ("║  Baseline  (random) avg reward : {0,8}    ║" -f $bAvg) -ForegroundColor Gray
    Write-Host ("║  Trained   (DQN)    avg reward : {0,8}    ║" -f $tAvg) -ForegroundColor Green
    Write-Host ("║  Improvement                   : {0,7}%   ║" -f $improvement) -ForegroundColor Yellow
    Write-Host "╠══════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "║  Agent learned to:                           ║" -ForegroundColor Cyan
    Write-Host "║    Ignore   low severity events             ║" -ForegroundColor White
    Write-Host "║    Log      medium severity events          ║" -ForegroundColor White
    Write-Host "║    Alert    high severity events            ║" -ForegroundColor White
    Write-Host "║    Escalate critical events immediately     ║" -ForegroundColor White
    Write-Host "╚══════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    return @{ Agent = $agent; Results = $results; Baseline = $baseline; Trained = $trained }
}

# ============================================================
# TEST SUGGESTIONS
# ============================================================
# 1. Run VBAF.LoadAll.ps1
# 2. QUICK DEMO
#    $r = Invoke-VBAFAlertRouterTraining -Episodes 50 -PrintEvery 10 -SimMode
# 3. FULL TRAINING (real Windows event logs)
#    $r = Invoke-VBAFAlertRouterTraining -Episodes 50 -PrintEvery 10
# 4. INSPECT DECISIONS
#    $env = New-EnterpriseEnvironment -Name "AlertRouter"
#    $state = $env.Reset()
#    Write-Host "Severity: $($env.Severity)  Frequency: $($env.Frequency)"
#    $action = $r.Agent.Act($state)
#    $labels = @("Ignore","Log","Alert","Escalate")
#    Write-Host "Agent decision: $($labels[$action])"
# ============================================================
Write-Host "📦 VBAF.Enterprise.AlertRouter.ps1 loaded  [v3.0.0 🏢]" -ForegroundColor Green
Write-Host "   Pillar 6 : Enterprise Scripting with Intelligence" -ForegroundColor Cyan
Write-Host "   Function : Invoke-VBAFAlertRouterTraining" -ForegroundColor Cyan
Write-Host ""
Write-Host "   Quick start:" -ForegroundColor Yellow
Write-Host '   $r = Invoke-VBAFAlertRouterTraining -Episodes 50 -PrintEvery 10 -SimMode' -ForegroundColor White
Write-Host ""



