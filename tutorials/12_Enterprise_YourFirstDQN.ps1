<#
#Requires -Version 5.1
.SYNOPSIS
    VBAF Tutorial 12 - Your First DQN Agent
    Enterprise Series | Estimated time: 30 minutes
.DESCRIPTION
    Learn how to:
      - Understand reinforcement learning vs supervised learning
      - Build a simple environment for a DQN agent
      - Train a DQN agent from scratch
      - Read and interpret training progress
      - Understand reward, epsilon and target network sync
    This is the bridge from ML to the enterprise automation engine!
#>

# ============================================================
# SECTION 1: Load the framework
# ============================================================
. .\VBAF.LoadAll.ps1

Write-Host "=== VBAF Tutorial 12: Your First DQN Agent ===" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# SECTION 2: RL vs Supervised Learning
# ============================================================
# TEACHING: Supervised learning: we give the model (X, y) pairs.
#           Reinforcement learning: the agent learns by DOING.
#           It takes actions, gets rewards, and improves over time.
#           No labels needed — just a reward signal!

Write-Host "--- Reinforcement Learning vs Supervised Learning ---" -ForegroundColor Yellow
Write-Host "  Supervised  : data=(X,y) -> model learns mapping" -ForegroundColor White
Write-Host "  Reinforcement: agent takes action -> gets reward -> improves" -ForegroundColor White
Write-Host "  Key concepts:" -ForegroundColor White
Write-Host "    State   : what the agent observes (e.g. server load)" -ForegroundColor White
Write-Host "    Action  : what the agent can do (e.g. scale up/down)" -ForegroundColor White
Write-Host "    Reward  : feedback signal (+good, -bad)" -ForegroundColor White
Write-Host "    Epsilon : exploration rate (1=random, 0=exploit learned policy)" -ForegroundColor White
Write-Host ""

# ============================================================
# SECTION 3: Build a simple environment
# ============================================================
# TEACHING: The environment defines the problem.
# State: server load (0-1), response time (0-1)
# Actions: 0=Idle, 1=Monitor, 2=ScaleUp, 3=ScaleDown
# Reward: +2 if correct action, -1 to -3 if wrong

Write-Host "--- Building a Simple Server Management Environment ---" -ForegroundColor Yellow

class ServerEnvironment {
    [double] $Load         # 0=idle  1=overloaded
    [double] $ResponseTime # 0=fast  1=slow
    [int]    $Steps
    [double] $LastReward
    [bool]   $LastDone
    [int]    $CurrentSeverity
    [int]    $StateSize  = 2
    [int]    $ActionSize = 4

    ServerEnvironment() { $this.Reset() | Out-Null }

    [double[]] GetState() { return [double[]]@($this.Load, $this.ResponseTime) }

    [double[]] Reset() {
        $this.Steps    = 0
        $this.LastDone = $false
        $this._Sample()
        return $this.GetState()
    }

    [void] _Sample() {
        $r = Get-Random -Minimum 1 -Maximum 100
        if      ($r -le 25) { $this.CurrentSeverity = 0 }
        elseif  ($r -le 55) { $this.CurrentSeverity = 1 }
        elseif  ($r -le 85) { $this.CurrentSeverity = 2 }
        else                { $this.CurrentSeverity = 3 }
        switch ($this.CurrentSeverity) {
            0 { $this.Load = (Get-Random -Min 0  -Max 20)  / 100.0; $this.ResponseTime = (Get-Random -Min 0  -Max 20)  / 100.0 }
            1 { $this.Load = (Get-Random -Min 25 -Max 50)  / 100.0; $this.ResponseTime = (Get-Random -Min 25 -Max 50)  / 100.0 }
            2 { $this.Load = (Get-Random -Min 50 -Max 75)  / 100.0; $this.ResponseTime = (Get-Random -Min 50 -Max 75)  / 100.0 }
            3 { $this.Load = (Get-Random -Min 75 -Max 100) / 100.0; $this.ResponseTime = (Get-Random -Min 75 -Max 100) / 100.0 }
        }
    }

    [void] Step([int]$action) {
        $this.Steps++
        $optimal = $this.CurrentSeverity
        $dist = [Math]::Abs($action - $optimal)
        if    ($dist -eq 0) { $this.LastReward =  2.0 }
        elseif($dist -eq 1) { $this.LastReward = -1.0 }
        elseif($dist -eq 2) { $this.LastReward = -2.0 }
        else                { $this.LastReward = -3.0 }
        $this._Sample()
        $this.LastDone = ($this.Steps -ge 100)
    }
}

$env = [ServerEnvironment]::new()
Write-Host "  Environment created!" -ForegroundColor Green
Write-Host "  State  : [Load, ResponseTime] (0.0 - 1.0)" -ForegroundColor White
Write-Host "  Actions: 0=Idle  1=Monitor  2=ScaleUp  3=ScaleDown" -ForegroundColor White
Write-Host "  Reward : +2 correct  -1 dist=1  -2 dist=2  -3 dist=3" -ForegroundColor White
Write-Host ""

