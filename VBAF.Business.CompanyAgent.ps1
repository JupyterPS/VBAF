#Requires -Version 5.1
# VBAF.Business.CompanyAgent.ps1

<#
.SYNOPSIS
    Intelligent company agent with reinforcement learning
.DESCRIPTION
    Company that learns optimal business strategies through
    Q-Learning and experience replay.
.NOTES
    Part of VBAF Phase 2 - Business Applications
    Dependencies: QLearningAgent, ExperienceReplay, CompanyState, BusinessAction
    These must be loaded BEFORE this file is dot-sourced
#>

class CompanyAgent {
    # Identity
    [string]$Name
    [string]$Industry
    
    # State
    [CompanyState]$State
    [CompanyState]$PreviousState
    
    # Learning
    [QLearningAgent]$Brain
    [ExperienceReplay]$Memory
    [double]$TotalReward
    [int]$Episode
    
    # Actions
    [BusinessAction[]]$AvailableActions
    [BusinessAction]$LastAction
    
    # Performance Tracking
    [System.Collections.ArrayList]$RewardHistory
    [System.Collections.ArrayList]$ProfitHistory
    [System.Collections.ArrayList]$MarketShareHistory
    
    # Constructor
    CompanyAgent([string]$name, [string]$industry, [double]$startingCapital) {
        $this.Name = $name
        $this.Industry = $industry
        $this.State = New-Object CompanyState -ArgumentList $startingCapital
        $this.Episode = 0
        $this.TotalReward = 0.0
        
        # Initialize available actions
        $this.AvailableActions = [BusinessAction]::GetAllActions()
        $actionNames = $this.AvailableActions | ForEach-Object { $_.ToString() }
        
        # Create Q-Learning brain
        # Learning rate: 0.1, Epsilon: 0.3 (30% exploration)
        $this.Brain = New-Object QLearningAgent -ArgumentList $actionNames, 0.1, 0.3
        
        # Experience replay memory (max 500 experiences)
        $this.Memory = New-Object ExperienceReplay -ArgumentList 500
        
        # Performance tracking
        $this.RewardHistory = New-Object System.Collections.ArrayList
        $this.ProfitHistory = New-Object System.Collections.ArrayList
        $this.MarketShareHistory = New-Object System.Collections.ArrayList
    }
    
    # Observe current state
    [CompanyState] ObserveState() {
        return $this.State
    }
    
    # Decide next action using Q-Learning
    [BusinessAction] DecideAction() {
        # Get state representation
        $stateStr = $this.State.ToStateString()
        
        # Agent chooses action (epsilon-greedy)
        $actionName = $this.Brain.ChooseAction($stateStr)
        
        # Find corresponding BusinessAction
        $action = $this.AvailableActions | Where-Object { $_.ToString() -eq $actionName } | Select-Object -First 1
        
        if ($null -eq $action) {
            # Fallback: do nothing
            $action = [BusinessAction]::DoNothing()
        }
        
        $this.LastAction = $action
        return $action
    }
    
# Execute action and update state
[hashtable] ExecuteAction([BusinessAction]$action) {
    # Save previous state
    $this.PreviousState = $this.State.Clone()
    
    # Apply action effects
    $results = $this.ApplyActionEffects($action)
    
    # NOTE: Do NOT simulate quarter here - the MarketEnvironment handles that!
    # Only simulate if this company is running standalone (not in a market)
    # $this.SimulateQuarter()  <-- REMOVE THIS LINE
    
    # Calculate reward
    $reward = $this.CalculateReward($results)
    
    return @{
        Action = $action
        Results = $results
        Reward = $reward
        NewState = $this.State
    }
}
    
