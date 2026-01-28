#Requires -Version 5.1

<#
.SYNOPSIS
    Single Company Learning Demo
.DESCRIPTION
    Demonstrates a company agent learning optimal business strategy
    through reinforcement learning over multiple quarters.
.NOTES
    Part of VBAF Phase 2 - Week 5 Example
    FIXED: Proper loading order to avoid class dependency issues
#>

# Set base path
$basePath = "C:\Users\henni\OneDrive\WindowsPowerShell"

# Display header first
Write-Host "`n╔══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   VBAF - Company Agent Learning Demo               ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# CRITICAL: Load in correct order - dependencies first!
Write-Host "Loading VBAF Business Framework..." -ForegroundColor Cyan

# 1. Load RL framework first (CompanyAgent needs these)
Write-Host "  [1/4] Loading RL components..." -ForegroundColor Gray
. "$basePath\VBAF.RL.QLearningAgent.ps1"
. "$basePath\VBAF.RL.ExperienceReplay.ps1"

# 2. Load Business state & actions (CompanyAgent needs these too)
Write-Host "  [2/4] Loading Business state..." -ForegroundColor Gray
. "$basePath\VBAF.Business.CompanyState.ps1"

Write-Host "  [3/4] Loading Business actions..." -ForegroundColor Gray
. "$basePath\VBAF.Business.BusinessAction.ps1"

# 3. Finally load CompanyAgent (depends on all above)
Write-Host "  [4/4] Loading CompanyAgent..." -ForegroundColor Gray
. "$basePath\VBAF.Business.CompanyAgent.ps1"

Write-Host "✓ Framework loaded successfully" -ForegroundColor Green
Write-Host ""

Write-Host "This demo shows a company learning optimal business" -ForegroundColor Yellow
Write-Host "strategies through reinforcement learning." -ForegroundColor Yellow
Write-Host ""

# Create company agent
Write-Host "Creating company agent..." -ForegroundColor Cyan
$company = New-Object CompanyAgent -ArgumentList "TechCorp", "Technology", 1000000.0

Write-Host "✓ Created: $($company.Name)" -ForegroundColor Green
Write-Host "  Industry: $($company.Industry)" -ForegroundColor Gray
Write-Host "  Starting Capital: `$$($company.State.Cash.ToString('N0'))" -ForegroundColor Gray
Write-Host "  Available Actions: $($company.AvailableActions.Count)" -ForegroundColor Gray
Write-Host ""

# Display initial state
$company.DisplayState()

# Training parameters
$totalQuarters = 40  # 10 years
$reportInterval = 4  # Report every year

Write-Host "`nStarting training for $totalQuarters quarters (10 years)..." -ForegroundColor Cyan
Write-Host "(This will take ~30 seconds)" -ForegroundColor Gray
Write-Host ""

# Training loop
$startTime = Get-Date

for ($q = 1; $q -le $totalQuarters; $q++) {
    # Run one quarter
    $results = $company.RunEpisode()
    
    # Report progress every year
    if ($q % $reportInterval -eq 0) {
        $year = $q / 4
        
        Write-Host "`n--- Year $year Complete ---" -ForegroundColor Yellow
        Write-Host "Last Action: $($results.Action.Name)" -ForegroundColor Gray
        Write-Host "Result: $($results.Results.Message)" -ForegroundColor Gray
        Write-Host "Reward: $($results.Reward.ToString('F2'))" -ForegroundColor $(if ($results.Reward -gt 0) { "Green" } else { "Red" })
        Write-Host ""
        Write-Host "Company Status:" -ForegroundColor Cyan
        Write-Host "  Cash: `$$($company.State.Cash.ToString('N0'))"
        Write-Host "  Revenue: `$$($company.State.Revenue.ToString('N0'))"
        Write-Host "  Profit: `$$($company.State.Profit.ToString('N0')) ($($company.State.ProfitMargin.ToString('P1')) margin)"
        Write-Host "  Market Share: $($company.State.MarketShare.ToString('P2'))"
        Write-Host "  Customers: $($company.State.CustomerCount)"
        Write-Host "  Satisfaction: $($company.State.CustomerSatisfaction.ToString('P0'))"
        Write-Host "  Employees: $($company.State.EmployeeCount)"
        Write-Host ""
        Write-Host "Learning Progress:" -ForegroundColor Cyan
        Write-Host "  Total Reward: $($company.TotalReward.ToString('F2'))"
        Write-Host "  Exploration (ε): $($company.Brain.Epsilon.ToString('F3'))"
    }
}

$endTime = Get-Date
$duration = ($endTime - $startTime).TotalSeconds

# Training complete
Write-Host "`n╔══════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   TRAINING COMPLETE!                                ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host "Completed in $($duration.ToString('F1')) seconds" -ForegroundColor Gray
Write-Host ""

# Final performance summary
$summary = $company.GetPerformanceSummary()

