#Requires -Version 5.1

<#
.SYNOPSIS
    Q-Learning Castle Agent - Training Demo
.DESCRIPTION
    Demonstrates Q-Learning agent learning to generate castles.
    Shows exploration/exploitation balance and reward improvement.
#>

$basePath = $PSScriptRoot

# Load dependencies
. (Join-Path $basePath "VBAF.RL.QTable.ps1")
. (Join-Path $basePath "VBAF.RL.ExperienceReplay.ps1")
. (Join-Path $basePath "VBAF.RL.QLearningAgent.ps1")

Write-Host "`n+----------------------------------------------+" -ForegroundColor Cyan
Write-Host "¦   Q-LEARNING CASTLE AGENT - TRAINING DEMO   ¦" -ForegroundColor Cyan
Write-Host "+----------------------------------------------+" -ForegroundColor Cyan

$castleTypes = @(
    "Gothic", "FairyTale", "Fortress", "Palace",
    "Wizard", "Cathedral", "Oriental", "Ruins"
)

Write-Host "`nAvailable Castle Types:" -ForegroundColor Yellow
foreach ($type in $castleTypes) {
    Write-Host "  • $type"
}

Write-Host "`nCreating Q-Learning Agent..." -ForegroundColor Yellow
$agent = New-Object QLearningAgent -ArgumentList @(,$castleTypes)

Write-Host "  Alpha (learning rate): $($agent.Alpha)"
Write-Host "  Gamma (discount): $($agent.Gamma)"
Write-Host "  Epsilon (exploration): $($agent.Epsilon)"

$episodes = 100
$stepsPerEpisode = 10

Write-Host "`nTraining Configuration:" -ForegroundColor Yellow
Write-Host "  Episodes: $episodes"
Write-Host "  Steps per episode: $stepsPerEpisode"
Write-Host "  Total interactions: $($episodes * $stepsPerEpisode)"

$recentCastles = New-Object System.Collections.ArrayList

Write-Host "`n" + ("-" * 60) -ForegroundColor Cyan
Write-Host "TRAINING IN PROGRESS" -ForegroundColor Cyan
Write-Host ("-" * 60) -ForegroundColor Cyan
Write-Host ""

for ($ep = 1; $ep -le $episodes; $ep++) {
    $episodeReward = 0.0
    
    for ($step = 1; $step -le $stepsPerEpisode; $step++) {
        $context = @{ RecentTypes = $recentCastles }
        $state = $agent.GetState($context)
        
        $action = $agent.ChooseAction($state)
        
        $isVaried = ($recentCastles.Count -eq 0) -or ($recentCastles[-1] -ne $action)
        $visualBalance = Get-Random -Minimum 0.0 -Maximum 1.0
        $engagement = Get-Random -Minimum 0.0 -Maximum 1.0
        
        $outcome = @{
            CastleType = $action
            IsVaried = $isVaried
            VisualBalance = $visualBalance
            Engagement = $engagement
        }
        
        $reward = $agent.CalculateReward($outcome)
        $episodeReward += $reward
        
        $recentCastles.Add($action) | Out-Null
        if ($recentCastles.Count -gt 5) {
            $recentCastles.RemoveAt(0)
        }
        
        $nextContext = @{ RecentTypes = $recentCastles }
        $nextState = $agent.GetState($nextContext)
        
        $agent.Learn($state, $action, $reward, $nextState)
    }
    
    $agent.EndEpisode($episodeReward)
    
    if ($ep % 10 -eq 0 -or $ep -eq 1 -or $ep -eq $episodes) {
        $stats = $agent.GetStats()
        $exploitPct = (1.0 - $stats.ExplorationRatio) * 100
        
        Write-Host ("Episode {0,3} | Reward: {1,6:F2} | Epsilon: {2:F3} | Exploit: {3,5:F1}% | Q-Table: {4,3} entries" -f `
            $ep, $episodeReward, $stats.Epsilon, $exploitPct, $stats.QTableSize)
    }
}

Write-Host "`n? Training complete!" -ForegroundColor Green

Write-Host "`n" + ("-" * 60) -ForegroundColor Cyan
Write-Host "FINAL RESULTS" -ForegroundColor Cyan
Write-Host ("-" * 60) -ForegroundColor Cyan

$finalStats = $agent.GetStats()

Write-Host "`nLearning Progress:" -ForegroundColor Yellow
Write-Host "  Total Episodes: $($finalStats.Episode)"
Write-Host "  Total Reward: $($finalStats.TotalReward.ToString('F2'))"
Write-Host "  Average Reward: $($finalStats.AverageReward.ToString('F2'))"
Write-Host "  Recent Average (last 10): $($finalStats.RecentAverageReward.ToString('F2'))"

Write-Host "`nExploration vs Exploitation:" -ForegroundColor Yellow
Write-Host "  Explorations: $($finalStats.ExplorationCount)"
Write-Host "  Exploitations: $($finalStats.ExploitationCount)"
Write-Host "  Final Epsilon: $($finalStats.Epsilon.ToString('F3'))"

Write-Host "`nKnowledge Base:" -ForegroundColor Yellow
Write-Host "  Q-Table Entries: $($finalStats.QTableSize)"
Write-Host "  Experiences Stored: $($finalStats.MemorySize)"

# FIX 1: Show Q-values for ACTUAL states used
Write-Host "`nLearned Q-Values BY STATE:" -ForegroundColor Yellow
Write-Host "(State = number of recent castles shown)" -ForegroundColor Gray

$statesFound = @()

for ($stateNum = 0; $stateNum -le 5; $stateNum++) {
    $qValues = $agent.GetQValues("$stateNum")
    
    # Check if this state has any non-zero values
    $hasLearning = $false
    foreach ($val in $qValues.Values) {
        if ($val -ne 0) {
            $hasLearning = $true
            break
        }
    }
    
    if ($hasLearning) {
        $statesFound += $stateNum
        Write-Host "`n  State '$stateNum':" -ForegroundColor Cyan
        
        $sorted = $qValues.GetEnumerator() | Sort-Object Value -Descending
        
        foreach ($item in $sorted) {
            if ($item.Value -ne 0) {
                $color = if ($item.Value -gt 0) { "Green" } 
                         elseif ($item.Value -lt 0) { "Red" } 
                         else { "Gray" }
                
                Write-Host ("    {0,-15} {1,8:F4}" -f $item.Key, $item.Value) -ForegroundColor $color
            }
        }
    }
}

if ($statesFound.Count -eq 0) {
    Write-Host "`n  ? No learning detected in any state!" -ForegroundColor Red
    Write-Host "  This suggests the Q-Learning update isn't working." -ForegroundColor Red
} else {
    Write-Host "`n? Learning detected in states: $($statesFound -join ', ')" -ForegroundColor Green
}

if ($finalStats.RecentAverageReward -gt $finalStats.AverageReward) {
    Write-Host "`n?? Agent is IMPROVING! Recent rewards higher than average!" -ForegroundColor Green
} else {
    Write-Host "`n? Agent performance stable" -ForegroundColor Yellow
}

Write-Host ""
