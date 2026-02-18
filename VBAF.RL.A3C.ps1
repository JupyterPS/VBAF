#Requires -Version 5.1
<#
.SYNOPSIS
    Advantage Actor-Critic (A3C) Agent for Reinforcement Learning
.DESCRIPTION
    Implements the A3C algorithm with:
      - Shared Actor-Critic Network : single network, two output heads
      - Advantage estimation        : A(s,a) = R - V(s)
      - Entropy regularization      : encourages exploration
      - n-step returns              : bootstrapped multi-step rewards
      - Multiple worker rollouts    : simulated synchronously (PS 5.1)
    Note: True async threading not available in PS 5.1.
    Workers run sequentially, gradients accumulated before update.
    Requires VBAF.Core.AllClasses.ps1 (via VBAF.LoadAll.ps1).
.NOTES
    Part of VBAF - Phase 3 Reinforcement Learning Module
    PS 5.1 compatible - dependency injection pattern throughout
#>
# Set base path
$basePath = $PSScriptRoot

# ============================================================
class A3CConfig {
    [int]    $StateSize      = 4
    [int]    $ActionSize     = 2
    [int[]]  $SharedHidden   = @(64, 64)  # Shared layers for actor+critic
    [double] $LearningRate   = 0.001
    [double] $Gamma          = 0.99       # Discount factor
    [double] $EntropyBonus   = 0.01       # Exploration bonus
    [double] $ValueLossCoeff = 0.5        # Weight of critic loss
    [int]    $NSteps         = 5          # n-step return length
    [int]    $NumWorkers     = 4          # Simulated parallel workers
    [int]    $MaxSteps       = 200        # Max steps per episode
}

# ============================================================
class A3CWorker {
    # Each worker has its OWN local network copy
    # and collects experience independently
    [object] $LocalNetwork
    [object] $Config
    [int]    $WorkerId
    [int]    $EpisodesDone = 0
    [double] $LastReward   = 0.0

    hidden [System.Random] $Rng

    A3CWorker([int]$workerId, [object]$config, [object]$localNetwork) {
        $this.WorkerId      = $workerId
        $this.Config        = $config
        $this.LocalNetwork  = $localNetwork
        $this.Rng           = [System.Random]::new($workerId * 42 + 7)
    }

    # Softmax on raw logits
    [double[]] Softmax([double[]]$logits) {
        $max  = ($logits | Measure-Object -Maximum).Maximum
        $exps = @(0.0) * $logits.Length
        $sum  = 0.0
        for ($i = 0; $i -lt $logits.Length; $i++) {
            $exps[$i] = [Math]::Exp($logits[$i] - $max)
            $sum += $exps[$i]
        }
        $probs = @(0.0) * $logits.Length
        for ($i = 0; $i -lt $logits.Length; $i++) {
            $probs[$i] = $exps[$i] / $sum
        }
        return $probs
    }

    # Sample action from probability distribution
    [int] SampleAction([double[]]$probs) {
        $r   = $this.Rng.NextDouble()
        $cum = 0.0
        for ($i = 0; $i -lt $probs.Length; $i++) {
            $cum += $probs[$i]
            if ($r -le $cum) { return $i }
        }
        return $probs.Length - 1
    }

    # Run n-step rollout on an environment, return experience batch
    [hashtable] RunRollout([object]$env) {
        $states   = [System.Collections.ArrayList]::new()
        $actions  = [System.Collections.ArrayList]::new()
        $rewards  = [System.Collections.ArrayList]::new()
        $dones    = [System.Collections.ArrayList]::new()

        $state = $env.GetState()
        $done  = $false
        $totalReward = 0.0

        for ($step = 0; $step -lt $this.Config.NSteps; $step++) {
            # Forward pass: first ActionSize outputs = policy logits
            #               last output = value estimate
            $out    = $this.LocalNetwork.Predict($state)
            $nA     = $this.Config.ActionSize
            $logits = $out[0..($nA-1)]
            $probs  = $this.Softmax($logits)
            $action = $this.SampleAction($probs)

            $result = $env.Step($action)
            $ns     = $result.NextState
            $reward = $result.Reward
            $done   = $result.Done

            $states.Add($state)   | Out-Null
            $actions.Add($action) | Out-Null
            $rewards.Add($reward) | Out-Null
            $dones.Add($done)     | Out-Null

            $totalReward += $reward
            $state = $ns

            if ($done) {
                $env.Reset() | Out-Null
                $this.EpisodesDone++
                $this.LastReward = $totalReward
                $totalReward = 0.0
                $done = $false
            }
        }

        # Bootstrap value for last state
        $lastOut   = $this.LocalNetwork.Predict($state)
        $lastValue = $lastOut[$this.Config.ActionSize]  # Last output = value

        return @{
            States    = $states
            Actions   = $actions
            Rewards   = $rewards
            Dones     = $dones
            LastValue = $lastValue
            LastState = $state
        }
    }
}

