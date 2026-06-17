#Requires -Version 5.1
<#
.SYNOPSIS
    Standardized Environment Interface for VBAF RL Algorithms
.DESCRIPTION
    Provides an OpenAI Gym-like environment interface for all VBAF RL algorithms.

    WHAT YOU ARE LEARNING HERE:
    ============================
    In reinforcement learning, the ENVIRONMENT is everything the agent
    interacts with. It defines:
      - What the agent can OBSERVE (the state space)
      - What the agent can DO (the action space)
      - What HAPPENS when the agent acts (the transition function)
      - How much REWARD the agent gets (the reward function)

    This file standardises environments so that ANY agent (DQN, PPO, A3C,
    Q-learning) can work with ANY environment without code changes.
    This is the same design as OpenAI Gym -- the most widely used
    RL environment library in the world.

    THE GYM INTERFACE -- THREE METHODS:
    =====================================
    Every environment in VBAF implements the same three methods:

      Reset()         -- start a new episode, return initial state
      Step(action)    -- apply action, return (nextState, reward, done)
      GetState()      -- return current state as a double array

    This is the standard contract. Any agent that calls these three methods
    works with any environment. Swap CartPole for GridWorld -- same agent code.

    STATE SPACE vs ACTION SPACE:
    ============================
    State space: what the agent can observe
      Continuous: real-valued numbers (position, velocity, angle)
      Discrete:   integer categories (grid cell, one of N options)

    Action space: what the agent can do
      Discrete:   a fixed set of choices (push left, push right)
      Continuous: a real-valued command (force between -1 and +1)

    VBAF currently uses discrete actions -- simpler to implement
    and sufficient for all examples in this framework.

    THE THREE ENVIRONMENTS:
    =======================
    CartPole:   balance a pole on a cart (classic control problem)
                State: [position, velocity, angle, angular_velocity]
                Actions: 0=push left, 1=push right

    GridWorld:  navigate a grid to reach a goal (spatial reasoning)
                State: [agent_row, agent_col, goal_row, goal_col]
                Actions: 0=up, 1=right, 2=down, 3=left

    RandomWalk: move along a 1D line to reach the center (simplest possible)
                State: [position]
                Actions: 0=left, 1=right
                Use this for quick sanity checks when debugging an agent.

    INHERITANCE:
    ============
    CartPoleEnvironment, GridWorldEnvironment and RandomWalkEnvironment
    all inherit from VBAFEnvironment. They share the same interface
    but implement different physics and reward functions.

    This is polymorphism in action -- the same agent code works with
    all three environments because they all respond to the same methods.

    THEORY REFERENCE:
    =================
    Brockman, G. et al. (2016). "OpenAI Gym."
    ArXiv:1606.01540.

    The OpenAI Gym paper established the standard environment interface
    that this file implements. Every major RL library uses this pattern.

.NOTES
    Part of VBAF (Visual AI & Reinforcement Learning Framework)
    Educational use -- swap environments to see how agents generalise.
#>

$basePath = $PSScriptRoot

# ============================================================
# VBAFSPACE -- describes a state or action space
# ============================================================
#
# WHAT IS A SPACE
# ----------------
# A space defines the valid values for states or actions.
#
# Discrete space (Type="discrete", Size=2):
#   Actions are integers 0, 1, ..., Size-1
#   Example: CartPole has 2 actions (0=left, 1=right)
#
# Continuous space (Type="continuous", Size=4, Low=-4.8, High=4.8):
#   States are arrays of Size real numbers, each in [Low, High]
#   Example: CartPole state has 4 values (position, velocity, angle, angular velocity)
#
# Knowing the space lets agents and environments work together without
# hardcoding sizes -- an agent can ask the environment "how many actions
# do you have" and configure itself accordingly.

class VBAFSpace {
    [string] $Type    # "discrete" or "continuous"
    [int]    $Size    # number of actions OR number of state dimensions
    [double] $Low     # minimum value (for continuous spaces)
    [double] $High    # maximum value (for continuous spaces)

    VBAFSpace([string]$type, [int]$size) {
        $this.Type = $type
        $this.Size = $size
        $this.Low  = -1.0
        $this.High =  1.0
    }

    VBAFSpace([string]$type, [int]$size, [double]$low, [double]$high) {
        $this.Type = $type
        $this.Size = $size
        $this.Low  = $low
        $this.High = $high
    }

