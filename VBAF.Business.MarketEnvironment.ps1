#Requires -Version 5.1

<#
.SYNOPSIS
    Multi-Agent Market Environment
.DESCRIPTION
    Simulates a competitive market where multiple company agents
    interact, compete, and learn from each other.
.NOTES
    Part of VBAF Phase 2 - Week 6
    Features: Competition, supply/demand, market events, game theory
#>

# Load dependencies
$basePath = $PSScriptRoot

. (Join-Path $basePath "VBAF.Business.CompanyAgent.ps1")

class MarketEnvironment {
    # Market participants
    [System.Collections.ArrayList]$Companies
    
    # Market state
    [int]$CurrentQuarter
    [int]$CurrentYear
    [double]$EconomyGrowth
    [double]$InterestRate
    [string]$MarketCondition
    [double]$TotalMarketSize
    
    # History
    [System.Collections.ArrayList]$History
    
    # Configuration
    [hashtable]$Config
    
    # Constructor
    MarketEnvironment() {
        $this.Companies = New-Object System.Collections.ArrayList
        $this.History = New-Object System.Collections.ArrayList
        $this.CurrentQuarter = 1
        $this.CurrentYear = 1
        $this.EconomyGrowth = 0.02
        $this.InterestRate = 0.05
        $this.MarketCondition = "Neutral"
        $this.TotalMarketSize = 1000000.0
        
        $this.Config = @{
            EnableRandomEvents = $true
            EventProbability = 0.10
            EnableCompetition = $true
            EnableSupplyDemand = $true
        }
    }
    
    # Add company to market
    [void] AddCompany([CompanyAgent]$company) {
        $this.Companies.Add($company) | Out-Null
        
        # Update company's external environment
        $company.State.EconomyGrowth = $this.EconomyGrowth
        $company.State.InterestRate = $this.InterestRate
        $company.State.MarketCondition = $this.MarketCondition
        $company.State.CompetitorCount = $this.Companies.Count - 1
        
        Write-Host "? Added $($company.Name) to market" -ForegroundColor Green
    }
    
    # Simulate one quarter
    [hashtable] SimulateQuarter() {
        Write-Host "`n=== Quarter $($this.CurrentQuarter), Year $($this.CurrentYear) ===" -ForegroundColor Cyan
        
        # 1. Update global state
        $this.UpdateGlobalState()
        
        # 2. Random events (recessions, booms, disruptions)
        if ($this.Config.EnableRandomEvents) {
            $this.CheckForRandomEvents()
        }
        
        # 3. Each company observes and decides
        $actions = @{}
        foreach ($company in $this.Companies) {
            # Update company's view of environment
            $company.State.EconomyGrowth = $this.EconomyGrowth
            $company.State.InterestRate = $this.InterestRate
            $company.State.MarketCondition = $this.MarketCondition
            $company.State.CompetitorCount = $this.Companies.Count - 1
            
            # Company decides action
            $action = $company.DecideAction()
            $actions[$company.Name] = $action
            
            Write-Host "  $($company.Name): $($action.Name)" -ForegroundColor Gray
        }
        
        # 4. Resolve interactions (competition!)
        $interactions = $this.ResolveInteractions($actions)

        # 5. Execute actions and calculate outcomes
        $results = @{}
        foreach ($company in $this.Companies) {
            $action = $actions[$company.Name]
            $interaction = $interactions[$company.Name]
            
            # Apply interaction effects first
            $this.ApplyInteractionEffects($company, $interaction)
            
            # Then execute company's action (without internal simulation)
            $result = $company.ExecuteAction($action)
            
            # NOW simulate the company's quarter (market controls timing)
            $company.SimulateQuarter()
            
            $results[$company.Name] = $result
        }                
      
        # 6. Each company learns
        foreach ($company in $this.Companies) {
            $result = $results[$company.Name]
            $company.Learn($result.Reward)
        }
        
        # 7. Record history
        $snapshot = $this.CaptureSnapshot($results)
        $this.History.Add($snapshot) | Out-Null
        
        # 8. Increment time
        $this.CurrentQuarter++
        if ($this.CurrentQuarter -gt 4) {
            $this.CurrentQuarter = 1
            $this.CurrentYear++
        }
        
        return $snapshot
    }
    
