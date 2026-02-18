#Requires -Version 5.1
<#
.SYNOPSIS
    Proximal Policy Optimization (PPO) Agent for Reinforcement Learning
.DESCRIPTION
    Implements the PPO algorithm combining:
      - Actor Network  : maps state -> action probabilities (policy)
      - Critic Network : maps state -> value estimate (baseline)
      - GAE            : Generalized Advantage Estimation
      - Clipped update : limits policy change per update step
    Requires VBAF.Core.AllClasses.ps1 to be loaded first (via VBAF.LoadAll.ps1).
.NOTES
    Part of VBAF - Phase 3 Reinforcement Learning Module
    PS 5.1 compatible - dependency injection pattern used
    to avoid parse-time type resolution errors in classes.
#>
# Set base path
$basePath = $PSScriptRoot

# ============================================================
class PPOConfig {
    [int]    $StateSize        = 4
    [int]    $ActionSize       = 2
    [int[]]  $ActorHidden      = @(64, 64)
    [int[]]  $CriticHidden     = @(64, 64)
    [double] $LearningRate     = 0.001
    [double] $Gamma            = 0.99    # Discount factor
    [double] $LambdaGAE       = 0.95    # GAE smoothing
    [double] $ClipEpsilon      = 0.2    # PPO clip range
    [double] $EntropyBonus     = 0.01   # Encourages exploration
    [int]    $UpdateEpochs     = 4      # Training passes per rollout
    [int]    $RolloutSteps     = 64     # Steps before each update
    [int]    $MaxSteps         = 200    # Max steps per episode
}

# ============================================================
class PPOAgent {
    # [object] for all cross-file types - PS 5.1 requirement
    [object] $Actor
    [object] $Critic
    [object] $Config

    # Stats
    [int]    $TotalSteps     = 0
    [int]    $TotalEpisodes  = 0
    [int]    $UpdateCount    = 0
    [double] $LastActorLoss  = 0.0
    [double] $LastCriticLoss = 0.0
    [double] $LastEntropy    = 0.0

    [System.Collections.Generic.List[double]] $EpisodeRewards
    [System.Collections.Generic.List[double]] $ActorLossHistory
    [System.Collections.Generic.List[double]] $CriticLossHistory

    # Rollout buffer
    hidden [System.Collections.ArrayList] $States
    hidden [System.Collections.ArrayList] $Actions
    hidden [System.Collections.ArrayList] $Rewards
    hidden [System.Collections.ArrayList] $Values
    hidden [System.Collections.ArrayList] $LogProbs
    hidden [System.Collections.ArrayList] $Dones

    hidden [System.Random] $Rng

    # -------------------------------------------------------
    # Constructor - receives pre-built networks (PS 5.1 safe)
    # -------------------------------------------------------
    PPOAgent([object]$config, [object]$actor, [object]$critic) {
        $this.Config  = $config
        $this.Actor   = $actor
        $this.Critic  = $critic
        $this.Rng     = [System.Random]::new()

        $this.EpisodeRewards    = [System.Collections.Generic.List[double]]::new()
        $this.ActorLossHistory  = [System.Collections.Generic.List[double]]::new()
        $this.CriticLossHistory = [System.Collections.Generic.List[double]]::new()

        $this.ClearRollout()

        Write-Host "✅ PPOAgent created" -ForegroundColor Green
        Write-Host "   State size    : $($config.StateSize)"                          -ForegroundColor Cyan
        Write-Host "   Action size   : $($config.ActionSize)"                         -ForegroundColor Cyan
        Write-Host "   Actor hidden  : $($config.ActorHidden  -join ' -> ')"          -ForegroundColor Cyan
        Write-Host "   Critic hidden : $($config.CriticHidden -join ' -> ')"          -ForegroundColor Cyan
        Write-Host "   Clip epsilon  : $($config.ClipEpsilon)"                        -ForegroundColor Cyan
        Write-Host "   Rollout steps : $($config.RolloutSteps)"                       -ForegroundColor Cyan
    }

    # -------------------------------------------------------
    # Softmax helper - converts raw outputs to probabilities
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
    # Sample action from probability distribution
    # -------------------------------------------------------
    hidden [int] SampleAction([double[]]$probs) {
        $r   = $this.Rng.NextDouble()
        $cum = 0.0
        for ($i = 0; $i -lt $probs.Length; $i++) {
            $cum += $probs[$i]
            if ($r -le $cum) { return $i }
        }
        return $probs.Length - 1
    }

