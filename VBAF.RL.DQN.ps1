#Requires -Version 5.1
<#
.SYNOPSIS
    Deep Q-Network (DQN) Agent for Reinforcement Learning
.DESCRIPTION
    Implements the DQN algorithm — the breakthrough that made
    reinforcement learning work on complex problems.

    WHAT YOU ARE LEARNING HERE:
    ════════════════════════════
    DQN combines two powerful ideas:

      1. Q-LEARNING — a reinforcement learning algorithm that learns
         the VALUE of taking each action in each state. The agent
         tries to maximise its total future reward.

      2. NEURAL NETWORK — used to APPROXIMATE the Q-values, because
         storing a table of every possible state is impossible for
         complex problems like games or robotics.

    DQN was published by DeepMind in 2013 and shocked the world by
    learning to play 49 Atari games from raw pixels — better than
    a human expert at many of them — using the same algorithm with
    the same hyperparameters for every game.

    This file implements the same algorithm. Instead of Atari pixels,
    we use a CartPole simulation (balance a pole on a moving cart).

    THREE KEY INNOVATIONS IN DQN:
    ══════════════════════════════
    1. EXPERIENCE REPLAY — store past experiences and train on random
       batches. Breaks the correlation between consecutive experiences
       that would otherwise destabilise training.

    2. TARGET NETWORK — a second copy of the network that provides
       stable training targets. Without it, the network chases a
       moving target and training often diverges.

    3. EPSILON-GREEDY EXPLORATION — start by exploring randomly
       (epsilon = 1.0), gradually shift to exploiting what was learned
       (epsilon decays toward 0.01). This is the explore-exploit tradeoff.

    THEORY REFERENCE:
    ═════════════════
    Mnih, V. et al. (2013). "Playing Atari with Deep Reinforcement Learning."
    ArXiv:1312.5602. DeepMind Technologies.

    Mnih, V. et al. (2015). "Human-level control through deep reinforcement
    learning." Nature, 518, 529–533.

    READ IN ORDER:
    ══════════════
    DQNConfig → DQNEnvironment → DQNAgent → Invoke-DQNTraining
.NOTES
    Part of VBAF (Visual AI & Reinforcement Learning Framework)
    Educational use — read the comments, not just the code.
    Requires VBAF.Core.AllClasses.ps1 and VBAF.RL.ExperienceReplay.ps1
    (loaded automatically by VBAF.LoadAll.ps1)
#>

$basePath = $PSScriptRoot


# ============================================================================
# DQNCONFIG — hyperparameters
# ============================================================================
#
# WHAT ARE HYPERPARAMETERS?
# ─────────────────────────
# Hyperparameters are settings chosen BEFORE training begins.
# They control how the agent learns — not what it learns.
# Finding good hyperparameters is part art, part science.
#
# KEY HYPERPARAMETERS EXPLAINED:
#
# Gamma (γ) = 0.95 — DISCOUNT FACTOR
#   How much the agent values FUTURE rewards vs IMMEDIATE rewards.
#   γ = 0: agent only cares about immediate reward (greedy, short-sighted)
#   γ = 1: agent values future rewards equally to immediate ones
#   γ = 0.95: reward 10 steps away is worth 0.95^10 ≈ 0.60 of immediate reward
#   Intuition: a reward tomorrow is worth slightly less than a reward today.
#
# Epsilon (ε) = 1.0 → 0.01 — EXPLORATION RATE
#   Probability of taking a RANDOM action instead of the best known action.
#   ε = 1.0: completely random (pure exploration at the start)
#   ε = 0.01: 99% exploit best action, 1% random (mostly exploitation)
#   EpsilonDecay: multiply epsilon by 0.995 after each training batch
#   This is the explore-exploit tradeoff — explore first, exploit later.
#
# BatchSize = 32 — EXPERIENCE REPLAY BATCH
#   Number of past experiences sampled from memory for each training step.
#   Larger batches = more stable but slower training.
#   32-64 is typical in DQN literature.
#
# TargetUpdateFreq = 10 — HOW OFTEN TO SYNC TARGET NETWORK
#   Every 10 episodes, copy main network weights to target network.
#   Less frequent = more stable targets but slower learning.

