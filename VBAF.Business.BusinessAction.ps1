#Requires -Version 5.1

<#
.SYNOPSIS
    Business action definitions for company agents
.DESCRIPTION
    Defines the action space for company decision-making:
    pricing, investment, operational, and strategic actions.
.NOTES
    Part of VBAF Phase 2 - Business Applications
#>

class BusinessAction {
    [string]$Type           # "Pricing", "Investment", "Operational", "Strategic"
    [string]$Name           # Descriptive name
    [hashtable]$Parameters  # Action-specific parameters
    
    # Constructor
    BusinessAction([string]$type, [string]$name, [hashtable]$parameters) {
        $this.Type = $type
        $this.Name = $name
        $this.Parameters = $parameters
    }
    
    # Convert to string for Q-table key
    [string] ToString() {
        return "$($this.Type):$($this.Name)"
    }
    
    # Static factory methods for common actions
    
    # Pricing Actions
    static [BusinessAction] SetPricePremium() {
        return New-Object BusinessAction -ArgumentList "Pricing", "Premium", @{
            PriceMultiplier = 1.3
            ExpectedVolume = 0.7
        }
    }
    
    static [BusinessAction] SetPriceCompetitive() {
        return New-Object BusinessAction -ArgumentList "Pricing", "Competitive", @{
            PriceMultiplier = 1.0
            ExpectedVolume = 1.0
        }
    }
    
    static [BusinessAction] SetPricePenetration() {
        return New-Object BusinessAction -ArgumentList "Pricing", "Penetration", @{
            PriceMultiplier = 0.8
            ExpectedVolume = 1.4
        }
    }
    
    static [BusinessAction] SetPriceDynamic() {
        return New-Object BusinessAction -ArgumentList "Pricing", "Dynamic", @{
            PriceMultiplier = 1.1
            ExpectedVolume = 1.1
        }
    }
    
    # Investment Actions
    static [BusinessAction] InvestRnDLow() {
        return New-Object BusinessAction -ArgumentList "Investment", "RnD_Low", @{
            Amount = 50000
            InnovationBoost = 0.05
        }
    }
    
    static [BusinessAction] InvestRnDMedium() {
        return New-Object BusinessAction -ArgumentList "Investment", "RnD_Medium", @{
            Amount = 150000
            InnovationBoost = 0.15
        }
    }
    
    static [BusinessAction] InvestRnDHigh() {
        return New-Object BusinessAction -ArgumentList "Investment", "RnD_High", @{
            Amount = 300000
            InnovationBoost = 0.30
        }
    }
    
    static [BusinessAction] InvestMarketingLow() {
        return New-Object BusinessAction -ArgumentList "Investment", "Marketing_Low", @{
            Amount = 30000
            BrandBoost = 0.03
            CustomerBoost = 0.05
        }
    }
    
    static [BusinessAction] InvestMarketingMedium() {
        return New-Object BusinessAction -ArgumentList "Investment", "Marketing_Medium", @{
            Amount = 100000
            BrandBoost = 0.08
            CustomerBoost = 0.12
        }
    }
    
    static [BusinessAction] InvestMarketingHigh() {
        return New-Object BusinessAction -ArgumentList "Investment", "Marketing_High", @{
            Amount = 250000
            BrandBoost = 0.15
            CustomerBoost = 0.20
        }
    }
    
    static [BusinessAction] InvestCapExLow() {
        return New-Object BusinessAction -ArgumentList "Investment", "CapEx_Low", @{
            Amount = 100000
            CapacityIncrease = 0.10
        }
    }
    
    static [BusinessAction] InvestCapExHigh() {
        return New-Object BusinessAction -ArgumentList "Investment", "CapEx_High", @{
            Amount = 500000
            CapacityIncrease = 0.50
        }
    }
    
    # Operational Actions
    static [BusinessAction] HireEmployees([int]$count) {
        return New-Object BusinessAction -ArgumentList "Operational", "Hire_$count", @{
            Count = $count
            Cost = $count * 50000  # $50k per employee per year
        }
    }
    
    static [BusinessAction] LayoffEmployees([int]$count) {
        return New-Object BusinessAction -ArgumentList "Operational", "Layoff_$count", @{
            Count = $count
            SeveranceCost = $count * 25000
            ProductivityImpact = -0.1
        }
    }
    