    # Apply action effects to state
    hidden [hashtable] ApplyActionEffects([BusinessAction]$action) {
        $results = @{
            Type = $action.Type
            Success = $true
            Message = ""
        }
        
        switch ($action.Type) {
            "Pricing" {
                $oldPrice = $this.State.AveragePrice
                $this.State.AveragePrice = $oldPrice * $action.Parameters.PriceMultiplier
                $results.Message = "Price changed from `$$($oldPrice) to `$$($this.State.AveragePrice)"
            }
            
            "Investment" {
                $cost = $action.Parameters.Amount
                
                if ($this.State.Cash -ge $cost) {
                    $this.State.Cash -= $cost
                    
                    # Apply investment benefits
                    if ($action.Parameters.ContainsKey('InnovationBoost')) {
                        $this.State.InnovationScore += $action.Parameters.InnovationBoost
                    }
                    if ($action.Parameters.ContainsKey('BrandBoost')) {
                        $this.State.BrandValue *= (1 + $action.Parameters.BrandBoost)
                    }
                    if ($action.Parameters.ContainsKey('CapacityIncrease')) {
                        $this.State.ProductionCapacity *= (1 + $action.Parameters.CapacityIncrease)
                    }
                    
                    $results.Message = "Invested `$$cost in $($action.Name)"
                } else {
                    $results.Success = $false
                    $results.Message = "Insufficient cash for investment (need `$$cost, have `$$($this.State.Cash))"
                }
            }
            
            "Operational" {
                if ($action.Name.StartsWith("Hire")) {
                    $count = $action.Parameters.Count
                    $cost = $action.Parameters.Cost
                    
                    if ($this.State.Cash -ge $cost) {
                        $this.State.EmployeeCount += $count
                        $this.State.Cash -= $cost
                        $this.State.ProductionCapacity *= (1 + $count * 0.05)
                        $results.Message = "Hired $count employees"
                    } else {
                        $results.Success = $false
                        $results.Message = "Cannot afford to hire"
                    }
                }
                elseif ($action.Name.StartsWith("Layoff")) {
                    $count = $action.Parameters.Count
                    if ($this.State.EmployeeCount -gt $count) {
                        $this.State.EmployeeCount -= $count
                        $this.State.Cash -= $action.Parameters.SeveranceCost
                        $this.State.ProductionCapacity *= 0.95
                        $results.Message = "Laid off $count employees"
                    } else {
                        $results.Success = $false
                        $results.Message = "Not enough employees to layoff"
                    }
                }
                elseif ($action.Name -eq "Quality_Improve") {
                    if ($this.State.Cash -ge $action.Parameters.Cost) {
                        $this.State.Cash -= $action.Parameters.Cost
                        $this.State.ProductQuality += $action.Parameters.QualityIncrease
                        $this.State.ProductQuality = [Math]::Min($this.State.ProductQuality, 1.0)
                        $results.Message = "Improved quality"
                    } else {
                        $results.Success = $false
                        $results.Message = "Cannot afford quality improvement"
                    }
                }
                elseif ($action.Name -eq "Cost_Reduction") {
                    $this.State.Costs *= (1 - $action.Parameters.CostSavings)
                    $this.State.ProductQuality *= (1 + $action.Parameters.QualityImpact)
                    $results.Message = "Reduced costs by $($action.Parameters.CostSavings.ToString('P0'))"
                }
            }
            
            "Strategic" {
                if ($action.Name -eq "Market_Expand") {
                    if ($this.State.Cash -ge $action.Parameters.Cost) {
                        $this.State.Cash -= $action.Parameters.Cost
                        # Success is probabilistic
                        $success = (Get-Random -Minimum 0.0 -Maximum 1.0) -gt $action.Parameters.RiskLevel
                        if ($success) {
                            $this.State.MarketShare *= (1 + $action.Parameters.NewCustomerPotential)
                            $results.Message = "Market expansion successful!"
                        } else {
                            $results.Message = "Market expansion failed"
                            $results.Success = $false
                        }
                    }
                }
                elseif ($action.Name -eq "Product_Launch") {
                    if ($this.State.Cash -ge $action.Parameters.Cost) {
                        $this.State.Cash -= $action.Parameters.Cost
                        $success = (Get-Random -Minimum 0.0 -Maximum 1.0) -lt $action.Parameters.SuccessProbability
                        if ($success) {
                            $this.State.ProductsInPipeline++
                            $results.Message = "Product launch successful!"
                        } else {
                            $results.Message = "Product launch failed"
                            $results.Success = $false
                        }
                    }
                }
                elseif ($action.Name -eq "Hold_Position") {
                    $results.Message = "Maintaining current strategy"
                }
            }
        }
        
        return $results
    }
    
