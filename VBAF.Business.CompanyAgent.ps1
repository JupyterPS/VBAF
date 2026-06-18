#Requires -Version 5.1
# VBAF.Business.CompanyAgent.ps1

<#
.SYNOPSIS
    Intelligent company agent with reinforcement learning brain
.DESCRIPTION
    A company that learns optimal business strategies through Q-Learning.
    Each company is an agent in a multi-agent market simulation.

    WHAT YOU ARE LEARNING HERE:
    ============================
    CompanyAgent is the bridge between abstract RL concepts and a
    concrete business problem. It wraps a QLearningAgent (the "Brain")
    inside a business context with:
      - Company state (cash, market share, profit, employees)
      - Business actions (price, invest, hire, expand)
      - Reward function (profit-based, with growth and satisfaction bonuses)

    AGENT ARCHITECTURE:
    ===================
    CompanyAgent contains:
      Brain:  QLearningAgent -- the learning algorithm
      Memory: ExperienceReplay -- stores past (state, action, reward) tuples
      State:  CompanyState -- the current business situation
      AvailableActions: BusinessAction[] -- what the agent can do

    This is the ADAPTER PATTERN -- wrapping a general-purpose RL agent
    (QLearningAgent) inside a domain-specific shell (CompanyAgent).
    The Brain knows nothing about companies or markets.
    The CompanyAgent knows nothing about Q-tables or epsilon-greedy.
    They communicate through strings (state representations) and numbers (rewards).

    STATE REPRESENTATION:
    =====================
    The QLearningAgent needs states as STRINGS (for Q-table keys).
    CompanyState.ToStateString() converts the company's situation
    into a compact string like "ProfitHigh_ShareMid_CashGood".
    This discretises the continuous business state into categories
    the Q-table can store and look up efficiently.

    REWARD FUNCTION DESIGN:
    =======================
    CalculateReward() defines WHAT the company is trying to optimise.
    Current reward components:
      +profit / 10000    -- primary objective: make money
      +growth * 20       -- bonus for revenue growth quarter-over-quarter
      +market_share * 10 -- bonus for gaining market position
      +satisfaction * 5  -- bonus for customer quality
      -5  if action failed (e.g. not enough cash)
      -50 if cash runs negative (bankruptcy warning)

    This reward function shapes what the agent learns.
    Different reward functions = different company personalities:
    - Remove market share bonus -> company optimises pure profit
    - Increase growth weight -> company becomes aggressive expander
    - Add competitor penalty -> company becomes more defensive

    EXPERIENCE REPLAY IN COMPANY CONTEXT:
    ======================================
    After each action, the agent:
    1. Stores the experience: (prevState, action, reward, newState)
    2. Immediately learns from it (online learning)
    3. Samples 5 random past experiences and learns from those too

    The random batch learning is experience replay -- the same technique
    used in DQN. It prevents the agent overfitting to the most recent
    experience and helps consolidate older lessons.

    QUARTER vs EPISODE:
    ===================
    In the multi-agent market simulation:
      Episode = one quarter of business operations
      MarketEnvironment calls SimulateQuarter() externally
    CompanyAgent.RunEpisode() is used for STANDALONE operation only.
    When running in MarketEnvironment, ExecuteAction() is called directly.

.NOTES
    Part of VBAF (Visual AI & Reinforcement Learning Framework)
    Educational use -- trace one full episode to see RL in a business context.
    Dependencies (must be loaded before this file):
      VBAF.RL.QLearningAgent.ps1
      VBAF.RL.ExperienceReplay.ps1
      VBAF.Business.CompanyState.ps1
      VBAF.Business.BusinessAction.ps1
#>

class CompanyAgent {

    #  Identity 
    [string]$Name
    [string]$Industry

    #  State 
    # Current and previous state -- previous state needed for reward calculation
    # (we need to measure how much things improved since last quarter)
    [CompanyState]$State
    [CompanyState]$PreviousState

