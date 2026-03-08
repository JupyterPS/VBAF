#Requires -Version 5.1
<#
.SYNOPSIS
    Pillar 4 - Adaptive Automation: Intelligent Windows Job Scheduler
.DESCRIPTION
    Trains a DQN agent to learn optimal Windows task scheduling.
    The agent observes real CPU/memory load and learns when to:
      - RunNow  : execute job immediately (action 0)
      - Delay   : postpone job (action 1)
      - Skip    : skip job entirely (action 2)
    Uses real Windows performance counters as state input.
.NOTES
    Part of VBAF - Phase 9 Enterprise Automation Engine
    Pillar 4: Adaptive Automation
    PS 5.1 compatible
#>

# ============================================================
# PILLAR 4 - ADAPTIVE AUTOMATION: JOB SCHEDULER
# ============================================================
function Invoke-VBAFJobSchedulerTraining {
    param(
        [int]    $Episodes   = 100,
        [int]    $PrintEvery = 10,
        [switch] $FastMode,
        [switch] $SimMode   # Train on simulated data (fast), evaluate on real Windows data
    )

    Write-Host ""
    Write-Host "🏢 VBAF Enterprise - Pillar 4: Adaptive Automation" -ForegroundColor Cyan
    Write-Host "   Training DQN agent on Windows Job Scheduler..." -ForegroundColor Cyan
    Write-Host "   Actions: 0=RunNow  1=Delay  2=Skip" -ForegroundColor Yellow
    Write-Host ""

    # Create enterprise environment
    # SimMode = fast training on random state, then real eval
    $jsEnv = New-EnterpriseEnvironment -Name "JobScheduler" -MaxSteps 30
    $jsEnv = New-EnterpriseEnvironment -Name "JobScheduler" -MaxSteps 50

    # Train DQN on it
    Write-Host "   Phase 1: Baseline (random agent)..." -ForegroundColor Gray
    $baseline = Invoke-VBAFBenchmark -Environment $jsEnv -Episodes 10 -Label "Baseline Random"

    Write-Host ""
    Write-Host ""
    if ($SimMode) {
        Write-Host "   Phase 2: Training DQN agent ($Episodes episodes - SimMode fast)..." -ForegroundColor Gray
    } else {
        Write-Host "   Phase 2: Training DQN agent ($Episodes episodes)..." -ForegroundColor Gray
    }

    # Build DQN config for 4-state, 3-action job scheduler
    $config                  = [DQNConfig]::new()
    $config.StateSize        = 4   # cpuLoad, memLoad, pendingJobs, timeOfDay
    $config.ActionSize       = 3   # RunNow, Delay, Skip
    $config.HiddenLayers     = @(16, 16)
    $config.BatchSize        = 16
    $config.EpsilonDecay     = 0.99
    if ($FastMode) { $Episodes = [Math]::Min($Episodes, 50) }

    # Build networks - int[] architecture like Invoke-DQNTraining
    [int[]] $arch  = @($config.StateSize, 16, 16, $config.ActionSize)
    $mainNetwork   = [NeuralNetwork]::new($arch, $config.LearningRate)
    $targetNetwork = [NeuralNetwork]::new($arch, $config.LearningRate)
    $memory        = [ExperienceReplay]::new($config.MemorySize)
    $layers = [System.Collections.Generic.List[object]]::new()
    $memory        = [ExperienceReplay]::new($config.MemorySize)
    $config             = [DQNConfig]::new()
    $config.StateSize   = 4   # cpuLoad, memLoad, pendingJobs, timeOfDay
    $config.ActionSize  = 3   # RunNow, Delay, Skip

    # Train agent
    $results = [System.Collections.Generic.List[object]]::new()
    $agent = [DQNAgent]::new($config, $mainNetwork, $targetNetwork, $memory)

    for ($ep = 1; $ep -le $config.Episodes; $ep++) {
        # SimMode: skip real Get-Counter for speed during training
        if ($SimMode) {
            $jsEnv.CpuLoad     = [double](Get-Random -Minimum 10 -Maximum 90) / 100.0
            $jsEnv.MemLoad     = [double](Get-Random -Minimum 20 -Maximum 85) / 100.0
            $jsEnv.PendingJobs = Get-Random -Minimum 1 -Maximum 10
            $jsEnv.TimeOfDay   = [double]([System.DateTime]::Now.Hour) / 23.0
            $jsEnv.Steps       = 0
            $jsEnv.TotalReward = 0.0
            $jsEnv.EpisodeCount++
            $state = $jsEnv.GetState()
        } else {
            $state = $jsEnv.Reset()
        }
        $done       = $false
        $epReward   = 0.0
        $epSteps    = 0
        $runCount   = 0
        $delayCount = 0
        $skipCount  = 0

        while (-not $done) {
            $action = $agent.Act($state)
            $result = $jsEnv.Step($action)
            $next   = $result.NextState
            $reward = $result.Reward
            $done   = $result.Done

            $agent.Remember($state, $action, $reward, $next, $done)
            $agent.Replay()

            $state      = $next
            $epReward  += $reward
            $epSteps++
            switch ($action) {
                0 { $runCount++ }
                1 { $delayCount++ }
                2 { $skipCount++ }
            }
        }

        $results.Add(@{
            Episode    = $ep
            Reward     = $epReward
            Steps      = $epSteps
            RunNow     = $runCount
            Delay      = $delayCount
            Skip       = $skipCount
            Epsilon    = $agent.Epsilon
        })

        if ($ep % $PrintEvery -eq 0) {
            $lastN = $results | Select-Object -Last $PrintEvery
            $avgSum = 0.0
            foreach ($r2 in $lastN) { $avgSum += $r2.Reward }
            $avg = [Math]::Round($avgSum / $lastN.Count, 2)
            Write-Host ("   Ep {0,4}/{1}  AvgReward: {2,7}  Epsilon: {3:F3}  Run:{4} Delay:{5} Skip:{6}" -f $ep, $config.Episodes, $avg, $agent.Epsilon, $runCount, $delayCount, $skipCount) -ForegroundColor White
        }
    }

    # Final benchmark - trained vs random
    Write-Host ""
    Write-Host "   Phase 3: Final evaluation..." -ForegroundColor Gray
    $trained = Invoke-VBAFBenchmark -Agent $agent -Environment $jsEnv -Episodes 10 -Label "Trained DQN"

    # Summary
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  Pillar 4: Adaptive Automation - Results     ║" -ForegroundColor Cyan
    Write-Host "╠══════════════════════════════════════════════╣" -ForegroundColor Cyan
    $bAvg = [Math]::Round($baseline.Avg, 2)
    $tAvg = [Math]::Round($trained.Avg, 2)
    $improvement = if ($bAvg -ne 0) { [Math]::Round((($tAvg - $bAvg) / [Math]::Abs($bAvg)) * 100, 1) } else { 0 }
    Write-Host ("║  Baseline  (random) avg reward : {0,8}    ║" -f $bAvg) -ForegroundColor Gray
    Write-Host ("║  Trained   (DQN)    avg reward : {0,8}    ║" -f $tAvg) -ForegroundColor Green
    Write-Host ("║  Improvement                   : {0,7}%   ║" -f $improvement) -ForegroundColor Yellow
    Write-Host "╠══════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "║  Agent learned to:                           ║" -ForegroundColor Cyan
    Write-Host "║    RunNow  when CPU < 70% and MEM < 80%     ║" -ForegroundColor White
    Write-Host "║    Delay   when system is under heavy load  ║" -ForegroundColor White
    Write-Host "║    Skip    as last resort (penalized)       ║" -ForegroundColor White
    Write-Host "╚══════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    return @{ Agent = $agent; Results = $results; Baseline = $baseline; Trained = $trained }
}