Write-Host "=== FINAL PERFORMANCE SUMMARY ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Company: $($summary.Company)" -ForegroundColor White
Write-Host "Episodes Completed: $($summary.Episodes)" -ForegroundColor White
Write-Host ""
Write-Host "Financial Performance:" -ForegroundColor Yellow
Write-Host "  Final Cash: `$$($summary.Cash.ToString('N0'))"
Write-Host "  Final Profit: `$$($summary.CurrentProfit.ToString('N0'))"
Write-Host "  Average Profit: `$$($summary.AverageProfit.ToString('N0'))"
Write-Host ""
Write-Host "Market Performance:" -ForegroundColor Yellow
Write-Host "  Market Share: $($summary.MarketShare.ToString('P2'))"
Write-Host ""
Write-Host "Learning Performance:" -ForegroundColor Yellow
Write-Host "  Total Reward: $($summary.TotalReward.ToString('F2'))"
Write-Host "  Average Reward: $($summary.AverageReward.ToString('F2'))"
Write-Host "  Final Exploration Rate: $($summary.Epsilon.ToString('F3'))"
Write-Host ""

# Analyze learning
Write-Host "=== LEARNING ANALYSIS ===" -ForegroundColor Cyan
Write-Host ""

# Reward trend
if ($company.RewardHistory.Count -ge 20) {
    $earlyRewards = $company.RewardHistory[0..9]
    $lateRewards = $company.RewardHistory[-10..-1]
    
    $earlyAvg = ($earlyRewards | Measure-Object -Average).Average
    $lateAvg = ($lateRewards | Measure-Object -Average).Average
    $improvement = (($lateAvg - $earlyAvg) / [Math]::Abs($earlyAvg)) * 100
    
    Write-Host "Reward Improvement:" -ForegroundColor Yellow
    Write-Host "  Early Average (Q1-10): $($earlyAvg.ToString('F2'))"
    Write-Host "  Late Average (Q31-40): $($lateAvg.ToString('F2'))"
    Write-Host "  Improvement: $($improvement.ToString('F1'))%" -ForegroundColor $(if ($improvement -gt 0) { "Green" } else { "Red" })
    Write-Host ""
}

# Profit trend
if ($company.ProfitHistory.Count -ge 20) {
    $earlyProfits = $company.ProfitHistory[0..9]
    $lateProfits = $company.ProfitHistory[-10..-1]
    
    $earlyAvg = ($earlyProfits | Measure-Object -Average).Average
    $lateAvg = ($lateProfits | Measure-Object -Average).Average
    
    if ($earlyAvg -ne 0) {
        $profitGrowth = (($lateAvg - $earlyAvg) / [Math]::Abs($earlyAvg)) * 100
        
        Write-Host "Profit Growth:" -ForegroundColor Yellow
        Write-Host "  Early Average: `$$($earlyAvg.ToString('N0'))"
        Write-Host "  Late Average: `$$($lateAvg.ToString('N0'))"
        Write-Host "  Growth: $($profitGrowth.ToString('F1'))%" -ForegroundColor $(if ($profitGrowth -gt 0) { "Green" } else { "Red" })
        Write-Host ""
    }
}

# Top learned strategies
Write-Host "=== TOP LEARNED STRATEGIES ===" -ForegroundColor Cyan
Write-Host ""

$topQValues = $company.Brain.QTable.GetEnumerator() | 
    Sort-Object Value -Descending | 
    Select-Object -First 10

Write-Host "Best State-Action Pairs (Q-Values):" -ForegroundColor Yellow
foreach ($pair in $topQValues) {
    Write-Host ("  {0,-50} = {1,8:F2}" -f $pair.Key.Substring(0, [Math]::Min(50, $pair.Key.Length)), $pair.Value)
}

Write-Host ""

# Recommendations
Write-Host "=== WHAT THE AGENT LEARNED ===" -ForegroundColor Cyan
Write-Host ""

if ($summary.MarketShare -gt 0.2) {
    Write-Host "✓ Successfully gained significant market share" -ForegroundColor Green
} else {
    Write-Host "⚠ Struggled to gain market share" -ForegroundColor Yellow
}

if ($summary.CurrentProfit -gt 0) {
    Write-Host "✓ Achieved profitability" -ForegroundColor Green
} else {
    Write-Host "⚠ Not yet profitable" -ForegroundColor Yellow
}

if ($summary.Cash -gt 1000000) {
    Write-Host "✓ Grew cash reserves" -ForegroundColor Green
} else {
    Write-Host "⚠ Cash reserves declined" -ForegroundColor Yellow
}

$explorationRate = $summary.Epsilon
if ($explorationRate -lt 0.2) {
    Write-Host "✓ Agent converged to exploitation (confident in strategy)" -ForegroundColor Green
} else {
    Write-Host "⚠ Agent still exploring (may need more training)" -ForegroundColor Yellow
}

Write-Host ""

# Next steps
Write-Host "=== NEXT STEPS ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Try different parameters:" -ForegroundColor Yellow
Write-Host "   - Adjust learning rate in CompanyAgent constructor"
Write-Host "   - Change starting capital (500K or 2M)"
Write-Host "   - Train for more quarters (100+)"
Write-Host ""
Write-Host "2. Experiment with reward function:" -ForegroundColor Yellow
Write-Host "   - Edit CalculateReward() method"
Write-Host "   - Weight different objectives"
Write-Host ""
Write-Host "3. Coming in Week 6: Multi-agent competition!" -ForegroundColor Yellow
Write-Host "   - 4 companies competing in shared market"
Write-Host "   - Strategic interaction & game theory"
Write-Host "   - Emergent behaviors"
Write-Host ""

Write-Host "✓ Demo complete!" -ForegroundColor Green
Write-Host ""