    [string] ToString() {
        return "$($this.Type)($($this.Size)) [$($this.Low), $($this.High)]"
    }
}


# ============================================================
# VBAFENVIRONMENT -- base class for all environments
# ============================================================
#
# BASE CLASS PATTERN:
# -------------------
# VBAFEnvironment defines the INTERFACE that all environments share.
# Subclasses (CartPole, GridWorld, RandomWalk) override Reset() and Step()
# with their own physics and reward functions.
#
# The base class provides:
#   - Common properties (Name, Steps, MaxSteps, TotalReward, EpisodeCount)
#   - PrintInfo() -- works for all environments automatically
#   - Default implementations of Reset/Step (return zeros -- override these)
#
# This is the Template Method pattern -- define the structure here,
# fill in the details in subclasses.

class VBAFEnvironment {
    [string]    $Name
    [VBAFSpace] $ObservationSpace   # Defines what the agent can observe
    [VBAFSpace] $ActionSpace        # Defines what the agent can do
    [int]       $Steps              # Steps taken in current episode
    [int]       $MaxSteps           # Episode ends after this many steps
    [double]    $TotalReward        # Cumulative reward this episode
    [int]       $EpisodeCount       # Total episodes started

    VBAFEnvironment([string]$name, [int]$maxSteps) {
        $this.Name         = $name
        $this.MaxSteps     = $maxSteps
        $this.Steps        = 0
        $this.TotalReward  = 0.0
        $this.EpisodeCount = 0
    }

    # Override in subclass -- return initial state array
    [double[]] Reset()   { return @(0.0) }

    # Override in subclass -- return current state array
    [double[]] GetState() { return @(0.0) }

    # Override in subclass -- apply action, return (NextState, Reward, Done)
    [hashtable] Step([int]$action) {
        return @{ NextState = @(0.0); Reward = 0.0; Done = $true }
    }

    # Print environment summary -- works for all subclasses automatically
    [void] PrintInfo() {
        Write-Host "  Environment : $($this.Name)"                          -ForegroundColor Cyan
        Write-Host "  Obs Space   : $($this.ObservationSpace.ToString())"  -ForegroundColor Cyan
        Write-Host "  Act Space   : $($this.ActionSpace.ToString())"       -ForegroundColor Cyan
        Write-Host "  Max Steps   : $($this.MaxSteps)"                     -ForegroundColor Cyan
    }
}


# ============================================================
# CARTPOLE ENVIRONMENT
# ============================================================
#
# THE PROBLEM:
# ------------
# A pole is attached to a cart that slides left and right.
# The agent pushes the cart left or right to keep the pole balanced.
# The episode ends when the pole falls too far or the cart goes off track.
#
# State: [position, velocity, angle, angular_velocity]
#   position: cart position on the track (-2.4 to +2.4)
#   velocity: cart speed (negative = moving left)
#   angle:    pole angle from vertical in radians (0 = upright)
#   angular_velocity: how fast the pole is rotating
#
# Reward: +1 for every step the pole stays balanced
# Episode ends if:
#   |position| > 2.4 (cart went off track)
#   |angle| > 0.21 radians (~12 degrees -- pole fell)
#   steps >= MaxSteps (success -- survived the full episode)
#
# A random agent survives ~10-20 steps.
# A trained DQN survives 200 steps (the maximum).
# This gap measures how much the agent learned.
#
# INHERITANCE NOTE:
# -----------------
# ": base("CartPole", maxSteps)" calls the parent class constructor.
# This is PowerShell 5.1's syntax for inheritance.

class CartPoleEnvironment : VBAFEnvironment {
    [double] $Position
    [double] $Velocity
    [double] $Angle
    [double] $AngularVelocity
    hidden [System.Random] $Rng

    CartPoleEnvironment() : base("CartPole", 200) {
        $this.ObservationSpace = [VBAFSpace]::new("continuous", 4, -4.8, 4.8)
        $this.ActionSpace      = [VBAFSpace]::new("discrete",   2,  0.0, 1.0)
        $this.Rng              = [System.Random]::new()
        $this.Reset()
    }