    # Simulate one quarter of business
    hidden [void] SimulateQuarter() {
        # Use GDPGrowth from market state (injected by MarketEnvironment)
        $economyGrowth = if ($this.State.PSObject.Properties['GDPGrowth']) { 
            $this.State.GDPGrowth 
        } else { 
            0.03  # Default 3% growth if not set
        }
        $baseDemand = 1000.0 * (1.0 + $economyGrowth)
        $baseDemand *= (1.0 + ($this.State.MarketShare * 2.0))  # Market share boost
        $baseDemand *= (0.5 + ($this.State.CustomerSatisfaction * 0.5))
        $baseDemand *= (0.7 + ($this.State.ProductQuality * 0.3))
        
        # Price elasticity (bounded to prevent extreme values)
        $priceEffect = 1.0
        if ($this.State.AveragePrice -gt 100) {
            $priceDiff = [Math]::Min(($this.State.AveragePrice - 100) / 100, 2.0)
            $priceEffect = [Math]::Max(1.0 - ($priceDiff * 0.3), 0.3)
        } else {
            $priceDiff = [Math]::Min((100 - $this.State.AveragePrice) / 100, 2.0)
            $priceEffect = [Math]::Min(1.0 + ($priceDiff * 0.2), 2.0)
        }
        
        $demand = [Math]::Max($baseDemand * $priceEffect, 0)
        
        # Production constraint
        $production = [Math]::Min($demand, $this.State.ProductionCapacity)
        $production = [Math]::Max($production, 0)  # Never negative
        $this.State.ProductsSold = [int]$production
        
        # Capacity utilization (bounded 0-1)
        if ($this.State.ProductionCapacity -gt 0) {
            $this.State.CapacityUtilization = [Math]::Min($production / $this.State.ProductionCapacity, 1.0)
        } else {
            $this.State.CapacityUtilization = 0.0
        }
        
        # Revenue (always positive or zero)
        $this.State.Revenue = [Math]::Max($production * $this.State.AveragePrice, 0)
        
        # Costs (realistic and bounded)
        $fixedCosts = [Math]::Max($this.State.EmployeeCount * 12500, 0)  # ~$50k/year per employee
        $variableCosts = [Math]::Max($production * 30, 0)  # $30 per unit
        $this.State.Costs = $fixedCosts + $variableCosts
        
        # Profit
        $this.State.Profit = $this.State.Revenue - $this.State.Costs
        if ($this.State.Revenue -gt 0) {
            $this.State.ProfitMargin = $this.State.Profit / $this.State.Revenue
        } else {
            $this.State.ProfitMargin = 0.0
        }
        
        # Update cash
        $this.State.Cash += $this.State.Profit
        
        # Update customer satisfaction (bounded changes)
        $qualityEffect = [Math]::Max([Math]::Min($this.State.ProductQuality * 0.05, 0.1), -0.1)
        $priceEffect = if ($this.State.AveragePrice -lt 100) { 0.02 } else { -0.02 }
        $this.State.CustomerSatisfaction += $qualityEffect + $priceEffect
        $this.State.CustomerSatisfaction = [Math]::Max(0.1, [Math]::Min(1.0, $this.State.CustomerSatisfaction))
        
        # Update market share (bounded growth)
        $shareChange = ($this.State.InnovationScore * 0.01) + ($this.State.CustomerSatisfaction * 0.005)
        $shareChange = [Math]::Max([Math]::Min($shareChange, 0.05), -0.05)  # Max 5% change per quarter
        $this.State.MarketShare += $shareChange
        $this.State.MarketShare = [Math]::Max(0.0, [Math]::Min(0.5, $this.State.MarketShare))
        
        # Increment time
        $this.State.Quarter++
        if ($this.State.Quarter -gt 4) {
            $this.State.Quarter = 1
            $this.State.Year++
        }
        
        # Track history
        $this.ProfitHistory.Add([double]$this.State.Profit) | Out-Null
        $this.MarketShareHistory.Add([double]$this.State.MarketShare) | Out-Null
    }
    