# ============================================================
# SECTION 4: Baseline — random agent
# ============================================================
Write-Host "--- Baseline: Random Agent ---" -ForegroundColor Yellow
$baseRewards = @()
for ($b = 1; $b -le 10; $b++) {
    $env.Reset() | Out-Null
    $bRew = 0.0
    while (-not $env.LastDone) {
        $env.Step((Get-Random -Minimum 0 -Maximum 4))
        $bRew += $env.LastReward
    }
    $baseRewards += $bRew
}
[double]$baseAvg = ($baseRewards | Measure-Object -Average).Average
Write-Host ("  Random agent avg reward: {0:F2}" -f $baseAvg) -ForegroundColor Gray
Write-Host ""

# ============================================================
# SECTION 5: Train a DQN agent
# ============================================================
# TEACHING: DQN = Deep Q-Network.
# Uses a neural network to approximate the Q-function:
#   Q(state, action) = expected future reward
# Epsilon starts high (explore) and decays (exploit).
# Target network syncs every N episodes for stability.

Write-Host "--- Training DQN Agent ---" -ForegroundColor Yellow

$config              = [DQNConfig]::new()
$config.StateSize    = 2
$config.ActionSize   = 4
$config.EpsilonDecay = 0.9995
$config.EpsilonMin   = 0.05
[int[]] $arch        = @(2, 16, 16, 4)
$main                = [NeuralNetwork]::new($arch, $config.LearningRate)
$target              = [NeuralNetwork]::new($arch, $config.LearningRate)
$memory              = [ExperienceReplay]::new($config.MemorySize)
$agent               = [DQNAgent]::new($config, $main, $target, $memory)

Write-Host "✅ DQN Agent created" -ForegroundColor Green
Write-Host "   Neural net: 2 -> 16 -> 16 -> 4" -ForegroundColor White
Write-Host ""

$Episodes   = 30
$PrintEvery = 10
$results    = [System.Collections.Generic.List[object]]::new()

for ($ep = 1; $ep -le $Episodes; $ep++) {
    [double[]] $state = $env.Reset()
    $done    = $false
    $epRew   = 0.0
    $stepCnt = 0

    while (-not $done) {
        $action = $agent.Act($state)
        $env.Step($action)
        [double[]] $next = $env.GetState()
        $agent.Remember($state, $action, $env.LastReward, $next, $env.LastDone)
        $stepCnt++
        if ($stepCnt % 4 -eq 0) { $agent.Replay() | Out-Null }
        $state  = $next
        $done   = $env.LastDone
        $epRew += $env.LastReward
    }
    $agent.EndEpisode($epRew) | Out-Null
    $results.Add($epRew)

    if ($ep % $PrintEvery -eq 0) {
        $last   = $results | Select-Object -Last $PrintEvery
        [double]$avg = ($last | Measure-Object -Average).Average
        Write-Host ("  Ep {0,4}/{1}  AvgReward: {2,7:F1}  Epsilon: {3:F3}" -f $ep, $Episodes, $avg, $agent.Epsilon) -ForegroundColor White
    }
}

# ============================================================
# SECTION 6: Evaluate trained agent
# ============================================================
Write-Host ""
Write-Host "--- Evaluating Trained Agent (epsilon=0) ---" -ForegroundColor Yellow
$agent.Epsilon = 0.0
$trainedRewards = @()
for ($t = 1; $t -le 10; $t++) {
    [double[]] $s = $env.Reset()
    $tRew = 0.0
    while (-not $env.LastDone) {
        $env.Step($agent.Act($s))
        $s     = $env.GetState()
        $tRew += $env.LastReward
    }
    $trainedRewards += $tRew
}
[double]$trainedAvg = ($trainedRewards | Measure-Object -Average).Average

[double]$imp = if ($baseAvg -ne 0) { ($trainedAvg - $baseAvg) / [Math]::Abs($baseAvg) * 100 } else { 0 }

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Tutorial 12: DQN Results                        ║" -ForegroundColor Cyan
Write-Host "╠══════════════════════════════════════════════════╣" -ForegroundColor Cyan
Write-Host ("║  Baseline (random) avg reward : {0,8:F2}        ║" -f $baseAvg)    -ForegroundColor Gray
Write-Host ("║  Trained  (DQN)    avg reward : {0,8:F2}        ║" -f $trainedAvg) -ForegroundColor Green
Write-Host ("║  Improvement                  : {0,7:F1}%        ║" -f $imp)       -ForegroundColor Yellow
Write-Host "╠══════════════════════════════════════════════════╣" -ForegroundColor Cyan
Write-Host "║  Agent learned to:                               ║" -ForegroundColor Cyan
Write-Host "║    Idle      low load, fast response            ║" -ForegroundColor White
Write-Host "║    Monitor   moderate load, watch closely       ║" -ForegroundColor White
Write-Host "║    ScaleUp   high load, add resources           ║" -ForegroundColor White
Write-Host "║    ScaleDown overloaded, emergency response     ║" -ForegroundColor White
Write-Host "╚══════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "=== Key Takeaways ===" -ForegroundColor Cyan
Write-Host "  RL agent learns WITHOUT labelled data" -ForegroundColor White
Write-Host "  Epsilon decay: starts exploring, ends exploiting" -ForegroundColor White
Write-Host "  Target network: stabilises training (syncs every N episodes)" -ForegroundColor White
Write-Host "  Reward design is critical — defines what good behaviour means" -ForegroundColor White
Write-Host "  This is exactly how Phases 14-27 work!" -ForegroundColor Yellow
Write-Host ""
Write-Host "Tutorial 12 complete! Try Tutorial 13 next: Custom Enterprise Pillar." -ForegroundColor Green




