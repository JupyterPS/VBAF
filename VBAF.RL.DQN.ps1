#Requires -Version 5.1
<#
.SYNOPSIS
    Deep Q-Network (DQN) Agent for Reinforcement Learning
.DESCRIPTION
    Implements the DQN algorithm combining:
      - Neural Network for Q-value approximation
      - Experience Replay for stable training
      - Target Network for stable Bellman targets
    Requires VBAF.Core.AllClasses.ps1 and VBAF.RL.ExperienceReplay.ps1
    to be loaded first (via VBAF.LoadAll.ps1).
.NOTES
    Part of VBAF - Phase 3 Reinforcement Learning Module
    PS 5.1 compatible - dependency injection pattern used
    to avoid parse-time type resolution errors in classes.
#>
# Set base path
$basePath = $PSScriptRoot

class DQNConfig {
    [int]    $StateSize        = 4
    [int]    $ActionSize       = 2
    [int[]]  $HiddenLayers     = @(64, 64)
    [double] $LearningRate     = 0.001
    [double] $Gamma            = 0.95
    [double] $Epsilon          = 1.0
    [double] $EpsilonMin       = 0.01
    [double] $EpsilonDecay     = 0.995
    [int]    $BatchSize        = 32
    [int]    $MemorySize       = 10000
    [int]    $TargetUpdateFreq = 10
    [string] $Activation       = "relu"
}

# ============================================================
class DQNAgent {
    # [object] used for all cross-file types - PS 5.1 requirement
    [object] $MainNetwork
    [object] $TargetNetwork
    [object] $Memory
    [object] $Config

    [int]    $ActionSize
    [double] $Epsilon
    [int]    $TotalSteps      = 0
    [int]    $TotalEpisodes   = 0
    [int]    $TrainingSteps   = 0
    [double] $LastLoss        = 0.0

    [System.Collections.Generic.List[double]] $EpisodeRewards
    [System.Collections.Generic.List[double]] $LossHistory

    hidden [System.Random] $Rng

    # -------------------------------------------------------
    # Constructor receives pre-built network objects (injected)
    # so this class never needs to reference external types
    # -------------------------------------------------------
    DQNAgent([object]$config, [object]$mainNetwork, [object]$targetNetwork, [object]$memory) {
        $this.Config        = $config
        $this.MainNetwork   = $mainNetwork
        $this.TargetNetwork = $targetNetwork
        $this.Memory        = $memory
        $this.ActionSize    = $config.ActionSize
        $this.Epsilon       = $config.Epsilon
        $this.Rng           = [System.Random]::new()

        $this.EpisodeRewards = [System.Collections.Generic.List[double]]::new()
        $this.LossHistory    = [System.Collections.Generic.List[double]]::new()

        # Sync target = main weights at start
        $this.SyncTargetNetwork()

        Write-Host "✅ DQNAgent created" -ForegroundColor Green
        Write-Host "   State size  : $($config.StateSize)"           -ForegroundColor Cyan
        Write-Host "   Action size : $($config.ActionSize)"          -ForegroundColor Cyan
        Write-Host "   Hidden      : $($config.HiddenLayers -join ' -> ')" -ForegroundColor Cyan
        Write-Host "   Memory      : $($config.MemorySize)"          -ForegroundColor Cyan
        Write-Host "   Batch size  : $($config.BatchSize)"           -ForegroundColor Cyan
    }

    # -------------------------------------------------------
    [void] Remember([double[]]$state, [int]$action, [double]$reward,
                    [double[]]$nextState, [bool]$done) {
        $exp = @{
            State     = $state
            Action    = $action
            Reward    = $reward
            NextState = $nextState
            Done      = $done
        }
        $this.Memory.Add($exp)
        $this.TotalSteps++
    }

