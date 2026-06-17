#Requires -Version 5.1
<#
.SYNOPSIS
    Advantage Actor-Critic (A3C) Agent for Reinforcement Learning
.DESCRIPTION
    Implements the A3C algorithm -- the most architecturally complex
    algorithm in VBAF, and historically significant in deep RL.

    WHAT YOU ARE LEARNING HERE:
    ============================
    A3C (Asynchronous Advantage Actor-Critic) was published by DeepMind
    in 2016 and introduced two major ideas:

    1. SHARED ACTOR-CRITIC NETWORK:
       Unlike PPO which uses two separate networks (Actor + Critic),
       A3C uses ONE shared network with TWO OUTPUT HEADS:
         - Policy head:  outputs[0..ActionSize-1] = action logits
         - Value head:   outputs[ActionSize]       = state value estimate
       Sharing the network means both heads learn common features
       of the environment, potentially more efficiently.

    2. MULTIPLE PARALLEL WORKERS (the "Asynchronous" part):
       In the original paper, multiple copies of the agent run
       simultaneously in separate threads, each with their own
       environment and local network copy.
       Workers collect experience INDEPENDENTLY and asynchronously
       update a SHARED GLOBAL NETWORK.

       WHY ASYNC WORKERS HELP:
       - Each worker explores different parts of the environment
       - Their experiences are naturally de-correlated
       - No replay buffer needed -- diversity comes from parallel exploration
       - Much faster wall-clock training on multi-core hardware

    POWERSHELL 5.1 LIMITATION:
    ===========================
    True asynchronous threading is not available in PS 5.1.
    Workers in this implementation run SEQUENTIALLY, not simultaneously.
    Each worker runs its rollout, updates the global network, then the
    next worker runs. The result is mathematically equivalent but
    slower than true async (no parallelism speedup).
    The learning behaviour is correct -- only the speed differs.

    THREE CLASSES -- HOW THEY FIT TOGETHER:
    =========================================
    A3CConfig:      hyperparameters
    A3CWorker:      one "parallel" worker -- has its own local network
                    and environment, runs n-step rollouts
    A3CAgent:       owns the GLOBAL network, coordinates all workers,
                    applies updates from worker experience batches

    THE A3C TRAINING CYCLE:
    =======================
    For each update round:
      1. Each worker SYNCS its local network from the global network
      2. Each worker runs an N-STEP ROLLOUT (NSteps environment steps)
      3. Each worker sends its experience batch to the global agent
      4. Global agent UPDATES the global network from that batch
      5. Repeat from step 1

    N-STEP RETURNS (vs PPO's GAE):
    ================================
    PPO uses GAE (Generalized Advantage Estimation) -- a weighted average
    of multi-step advantage estimates.

    A3C uses simpler N-STEP RETURNS:
      R_t = r_t + gamma*r_{t+1} + gamma^2*r_{t+2} + ... + gamma^n * V(s_{t+n})

    With NSteps=5: look 5 steps ahead, then bootstrap from the value estimate.
    This is less sophisticated than GAE but computationally simpler.

    A3C vs PPO vs DQN -- ALGORITHM COMPARISON:
    ============================================
    DQN:  off-policy, replay buffer, one network (Q-values), discrete only
    PPO:  on-policy, rollout buffer, two networks (Actor + Critic), stable
    A3C:  on-policy, no buffer, one network (shared), parallel workers

    A3C was state-of-the-art in 2016 -- PPO (2017) largely replaced it
    because PPO is simpler and often more stable. But A3C introduced
    the shared actor-critic architecture that influenced all subsequent methods.

    THEORY REFERENCE:
    =================
    Mnih, V. et al. (2016). "Asynchronous Methods for Deep Reinforcement
    Learning." Proceedings of ICML 2016. ArXiv:1602.01783.

    This paper also introduced A2C (synchronous version -- what we implement)
    alongside the asynchronous A3C. Both use the same architecture.

.NOTES
    Part of VBAF (Visual AI & Reinforcement Learning Framework)
    Educational use -- compare all three algorithms: DQN, PPO, A3C.
    Requires VBAF.Core.AllClasses.ps1 (loaded via VBAF.LoadAll.ps1)
#>

$basePath = $PSScriptRoot


# ============================================================
# A3CCONFIG -- hyperparameters
# ============================================================
#
# KEY A3C HYPERPARAMETERS:
#
# SharedHidden = [64, 64]
#   The hidden layers shared between actor and critic heads.
#   Both heads benefit from the same learned state representation.
#
# Gamma = 0.99 -- same as PPO, higher than DQN
#   Both A3C and PPO use higher gamma because they learn value functions
#   that can accurately estimate long-horizon returns.
#
# EntropyBonus = 0.01
#   Same role as in PPO -- discourages premature convergence.
#   More important in A3C because workers might overfit to their environments.
#
# ValueLossCoeff = 0.5
#   Weight of the critic (value) loss relative to actor (policy) loss.
#   Original A3C paper used 0.5 -- standard across implementations.
#
# NSteps = 5
#   How many environment steps each worker takes before updating global.
#   Short rollouts = more frequent updates = can be noisier
#   Long rollouts = less frequent updates = more stable gradients
#   NSteps=5 is the value from the original A3C paper.
#
# NumWorkers = 4
#   Simulated parallel workers. In true async A3C, each would be a thread.
#   Here they run sequentially -- diversity comes from different random seeds.

class A3CConfig {
    [int]    $StateSize     = 4
    [int]    $ActionSize    = 2
    [int[]]  $SharedHidden  = @(64, 64)   # Shared between actor and critic heads
    [double] $LearningRate  = 0.001
    [double] $Gamma         = 0.99        # High discount -- values long-term reward
    [double] $EntropyBonus  = 0.01        # Exploration encouragement
    [double] $ValueLossCoeff = 0.5        # Weight of critic loss (from A3C paper)
    [int]    $NSteps        = 5           # Steps per worker rollout
    [int]    $NumWorkers    = 4           # Simulated parallel workers
    [int]    $MaxSteps      = 200         # Max steps per episode
}


# ============================================================
# A3CWORKER -- one parallel worker
# ============================================================
#
# WHAT IS A WORKER
# -----------------
# In true A3C, each worker is a separate THREAD with:
#   - Its own LOCAL NETWORK (copy of global at start of rollout)
#   - Its own ENVIRONMENT (different random seed = different exploration)
#
# The worker collects NSteps of experience using its local network,
# then sends the experience batch to the global agent for the update.
# After the update, it syncs its local network from the global again.
#
# WHY LOCAL NETWORKS
# -------------------
# If all workers shared the exact same network simultaneously,
# concurrent reads/writes would cause race conditions and corrupted weights.
# By using local copies, each worker can predict independently.
# The global network is only written to during the update step.
#
# NETWORK OUTPUT FORMAT FOR A3C:
# --------------------------------
# The shared network has (ActionSize + 1) outputs:
#   outputs[0..ActionSize-1] = policy logits (for Softmax -> action probabilities)
#   outputs[ActionSize]      = value estimate V(s)
# This is different from DQN (ActionSize outputs, Q-values only) and
# PPO (two completely separate networks).
#
# WORKER SEED:
# ------------
# Each worker gets a different random seed (workerId * 42 + 7).
# This ensures different starting states and exploration patterns.
# Without different seeds, sequential workers would explore identically.

class A3CWorker {
    [object] $LocalNetwork   # Copy of global network -- used for rollout
    [object] $Config
    [int]    $WorkerId
    [int]    $EpisodesDone = 0
    [double] $LastReward   = 0.0
    hidden [System.Random] $Rng

    A3CWorker([int]$workerId, [object]$config, [object]$localNetwork) {
        $this.WorkerId     = $workerId
        $this.Config       = $config
        $this.LocalNetwork = $localNetwork
        $this.Rng          = [System.Random]::new($workerId * 42 + 7)  # Unique seed per worker
    }

    # Softmax -- same as PPO. Each worker needs its own copy because
    # PS 5.1 classes cannot call methods from other class instances directly.
    [double[]] Softmax([double[]]$logits) {
        $max  = ($logits | Measure-Object -Maximum).Maximum
        $exps = @(0.0) * $logits.Length
        $sum  = 0.0
        for ($i = 0; $i -lt $logits.Length; $i++) {
            $exps[$i] = [Math]::Exp($logits[$i] - $max); $sum += $exps[$i]
        }
        $probs = @(0.0) * $logits.Length
        for ($i = 0; $i -lt $logits.Length; $i++) { $probs[$i] = $exps[$i] / $sum }
        return $probs
    }

    # Stochastic sampling -- same role as in PPO.
    [int] SampleAction([double[]]$probs) {
        $r = $this.Rng.NextDouble(); $cum = 0.0
        for ($i = 0; $i -lt $probs.Length; $i++) {
            $cum += $probs[$i]
            if ($r -le $cum) { return $i }
        }
        return $probs.Length - 1
    }

    # RUN ROLLOUT -- collect NSteps of experience using LOCAL network.
    #
    # For each step:
    #   1. Predict from local network: get action logits and value estimate
    #   2. Sample action from policy probabilities
    #   3. Step the environment: get reward and next state
    #   4. Store (state, action, reward, done) in batch
    #   5. If episode ended: reset environment, start new episode
    #
    # BOOTSTRAPPED LAST VALUE:
    # After NSteps, we do not know the full future return.
    # We bootstrap: use the value network's estimate of the last state.
    # LastValue = V(s_{t+n}) -- what the critic thinks the last state is worth.
    # This is used in ComputeReturns to cap the n-step return.
    [hashtable] RunRollout([object]$env) {
        $states   = [System.Collections.ArrayList]::new()
        $actions  = [System.Collections.ArrayList]::new()
        $rewards  = [System.Collections.ArrayList]::new()
        $dones    = [System.Collections.ArrayList]::new()

        $state = $env.GetState()
        $done  = $false
        $totalReward = 0.0

        for ($step = 0; $step -lt $this.Config.NSteps; $step++) {
            # Forward pass on LOCAL network
            # First ActionSize outputs = policy logits
            # Last output = value estimate (used for bootstrapping)
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
                $totalReward     = 0.0
                $done            = $false
            }
        }

        # Bootstrap: estimate value of the state AFTER the rollout ends
        $lastOut   = $this.LocalNetwork.Predict($state)
        $lastValue = $lastOut[$this.Config.ActionSize]

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
# A3CAGENT -- global coordinator
# ============================================================
#
# THE GLOBAL NETWORK:
# -------------------
# The GlobalNetwork is the single shared model that all workers
# contribute to and sync from. It is the "true" agent -- workers
# are just temporary copies that gather experience.
#
# After each worker update, the global network has learned from
# that worker's experience. When the next worker syncs, it gets
# the benefit of all previous workers' updates.
#
# ADVANTAGE ESTIMATION IN A3C:
# ----------------------------
# A(s,a) = R_t - V(s)
# Where R_t is the n-step return and V(s) is the critic's estimate.
#
# Positive advantage: this action was BETTER than the critic expected
#   -> increase probability of this action
# Negative advantage: this action was WORSE than the critic expected
#   -> decrease probability of this action
#
# This is simpler than PPO's GAE but conceptually identical.
# The "advantage" is the key innovation of Actor-Critic methods --
# training the policy relative to a baseline (the value estimate)
# rather than on raw rewards.

class A3CAgent {
    [object] $GlobalNetwork   # The one true shared network
    [object] $Config
    [System.Collections.ArrayList] $Workers   # All worker instances

    [int]    $TotalSteps    = 0
    [int]    $TotalEpisodes = 0
    [int]    $UpdateCount   = 0
    [double] $LastLoss      = 0.0
    [double] $LastEntropy   = 0.0
    [double] $LastValue     = 0.0   # Last bootstrapped value estimate

    [System.Collections.Generic.List[double]] $EpisodeRewards
    [System.Collections.Generic.List[double]] $LossHistory

    hidden [System.Random] $Rng

    A3CAgent([object]$config, [object]$globalNetwork, [System.Collections.ArrayList]$workers) {
        $this.Config        = $config
        $this.GlobalNetwork = $globalNetwork
        $this.Workers       = $workers
        $this.Rng           = [System.Random]::new()

        $this.EpisodeRewards = [System.Collections.Generic.List[double]]::new()
        $this.LossHistory    = [System.Collections.Generic.List[double]]::new()

        Write-Host "  A3CAgent created" -ForegroundColor Green
        Write-Host "   State size    : $($config.StateSize)"                 -ForegroundColor Cyan
        Write-Host "   Action size   : $($config.ActionSize)"                -ForegroundColor Cyan
        Write-Host "   Shared hidden : $($config.SharedHidden -join ' -> ')" -ForegroundColor Cyan
        Write-Host "   Workers       : $($config.NumWorkers)"                -ForegroundColor Cyan
        Write-Host "   n-steps       : $($config.NSteps)"                    -ForegroundColor Cyan
    }

    hidden [double[]] Softmax([double[]]$logits) {
        $max  = ($logits | Measure-Object -Maximum).Maximum
        $exps = @(0.0) * $logits.Length; $sum = 0.0
        for ($i = 0; $i -lt $logits.Length; $i++) { $exps[$i] = [Math]::Exp($logits[$i] - $max); $sum += $exps[$i] }
        $probs = @(0.0) * $logits.Length
        for ($i = 0; $i -lt $logits.Length; $i++) { $probs[$i] = $exps[$i] / $sum }
        return $probs
    }

    hidden [double] Entropy([double[]]$probs) {
        $h = 0.0
        foreach ($p in $probs) { if ($p -gt 1e-8) { $h -= $p * [Math]::Log($p) } }
        return $h
    }

    # COMPUTE N-STEP RETURNS:
    # -----------------------
    # Work backwards through the rollout:
    #   R = lastValue  (bootstrap from value estimate of final state)
    #   for t from n-1 down to 0:
    #     if episode ended at t: R = 0  (no future rewards)
    #     R = reward[t] + gamma * R
    #     returns[t] = R
    #
    # The result is the discounted cumulative return from each time step.
    # This is what the critic should learn to predict.
    hidden [double[]] ComputeReturns([System.Collections.ArrayList]$rewards,
                                     [System.Collections.ArrayList]$dones,
                                     [double]$lastValue) {
        $n       = $rewards.Count
        $returns = @(0.0) * $n
        $R       = $lastValue

        for ($t = $n - 1; $t -ge 0; $t--) {
            if ([bool]$dones[$t]) { $R = 0.0 }   # Episode boundary -- reset future
            $R           = [double]$rewards[$t] + $this.Config.Gamma * $R
            $returns[$t] = $R
        }
        return $returns
    }

    # GLOBAL UPDATE FROM ONE WORKER'S BATCH:
    # ----------------------------------------
    # For each transition in the batch:
    #
    # 1. Forward pass on GLOBAL network -> get policy logits + value estimate
    # 2. Compute advantage: A = return - value_estimate
    # 3. Policy update: nudge P(action) in direction of advantage
    # 4. Value update: train value head toward the n-step return
    # 5. Entropy bonus: nudge all probabilities toward uniform
    #
    # The combined target vector has ActionSize + 1 elements:
    #   [0..ActionSize-1] = updated action probabilities
    #   [ActionSize]      = n-step return (value target)
    #
    # This trains BOTH heads of the shared network in one TrainSample call.
    [void] UpdateFromWorker([hashtable]$batch, [int]$workerId) {
        $states    = $batch.States
        $actions   = $batch.Actions
        $rewards   = $batch.Rewards
        $dones     = $batch.Dones
        $bootValue = $batch.LastValue
        $n         = $states.Count
        $nA        = $this.Config.ActionSize

        $returns      = $this.ComputeReturns($rewards, $dones, $bootValue)
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

            # A3C advantage: how much better was the actual return vs value estimate
            $advantage = $ret - $value
            $entropy   = $this.Entropy($probs)
            $totalEntropy += $entropy

            # Build combined target: policy probabilities + value target
            $targetOut = $out.Clone()

            # Nudge the taken action's probability in direction of advantage
            $nudge              = $advantage * 0.1 + $this.Config.EntropyBonus * $entropy
            $targetOut[$action] = [Math]::Max(0.01, [Math]::Min(0.99, $probs[$action] + $nudge))

            # Renormalise policy outputs to valid probability distribution
            $pSum = 0.0
            for ($i = 0; $i -lt $nA; $i++) { $pSum += $targetOut[$i] }
            for ($i = 0; $i -lt $nA; $i++) { $targetOut[$i] = $targetOut[$i] / $pSum }

            # Value target: n-step return
            $targetOut[$nA] = $ret

            # Train both heads simultaneously
            $loss       = $this.GlobalNetwork.TrainSample($state, $targetOut)
            $totalLoss += $loss
            $this.TotalSteps++
        }

        $this.LastLoss    = $totalLoss    / $n
        $this.LastEntropy = $totalEntropy / $n
        $this.LastValue   = $bootValue
        $this.LossHistory.Add($this.LastLoss)
        $this.UpdateCount++
    }

    # SYNC WORKER -- copy global network weights to worker's local network.
    # Called BEFORE each worker runs its rollout (step 1 of the A3C cycle).
    # This ensures the worker uses the latest global knowledge.
    [void] SyncWorker([object]$worker) {
        $state = $this.GlobalNetwork.ExportState()
        $worker.LocalNetwork.ImportState($state)
    }

    # Greedy action from global network for evaluation.
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

    [void] EndEpisode([double]$totalReward) {
        $this.TotalEpisodes++
        $this.EpisodeRewards.Add($totalReward)
    }

    [hashtable] GetStats() {
        $avgReward = 0.0; $avgLoss = 0.0
        if ($this.EpisodeRewards.Count -gt 0) { $avgReward = ($this.EpisodeRewards | Select-Object -Last 100 | Measure-Object -Average).Average }
        if ($this.LossHistory.Count    -gt 0) { $avgLoss   = ($this.LossHistory    | Select-Object -Last 100 | Measure-Object -Average).Average }
        return @{
            TotalEpisodes = $this.TotalEpisodes
            TotalSteps    = $this.TotalSteps
            UpdateCount   = $this.UpdateCount
            AvgReward100  = [Math]::Round($avgReward,        3)
            LastLoss      = [Math]::Round($this.LastLoss,    6)
            AvgLoss       = [Math]::Round($avgLoss,          6)
            LastEntropy   = [Math]::Round($this.LastEntropy, 4)
            LastValue     = [Math]::Round($this.LastValue,   4)
        }
    }

    [void] PrintStats() {
        $s = $this.GetStats()
        Write-Host ""
        Write-Host "  +--------------------------------------+" -ForegroundColor Cyan
        Write-Host "  |      A3C Agent Statistics            |" -ForegroundColor Cyan
        Write-Host "  +--------------------------------------+" -ForegroundColor Cyan
        Write-Host ("  |  Episodes      : {0,-20}|" -f $s.TotalEpisodes) -ForegroundColor White
        Write-Host ("  |  Total Steps   : {0,-20}|" -f $s.TotalSteps)    -ForegroundColor White
        Write-Host ("  |  Global Updates: {0,-20}|" -f $s.UpdateCount)   -ForegroundColor White
        Write-Host ("  |  Avg Reward    : {0,-20}|" -f $s.AvgReward100)  -ForegroundColor Green
        Write-Host ("  |  Last Entropy  : {0,-20}|" -f $s.LastEntropy)   -ForegroundColor Yellow
        Write-Host ("  |  Last Loss     : {0,-20}|" -f $s.LastLoss)      -ForegroundColor Magenta
        Write-Host ("  |  Avg Loss      : {0,-20}|" -f $s.AvgLoss)       -ForegroundColor Magenta
        Write-Host ("  |  Last Value    : {0,-20}|" -f $s.LastValue)     -ForegroundColor White
        Write-Host "  +--------------------------------------+" -ForegroundColor Cyan
        Write-Host ""
    }
}


# ============================================================
# A3CENVIRONMENT -- CartPole (self-contained, unique seed per worker)
# ============================================================
# Each worker gets its own environment with a unique random seed.
# This ensures workers explore different starting conditions.
# See VBAF.RL.Environment.ps1 for the shared environment abstraction.

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
        $this.Rng      = [System.Random]::new($seed)   # Unique seed per worker
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
        $gravity   = 9.8; $cartMass = 1.0; $poleMass = 0.1
        $totalMass = $cartMass + $poleMass; $halfLen = 0.25; $dt = 0.02
        $cosA = [Math]::Cos($this.Angle); $sinA = [Math]::Sin($this.Angle)
        $temp = ($force + $poleMass * $halfLen * $this.AngularVelocity * $this.AngularVelocity * $sinA) / $totalMass
        $aAcc = ($gravity * $sinA - $cosA * $temp) / ($halfLen * (4.0/3.0 - $poleMass * $cosA * $cosA / $totalMass))
        $acc  = $temp - $poleMass * $halfLen * $aAcc * $cosA / $totalMass
        $this.Position        += $dt * $this.Velocity
        $this.Velocity        += $dt * $acc
        $this.Angle           += $dt * $this.AngularVelocity
        $this.AngularVelocity += $dt * $aAcc
        $done   = ($this.Steps -ge $this.MaxSteps) -or ([Math]::Abs($this.Position) -gt 2.4) -or ([Math]::Abs($this.Angle) -gt 0.21)
        $reward = if (-not $done) { 1.0 } else { 0.0 }
        return @{ NextState = $this.GetState(); Reward = $reward; Done = $done }
    }
}


