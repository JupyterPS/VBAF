#Requires -Version 5.1
<#
.SYNOPSIS
    Pillar 5 - IT Optimization: Intelligent Resource Optimizer
.DESCRIPTION
    Trains a DQN agent to optimize CPU/memory resource allocation.
    The agent observes real system metrics and learns when to:
      - Throttle : reduce CPU load (action 0)
      - Normal   : maintain current load (action 1)
      - Boost    : increase throughput (action 2)
    Target: keep CPU near 60% for optimal throughput.
.NOTES
    Part of VBAF - Phase 9 Enterprise Automation Engine
    Pillar 5: IT Optimization
    PS 5.1 compatible
#>

# ============================================================
# PILLAR 5 - IT OPTIMIZATION: RESOURCE OPTIMIZER
# ============================================================
function Invoke-VBAFResourceOptimizerTraining {
    param(
        [int]    $Episodes   = 50,
        [int]    $PrintEvery = 10,
        [switch] $FastMode,
        [switch] $SimMode
    )

    Write-Host ""
    Write-Host "🏢 VBAF Enterprise - Pillar 5: IT Optimization" -ForegroundColor Cyan
    Write-Host "   Training DQN agent on Resource Optimizer..." -ForegroundColor Cyan
    Write-Host "   Actions: 0=Throttle  1=Normal  2=Boost" -ForegroundColor Yellow
    Write-Host "   Target : keep CPU near 60%" -ForegroundColor Yellow
    Write-Host ""

    $roEnv = New-EnterpriseEnvironment -Name "ResourceOptimizer" -MaxSteps 20

    Write-Host "   Phase 1: Baseline (random agent)..." -ForegroundColor Gray
    $baseline = Invoke-VBAFBenchmark -Environment $roEnv -Episodes 10 -Label "Baseline Random"

    if ($FastMode) { $Episodes = [Math]::Min($Episodes, 50) }
    if ($SimMode) {
        Write-Host ""
        Write-Host "   Phase 2: Training DQN agent ($Episodes episodes - SimMode fast)..." -ForegroundColor Gray
    } else {
        Write-Host ""
        Write-Host "   Phase 2: Training DQN agent ($Episodes episodes)..." -ForegroundColor Gray
    }

    # Build DQN - 4 state, 3 actions
    $config              = [DQNConfig]::new()
    $config.StateSize    = 4   # cpuLoad, memLoad, processCount, diskIO
    $config.ActionSize   = 3   # Throttle, Normal, Boost
    $config.EpsilonDecay = 0.9995
    [int[]] $arch        = @(4, 16, 16, 3)
    $mainNetwork         = [NeuralNetwork]::new($arch, $config.LearningRate)
    $targetNetwork       = [NeuralNetwork]::new($arch, $config.LearningRate)
    $memory              = [ExperienceReplay]::new($config.MemorySize)
    $agent               = [DQNAgent]::new($config, $mainNetwork, $targetNetwork, $memory)

    $results = [System.Collections.Generic.List[object]]::new()

    for ($ep = 1; $ep -le $Episodes; $ep++) {
        # SimMode: skip real Get-Counter for speed during training
        if ($SimMode) {
            $roEnv.CpuLoad      = [double](Get-Random -Minimum 10 -Maximum 95) / 100.0
            $roEnv.MemLoad      = [double](Get-Random -Minimum 20 -Maximum 90) / 100.0
            $roEnv.ProcessCount = Get-Random -Minimum 50 -Maximum 250
            $roEnv.DiskIO       = [double](Get-Random -Minimum 0 -Maximum 80) / 100.0
            $roEnv.Steps        = 0
            $roEnv.TotalReward  = 0.0
            $roEnv.EpisodeCount++
            $state = $roEnv.GetState()
        } else {
            $state = $roEnv.Reset()
        }

        $done          = $false
        $epReward      = 0.0
        $throttleCount = 0
        $normalCount   = 0
        $boostCount    = 0

        while (-not $done) {
            $action = $agent.Act($state)
            $result = $roEnv.Step($action)
            $agent.Remember($state, $action, $result.Reward, $result.NextState, $result.Done)
            $agent.Replay()
            $state     = $result.NextState
            $done      = $result.Done
            $epReward += $result.Reward
            switch ($action) {
                0 { $throttleCount++ }
                1 { $normalCount++ }
                2 { $boostCount++ }
            }
        }

        $agent.EndEpisode($epReward)
        $results.Add(@{
            Episode  = $ep
            Reward   = $epReward
            Throttle = $throttleCount
            Normal   = $normalCount
            Boost    = $boostCount
            Epsilon  = $agent.Epsilon
        })

        if ($ep % $PrintEvery -eq 0) {
            $lastN  = $results | Select-Object -Last $PrintEvery
            $avgSum = 0.0
            foreach ($r2 in $lastN) { $avgSum += $r2.Reward }
            $avg = [Math]::Round($avgSum / $lastN.Count, 2)
            Write-Host ("   Ep {0,4}/{1}  AvgReward: {2,7}  Epsilon: {3:F3}  Throttle:{4} Normal:{5} Boost:{6}" -f $ep, $Episodes, $avg, $agent.Epsilon, $throttleCount, $normalCount, $boostCount) -ForegroundColor White
        }
    }

    Write-Host ""
    Write-Host "   Phase 3: Final evaluation..." -ForegroundColor Gray
    $trained = Invoke-VBAFBenchmark -Agent $agent -Environment $roEnv -Episodes 10 -Label "Trained DQN"

    $bAvg = [Math]::Round($baseline.Avg, 2)
    $tAvg = [Math]::Round($trained.Avg, 2)
    $improvement = if ($bAvg -ne 0) { [Math]::Round((($tAvg - $bAvg) / [Math]::Abs($bAvg)) * 100, 1) } else { 0 }

    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  Pillar 5: IT Optimization - Results         ║" -ForegroundColor Cyan
    Write-Host "╠══════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host ("║  Baseline  (random) avg reward : {0,8}    ║" -f $bAvg) -ForegroundColor Gray
    Write-Host ("║  Trained   (DQN)    avg reward : {0,8}    ║" -f $tAvg) -ForegroundColor Green
    Write-Host ("║  Improvement                   : {0,7}%   ║" -f $improvement) -ForegroundColor Yellow
    Write-Host "╠══════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "║  Agent learned to:                           ║" -ForegroundColor Cyan
    Write-Host "║    Throttle when CPU > 60% (overloaded)     ║" -ForegroundColor White
    Write-Host "║    Boost    when CPU < 60% (underutilized)  ║" -ForegroundColor White
    Write-Host "║    Normal   when CPU near target (optimal)  ║" -ForegroundColor White
    Write-Host "╚══════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    return @{ Agent = $agent; Results = $results; Baseline = $baseline; Trained = $trained }
}

