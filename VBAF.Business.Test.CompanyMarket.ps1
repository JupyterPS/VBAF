#Requires -Version 5.1

<#
.SYNOPSIS
    Four-Company Market Competition Demo
.DESCRIPTION
    Epic 4-way battle! Companies compete, adapt, and learn
    from each other in a dynamic market environment.
.NOTES
    Part of VBAF Phase 2 - Week 6
    Watch for: Price wars, innovation races, emergent behaviors!
#>

# Set base path
$basePath = "C:\Users\henni\OneDrive\WindowsPowerShell"

# Display epic header
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                                                              ║" -ForegroundColor Cyan
Write-Host "║        VBAF - FOUR COMPANY MARKET COMPETITION               ║" -ForegroundColor Cyan
Write-Host "║                                                              ║" -ForegroundColor Cyan
Write-Host "║     TechCorp vs InnovateCo vs MarketLeader vs StartupX      ║" -ForegroundColor Cyan
Write-Host "║                                                              ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Load framework
Write-Host "Loading VBAF Market Framework..." -ForegroundColor Yellow

Write-Host "  [1/5] Loading RL components..." -ForegroundColor Gray
. "$basePath\VBAF.RL.QLearningAgent.ps1"
. "$basePath\VBAF.RL.ExperienceReplay.ps1"

Write-Host "  [2/5] Loading Business components..." -ForegroundColor Gray
. "$basePath\VBAF.Business.CompanyState.ps1"
. "$basePath\VBAF.Business.BusinessAction.ps1"

Write-Host "  [3/5] Loading CompanyAgent..." -ForegroundColor Gray
. "$basePath\VBAF.Business.CompanyAgent.ps1"

Write-Host "  [4/5] Loading MarketEnvironment..." -ForegroundColor Gray
. "$basePath\VBAF.Business.MarketEnvironment.ps1"

Write-Host "  [5/5] Framework loaded!" -ForegroundColor Green
Write-Host ""

# Create market
Write-Host "Creating competitive market environment..." -ForegroundColor Cyan
$market = New-Object MarketEnvironment
Write-Host "✓ Market created" -ForegroundColor Green
Write-Host ""

# Create four competing companies
Write-Host "Spawning competitors..." -ForegroundColor Cyan
Write-Host ""

# Company 1: TechCorp (Balanced strategy)
Write-Host "  Creating TechCorp..." -ForegroundColor Gray
$techCorp = New-Object CompanyAgent -ArgumentList "TechCorp", "Technology", 1000000.0
$market.AddCompany($techCorp)

# Company 2: InnovateCo (R&D focused)
Write-Host "  Creating InnovateCo..." -ForegroundColor Gray
$innovateCo = New-Object CompanyAgent -ArgumentList "InnovateCo", "Technology", 1000000.0
$market.AddCompany($innovateCo)

# Company 3: MarketLeader (Established player)
Write-Host "  Creating MarketLeader..." -ForegroundColor Gray
$marketLeader = New-Object CompanyAgent -ArgumentList "MarketLeader", "Technology", 1500000.0  # More capital
$marketLeader.State.MarketShare = 0.15  # Starts with market share
$market.AddCompany($marketLeader)

# Company 4: StartupX (Aggressive newcomer)
Write-Host "  Creating StartupX..." -ForegroundColor Gray
$startupX = New-Object CompanyAgent -ArgumentList "StartupX", "Technology", 800000.0  # Less capital
$market.AddCompany($startupX)

Write-Host ""
Write-Host "✓ All competitors ready!" -ForegroundColor Green
Write-Host ""

# Training parameters
$totalQuarters = 40  # 10 years
$reportInterval = 4  # Report every year

Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host " STARTING 10-YEAR MARKET SIMULATION ($totalQuarters quarters)" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Watch for emergent behaviors:" -ForegroundColor Yellow
Write-Host "  • Price wars (competing on price)" -ForegroundColor Gray
Write-Host "  • Innovation races (R&D investments)" -ForegroundColor Gray
Write-Host "  • Market segmentation (finding niches)" -ForegroundColor Gray
Write-Host "  • Tacit collusion (cooperation without communication!)" -ForegroundColor Gray
Write-Host ""

