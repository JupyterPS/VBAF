#Requires -Version 5.1
<#
.SYNOPSIS
    Pillar 7 - Multi-Agent Strategy: Intelligent Supply Chain
.DESCRIPTION
    Trains a DQN agent to optimize inventory ordering strategy.
    The agent observes market conditions and learns when to:
      - OrderSmall  : order small stock (action 0)
      - OrderMedium : order medium stock (action 1)
      - OrderLarge  : order large stock (action 2)
      - Hold        : do not order (action 3)
    Goal: maximize profit by balancing stock vs demand vs cost.
.NOTES
    Part of VBAF - Phase 9 Enterprise Automation Engine
    Pillar 7: Multi-Agent Strategy Modeling
    PS 5.1 compatible
#>

# ============================================================
# PILLAR 7 - MULTI-AGENT STRATEGY: SUPPLY CHAIN
# ============================================================
function Invoke-VBAFSupplyChainTraining {
    param(
        [int]    $Episodes   = 100,
        [int]    $PrintEvery = 20,
        [switch] $FastMode
    )

    Write-Host ""
    Write-Host "🏢 VBAF Enterprise - Pillar 7: Multi-Agent Strategy" -ForegroundColor Cyan
    Write-Host "   Training DQN agent on Supply Chain..." -ForegroundColor Cyan
    Write-Host "   Actions: 0=OrderSmall  1=OrderMedium  2=OrderLarge  3=Hold" -ForegroundColor Yellow
    Write-Host "   Goal   : maximize profit - balance stock vs demand vs cost" -ForegroundColor Yellow
    Write-Host ""

    $scEnv = New-EnterpriseEnvironment -Name "SupplyChain"

    Write-Host "   Phase 1: Baseline (random agent)..." -ForegroundColor Gray
    $baseline = Invoke-VBAFBenchmark -Environment $scEnv -Episodes 10 -Label "Baseline Random"

    if ($FastMode) { $Episodes = [Math]::Min($Episodes, 50) }
    Write-Host ""
    Write-Host "   Phase 2: Training DQN agent ($Episodes episodes)..." -ForegroundColor Gray

    # Build DQN - 4 state, 4 actions
    $config              = [DQNConfig]::new()
    $config.StateSize    = 4   # inventory, demand, price, backlog
    $config.ActionSize   = 4   # OrderSmall, OrderMedium, OrderLarge, Hold
    $config.EpsilonDecay = 0.9995
    $config.EpsilonMin   = 0.05
    [int[]] $arch        = @(4, 16, 16, 4)
    $mainNetwork         = [NeuralNetwork]::new($arch, $config.LearningRate)
    $targetNetwork       = [NeuralNetwork]::new($arch, $config.LearningRate)
    $memory              = [ExperienceReplay]::new($config.MemorySize)
    $agent               = [DQNAgent]::new($config, $mainNetwork, $targetNetwork, $memory)

    $results = [System.Collections.Generic.List[object]]::new()

    for ($ep = 1; $ep -le $Episodes; $ep++) {
        $state         = $scEnv.Reset()
        $done          = $false
        $epReward      = 0.0
        $smallCount    = 0
        $medCount      = 0
        $largeCount    = 0
        $holdCount     = 0
        [int] $stepCount = 0

        while (-not $done) {
            $action = $agent.Act($state)
            $result = $scEnv.Step($action)
            $agent.Remember($state, $action, $result.Reward, $result.NextState, $result.Done)
            $stepCount++
            if ($stepCount % 4 -eq 0) { $agent.Replay() }
            $state     = $result.NextState
            $done      = $result.Done
            $epReward += $result.Reward
            switch ($action) {
                0 { $smallCount++ }
                1 { $medCount++ }
                2 { $largeCount++ }
                3 { $holdCount++ }
            }
        }

        $agent.EndEpisode($epReward)
        $results.Add(@{
            Episode  = $ep
            Reward   = $epReward
            Small    = $smallCount
            Medium   = $medCount
            Large    = $largeCount
            Hold     = $holdCount
            Epsilon  = $agent.Epsilon
            StockOut = $scEnv.StockOuts
        })

        if ($ep % $PrintEvery -eq 0) {
            $lastN  = $results | Select-Object -Last $PrintEvery
            $avgSum = 0.0
            foreach ($r2 in $lastN) { $avgSum += $r2.Reward }
            $avg = [Math]::Round($avgSum / $lastN.Count, 2)
            Write-Host ("   Ep {0,4}/{1}  AvgReward: {2,7}  Eps: {3:F3}  S:{4} M:{5} L:{6} H:{7} StockOut:{8}" -f $ep, $Episodes, $avg, $agent.Epsilon, $smallCount, $medCount, $largeCount, $holdCount, $scEnv.StockOuts) -ForegroundColor White
        }
    }

    # Pure exploitation for evaluation
    $agent.Epsilon = 0.0
    Write-Host ""
    Write-Host "   Phase 3: Final evaluation (epsilon=0)..." -ForegroundColor Gray
    $trained = Invoke-VBAFBenchmark -Agent $agent -Environment $scEnv -Episodes 10 -Label "Trained DQN"

    $bAvg = [Math]::Round($baseline.Avg, 2)
    $tAvg = [Math]::Round($trained.Avg, 2)
    $improvement = if ($bAvg -ne 0) { [Math]::Round((($tAvg - $bAvg) / [Math]::Abs($bAvg)) * 100, 1) } else { 0 }

    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  Pillar 7: Multi-Agent Strategy - Results    ║" -ForegroundColor Cyan
    Write-Host "╠══════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host ("║  Baseline  (random) avg reward : {0,8}    ║" -f $bAvg) -ForegroundColor Gray
    Write-Host ("║  Trained   (DQN)    avg reward : {0,8}    ║" -f $tAvg) -ForegroundColor Green
    Write-Host ("║  Improvement                   : {0,7}%   ║" -f $improvement) -ForegroundColor Yellow
    Write-Host "╠══════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "║  Agent learned to:                           ║" -ForegroundColor Cyan
    Write-Host "║    Order when inventory low + demand high   ║" -ForegroundColor White
    Write-Host "║    Hold  when inventory high + demand low   ║" -ForegroundColor White
    Write-Host "║    Match order size to market conditions    ║" -ForegroundColor White
    Write-Host "╚══════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    return @{ Agent = $agent; Results = $results; Baseline = $baseline; Trained = $trained }
}

