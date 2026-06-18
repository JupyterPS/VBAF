#Requires -Version 5.1

<#
.SYNOPSIS
    Multi-Agent Market Environment
.DESCRIPTION
    Simulates a competitive market where multiple company agents
    interact, compete, and learn from each other.

    WHAT YOU ARE LEARNING HERE:
    ============================
    MarketEnvironment is the ORCHESTRATOR of the multi-agent simulation.
    It controls the shared world that all CompanyAgents live in.

    In single-agent RL (DQN, PPO, A3C):
      One agent, one environment, one reward signal.

    In multi-agent RL (this file):
      Multiple agents, ONE shared environment, SEPARATE reward signals.
      Each agent's actions affect ALL other agents' outcomes.
      The environment is NON-STATIONARY -- it changes as agents learn.

    WHY MULTI-AGENT RL IS HARDER:
    ==============================
    In single-agent RL, the environment is fixed -- the Q-table converges
    because the mapping from (state, action) to reward is stable.

    In multi-agent RL, the environment keeps changing because OTHER AGENTS
    keep changing their behaviour. If TechCorp learns to lower prices,
    MarketLeader's optimal strategy changes in response.

    This is called NON-STATIONARITY -- the target keeps moving.
    It is one of the central challenges in multi-agent RL research.

    THE SIMULATION CYCLE (one quarter):
    =====================================
    Step 1 -- UpdateGlobalState:
      Economy grows or contracts. Market condition updates (Bullish/Neutral/Bearish).

    Step 2 -- CheckForRandomEvents (10% chance each quarter):
      Recession, boom, tech breakthrough, regulation, consumer shift.
      These inject external shocks the agents must adapt to.

    Step 3 -- Each company observes and decides:
      Company sees current economy, interest rate, market condition.
      Brain.ChooseAction() picks the action (epsilon-greedy Q-learning).

    Step 4 -- ResolveInteractions:
      Companies compete! Pricing and market share effects computed.
      Bertrand price competition: lower price = demand advantage.
      Quality/innovation competition: better product = more market share.

    Step 5 -- Execute and simulate:
      Each company applies its action, then simulates the quarter.
      Market environment applies interaction effects BEFORE simulation.

    Step 6 -- Each company learns:
      Brain.Learn() updates Q-table from (state, action, reward).

    Step 7 -- Record history:
      Snapshot of all companies' states saved for analysis.

    BERTRAND PRICE COMPETITION:
    ============================
    Named after economist Joseph Bertrand (1883).
    Companies that price BELOW the market average gain demand advantage.
    Companies that price ABOVE the average lose customers.
    This creates pressure toward the equilibrium price.

    In Q-learning terms: agents that learn to price competitively
    receive higher rewards and those actions get higher Q-values.
    Over time, pricing strategies converge (tacit collusion or price war).

    RANDOM EVENTS:
    ==============
    10% chance per quarter of a market shock:
    - Recession:  economy growth = -3% (all companies suffer)
    - Boom:       economy growth = +8% (all companies benefit)
    - Tech breakthrough: one random company gets +0.2 innovation score
    - New regulation: all companies pay 5% cost increase
    - Consumer shift: high-quality companies gain satisfaction boost

    These events test whether agents have learned ROBUST strategies
    or just memorised the baseline scenario.

    GAME THEORY CONNECTIONS:
    =========================
    Cournot competition: firms choose quantities, prices determined by market
    Bertrand competition: firms choose prices, market share follows (this model)
    Nash equilibrium: no firm can improve by changing strategy alone
    Prisoner's dilemma: mutual price cuts hurt everyone but are individually rational

    Q-learning agents sometimes discover tacit collusion (avoiding price wars)
    as the Nash equilibrium -- without any communication or programming.

.NOTES
    Part of VBAF (Visual AI & Reinforcement Learning Framework)
    Educational use -- the most complex environment in VBAF.
    Requires VBAF.Business.CompanyAgent.ps1 (and its dependencies).
#>

$basePath = $PSScriptRoot

. (Join-Path $basePath "VBAF.Business.CompanyAgent.ps1")


class MarketEnvironment {

    #  Market participants 
    [System.Collections.ArrayList]$Companies   # All competing CompanyAgents

    #  Shared economic state 
    # All companies see these values each quarter -- the "macro environment"
    [int]$CurrentQuarter
    [int]$CurrentYear
    [double]$EconomyGrowth     # Current GDP growth rate (can be negative in recession)
    [double]$InterestRate      # Cost of capital (affects investment decisions)
    [string]$MarketCondition   # "Bullish", "Neutral", or "Bearish"
    [double]$TotalMarketSize   # Total demand available to all companies combined

    #  History 
    # Every quarter gets a snapshot -- useful for plotting learning curves
    [System.Collections.ArrayList]$History