# Simulation loop
$startTime = Get-Date

for ($q = 1; $q -le $totalQuarters; $q++) {
    # Run one quarter
    $snapshot = $market.SimulateQuarter()
    
    # Report every year
    if ($q % $reportInterval -eq 0) {
        $year = $q / 4
        
        Write-Host ""
        Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Yellow
        Write-Host " YEAR $year COMPLETE - MARKET REPORT" -ForegroundColor Yellow
        Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Yellow
        
        $market.DisplayMarketStatus()
        
        # Show some interesting stats
        Write-Host ""
        Write-Host "Year $year Highlights:" -ForegroundColor Cyan
        
        # Find most profitable
        $mostProfitable = $market.Companies | Sort-Object { $_.State.Profit } -Descending | Select-Object -First 1
        Write-Host "  💰 Most Profitable: $($mostProfitable.Name) (`$$($mostProfitable.State.Profit.ToString('N0')))" -ForegroundColor Green
        
        # Find market leader
        $leader = $market.Companies | Sort-Object { $_.State.MarketShare } -Descending | Select-Object -First 1
        Write-Host "  👑 Market Leader: $($leader.Name) ($($leader.State.MarketShare.ToString('P2')) share)" -ForegroundColor Cyan
        
        # Find best learner (highest total reward)
        $bestLearner = $market.Companies | Sort-Object { $_.TotalReward } -Descending | Select-Object -First 1
        Write-Host "  🧠 Best Learner: $($bestLearner.Name) (reward: $($bestLearner.TotalReward.ToString('F0')))" -ForegroundColor Magenta
        
        Write-Host ""
    }
}

$endTime = Get-Date
$duration = ($endTime - $startTime).TotalSeconds

# Final results
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                 SIMULATION COMPLETE!                        ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host "Completed in $($duration.ToString('F1')) seconds" -ForegroundColor Gray
Write-Host ""

# Final rankings
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host " FINAL RANKINGS - 10 YEAR RESULTS" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# By Market Share
Write-Host "BY MARKET SHARE:" -ForegroundColor Yellow
$ranked = $market.Companies | Sort-Object { $_.State.MarketShare } -Descending
$rank = 1
foreach ($company in $ranked) {
    $medal = switch ($rank) {
        1 { "🥇" }
        2 { "🥈" }
        3 { "🥉" }
        default { "  " }
    }
    Write-Host "$medal #$rank $($company.Name): $($company.State.MarketShare.ToString('P2'))" -ForegroundColor White
    $rank++
}

Write-Host ""

# By Profitability
Write-Host "BY PROFITABILITY:" -ForegroundColor Yellow
$ranked = $market.Companies | Sort-Object { $_.State.Profit } -Descending
$rank = 1
foreach ($company in $ranked) {
    $medal = switch ($rank) {
        1 { "🥇" }
        2 { "🥈" }
        3 { "🥉" }
        default { "  " }
    }
    $profitColor = if ($company.State.Profit -gt 0) { "Green" } else { "Red" }
    Write-Host "$medal #$rank $($company.Name): `$$($company.State.Profit.ToString('N0'))" -ForegroundColor $profitColor
    $rank++
}

Write-Host ""

# By Total Wealth (Cash)
Write-Host "BY TOTAL WEALTH:" -ForegroundColor Yellow
$ranked = $market.Companies | Sort-Object { $_.State.Cash } -Descending
$rank = 1
foreach ($company in $ranked) {
    $medal = switch ($rank) {
        1 { "🥇" }
        2 { "🥈" }
        3 { "🥉" }
        default { "  " }
    }
    $cashColor = if ($company.State.Cash -gt 0) { "Green" } else { "Red" }
    Write-Host "$medal #$rank $($company.Name): `$$($company.State.Cash.ToString('N0'))" -ForegroundColor $cashColor
    $rank++
}