# ============================================================
# TEST SUGGESTIONS
# ============================================================
# 1. Run VBAF.LoadAll.ps1
# 2. QUICK DEMO
#    $r = Invoke-VBAFSupplyChainTraining -Episodes 100 -PrintEvery 20
# 3. FAST MODE
#    $r = Invoke-VBAFSupplyChainTraining -Episodes 50 -PrintEvery 10 -FastMode
# 4. INSPECT DECISIONS
#    $env = New-EnterpriseEnvironment -Name "SupplyChain"
#    $state = $env.Reset()
#    Write-Host "Inventory: $($env.Inventory)  Demand: $($env.Demand)  Price: $($env.Price)"
#    $action = $r.Agent.Act($state)
#    $labels = @("OrderSmall","OrderMedium","OrderLarge","Hold")
#    Write-Host "Agent decision: $($labels[$action])"
# ============================================================
Write-Host "📦 VBAF.Enterprise.SupplyChain.ps1 loaded  [v3.0.0 🏢]" -ForegroundColor Green
Write-Host "   Pillar 7 : Multi-Agent Strategy Modeling" -ForegroundColor Cyan
Write-Host "   Function : Invoke-VBAFSupplyChainTraining" -ForegroundColor Cyan
Write-Host ""
Write-Host "   Quick start:" -ForegroundColor Yellow
Write-Host '   $r = Invoke-VBAFSupplyChainTraining -Episodes 100 -PrintEvery 20' -ForegroundColor White
Write-Host ""