    #  Configuration 
    [hashtable]$Config

    MarketEnvironment() {
        $this.Companies        = New-Object System.Collections.ArrayList
        $this.History          = New-Object System.Collections.ArrayList
        $this.CurrentQuarter   = 1
        $this.CurrentYear      = 1
        $this.EconomyGrowth    = 0.02    # Start at 2% growth -- mild expansion
        $this.InterestRate     = 0.05    # 5% interest rate
        $this.MarketCondition  = "Neutral"
        $this.TotalMarketSize  = 1000000.0

        $this.Config = @{
            EnableRandomEvents  = $true
            EventProbability    = 0.10    # 10% chance of a market event each quarter
            EnableCompetition   = $true
            EnableSupplyDemand  = $true
        }
    }

    # ADD COMPANY: register a CompanyAgent with the market.
    # Injects the current macro environment into the company's state
    # so the agent can observe economic conditions when making decisions.
    [void] AddCompany([CompanyAgent]$company) {
        $this.Companies.Add($company) | Out-Null

        # Inject macro environment into company state
        $company.State.EconomyGrowth   = $this.EconomyGrowth
        $company.State.InterestRate    = $this.InterestRate
        $company.State.MarketCondition = $this.MarketCondition
        $company.State.CompetitorCount = $this.Companies.Count - 1

        Write-Host "  Added $($company.Name) to market" -ForegroundColor Green
    }

    # SIMULATE ONE QUARTER: the main orchestration method.
    # This runs the complete 8-step simulation cycle.
    # Called once per quarter in the training loop.
    [hashtable] SimulateQuarter() {
        Write-Host ""
        Write-Host "  === Quarter $($this.CurrentQuarter), Year $($this.CurrentYear) ===" -ForegroundColor Cyan

        # Step 1: Update macro economy (GDP growth, market condition)
        $this.UpdateGlobalState()

        # Step 2: Random market events (recession, boom, disruption, etc.)
        if ($this.Config.EnableRandomEvents) {
            $this.CheckForRandomEvents()
        }

        # Step 3: Each company observes the macro environment and chooses action.
        # Actions are chosen SIMULTANEOUSLY -- no company sees what others decided.
        # This simulates sealed-bid competition (all decide in ignorance of rivals).
        $actions = @{}
        foreach ($company in $this.Companies) {
            $company.State.EconomyGrowth   = $this.EconomyGrowth
            $company.State.InterestRate    = $this.InterestRate
            $company.State.MarketCondition = $this.MarketCondition
            $company.State.CompetitorCount = $this.Companies.Count - 1

            $action                        = $company.DecideAction()
            $actions[$company.Name]        = $action

            Write-Host "  $($company.Name): $($action.Name)" -ForegroundColor Gray
        }

        # Step 4: Resolve competitive interactions.
        # NOW we can see all actions and compute how companies affect each other.
        # Price competition and market share competition are resolved here.
        $interactions = $this.ResolveInteractions($actions)

        # Step 5: Execute each company's action and simulate the quarter.
        # Interaction effects are applied BEFORE quarter simulation
        # so that competitive advantages affect this quarter's results.
        $results = @{}
        foreach ($company in $this.Companies) {
            $action      = $actions[$company.Name]
            $interaction = $interactions[$company.Name]

            $this.ApplyInteractionEffects($company, $interaction)
            $result = $company.ExecuteAction($action)
            $company.SimulateQuarter()   # Market controls simulation timing

            $results[$company.Name] = $result
        }

        # Step 6: Each company learns from its experience this quarter.
        foreach ($company in $this.Companies) {
            $result = $results[$company.Name]
            $company.Learn($result.Reward)
        }

        # Step 7: Record the quarter's state for later analysis.
        $snapshot = $this.CaptureSnapshot($results)
        $this.History.Add($snapshot) | Out-Null

        # Step 8: Advance time.
        $this.CurrentQuarter++
        if ($this.CurrentQuarter -gt 4) {
            $this.CurrentQuarter = 1
            $this.CurrentYear++
        }

        return $snapshot
    }

    # UPDATE GLOBAL STATE: evolve the macro economy each quarter.
    #
    # Economy cycles slightly each year (random +/-1%).
    # Clamped to [-5%, +10%] to prevent extreme scenarios.
    # Market condition label derived from growth rate:
    #   > 4%  = Bullish  (companies should invest and expand)
    #   < 0%  = Bearish  (companies should conserve cash)
    #   else  = Neutral
    hidden [void] UpdateGlobalState() {
        if ($this.CurrentQuarter % 4 -eq 0) {
            $change             = (Get-Random -Minimum -0.01 -Maximum 0.01)
            $this.EconomyGrowth += $change
            $this.EconomyGrowth  = [Math]::Max(-0.05, [Math]::Min(0.10, $this.EconomyGrowth))
        }

        $this.MarketCondition = if ($this.EconomyGrowth -gt 0.04) { "Bullish" }
                                elseif ($this.EconomyGrowth -lt 0.0) { "Bearish" }
                                else { "Neutral" }

        $this.TotalMarketSize *= (1 + $this.EconomyGrowth / 4)
    }