    static [BusinessAction] ImproveQuality() {
        return New-Object BusinessAction -ArgumentList "Operational", "Quality_Improve", @{
            Cost = 80000
            QualityIncrease = 0.10
            TimeMonths = 2
        }
    }
    
    static [BusinessAction] ReduceCosts() {
        return New-Object BusinessAction -ArgumentList "Operational", "Cost_Reduction", @{
            CostSavings = 0.10
            QualityImpact = -0.05
        }
    }
    
    # Strategic Actions
    static [BusinessAction] ExpandMarket() {
        return New-Object BusinessAction -ArgumentList "Strategic", "Market_Expand", @{
            Cost = 200000
            NewCustomerPotential = 0.20
            RiskLevel = 0.3
        }
    }
    
    static [BusinessAction] FormPartnership() {
        return New-Object BusinessAction -ArgumentList "Strategic", "Partnership", @{
            Cost = 50000
            MarketShareBoost = 0.05
            InnovationBoost = 0.10
        }
    }
    
    static [BusinessAction] LaunchProduct() {
        return New-Object BusinessAction -ArgumentList "Strategic", "Product_Launch", @{
            Cost = 150000
            SuccessProbability = 0.6
            RevenueBoost = 0.25
        }
    }
    
    static [BusinessAction] DoNothing() {
        return New-Object BusinessAction -ArgumentList "Strategic", "Hold_Position", @{
            Cost = 0
        }
    }
    
    # Get all available actions (for agent action space)
    static [BusinessAction[]] GetAllActions() {
        return @(
            # Pricing (4 options)
            [BusinessAction]::SetPricePremium(),
            [BusinessAction]::SetPriceCompetitive(),
            [BusinessAction]::SetPricePenetration(),
            [BusinessAction]::SetPriceDynamic(),
            
            # Investment (8 options)
            [BusinessAction]::InvestRnDLow(),
            [BusinessAction]::InvestRnDMedium(),
            [BusinessAction]::InvestRnDHigh(),
            [BusinessAction]::InvestMarketingLow(),
            [BusinessAction]::InvestMarketingMedium(),
            [BusinessAction]::InvestMarketingHigh(),
            [BusinessAction]::InvestCapExLow(),
            [BusinessAction]::InvestCapExHigh(),
            
            # Operational (4 options)
            [BusinessAction]::HireEmployees(5),
            [BusinessAction]::LayoffEmployees(3),
            [BusinessAction]::ImproveQuality(),
            [BusinessAction]::ReduceCosts(),
            
            # Strategic (4 options)
            [BusinessAction]::ExpandMarket(),
            [BusinessAction]::FormPartnership(),
            [BusinessAction]::LaunchProduct(),
            [BusinessAction]::DoNothing()
        )
    }
    
    # Get action names for Q-Learning
    static [string[]] GetActionNames() {
        $actions = [BusinessAction]::GetAllActions()
        return $actions | ForEach-Object { $_.ToString() }
    }
    
    # Get specific action categories
    static [BusinessAction[]] GetPricingActions() {
        return @(
            [BusinessAction]::SetPricePremium(),
            [BusinessAction]::SetPriceCompetitive(),
            [BusinessAction]::SetPricePenetration(),
            [BusinessAction]::SetPriceDynamic()
        )
    }
    
    static [BusinessAction[]] GetInvestmentActions() {
        return @(
            [BusinessAction]::InvestRnDLow(),
            [BusinessAction]::InvestRnDMedium(),
            [BusinessAction]::InvestRnDHigh(),
            [BusinessAction]::InvestMarketingLow(),
            [BusinessAction]::InvestMarketingMedium(),
            [BusinessAction]::InvestMarketingHigh(),
            [BusinessAction]::InvestCapExLow(),
            [BusinessAction]::InvestCapExHigh()
        )
    }
    
    static [BusinessAction[]] GetOperationalActions() {
        return @(
            [BusinessAction]::HireEmployees(5),
            [BusinessAction]::LayoffEmployees(3),
            [BusinessAction]::ImproveQuality(),
            [BusinessAction]::ReduceCosts()
        )
    }
    
    static [BusinessAction[]] GetStrategicActions() {
        return @(
            [BusinessAction]::ExpandMarket(),
            [BusinessAction]::FormPartnership(),
            [BusinessAction]::LaunchProduct(),
            [BusinessAction]::DoNothing()
        )
    }
}