#Requires -Version 5.1

<#
.SYNOPSIS
    Four-Company Market Competition Demo
.DESCRIPTION
    Four companies compete, adapt and learn from each other
    in a dynamic market environment over 10 simulated years.

    WHAT YOU ARE LEARNING HERE:
    ============================
    This is MULTI-AGENT reinforcement learning -- the most advanced
    concept in VBAF. Instead of one agent learning in isolation,
    FOUR agents learn simultaneously in a SHARED environment.

    Each company is a QLearningAgent that:
    - Observes its own market position (state)
    - Chooses a business action (price, invest, market, cut costs)
    - Receives a reward based on profit and market share change
    - Updates its Q-table based on what worked

    KEY CONCEPT -- EMERGENT BEHAVIOUR:
    ====================================
    Nobody programs the companies to collude, compete or specialise.
    These behaviours EMERGE from the agents optimising their rewards.

    This is the same phenomenon studied in game theory and economics.
    The difference: these agents learn through experience, not equations.

    WHAT TO WATCH FOR:
    ==================
    Price wars:
      Companies undercut each other on price to gain market share.
      Detected when average price varies widely across companies.
      This hurts everyone -- a classic prisoner's dilemma.

    Tacit collusion:
      Companies independently learn to AVOID price wars.
      They converge on similar prices without communicating.
      Emerges because mutual price cuts reduce everyone's profit.

    Innovation race:
      Companies invest in R&D to gain product advantage.
      Emerges when Q-learning discovers innovation beats price cuts.

    Market segmentation:
      Companies find niches where they dominate.
      Emerges when direct competition becomes too costly.

    THE HERFINDAHL INDEX:
    =====================
    H = sum of (market_share^2) for all companies
    H > 0.25: one company dominates (monopoly tendency)
    H < 0.15: competitive market (evenly distributed)
    Named after economists Herfindahl and Hirschman.
    Used by regulators worldwide to measure market concentration.

    STARTING CONDITIONS:
    ====================
    TechCorp:     1,000,000 capital -- balanced start
    InnovateCo:   1,000,000 capital -- same as TechCorp
    MarketLeader: 1,500,000 capital + 15% market share -- established
    StartupX:       800,000 capital -- underdog, aggressive

    MarketLeader has an advantage at the start.
    Does it maintain dominance Or do the others catch up
    Run it and see -- the outcome varies each time.

.NOTES
    Part of VBAF (Visual AI & Reinforcement Learning Framework)
    Educational use -- the most complex example in VBAF.
    Requires all Business and RL modules (loaded by VBAF.LoadAll.ps1)
#>

$basePath = $PSScriptRoot

Write-Host ""
Write-Host "+--------------------------------------------------------------+" -ForegroundColor Cyan
Write-Host "|                                                              |" -ForegroundColor Cyan
Write-Host "|        VBAF - FOUR COMPANY MARKET COMPETITION               |" -ForegroundColor Cyan
Write-Host "|                                                              |" -ForegroundColor Cyan
Write-Host "|     TechCorp vs InnovateCo vs MarketLeader vs StartupX      |" -ForegroundColor Cyan
Write-Host "|                                                              |" -ForegroundColor Cyan
Write-Host "+--------------------------------------------------------------+" -ForegroundColor Cyan
Write-Host ""

#  LOAD FRAMEWORK 
Write-Host "Loading VBAF Market Framework..." -ForegroundColor Yellow

Write-Host "  [1/5] Loading RL components..." -ForegroundColor Gray
. (Join-Path $basePath "VBAF.RL.QLearningAgent.ps1")
. (Join-Path $basePath "VBAF.RL.ExperienceReplay.ps1")

Write-Host "  [2/5] Loading Business components..." -ForegroundColor Gray
. (Join-Path $basePath "VBAF.Business.CompanyState.ps1")
. (Join-Path $basePath "VBAF.Business.BusinessAction.ps1")

Write-Host "  [3/5] Loading CompanyAgent..." -ForegroundColor Gray
. (Join-Path $basePath "VBAF.Business.CompanyAgent.ps1")

Write-Host "  [4/5] Loading MarketEnvironment..." -ForegroundColor Gray
. (Join-Path $basePath "VBAF.Business.MarketEnvironment.ps1")