    # -------------------------------------------------------
    # Log probability of action given probs
    # -------------------------------------------------------
    hidden [double] LogProb([double[]]$probs, [int]$action) {
        $p = [Math]::Max($probs[$action], 1e-8)
        return [Math]::Log($p)
    }

    # -------------------------------------------------------
    # Entropy of distribution (encourages exploration)
    # -------------------------------------------------------
    hidden [double] Entropy([double[]]$probs) {
        $h = 0.0
        foreach ($p in $probs) {
            if ($p -gt 1e-8) { $h -= $p * [Math]::Log($p) }
        }
        return $h
    }

    # -------------------------------------------------------
    # Select action - returns hashtable {Action, LogProb, Value}
    # -------------------------------------------------------
    [hashtable] Act([double[]]$state) {
        $logits = $this.Actor.Predict($state)
        $probs  = $this.Softmax($logits)
        $action = $this.SampleAction($probs)
        $logP   = $this.LogProb($probs, $action)

        # Critic value estimate
        $valueOut = $this.Critic.Predict($state)
        $value    = $valueOut[0]

        return @{ Action = $action; LogProb = $logP; Value = $value; Probs = $probs }
    }

    # -------------------------------------------------------
    # Greedy action for evaluation
    # -------------------------------------------------------
    [int] Predict([double[]]$state) {
        $logits = $this.Actor.Predict($state)
        $probs  = $this.Softmax($logits)
        $best   = 0
        for ($i = 1; $i -lt $probs.Length; $i++) {
            if ($probs[$i] -gt $probs[$best]) { $best = $i }
        }
        return $best
    }

    # -------------------------------------------------------
    # Store one transition in rollout buffer
    # -------------------------------------------------------
    [void] StoreTransition([double[]]$state, [int]$action, [double]$reward,
                           [double]$value, [double]$logProb, [bool]$done) {
        $this.States.Add($state)
        $this.Actions.Add($action)
        $this.Rewards.Add($reward)
        $this.Values.Add($value)
        $this.LogProbs.Add($logProb)
        $this.Dones.Add($done)
        $this.TotalSteps++
    }

    # -------------------------------------------------------
    # Clear rollout buffer
    # -------------------------------------------------------
    [void] ClearRollout() {
        $this.States   = [System.Collections.ArrayList]::new()
        $this.Actions  = [System.Collections.ArrayList]::new()
        $this.Rewards  = [System.Collections.ArrayList]::new()
        $this.Values   = [System.Collections.ArrayList]::new()
        $this.LogProbs = [System.Collections.ArrayList]::new()
        $this.Dones    = [System.Collections.ArrayList]::new()
    }

    # -------------------------------------------------------
    # Compute GAE advantages and discounted returns
    # lastValue = critic estimate of state after rollout ends
    # -------------------------------------------------------
    hidden [hashtable] ComputeGAE([double]$lastValue) {
        $n          = $this.Rewards.Count
        $advantages = @(0.0) * $n
        $returns    = @(0.0) * $n
        $gaeVal     = 0.0

        for ($t = $n - 1; $t -ge 0; $t--) {
            $done     = [bool]$this.Dones[$t]
            $reward   = [double]$this.Rewards[$t]
            $value    = [double]$this.Values[$t]
            $nextVal  = if ($t -eq $n - 1) { $lastValue } else { [double]$this.Values[$t + 1] }

            if ($done) { $nextVal = 0.0; $gaeVal = 0.0 }

            $delta        = $reward + $this.Config.Gamma * $nextVal - $value
            $gaeVal       = $delta + $this.Config.Gamma * $this.Config.LambdaGAE * $gaeVal
            $advantages[$t] = $gaeVal
            $returns[$t]    = $gaeVal + $value
        }

        # Normalize advantages
        $mean   = ($advantages | Measure-Object -Average).Average
        $sq     = $advantages | ForEach-Object { ($_ - $mean) * ($_ - $mean) }
        $stdDev = [Math]::Sqrt(($sq | Measure-Object -Average).Average + 1e-8)
        for ($i = 0; $i -lt $n; $i++) {
            $advantages[$i] = ($advantages[$i] - $mean) / $stdDev
        }

        return @{ Advantages = $advantages; Returns = $returns }
    }