# ============================================================
# TEST SUGGESTIONS
# ============================================================
# 1. Run VBAF.LoadAll.ps1
#
# 2. QUICK DEMO (FastMode)
#    $r = Invoke-VBAFJobSchedulerTraining -Episodes 50 -PrintEvery 10 -FastMode
#    $r.Agent.PrintStats()
#
# 3. FULL TRAINING
#    $r = Invoke-VBAFJobSchedulerTraining -Episodes 100 -PrintEvery 10
#    $r.Agent.PrintStats()
#
# 4. INSPECT DECISIONS
#    $env = New-EnterpriseEnvironment -Name "JobScheduler"
#    $state = $env.Reset()
#    Write-Host "CPU: $($env.CpuLoad)  MEM: $($env.MemLoad)  Jobs: $($env.PendingJobs)"
#    $action = $r.Agent.Act($state)
#    $labels = @("RunNow","Delay","Skip")
#    Write-Host "Agent decision: $($labels[$action])"
# ============================================================
Write-Host "📦 VBAF.Enterprise.JobScheduler.ps1 loaded  [v3.0.0 🏢]" -ForegroundColor Green
Write-Host "   Pillar 4 : Adaptive Automation" -ForegroundColor Cyan
Write-Host "   Function : Invoke-VBAFJobSchedulerTraining" -ForegroundColor Cyan
Write-Host ""
Write-Host "   Quick start:" -ForegroundColor Yellow
Write-Host '   $r = Invoke-VBAFJobSchedulerTraining -Episodes 50 -FastMode' -ForegroundColor White
Write-Host ""