    # Update global economic conditions
    hidden [void] UpdateGlobalState() {
        # Economy cycles
        if ($this.CurrentQuarter % 4 -eq 0) {
            # Slight randomness in economy each year
            $change = (Get-Random -Minimum -0.01 -Maximum 0.01)
            $this.EconomyGrowth += $change
            $this.EconomyGrowth = [Math]::Max(-0.05, [Math]::Min(0.10, $this.EconomyGrowth))
        }
        
        # Market condition based on economy
        if ($this.EconomyGrowth -gt 0.04) {
            $this.MarketCondition = "Bullish"
        } elseif ($this.EconomyGrowth -lt 0.0) {
            $this.MarketCondition = "Bearish"
        } else {
            $this.MarketCondition = "Neutral"
        }
        
        # Total market size grows with economy
        $this.TotalMarketSize *= (1 + $this.EconomyGrowth / 4)
    }
    
    # Check for random market events
    hidden [void] CheckForRandomEvents() {
        $roll = Get-Random -Minimum 0.0 -Maximum 1.0
        
        if ($roll -lt $this.Config.EventProbability) {
            $eventType = Get-Random -Minimum 0 -Maximum 5
            
            switch ($eventType) {
                0 {
                    # Recession
                    Write-Host "  ? EVENT: Economic Recession!" -ForegroundColor Red
                    $this.EconomyGrowth = -0.03
                    $this.MarketCondition = "Bearish"
                }
                1 {
                    # Boom
                    Write-Host "  ? EVENT: Economic Boom!" -ForegroundColor Green
                    $this.EconomyGrowth = 0.08
                    $this.MarketCondition = "Bullish"
                }
                2 {
                    # Tech disruption
                    Write-Host "  ?? EVENT: Technological Breakthrough!" -ForegroundColor Yellow
                    # Random company gets innovation boost
                    if ($this.Companies.Count -gt 0) {
                        $luckyCompany = $this.Companies[(Get-Random -Minimum 0 -Maximum $this.Companies.Count)]
                        $luckyCompany.State.InnovationScore += 0.2
                        Write-Host "     ? $($luckyCompany.Name) gains innovation advantage!" -ForegroundColor Yellow
                    }
                }
                3 {
                    # Regulatory change
                    Write-Host "  ?? EVENT: New Regulation!" -ForegroundColor Magenta
                    foreach ($company in $this.Companies) {
                        $company.State.Costs *= 1.05  # 5% cost increase
                    }
                }
                4 {
                    # Consumer trend shift
                    Write-Host "  ?? EVENT: Consumer Preferences Shift!" -ForegroundColor Cyan
                    # Rewards quality over price
                    foreach ($company in $this.Companies) {
                        if ($company.State.ProductQuality -gt 0.7) {
                            $company.State.CustomerSatisfaction += 0.05
                        }
                    }
                }
            }
        }
    }
    
    # Resolve competitive interactions
    hidden [hashtable] ResolveInteractions([hashtable]$actions) {
        $interactions = @{}
        
        # Initialize interactions for each company
        foreach ($company in $this.Companies) {
            $interactions[$company.Name] = @{
                PriceAdvantage = 0.0
                MarketShareChange = 0.0
                CompetitivePressure = 0.0
            }
        }
        
        # Price competition
        if ($this.Config.EnableCompetition) {
            $this.ResolvePriceCompetition($interactions)
        }
        
        # Market share competition
        $this.ResolveMarketShareCompetition($interactions)
        
        return $interactions
    }
    
    # Price competition (Bertrand model)
    hidden [void] ResolvePriceCompetition([hashtable]$interactions) {
        # Find average price
        $totalPrice = 0.0
        $count = 0
        foreach ($company in $this.Companies) {
            $totalPrice += $company.State.AveragePrice
            $count++
        }
        $avgPrice = if ($count -gt 0) { $totalPrice / $count } else { 100.0 }
        
        # Companies below average gain advantage
        foreach ($company in $this.Companies) {
            $priceDiff = ($avgPrice - $company.State.AveragePrice) / $avgPrice
            $interactions[$company.Name].PriceAdvantage = $priceDiff * 0.1  # 10% effect
        }
    }
    
