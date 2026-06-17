#Requires -Version 5.1
<#
.SYNOPSIS
    Proximal Policy Optimization (PPO) Agent for Reinforcement Learning
.DESCRIPTION
    Implements the PPO algorithm -- one of the most widely used RL
    algorithms in research and industry today.

    WHAT YOU ARE LEARNING HERE:
    ============================
    PPO is a POLICY GRADIENT method -- a fundamentally different approach
    to RL than Q-learning or DQN.

    Q-LEARNING (what you learned before):
      Learns a VALUE FUNCTION: Q(state, action) = expected future reward
      Chooses the action with the highest Q-value
      Indirect: learn values, then derive policy from values

    PPO (what you are learning now):
      Learns a POLICY DIRECTLY: pi(action | state) = probability of each action
      The policy IS the output -- no value table or Q-table needed
      Direct: learn "what to do" rather than "how good is each option"

    TWO NETWORKS -- ACTOR AND CRITIC:
    ==================================
    PPO uses TWO neural networks working together:

    ACTOR (the policy network):
      Input:  state (4 numbers for CartPole)
      Output: probability for each action [0.3, 0.7] = 30% left, 70% right
      Role:   decides WHAT to do
      Learns: to increase probability of actions that led to high reward

    CRITIC (the value network):
      Input:  state (4 numbers for CartPole)
      Output: one number -- estimated total future reward from this state
      Role:   evaluates HOW GOOD the current situation is
      Learns: to predict total reward accurately

    The Critic helps train the Actor by providing a BASELINE.
    Without a baseline, reward signals are noisy and hard to learn from.
    With a baseline: "this action was better than average" vs "worse than average."

    GENERALIZED ADVANTAGE ESTIMATION (GAE):
    =========================================
    Advantage = "how much better was this action than expected"
    Advantage = actual_return - critic_estimate

    Positive advantage: action led to MORE reward than expected -- do it more
    Negative advantage: action led to LESS reward than expected -- do it less

    GAE smooths the advantage estimate across multiple time steps
    using the lambda parameter (LambdaGAE = 0.95).
    This reduces variance (noisy estimates) at the cost of some bias.

    THE PPO "CLIP" TRICK:
    =====================
    The key innovation in PPO is the CLIPPED UPDATE.

    Older policy gradient methods (TRPO) could make huge policy updates
    that destabilised training -- like overcorrecting a steering wheel.

    PPO solves this by CLIPPING the update ratio:
      ratio = new_probability / old_probability
      clipped_ratio = clip(ratio, 1-epsilon, 1+epsilon)

    ClipEpsilon = 0.2 means:
      If the new policy pushes an action probability more than 20%
      above or below the old probability, the update is clipped.
      This keeps policy changes small and stable each step.

    ROLLOUT BUFFER:
    ===============
    Unlike DQN (which trains on random samples from a replay buffer),
    PPO collects a ROLLOUT -- a fixed-size sequence of recent experiences.
    After RolloutSteps experiences, it trains on ALL of them (UpdateEpochs times),
    then discards them and starts a new rollout.
    This is "on-policy" learning -- the agent learns from its own current behaviour.

    PPO vs DQN -- WHEN TO USE WHICH:
    ==================================
    DQN:  simpler, works well for discrete actions, sample efficient
          uses experience replay (off-policy)
    PPO:  more stable, handles continuous and discrete actions
          widely used in robotics, games (OpenAI Five, AlphaStar)
          on-policy (only learns from current policy's experience)

    THEORY REFERENCE:
    =================
    Schulman, J. et al. (2017). "Proximal Policy Optimization Algorithms."
    ArXiv:1707.06347. OpenAI.

    PPO replaced TRPO as the default policy gradient algorithm at OpenAI.
    It is simpler to implement, more stable, and almost as sample-efficient.

.NOTES
    Part of VBAF (Visual AI & Reinforcement Learning Framework)
    Educational use -- compare with DQN to understand policy vs value methods.
    Requires VBAF.Core.AllClasses.ps1 (loaded via VBAF.LoadAll.ps1)
#>

$basePath = $PSScriptRoot


# ============================================================
# PPOCONFIG -- hyperparameters
# ============================================================
#
# KEY PPO HYPERPARAMETERS:
#
# Gamma = 0.99 -- higher than DQN's 0.95
#   PPO often uses higher gamma because it learns a value function
#   (Critic) that can accurately estimate long-term returns.
#   Higher gamma = agent cares more about distant future rewards.
#
# LambdaGAE = 0.95 -- GAE smoothing factor
#   Controls the tradeoff between variance and bias in advantage estimates.
#   LambdaGAE = 1.0: unbiased but high variance (pure Monte Carlo)
#   LambdaGAE = 0.0: low variance but biased (pure TD error)
#   LambdaGAE = 0.95: standard tradeoff used in the original PPO paper
#
# ClipEpsilon = 0.2 -- the PPO clip range
#   Limits how much the policy can change in one update step.
#   Smaller = more conservative updates (slower but more stable)
#   Larger = faster updates (but risks instability)
#   0.2 is the value used in the original PPO paper.
#
# EntropyBonus = 0.01 -- encourages exploration
#   Adds a bonus for maintaining a diverse (high entropy) policy.
#   Without this, the policy might collapse to always choosing one action.
#   "Entropy" here means how spread out the action probabilities are.
#
# UpdateEpochs = 4 -- training passes per rollout
#   After collecting RolloutSteps experiences, train on them 4 times.
#   More epochs = better use of data but risks overfitting to the rollout.
#
# RolloutSteps = 64 -- collect this many steps before each update
#   Longer rollouts = more stable advantage estimates but slower updates.

class PPOConfig {
    [int]    $StateSize     = 4
    [int]    $ActionSize    = 2
    [int[]]  $ActorHidden   = @(64, 64)   # Actor network architecture
    [int[]]  $CriticHidden  = @(64, 64)   # Critic network architecture
    [double] $LearningRate  = 0.001
    [double] $Gamma         = 0.99        # Higher than DQN -- long-horizon planning
    [double] $LambdaGAE     = 0.95        # GAE smoothing (1.0=unbiased, 0.0=TD)
    [double] $ClipEpsilon   = 0.2         # PPO clip range -- limits policy change
    [double] $EntropyBonus  = 0.01        # Exploration bonus
    [int]    $UpdateEpochs  = 4           # Training passes per rollout
    [int]    $RolloutSteps  = 64          # Steps before each PPO update
    [int]    $MaxSteps      = 200         # Max steps per episode
}


# ============================================================
# PPOAGENT -- the learning agent
# ============================================================
#
# ACTOR-CRITIC ARCHITECTURE:
# --------------------------
# Actor:  [StateSize -> hidden -> ActionSize]  outputs action probabilities
# Critic: [StateSize -> hidden -> 1]           outputs state value estimate
#
# Both networks share the same state input but have different outputs
# and different loss functions.
#
# DEPENDENCY INJECTION (PS 5.1 PATTERN):
# ----------------------------------------
# Same pattern as DQNAgent -- [object] type used for cross-file classes.
# Both Actor and Critic are NeuralNetwork instances built outside this class
# and passed in via the constructor.

class PPOAgent {
    [object] $Actor    # Policy network: state -> action probabilities
    [object] $Critic   # Value network:  state -> expected return
    [object] $Config

    [int]    $TotalSteps     = 0
    [int]    $TotalEpisodes  = 0
    [int]    $UpdateCount    = 0
    [double] $LastActorLoss  = 0.0
    [double] $LastCriticLoss = 0.0
    [double] $LastEntropy    = 0.0   # Higher entropy = more exploration

    [System.Collections.Generic.List[double]] $EpisodeRewards
    [System.Collections.Generic.List[double]] $ActorLossHistory
    [System.Collections.Generic.List[double]] $CriticLossHistory

    # Rollout buffer -- stores RolloutSteps transitions before each update
    hidden [System.Collections.ArrayList] $States
    hidden [System.Collections.ArrayList] $Actions
    hidden [System.Collections.ArrayList] $Rewards
    hidden [System.Collections.ArrayList] $Values    # Critic estimates at each step
    hidden [System.Collections.ArrayList] $LogProbs  # Log probabilities of actions taken
    hidden [System.Collections.ArrayList] $Dones

    hidden [System.Random] $Rng

    PPOAgent([object]$config, [object]$actor, [object]$critic) {
        $this.Config  = $config
        $this.Actor   = $actor
        $this.Critic  = $critic
        $this.Rng     = [System.Random]::new()

        $this.EpisodeRewards    = [System.Collections.Generic.List[double]]::new()
        $this.ActorLossHistory  = [System.Collections.Generic.List[double]]::new()
        $this.CriticLossHistory = [System.Collections.Generic.List[double]]::new()

        $this.ClearRollout()

        Write-Host "  PPOAgent created" -ForegroundColor Green
        Write-Host "   State size    : $($config.StateSize)"                  -ForegroundColor Cyan
        Write-Host "   Action size   : $($config.ActionSize)"                 -ForegroundColor Cyan
        Write-Host "   Actor hidden  : $($config.ActorHidden  -join ' -> ')" -ForegroundColor Cyan
        Write-Host "   Critic hidden : $($config.CriticHidden -join ' -> ')" -ForegroundColor Cyan
        Write-Host "   Clip epsilon  : $($config.ClipEpsilon)"               -ForegroundColor Cyan
        Write-Host "   Rollout steps : $($config.RolloutSteps)"              -ForegroundColor Cyan
    }

    # SOFTMAX: converts raw network outputs (logits) to probabilities.
    # Subtracts the maximum before exp() to prevent numerical overflow.
    # Output: array of values summing to 1.0 -- a proper probability distribution.
    hidden [double[]] Softmax([double[]]$logits) {
        $max  = ($logits | Measure-Object -Maximum).Maximum
        $exps = @(0.0) * $logits.Length
        $sum  = 0.0
        for ($i = 0; $i -lt $logits.Length; $i++) {
            $exps[$i]  = [Math]::Exp($logits[$i] - $max)
            $sum      += $exps[$i]
        }
        $probs = @(0.0) * $logits.Length
        for ($i = 0; $i -lt $logits.Length; $i++) {
            $probs[$i] = $exps[$i] / $sum
        }
        return $probs
    }

    # SAMPLE ACTION: draw one action from the probability distribution.
    # If probs = [0.3, 0.7]: action 0 chosen 30% of the time, action 1 70%.
    # This is STOCHASTIC sampling -- unlike DQN's deterministic argmax.
    # Stochastic policy naturally explores without needing epsilon-greedy.
    hidden [int] SampleAction([double[]]$probs) {
        $r   = $this.Rng.NextDouble()
        $cum = 0.0
        for ($i = 0; $i -lt $probs.Length; $i++) {
            $cum += $probs[$i]
            if ($r -le $cum) { return $i }
        }
        return $probs.Length - 1
    }

    # LOG PROBABILITY: log(P(action)) -- used in the PPO ratio calculation.
    # We use log probabilities instead of raw probabilities because:
    # 1. log(a/b) = log(a) - log(b) -- subtraction is numerically stable
    # 2. Products of small probabilities underflow -- logs prevent this
    # Clamp to 1e-8 to avoid log(0) = -infinity.
    hidden [double] LogProb([double[]]$probs, [int]$action) {
        $p = [Math]::Max($probs[$action], 1e-8)
        return [Math]::Log($p)
    }

    # ENTROPY: measures how spread out the probability distribution is.
    # H = -sum(p * log(p))
    # High entropy: probabilities near equal (0.5, 0.5) -- uncertain, exploring
    # Low entropy:  probabilities extreme (0.0, 1.0) -- confident, exploiting
    # EntropyBonus encourages the agent to maintain some exploration
    # throughout training -- prevents premature convergence to suboptimal policy.
    hidden [double] Entropy([double[]]$probs) {
        $h = 0.0
        foreach ($p in $probs) {
            if ($p -gt 1e-8) { $h -= $p * [Math]::Log($p) }
        }
        return $h
    }

    # ACT: the full Actor-Critic forward pass for one step.
    # Returns Action, LogProb (for PPO ratio), and Value (for GAE).
    # All three are needed by StoreTransition and Update.
    [hashtable] Act([double[]]$state) {
        $logits = $this.Actor.Predict($state)
        $probs  = $this.Softmax($logits)
        $action = $this.SampleAction($probs)   # Stochastic -- natural exploration
        $logP   = $this.LogProb($probs, $action)

        $valueOut = $this.Critic.Predict($state)
        $value    = $valueOut[0]   # Critic outputs one number

        return @{ Action = $action; LogProb = $logP; Value = $value; Probs = $probs }
    }

    # PREDICT: greedy action for evaluation (no sampling -- pick highest probability).
    # Used during benchmarking -- we want the agent's BEST action, not a random sample.
    [int] Predict([double[]]$state) {
        $logits = $this.Actor.Predict($state)
        $probs  = $this.Softmax($logits)
        $best   = 0
        for ($i = 1; $i -lt $probs.Length; $i++) {
            if ($probs[$i] -gt $probs[$best]) { $best = $i }
        }
        return $best
    }

    # Store one transition in the rollout buffer.
    # All five values are needed for the PPO update:
    #   State, Action  -- what happened
    #   Reward         -- what we got
    #   Value          -- what the Critic predicted we would get
    #   LogProb        -- log probability of this action under old policy
    #   Done           -- did the episode end
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

    [void] ClearRollout() {
        $this.States   = [System.Collections.ArrayList]::new()
        $this.Actions  = [System.Collections.ArrayList]::new()
        $this.Rewards  = [System.Collections.ArrayList]::new()
        $this.Values   = [System.Collections.ArrayList]::new()
        $this.LogProbs = [System.Collections.ArrayList]::new()
        $this.Dones    = [System.Collections.ArrayList]::new()
    }

    # COMPUTE GAE -- Generalized Advantage Estimation.
    #
    # For each time step t in the rollout, compute:
    #   delta_t = r_t + gamma * V(s_{t+1}) - V(s_t)    (TD error)
    #   A_t = delta_t + gamma * lambda * A_{t+1}          (GAE recursion)
    #
    # This is computed BACKWARDS through the rollout (t = n-1 down to 0).
    # At episode boundaries (done=true), future advantages are zeroed out.
    #
    # Also computes discounted RETURNS = advantages + values (for Critic training).
    #
    # ADVANTAGE NORMALISATION:
    # Subtract mean and divide by std dev.
    # This keeps advantage values in a consistent range across rollouts,
    # making learning rate and other hyperparameters easier to tune.
    hidden [hashtable] ComputeGAE([double]$lastValue) {
        $n          = $this.Rewards.Count
        $advantages = @(0.0) * $n
        $returns    = @(0.0) * $n
        $gaeVal     = 0.0

        for ($t = $n - 1; $t -ge 0; $t--) {
            $done    = [bool]$this.Dones[$t]
            $reward  = [double]$this.Rewards[$t]
            $value   = [double]$this.Values[$t]
            $nextVal = if ($t -eq $n - 1) { $lastValue } else { [double]$this.Values[$t + 1] }

            if ($done) { $nextVal = 0.0; $gaeVal = 0.0 }  # No future at episode end

            $delta          = $reward + $this.Config.Gamma * $nextVal - $value
            $gaeVal         = $delta + $this.Config.Gamma * $this.Config.LambdaGAE * $gaeVal
            $advantages[$t] = $gaeVal
            $returns[$t]    = $gaeVal + $value
        }

        # Normalise advantages: subtract mean, divide by std dev
        $mean   = ($advantages | Measure-Object -Average).Average
        $sq     = $advantages | ForEach-Object { ($_ - $mean) * ($_ - $mean) }
        $stdDev = [Math]::Sqrt(($sq | Measure-Object -Average).Average + 1e-8)
        for ($i = 0; $i -lt $n; $i++) {
            $advantages[$i] = ($advantages[$i] - $mean) / $stdDev
        }

        return @{ Advantages = $advantages; Returns = $returns }
    }

    # THE PPO UPDATE -- train Actor and Critic on the collected rollout.
    #
    # For each transition in the rollout (repeated UpdateEpochs times):
    #
    # CRITIC UPDATE:
    #   Target = discounted return (computed by GAE)
    #   Train Critic to predict this return accurately
    #   Loss = (predicted_value - return)^2
    #
    # ACTOR UPDATE (the PPO innovation):
    #   ratio = exp(new_log_prob - old_log_prob) = new_prob / old_prob
    #   If ratio > 1+epsilon: policy moved too far toward this action -- clip
    #   If ratio < 1-epsilon: policy moved too far away -- clip
    #   Objective = advantage * clipped_ratio
    #   Train Actor to maximise this clipped objective
    #
    # ENTROPY BONUS:
    #   Add entropy * EntropyBonus to encourage exploration
    #   Prevents policy collapsing to deterministic too quickly
    [void] Update([double]$lastValue) {
        $gae        = $this.ComputeGAE($lastValue)
        $advantages = $gae.Advantages
        $returns    = $gae.Returns
        $n          = $this.States.Count

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

                # Critic update: learn to predict discounted returns
                $criticTarget    = @($ret)
                $criticLoss      = $this.Critic.TrainSample($state, $criticTarget)
                $totalCriticLoss += $criticLoss

                # Actor update: PPO clipped objective
                $logits   = $this.Actor.Predict($state)
                $probs    = $this.Softmax($logits)
                $newLogP  = $this.LogProb($probs, $action)
                $entropy  = $this.Entropy($probs)
                $totalEntropy += $entropy

                # PPO ratio: how much did the policy change for this action
                $ratio     = [Math]::Exp($newLogP - $oldLogProb)
                $clipRatio = [Math]::Max($this.Config.ClipEpsilon * -1,
                             [Math]::Min($this.Config.ClipEpsilon,
                             $ratio - 1.0)) + 1.0

                # Nudge action probability in direction of advantage, clipped
                $effectiveRatio         = [Math]::Min($ratio, $clipRatio)
                $actorTarget            = $probs.Clone()
                $nudge                  = $advantage * $effectiveRatio * 0.1 + $this.Config.EntropyBonus * $entropy
                $actorTarget[$action]   = [Math]::Max(0.01, [Math]::Min(0.99, $probs[$action] + $nudge))

                # Renormalise to keep valid probability distribution
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
        $this.ClearRollout()   # Discard rollout -- on-policy learning
    }

    [void] EndEpisode([double]$totalReward) {
        $this.TotalEpisodes++
        $this.EpisodeRewards.Add($totalReward)
    }

    [hashtable] GetStats() {
        $avgReward     = 0.0
        $avgActorLoss  = 0.0
        $avgCriticLoss = 0.0

        if ($this.EpisodeRewards.Count    -gt 0) { $avgReward     = ($this.EpisodeRewards    | Select-Object -Last 100 | Measure-Object -Average).Average }
        if ($this.ActorLossHistory.Count  -gt 0) { $avgActorLoss  = ($this.ActorLossHistory  | Select-Object -Last 100 | Measure-Object -Average).Average }
        if ($this.CriticLossHistory.Count -gt 0) { $avgCriticLoss = ($this.CriticLossHistory | Select-Object -Last 100 | Measure-Object -Average).Average }

        return @{
            TotalEpisodes  = $this.TotalEpisodes
            TotalSteps     = $this.TotalSteps
            UpdateCount    = $this.UpdateCount
            LastActorLoss  = [Math]::Round($this.LastActorLoss,  6)
            LastCriticLoss = [Math]::Round($this.LastCriticLoss, 6)
            LastEntropy    = [Math]::Round($this.LastEntropy,     4)
            AvgReward100   = [Math]::Round($avgReward,            3)
            AvgActorLoss   = [Math]::Round($avgActorLoss,         6)
            AvgCriticLoss  = [Math]::Round($avgCriticLoss,        6)
        }
    }

    [void] PrintStats() {
        $s = $this.GetStats()
        Write-Host ""
        Write-Host "  +--------------------------------------+" -ForegroundColor Cyan
        Write-Host "  |      PPO Agent Statistics            |" -ForegroundColor Cyan
        Write-Host "  +--------------------------------------+" -ForegroundColor Cyan
        Write-Host ("  |  Episodes      : {0,-20}|" -f $s.TotalEpisodes)   -ForegroundColor White
        Write-Host ("  |  Total Steps   : {0,-20}|" -f $s.TotalSteps)      -ForegroundColor White
        Write-Host ("  |  PPO Updates   : {0,-20}|" -f $s.UpdateCount)     -ForegroundColor White
        Write-Host ("  |  Avg Reward    : {0,-20}|" -f $s.AvgReward100)    -ForegroundColor Green
        Write-Host ("  |  Entropy       : {0,-20}|" -f $s.LastEntropy)     -ForegroundColor Yellow
        Write-Host ("  |  Actor Loss    : {0,-20}|" -f $s.LastActorLoss)   -ForegroundColor Magenta
        Write-Host ("  |  Critic Loss   : {0,-20}|" -f $s.LastCriticLoss)  -ForegroundColor Magenta
        Write-Host "  +--------------------------------------+" -ForegroundColor Cyan
        Write-Host ""
    }
}


# ============================================================
# PPOENVIRONMENT -- CartPole simulation (same physics as DQN)
# ============================================================
# Kept separate from VBAFEnvironment so PPO.ps1 is self-contained.
# See VBAF.RL.Environment.ps1 for the shared environment abstraction.
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
# INVOKE-PPOTRAINING -- the PPO training loop
# ============================================================
#
# THE PPO TRAINING LOOP:
# ----------------------
# For each episode:
#   1. Reset environment
#   2. While not done:
#      a. Call Act() -- Actor picks action stochastically
#      b. Step environment -- get reward and next state
#      c. Call StoreTransition() -- save (s, a, r, V, logP, done)
#      d. If rollout buffer full: call Update(lastValue)
#   3. EndEpisode() -- record total reward
#
# UPDATE FREQUENCY:
# -----------------
# Unlike DQN which updates every 4 steps from a replay buffer,
# PPO updates every RolloutSteps (64) steps from the rollout buffer.
# The rollout is then DISCARDED -- PPO is on-policy.
#
# FAST MODE:
# ----------
# Uses smaller networks (16->16) and shorter episodes (30 steps).
# Reduces training time for quick tests.

function Invoke-PPOTraining {
    param(
        [int]    $Episodes   = 100,
        [int]    $PrintEvery = 10,
        [switch] $Quiet,
        [switch] $FastMode
    )

    $actorHidden  = @(64, 64)
    $criticHidden = @(64, 64)
    $maxSteps     = 200
    $rolloutSteps = 64

    if ($FastMode) {
        $actorHidden  = @(16, 16)
        $criticHidden = @(16, 16)
        $maxSteps     = 30
        $rolloutSteps = 32
        if ($Episodes   -eq 100) { $Episodes   = 50 }
        if ($PrintEvery -eq 10)  { $PrintEvery  = 5  }
        Write-Host ""
        Write-Host "  FAST MODE -- smaller network, fewer steps" -ForegroundColor Yellow
        Write-Host "   Actor/Critic : 16 -> 16" -ForegroundColor Yellow
        Write-Host "   Episodes     : $Episodes" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "  VBAF PPO Training" -ForegroundColor Green
    Write-Host "   Episodes: $Episodes" -ForegroundColor Cyan
    Write-Host ""

    $config                = [PPOConfig]::new()
    $config.StateSize      = 4
    $config.ActionSize     = 2
    $config.ActorHidden    = $actorHidden
    $config.CriticHidden   = $criticHidden
    $config.LearningRate   = 0.001
    $config.Gamma          = 0.99
    $config.LambdaGAE      = 0.95
    $config.ClipEpsilon    = 0.2
    $config.EntropyBonus   = 0.01
    $config.UpdateEpochs   = 4
    $config.RolloutSteps   = $rolloutSteps
    $config.MaxSteps       = $maxSteps

    # Build Actor: [StateSize -> hidden -> ActionSize]
    $actorLayers = [System.Collections.Generic.List[int]]::new()
    $actorLayers.Add($config.StateSize)
    foreach ($h in $config.ActorHidden) { $actorLayers.Add($h) }
    $actorLayers.Add($config.ActionSize)

    # Build Critic: [StateSize -> hidden -> 1]
    $criticLayers = [System.Collections.Generic.List[int]]::new()
    $criticLayers.Add($config.StateSize)
    foreach ($h in $config.CriticHidden) { $criticLayers.Add($h) }
    $criticLayers.Add(1)   # Single value output

    # Instantiate at script level -- PS 5.1 dependency injection
    $actor  = [NeuralNetwork]::new($actorLayers.ToArray(),  $config.LearningRate)
    $critic = [NeuralNetwork]::new($criticLayers.ToArray(), $config.LearningRate)
    $agent  = [PPOAgent]::new($config, $actor, $critic)

    $env          = [PPOEnvironment]::new()
    $env.MaxSteps = $maxSteps

    $bestReward  = 0.0
    $stepCounter = 0

    for ($ep = 1; $ep -le $Episodes; $ep++) {
        $state       = $env.Reset()
        $totalReward = 0.0
        $done        = $false

        while (-not $done) {
            $result  = $agent.Act($state)
            $action  = $result.Action
            $logProb = $result.LogProb
            $value   = $result.Value

            $step    = $env.Step($action)
            $ns      = $step.NextState
            $reward  = $step.Reward
            $done    = $step.Done

            $agent.StoreTransition($state, $action, $reward, $value, $logProb, $done)
            $state        = $ns
            $totalReward += $reward
            $stepCounter++

            # Update when rollout buffer is full
            if ($stepCounter % $config.RolloutSteps -eq 0) {
                $lastVal = $agent.Critic.Predict($state)[0]
                $agent.Update($lastVal)
            }
        }

        $agent.EndEpisode($totalReward)
        if ($totalReward -gt $bestReward) { $bestReward = $totalReward }

        if (-not $Quiet -and ($ep % $PrintEvery -eq 0)) {
            $stats = $agent.GetStats()
            Write-Host ("  Ep {0,4}  Reward: {1,5:F0}  Best: {2,5:F0}  Updates: {3,4}  Entropy: {4:F3}  CriticLoss: {5:F5}" -f `
                $ep, $totalReward, $bestReward, $stats.UpdateCount, $stats.LastEntropy, $stats.LastCriticLoss) -ForegroundColor White
        }
    }

    # Final update on any remaining rollout steps
    if ($agent.States.Count -gt 0) { $agent.Update(0.0) }

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
#   $agent = (Invoke-PPOTraining -Episodes 100 -PrintEvery 10)[-1]
#   $agent.PrintStats()
#
# FAST TEST:
#   $agent = (Invoke-PPOTraining -Episodes 5 -PrintEvery 1 -FastMode)[-1]
#
# COMPARE WITH DQN:
#   $dqn = (Invoke-DQNTraining -Episodes 100 -FastMode)[-1]
#   $ppo = (Invoke-PPOTraining -Episodes 100 -FastMode)[-1]
#   $env = New-VBAFEnvironment -Name "CartPole"
#   Invoke-VBAFBenchmark -Agent $dqn -Environment $env -Episodes 20 -Label "DQN"
#   Invoke-VBAFBenchmark -Agent $ppo -Environment $env -Episodes 20 -Label "PPO"
#
# KEY DIFFERENCES FROM DQN TO WATCH:
#   DQN: Epsilon decays from 1.0 to 0.01 (explore-exploit shift)
#   PPO: Entropy decreases as policy becomes more confident
#   DQN: One network (Q-values)
#   PPO: Two networks (Actor + Critic)
#   DQN: Off-policy (replay buffer with old experiences)
#   PPO: On-policy (rollout buffer discarded after each update)
#
# SEE ALSO:
#   VBAF.RL.DQN.ps1   -- Q-value based alternative
#   VBAF.RL.A3C.ps1   -- asynchronous actor-critic (next algorithm)
# ============================================================

Write-Host "  VBAF.RL.PPO.ps1 loaded" -ForegroundColor Green
Write-Host "   Classes  : PPOConfig, PPOAgent, PPOEnvironment" -ForegroundColor Cyan
Write-Host "   Function : Invoke-PPOTraining"                  -ForegroundColor Cyan
Write-Host ""
Write-Host "   Quick start:" -ForegroundColor Yellow
Write-Host '   $agent = (Invoke-PPOTraining -Episodes 50 -PrintEvery 5 -FastMode)[-1]' -ForegroundColor White
Write-Host '   $agent.PrintStats()' -ForegroundColor White
Write-Host ""