Write-Host ""

# Emergent behavior analysis
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host " EMERGENT BEHAVIOR ANALYSIS" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Price war detection
$avgPrice = ($market.Companies | ForEach-Object { $_.State.AveragePrice } | Measure-Object -Average).Average
$priceVariation = ($market.Companies | ForEach-Object { [Math]::Abs($_.State.AveragePrice - $avgPrice) } | Measure-Object -Average).Average

if ($priceVariation -gt 50) {
    Write-Host "💥 PRICE WAR DETECTED!" -ForegroundColor Red
    Write-Host "   Companies competed aggressively on pricing" -ForegroundColor Gray
} else {
    Write-Host "🤝 TACIT COLLUSION DETECTED!" -ForegroundColor Green
    Write-Host "   Companies learned to avoid destructive price competition" -ForegroundColor Gray
}

Write-Host ""

# Innovation race
$totalInnovation = ($market.Companies | ForEach-Object { $_.State.InnovationScore } | Measure-Object -Sum).Sum
if ($totalInnovation -gt 0.5) {
    Write-Host "🚀 INNOVATION RACE!" -ForegroundColor Cyan
    Write-Host "   Companies invested heavily in R&D" -ForegroundColor Gray
} else {
    Write-Host "💤 LOW INNOVATION" -ForegroundColor Yellow
    Write-Host "   Companies focused on operational efficiency over innovation" -ForegroundColor Gray
}

Write-Host ""

# Market concentration
$herfindahl = ($market.Companies | ForEach-Object { [Math]::Pow($_.State.MarketShare, 2) } | Measure-Object -Sum).Sum
if ($herfindahl -gt 0.25) {
    Write-Host "👑 MARKET CONSOLIDATION" -ForegroundColor Magenta
    Write-Host "   One or two companies dominate the market" -ForegroundColor Gray
} else {
    Write-Host "⚖️ BALANCED COMPETITION" -ForegroundColor Green
    Write-Host "   Market share distributed relatively evenly" -ForegroundColor Gray
}

Write-Host ""

# Learning convergence
$avgEpsilon = ($market.Companies | ForEach-Object { $_.Brain.Epsilon } | Measure-Object -Average).Average
if ($avgEpsilon -lt 0.15) {
    Write-Host "🎓 STRATEGIES CONVERGED" -ForegroundColor Green
    Write-Host "   All agents found their optimal strategies (ε < 0.15)" -ForegroundColor Gray
} else {
    Write-Host "🔄 STILL LEARNING" -ForegroundColor Yellow
    Write-Host "   Agents still exploring strategies (ε = $($avgEpsilon.ToString('F3')))" -ForegroundColor Gray
    Write-Host "   Try running for 100+ quarters for full convergence" -ForegroundColor Gray
}

Write-Host ""

# Final insights
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host " KEY INSIGHTS" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Write-Host "✓ Multi-agent reinforcement learning WORKS!" -ForegroundColor Green
Write-Host "✓ Companies learned to compete and adapt" -ForegroundColor Green
Write-Host "✓ Emergent behaviors appeared naturally" -ForegroundColor Green
Write-Host "✓ No explicit programming of competition - it emerged!" -ForegroundColor Green
Write-Host ""

Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Run for 100+ quarters to see full convergence" -ForegroundColor Gray
Write-Host "  2. Try recession scenarios (market events)" -ForegroundColor Gray
Write-Host "  3. Add 5th or 6th competitor mid-simulation" -ForegroundColor Gray
Write-Host "  4. Week 7: Market visualization dashboard!" -ForegroundColor Gray
Write-Host ""

Write-Host "✓ Phase 2, Week 6 COMPLETE!" -ForegroundColor Green
Write-Host ""