# ============================================================
# INVOKE-A3CTRAINING -- the A3C training loop
# ============================================================
#
# THE A3C TRAINING CYCLE:
# -----------------------
# For each episode:
#   For each worker (0 to NumWorkers-1):
#     1. Sync worker local network from global
#     2. Worker runs NSteps rollout
#     3. Global agent updates from worker's batch
#   Record average reward across all workers
#
# NETWORK ARCHITECTURE NOTE:
# --------------------------
# The shared network has (ActionSize + 1) outputs:
#   outputs[0] = logit for action 0
#   outputs[1] = logit for action 1
#   outputs[2] = value estimate V(s)
# This is unusual -- normally a network outputs one type of thing.
# A3C's shared network outputs TWO types (policy + value) from the same layers.

function Invoke-A3CTraining {
    param(
        [int]    $Episodes   = 100,
        [int]    $PrintEvery = 10,
        [switch] $Quiet,
        [switch] $FastMode
    )

    $sharedHidden = @(64, 64)
    $maxSteps     = 200
    $numWorkers   = 4
    $nSteps       = 5

    if ($FastMode) {
        $sharedHidden = @(16, 16)
        $maxSteps     = 30
        $numWorkers   = 2
        $nSteps       = 5
        if ($Episodes   -eq 100) { $Episodes   = 50 }
        if ($PrintEvery -eq 10)  { $PrintEvery  = 5  }
        Write-Host ""
        Write-Host "  FAST MODE -- smaller network, fewer steps" -ForegroundColor Yellow
        Write-Host "   Shared  : 16 -> 16" -ForegroundColor Yellow
        Write-Host "   Workers : $numWorkers" -ForegroundColor Yellow
        Write-Host "   Episodes: $Episodes" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "  VBAF A3C Training" -ForegroundColor Green
    Write-Host "   Episodes: $Episodes" -ForegroundColor Cyan
    Write-Host ""

    $config                = [A3CConfig]::new()
    $config.StateSize      = 4
    $config.ActionSize     = 2
    $config.SharedHidden   = $sharedHidden
    $config.LearningRate   = 0.001
    $config.Gamma          = 0.99
    $config.EntropyBonus   = 0.01
    $config.ValueLossCoeff = 0.5
    $config.NSteps         = $nSteps
    $config.NumWorkers     = $numWorkers
    $config.MaxSteps       = $maxSteps

    # Shared network: outputs ActionSize policy logits + 1 value = ActionSize+1 total
    $layers = [System.Collections.Generic.List[int]]::new()
    $layers.Add($config.StateSize)
    foreach ($h in $config.SharedHidden) { $layers.Add($h) }
    $layers.Add($config.ActionSize + 1)   # policy logits + value head
    $layerArray = $layers.ToArray()

    # Build global network -- the shared model all workers update
    $globalNetwork = [NeuralNetwork]::new($layerArray, $config.LearningRate)

    # Build worker local networks + environments (each with unique seed)
    $workers = [System.Collections.ArrayList]::new()
    $envs    = [System.Collections.ArrayList]::new()

    for ($w = 0; $w -lt $numWorkers; $w++) {
        $localNet = [NeuralNetwork]::new($layerArray, $config.LearningRate)
        $worker   = [A3CWorker]::new($w, $config, $localNet)
        $env      = [A3CEnvironment]::new($w * 13 + 1)   # Unique seed per worker
        $env.MaxSteps = $maxSteps
        $workers.Add($worker) | Out-Null
        $envs.Add($env)       | Out-Null
    }

    $agent = [A3CAgent]::new($config, $globalNetwork, $workers)

    # All workers start with the same global network weights
    foreach ($worker in $workers) { $agent.SyncWorker($worker) }

    $bestReward = 0.0

    for ($ep = 1; $ep -le $Episodes; $ep++) {
        $totalRewardThisEp = 0.0

        for ($w = 0; $w -lt $numWorkers; $w++) {
            $worker = $workers[$w]
            $env    = $envs[$w]

            # Step 1: sync worker from global (get latest knowledge)
            $agent.SyncWorker($worker)

            # Step 2: worker runs NSteps rollout with local network
            $batch = $worker.RunRollout($env)

            # Step 3: update global network from worker's experience
            $agent.UpdateFromWorker($batch, $w)

            $totalRewardThisEp += $worker.LastReward
        }

        $avgEpReward = $totalRewardThisEp / $numWorkers
        $agent.EndEpisode($avgEpReward)
        if ($avgEpReward -gt $bestReward) { $bestReward = $avgEpReward }

        if (-not $Quiet -and ($ep % $PrintEvery -eq 0)) {
            $stats = $agent.GetStats()
            Write-Host ("  Ep {0,4}  Reward: {1,5:F1}  Best: {2,5:F1}  Updates: {3,5}  Entropy: {4:F3}  Loss: {5:F5}" -f `
                $ep, $avgEpReward, $bestReward, $stats.UpdateCount, $stats.LastEntropy, $stats.LastLoss) -ForegroundColor White
        }
    }

    Write-Host ""
    Write-Host "  Training Complete!" -ForegroundColor Green
    $agent.PrintStats()
    ,$agent
}


# ============================================================
# QUICK REFERENCE
# ============================================================
#
# BASIC USAGE:
#   . .\VBAF.LoadAll.ps1
#   $agent = (Invoke-A3CTraining -Episodes 100 -PrintEvery 10)[-1]
#   $agent.PrintStats()
#
# FAST TEST:
#   $agent = (Invoke-A3CTraining -Episodes 20 -PrintEvery 2 -FastMode)[-1]
#
# COMPARE ALL THREE ALGORITHMS:
#   $dqn = (Invoke-DQNTraining -Episodes 100 -FastMode -Quiet)[-1]
#   $ppo = (Invoke-PPOTraining -Episodes 100 -FastMode -Quiet)[-1]
#   $a3c = (Invoke-A3CTraining -Episodes 100 -FastMode -Quiet)[-1]
#   $env = New-VBAFEnvironment -Name "CartPole"
#   Invoke-VBAFBenchmark -Agent $dqn -Environment $env -Episodes 20 -Label "DQN"
#   Invoke-VBAFBenchmark -Agent $ppo -Environment $env -Episodes 20 -Label "PPO"
#   Invoke-VBAFBenchmark -Agent $a3c -Environment $env -Episodes 20 -Label "A3C"
#
# KEY THINGS TO OBSERVE:
#   A3C updates more frequently than PPO (NSteps=5 vs RolloutSteps=64)
#   A3C uses workers to diversify exploration (different seeds)
#   A3C shares the network between actor and critic (one forward pass)
#   LastValue shows what the critic thinks each state is worth
#
# SEE ALSO:
#   VBAF.RL.DQN.ps1  -- value-based, replay buffer, one network
#   VBAF.RL.PPO.ps1  -- policy gradient, two networks, rollout buffer
# ============================================================

Write-Host "  VBAF.RL.A3C.ps1 loaded" -ForegroundColor Green
Write-Host "   Classes  : A3CConfig, A3CAgent, A3CWorker, A3CEnvironment" -ForegroundColor Cyan
Write-Host "   Function : Invoke-A3CTraining"                              -ForegroundColor Cyan
Write-Host ""
Write-Host "   Quick start:" -ForegroundColor Yellow
Write-Host '   $agent = (Invoke-A3CTraining -Episodes 20 -PrintEvery 2 -FastMode)[-1]' -ForegroundColor White
Write-Host '   $agent.PrintStats()' -ForegroundColor White
Write-Host ""