Write-Host "  [5/5] Framework loaded!" -ForegroundColor Green
Write-Host ""

#  CREATE MARKET 
# The market environment tracks all companies and simulates
# one quarter at a time -- each company acts, then outcomes are computed.
Write-Host "Creating competitive market environment..." -ForegroundColor Cyan
$market = New-Object MarketEnvironment
Write-Host "  Market created" -ForegroundColor Green
Write-Host ""

#  SPAWN COMPANIES 
# Each company is a QLearningAgent wrapped in a business context.
# They all start with the same technology sector but different
# capital and market positions -- mirroring real competitive markets.
Write-Host "Spawning competitors..." -ForegroundColor Cyan
Write-Host ""

# TechCorp: balanced starting position -- the control group
Write-Host "  Creating TechCorp..." -ForegroundColor Gray
$techCorp = New-Object CompanyAgent -ArgumentList "TechCorp", "Technology", 1000000.0
$market.AddCompany($techCorp)

# InnovateCo: same capital as TechCorp -- will it find a different strategy
Write-Host "  Creating InnovateCo..." -ForegroundColor Gray
$innovateCo = New-Object CompanyAgent -ArgumentList "InnovateCo", "Technology", 1000000.0
$market.AddCompany($innovateCo)

# MarketLeader: starts with MORE capital and existing market share.
# Advantage at t=0. Does early advantage persist or erode
Write-Host "  Creating MarketLeader..." -ForegroundColor Gray
$marketLeader = New-Object CompanyAgent -ArgumentList "MarketLeader", "Technology", 1500000.0
$marketLeader.State.MarketShare = 0.15   # 15% head start
$market.AddCompany($marketLeader)

# StartupX: LESS capital, no market share.
# The underdog. Aggressive Q-learning may compensate.
Write-Host "  Creating StartupX..." -ForegroundColor Gray
$startupX = New-Object CompanyAgent -ArgumentList "StartupX", "Technology", 800000.0
$market.AddCompany($startupX)

Write-Host ""
Write-Host "  All competitors ready!" -ForegroundColor Green
Write-Host ""

#  SIMULATION PARAMETERS 
# 40 quarters = 10 years.
# Each quarter: every company observes state, chooses action, gets reward.
# Q-tables update after every quarter.
$totalQuarters  = 40   # 10 simulated years
$reportInterval = 4    # Print market report every 4 quarters (1 year)

Write-Host "------------------------------------------------------------" -ForegroundColor Cyan
Write-Host " STARTING 10-YEAR MARKET SIMULATION ($totalQuarters quarters)" -ForegroundColor Cyan
Write-Host "------------------------------------------------------------" -ForegroundColor Cyan
Write-Host ""
Write-Host "Watch for emergent behaviours:" -ForegroundColor Yellow
Write-Host "  - Price wars (competing aggressively on price)"      -ForegroundColor Gray
Write-Host "  - Innovation races (R&D investments)"               -ForegroundColor Gray
Write-Host "  - Market segmentation (finding niches)"             -ForegroundColor Gray
Write-Host "  - Tacit collusion (cooperation without communication)" -ForegroundColor Gray
Write-Host ""

#  MAIN SIMULATION LOOP 
$startTime = Get-Date

for ($q = 1; $q -le $totalQuarters; $q++) {
    # Each SimulateQuarter call:
    # 1. Every company observes its current state
    # 2. Every company chooses an action (epsilon-greedy)
    # 3. Market computes outcomes (profit, market share changes)
    # 4. Every company receives its reward and updates Q-table
    $snapshot = $market.SimulateQuarter()

    # Print annual report every 4 quarters
    if ($q % $reportInterval -eq 0) {
        $year = $q / 4

        Write-Host ""
        Write-Host "------------------------------------------------------------" -ForegroundColor Yellow
        Write-Host " YEAR $year COMPLETE - MARKET REPORT" -ForegroundColor Yellow
        Write-Host "------------------------------------------------------------" -ForegroundColor Yellow

        $market.DisplayMarketStatus()

        Write-Host ""
        Write-Host "Year $year Highlights:" -ForegroundColor Cyan

        # Most profitable this year
        $mostProfitable = $market.Companies |
            Sort-Object { $_.State.Profit } -Descending |
            Select-Object -First 1
        Write-Host "  Most Profitable : $($mostProfitable.Name) (`$$($mostProfitable.State.Profit.ToString('N0')))" -ForegroundColor Green

        # Current market leader by share
        $leader = $market.Companies |
            Sort-Object { $_.State.MarketShare } -Descending |
            Select-Object -First 1
        Write-Host "  Market Leader   : $($leader.Name) ($($leader.State.MarketShare.ToString('P2')) share)" -ForegroundColor Cyan

        # Best learner by cumulative reward
        $bestLearner = $market.Companies |
            Sort-Object { $_.TotalReward } -Descending |
            Select-Object -First 1
        Write-Host "  Best Learner    : $($bestLearner.Name) (reward: $($bestLearner.TotalReward.ToString('F0')))" -ForegroundColor Magenta

        Write-Host ""
    }
}

