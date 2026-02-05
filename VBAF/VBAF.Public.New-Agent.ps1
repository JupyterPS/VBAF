function New-VBAFAgent {
    <#
    .SYNOPSIS
        Creates a new reinforcement learning agent.
    
    .DESCRIPTION
        Creates a Q-Learning agent that can learn from interaction with an environment.
        The agent uses epsilon-greedy exploration and can optionally use experience replay.
        
        Perfect for:
        - Game playing (grid worlds, puzzles)
        - Resource optimization
        - Sequential decision making
        - Multi-agent simulations
    
    .PARAMETER Actions
        Array of available actions the agent can take.
        Example: @("up", "down", "left", "right")
    
    .PARAMETER LearningRate
        Learning rate (alpha) for Q-value updates.
        Typical values: 0.05 to 0.3
        Default: 0.1
        
        Higher = learns faster but less stable
        Lower = learns slower but more stable
    
    .PARAMETER DiscountFactor
        Discount factor (gamma) for future rewards.
        Range: 0.0 to 1.0
        Default: 0.9
        
        0.0 = only immediate rewards matter
        1.0 = future rewards as important as immediate
    
    .PARAMETER Epsilon
        Initial exploration rate (epsilon).
        Range: 0.0 to 1.0
        Default: 1.0 (full exploration)
        
        Probability of taking random action vs. best known action.
        Decays over time as agent learns.
    
    .PARAMETER EpsilonDecay
        Epsilon decay rate per episode.
        Range: 0.9 to 0.999
        Default: 0.995
        
        epsilon *= decay after each episode
    
    .PARAMETER MinEpsilon
        Minimum epsilon value.
        Range: 0.0 to 0.2
        Default: 0.01
        
        Agent always explores at least this much.
    
    .PARAMETER UseExperienceReplay
        Enable experience replay memory.
        Improves learning stability.
    
    .PARAMETER MemorySize
        Size of experience replay buffer.
        Only used if UseExperienceReplay is true.
        Default: 1000
    
    .EXAMPLE
        # Simple grid world agent
        $agent = New-VBAFAgent -Actions @("up", "down", "left", "right")
        
        # Agent decides action
        $action = $agent.ChooseAction($currentState)
        
        # Agent learns from outcome
        $agent.Learn($state, $action, $reward, $nextState)
    
    .EXAMPLE
        # Castle generation agent with experience replay
        $castleTypes = @("Gothic", "FairyTale", "Cathedral", "Wizard", "Palace", "Oriental", "Fortress", "Ruins")
        $agent = New-VBAFAgent -Actions $castleTypes -LearningRate 0.15 -UseExperienceReplay -MemorySize 500
    
    .EXAMPLE
        # Conservative learning agent (low learning rate, slow epsilon decay)
        $agent = New-VBAFAgent -Actions @("buy", "sell", "hold") -LearningRate 0.05 -EpsilonDecay 0.999 -MinEpsilon 0.05
    
    .OUTPUTS
        QLearningAgent object with methods:
        - ChooseAction($state) - Select action using epsilon-greedy
        - Learn($state, $action, $reward, $nextState) - Update Q-values
        - GetQValue($state, $action) - Get Q-value for state-action pair
        - GetBestAction($state) - Get best known action for state
        - EndEpisode($episodeReward) - Decay epsilon
        - GetStats() - Get agent statistics
    
    .NOTES
        Author: Henning
        Part of VBAF Module
        
    .LINK
        Train-VBAFAgent
        Get-VBAFAgentStats
    #>
    
    [CmdletBinding()]
    #[OutputType([QLearningAgent])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [ValidateCount(1, 1000)]
        [string[]]$Actions,
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(0.001, 1.0)]
        [double]$LearningRate = 0.1,
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(0.0, 1.0)]
        [double]$DiscountFactor = 0.9,
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(0.0, 1.0)]
        [double]$Epsilon = 1.0,
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(0.9, 0.9999)]
        [double]$EpsilonDecay = 0.995,
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(0.0, 0.2)]
        [double]$MinEpsilon = 0.01,
        
        [Parameter(Mandatory = $false)]
        [switch]$UseExperienceReplay,
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(10, 100000)]
        [int]$MemorySize = 1000
    )
    
    begin {
        Write-Verbose "Creating Q-Learning agent"
        Write-Verbose "  Actions: $($Actions.Count) available"
        Write-Verbose "  Learning rate: $LearningRate"
        Write-Verbose "  Discount factor: $DiscountFactor"
        Write-Verbose "  Initial epsilon: $Epsilon"
    }
    
    process {
        try {
            # Create Q-Learning agent
            $args = @(,$Actions; $LearningRate; $Epsilon)
            $agent = New-Object QLearningAgent -ArgumentList $args
            
            # Set additional parameters
            $agent.DiscountFactor = $DiscountFactor
            $agent.Gamma = $DiscountFactor
            $agent.EpsilonDecay = $EpsilonDecay
            $agent.MinEpsilon = $MinEpsilon
            
            Write-Verbose "✓ Q-Learning agent created"
            
            # Create experience replay if requested
            if ($UseExperienceReplay) {
                $agent.ExperienceReplay = New-Object ExperienceReplay -ArgumentList $MemorySize
                $agent.MemorySize = $MemorySize
                Write-Verbose "✓ Experience replay enabled (size: $MemorySize)"
            }
            
            Write-Verbose "Agent ready for learning!"
            
            return $agent
            
        } catch {
            Write-Error "Failed to create agent: $_"
            throw
        }
    }
    
    end {
        Write-Verbose "New-VBAFAgent completed"
    }
}