    CartPoleEnvironment([int]$maxSteps) : base("CartPole", $maxSteps) {
        $this.ObservationSpace = [VBAFSpace]::new("continuous", 4, -4.8, 4.8)
        $this.ActionSpace      = [VBAFSpace]::new("discrete",   2,  0.0, 1.0)
        $this.Rng              = [System.Random]::new()
        $this.Reset()
    }

    CartPoleEnvironment([int]$maxSteps, [int]$seed) : base("CartPole", $maxSteps) {
        $this.ObservationSpace = [VBAFSpace]::new("continuous", 4, -4.8, 4.8)
        $this.ActionSpace      = [VBAFSpace]::new("discrete",   2,  0.0, 1.0)
        $this.Rng              = [System.Random]::new($seed)   # Fixed seed for reproducibility
        $this.Reset()
    }

    # Reset to a new random starting state.
    # Small perturbations (+-0.05) prevent the agent memorising one fixed sequence.
    [double[]] Reset() {
        $this.Position        = ($this.Rng.NextDouble() - 0.5) * 0.1
        $this.Velocity        = ($this.Rng.NextDouble() - 0.5) * 0.1
        $this.Angle           = ($this.Rng.NextDouble() - 0.5) * 0.1
        $this.AngularVelocity = ($this.Rng.NextDouble() - 0.5) * 0.1
        $this.Steps           = 0
        $this.TotalReward     = 0.0
        $this.EpisodeCount++
        return $this.GetState()
    }

    [double[]] GetState() {
        return @($this.Position, $this.Velocity, $this.Angle, $this.AngularVelocity)
    }

    # Apply physics equations for one time step (dt = 0.02 seconds).
    # These are standard CartPole equations from control systems literature.
    # Treat as a black box -- the important thing is the interface, not the physics.
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

        $this.TotalReward += $reward
        return @{ NextState = $this.GetState(); Reward = $reward; Done = $done }
    }
}


# ============================================================
# GRIDWORLD ENVIRONMENT
# ============================================================
#
# THE PROBLEM:
# ------------
# A grid of Size x Size cells. The agent starts at a random cell
# and must navigate to a goal cell, which is also random.
#
# This tests whether an agent can learn SPATIAL REASONING --
# moving toward a target rather than away from it.
#
# State: [agent_row, agent_col, goal_row, goal_col] (normalised 0 to 1)
#   Normalisation makes all values the same scale for the neural network.
#   Raw row/col values (0-4 for a 5x5 grid) would be fine for Q-learning
#   but neural networks train better on normalised inputs.
#
# Actions: 0=up, 1=right, 2=down, 3=left
#   Agent cannot move off the grid (clamped to boundary).
#
# Reward:
#   +10 for reaching the goal
#   -0.1 for each step (encourages finding the SHORT path)
#   -1.0 if episode ends without reaching goal (timeout)
#
# REWARD SHAPING NOTE:
# --------------------
# The -0.1 step penalty is reward shaping -- we add domain knowledge
# to help the agent learn faster. Without it, the agent might wander
# randomly and eventually reach the goal by chance, but learn nothing
# about finding efficient paths.

class GridWorldEnvironment : VBAFEnvironment {
    [int] $GridSize
    [int] $AgentRow
    [int] $AgentCol
    [int] $GoalRow
    [int] $GoalCol
    hidden [System.Random] $Rng

    GridWorldEnvironment() : base("GridWorld", 100) {
        $this.GridSize         = 5
        $this.ObservationSpace = [VBAFSpace]::new("continuous", 4, 0.0, 1.0)
        $this.ActionSpace      = [VBAFSpace]::new("discrete",   4, 0.0, 3.0)
        $this.Rng              = [System.Random]::new()
        $this.Reset()
    }

    GridWorldEnvironment([int]$gridSize, [int]$maxSteps) : base("GridWorld", $maxSteps) {
        $this.GridSize         = $gridSize
        $this.ObservationSpace = [VBAFSpace]::new("continuous", 4, 0.0, 1.0)
        $this.ActionSpace      = [VBAFSpace]::new("discrete",   4, 0.0, 3.0)
        $this.Rng              = [System.Random]::new()
        $this.Reset()
    }

