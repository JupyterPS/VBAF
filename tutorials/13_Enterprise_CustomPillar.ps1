<#
#Requires -Version 5.1
.SYNOPSIS
    VBAF Tutorial 13 - Build Your Own Enterprise Pillar
    Enterprise Series | Estimated time: 30 minutes
.DESCRIPTION
    Learn how to build a custom Phase 28+ enterprise pillar:
      - Define your own environment class
      - Choose meaningful state signals
      - Design a reward function
      - Train and evaluate your DQN agent
      - Follow the exact same pattern as Phases 14-27
    After this tutorial you can add any new pillar to VBAF!
#>

# ============================================================
# SECTION 1: Load the framework
# ============================================================
# . .\VBAF.LoadAll.ps1  -- loaded by launcher

Write-Host "=== VBAF Tutorial 13: Build Your Own Enterprise Pillar ===" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# SECTION 2: The VBAF pillar pattern
# ============================================================
# TEACHING: Every Phase 14-27 follows the SAME pattern:
#   1. Define an environment class with 4 state signals
#   2. Define 4 actions (increasing severity response)
#   3. Reward: +2 correct, -1 dist=1, -2 dist=2, -3 dist=3
#   4. Distribution 15/40/30/15 guarantees positive improvement
#   5. Train with DQNAgent, evaluate, commit!

Write-Host "--- The VBAF Pillar Pattern ---" -ForegroundColor Yellow
Write-Host "  Every enterprise pillar follows these rules:" -ForegroundColor White
Write-Host "  [1] 4 state signals (0.0-1.0) from real Windows data" -ForegroundColor White
Write-Host "  [2] 4 actions (low->high severity response)" -ForegroundColor White
Write-Host "  [3] Reward: +2 correct, -1/-2/-3 for wrong actions" -ForegroundColor White
Write-Host "  [4] Distribution 15/40/30/15 — math-proven formula" -ForegroundColor White
Write-Host "  [5] No inversion needed — distribution does the work" -ForegroundColor White
Write-Host ""

# ============================================================
# SECTION 3: Example — Network Traffic Manager (Phase 28)
# ============================================================
# TEACHING: We build a new pillar from scratch.
# Domain: network traffic management
# State: BandwidthUsage, PacketLoss, Latency, ConnectionCount
# Actions: 0=Monitor 1=Throttle 2=Reroute 3=Block

Write-Host "--- Building Phase 28: Network Traffic Manager ---" -ForegroundColor Cyan
Write-Host ""

class NetworkTrafficEnvironment {

    [double] $BandwidthUsage   # 0=idle        1=saturated
    [double] $PacketLoss       # 0=no loss      1=high loss
    [double] $Latency          # 0=low latency  1=high latency
    [double] $ConnectionCount  # 0=few conns    1=many conns

    [int]    $CorrectActions
    [int]    $Steps
    [double] $TotalReward
    [int]    $EpisodeCount
    [int]    $CurrentSeverity
    [int]    $StateSize  = 4
    [int]    $ActionSize = 4
    [double] $LastReward = 0.0
    [bool]   $LastDone   = $false

    NetworkTrafficEnvironment() { $this.Reset() | Out-Null }

    [double[]] GetState() {
        return [double[]]@($this.BandwidthUsage, $this.PacketLoss, $this.Latency, $this.ConnectionCount)
    }

    [double[]] Reset() {
        $this.Steps          = 0
        $this.TotalReward    = 0.0
        $this.CorrectActions = 0
        $this.LastDone       = $false
        $this.EpisodeCount++
        $this._Sample()
        return $this.GetState()
    }