    # Market share competition
    hidden [void] ResolveMarketShareCompetition([hashtable]$interactions) {
        # Calculate total current market share
        $totalShare = 0.0
        foreach ($company in $this.Companies) {
            $totalShare += $company.State.MarketShare
        }
        
        # If total exceeds 100%, rebalance
        if ($totalShare -gt 1.0) {
            foreach ($company in $this.Companies) {
                $company.State.MarketShare = $company.State.MarketShare / $totalShare
            }
        }
        
        # Companies with higher quality/innovation gain share
        foreach ($company in $this.Companies) {
            $qualityAdvantage = ($company.State.ProductQuality - 0.5) * 0.02
            $innovationAdvantage = $company.State.InnovationScore * 0.01
            
            $interactions[$company.Name].MarketShareChange = $qualityAdvantage + $innovationAdvantage
        }
    }
    
    # Apply interaction effects to company
    hidden [void] ApplyInteractionEffects([CompanyAgent]$company, [hashtable]$interaction) {
        # Price advantage affects revenue
        if ($interaction.PriceAdvantage -ne 0) {
            # This will be reflected in next quarter's revenue
            $company.State.CustomerSatisfaction += $interaction.PriceAdvantage * 0.5
            $company.State.CustomerSatisfaction = [Math]::Max(0.1, [Math]::Min(1.0, $company.State.CustomerSatisfaction))
        }
        
        # Market share changes
        if ($interaction.MarketShareChange -ne 0) {
            $company.State.MarketShare += $interaction.MarketShareChange
            $company.State.MarketShare = [Math]::Max(0.0, [Math]::Min(0.5, $company.State.MarketShare))
        }
    }
    
    # Capture market snapshot
    hidden [hashtable] CaptureSnapshot([hashtable]$results) {
        $snapshot = @{
            Quarter = $this.CurrentQuarter
            Year = $this.CurrentYear
            MarketCondition = $this.MarketCondition
            EconomyGrowth = $this.EconomyGrowth
            Companies = @{}
        }
        
        foreach ($company in $this.Companies) {
            $snapshot.Companies[$company.Name] = @{
                Cash = $company.State.Cash
                Revenue = $company.State.Revenue
                Profit = $company.State.Profit
                MarketShare = $company.State.MarketShare
                CustomerSatisfaction = $company.State.CustomerSatisfaction
                Action = $results[$company.Name].Action.Name
                Reward = $results[$company.Name].Reward
            }
        }
        
        return $snapshot
    }
    
    # Get market summary
    [hashtable] GetMarketSummary() {
        $summary = @{
            Quarter = $this.CurrentQuarter
            Year = $this.CurrentYear
            MarketCondition = $this.MarketCondition
            EconomyGrowth = $this.EconomyGrowth
            TotalCompanies = $this.Companies.Count
            Companies = @()
        }
        
        foreach ($company in $this.Companies) {
            $summary.Companies += @{
                Name = $company.Name
                Cash = $company.State.Cash
                Profit = $company.State.Profit
                MarketShare = $company.State.MarketShare
                Revenue = $company.State.Revenue
            }
        }
        
        return $summary
    }
    
    # Display market status
    [void] DisplayMarketStatus() {
        Write-Host "`n+------------------------------------------------------+" -ForegroundColor Cyan
        Write-Host "¦           MARKET STATUS                             ¦" -ForegroundColor Cyan
        Write-Host "+------------------------------------------------------+" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Quarter: Q$($this.CurrentQuarter) Y$($this.CurrentYear)" -ForegroundColor White
        Write-Host "Economy: $($this.EconomyGrowth.ToString('P2')) growth - $($this.MarketCondition)" -ForegroundColor Yellow
        Write-Host "Companies: $($this.Companies.Count)" -ForegroundColor White
        Write-Host ""
        Write-Host "Rankings by Market Share:" -ForegroundColor Cyan
        
        $ranked = $this.Companies | Sort-Object { $_.State.MarketShare } -Descending
        $rank = 1
        foreach ($company in $ranked) {
            $profitColor = if ($company.State.Profit -gt 0) { "Green" } else { "Red" }
            Write-Host "#$rank " -NoNewline -ForegroundColor Gray
            Write-Host "$($company.Name): " -NoNewline -ForegroundColor White
            Write-Host "$($company.State.MarketShare.ToString('P2')) share, " -NoNewline -ForegroundColor Cyan
            Write-Host "`$($company.State.Profit.ToString('N0')) profit" -NoNewline -ForegroundColor $profitColor
            Write-Host ", `$($company.State.Cash.ToString('N0')) cash" -ForegroundColor Gray
            $rank++
        }
    }
}