    [double[]] Reset() {
        $this.AgentRow    = $this.Rng.Next(0, $this.GridSize)
        $this.AgentCol    = $this.Rng.Next(0, $this.GridSize)
        $this.GoalRow     = $this.Rng.Next(0, $this.GridSize)
        $this.GoalCol     = $this.Rng.Next(0, $this.GridSize)
        # Ensure agent and goal are not in the same cell
        while ($this.AgentRow -eq $this.GoalRow -and $this.AgentCol -eq $this.GoalCol) {
            $this.GoalRow = $this.Rng.Next(0, $this.GridSize)
            $this.GoalCol = $this.Rng.Next(0, $this.GridSize)
        }
        $this.Steps       = 0
        $this.TotalReward = 0.0
        $this.EpisodeCount++
        return $this.GetState()
    }

    # Normalise positions to [0, 1] range for neural network compatibility
    [double[]] GetState() {
        [int]      $g   = $this.GridSize - 1
        [double[]] $arr = @(0.0, 0.0, 0.0, 0.0)
        $arr[0] = $this.AgentRow / $g
        $arr[1] = $this.AgentCol / $g
        $arr[2] = $this.GoalRow  / $g
        $arr[3] = $this.GoalCol  / $g
        return $arr
    }

    [hashtable] Step([int]$action) {
        $this.Steps++
        $newRow = $this.AgentRow
        $newCol = $this.AgentCol

        switch ($action) {
            0 { $newRow-- }   # up
            1 { $newCol++ }   # right
            2 { $newRow++ }   # down
            3 { $newCol-- }   # left
        }

        # Clamp to grid boundaries -- agent cannot walk off the edge
        $newRow = [Math]::Max(0, [Math]::Min($this.GridSize - 1, $newRow))
        $newCol = [Math]::Max(0, [Math]::Min($this.GridSize - 1, $newCol))

        $this.AgentRow = $newRow
        $this.AgentCol = $newCol

        $atGoal = ($this.AgentRow -eq $this.GoalRow -and $this.AgentCol -eq $this.GoalCol)
        $done   = $atGoal -or ($this.Steps -ge $this.MaxSteps)
        $reward = if ($atGoal) { 10.0 } elseif ($done) { -1.0 } else { -0.1 }

        $this.TotalReward += $reward
        return @{ NextState = $this.GetState(); Reward = $reward; Done = $done }
    }
}


# ============================================================
# RANDOM WALK ENVIRONMENT
# ============================================================
#
# THE PROBLEM:
# ------------
# The simplest possible RL problem -- a 1D number line.
# Agent starts at a random position and must reach position 0 (center).
#
# State:  [position / range]  -- one number between -1 and +1
# Actions: 0=move left, 1=move right
#
# Reward: +10 for reaching 0, else -(distance from center) * 0.1
#   The distance-based penalty guides the agent toward the center.
#
# USE THIS ENVIRONMENT FOR:
# -------------------------
# Debugging a new agent implementation before trying CartPole.
# If an agent cannot solve RandomWalk, it will not solve anything harder.
# Much faster to train -- useful for quick sanity checks.

class RandomWalkEnvironment : VBAFEnvironment {
    [int] $Position
    [int] $Range
    hidden [System.Random] $Rng

    RandomWalkEnvironment() : base("RandomWalk", 50) {
        $this.Range            = 10
        $this.ObservationSpace = [VBAFSpace]::new("continuous", 1, -1.0, 1.0)
        $this.ActionSpace      = [VBAFSpace]::new("discrete",   2,  0.0, 1.0)
        $this.Rng              = [System.Random]::new()
        $this.Reset()
    }

    [double[]] Reset() {
        $this.Position    = $this.Rng.Next(-$this.Range, $this.Range)
        $this.Steps       = 0
        $this.TotalReward = 0.0
        $this.EpisodeCount++
        return $this.GetState()
    }

    [double[]] GetState() {
        return @([double]$this.Position / $this.Range)
    }

    [hashtable] Step([int]$action) {
        $this.Steps++
        if ($action -eq 0) { $this.Position-- } else { $this.Position++ }
        $this.Position = [Math]::Max(-$this.Range, [Math]::Min($this.Range, $this.Position))

        $atCenter = ($this.Position -eq 0)
        $done     = $atCenter -or ($this.Steps -ge $this.MaxSteps)
        $reward   = if ($atCenter) { 10.0 } else { -[Math]::Abs($this.Position) * 0.1 }

        $this.TotalReward += $reward
        return @{ NextState = $this.GetState(); Reward = $reward; Done = $done }
    }
}