    # -------------------------------------------------------
    # PPO Update - train actor and critic on collected rollout
    # -------------------------------------------------------
    [void] Update([double]$lastValue) {
        $gae         = $this.ComputeGAE($lastValue)
        $advantages  = $gae.Advantages
        $returns     = $gae.Returns
        $n           = $this.States.Count

        $totalActorLoss  = 0.0
        $totalCriticLoss = 0.0
        $totalEntropy    = 0.0
        $updateSamples   = 0

        for ($epoch = 0; $epoch -lt $this.Config.UpdateEpochs; $epoch++) {
            for ($t = 0; $t -lt $n; $t++) {
                $state      = [double[]]$this.States[$t]
                $action     = [int]$this.Actions[$t]
                $oldLogProb = [double]$this.LogProbs[$t]
                $advantage  = $advantages[$t]
                $ret        = $returns[$t]

                # ---- Critic update ----
                # Target: discounted return
                $criticTarget    = @($ret)
                $criticLoss      = $this.Critic.TrainSample($state, $criticTarget)
                $totalCriticLoss += $criticLoss

                # ---- Actor update ----
                # Get new probabilities
                $logits   = $this.Actor.Predict($state)
                $probs    = $this.Softmax($logits)
                $newLogP  = $this.LogProb($probs, $action)
                $entropy  = $this.Entropy($probs)
                $totalEntropy += $entropy

                # PPO ratio and clipped objective
                $ratio      = [Math]::Exp($newLogP - $oldLogProb)
                $clipRatio  = [Math]::Max($this.Config.ClipEpsilon * -1,
                              [Math]::Min($this.Config.ClipEpsilon,
                              $ratio - 1.0)) + 1.0

                # Build actor target: nudge probability of taken action
                # in direction of advantage, clipped by ratio
                $effectiveRatio = [Math]::Min($ratio, $clipRatio)
                $actorTarget    = $probs.Clone()
                $nudge          = $advantage * $effectiveRatio * 0.1 + $this.Config.EntropyBonus * $entropy
                $actorTarget[$action] = [Math]::Max(0.01,
                                        [Math]::Min(0.99,
                                        $probs[$action] + $nudge))

                # Renormalize
                $sum = ($actorTarget | Measure-Object -Sum).Sum
                for ($i = 0; $i -lt $actorTarget.Length; $i++) {
                    $actorTarget[$i] = $actorTarget[$i] / $sum
                }

                $actorLoss      = $this.Actor.TrainSample($state, $actorTarget)
                $totalActorLoss += $actorLoss
                $updateSamples++
            }
        }

        if ($updateSamples -gt 0) {
            $this.LastActorLoss  = $totalActorLoss  / $updateSamples
            $this.LastCriticLoss = $totalCriticLoss / $updateSamples
            $this.LastEntropy    = $totalEntropy     / $updateSamples
            $this.ActorLossHistory.Add($this.LastActorLoss)
            $this.CriticLossHistory.Add($this.LastCriticLoss)
        }

        $this.UpdateCount++
        $this.ClearRollout()
    }

    # -------------------------------------------------------
    [void] EndEpisode([double]$totalReward) {
        $this.TotalEpisodes++
        $this.EpisodeRewards.Add($totalReward)
    }

    # -------------------------------------------------------
    [hashtable] GetStats() {
        $avgReward      = 0.0
        $avgActorLoss   = 0.0
        $avgCriticLoss  = 0.0

        if ($this.EpisodeRewards.Count -gt 0) {
            $slice     = $this.EpisodeRewards | Select-Object -Last 100
            $avgReward = ($slice | Measure-Object -Average).Average
        }
        if ($this.ActorLossHistory.Count -gt 0) {
            $slice         = $this.ActorLossHistory | Select-Object -Last 100
            $avgActorLoss  = ($slice | Measure-Object -Average).Average
        }
        if ($this.CriticLossHistory.Count -gt 0) {
            $slice          = $this.CriticLossHistory | Select-Object -Last 100
            $avgCriticLoss  = ($slice | Measure-Object -Average).Average
        }

        return @{
            TotalEpisodes   = $this.TotalEpisodes
            TotalSteps      = $this.TotalSteps
            UpdateCount     = $this.UpdateCount
            LastActorLoss   = [Math]::Round($this.LastActorLoss,  6)
            LastCriticLoss  = [Math]::Round($this.LastCriticLoss, 6)
            LastEntropy     = [Math]::Round($this.LastEntropy,     4)
            AvgReward100    = [Math]::Round($avgReward,            3)
            AvgActorLoss    = [Math]::Round($avgActorLoss,         6)
            AvgCriticLoss   = [Math]::Round($avgCriticLoss,        6)
        }
    }

