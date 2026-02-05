#Requires -Version 5.1

<#
.SYNOPSIS
    Q-Learning Agent for Reinforcement Learning
.DESCRIPTION
    Implements Q-Learning algorithm with epsilon-greedy exploration.
    Uses hashtable for Q-table storage (no separate QTable class needed).
.NOTES
    Part of VBAF - Reinforcement Learning Module
    COMPLETE VERSION - All methods included
#>

# Set base path
$basePath = $PSScriptRoot

# Load dependencies
. (Join-Path $basePath "VBAF.RL.QTable.ps1")
. (Join-Path $basePath "VBAF.RL.ExperienceReplay.ps1")

class QLearningAgent {
    # Learning parameters
    [string[]]$Actions                  # Available actions
    [hashtable]$QTable                  # Stores learned Q-values (hashtable, not custom class!)
    [double]$LearningRate               # Alpha (a)
    [double]$DiscountFactor             # Gamma (?)
    [double]$Epsilon                    # Exploration rate
    [double]$EpsilonDecay               # How fast epsilon decreases
    [double]$MinEpsilon                 # Minimum epsilon value
    
    # Statistics
    [int]$TotalSteps
    [int]$TotalEpisodes
    [double]$TotalReward
    [System.Collections.ArrayList]$EpisodeRewards
    [int]$ExplorationCount
    [int]$ExploitationCount
    [double]$Alpha                      # Alias for LearningRate
    [double]$Gamma                      # Alias for DiscountFactor
    [int]$Episode                       # Alias for TotalEpisodes
    [int]$MemorySize                    # For compatibility
    
    # Simplified constructor with defaults
    QLearningAgent([string[]]$actions) {
        $this.Actions = $actions
        $this.QTable = @{}
        $this.LearningRate = 0.1        # Default alpha
        $this.DiscountFactor = 0.9      # Default gamma
        $this.Epsilon = 1.0             # Start with full exploration
        $this.EpsilonDecay = 0.995      # Decay 0.5% per episode
        $this.MinEpsilon = 0.01         # Always explore at least 1%
        $this.TotalSteps = 0
        $this.TotalEpisodes = 0
        $this.TotalReward = 0.0
        $this.EpisodeRewards = New-Object System.Collections.ArrayList
        $this.ExplorationCount = 0
        $this.ExploitationCount = 0
        $this.Alpha = $this.LearningRate
        $this.Gamma = $this.DiscountFactor
        $this.Episode = 0
        $this.MemorySize = 0
    }
    
    # Full constructor with custom parameters
    QLearningAgent([string[]]$actions, [double]$learningRate, [double]$epsilon) {
        $this.Actions = $actions
        $this.QTable = @{}
        $this.LearningRate = $learningRate
        $this.DiscountFactor = 0.9
        $this.Epsilon = $epsilon
        $this.EpsilonDecay = 0.995
        $this.MinEpsilon = 0.01
        $this.TotalSteps = 0
        $this.TotalEpisodes = 0
        $this.TotalReward = 0.0
        $this.EpisodeRewards = New-Object System.Collections.ArrayList
        $this.ExplorationCount = 0
        $this.ExploitationCount = 0
        $this.Alpha = $this.LearningRate
        $this.Gamma = $this.DiscountFactor
        $this.Episode = 0
        $this.MemorySize = 0
    }
    
    # Get state from context (castle parade specific)
    [string] GetState([hashtable]$context) {
        # State = recent castle types
        if ($context.RecentTypes.Count -eq 0) {
            return "START"
        }
        
        # Use last 2 castles as state
        $recent = $context.RecentTypes
        if ($recent.Count -eq 1) {
            return $recent[-1]
        } else {
            return "$($recent[-2])|$($recent[-1])"
        }
    }
    
    # Calculate reward based on outcome
    [double] CalculateReward([hashtable]$outcome) {
        $reward = 0.0
        
        # Reward for variety (not repeating same castle)
        if ($outcome.IsVaried) {
            $reward += 2.0
        } else {
            $reward -= 1.0  # Penalty for repetition
        }
        
        # Reward for visual balance
        $reward += $outcome.VisualBalance * 1.5
        
        # Reward for engagement
        $reward += $outcome.Engagement * 2.0
        
        return $reward
    }
    
    # Get Q-value for state-action pair
    [double] GetQValue([string]$state, [string]$action) {
        $key = "$state|$action"
        
        if ($this.QTable.ContainsKey($key)) {
            return [double]$this.QTable[$key]
        } else {
            return 0.0
        }
    }
    
    # Set Q-value for state-action pair
    [void] SetQValue([string]$state, [string]$action, [double]$value) {
        $key = "$state|$action"
        $this.QTable[$key] = $value
    }
    