class DQNConfig {
    [int]    $StateSize        = 4      # Dimensions in the observation (e.g. position, velocity, angle, angular velocity)
    [int]    $ActionSize       = 2      # Number of possible actions (e.g. push left / push right)
    [int[]]  $HiddenLayers     = @(64, 64)  # Neurons in each hidden layer
    [double] $LearningRate     = 0.001  # How fast the neural network updates its weights
    [double] $Gamma            = 0.95   # Discount factor for future rewards
    [double] $Epsilon          = 1.0    # Starting exploration rate (100% random)
    [double] $EpsilonMin       = 0.01   # Minimum exploration rate (1% random)
    [double] $EpsilonDecay     = 0.995  # Multiply epsilon by this after each replay
    [int]    $BatchSize        = 32     # Experiences sampled per training step
    [int]    $MemorySize       = 10000  # Maximum experiences stored in replay buffer
    [int]    $TargetUpdateFreq = 10     # Sync target network every N episodes
    [string] $Activation       = "relu" # Activation function for hidden layers
}


# ============================================================================
# DQNAGENT — the learning agent
# ============================================================================
#
# THE Q-LEARNING FOUNDATION:
# ──────────────────────────
# Q-learning learns a function Q(state, action) that estimates the
# TOTAL FUTURE REWARD of taking action A in state S, then following
# the best policy afterwards.
#
# The Q-value update rule (Bellman equation):
#   Q(s,a) = reward + γ × max[Q(s', a')]
#   Where s' is the next state and a' is the best action in that state.
#
# Interpretation: the value of (state, action) equals the immediate
# reward PLUS the discounted value of the best next move.
#
# WHY TWO NETWORKS (MAIN + TARGET)?
# ───────────────────────────────────
# Without a target network, we would use the same network to both
# PREDICT Q-values AND generate the TARGET Q-values we are training toward.
# This is like trying to hit a moving target — the network keeps
# changing what it is trying to learn, which causes unstable training.
#
# Solution: keep a COPY of the network (target) that updates slowly.
# Main network: trained every step — learns quickly
# Target network: updated every 10 episodes — provides stable targets
#
# THE DEPENDENCY INJECTION PATTERN:
# ────────────────────────────────────
# Notice the constructor receives pre-built network objects ([object] type).
# This is because PowerShell 5.1 cannot reference external class types
# inside a class definition — the parser fails at load time.
# By using [object] and passing instances in, we sidestep this limitation.
# This is called dependency injection — a common software design pattern.

class DQNAgent {
    [object] $MainNetwork     # The network being actively trained
    [object] $TargetNetwork   # Stable copy — provides training targets
    [object] $Memory          # Experience replay buffer
    [object] $Config          # All hyperparameters

    [int]    $ActionSize
    [double] $Epsilon         # Current exploration rate (decays over time)
    [int]    $TotalSteps    = 0   # Total environment interactions
    [int]    $TotalEpisodes = 0   # Total episodes completed
    [int]    $TrainingSteps = 0   # Total neural network training steps
    [double] $LastLoss      = 0.0 # Most recent training loss

    [System.Collections.Generic.List[double]] $EpisodeRewards  # Reward per episode
    [System.Collections.Generic.List[double]] $LossHistory     # Loss per training step

    hidden [System.Random] $Rng

    # Constructor: receives all dependencies as pre-built objects.
    # Networks are built OUTSIDE this class and injected in.
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

        # At the start, target and main networks have the same random weights.
        # As training progresses, main updates every step but target only
        # updates every TargetUpdateFreq episodes.
        $this.SyncTargetNetwork()