# ============================================================
class A3CAgent {
    # Global (shared) network - [object] for PS 5.1
    [object] $GlobalNetwork
    [object] $Config

    # Stats
    [int]    $TotalSteps     = 0
    [int]    $TotalEpisodes  = 0
    [int]    $UpdateCount    = 0
    [double] $LastLoss       = 0.0
    [double] $LastEntropy    = 0.0
    [double] $LastValue      = 0.0

    [System.Collections.Generic.List[double]] $EpisodeRewards
    [System.Collections.Generic.List[double]] $LossHistory
    [System.Collections.ArrayList]            $Workers

    hidden [System.Random] $Rng

    # -------------------------------------------------------
    # Constructor - receives pre-built global network
    # -------------------------------------------------------
    A3CAgent([object]$config, [object]$globalNetwork, [System.Collections.ArrayList]$workers) {
        $this.Config         = $config
        $this.GlobalNetwork  = $globalNetwork
        $this.Workers        = $workers
        $this.Rng            = [System.Random]::new()
        $this.EpisodeRewards = [System.Collections.Generic.List[double]]::new()
        $this.LossHistory    = [System.Collections.Generic.List[double]]::new()

        Write-Host "✅ A3CAgent created" -ForegroundColor Green
        Write-Host "   State size   : $($config.StateSize)"              -ForegroundColor Cyan
        Write-Host "   Action size  : $($config.ActionSize)"             -ForegroundColor Cyan
        Write-Host "   Shared hidden: $($config.SharedHidden -join ' -> ')" -ForegroundColor Cyan
        Write-Host "   Workers      : $($config.NumWorkers)"             -ForegroundColor Cyan
        Write-Host "   n-steps      : $($config.NSteps)"                 -ForegroundColor Cyan
        Write-Host "   Entropy bonus: $($config.EntropyBonus)"           -ForegroundColor Cyan
    }

    # -------------------------------------------------------
    # Softmax helper
    # -------------------------------------------------------
    hidden [double[]] Softmax([double[]]$logits) {
        $max  = ($logits | Measure-Object -Maximum).Maximum
        $exps = @(0.0) * $logits.Length
        $sum  = 0.0
        for ($i = 0; $i -lt $logits.Length; $i++) {
            $exps[$i] = [Math]::Exp($logits[$i] - $max)
            $sum += $exps[$i]
        }
        $probs = @(0.0) * $logits.Length
        for ($i = 0; $i -lt $logits.Length; $i++) {
            $probs[$i] = $exps[$i] / $sum
        }
        return $probs
    }

    # -------------------------------------------------------
    # Entropy of distribution
    # -------------------------------------------------------
    hidden [double] Entropy([double[]]$probs) {
        $h = 0.0
        foreach ($p in $probs) {
            if ($p -gt 1e-8) { $h -= $p * [Math]::Log($p) }
        }
        return $h
    }

    # -------------------------------------------------------
    # Compute n-step returns with bootstrapping
    # -------------------------------------------------------
    hidden [double[]] ComputeReturns([System.Collections.ArrayList]$rewards,
                                     [System.Collections.ArrayList]$dones,
                                     [double]$lastValue) {
        $n       = $rewards.Count
        $returns = @(0.0) * $n
        $R       = $lastValue

        for ($t = $n - 1; $t -ge 0; $t--) {
            if ([bool]$dones[$t]) { $R = 0.0 }
            $R           = [double]$rewards[$t] + $this.Config.Gamma * $R
            $returns[$t] = $R
        }
        return $returns
    }