    # -------------------------------------------------------
    # Epsilon-greedy action selection
    # -------------------------------------------------------
    [int] Act([double[]]$state) {
        if ($this.Rng.NextDouble() -le $this.Epsilon) {
            return $this.Rng.Next(0, $this.ActionSize)
        }
        $qValues = $this.MainNetwork.Predict($state)
        return [DQNAgent]::ArgMax($qValues)
    }

    # -------------------------------------------------------
    # Greedy action for evaluation (no exploration)
    # -------------------------------------------------------
    [int] Predict([double[]]$state) {
        $qValues = $this.MainNetwork.Predict($state)
        return [DQNAgent]::ArgMax($qValues)
    }

    # -------------------------------------------------------
    [double[]] GetQValues([double[]]$state) {
        return $this.MainNetwork.Predict($state)
    }

    # -------------------------------------------------------
    # Sample batch from memory and train main network
    # -------------------------------------------------------
    [double] Replay() {
        if ($this.Memory.Size() -lt $this.Config.BatchSize) {
            return 0.0
        }

        $batch     = $this.Memory.Sample($this.Config.BatchSize)
        $totalLoss = 0.0

        foreach ($exp in $batch) {
            $state     = $exp.State
            $action    = $exp.Action
            $reward    = $exp.Reward
            $nextState = $exp.NextState
            $done      = $exp.Done

            $target = $this.MainNetwork.Predict($state)

            if ($done) {
                $target[$action] = $reward
            } else {
                $nextQ           = $this.TargetNetwork.Predict($nextState)
                $maxNextQ        = ($nextQ | Measure-Object -Maximum).Maximum
                $target[$action] = $reward + $this.Config.Gamma * $maxNextQ
            }

            $this.MainNetwork.TrainSample($state, $target)
            $this.TrainingSteps++

            $currentQ  = $this.MainNetwork.Predict($state)
            $diff      = $currentQ[$action] - $target[$action]
            $totalLoss += $diff * $diff
        }

        # Decay epsilon
        if ($this.Epsilon -gt $this.Config.EpsilonMin) {
            $this.Epsilon *= $this.Config.EpsilonDecay
            if ($this.Epsilon -lt $this.Config.EpsilonMin) {
                $this.Epsilon = $this.Config.EpsilonMin
            }
        }

        $avgLoss       = $totalLoss / $this.Config.BatchSize
        $this.LastLoss = $avgLoss
        $this.LossHistory.Add($avgLoss)
        return $avgLoss
    }

    # -------------------------------------------------------
    # Copy MainNetwork weights to TargetNetwork
    # -------------------------------------------------------
    [void] SyncTargetNetwork() {
        $state = $this.MainNetwork.ExportState()
        $this.TargetNetwork.ImportState($state)
    }

    # -------------------------------------------------------
    [void] EndEpisode([double]$totalReward) {
        $this.TotalEpisodes++
        $this.EpisodeRewards.Add($totalReward)

        if ($this.TotalEpisodes % $this.Config.TargetUpdateFreq -eq 0) {
            $this.SyncTargetNetwork()
            Write-Host "   🔄 Target network synced (Episode $($this.TotalEpisodes))" -ForegroundColor DarkYellow
        }
    }

    # -------------------------------------------------------
    [hashtable] GetStats() {
        $avgReward = 0.0
        $avgLoss   = 0.0

        if ($this.EpisodeRewards.Count -gt 0) {
            $slice     = $this.EpisodeRewards | Select-Object -Last 100
            $avgReward = ($slice | Measure-Object -Average).Average
        }
        if ($this.LossHistory.Count -gt 0) {
            $slice   = $this.LossHistory | Select-Object -Last 100
            $avgLoss = ($slice | Measure-Object -Average).Average
        }

        return @{
            TotalEpisodes   = $this.TotalEpisodes
            TotalSteps      = $this.TotalSteps
            TrainingSteps   = $this.TrainingSteps
            MemorySize      = $this.Memory.Size()
            Epsilon         = [Math]::Round($this.Epsilon, 4)
            LastLoss        = [Math]::Round($this.LastLoss, 6)
            AvgReward100    = [Math]::Round($avgReward, 3)
            AvgLoss100      = [Math]::Round($avgLoss, 6)
            TargetSyncEvery = $this.Config.TargetUpdateFreq
        }
    }