        Write-Host "  DQNAgent created" -ForegroundColor Green
        Write-Host "   State size  : $($config.StateSize)"                    -ForegroundColor Cyan
        Write-Host "   Action size : $($config.ActionSize)"                   -ForegroundColor Cyan
        Write-Host "   Hidden      : $($config.HiddenLayers -join ' -> ')"   -ForegroundColor Cyan
        Write-Host "   Memory      : $($config.MemorySize)"                   -ForegroundColor Cyan
        Write-Host "   Batch size  : $($config.BatchSize)"                    -ForegroundColor Cyan
    }

    # Store one experience in the replay buffer.
    # (state, action, reward, nextState, done) is called a "transition" or "experience".
    # Done = true means the episode ended (pole fell, cart went out of bounds).
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

    # EPSILON-GREEDY ACTION SELECTION:
    # ─────────────────────────────────
    # With probability ε: take a RANDOM action (explore)
    # With probability 1-ε: take the action with highest Q-value (exploit)
    #
    # Early in training (ε ≈ 1.0): almost always random — discovers new things
    # Late in training (ε ≈ 0.01): almost always greedy — uses what it learned
    #
    # Why explore at all? Without exploration, the agent might never discover
    # that a better strategy exists — it gets stuck in a local optimum.
    [int] Act([double[]]$state) {
        if ($this.Rng.NextDouble() -le $this.Epsilon) {
            # Explore: random action
            return $this.Rng.Next(0, $this.ActionSize)
        }
        # Exploit: choose action with highest Q-value
        $qValues = $this.MainNetwork.Predict($state)
        return [DQNAgent]::ArgMax($qValues)
    }

    # Greedy action selection — no exploration.
    # Used for EVALUATION (testing) not training.
    # Always picks the best known action.
    [int] Predict([double[]]$state) {
        $qValues = $this.MainNetwork.Predict($state)
        return [DQNAgent]::ArgMax($qValues)
    }

    # Return the raw Q-values for all actions in this state.
    # Useful for inspecting what the agent has learned:
    #   High Q-value for action 0 = agent thinks pushing left is good here
    #   Low Q-value for action 1  = agent thinks pushing right is bad here
    [double[]] GetQValues([double[]]$state) {
        return $this.MainNetwork.Predict($state)
    }

    # THE CORE TRAINING STEP — EXPERIENCE REPLAY:
    # ────────────────────────────────────────────
    # 1. Sample a random batch of past experiences from memory
    # 2. For each experience, compute the TARGET Q-value using Bellman equation:
    #       If episode ended: target = reward  (no future)
    #       Otherwise:        target = reward + γ × max[Q_target(next_state)]
    # 3. Train main network to predict these targets
    # 4. Decay epsilon (explore less over time)
    #
    # WHY RANDOM SAMPLING?
    # ────────────────────
    # Consecutive experiences are highly correlated — cart moving left,
    # then left, then left. Training on sequences like this causes the
    # network to overfit to recent experiences and forget earlier ones.
    # Random sampling breaks these correlations.
    [double] Replay() {
        if ($this.Memory.Size() -lt $this.Config.BatchSize) {
            return 0.0   # Not enough experiences yet — wait
        }

        $batch     = $this.Memory.Sample($this.Config.BatchSize)
        $totalLoss = 0.0

        foreach ($exp in $batch) {
            $state     = $exp.State
            $action    = $exp.Action
            $reward    = $exp.Reward
            $nextState = $exp.NextState
            $done      = $exp.Done

            # Get current Q-value predictions for this state
            $target = $this.MainNetwork.Predict($state)

            if ($done) {
                # Episode ended — no future rewards, target is just the reward
                $target[$action] = $reward
            } else {
                # Bellman equation: target = reward + γ × max Q(next_state)
                # Note: we use TARGET network here for stability
                $nextQ           = $this.TargetNetwork.Predict($nextState)
                $maxNextQ        = ($nextQ | Measure-Object -Maximum).Maximum
                $target[$action] = $reward + $this.Config.Gamma * $maxNextQ
            }

            # Train main network — push Q(state, action) toward the target
            $this.MainNetwork.TrainSample($state, $target)
            $this.TrainingSteps++

            # Measure how far off our prediction was (for monitoring)
            $currentQ  = $this.MainNetwork.Predict($state)
            $diff      = $currentQ[$action] - $target[$action]
            $totalLoss += $diff * $diff
        }

        # EPSILON DECAY — explore less as training progresses
        # Multiply by 0.995 each time → reaches 0.01 after ~900 replays
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

    # Copy ALL weights from main network to target network.
    # Called at the start and every TargetUpdateFreq episodes.
    # This is a "hard update" — the alternative is a "soft update"
    # that blends weights gradually: target = τ×main + (1-τ)×target
    [void] SyncTargetNetwork() {
        $state = $this.MainNetwork.ExportState()
        $this.TargetNetwork.ImportState($state)
    }

    # Called at the end of each episode.
    # Records the total reward and triggers a target network sync
    # every TargetUpdateFreq episodes.
    [void] EndEpisode([double]$totalReward) {
        $this.TotalEpisodes++
        $this.EpisodeRewards.Add($totalReward)

        if ($this.TotalEpisodes % $this.Config.TargetUpdateFreq -eq 0) {
            $this.SyncTargetNetwork()
            Write-Host "   Target network synced (Episode $($this.TotalEpisodes))" -ForegroundColor DarkYellow
        }
    }

    # Return training statistics — useful for monitoring learning progress.
    # AvgReward100 and AvgLoss100 average over the last 100 episodes.
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

    [void] PrintStats() {
        $s = $this.GetStats()
        Write-Host ""
        Write-Host "  +--------------------------------------+" -ForegroundColor Cyan
        Write-Host "  |      DQN Agent Statistics            |" -ForegroundColor Cyan
        Write-Host "  +--------------------------------------+" -ForegroundColor Cyan
        Write-Host ("  |  Episodes     : {0,-20}|" -f $s.TotalEpisodes)  -ForegroundColor White
        Write-Host ("  |  Total Steps  : {0,-20}|" -f $s.TotalSteps)     -ForegroundColor White
        Write-Host ("  |  Train Steps  : {0,-20}|" -f $s.TrainingSteps)  -ForegroundColor White
        Write-Host ("  |  Memory Used  : {0,-20}|" -f $s.MemorySize)     -ForegroundColor White
        Write-Host ("  |  Epsilon      : {0,-20}|" -f $s.Epsilon)        -ForegroundColor Yellow
        Write-Host ("  |  Last Loss    : {0,-20}|" -f $s.LastLoss)       -ForegroundColor Magenta
        Write-Host ("  |  Avg Reward   : {0,-20}|" -f $s.AvgReward100)  -ForegroundColor Green
        Write-Host ("  |  Avg Loss     : {0,-20}|" -f $s.AvgLoss100)    -ForegroundColor Magenta
        Write-Host "  +--------------------------------------+" -ForegroundColor Cyan
        Write-Host ""
    }

    # Return the index of the largest value in an array.
    # Used to find the action with the highest Q-value.
    static [int] ArgMax([double[]]$arr) {
        $best = 0
        for ($i = 1; $i -lt $arr.Length; $i++) {
            if ($arr[$i] -gt $arr[$best]) { $best = $i }
        }
        return $best
    }
}