    # -------------------------------------------------------
    # Global update from one worker's experience batch
    # -------------------------------------------------------
    [void] UpdateFromWorker([hashtable]$batch, [int]$workerId) {
        $states    = $batch.States
        $actions   = $batch.Actions
        $rewards   = $batch.Rewards
        $dones     = $batch.Dones
        $bootValue = $batch.LastValue
        $n         = $states.Count
        $nA        = $this.Config.ActionSize

        $returns  = $this.ComputeReturns($rewards, $dones, $bootValue)

        $totalLoss    = 0.0
        $totalEntropy = 0.0

        for ($t = 0; $t -lt $n; $t++) {
            $state  = [double[]]$states[$t]
            $action = [int]$actions[$t]
            $ret    = $returns[$t]

            # Forward pass on global network
            $out    = $this.GlobalNetwork.Predict($state)
            $logits = $out[0..($nA-1)]
            $value  = $out[$nA]
            $probs  = $this.Softmax($logits)

            # Advantage = return - value estimate
            $advantage = $ret - $value
            $entropy   = $this.Entropy($probs)
            $totalEntropy += $entropy

            # Build combined target output:
            # Policy head: nudge action probability by advantage
            $targetOut = $out.Clone()
            $nudge     = $advantage * 0.1 + $this.Config.EntropyBonus * $entropy
            $targetOut[$action] = [Math]::Max(0.01,
                                  [Math]::Min(0.99, $probs[$action] + $nudge))

            # Renormalize policy outputs
            $pSum = 0.0
            for ($i = 0; $i -lt $nA; $i++) { $pSum += $targetOut[$i] }
            for ($i = 0; $i -lt $nA; $i++) { $targetOut[$i] = $targetOut[$i] / $pSum }

            # Value head: target is the n-step return
            $targetOut[$nA] = $ret

            # Train global network
            $loss       = $this.GlobalNetwork.TrainSample($state, $targetOut)
            $totalLoss += $loss
            $this.TotalSteps++
        }

        $this.LastLoss    = $totalLoss / $n
        $this.LastEntropy = $totalEntropy / $n
        $this.LastValue   = $bootValue
        $this.LossHistory.Add($this.LastLoss)
        $this.UpdateCount++
    }

    # -------------------------------------------------------
    # Sync worker local network from global network
    # -------------------------------------------------------
    [void] SyncWorker([object]$worker) {
        $state = $this.GlobalNetwork.ExportState()
        $worker.LocalNetwork.ImportState($state)
    }

    # -------------------------------------------------------
    # Greedy action from global network for evaluation
    # -------------------------------------------------------
    [int] Predict([double[]]$state) {
        $out    = $this.GlobalNetwork.Predict($state)
        $nA     = $this.Config.ActionSize
        $logits = $out[0..($nA-1)]
        $probs  = $this.Softmax($logits)
        $best   = 0
        for ($i = 1; $i -lt $probs.Length; $i++) {
            if ($probs[$i] -gt $probs[$best]) { $best = $i }
        }
        return $best
    }