    # RANDOM EVENTS: inject external shocks.
    #
    # 10% probability each quarter. Five event types:
    #   0: Recession     -- economy contracts (-3%), all companies suffer
    #   1: Boom          -- economy surges (+8%), all companies benefit
    #   2: Tech breakthrough -- one random company gets innovation advantage
    #   3: New regulation -- all companies pay 5% cost increase
    #   4: Consumer shift -- high-quality companies gain satisfaction boost
    #
    # Random events test strategy ROBUSTNESS.
    # An agent that learned only for stable conditions will struggle
    # when a recession hits. Robust agents learn to hedge across scenarios.
    hidden [void] CheckForRandomEvents() {
        $roll = Get-Random -Minimum 0.0 -Maximum 1.0

        if ($roll -lt $this.Config.EventProbability) {
            $eventType = Get-Random -Minimum 0 -Maximum 5

            switch ($eventType) {
                0 {
                    Write-Host "  EVENT: Economic Recession!" -ForegroundColor Red
                    $this.EconomyGrowth   = -0.03
                    $this.MarketCondition = "Bearish"
                }
                1 {
                    Write-Host "  EVENT: Economic Boom!" -ForegroundColor Green
                    $this.EconomyGrowth   = 0.08
                    $this.MarketCondition = "Bullish"
                }
                2 {
                    Write-Host "  EVENT: Technological Breakthrough!" -ForegroundColor Yellow
                    if ($this.Companies.Count -gt 0) {
                        $luckyCompany = $this.Companies[(Get-Random -Minimum 0 -Maximum $this.Companies.Count)]
                        $luckyCompany.State.InnovationScore += 0.2
                        Write-Host "    $($luckyCompany.Name) gains innovation advantage!" -ForegroundColor Yellow
                    }
                }
                3 {
                    Write-Host "  EVENT: New Regulation! (all costs +5%)" -ForegroundColor Magenta
                    foreach ($company in $this.Companies) { $company.State.Costs *= 1.05 }
                }
                4 {
                    Write-Host "  EVENT: Consumer Preferences Shift! (quality rewarded)" -ForegroundColor Cyan
                    foreach ($company in $this.Companies) {
                        if ($company.State.ProductQuality -gt 0.7) {
                            $company.State.CustomerSatisfaction += 0.05
                        }
                    }
                }
            }
        }
    }

    # RESOLVE INTERACTIONS: compute competitive effects between companies.
    #
    # This is where the multi-agent dynamics happen.
    # Companies do not directly observe each other's actions -- but the market
    # resolves the competition and adjusts each company's situation.
    hidden [hashtable] ResolveInteractions([hashtable]$actions) {
        $interactions = @{}
        foreach ($company in $this.Companies) {
            $interactions[$company.Name] = @{
                PriceAdvantage      = 0.0
                MarketShareChange   = 0.0
                CompetitivePressure = 0.0
            }
        }

        if ($this.Config.EnableCompetition) {
            $this.ResolvePriceCompetition($interactions)
        }
        $this.ResolveMarketShareCompetition($interactions)

        return $interactions
    }

    # BERTRAND PRICE COMPETITION:
    # ---------------------------
    # Compute each company's price relative to the market average.
    # Companies priced BELOW average gain PriceAdvantage > 0.
    # Companies priced ABOVE average get PriceAdvantage < 0.
    #
    # Effect is 10% of the price difference -- moderate competitive pressure.
    # In a real Bertrand model, the lowest price captures ALL market share.
    # This smoothed version is more realistic for oligopoly markets.
    hidden [void] ResolvePriceCompetition([hashtable]$interactions) {
        $totalPrice = 0.0; $count = 0
        foreach ($company in $this.Companies) { $totalPrice += $company.State.AveragePrice; $count++ }
        $avgPrice = if ($count -gt 0) { $totalPrice / $count } else { 100.0 }

        foreach ($company in $this.Companies) {
            $priceDiff = ($avgPrice - $company.State.AveragePrice) / $avgPrice
            $interactions[$company.Name].PriceAdvantage = $priceDiff * 0.1
        }
    }