# ============================================================
# ENVIRONMENT FACTORY
# ============================================================
#
# New-VBAFEnvironment is a FACTORY FUNCTION -- it creates the right
# environment type based on a name string.
#
# This lets you write code like:
#   $env = New-VBAFEnvironment -Name "CartPole"
# and swap environments by changing just the name -- no code restructuring needed.
#
# Factory functions are a common design pattern when you have multiple
# classes that share the same interface but different implementations.

function New-VBAFEnvironment {
    param(
        [string] $Name     = "CartPole",   # Which environment to create
        [int]    $MaxSteps = 200,           # Episode length
        [int]    $GridSize = 5,             # GridWorld only: grid dimensions
        [int]    $Seed     = -1             # CartPole only: fixed random seed (-1 = random)
    )

    switch ($Name) {
        "CartPole" {
            if ($Seed -ge 0) { return [CartPoleEnvironment]::new($MaxSteps, $Seed) }
            return [CartPoleEnvironment]::new($MaxSteps)
        }
        "GridWorld"  { return [GridWorldEnvironment]::new($GridSize, $MaxSteps) }
        "RandomWalk" { return [RandomWalkEnvironment]::new() }
        default {
            Write-Host "  Unknown environment: $Name" -ForegroundColor Red
            Write-Host "  Available: CartPole, GridWorld, RandomWalk" -ForegroundColor Yellow
            return $null
        }
    }
}


# ============================================================
# REWARD SHAPER WRAPPER
# ============================================================
#
# A wrapper that modifies rewards from any environment.
# Useful for experimenting with reward engineering without
# changing the environment itself.
#
# Scale:       multiply all rewards by this factor
# Clip:        clamp rewards to [-Clip, +Clip] (0 = no clipping)
# StepPenalty: subtract this from every reward (encourages shorter episodes)
#
# REWARD CLIPPING NOTE:
# ---------------------
# DeepMind used reward clipping (clip all rewards to -1/+1) in the
# original Atari DQN paper. This helped the same hyperparameters work
# across all 49 games despite very different score scales.

function New-RewardShaper {
    param(
        [object] $Environment,
        [double] $Scale       = 1.0,
        [double] $Clip        = 0.0,    # 0 = no clipping
        [double] $StepPenalty = 0.0     # penalty per step
    )

    return @{
        Env         = $Environment
        Scale       = $Scale
        Clip        = $Clip
        StepPenalty = $StepPenalty
        Reset       = { $Environment.Reset() }
        GetState    = { $Environment.GetState() }
        Step        = {
            param([int]$action)
            $result = $Environment.Step($action)
            $r      = $result.Reward * $Scale - $StepPenalty
            if ($Clip -gt 0) { $r = [Math]::Max(-$Clip, [Math]::Min($Clip, $r)) }
            return @{ NextState = $result.NextState; Reward = $r; Done = $result.Done }
        }
    }
}


# ============================================================
# BENCHMARKING UTILITY
# ============================================================
#
# Invoke-VBAFBenchmark runs a trained agent (or a random baseline)
# on an environment for N episodes and reports average performance.
#
# WHY BENCHMARK
# --------------
# Training reward is noisy -- the agent explores randomly which adds noise.
# Benchmark reward is clean -- the agent always picks its best action.
# Compare benchmark reward BEFORE and AFTER training to measure improvement.
#
# RANDOM BASELINE:
# ----------------
# Pass Agent=$null to get a random agent baseline.
# If your trained agent does not beat random, something is wrong.
# Random baseline for CartPole is typically 10-20 reward.
# A trained DQN should reach 150-200 reward.