    # Get best action for a state
    [string] GetBestAction([string]$state) {
        $bestAction = $this.Actions[0]
        $bestValue = $this.GetQValue($state, $bestAction)
        
        foreach ($action in $this.Actions) {
            $qValue = $this.GetQValue($state, $action)
            if ($qValue -gt $bestValue) {
                $bestValue = $qValue
                $bestAction = $action
            }
        }
        
        return $bestAction
    }
    
    # Get max Q-value for a state
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
    
    # Get all Q-values for a state (for analysis)
    [hashtable] GetQValues([string]$state) {
        $values = @{}
        
        foreach ($action in $this.Actions) {
            $values[$action] = $this.GetQValue($state, $action)
        }
        
        return $values
    }
    
    # Choose action using epsilon-greedy
    [string] ChooseAction([string]$state) {
        # Exploration: random action
        if ((Get-Random -Minimum 0.0 -Maximum 1.0) -lt $this.Epsilon) {
            $this.ExplorationCount++
            $randomIndex = Get-Random -Minimum 0 -Maximum $this.Actions.Count
            return $this.Actions[$randomIndex]
        }
        
        # Exploitation: best known action
        $this.ExploitationCount++
        return $this.GetBestAction($state)
    }
    
    # Learn from experience (Q-Learning update)
    [void] Learn([string]$state, [string]$action, [double]$reward, [string]$nextState) {
        # Current Q-value
        $currentQ = $this.GetQValue($state, $action)
        
        # Max Q-value for next state
        $maxNextQ = $this.GetMaxQValue($nextState)
        
        # Q-Learning update rule:
        # Q(s,a) ? Q(s,a) + a[r + ?·max(Q(s',a')) - Q(s,a)]
        $tdTarget = $reward + ($this.DiscountFactor * $maxNextQ)
        $tdError = $tdTarget - $currentQ
        $newQ = $currentQ + ($this.LearningRate * $tdError)
        
        # Update Q-table
        $this.SetQValue($state, $action, $newQ)
        
        # Increment steps and accumulate reward
        $this.TotalSteps++
        $this.TotalReward += $reward
    }
    
    # End episode (decay epsilon)
    [void] EndEpisode([double]$episodeReward) {
        $this.TotalEpisodes++
        $this.Episode = $this.TotalEpisodes
        $this.EpisodeRewards.Add($episodeReward) | Out-Null
        
        # Decay epsilon
        $this.Epsilon *= $this.EpsilonDecay
        if ($this.Epsilon -lt $this.MinEpsilon) {
            $this.Epsilon = $this.MinEpsilon
        }
    }
    
    # Decay epsilon manually (reduce exploration over time)
    [void] DecayEpsilon([double]$decayRate) {
        $this.Epsilon *= $decayRate
        
        if ($this.Epsilon -lt $this.MinEpsilon) {
            $this.Epsilon = $this.MinEpsilon
        }
    }
    
    # Reset Q-table
    [void] Reset() {
        $this.QTable.Clear()
        $this.TotalSteps = 0
        $this.TotalEpisodes = 0
        $this.TotalReward = 0.0
        $this.EpisodeRewards.Clear()
        $this.Epsilon = 1.0
    }
    
    # Get statistics
    [hashtable] GetStats() {
        $avgReward = if ($this.TotalEpisodes -gt 0) {
            $this.TotalReward / $this.TotalEpisodes
        } else {
            0.0
        }
        
        # Recent average (last 10 episodes)
        $recentAvg = 0.0
        if ($this.EpisodeRewards.Count -gt 0) {
            $recentCount = [Math]::Min(10, $this.EpisodeRewards.Count)
            $start = $this.EpisodeRewards.Count - $recentCount
            $recentSum = 0.0
            for ($i = $start; $i -lt $this.EpisodeRewards.Count; $i++) {
                $recentSum += [double]$this.EpisodeRewards[$i]
            }
            $recentAvg = $recentSum / $recentCount
        }
        
        $explorationRatio = if ($this.TotalSteps -gt 0) {
            $this.Epsilon
        } else {
            1.0
        }
        
        return @{
            TotalSteps = $this.TotalSteps
            TotalEpisodes = $this.TotalEpisodes
            Episode = $this.TotalEpisodes
            TotalReward = $this.TotalReward
            QTableSize = $this.QTable.Count
            Epsilon = $this.Epsilon
            LearningRate = $this.LearningRate
            AverageReward = $avgReward
            RecentAverageReward = $recentAvg
            ExplorationRatio = $explorationRatio
            ExplorationCount = $this.ExplorationCount
            ExploitationCount = $this.ExploitationCount
            MemorySize = $this.MemorySize
        }
    }
    
    # Get statistics (alias for compatibility)
    [hashtable] GetStatistics() {
        return $this.GetStats()
    }
}