$endTime  = Get-Date
$duration = ($endTime - $startTime).TotalSeconds

#  FINAL RESULTS 
Write-Host ""
Write-Host "+--------------------------------------------------------------+" -ForegroundColor Green
Write-Host "|                 SIMULATION COMPLETE!                        |" -ForegroundColor Green
Write-Host "+--------------------------------------------------------------+" -ForegroundColor Green
Write-Host "  Completed in $($duration.ToString('F1')) seconds" -ForegroundColor Gray
Write-Host ""

Write-Host "------------------------------------------------------------" -ForegroundColor Cyan
Write-Host " FINAL RANKINGS - 10 YEAR RESULTS" -ForegroundColor Cyan
Write-Host "------------------------------------------------------------" -ForegroundColor Cyan
Write-Host ""

# Rankings by market share
Write-Host "BY MARKET SHARE:" -ForegroundColor Yellow
$ranked = $market.Companies | Sort-Object { $_.State.MarketShare } -Descending
$rank = 1
foreach ($company in $ranked) {
    $medal = switch ($rank) { 1 { "#1" } 2 { "#2" } 3 { "#3" } default { "#4" } }
    Write-Host "  $medal $($company.Name): $($company.State.MarketShare.ToString('P2'))" -ForegroundColor White
    $rank++
}

Write-Host ""

# Rankings by profitability
Write-Host "BY PROFITABILITY:" -ForegroundColor Yellow
$ranked = $market.Companies | Sort-Object { $_.State.Profit } -Descending
$rank = 1
foreach ($company in $ranked) {
    $medal      = switch ($rank) { 1 { "#1" } 2 { "#2" } 3 { "#3" } default { "#4" } }
    $profitColor = if ($company.State.Profit -gt 0) { "Green" } else { "Red" }
    Write-Host "  $medal $($company.Name): `$$($company.State.Profit.ToString('N0'))" -ForegroundColor $profitColor
    $rank++
}

Write-Host ""

# Rankings by cash (total wealth)
Write-Host "BY TOTAL WEALTH (CASH):" -ForegroundColor Yellow
$ranked = $market.Companies | Sort-Object { $_.State.Cash } -Descending
$rank = 1
foreach ($company in $ranked) {
    $medal     = switch ($rank) { 1 { "#1" } 2 { "#2" } 3 { "#3" } default { "#4" } }
    $cashColor  = if ($company.State.Cash -gt 0) { "Green" } else { "Red" }
    Write-Host "  $medal $($company.Name): `$$($company.State.Cash.ToString('N0'))" -ForegroundColor $cashColor
    $rank++
}

Write-Host ""

#  EMERGENT BEHAVIOUR ANALYSIS 
Write-Host "------------------------------------------------------------" -ForegroundColor Cyan
Write-Host " EMERGENT BEHAVIOUR ANALYSIS" -ForegroundColor Cyan
Write-Host "------------------------------------------------------------" -ForegroundColor Cyan
Write-Host ""

# Price war detection: high price variation = active price competition
$avgPrice      = ($market.Companies | ForEach-Object { $_.State.AveragePrice } | Measure-Object -Average).Average
$priceVariation = ($market.Companies | ForEach-Object { [Math]::Abs($_.State.AveragePrice - $avgPrice) } | Measure-Object -Average).Average