    # -------------------------------------------------------
    [void] PrintStats() {
        $s = $this.GetStats()
        Write-Host ""
        Write-Host "╔══════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║         PPO Agent Statistics         ║" -ForegroundColor Cyan
        Write-Host "╠══════════════════════════════════════╣" -ForegroundColor Cyan
        Write-Host ("║  Episodes      : {0,-20}║" -f $s.TotalEpisodes)   -ForegroundColor White
        Write-Host ("║  Total Steps   : {0,-20}║" -f $s.TotalSteps)      -ForegroundColor White
        Write-Host ("║  PPO Updates   : {0,-20}║" -f $s.UpdateCount)     -ForegroundColor White
        Write-Host ("║  Avg Reward    : {0,-20}║" -f $s.AvgReward100)    -ForegroundColor Green
        Write-Host ("║  Entropy       : {0,-20}║" -f $s.LastEntropy)     -ForegroundColor Yellow
        Write-Host ("║  Actor Loss    : {0,-20}║" -f $s.LastActorLoss)   -ForegroundColor Magenta
        Write-Host ("║  Critic Loss   : {0,-20}║" -f $s.LastCriticLoss)  -ForegroundColor Magenta
        Write-Host "╚══════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
    }
}

# ============================================================
# CartPole-style environment (same as DQN, self-contained)
# ============================================================
class PPOEnvironment {
    [double] $Position
    [double] $Velocity
    [double] $Angle
    [double] $AngularVelocity
    [int]    $Steps
    [int]    $MaxSteps
    hidden [System.Random] $Rng