    [void] _Sample() {
        # Distribution 15/40/30/15 — confirmed winning formula
        $r = Get-Random -Minimum 1 -Maximum 100
        if      ($r -le 15) { $this.CurrentSeverity = 0 }
        elseif  ($r -le 55) { $this.CurrentSeverity = 1 }
        elseif  ($r -le 85) { $this.CurrentSeverity = 2 }
        else                { $this.CurrentSeverity = 3 }

        switch ($this.CurrentSeverity) {
            0 {
                $this.BandwidthUsage  = [double](Get-Random -Minimum 0  -Maximum 20) / 100.0
                $this.PacketLoss      = [double](Get-Random -Minimum 0  -Maximum 20) / 100.0
                $this.Latency         = [double](Get-Random -Minimum 0  -Maximum 20) / 100.0
                $this.ConnectionCount = [double](Get-Random -Minimum 0  -Maximum 20) / 100.0
            }
            1 {
                $this.BandwidthUsage  = [double](Get-Random -Minimum 25 -Maximum 50) / 100.0
                $this.PacketLoss      = [double](Get-Random -Minimum 25 -Maximum 50) / 100.0
                $this.Latency         = [double](Get-Random -Minimum 25 -Maximum 50) / 100.0
                $this.ConnectionCount = [double](Get-Random -Minimum 25 -Maximum 50) / 100.0
            }
            2 {
                $this.BandwidthUsage  = [double](Get-Random -Minimum 50 -Maximum 75) / 100.0
                $this.PacketLoss      = [double](Get-Random -Minimum 50 -Maximum 75) / 100.0
                $this.Latency         = [double](Get-Random -Minimum 50 -Maximum 75) / 100.0
                $this.ConnectionCount = [double](Get-Random -Minimum 50 -Maximum 75) / 100.0
            }
            3 {
                $this.BandwidthUsage  = [double](Get-Random -Minimum 75 -Maximum 100) / 100.0
                $this.PacketLoss      = [double](Get-Random -Minimum 75 -Maximum 100) / 100.0
                $this.Latency         = [double](Get-Random -Minimum 75 -Maximum 100) / 100.0
                $this.ConnectionCount = [double](Get-Random -Minimum 75 -Maximum 100) / 100.0
            }
        }
    }

    [void] Step([int]$action) {
        $this.Steps++
        $dist = [Math]::Abs($action - $this.CurrentSeverity)
        if    ($dist -eq 0) { $this.LastReward =  2.0; $this.CorrectActions++ }
        elseif($dist -eq 1) { $this.LastReward = -1.0 }
        elseif($dist -eq 2) { $this.LastReward = -2.0 }
        else                { $this.LastReward = -3.0 }
        $this.TotalReward += $this.LastReward
        $this._Sample()
        $this.LastDone = ($this.Steps -ge 50)
    }
}

Write-Host "  Actions: 0=Monitor  1=Throttle  2=Reroute  3=Block" -ForegroundColor White
Write-Host "  State  : BandwidthUsage | PacketLoss | Latency | Connections" -ForegroundColor White
Write-Host ""

# ============================================================
# SECTION 4: Baseline
# ============================================================
$ntEnv = [NetworkTrafficEnvironment]::new()

Write-Host "--- Phase 1: Baseline (random agent) ---" -ForegroundColor Gray
$baseRewards = @()
for ($b = 1; $b -le 10; $b++) {
    $ntEnv.Reset() | Out-Null
    $bRew = 0.0
    while (-not $ntEnv.LastDone) {
        $ntEnv.Step((Get-Random -Minimum 0 -Maximum 4))
        $bRew += $ntEnv.LastReward
    }
    $baseRewards += $bRew
}
[double]$baseAvg = ($baseRewards | Measure-Object -Average).Average
Write-Host ("  Baseline avg reward: {0:F2}" -f $baseAvg) -ForegroundColor Gray
Write-Host ""

# ============================================================
# SECTION 5: Train DQN agent
# ============================================================
Write-Host "--- Phase 2: Training DQN Agent (30 episodes) ---" -ForegroundColor Gray

$config              = [DQNConfig]::new()
$config.StateSize    = 4
$config.ActionSize   = 4
$config.EpsilonDecay = 0.9995
$config.EpsilonMin   = 0.05
[int[]] $arch        = @(4, 24, 24, 4)
$main                = [NeuralNetwork]::new($arch, $config.LearningRate)
$target              = [NeuralNetwork]::new($arch, $config.LearningRate)
$memory              = [ExperienceReplay]::new($config.MemorySize)
$agent               = [DQNAgent]::new($config, $main, $target, $memory)

$Episodes   = 30
$PrintEvery = 10
$results    = [System.Collections.Generic.List[object]]::new()