    # -------------------------------------------------------
    [void] EndEpisode([double]$totalReward) {
        $this.TotalEpisodes++
        $this.EpisodeRewards.Add($totalReward)
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
            TotalEpisodes = $this.TotalEpisodes
            TotalSteps    = $this.TotalSteps
            UpdateCount   = $this.UpdateCount
            AvgReward100  = [Math]::Round($avgReward,         3)
            LastLoss      = [Math]::Round($this.LastLoss,     6)
            AvgLoss       = [Math]::Round($avgLoss,           6)
            LastEntropy   = [Math]::Round($this.LastEntropy,  4)
            LastValue     = [Math]::Round($this.LastValue,    4)
        }
    }

    # -------------------------------------------------------
    [void] PrintStats() {
        $s = $this.GetStats()
        Write-Host ""
        Write-Host "╔══════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║         A3C Agent Statistics         ║" -ForegroundColor Cyan
        Write-Host "╠══════════════════════════════════════╣" -ForegroundColor Cyan
        Write-Host ("║  Episodes      : {0,-20}║" -f $s.TotalEpisodes) -ForegroundColor White
        Write-Host ("║  Total Steps   : {0,-20}║" -f $s.TotalSteps)    -ForegroundColor White
        Write-Host ("║  Global Updates: {0,-20}║" -f $s.UpdateCount)   -ForegroundColor White
        Write-Host ("║  Avg Reward    : {0,-20}║" -f $s.AvgReward100)  -ForegroundColor Green
        Write-Host ("║  Last Entropy  : {0,-20}║" -f $s.LastEntropy)   -ForegroundColor Yellow
        Write-Host ("║  Last Loss     : {0,-20}║" -f $s.LastLoss)      -ForegroundColor Magenta
        Write-Host ("║  Avg Loss      : {0,-20}║" -f $s.AvgLoss)       -ForegroundColor Magenta
        Write-Host ("║  Last Value    : {0,-20}║" -f $s.LastValue)     -ForegroundColor White
        Write-Host "╚══════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
    }
}

# ============================================================
# CartPole-style environment (self-contained, no external deps)
# ============================================================
class A3CEnvironment {
    [double] $Position
    [double] $Velocity
    [double] $Angle
    [double] $AngularVelocity
    [int]    $Steps
    [int]    $MaxSteps
    hidden [System.Random] $Rng