    # MARKET SHARE COMPETITION:
    # -------------------------
    # Companies with higher quality and innovation gradually gain market share.
    # If total market share exceeds 100%, rebalance proportionally.
    # Quality advantage: product quality above 0.5 gains share
    # Innovation advantage: each innovation point adds 1% share per quarter
    hidden [void] ResolveMarketShareCompetition([hashtable]$interactions) {
        $totalShare = 0.0
        foreach ($company in $this.Companies) { $totalShare += $company.State.MarketShare }

        # Rebalance if companies collectively claim more than 100% of market
        if ($totalShare -gt 1.0) {
            foreach ($company in $this.Companies) {
                $company.State.MarketShare = $company.State.MarketShare / $totalShare
            }
        }

        foreach ($company in $this.Companies) {
            $qualityAdvantage    = ($company.State.ProductQuality - 0.5) * 0.02
            $innovationAdvantage = $company.State.InnovationScore * 0.01
            $interactions[$company.Name].MarketShareChange = $qualityAdvantage + $innovationAdvantage
        }
    }

    # APPLY INTERACTION EFFECTS: translate competitive results into state changes.
    hidden [void] ApplyInteractionEffects([CompanyAgent]$company, [hashtable]$interaction) {
        if ($interaction.PriceAdvantage -ne 0) {
            $company.State.CustomerSatisfaction += $interaction.PriceAdvantage * 0.5
            $company.State.CustomerSatisfaction  = [Math]::Max(0.1, [Math]::Min(1.0, $company.State.CustomerSatisfaction))
        }

        if ($interaction.MarketShareChange -ne 0) {
            $company.State.MarketShare += $interaction.MarketShareChange
            $company.State.MarketShare  = [Math]::Max(0.0, [Math]::Min(0.5, $company.State.MarketShare))
        }
    }

    # CAPTURE SNAPSHOT: record the state of all companies this quarter.
    # Stored in History for later analysis and visualisation.
    hidden [hashtable] CaptureSnapshot([hashtable]$results) {
        $snapshot = @{
            Quarter         = $this.CurrentQuarter
            Year            = $this.CurrentYear
            MarketCondition = $this.MarketCondition
            EconomyGrowth   = $this.EconomyGrowth
            Companies       = @{}
        }

        foreach ($company in $this.Companies) {
            $snapshot.Companies[$company.Name] = @{
                Cash                 = $company.State.Cash
                Revenue              = $company.State.Revenue
                Profit               = $company.State.Profit
                MarketShare          = $company.State.MarketShare
                CustomerSatisfaction = $company.State.CustomerSatisfaction
                Action               = $results[$company.Name].Action.Name
                Reward               = $results[$company.Name].Reward
            }
        }

        return $snapshot
    }

    # GET MARKET SUMMARY: current state of the whole market in one hashtable.
    [hashtable] GetMarketSummary() {
        $summary = @{
            Quarter        = $this.CurrentQuarter
            Year           = $this.CurrentYear
            MarketCondition = $this.MarketCondition
            EconomyGrowth  = $this.EconomyGrowth
            TotalCompanies = $this.Companies.Count
            Companies      = @()
        }

        foreach ($company in $this.Companies) {
            $summary.Companies += @{
                Name        = $company.Name
                Cash        = $company.State.Cash
                Profit      = $company.State.Profit
                MarketShare = $company.State.MarketShare
                Revenue     = $company.State.Revenue
            }
        }

        return $summary
    }

    # DISPLAY MARKET STATUS: formatted console output for the annual report.
    [void] DisplayMarketStatus() {
        Write-Host ""
        Write-Host "+------------------------------------------------------+" -ForegroundColor Cyan
        Write-Host "|           MARKET STATUS                              |" -ForegroundColor Cyan
        Write-Host "+------------------------------------------------------+" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  Quarter : Q$($this.CurrentQuarter) Y$($this.CurrentYear)" -ForegroundColor White
        Write-Host "  Economy : $($this.EconomyGrowth.ToString('P2')) growth -- $($this.MarketCondition)" -ForegroundColor Yellow
        Write-Host "  Companies: $($this.Companies.Count)" -ForegroundColor White
        Write-Host ""
        Write-Host "  Rankings by Market Share:" -ForegroundColor Cyan

        $ranked = $this.Companies | Sort-Object { $_.State.MarketShare } -Descending
        $rank   = 1
        foreach ($company in $ranked) {
            $profitColor = if ($company.State.Profit -gt 0) { "Green" } else { "Red" }
            Write-Host "  #$rank " -NoNewline -ForegroundColor Gray
            Write-Host "$($company.Name): " -NoNewline -ForegroundColor White
            Write-Host "$($company.State.MarketShare.ToString('P2')) share, " -NoNewline -ForegroundColor Cyan
            Write-Host "$($company.State.Profit.ToString('N0')) profit" -NoNewline -ForegroundColor $profitColor
            Write-Host ", $($company.State.Cash.ToString('N0')) cash" -ForegroundColor Gray
            $rank++
        }
    }
}