    # -------------------------------------------------------
    [void] PrintStats() {
        $s = $this.GetStats()
        Write-Host ""
        Write-Host "╔══════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║         DQN Agent Statistics         ║" -ForegroundColor Cyan
        Write-Host "╠══════════════════════════════════════╣" -ForegroundColor Cyan
        Write-Host ("║  Episodes     : {0,-20}║" -f $s.TotalEpisodes)  -ForegroundColor White
        Write-Host ("║  Total Steps  : {0,-20}║" -f $s.TotalSteps)     -ForegroundColor White
        Write-Host ("║  Train Steps  : {0,-20}║" -f $s.TrainingSteps)  -ForegroundColor White
        Write-Host ("║  Memory Used  : {0,-20}║" -f $s.MemorySize)     -ForegroundColor White
        Write-Host ("║  Epsilon      : {0,-20}║" -f $s.Epsilon)        -ForegroundColor Yellow
        Write-Host ("║  Last Loss    : {0,-20}║" -f $s.LastLoss)       -ForegroundColor Magenta
        Write-Host ("║  Avg Reward   : {0,-20}║" -f $s.AvgReward100)  -ForegroundColor Green
        Write-Host ("║  Avg Loss     : {0,-20}║" -f $s.AvgLoss100)    -ForegroundColor Magenta
        Write-Host "╚══════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
    }

    # -------------------------------------------------------
    static [int] ArgMax([double[]]$arr) {
        $best = 0
        for ($i = 1; $i -lt $arr.Length; $i++) {
            if ($arr[$i] -gt $arr[$best]) { $best = $i }
        }
        return $best
    }
}

# ============================================================
# Simple CartPole-style test environment (no external deps)
# ============================================================
class DQNEnvironment {
    [double] $Position
    [double] $Velocity
    [double] $Angle
    [double] $AngularVelocity
    [int]    $Steps
    [int]    $MaxSteps
    hidden [System.Random] $Rng

    DQNEnvironment() {
        $this.MaxSteps = 200
        $this.Rng      = [System.Random]::new()
        $this.Reset()
    }

    [double[]] Reset() {
        $this.Position        = ($this.Rng.NextDouble() - 0.5) * 0.1
        $this.Velocity        = ($this.Rng.NextDouble() - 0.5) * 0.1
        $this.Angle           = ($this.Rng.NextDouble() - 0.5) * 0.1
        $this.AngularVelocity = ($this.Rng.NextDouble() - 0.5) * 0.1
        $this.Steps           = 0
        return $this.GetState()
    }

    [double[]] GetState() {
        return @($this.Position, $this.Velocity, $this.Angle, $this.AngularVelocity)
    }

    [hashtable] Step([int]$action) {
        $this.Steps++
        $force       = if ($action -eq 1) { 1.0 } else { -1.0 }
        $gravity     = 9.8
        $cartMass    = 1.0
        $poleMass    = 0.1
        $totalMass   = $cartMass + $poleMass
        $halfLen     = 0.25
        $dt          = 0.02

        $cosA  = [Math]::Cos($this.Angle)
        $sinA  = [Math]::Sin($this.Angle)
        $temp  = ($force + $poleMass * $halfLen * $this.AngularVelocity * $this.AngularVelocity * $sinA) / $totalMass
        $aAcc  = ($gravity * $sinA - $cosA * $temp) / ($halfLen * (4.0/3.0 - $poleMass * $cosA * $cosA / $totalMass))
        $acc   = $temp - $poleMass * $halfLen * $aAcc * $cosA / $totalMass

        $this.Position        += $dt * $this.Velocity
        $this.Velocity        += $dt * $acc
        $this.Angle           += $dt * $this.AngularVelocity
        $this.AngularVelocity += $dt * $aAcc

        $done   = ($this.Steps -ge $this.MaxSteps) -or
                  ([Math]::Abs($this.Position) -gt 2.4) -or
                  ([Math]::Abs($this.Angle)    -gt 0.21)
        $reward = if (-not $done) { 1.0 } else { 0.0 }

        return @{ NextState = $this.GetState(); Reward = $reward; Done = $done }
    }
}