# ============================================================================
# DQNENVIRONMENT — CartPole simulation
# ============================================================================
#
# WHAT IS CARTPOLE?
# ─────────────────
# CartPole is the "Hello World" of reinforcement learning.
# A pole is attached to a cart that moves left and right.
# The agent must keep the pole balanced by pushing the cart.
#
# STATE (what the agent observes):
#   [position, velocity, angle, angular_velocity]
#   4 continuous values — too many states for a simple Q-table,
#   which is why we need a neural network to approximate Q-values.
#
# ACTIONS (what the agent can do):
#   0 = push cart left
#   1 = push cart right
#
# REWARD:
#   +1 for every time step the pole stays balanced
#   Episode ends if pole falls (|angle| > 0.21 rad ≈ 12°)
#   or cart goes out of bounds (|position| > 2.4)
#   or MaxSteps is reached (success!)
#
# PHYSICS (simplified Newtonian mechanics):
#   The Step() method applies real physics equations for a cart-pole system.
#   These are the standard CartPole equations from the control systems literature.
#   You do not need to understand them to learn RL — treat Step() as a black box
#   that takes an action and returns what happens next.

class DQNEnvironment {
    [double] $Position          # Cart position on the track
    [double] $Velocity          # Cart velocity
    [double] $Angle             # Pole angle from vertical (radians)
    [double] $AngularVelocity   # Pole rotation speed
    [int]    $Steps             # Steps taken in current episode
    [int]    $MaxSteps          # Episode ends after this many steps (success)
    hidden [System.Random] $Rng