    A3CEnvironment([int]$seed) {
        $this.MaxSteps = 200
        $this.Rng      = [System.Random]::new($seed)
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
        $force     = if ($action -eq 1) { 1.0 } else { -1.0 }
        $gravity   = 9.8
        $cartMass  = 1.0
        $poleMass  = 0.1
        $totalMass = $cartMass + $poleMass
        $halfLen   = 0.25
        $dt        = 0.02

        $cosA = [Math]::Cos($this.Angle)
        $sinA = [Math]::Sin($this.Angle)
        $temp = ($force + $poleMass * $halfLen * $this.AngularVelocity * $this.AngularVelocity * $sinA) / $totalMass
        $aAcc = ($gravity * $sinA - $cosA * $temp) / ($halfLen * (4.0/3.0 - $poleMass * $cosA * $cosA / $totalMass))
        $acc  = $temp - $poleMass * $halfLen * $aAcc * $cosA / $totalMass

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
# All external types instantiated HERE (script level) - PS 5.1 safe
# Global network + worker networks built and injected.
# ============================================================
function Invoke-A3CTraining {
    param(
        [int]    $Episodes   = 100,
        [int]    $PrintEvery = 10,
        [switch] $Quiet,
        [switch] $FastMode
    )

    # ---- Settings ----
    $sharedHidden = @(64, 64)
    $maxSteps     = 200
    $numWorkers   = 4
    $nSteps       = 5

    if ($FastMode) {
        $sharedHidden = @(16, 16)
        $maxSteps     = 30
        $numWorkers   = 2
        $nSteps       = 5
        if ($Episodes  -eq 100) { $Episodes   = 50 }
        if ($PrintEvery -eq 10) { $PrintEvery  = 5  }
        Write-Host ""
        Write-Host "⚡ FAST MODE ENABLED" -ForegroundColor Yellow
        Write-Host "   Shared hidden: 16 -> 16" -ForegroundColor Yellow
        Write-Host "   MaxSteps     : $maxSteps" -ForegroundColor Yellow
        Write-Host "   Workers      : $numWorkers" -ForegroundColor Yellow
        Write-Host "   n-steps      : $nSteps"   -ForegroundColor Yellow
        Write-Host "   Episodes     : $Episodes"  -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "🚀 VBAF A3C Training Started" -ForegroundColor Green
    Write-Host "   Episodes: $Episodes"        -ForegroundColor Cyan
    Write-Host ""

    # ---- Config ----
    $config                 = [A3CConfig]::new()
    $config.StateSize       = 4
    $config.ActionSize      = 2
    $config.SharedHidden    = $sharedHidden
    $config.LearningRate    = 0.001
    $config.Gamma           = 0.99
    $config.EntropyBonus    = 0.01
    $config.ValueLossCoeff  = 0.5
    $config.NSteps          = $nSteps
    $config.NumWorkers      = $numWorkers
    $config.MaxSteps        = $maxSteps

    # ---- Build layer array ----
    # A3C uses ONE shared network with (ActionSize + 1) outputs:
    # [0..ActionSize-1] = policy logits, [ActionSize] = value
    $layers = [System.Collections.Generic.List[int]]::new()
    $layers.Add($config.StateSize)
    foreach ($h in $config.SharedHidden) { $layers.Add($h) }
    $layers.Add($config.ActionSize + 1)   # policy + value head
    $layerArray = $layers.ToArray()

    # ---- Build global network (script level - PS 5.1 safe) ----
    $globalNetwork = [NeuralNetwork]::new($layerArray, $config.LearningRate)

    # ---- Build worker local networks + environments ----
    $workers  = [System.Collections.ArrayList]::new()
    $envs     = [System.Collections.ArrayList]::new()

    for ($w = 0; $w -lt $numWorkers; $w++) {
        $localNet = [NeuralNetwork]::new($layerArray, $config.LearningRate)
        $worker   = [A3CWorker]::new($w, $config, $localNet)
        $env      = [A3CEnvironment]::new($w * 13 + 1)
        $env.MaxSteps = $maxSteps
        $workers.Add($worker) | Out-Null
        $envs.Add($env)       | Out-Null
    }

    # ---- Inject into A3CAgent ----
    $agent = [A3CAgent]::new($config, $globalNetwork, $workers)

    # Sync all workers with global network at start
    foreach ($worker in $workers) { $agent.SyncWorker($worker) }

    $bestReward  = 0.0
    $epRewards   = @(0.0) * $numWorkers

    for ($ep = 1; $ep -le $Episodes; $ep++) {

        $totalRewardThisEp = 0.0

        # Each worker runs a rollout, global network gets updated
        for ($w = 0; $w -lt $numWorkers; $w++) {
            $worker = $workers[$w]
            $env    = $envs[$w]

            # Run n-step rollout
            $batch  = $worker.RunRollout($env)

            # Update global network from this worker's experience
            $agent.UpdateFromWorker($batch, $w)

            # Sync worker local network from updated global
            $agent.SyncWorker($worker)

            $totalRewardThisEp += $worker.LastReward
        }

        $avgEpReward = $totalRewardThisEp / $numWorkers
        $agent.EndEpisode($avgEpReward)
        if ($avgEpReward -gt $bestReward) { $bestReward = $avgEpReward }

        if (-not $Quiet -and ($ep % $PrintEvery -eq 0)) {
            $stats = $agent.GetStats()
            Write-Host ("  Ep {0,4}  Reward: {1,5:F1}  Best: {2,5:F1}  Updates: {3,5}  Entropy: {4:F3}  Loss: {5:F5}" -f `
                $ep, $avgEpReward, $bestReward,
                $stats.UpdateCount, $stats.LastEntropy, $stats.LastLoss) -ForegroundColor White
        }
    }

    Write-Host ""
    Write-Host "✅ Training Complete!" -ForegroundColor Green
    $agent.PrintStats()
    return $agent
}

# ============================================================
# TEST
# 1. Run VBAF.LoadAll.ps1
# 2. $agent = Invoke-A3CTraining -Episodes 20 -PrintEvery 2 -FastMode
# 3. $agent = Invoke-A3CTraining -Episodes 50 -PrintEvery 5 -FastMode
# 4. $agent.PrintStats()
# ============================================================
Write-Host "📦 VBAF.RL.A3C.ps1 loaded" -ForegroundColor Green
Write-Host "   Classes : A3CConfig, A3CAgent, A3CWorker, A3CEnvironment" -ForegroundColor Cyan
Write-Host "   Function: Invoke-A3CTraining"                             -ForegroundColor Cyan
Write-Host ""
Write-Host "   Quick start:"                                                             -ForegroundColor Yellow
Write-Host '   $agent = Invoke-A3CTraining -Episodes 20 -PrintEvery 2 -FastMode'        -ForegroundColor White
Write-Host '   $agent.PrintStats()'                                                      -ForegroundColor White
Write-Host ""