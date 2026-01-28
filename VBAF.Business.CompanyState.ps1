#Requires -Version 5.1

<#
.SYNOPSIS
    Company state representation for business simulation
.DESCRIPTION
    Encapsulates all observable state about a company:
    financial metrics, market position, operations, and strategy.
.NOTES
    Part of VBAF Phase 2 - Business Applications
#>

class CompanyState {
    # Financial Metrics
    [double]$Cash
    [double]$Revenue
    [double]$Costs
    [double]$Profit
    [double]$ProfitMargin
    [double]$Debt
    
    # Market Metrics
    [double]$MarketShare
    [double]$CustomerSatisfaction
    [double]$BrandValue
    [int]$CustomerCount
    [double]$AveragePrice
    
    # Operational Metrics
    [int]$EmployeeCount
    [double]$ProductionCapacity
    [double]$CapacityUtilization
    [double]$ProductQuality
    [int]$ProductsSold
    
    # Strategic Metrics
    [double]$RnDInvestment
    [double]$MarketingSpend
    [double]$InnovationScore
    [int]$ProductsInPipeline
    [double]$CompetitivePosition
    
    # External Environment
    [string]$MarketCondition    # "Bullish", "Neutral", "Bearish"
    [double]$EconomyGrowth
    [double]$InterestRate
    [int]$CompetitorCount
    
    # Time
    [int]$Quarter
    [int]$Year
    
    # Constructor - Initialize with defaults
    CompanyState() {
        $this.Cash = 1000000.0
        $this.Revenue = 0.0
        $this.Costs = 0.0
        $this.Profit = 0.0
        $this.ProfitMargin = 0.0
        $this.Debt = 0.0
        
        $this.MarketShare = 0.0
        $this.CustomerSatisfaction = 0.5
        $this.BrandValue = 100.0
        $this.CustomerCount = 0
        $this.AveragePrice = 100.0
        
        $this.EmployeeCount = 10
        $this.ProductionCapacity = 1000.0
        $this.CapacityUtilization = 0.0
        $this.ProductQuality = 0.5
        $this.ProductsSold = 0
        
        $this.RnDInvestment = 0.0
        $this.MarketingSpend = 0.0
        $this.InnovationScore = 0.0
        $this.ProductsInPipeline = 0
        $this.CompetitivePosition = 0.5
        
        $this.MarketCondition = "Neutral"
        $this.EconomyGrowth = 0.02
        $this.InterestRate = 0.05
        $this.CompetitorCount = 3
        
        $this.Quarter = 1
        $this.Year = 1
    }
    
    # Constructor with initial capital
    CompanyState([double]$startingCapital) {
        $this.Cash = $startingCapital
        $this.Revenue = 0.0
        $this.Costs = 0.0
        $this.Profit = 0.0
        $this.ProfitMargin = 0.0
        $this.Debt = 0.0
        
        $this.MarketShare = 0.0
        $this.CustomerSatisfaction = 0.5
        $this.BrandValue = 100.0
        $this.CustomerCount = 0
        $this.AveragePrice = 100.0
        
        $this.EmployeeCount = 10
        $this.ProductionCapacity = 1000.0
        $this.CapacityUtilization = 0.0
        $this.ProductQuality = 0.5
        $this.ProductsSold = 0
        
        $this.RnDInvestment = 0.0
        $this.MarketingSpend = 0.0
        $this.InnovationScore = 0.0
        $this.ProductsInPipeline = 0
        $this.CompetitivePosition = 0.5
        
        $this.MarketCondition = "Neutral"
        $this.EconomyGrowth = 0.02
        $this.InterestRate = 0.05
        $this.CompetitorCount = 3
        
        $this.Quarter = 1
        $this.Year = 1
    }
    
    # Convert state to normalized vector for neural network input
    [double[]] ToVector() {
        return @(
            # Financial (normalized to 0-1 range)
            [Math]::Min($this.Cash / 10000000.0, 1.0),
            [Math]::Min($this.Revenue / 5000000.0, 1.0),
            [Math]::Max([Math]::Min($this.ProfitMargin, 1.0), -1.0),
            [Math]::Min($this.Debt / 5000000.0, 1.0),
            
            # Market
            $this.MarketShare,
            $this.CustomerSatisfaction,
            [Math]::Min($this.BrandValue / 1000.0, 1.0),
            
            # Operational
            [Math]::Min($this.EmployeeCount / 1000.0, 1.0),
            $this.CapacityUtilization,
            $this.ProductQuality,
            
            # Strategic
            $this.InnovationScore,
            $this.CompetitivePosition,
            
            # External
            $(if ($this.MarketCondition -eq "Bullish") { 1.0 } 
              elseif ($this.MarketCondition -eq "Bearish") { 0.0 } 
              else { 0.5 }),
            [Math]::Min($this.EconomyGrowth * 10, 1.0)
        )
    }
    