    DQNEnvironment() {
        $this.MaxSteps = 200
        $this.Rng      = [System.Random]::new()
        $this.Reset()
    }

    # Reset to a new random starting state.
    # Small random perturbations prevent the agent from memorising a fixed sequence.
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

    # Apply action to the environment using simplified CartPole physics.
    # Returns: NextState, Reward, Done
    # This is a standard control systems simulation — treat as a black box.
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

        # Episode ends if pole falls or cart goes out of bounds
        $done   = ($this.Steps -ge $this.MaxSteps) -or
                  ([Math]::Abs($this.Position) -gt 2.4) -or
                  ([Math]::Abs($this.Angle)    -gt 0.21)

        # +1 reward for every step the pole stays balanced
        $reward = if (-not $done) { 1.0 } else { 0.0 }

        return @{ NextState = $this.GetState(); Reward = $reward; Done = $done }
    }
}


# ============================================================================
# INVOKE-DQNTRAINING — the training loop
# ============================================================================
#
# THE COMPLETE DQN TRAINING LOOP:
# ────────────────────────────────
# For each episode:
#   1. Reset environment to a new random starting state
#   2. While not done:
#      a. Agent OBSERVES the current state
#      b. Agent ACTS (epsilon-greedy: explore or exploit)
#      c. Environment RESPONDS with next state, reward, done
#      d. Agent REMEMBERS the experience (state, action, reward, next, done)
#      e. Every 4 steps: agent REPLAYS (trains on random batch from memory)
#   3. End episode: record total reward, sync target network if needed
#
# WHAT TO WATCH DURING TRAINING:
# ────────────────────────────────
# Epsilon:    starts at 1.0, decays to 0.01 — less exploration over time
# Reward:     starts low (pole falls quickly), should increase as agent learns
# Loss:       training error — may be noisy but should trend downward
# Memory:     fills up as agent gains experience — must reach BatchSize to train
#
# REPLAY EVERY 4 STEPS (-replayEvery 4):
# ────────────────────────────────────────
# We only train every 4 environment steps rather than every step.
# This gives the agent time to collect diverse experiences between
# training steps, and dramatically speeds up overall training.
#
# FASTMODE:
# ─────────
# Uses smaller networks (16→16 vs 64→64) and fewer steps per episode.
# Good for testing the code works before committing to a full training run.

