#Requires -Version 5.1

<#
.SYNOPSIS
    Q-Learning Agent for Reinforcement Learning
.DESCRIPTION
    Implements the Q-Learning algorithm -- the foundation that DQN builds upon.

    WHAT YOU ARE LEARNING HERE:
    ============================
    Q-Learning is the simplest form of reinforcement learning that works
    for discrete state and action spaces. Before neural networks were used,
    this was the dominant approach.

    The key idea: maintain a TABLE of values Q(state, action) that estimates
    the total future reward of taking each action in each state.
    Over many episodes, these values converge to the optimal policy.

    Q-LEARNING vs DQN -- THE KEY DIFFERENCE:
    =========================================
    Q-Learning uses a HASHTABLE to store Q-values.
    Each (state, action) pair maps directly to a number.
    This works when the number of states is small and discrete.

    DQN uses a NEURAL NETWORK to APPROXIMATE Q-values.
    The network generalises across similar states.
    This works when states are continuous or too numerous for a table.

    Example:
      Q-Learning: "state 5, action LEFT = 2.3" (stored in table)
      DQN:        "given these sensor readings, LEFT looks worth 2.3"
                  (computed by neural network)

    THE Q-LEARNING UPDATE RULE (Bellman equation):
    ================================================
    Q(s,a) <- Q(s,a) + alpha x [r + gamma x max Q(s',a') - Q(s,a)]
    Where:
      alpha (alpha)  = learning rate -- how fast to update
      gamma (gamma)  = discount factor -- how much to value future rewards
      r          = immediate reward received
      s'         = next state after taking action
      max Q(s')  = best possible future Q-value from the next state
      TD error   = r + gamma x max Q(s',a') - Q(s,a) -- how wrong we were

    INTUITION:
    ==========
    "I thought action LEFT in state 5 was worth 2.3.
     I tried it. Got reward 1.0. From the next state, the best
     I can expect is 1.8. So the true value is 1.0 + 0.9x1.8 = 2.62.
     I was wrong by 0.32. Update my estimate toward the truth."

    This is called Temporal Difference (TD) learning -- updating estimates
    based on other estimates, without waiting for the episode to end.

    THEORY REFERENCE:
    =================
    Watkins, C.J.C.H. (1989). "Learning from Delayed Rewards."
    PhD thesis, Cambridge University.

    Watkins, C.J.C.H. & Dayan, P. (1992). "Q-learning."
    Machine Learning, 8(3-4), 279-292.

    READ IN ORDER:
    ==============
    Constructor -> GetQValue/SetQValue -> ChooseAction -> Learn -> EndEpisode

.NOTES
    Part of VBAF (Visual AI & Reinforcement Learning Framework)
    Educational use -- read the comments, not just the code.
    Compare with VBAF.RL.DQN.ps1 to see how neural networks extend Q-learning.
#>

$basePath = $PSScriptRoot

. (Join-Path $basePath "VBAF.RL.QTable.ps1")
. (Join-Path $basePath "VBAF.RL.ExperienceReplay.ps1")


# ============================================================================
# QLEARNINGAGENT
# ============================================================================
#
# STATE REPRESENTATION:
# ---------------------
# In this implementation, states are STRINGS -- human-readable descriptions
# of the current situation (e.g. "TowerA|TowerB" = last two castle types).
# This makes Q-learning easy to inspect and debug:
#   agent.QTable["START|LEFT"] = 2.3   <- you can READ what the agent learned
#
# Compare with DQN where state is an array of numbers and Q-values
# are hidden inside neural network weights -- much harder to interpret.
#
# HASHTABLE AS Q-TABLE:
# ---------------------
# The Q-table is a PowerShell hashtable: @{}
# Keys are "$state|$action" strings (e.g. "TowerA|TowerB|LEFT")
# Values are the learned Q-values (doubles)
# If a state-action pair has never been seen, it defaults to 0.0
#
# This sparse representation is efficient -- only visited states are stored.
# A DQN would generalise to unseen states via the neural network.
# A Q-table cannot -- it can only learn from states it has actually visited.

class QLearningAgent {

    # -- Core Q-learning components --------------------------------------------
    [string[]]$Actions          # All available actions the agent can take
    [hashtable]$QTable          # The learned value table: state+action -> value
    [double]$LearningRate       # alpha (alpha): how fast to update Q-values
    [double]$DiscountFactor     # gamma (gamma): how much to value future rewards
    [double]$Epsilon            # Current exploration rate (1.0 = random, 0.01 = greedy)
    [double]$EpsilonDecay       # Multiply epsilon by this after each episode
    [double]$MinEpsilon         # Minimum exploration rate -- never goes below this

    # -- Statistics tracking ---------------------------------------------------
    [int]$TotalSteps            # Total number of (state, action, reward) steps taken
    [int]$TotalEpisodes         # Total episodes completed
    [double]$TotalReward        # Cumulative reward across all episodes
    [System.Collections.ArrayList]$EpisodeRewards  # Reward per episode -- track progress
    [int]$ExplorationCount      # How many times agent chose randomly (explore)
    [int]$ExploitationCount     # How many times agent chose best known action (exploit)

    # -- Aliases (for compatibility with other VBAF modules) -------------------
    [double]$Alpha              # Same as LearningRate
    [double]$Gamma              # Same as DiscountFactor
    [int]$Episode               # Same as TotalEpisodes
    [int]$MemorySize            # Always 0 for Q-learning (no replay buffer)

    # Default constructor -- sensible defaults for most problems
    QLearningAgent([string[]]$actions) {
        $this.Actions         = $actions
        $this.QTable          = @{}
        $this.LearningRate    = 0.1      # alpha = 0.1 -- moderate learning speed
        $this.DiscountFactor  = 0.9      # gamma = 0.9 -- values future rewards highly
        $this.Epsilon         = 1.0      # Start fully random -- explore everything
        $this.EpsilonDecay    = 0.995    # Decay 0.5% per episode
        $this.MinEpsilon      = 0.01     # Always keep 1% randomness
        $this.TotalSteps      = 0
        $this.TotalEpisodes   = 0
        $this.TotalReward     = 0.0
        $this.EpisodeRewards  = New-Object System.Collections.ArrayList
        $this.ExplorationCount   = 0
        $this.ExploitationCount  = 0
        $this.Alpha           = $this.LearningRate
        $this.Gamma           = $this.DiscountFactor
        $this.Episode         = 0
        $this.MemorySize      = 0
    }

    # Full constructor -- custom learning rate and starting epsilon
    QLearningAgent([string[]]$actions, [double]$learningRate, [double]$epsilon) {
        $this.Actions         = $actions
        $this.QTable          = @{}
        $this.LearningRate    = $learningRate
        $this.DiscountFactor  = 0.9
        $this.Epsilon         = $epsilon
        $this.EpsilonDecay    = 0.995
        $this.MinEpsilon      = 0.01
        $this.TotalSteps      = 0
        $this.TotalEpisodes   = 0
        $this.TotalReward     = 0.0
        $this.EpisodeRewards  = New-Object System.Collections.ArrayList
        $this.ExplorationCount   = 0
        $this.ExploitationCount  = 0
        $this.Alpha           = $this.LearningRate
        $this.Gamma           = $this.DiscountFactor
        $this.Episode         = 0
        $this.MemorySize      = 0
    }

    # Convert environment context into a state string.
    # This is domain-specific -- for the castle parade problem,
    # state = the last two castle types seen.
    #
    # WHY ONLY 2 CASTLES?
    # --------------------
    # More history = more states = larger Q-table = slower learning.
    # 2 previous castles captures enough context to learn good sequences.
    # This is a Markov approximation -- assuming the future depends only
    # on recent history, not the entire past.
    [string] GetState([hashtable]$context) {
        if ($context.RecentTypes.Count -eq 0) {
            return "START"
        }
        $recent = $context.RecentTypes
        if ($recent.Count -eq 1) {
            return $recent[-1]
        } else {
            return "$($recent[-2])|$($recent[-1])"
        }
    }

    # Compute reward signal from environment outcome.
    # Reward design is crucial -- it defines WHAT the agent learns to optimise.
    #
    # WHY REWARD VARIETY?
    # --------------------
    # If we only reward high score, the agent might repeat one castle type.
    # Adding penalties for repetition forces the agent to explore variety.
    # Visual balance and engagement rewards shape the aesthetic quality.
    # Getting reward design right is one of the hardest parts of RL.
    [double] CalculateReward([hashtable]$outcome) {
        $reward = 0.0

        # +2 for variety (different castle type than recent ones)
        # -1 for repetition (same castle type as recent ones)
        if ($outcome.IsVaried) {
            $reward += 2.0
        } else {
            $reward -= 1.0
        }

        # Visual balance score (0.0 to 1.0) weighted by 1.5
        $reward += $outcome.VisualBalance * 1.5

        # Engagement score (0.0 to 1.0) weighted by 2.0
        $reward += $outcome.Engagement * 2.0

        return $reward
    }

    # Look up Q(state, action) from the table.
    # Returns 0.0 for unseen state-action pairs -- optimistic initialisation.
    # This encourages the agent to try all actions at least once.
    [double] GetQValue([string]$state, [string]$action) {
        $key = "$state|$action"
        if ($this.QTable.ContainsKey($key)) {
            return [double]$this.QTable[$key]
        } else {
            return 0.0   # Unseen states default to 0 -- neutral starting point
        }
    }

    # Store Q(state, action) = value in the table.
    [void] SetQValue([string]$state, [string]$action, [double]$value) {
        $key = "$state|$action"
        $this.QTable[$key] = $value
    }

    # Find the action with the highest Q-value in this state.
    # This is the GREEDY action -- what the agent believes is best.
    # Used during exploitation (when not exploring randomly).
    [string] GetBestAction([string]$state) {
        $bestAction = $this.Actions[0]
        $bestValue  = $this.GetQValue($state, $bestAction)

        foreach ($action in $this.Actions) {
            $qValue = $this.GetQValue($state, $action)
            if ($qValue -gt $bestValue) {
                $bestValue  = $qValue
                $bestAction = $action
            }
        }

        return $bestAction
    }

    # Find the maximum Q-value achievable from this state (over all actions).
    # Used in the Bellman equation: max Q(s', a') for the next state.
    [double] GetMaxQValue([string]$state) {
        $maxValue = $this.GetQValue($state, $this.Actions[0])

        foreach ($action in $this.Actions) {
            $qValue = $this.GetQValue($state, $action)
            if ($qValue -gt $maxValue) {
                $maxValue = $qValue
            }
        }

        return $maxValue
    }

    # Return Q-values for ALL actions in this state -- useful for analysis.
    # Shows what the agent has learned about each action's value.
    [hashtable] GetQValues([string]$state) {
        $values = @{}
        foreach ($action in $this.Actions) {
            $values[$action] = $this.GetQValue($state, $action)
        }
        return $values
    }

    # EPSILON-GREEDY ACTION SELECTION:
    # ---------------------------------
    # The explore-exploit tradeoff in one function.
    # epsilon probability of random action (explore new possibilities)
    # 1-epsilon probability of best known action (exploit learned knowledge)
    #
    # Track counts so we can see the exploration ratio in statistics.
    # At the start: almost all exploration.
    # After training: almost all exploitation.
    [string] ChooseAction([string]$state) {
        if ((Get-Random -Minimum 0.0 -Maximum 1.0) -lt $this.Epsilon) {
            # Explore: pick a random action
            $this.ExplorationCount++
            $randomIndex = Get-Random -Minimum 0 -Maximum $this.Actions.Count
            return $this.Actions[$randomIndex]
        }

        # Exploit: pick the action with the highest Q-value
        $this.ExploitationCount++
        return $this.GetBestAction($state)
    }

    # THE CORE LEARNING STEP -- Q-TABLE UPDATE:
    # -----------------------------------------
    # Apply the Q-learning update rule (Bellman equation):
    #
    #   Q(s,a) <- Q(s,a) + alpha x [r + gamma x max Q(s',a') - Q(s,a)]
    #
    # Breaking it down:
    #   r + gamma x max Q(s',a')    = what we now THINK the true value is
    #   Q(s,a)                  = what we CURRENTLY estimate
    #   [true - current]        = TD error (temporal difference error)
    #   alpha x TD error            = how much to adjust our estimate
    #
    # Over many iterations, Q(s,a) converges to the true optimal value.
    # This is mathematically guaranteed under certain conditions
    # (all state-action pairs visited infinitely often, alpha decays properly).
    [void] Learn([string]$state, [string]$action, [double]$reward, [string]$nextState) {
        $currentQ = $this.GetQValue($state, $action)
        $maxNextQ = $this.GetMaxQValue($nextState)

        # Bellman target: what we now believe the true Q-value should be
        $tdTarget = $reward + ($this.DiscountFactor * $maxNextQ)

        # Temporal Difference error: how wrong our current estimate was
        $tdError  = $tdTarget - $currentQ

        # Update: move estimate toward the target by a fraction alpha
        $newQ     = $currentQ + ($this.LearningRate * $tdError)

        $this.SetQValue($state, $action, $newQ)

        $this.TotalSteps  += 1
        $this.TotalReward += $reward
    }

    # Called at the end of each episode:
    # 1. Record total reward for this episode
    # 2. Decay epsilon -- explore less as training progresses
    [void] EndEpisode([double]$episodeReward) {
        $this.TotalEpisodes++
        $this.Episode = $this.TotalEpisodes
        $this.EpisodeRewards.Add($episodeReward) | Out-Null

        # Epsilon decay -- gradually shift from exploration to exploitation
        $this.Epsilon *= $this.EpsilonDecay
        if ($this.Epsilon -lt $this.MinEpsilon) {
            $this.Epsilon = $this.MinEpsilon
        }
    }

    # Manual epsilon decay -- allows custom decay schedules.
    [void] DecayEpsilon([double]$decayRate) {
        $this.Epsilon *= $decayRate
        if ($this.Epsilon -lt $this.MinEpsilon) {
            $this.Epsilon = $this.MinEpsilon
        }
    }

    # Reset everything -- start fresh.
    # Clears the Q-table (all learned values lost).
    # Useful for comparing agents with different hyperparameters.
    [void] Reset() {
        $this.QTable.Clear()
        $this.TotalSteps    = 0
        $this.TotalEpisodes = 0
        $this.TotalReward   = 0.0
        $this.EpisodeRewards.Clear()
        $this.Epsilon       = 1.0
    }

    # Return training statistics.
    # RecentAverageReward (last 10 episodes) is the most useful metric --
    # it shows whether the agent is currently improving.
    [hashtable] GetStats() {
        $avgReward = if ($this.TotalEpisodes -gt 0) {
            $this.TotalReward / $this.TotalEpisodes
        } else { 0.0 }

        # Average reward over the last 10 episodes
        $recentAvg = 0.0
        if ($this.EpisodeRewards.Count -gt 0) {
            $recentCount = [Math]::Min(10, $this.EpisodeRewards.Count)
            $start       = $this.EpisodeRewards.Count - $recentCount
            $recentSum   = 0.0
            for ($i = $start; $i -lt $this.EpisodeRewards.Count; $i++) {
                $recentSum += [double]$this.EpisodeRewards[$i]
            }
            $recentAvg = $recentSum / $recentCount
        }

        return @{
            TotalSteps          = $this.TotalSteps
            TotalEpisodes       = $this.TotalEpisodes
            Episode             = $this.TotalEpisodes
            TotalReward         = $this.TotalReward
            QTableSize          = $this.QTable.Count    # How many state-action pairs learned
            Epsilon             = $this.Epsilon
            LearningRate        = $this.LearningRate
            AverageReward       = $avgReward
            RecentAverageReward = $recentAvg             # Best indicator of current performance
            ExplorationCount    = $this.ExplorationCount
            ExploitationCount   = $this.ExploitationCount
            MemorySize          = $this.MemorySize
        }
    }

    # Alias for compatibility with other VBAF modules.
    [hashtable] GetStatistics() {
        return $this.GetStats()
    }
}

# ============================================================================
# QUICK REFERENCE
# ============================================================================
#
# CREATE AN AGENT:
#   $actions = @("TowerA", "TowerB", "Castle", "Fort")
#   $agent = [QLearningAgent]::new($actions)
#
# TRAINING LOOP:
#   for ($ep = 0; $ep -lt 100; $ep++) {
#       $state = $env.GetInitialState()
#       $totalReward = 0.0
#       for ($step = 0; $step -lt 20; $step++) {
#           $action    = $agent.ChooseAction($state)          # epsilon-greedy
#           $outcome   = $env.TakeAction($action)             # environment responds
#           $reward    = $agent.CalculateReward($outcome)     # compute reward
#           $nextState = $agent.GetState($outcome.Context)    # observe next state
#           $agent.Learn($state, $action, $reward, $nextState) # update Q-table
#           $state     = $nextState
#           $totalReward += $reward
#       }
#       $agent.EndEpisode($totalReward)   # decay epsilon
#   }
#
# INSPECT WHAT WAS LEARNED:
#   $agent.GetQValues("TowerA|Castle")   # Q-values for each action in this state
#   $agent.GetBestAction("TowerA|Castle") # Best action in this state
#   $agent.QTable.Count                  # How many state-action pairs were visited
#
# COMPARE WITH DQN:
#   Q-learning:  works for small discrete state spaces  (< 10,000 states)
#   DQN:         works for large or continuous spaces   (CartPole, Atari, robotics)
#
# SEE ALSO:
#   VBAF.RL.DQN.ps1             -- neural network extends Q-learning
#   VBAF.RL.QTable.ps1          -- Q-table data structure
#   examples\02-Castle-Learning\ -- Q-learning applied to castle generation
# ============================================================================