if ($priceVariation -gt 50) {
    Write-Host "  PRICE WAR DETECTED" -ForegroundColor Red
    Write-Host "  Companies competed aggressively on pricing." -ForegroundColor Gray
    Write-Host "  This reduces profit for all -- a classic race to the bottom." -ForegroundColor DarkGray
} else {
    Write-Host "  TACIT COLLUSION DETECTED" -ForegroundColor Green
    Write-Host "  Companies learned to avoid destructive price competition." -ForegroundColor Gray
    Write-Host "  Prices converged without any explicit communication -- Q-learning found it." -ForegroundColor DarkGray
}

Write-Host ""

# Innovation race detection
$totalInnovation = ($market.Companies | ForEach-Object { $_.State.InnovationScore } | Measure-Object -Sum).Sum
if ($totalInnovation -gt 0.5) {
    Write-Host "  INNOVATION RACE DETECTED" -ForegroundColor Cyan
    Write-Host "  Companies discovered R&D investment beats price cuts." -ForegroundColor Gray
} else {
    Write-Host "  LOW INNOVATION" -ForegroundColor Yellow
    Write-Host "  Companies focused on cost efficiency over R&D." -ForegroundColor Gray
}

Write-Host ""

# Herfindahl Index -- market concentration measure
$herfindahl = ($market.Companies | ForEach-Object { [Math]::Pow($_.State.MarketShare, 2) } | Measure-Object -Sum).Sum
Write-Host "  Herfindahl Index: $($herfindahl.ToString('F3'))" -ForegroundColor DarkGray
if ($herfindahl -gt 0.25) {
    Write-Host "  MARKET CONSOLIDATION -- one company dominates (H > 0.25)" -ForegroundColor Magenta
    Write-Host "  In reality, regulators would investigate at this level." -ForegroundColor DarkGray
} else {
    Write-Host "  BALANCED COMPETITION -- market share distributed evenly (H < 0.25)" -ForegroundColor Green
}

Write-Host ""

# Learning convergence -- has epsilon reached minimum
$avgEpsilon = ($market.Companies | ForEach-Object { $_.Brain.Epsilon } | Measure-Object -Average).Average
if ($avgEpsilon -lt 0.15) {
    Write-Host "  STRATEGIES CONVERGED -- all agents found stable strategies (epsilon < 0.15)" -ForegroundColor Green
} else {
    Write-Host "  STILL LEARNING -- agents still exploring (epsilon = $($avgEpsilon.ToString('F3')))" -ForegroundColor Yellow
    Write-Host "  Run for 100+ quarters to see full convergence." -ForegroundColor DarkGray
}

Write-Host ""

#  KEY INSIGHTS 
Write-Host "------------------------------------------------------------" -ForegroundColor Cyan
Write-Host " KEY INSIGHTS" -ForegroundColor Cyan
Write-Host "------------------------------------------------------------" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Multi-agent reinforcement learning works." -ForegroundColor Green
Write-Host "  Companies learned to compete and adapt without being told how." -ForegroundColor Green
Write-Host "  Emergent behaviours (collusion, price wars, innovation) appeared naturally." -ForegroundColor Green
Write-Host "  Nobody programmed competition -- it emerged from reward optimisation." -ForegroundColor Green
Write-Host ""
Write-Host "  This is the same mechanism studied in:" -ForegroundColor DarkGray
Write-Host "  - Game theory (Nash equilibrium, prisoner's dilemma)" -ForegroundColor DarkGray
Write-Host "  - Economics (oligopoly behaviour, Cournot competition)" -ForegroundColor DarkGray
Write-Host "  - Biology (evolutionary game theory)" -ForegroundColor DarkGray
Write-Host ""
Write-Host "What to try next:" -ForegroundColor Yellow
Write-Host "  1. Run for 100+ quarters -- watch strategies fully converge" -ForegroundColor Gray
Write-Host "  2. Change StartupX capital to 2,000,000 -- does the underdog win" -ForegroundColor Gray
Write-Host "  3. Give all companies the same starting position -- pure skill test" -ForegroundColor Gray
Write-Host "  4. Move on to: VBAF.Visualization.LearningDashboard.ps1" -ForegroundColor Gray
Write-Host ""