# ============================================================
# TRAINING RUNNER
# Types are instantiated HERE (script level) where NeuralNetwork
# and ExperienceReplay are already loaded by LoadAll.ps1
# Then injected into DQNAgent constructor.
# ============================================================
function Invoke-DQNTraining {
    param(
        [int]    $Episodes    = 100,
        [int]    $PrintEvery  = 10,
        [switch] $Quiet,
        [switch] $FastMode
    )

    # ---- Settings ----
    $hiddenLayers  = @(64, 64)
    $batchSize     = 32
    $maxSteps      = 200
    $replayEvery   = 4        # Only train every N steps (huge speed win)

    if ($FastMode) {
        $hiddenLayers = @(16, 16)
        $batchSize    = 16
        $maxSteps     = 30
        $replayEvery  = 4
        if ($Episodes -eq 100) { $Episodes  = 50 }
        if ($PrintEvery -eq 10) { $PrintEvery = 5 }
        Write-Host ""
        Write-Host "⚡ FAST MODE ENABLED" -ForegroundColor Yellow
        Write-Host "   Hidden   : 16 -> 16" -ForegroundColor Yellow
        Write-Host "   Batch    : $batchSize" -ForegroundColor Yellow
        Write-Host "   MaxSteps : $maxSteps"  -ForegroundColor Yellow
        Write-Host "   Episodes : $Episodes"  -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "🚀 VBAF DQN Training Started" -ForegroundColor Green
    Write-Host "   Episodes: $Episodes"        -ForegroundColor Cyan
    Write-Host ""

    # ---- Config ----
    $config                  = [DQNConfig]::new()
    $config.StateSize        = 4
    $config.ActionSize       = 2
    $config.HiddenLayers     = $hiddenLayers
    $config.LearningRate     = 0.001
    $config.Gamma            = 0.95
    $config.Epsilon          = 1.0
    $config.EpsilonMin       = 0.01
    $config.EpsilonDecay     = 0.995
    $config.BatchSize        = $batchSize
    $config.MemorySize       = 5000
    $config.TargetUpdateFreq = 10
    # ---- Build layer array ----
    $layers = [System.Collections.Generic.List[int]]::new()
    $layers.Add($config.StateSize)
    foreach ($h in $config.HiddenLayers) { $layers.Add($h) }
    $layers.Add($config.ActionSize)
    $layerArray = $layers.ToArray()

    # ---- Instantiate at script level (PS 5.1 safe) ----
    $mainNetwork   = [NeuralNetwork]::new($layerArray, $config.LearningRate)
    $targetNetwork = [NeuralNetwork]::new($layerArray, $config.LearningRate)
    $memory        = [ExperienceReplay]::new($config.MemorySize)

    $agent = [DQNAgent]::new($config, $mainNetwork, $targetNetwork, $memory)

    $env          = [DQNEnvironment]::new()
    $env.MaxSteps = $maxSteps

    $bestReward = 0.0
    $stepCount  = 0

    for ($ep = 1; $ep -le $Episodes; $ep++) {
        $state       = $env.Reset()
        $totalReward = 0.0
        $done        = $false

        while (-not $done) {
            $action  = $agent.Act($state)
            $result  = $env.Step($action)
            $ns      = $result.NextState
            $reward  = $result.Reward
            $done    = $result.Done

            $agent.Remember($state, $action, $reward, $ns, $done)
            $stepCount++

            # Only replay every N steps - massive speed improvement
            if ($stepCount % $replayEvery -eq 0) {
                $agent.Replay()
            }

            $state        = $ns
            $totalReward += $reward
        }

        $agent.EndEpisode($totalReward)
        if ($totalReward -gt $bestReward) { $bestReward = $totalReward }

        if (-not $Quiet -and ($ep % $PrintEvery -eq 0)) {
            $stats = $agent.GetStats()
            Write-Host ("  Ep {0,4}  Reward: {1,5:F0}  Best: {2,5:F0}  e: {3:F3}  Loss: {4:F5}  Mem: {5}" -f `
                $ep, $totalReward, $bestReward,
                $stats.Epsilon, $stats.LastLoss, $stats.MemorySize) -ForegroundColor White
        }
    }

    Write-Host ""
    Write-Host "✅ Training Complete!" -ForegroundColor Green
    $agent.PrintStats()
    ,$agent  # comma operator forces return as single object in PS 5.1
}

# ============================================================
# TEST SUGGESTIONS
# ============================================================
# 1. BASIC LOAD TEST
#    Run VBAF.LoadAll.ps1 - should see "📦 VBAF.RL.DQN.ps1 loaded"
#
# 2. FAST SMOKE TEST (seconds)
#    $agent = (Invoke-DQNTraining -Episodes 5 -PrintEvery 1 -FastMode)[-1]
#    Verify: DQNAgent created, episodes complete, stats print
#
# 3. STANDARD FAST TRAINING (2-3 minutes)
#    $agent = (Invoke-DQNTraining -Episodes 50 -PrintEvery 5 -FastMode)[-1]
#    Expect: Epsilon decays 1.0 -> ~0.24, Avg Reward > 15
#
# 4. BENCHMARK AGAINST RANDOM (requires VBAF.RL.Environment.ps1)
#    $env = New-VBAFEnvironment -Name "CartPole" -MaxSteps 200
#    Invoke-VBAFBenchmark -Agent $agent -Environment $env -Episodes 10 -Label "DQN vs CartPole"
#    Invoke-VBAFBenchmark -Environment $env -Episodes 10 -Label "Random Baseline"
#    Expect: DQN Agent type shows as DQNAgent
#
# 5. INSPECT AGENT STATE
#    $agent.GetStats()
#    $agent.PrintStats()
#    $agent.Epsilon          # should be near EpsilonMin after full training
#    $agent.Memory.Size()    # should be > BatchSize (32) before replay kicks in
#
# 6. GET Q-VALUES FOR A STATE
#    $state = @(0.1, 0.0, 0.05, 0.0)   # sample CartPole state
#    $agent.GetQValues($state)           # shows Q-value for each action
#    $agent.Predict($state)              # greedy action (0 or 1)
#
# 7. COMPARE ALGORITHMS (after training PPO and A3C too)
#    $dqn = (Invoke-DQNTraining -Episodes 50 -PrintEvery 50 -FastMode -Quiet)[-1]
#    $env = New-VBAFEnvironment -Name "CartPole" -MaxSteps 200
#    Invoke-VBAFBenchmark -Agent $dqn -Environment $env -Episodes 20 -Label "DQN"
# ============================================================
Write-Host "📦 VBAF.RL.DQN.ps1 loaded" -ForegroundColor Green
Write-Host "   Classes : DQNConfig, DQNAgent, DQNEnvironment" -ForegroundColor Cyan
Write-Host "   Function: Invoke-DQNTraining"                  -ForegroundColor Cyan
Write-Host ""
Write-Host "   Quick start:"                                                           -ForegroundColor Yellow
Write-Host '   $agent = (Invoke-DQNTraining -Episodes 100 -PrintEvery 10)[-1]'              -ForegroundColor White
Write-Host '   $agent = (Invoke-DQNTraining -Episodes 50 -PrintEvery 5 -FastMode)[-1]'      -ForegroundColor White
Write-Host '   $agent.PrintStats()'                                                    -ForegroundColor White
Write-Host ""