    PPOEnvironment() {
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
        $force     = if ($action -eq 1) { 1.0 } else { -1.0 }
        $gravity   = 9.8
        $cartMass  = 1.0
        $poleMass  = 0.1
        $totalMass = $cartMass + $poleMass
        $halfLen   = 0.25
        $dt        = 0.02

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
# All external types instantiated HERE (script level) - PS 5.1 safe
# ============================================================
function Invoke-PPOTraining {
    param(
        [int]    $Episodes   = 100,
        [int]    $PrintEvery = 10,
        [switch] $Quiet,
        [switch] $FastMode
    )

    # ---- Settings ----
    $actorHidden  = @(64, 64)
    $criticHidden = @(64, 64)
    $maxSteps     = 200
    $rolloutSteps = 64

    if ($FastMode) {
        $actorHidden  = @(16, 16)
        $criticHidden = @(16, 16)
        $maxSteps     = 30
        $rolloutSteps = 32
        if ($Episodes  -eq 100) { $Episodes   = 50 }
        if ($PrintEvery -eq 10) { $PrintEvery  = 5  }
        Write-Host ""
        Write-Host "⚡ FAST MODE ENABLED" -ForegroundColor Yellow
        Write-Host "   Actor/Critic : 16 -> 16" -ForegroundColor Yellow
        Write-Host "   MaxSteps     : $maxSteps"  -ForegroundColor Yellow
        Write-Host "   RolloutSteps : $rolloutSteps" -ForegroundColor Yellow
        Write-Host "   Episodes     : $Episodes"  -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "🚀 VBAF PPO Training Started" -ForegroundColor Green
    Write-Host "   Episodes: $Episodes"        -ForegroundColor Cyan
    Write-Host ""

    # ---- Config ----
    $config                 = [PPOConfig]::new()
    $config.StateSize       = 4
    $config.ActionSize      = 2
    $config.ActorHidden     = $actorHidden
    $config.CriticHidden    = $criticHidden
    $config.LearningRate    = 0.001
    $config.Gamma           = 0.99
    $config.LambdaGAE      = 0.95
    $config.ClipEpsilon     = 0.2
    $config.EntropyBonus    = 0.01
    $config.UpdateEpochs    = 4
    $config.RolloutSteps    = $rolloutSteps
    $config.MaxSteps        = $maxSteps

    # ---- Build layer arrays ----
    $actorLayers  = [System.Collections.Generic.List[int]]::new()
    $actorLayers.Add($config.StateSize)
    foreach ($h in $config.ActorHidden)  { $actorLayers.Add($h) }
    $actorLayers.Add($config.ActionSize)

    $criticLayers = [System.Collections.Generic.List[int]]::new()
    $criticLayers.Add($config.StateSize)
    foreach ($h in $config.CriticHidden) { $criticLayers.Add($h) }
    $criticLayers.Add(1)   # Critic outputs single value

    # ---- Instantiate networks at script level (PS 5.1 safe) ----
    $actor  = [NeuralNetwork]::new($actorLayers.ToArray(),  $config.LearningRate)
    $critic = [NeuralNetwork]::new($criticLayers.ToArray(), $config.LearningRate)

    # ---- Inject into PPOAgent ----
    $agent = [PPOAgent]::new($config, $actor, $critic)

    $env          = [PPOEnvironment]::new()
    $env.MaxSteps = $maxSteps

    $bestReward  = 0.0
    $stepCounter = 0

    for ($ep = 1; $ep -le $Episodes; $ep++) {
        $state       = $env.Reset()
        $totalReward = 0.0
        $done        = $false

        while (-not $done) {
            # Get action from actor
            $result  = $agent.Act($state)
            $action  = $result.Action
            $logProb = $result.LogProb
            $value   = $result.Value

            # Step environment
            $step    = $env.Step($action)
            $ns      = $step.NextState
            $reward  = $step.Reward
            $done    = $step.Done

            # Store in rollout buffer
            $agent.StoreTransition($state, $action, $reward, $value, $logProb, $done)
            $state        = $ns
            $totalReward += $reward
            $stepCounter++

            # Update when rollout buffer is full
            if ($stepCounter % $config.RolloutSteps -eq 0) {
                $lastValOut = $agent.Critic.Predict($state)
                $lastVal    = $lastValOut[0]
                $agent.Update($lastVal)
            }
        }

        $agent.EndEpisode($totalReward)
        if ($totalReward -gt $bestReward) { $bestReward = $totalReward }

        if (-not $Quiet -and ($ep % $PrintEvery -eq 0)) {
            $stats = $agent.GetStats()
            Write-Host ("  Ep {0,4}  Reward: {1,5:F0}  Best: {2,5:F0}  Updates: {3,4}  Entropy: {4:F3}  CriticLoss: {5:F5}" -f `
                $ep, $totalReward, $bestReward,
                $stats.UpdateCount, $stats.LastEntropy, $stats.LastCriticLoss) -ForegroundColor White
        }
    }

    # Final update on remaining rollout
    if ($agent.States.Count -gt 0) {
        $agent.Update(0.0)
    }

    Write-Host ""
    Write-Host "✅ Training Complete!" -ForegroundColor Green
    $agent.PrintStats()
    ,$agent  # comma operator forces return as single object in PS 5.1
}

# ============================================================
# ============================================================
# TEST
# 1. Run VBAF.LoadAll.ps1
# 2. $agent = Invoke-PPOTraining -Episodes 20 -PrintEvery 2 -FastMode
# 3. $agent = (Invoke-PPOTraining -Episodes 50 -PrintEvery 5 -FastMode)[-1]
# 4. $agent.PrintStats()
# ============================================================
Write-Host "📦 VBAF.RL.PPO.ps1 loaded" -ForegroundColor Green
Write-Host "   Classes : PPOConfig, PPOAgent, PPOEnvironment"              -ForegroundColor Cyan
Write-Host "   Function: Invoke-PPOTraining"                               -ForegroundColor Cyan
Write-Host ""
Write-Host "   Quick start:"                                               -ForegroundColor Yellow
Write-Host '   $agent = (Invoke-PPOTraining -Episodes 50 -PrintEvery 5 -FastMode)[-1]'  -ForegroundColor White
Write-Host '   $agent.PrintStats()'                                        -ForegroundColor White
Write-Host ""