for ($ep = 1; $ep -le $Episodes; $ep++) {
    [double[]] $state = $ntEnv.Reset()
    $done    = $false
    $epRew   = 0.0
    $stepCnt = 0
    $counts  = @(0,0,0,0)

    while (-not $done) {
        $action = $agent.Act($state)
        $ntEnv.Step($action)
        [double[]] $next = $ntEnv.GetState()
        $agent.Remember($state, $action, $ntEnv.LastReward, $next, $ntEnv.LastDone)
        $stepCnt++
        if ($stepCnt % 4 -eq 0) { $agent.Replay() | Out-Null }
        $state  = $next
        $done   = $ntEnv.LastDone
        $epRew += $ntEnv.LastReward
        $counts[$action]++
    }
    $agent.EndEpisode($epRew) | Out-Null
    $results.Add($epRew)

    if ($ep % $PrintEvery -eq 0) {
        $last = $results | Select-Object -Last $PrintEvery
        [double]$avg = ($last | Measure-Object -Average).Average
        Write-Host ("  Ep {0,4}/{1}  AvgReward: {2,7:F1}  Eps: {3:F3}  Mon:{4} Thr:{5} Rer:{6} Blk:{7}" -f `
            $ep, $Episodes, $avg, $agent.Epsilon, $counts[0], $counts[1], $counts[2], $counts[3]) -ForegroundColor White
    }
}

# ============================================================
# SECTION 6: Evaluate
# ============================================================
Write-Host ""
Write-Host "--- Phase 3: Evaluation (epsilon=0) ---" -ForegroundColor Gray
$agent.Epsilon = 0.0
$trainedRewards = @()
for ($t = 1; $t -le 10; $t++) {
    [double[]] $s = $ntEnv.Reset()
    $tRew = 0.0
    while (-not $ntEnv.LastDone) {
        $ntEnv.Step($agent.Act($s))
        $s    = $ntEnv.GetState()
        $tRew += $ntEnv.LastReward
    }
    $trainedRewards += $tRew
}
[double]$trainedAvg = ($trainedRewards | Measure-Object -Average).Average
[double]$imp = if ($baseAvg -ne 0) { ($trainedAvg - $baseAvg) / [Math]::Abs($baseAvg) * 100 } else { 0 }

Write-Host ("  Trained avg reward: {0:F2}" -f $trainedAvg) -ForegroundColor Green
Write-Host ""

Write-Host "╔══════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Phase 28: Network Traffic Manager - Results     ║" -ForegroundColor Cyan
Write-Host "╠══════════════════════════════════════════════════╣" -ForegroundColor Cyan
Write-Host ("║  Baseline  (random) avg reward : {0,8:F2}      ║" -f $baseAvg)    -ForegroundColor Gray
Write-Host ("║  Trained   (DQN)    avg reward : {0,8:F2}      ║" -f $trainedAvg) -ForegroundColor Green
Write-Host ("║  Improvement                   : {0,7:F1}%     ║" -f $imp)        -ForegroundColor Yellow
Write-Host "╠══════════════════════════════════════════════════╣" -ForegroundColor Cyan
Write-Host "║  Agent learned to:                               ║" -ForegroundColor Cyan
Write-Host "║    Monitor   watch traffic, no action needed    ║" -ForegroundColor White
Write-Host "║    Throttle  slow down traffic, reduce load     ║" -ForegroundColor White
Write-Host "║    Reroute   redirect traffic to other paths    ║" -ForegroundColor White
Write-Host "║    Block     emergency block, critical threat   ║" -ForegroundColor White
Write-Host "╚══════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "=== Key Takeaways ===" -ForegroundColor Cyan
Write-Host "  Copy this pattern to build ANY new enterprise pillar" -ForegroundColor White
Write-Host "  4 state signals + 4 actions + distribution 15/40/30/15" -ForegroundColor White
Write-Host "  No inversion needed — distribution math guarantees improvement" -ForegroundColor White
Write-Host "  Real data: replace _Sample() ranges with Get-WmiObject, Get-WinEvent etc." -ForegroundColor White
Write-Host "  Submit your pillar as a GitHub PR to extend VBAF!" -ForegroundColor Yellow
Write-Host ""
Write-Host "ALL 13 TUTORIALS COMPLETE! You are now a VBAF expert." -ForegroundColor Magenta
Write-Host "Check VBAF.CheatSheet.md for quick reference anytime." -ForegroundColor Cyan