    # Calculate reward for RL
    hidden [double] CalculateReward([hashtable]$results) {
        $reward = 0.0
        
        # Primary: Profit
        $reward += $this.State.Profit / 10000.0  # Normalize to reasonable scale
        
        # Growth
        if ($null -ne $this.PreviousState) {
            $growthRate = if ($this.PreviousState.Revenue -gt 0) {
                ($this.State.Revenue - $this.PreviousState.Revenue) / $this.PreviousState.Revenue
            } else { 0.0 }
            $reward += $growthRate * 20.0
        }
        
        # Market share bonus
        $reward += $this.State.MarketShare * 10.0
        
        # Customer satisfaction bonus
        $reward += $this.State.CustomerSatisfaction * 5.0
        
        # Penalty for failed actions
        if (-not $results.Success) {
            $reward -= 5.0
        }
        
        # Penalty for running out of cash
        if ($this.State.Cash -lt 0) {
            $reward -= 50.0
        }
        
        return $reward
    }
    
    # Learn from experience
    [void] Learn([double]$reward) {
        $prevStateStr = $this.PreviousState.ToStateString()
        $currStateStr = $this.State.ToStateString()
        $actionStr = $this.LastAction.ToString()
        
        # Store experience
        $this.Memory.Add(@{
            State = $prevStateStr
            Action = $actionStr
            Reward = $reward
            NextState = $currStateStr
        })
        
        # Learn from this experience
        $this.Brain.Learn($prevStateStr, $actionStr, $reward, $currStateStr)
        
        # Also learn from a random batch (experience replay)
        if ($this.Memory.Memory.Count -ge 10) {
            $batch = $this.Memory.Sample(5)
            foreach ($exp in $batch) {
                $this.Brain.Learn($exp.State, $exp.Action, $exp.Reward, $exp.NextState)
            }
        }
        
        # Track reward
        $this.TotalReward += $reward
        $this.RewardHistory.Add([double]$reward) | Out-Null
    }
    
    # Run one episode (one quarter)
    [hashtable] RunEpisode() {
        # Decide action
        $action = $this.DecideAction()
        
        # Execute action
        $results = $this.ExecuteAction($action)
        
        # Learn from result
        $this.Learn($results.Reward)
        
        # Decay exploration
        $this.Brain.DecayEpsilon(0.995)
        
        # Increment episode
        $this.Episode++
        
        return $results
    }
    
    # Get performance summary
    [hashtable] GetPerformanceSummary() {
        $avgReward = if ($this.RewardHistory.Count -gt 0) {
            ($this.RewardHistory | Measure-Object -Average).Average
        } else { 0.0 }
        
        $avgProfit = if ($this.ProfitHistory.Count -gt 0) {
            ($this.ProfitHistory | Measure-Object -Average).Average
        } else { 0.0 }
        
        return @{
            Company = $this.Name
            Episodes = $this.Episode
            TotalReward = $this.TotalReward
            AverageReward = $avgReward
            CurrentProfit = $this.State.Profit
            AverageProfit = $avgProfit
            MarketShare = $this.State.MarketShare
            Cash = $this.State.Cash
            Epsilon = $this.Brain.Epsilon
        }
    }
    
    # Display current state
    [void] DisplayState() {
        Write-Host "`n=== $($this.Name) ($($this.Industry)) ===" -ForegroundColor Cyan
        Write-Host $this.State.ToString()
        Write-Host "Learning:" -ForegroundColor Yellow
        Write-Host "  Episode: $($this.Episode)"
        Write-Host "  Total Reward: $($this.TotalReward.ToString('F2'))"
        Write-Host "  Exploration (ε): $($this.Brain.Epsilon.ToString('F3'))"
    }
}