    #  The Learning Brain 
    # Brain is a QLearningAgent -- the same class from VBAF.RL.QLearningAgent.ps1
    # It knows nothing about companies -- it just sees state strings and action strings.
    # Memory is an ExperienceReplay buffer -- same class from VBAF.RL.ExperienceReplay.ps1
    [QLearningAgent]$Brain
    [ExperienceReplay]$Memory
    [double]$TotalReward
    [int]$Episode

    #  Actions 
    # Available actions are predefined business moves: price, invest, hire, etc.
    # The Brain selects from these using epsilon-greedy Q-learning.
    [BusinessAction[]]$AvailableActions
    [BusinessAction]$LastAction

    #  Performance tracking 
    [System.Collections.ArrayList]$RewardHistory
    [System.Collections.ArrayList]$ProfitHistory
    [System.Collections.ArrayList]$MarketShareHistory

    # Constructor: create a company with starting capital.
    # Brain uses:
    #   LearningRate = 0.1 -- moderate learning speed
    #   Epsilon = 0.3      -- 30% exploration (less than pure RL -- business context)
    # Memory holds up to 500 past experiences (small -- business simulation is fast)
    CompanyAgent([string]$name, [string]$industry, [double]$startingCapital) {
        $this.Name     = $name
        $this.Industry = $industry
        $this.State    = New-Object CompanyState -ArgumentList $startingCapital
        $this.Episode  = 0
        $this.TotalReward = 0.0

        # Get all available business actions as string names for the Q-table
        $this.AvailableActions = [BusinessAction]::GetAllActions()
        $actionNames = $this.AvailableActions | ForEach-Object { $_.ToString() }

        # Create the Q-learning brain
        # Lower epsilon (0.3) than typical RL -- business agents exploit more
        # because random actions can waste large amounts of money
        $this.Brain  = New-Object QLearningAgent -ArgumentList $actionNames, 0.1, 0.3

        # Experience replay -- small buffer sufficient for business simulation
        $this.Memory = New-Object ExperienceReplay -ArgumentList 500

        $this.RewardHistory     = New-Object System.Collections.ArrayList
        $this.ProfitHistory     = New-Object System.Collections.ArrayList
        $this.MarketShareHistory = New-Object System.Collections.ArrayList
    }

    # Return the current company state.
    [CompanyState] ObserveState() {
        return $this.State
    }

    # DECIDE ACTION: the epsilon-greedy decision step.
    #
    # 1. Convert company state to a string the Q-table understands
    # 2. Brain.ChooseAction() returns the action string (epsilon-greedy)
    # 3. Find the matching BusinessAction object
    #
    # This is where the RL agent "thinks" -- the Q-table lookup happens here.
    # After many quarters, the Q-table learns: in state "ProfitLow_CashGood"
    # the best action is "Investment_RnD" (not "Pricing_Increase").
    [BusinessAction] DecideAction() {
        $stateStr   = $this.State.ToStateString()
        $actionName = $this.Brain.ChooseAction($stateStr)

        $action = $this.AvailableActions |
            Where-Object { $_.ToString() -eq $actionName } |
            Select-Object -First 1

        if ($null -eq $action) { $action = [BusinessAction]::DoNothing() }

        $this.LastAction = $action
        return $action
    }

    # EXECUTE ACTION: apply the chosen action and calculate reward.
    #
    # NOTE: This does NOT simulate the quarter -- that is done by MarketEnvironment.
    # MarketEnvironment.SimulateQuarter() handles market-level interactions
    # (how companies compete for market share, how prices affect demand).
    # CompanyAgent only handles the immediate effects of its own action.
    [hashtable] ExecuteAction([BusinessAction]$action) {
        $this.PreviousState = $this.State.Clone()

        $results = $this.ApplyActionEffects($action)
        $reward  = $this.CalculateReward($results)

        return @{
            Action   = $action
            Results  = $results
            Reward   = $reward
            NewState = $this.State
        }
    }