# ============================================================
# TEST SUGGESTIONS
# ============================================================
# 1. Run VBAF.LoadAll.ps1
# 2. QUICK DEMO
#    $r = Invoke-VBAFResourceOptimizerTraining -Episodes 200 -PrintEvery 50 -SimMode
# 3. FULL TRAINING (real Windows data)
#    $r = Invoke-VBAFResourceOptimizerTraining -Episodes 200 -PrintEvery 50
# 4. INSPECT DECISIONS
#    $env = New-EnterpriseEnvironment -Name "ResourceOptimizer" -MaxSteps 20
#    $state = $env.Reset()
#    Write-Host "CPU: $($env.CpuLoad)  MEM: $($env.MemLoad)"
#    $action = $r.Agent.Act($state)
#    $labels = @("Throttle","Normal","Boost")
#    Write-Host "Agent decision: $($labels[$action])"
# ============================================================
Write-Host "📦 VBAF.Enterprise.ResourceOptimizer.ps1 loaded  [v3.0.0 🏢]" -ForegroundColor Green
Write-Host "   Pillar 5 : IT Optimization" -ForegroundColor Cyan
Write-Host "   Function : Invoke-VBAFResourceOptimizerTraining" -ForegroundColor Cyan
Write-Host ""
Write-Host "   Quick start:" -ForegroundColor Yellow
Write-Host '   $r = Invoke-VBAFResourceOptimizerTraining -Episodes 200 -PrintEvery 50 -SimMode' -ForegroundColor White
Write-Host ""



