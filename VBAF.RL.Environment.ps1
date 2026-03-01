#Requires -Version 5.1
<#
.SYNOPSIS
    Standardized Environment Interface for VBAF RL Algorithms
.DESCRIPTION
    Provides an OpenAI Gym-like environment interface for all VBAF RL algorithms.
    Replaces the individual DQNEnvironment, PPOEnvironment, A3CEnvironment classes.
    Features:
      - Standardized Reset(), Step(), GetState() interface
      - State/action space definitions
      - Reward shaping utilities
      - Pre-built environments: CartPole, GridWorld, RandomWalk
      - Environment wrappers: RewardShaper, StateNormalizer
    All algorithms (DQN, PPO, A3C) can use any environment interchangeably.
.NOTES
    Part of VBAF - Phase 3 Reinforcement Learning Module
    PS 5.1 compatible
#>
# Set base path
$basePath = $PSScriptRoot

# ============================================================
# SPACE DEFINITIONS - describe state and action spaces
# ============================================================
class VBAFSpace {
    [string] $Type    # "discrete" or "continuous"
    [int]    $Size    # number of actions OR state dimensions
    [double] $Low     # min value (continuous)
    [double] $High    # max value (continuous)

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
# BASE ENVIRONMENT - all environments inherit this interface
# ============================================================
class VBAFEnvironment {
    [string]     $Name
    [VBAFSpace]  $ObservationSpace
    [VBAFSpace]  $ActionSpace
    [int]        $Steps
    [int]        $MaxSteps
    [double]     $TotalReward
    [int]        $EpisodeCount

    VBAFEnvironment([string]$name, [int]$maxSteps) {
        $this.Name         = $name
        $this.MaxSteps     = $maxSteps
        $this.Steps        = 0
        $this.TotalReward  = 0.0
        $this.EpisodeCount = 0
    }

    # Override in subclass
    [double[]] Reset() { return @(0.0) }
    [double[]] GetState() { return @(0.0) }
    [hashtable] Step([int]$action) {
        return @{ NextState = @(0.0); Reward = 0.0; Done = $true }
    }