function Invoke-VBAFBenchmark {
    param(
        [object] $Agent,
        [object] $Environment,
        [int]    $Episodes = 10,
        [string] $Label    = "Benchmark"
    )

    Write-Host ""
    Write-Host "  $Label" -ForegroundColor Yellow
    Write-Host "   Episodes : $Episodes" -ForegroundColor Cyan

    $rewards    = [System.Collections.Generic.List[double]]::new()
    $timer      = [System.Diagnostics.Stopwatch]::StartNew()
    $rng        = [System.Random]::new()
    $actionSize = $Environment.ActionSpace.Size
    $useRandom  = ($null -eq $Agent)

    if ($useRandom) {
        Write-Host "   Agent    : Random baseline" -ForegroundColor DarkYellow
    } else {
        Write-Host "   Agent    : $($Agent.GetType().Name)" -ForegroundColor DarkYellow
    }

    for ($ep = 1; $ep -le $Episodes; $ep++) {
        $state       = $Environment.Reset()
        $totalReward = 0.0
        $done        = $false

        while (-not $done) {
            if ($useRandom) {
                $action = $rng.Next(0, $actionSize)
            } else {
                try   { $action = $Agent.Predict($state) }
                catch { $action = $rng.Next(0, $actionSize) }
            }
            $result       = $Environment.Step($action)
            $state        = $result.NextState
            $totalReward += $result.Reward
            $done         = $result.Done
        }
        $rewards.Add($totalReward)
    }

    $timer.Stop()
    $avg = ($rewards | Measure-Object -Average).Average
    $max = ($rewards | Measure-Object -Maximum).Maximum
    $min = ($rewards | Measure-Object -Minimum).Minimum
    $ms  = $timer.ElapsedMilliseconds

    Write-Host ""
    Write-Host "  +--------------------------------------+" -ForegroundColor Yellow
    Write-Host ("  |  {0,-36}|" -f $Label)                  -ForegroundColor Yellow
    Write-Host "  +--------------------------------------+" -ForegroundColor Yellow
    Write-Host ("  |  Avg Reward : {0,-23}|" -f [Math]::Round($avg, 2)) -ForegroundColor White
    Write-Host ("  |  Max Reward : {0,-23}|" -f [Math]::Round($max, 2)) -ForegroundColor Green
    Write-Host ("  |  Min Reward : {0,-23}|" -f [Math]::Round($min, 2)) -ForegroundColor White
    Write-Host ("  |  Time (ms)  : {0,-23}|" -f $ms)                    -ForegroundColor Cyan
    Write-Host ("  |  ms/episode : {0,-23}|" -f [Math]::Round($ms / $Episodes, 1)) -ForegroundColor Cyan
    Write-Host "  +--------------------------------------+" -ForegroundColor Yellow
    Write-Host ""

    return @{ Avg = $avg; Max = $max; Min = $min; TimeMs = $ms }
}

# ============================================================
# QUICK REFERENCE
# ============================================================
#
# CREATE AN ENVIRONMENT:
#   $env = New-VBAFEnvironment -Name "CartPole"   -MaxSteps 200
#   $env = New-VBAFEnvironment -Name "GridWorld"  -GridSize 5 -MaxSteps 100
#   $env = New-VBAFEnvironment -Name "RandomWalk"
#
# INSPECT THE ENVIRONMENT:
#   $env.PrintInfo()
#
# RUN ONE EPISODE MANUALLY:
#   $state = $env.Reset()
#   while ($true) {
#       $action = 0   # or use an agent: $agent.Predict($state)
#       $result = $env.Step($action)
#       $state  = $result.NextState
#       if ($result.Done) { break }
#   }
#
# BENCHMARK A TRAINED AGENT:
#   $dqn = (Invoke-DQNTraining -Episodes 100 -FastMode)[-1]
#   $env = New-VBAFEnvironment -Name "CartPole"
#   Invoke-VBAFBenchmark -Agent $dqn  -Environment $env -Episodes 20 -Label "DQN"
#   Invoke-VBAFBenchmark -Agent $null -Environment $env -Episodes 20 -Label "Random"
#
# SEE ALSO:
#   VBAF.RL.DQN.ps1            -- DQN agent that uses CartPoleEnvironment
#   VBAF.RL.QLearningAgent.ps1 -- Q-learning agent (good for GridWorld)
# ============================================================

Write-Host "  VBAF.RL.Environment.ps1 loaded" -ForegroundColor Green
Write-Host "   Classes      : VBAFSpace, VBAFEnvironment" -ForegroundColor Cyan
Write-Host "   Environments : CartPole, GridWorld, RandomWalk" -ForegroundColor Cyan
Write-Host "   Functions    : New-VBAFEnvironment, New-RewardShaper, Invoke-VBAFBenchmark" -ForegroundColor Cyan
Write-Host ""
Write-Host "   Quick start:" -ForegroundColor Yellow
Write-Host '   $env = New-VBAFEnvironment -Name "CartPole" -MaxSteps 200' -ForegroundColor White
Write-Host '   $env.PrintInfo()' -ForegroundColor White
Write-Host ""