    # Convert state to string representation for Q-table
    [string] ToStateString() {
        # Discretize continuous values for Q-table
        $cashBucket = if ($this.Cash -lt 500000) { "Low" } 
                      elseif ($this.Cash -lt 2000000) { "Medium" } 
                      else { "High" }
        
        $profitBucket = if ($this.ProfitMargin -lt 0) { "Loss" }
                        elseif ($this.ProfitMargin -lt 0.1) { "LowProfit" }
                        elseif ($this.ProfitMargin -lt 0.3) { "MedProfit" }
                        else { "HighProfit" }
        
        $shareBucket = if ($this.MarketShare -lt 0.1) { "Niche" }
                       elseif ($this.MarketShare -lt 0.3) { "Competitor" }
                       else { "Leader" }
        
        return "Cash:$cashBucket|Profit:$profitBucket|Share:$shareBucket|Market:$($this.MarketCondition)"
    }
    
    # Clone state (for safe copying)
    [CompanyState] Clone() {
        $clone = New-Object CompanyState
        
        # Financial
        $clone.Cash = $this.Cash
        $clone.Revenue = $this.Revenue
        $clone.Costs = $this.Costs
        $clone.Profit = $this.Profit
        $clone.ProfitMargin = $this.ProfitMargin
        $clone.Debt = $this.Debt
        
        # Market
        $clone.MarketShare = $this.MarketShare
        $clone.CustomerSatisfaction = $this.CustomerSatisfaction
        $clone.BrandValue = $this.BrandValue
        $clone.CustomerCount = $this.CustomerCount
        $clone.AveragePrice = $this.AveragePrice
        
        # Operational
        $clone.EmployeeCount = $this.EmployeeCount
        $clone.ProductionCapacity = $this.ProductionCapacity
        $clone.CapacityUtilization = $this.CapacityUtilization
        $clone.ProductQuality = $this.ProductQuality
        $clone.ProductsSold = $this.ProductsSold
        
        # Strategic
        $clone.RnDInvestment = $this.RnDInvestment
        $clone.MarketingSpend = $this.MarketingSpend
        $clone.InnovationScore = $this.InnovationScore
        $clone.ProductsInPipeline = $this.ProductsInPipeline
        $clone.CompetitivePosition = $this.CompetitivePosition
        
        # External
        $clone.MarketCondition = $this.MarketCondition
        $clone.EconomyGrowth = $this.EconomyGrowth
        $clone.InterestRate = $this.InterestRate
        $clone.CompetitorCount = $this.CompetitorCount
        
        # Time
        $clone.Quarter = $this.Quarter
        $clone.Year = $this.Year
        
        return $clone
    }
    
    # Pretty print state
    [string] ToString() {
        $sb = New-Object System.Text.StringBuilder
        
        $sb.AppendLine("=== Company State (Q$($this.Quarter) Y$($this.Year)) ===") | Out-Null
        $sb.AppendLine("Financial:") | Out-Null
        $sb.AppendLine("  Cash: `$$($this.Cash.ToString('N0'))") | Out-Null
        $sb.AppendLine("  Revenue: `$$($this.Revenue.ToString('N0'))") | Out-Null
        $sb.AppendLine("  Profit: `$$($this.Profit.ToString('N0')) ($($this.ProfitMargin.ToString('P1')) margin)") | Out-Null
        $sb.AppendLine("Market:") | Out-Null
        $sb.AppendLine("  Market Share: $($this.MarketShare.ToString('P1'))") | Out-Null
        $sb.AppendLine("  Customers: $($this.CustomerCount)") | Out-Null
        $sb.AppendLine("  Brand Value: `$$($this.BrandValue.ToString('N0'))") | Out-Null
        $sb.AppendLine("Operations:") | Out-Null
        $sb.AppendLine("  Employees: $($this.EmployeeCount)") | Out-Null
        $sb.AppendLine("  Capacity: $($this.CapacityUtilization.ToString('P0'))") | Out-Null
        $sb.AppendLine("  Quality: $($this.ProductQuality.ToString('P0'))") | Out-Null
        $sb.AppendLine("Environment: $($this.MarketCondition)") | Out-Null
        
        return $sb.ToString()
    }
}