function Invoke-DQNTraining {
    param(
        [int]    $Episodes   = 100,   # Total episodes to train for
        [int]    $PrintEvery = 10,    # Print progress every N episodes
        [switch] $Quiet,              # Suppress progress output
        [switch] $FastMode            # Use smaller network and fewer steps
    )

    $hiddenLayers = @(64, 64)
    $batchSize    = 32
    $maxSteps     = 200
    $replayEvery  = 4   # Train every N environment steps

    if ($FastMode) {
        $hiddenLayers = @(16, 16)
        $batchSize    = 16
        $maxSteps     = 30
        if ($Episodes -eq 100)  { $Episodes   = 50 }
        if ($PrintEvery -eq 10) { $PrintEvery = 5  }
        Write-Host ""
        Write-Host "  FAST MODE — smaller network, fewer steps" -ForegroundColor Yellow
        Write-Host "   Hidden   : 16 -> 16" -ForegroundColor Yellow
        Write-Host "   Episodes : $Episodes" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "  VBAF DQN Training" -ForegroundColor Green
    Write-Host "   Episodes: $Episodes" -ForegroundColor Cyan
    Write-Host ""

    # Build config
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

    # Build layer array: [StateSize, hidden1, hidden2, ActionSize]
    $layers = [System.Collections.Generic.List[int]]::new()
    $layers.Add($config.StateSize)
    foreach ($h in $config.HiddenLayers) { $layers.Add($h) }
    $layers.Add($config.ActionSize)
    $layerArray = $layers.ToArray()

    # Instantiate networks at script level — PS 5.1 requires this
    # because class definitions cannot reference external types at parse time.
    # These objects are then INJECTED into DQNAgent via its constructor.
    $mainNetwork   = [NeuralNetwork]::new($layerArray, $config.LearningRate)
    $targetNetwork = [NeuralNetwork]::new($layerArray, $config.LearningRate)
    $memory        = [ExperienceReplay]::new($config.MemorySize)

    $agent        = [DQNAgent]::new($config, $mainNetwork, $targetNetwork, $memory)
    $env          = [DQNEnvironment]::new()
    $env.MaxSteps = $maxSteps

    $bestReward = 0.0
    $stepCount  = 0

    # ── MAIN TRAINING LOOP ───────────────────────────────────────────────────
    for ($ep = 1; $ep -le $Episodes; $ep++) {
        $state       = $env.Reset()   # New episode — random starting state
        $totalReward = 0.0
        $done        = $false

        while (-not $done) {
            $action  = $agent.Act($state)        # Choose action (explore or exploit)
            $result  = $env.Step($action)        # Apply action to environment
            $ns      = $result.NextState
            $reward  = $result.Reward
            $done    = $result.Done

            $agent.Remember($state, $action, $reward, $ns, $done)   # Store experience
            $stepCount++

            # Train every 4 steps — not every step
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
    Write-Host "  Training Complete!" -ForegroundColor Green
    $agent.PrintStats()

    # Comma operator forces PowerShell to return as single object, not unwrap array
    ,$agent
}


# ============================================================================
# QUICK REFERENCE
# ============================================================================
#
# BASIC USAGE:
#   . .\VBAF.LoadAll.ps1
#   $agent = (Invoke-DQNTraining -Episodes 100 -PrintEvery 10)[-1]
#   $agent.PrintStats()
#
# FAST TEST (seconds):
#   $agent = (Invoke-DQNTraining -Episodes 5 -PrintEvery 1 -FastMode)[-1]
#
# INSPECT WHAT THE AGENT LEARNED:
#   $state = @(0.1, 0.0, 0.05, 0.0)   # sample CartPole state
#   $agent.GetQValues($state)           # Q-value for each action
#   $agent.Predict($state)              # best action (0=left, 1=right)
#
# MONITOR LEARNING:
#   Watch epsilon decay from 1.0 toward 0.01 — explore → exploit
#   Watch reward increase as agent learns to balance longer
#   Watch loss decrease as Q-value predictions become more accurate
#
# SEE ALSO:
#   VBAF.Core.AllClasses.ps1       — the NeuralNetwork powering this agent
#   VBAF.RL.ExperienceReplay.ps1   — the replay buffer implementation
#   VBAF.RL.QLearningAgent.ps1     — simpler Q-learning without neural network
#   examples\02-Castle-Learning\   — DQN applied to a multi-agent game
# ============================================================================

Write-Host "  VBAF.RL.DQN.ps1 loaded" -ForegroundColor Green
Write-Host "   Classes : DQNConfig, DQNAgent, DQNEnvironment" -ForegroundColor Cyan
Write-Host "   Function: Invoke-DQNTraining"                  -ForegroundColor Cyan
Write-Host ""
Write-Host "   Quick start:" -ForegroundColor Yellow
Write-Host '   $agent = (Invoke-DQNTraining -Episodes 100 -PrintEvery 10)[-1]'         -ForegroundColor White
Write-Host '   $agent = (Invoke-DQNTraining -Episodes 50 -PrintEvery 5 -FastMode)[-1]' -ForegroundColor White
Write-Host '   $agent.PrintStats()'                                                     -ForegroundColor White
Write-Host ""