    # APPLY ACTION EFFECTS: change company state based on chosen action.
    #
    # Each action type has different effects:
    #   Pricing:     change AveragePrice (affects demand and revenue next quarter)
    #   Investment:  spend cash to improve InnovationScore, BrandValue, or Capacity
    #   Operational: hire/layoff employees, improve quality, reduce costs
    #   Strategic:   expand to new markets, launch products (probabilistic success)
    #
    # Actions that require cash check State.Cash before applying.
    # Failed actions (insufficient cash) are recorded in results.Success = false.
    hidden [hashtable] ApplyActionEffects([BusinessAction]$action) {
        $results = @{ Type = $action.Type; Success = $true; Message = "" }

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
                    if ($action.Parameters.ContainsKey('InnovationBoost'))   { $this.State.InnovationScore    += $action.Parameters.InnovationBoost }
                    if ($action.Parameters.ContainsKey('BrandBoost'))        { $this.State.BrandValue         *= (1 + $action.Parameters.BrandBoost) }
                    if ($action.Parameters.ContainsKey('CapacityIncrease'))  { $this.State.ProductionCapacity *= (1 + $action.Parameters.CapacityIncrease) }
                    $results.Message = "Invested `$$cost in $($action.Name)"
                } else {
                    $results.Success = $false
                    $results.Message = "Insufficient cash (need `$$cost, have `$$($this.State.Cash))"
                }
            }

            "Operational" {
                if ($action.Name.StartsWith("Hire")) {
                    $count = $action.Parameters.Count
                    $cost  = $action.Parameters.Cost
                    if ($this.State.Cash -ge $cost) {
                        $this.State.EmployeeCount        += $count
                        $this.State.Cash                 -= $cost
                        $this.State.ProductionCapacity   *= (1 + $count * 0.05)
                        $results.Message = "Hired $count employees"
                    } else {
                        $results.Success = $false; $results.Message = "Cannot afford to hire"
                    }
                }
                elseif ($action.Name.StartsWith("Layoff")) {
                    $count = $action.Parameters.Count
                    if ($this.State.EmployeeCount -gt $count) {
                        $this.State.EmployeeCount      -= $count
                        $this.State.Cash               -= $action.Parameters.SeveranceCost
                        $this.State.ProductionCapacity *= 0.95
                        $results.Message = "Laid off $count employees"
                    } else {
                        $results.Success = $false; $results.Message = "Not enough employees to lay off"
                    }
                }
                elseif ($action.Name -eq "Quality_Improve") {
                    if ($this.State.Cash -ge $action.Parameters.Cost) {
                        $this.State.Cash            -= $action.Parameters.Cost
                        $this.State.ProductQuality  += $action.Parameters.QualityIncrease
                        $this.State.ProductQuality   = [Math]::Min($this.State.ProductQuality, 1.0)
                        $results.Message = "Improved product quality"
                    } else {
                        $results.Success = $false; $results.Message = "Cannot afford quality improvement"
                    }
                }
                elseif ($action.Name -eq "Cost_Reduction") {
                    $this.State.Costs          *= (1 - $action.Parameters.CostSavings)
                    $this.State.ProductQuality *= (1 + $action.Parameters.QualityImpact)
                    $results.Message = "Reduced costs by $($action.Parameters.CostSavings.ToString('P0'))"
                }
            }

            "Strategic" {
                if ($action.Name -eq "Market_Expand") {
                    if ($this.State.Cash -ge $action.Parameters.Cost) {
                        $this.State.Cash -= $action.Parameters.Cost
                        # Market expansion is PROBABILISTIC -- reflects real business uncertainty
                        $success = (Get-Random -Minimum 0.0 -Maximum 1.0) -gt $action.Parameters.RiskLevel
                        if ($success) {
                            $this.State.MarketShare *= (1 + $action.Parameters.NewCustomerPotential)
                            $results.Message = "Market expansion successful!"
                        } else {
                            $results.Success = $false; $results.Message = "Market expansion failed (bad luck)"
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
                            $results.Success = $false; $results.Message = "Product launch failed"
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

    # SIMULATE QUARTER: compute one quarter of business results.
    #
    # Called by MarketEnvironment after all companies have chosen actions.
    # Economics modelled:
    #   Demand:  base demand adjusted for market share, price, quality, satisfaction
    #   Supply:  capped at ProductionCapacity
    #   Revenue: units sold * price
    #   Costs:   fixed (employees) + variable (per unit) costs
    #   Profit:  revenue - costs
    #
    # PRICE ELASTICITY:
    # Price above 100 -> demand falls (customers buy less at higher prices)
    # Price below 100 -> demand rises (price attracts more customers)
    # Capped to prevent extreme values from destabilising the simulation.
    hidden [void] SimulateQuarter() {
        $economyGrowth = if ($this.State.PSObject.Properties['GDPGrowth']) { $this.State.GDPGrowth } else { 0.03 }

        $baseDemand  = 1000.0 * (1.0 + $economyGrowth)
        $baseDemand *= (1.0 + ($this.State.MarketShare * 2.0))
        $baseDemand *= (0.5 + ($this.State.CustomerSatisfaction * 0.5))
        $baseDemand *= (0.7 + ($this.State.ProductQuality * 0.3))

        # Price elasticity -- higher price reduces demand, lower price increases it
        $priceEffect = 1.0
        if ($this.State.AveragePrice -gt 100) {
            $priceDiff   = [Math]::Min(($this.State.AveragePrice - 100) / 100, 2.0)
            $priceEffect = [Math]::Max(1.0 - ($priceDiff * 0.3), 0.3)
        } else {
            $priceDiff   = [Math]::Min((100 - $this.State.AveragePrice) / 100, 2.0)
            $priceEffect = [Math]::Min(1.0 + ($priceDiff * 0.2), 2.0)
        }

        $demand                      = [Math]::Max($baseDemand * $priceEffect, 0)
        $production                  = [Math]::Max([Math]::Min($demand, $this.State.ProductionCapacity), 0)
        $this.State.ProductsSold     = [int]$production
        $this.State.CapacityUtilization = if ($this.State.ProductionCapacity -gt 0) {
            [Math]::Min($production / $this.State.ProductionCapacity, 1.0)
        } else { 0.0 }

        $this.State.Revenue          = [Math]::Max($production * $this.State.AveragePrice, 0)
        $fixedCosts                  = [Math]::Max($this.State.EmployeeCount * 12500, 0)
        $variableCosts               = [Math]::Max($production * 30, 0)
        $this.State.Costs            = $fixedCosts + $variableCosts
        $this.State.Profit           = $this.State.Revenue - $this.State.Costs
        $this.State.ProfitMargin     = if ($this.State.Revenue -gt 0) { $this.State.Profit / $this.State.Revenue } else { 0.0 }
        $this.State.Cash            += $this.State.Profit

        # Customer satisfaction drifts based on quality and price
        $qualityEffect = [Math]::Max([Math]::Min($this.State.ProductQuality * 0.05, 0.1), -0.1)
        $priceEff      = if ($this.State.AveragePrice -lt 100) { 0.02 } else { -0.02 }
        $this.State.CustomerSatisfaction += $qualityEffect + $priceEff
        $this.State.CustomerSatisfaction  = [Math]::Max(0.1, [Math]::Min(1.0, $this.State.CustomerSatisfaction))

        # Market share drifts based on innovation and satisfaction
        $shareChange = ($this.State.InnovationScore * 0.01) + ($this.State.CustomerSatisfaction * 0.005)
        $shareChange = [Math]::Max([Math]::Min($shareChange, 0.05), -0.05)
        $this.State.MarketShare = [Math]::Max(0.0, [Math]::Min(0.5, $this.State.MarketShare + $shareChange))

        $this.State.Quarter++
        if ($this.State.Quarter -gt 4) { $this.State.Quarter = 1; $this.State.Year++ }

        $this.ProfitHistory.Add([double]$this.State.Profit) | Out-Null
        $this.MarketShareHistory.Add([double]$this.State.MarketShare) | Out-Null
    }

    # CALCULATE REWARD: how good was this quarter for the company
    #
    # The reward function defines what "success" means.
    # Components:
    #   profit / 10000     -- normalise profit to a reasonable scale
    #   growth * 20        -- reward increasing revenue quarter-over-quarter
    #   market_share * 10  -- reward gaining market position
    #   satisfaction * 5   -- reward keeping customers happy
    #   -5 if action failed -- penalise wasted moves (e.g. insufficient cash)
    #   -50 if cash < 0    -- strong penalty for approaching bankruptcy
    #
    # Experimenting with reward weights changes company behaviour:
    # Increase growth weight -> more aggressive expansion
    # Reduce market share weight -> focus on profit over growth
    hidden [double] CalculateReward([hashtable]$results) {
        $reward = 0.0

        $reward += $this.State.Profit / 10000.0

        if ($null -ne $this.PreviousState) {
            $growthRate = if ($this.PreviousState.Revenue -gt 0) {
                ($this.State.Revenue - $this.PreviousState.Revenue) / $this.PreviousState.Revenue
            } else { 0.0 }
            $reward += $growthRate * 20.0
        }

        $reward += $this.State.MarketShare * 10.0
        $reward += $this.State.CustomerSatisfaction * 5.0

        if (-not $results.Success) { $reward -= 5.0 }    # Penalise failed actions
        if ($this.State.Cash -lt 0) { $reward -= 50.0 }  # Penalise near-bankruptcy

        return $reward
    }

    # LEARN: update the Q-table from this quarter's experience.
    #
    # Two types of learning happen here:
    #   1. Immediate learning: learn from the just-completed (state, action, reward) tuple
    #   2. Experience replay: sample 5 random past experiences and learn from those too
    #
    # Experience replay prevents the agent forgetting older strategies
    # and helps consolidate learning across many quarters.
    [void] Learn([double]$reward) {
        $prevStateStr = $this.PreviousState.ToStateString()
        $currStateStr = $this.State.ToStateString()
        $actionStr    = $this.LastAction.ToString()

        # Store this experience for future replay
        $this.Memory.Add(@{
            State     = $prevStateStr
            Action    = $actionStr
            Reward    = $reward
            NextState = $currStateStr
        })

        # Immediate learning from this experience
        $this.Brain.Learn($prevStateStr, $actionStr, $reward, $currStateStr)

        # Experience replay -- learn from 5 random past experiences
        if ($this.Memory.Memory.Count -ge 10) {
            $batch = $this.Memory.Sample(5)
            foreach ($exp in $batch) {
                $this.Brain.Learn($exp.State, $exp.Action, $exp.Reward, $exp.NextState)
            }
        }

        $this.TotalReward += $reward
        $this.RewardHistory.Add([double]$reward) | Out-Null
    }

    # RUN EPISODE: one full quarter cycle for standalone operation.
    # In multi-agent mode (MarketEnvironment), this is NOT called --
    # instead, ExecuteAction() is called directly by MarketEnvironment.
    [hashtable] RunEpisode() {
        $action  = $this.DecideAction()
        $results = $this.ExecuteAction($action)
        $this.Learn($results.Reward)
        $this.Brain.DecayEpsilon(0.995)
        $this.Episode++
        return $results
    }

    [hashtable] GetPerformanceSummary() {
        $avgReward = if ($this.RewardHistory.Count  -gt 0) { ($this.RewardHistory  | Measure-Object -Average).Average } else { 0.0 }
        $avgProfit = if ($this.ProfitHistory.Count  -gt 0) { ($this.ProfitHistory  | Measure-Object -Average).Average } else { 0.0 }

        return @{
            Company       = $this.Name
            Episodes      = $this.Episode
            TotalReward   = $this.TotalReward
            AverageReward = $avgReward
            CurrentProfit = $this.State.Profit
            AverageProfit = $avgProfit
            MarketShare   = $this.State.MarketShare
            Cash          = $this.State.Cash
            Epsilon       = $this.Brain.Epsilon
        }
    }

    [void] DisplayState() {
        Write-Host ""
        Write-Host "  === $($this.Name) ($($this.Industry)) ===" -ForegroundColor Cyan
        Write-Host $this.State.ToString()
        Write-Host "  Learning:" -ForegroundColor Yellow
        Write-Host "    Episode    : $($this.Episode)"
        Write-Host "    TotalReward: $($this.TotalReward.ToString('F2'))"
        Write-Host "    Epsilon    : $($this.Brain.Epsilon.ToString('F3'))"
    }
}