    [void] PrintInfo() {
        Write-Host "Environment : $($this.Name)"          -ForegroundColor Cyan
        Write-Host "Obs Space   : $($this.ObservationSpace.ToString())" -ForegroundColor Cyan
        Write-Host "Act Space   : $($this.ActionSpace.ToString())"      -ForegroundColor Cyan
        Write-Host "Max Steps   : $($this.MaxSteps)"      -ForegroundColor Cyan
    }
}

# ============================================================
# CARTPOLE ENVIRONMENT
# Classic control problem - balance a pole on a cart
# State : [position, velocity, angle, angularVelocity]
# Actions: 0=left, 1=right
# ============================================================
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
        $this.Rng              = [System.Random]::new($seed)
        $this.Reset()
    }

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
# Simple grid navigation - agent finds goal avoiding walls
# State : [row, col, goalRow, goalCol] normalized 0-1
# Actions: 0=up, 1=right, 2=down, 3=left
# ============================================================
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
        # Make sure agent and goal are not same cell
        while ($this.AgentRow -eq $this.GoalRow -and $this.AgentCol -eq $this.GoalCol) {
            $this.GoalRow = $this.Rng.Next(0, $this.GridSize)
            $this.GoalCol = $this.Rng.Next(0, $this.GridSize)
        }
        $this.Steps       = 0
        $this.TotalReward = 0.0
        $this.EpisodeCount++
        return $this.GetState()
    }

    [double[]] GetState() {
        [int] $g = $this.GridSize - 1
        [double[]] $arr = @(0.0, 0.0, 0.0, 0.0)
        $arr[0] = $this.AgentRow
        $arr[1] = $this.AgentCol
        $arr[2] = $this.GoalRow
        $arr[3] = $this.GoalCol
        $arr[0] /= $g
        $arr[1] /= $g
        $arr[2] /= $g
        $arr[3] /= $g
        return $arr
    }

    [hashtable] Step([int]$action) {
        $this.Steps++
        $newRow = $this.AgentRow
        $newCol = $this.AgentCol

        switch ($action) {
            0 { $newRow-- }  # up
            1 { $newCol++ }  # right
            2 { $newRow++ }  # down
            3 { $newCol-- }  # left
        }

        # Clamp to grid
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
# Simple 1D walk - agent tries to reach center (0)
# State : [position] normalized
# Actions: 0=left, 1=right
# Good for quick algorithm sanity checks
# ============================================================
class RandomWalkEnvironment : VBAFEnvironment {
    [int]    $Position
    [int]    $Range
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
# ENVIRONMENT FACTORY - create environments by name
# ============================================================
function New-VBAFEnvironment {
    param(
        [string] $Name     = "CartPole",
        [int]    $MaxSteps = 200,
        [int]    $GridSize = 5,
        [int]    $Seed     = -1
    )

    switch ($Name) {
        "CartPole" {
            if ($Seed -ge 0) {
                return [CartPoleEnvironment]::new($MaxSteps, $Seed)
            }
            return [CartPoleEnvironment]::new($MaxSteps)
        }
        "GridWorld" {
            return [GridWorldEnvironment]::new($GridSize, $MaxSteps)
        }
        "RandomWalk" {
            return [RandomWalkEnvironment]::new()
        }
        default {
            Write-Host "❌ Unknown environment: $Name" -ForegroundColor Red
            Write-Host "   Available: CartPole, GridWorld, RandomWalk" -ForegroundColor Yellow
            return $null
        }
    }
}

# ============================================================
# REWARD SHAPER WRAPPER
# Wraps any VBAFEnvironment to modify rewards
# ============================================================
function New-RewardShaper {
    param(
        [object]    $Environment,
        [double]    $Scale       = 1.0,
        [double]    $Clip        = 0.0,   # 0 = no clipping
        [double]    $StepPenalty = 0.0    # penalty per step
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
            if ($Clip -gt 0) {
                $r = [Math]::Max(-$Clip, [Math]::Min($Clip, $r))
            }
            return @{ NextState = $result.NextState; Reward = $r; Done = $result.Done }
        }
    }
}

# ============================================================
# BENCHMARKING UTILITY
# Run any algorithm on any environment and measure performance
# ============================================================
function Invoke-VBAFBenchmark {
    param(
        [object] $Agent,
        [object] $Environment,
        [int]    $Episodes = 10,
        [string] $Label    = "Benchmark"
    )

    Write-Host ""
    Write-Host "⏱️  $Label" -ForegroundColor Yellow
    Write-Host "   Episodes : $Episodes" -ForegroundColor Cyan

    $rewards  = [System.Collections.Generic.List[double]]::new()
    $timer    = [System.Diagnostics.Stopwatch]::StartNew()

    $rng        = [System.Random]::new()
    $actionSize = $Environment.ActionSpace.Size

    $useRandom = ($null -eq $Agent)

    if ($useRandom) {
        Write-Host "   Agent    : Random (no agent provided)" -ForegroundColor DarkYellow
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
    $avg  = ($rewards | Measure-Object -Average).Average
    $max  = ($rewards | Measure-Object -Maximum).Maximum
    $min  = ($rewards | Measure-Object -Minimum).Minimum
    $ms   = $timer.ElapsedMilliseconds

    Write-Host ""
    Write-Host "╔══════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host ("║  {0,-36}║" -f $Label)                  -ForegroundColor Yellow
    Write-Host "╠══════════════════════════════════════╣" -ForegroundColor Yellow
    Write-Host ("║  Avg Reward : {0,-23}║" -f [Math]::Round($avg, 2)) -ForegroundColor White
    Write-Host ("║  Max Reward : {0,-23}║" -f [Math]::Round($max, 2)) -ForegroundColor Green
    Write-Host ("║  Min Reward : {0,-23}║" -f [Math]::Round($min, 2)) -ForegroundColor White
    Write-Host ("║  Time (ms)  : {0,-23}║" -f $ms)                    -ForegroundColor Cyan
    Write-Host ("║  ms/episode : {0,-23}║" -f [Math]::Round($ms / $Episodes, 1)) -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════╝" -ForegroundColor Yellow
    Write-Host ""

    return @{ Avg = $avg; Max = $max; Min = $min; TimeMs = $ms }
}

# ============================================================
# TEST
# 1. Run VBAF.LoadAll.ps1
# 2. $env = New-VBAFEnvironment -Name "CartPole" -MaxSteps 200
# 3. $env = New-VBAFEnvironment -Name "GridWorld" -GridSize 5 -MaxSteps 100
# 4. $env = New-VBAFEnvironment -Name "RandomWalk"
# 5. $env.PrintInfo()
# 6. After training: Invoke-VBAFBenchmark -Agent $agent -Environment $env -Episodes 10
# NOTE: Always capture agent with [-1]: $agent = (Invoke-DQNTraining ...)[-1]
# ============================================================
Write-Host "📦 VBAF.RL.Environment.ps1 loaded" -ForegroundColor Green
Write-Host "   Classes   : VBAFSpace, VBAFEnvironment"          -ForegroundColor Cyan
Write-Host "   Environments: CartPole, GridWorld, RandomWalk"   -ForegroundColor Cyan
Write-Host "   Functions : New-VBAFEnvironment"                 -ForegroundColor Cyan
Write-Host "              New-RewardShaper"                     -ForegroundColor Cyan
Write-Host "              Invoke-VBAFBenchmark"                 -ForegroundColor Cyan
Write-Host ""
Write-Host "   Quick start:" -ForegroundColor Yellow
Write-Host '   $env = New-VBAFEnvironment -Name "CartPole" -MaxSteps 200' -ForegroundColor White
Write-Host '   $env.PrintInfo()'                                           -ForegroundColor White
Write-Host ""



