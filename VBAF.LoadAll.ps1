#Requires -Version 5.1
 
<#
.SYNOPSIS
    Master loader for VBAF framework
.DESCRIPTION
    Loads all VBAF components in correct dependency order
.EXAMPLE
    . C:\Users\henni\OneDrive\WindowsPowerShell\VBAF.LoadAll.ps1
#>

$basePath = "C:\Users\henni\OneDrive\WindowsPowerShell"

Write-Host "      - oo00oo - " -ForegroundColor Yellow 
Write-Host "Loading VBAF Framework..." -ForegroundColor Cyan

. "$basePath\VBAF.Core.AllClasses.ps1"
Write-Host "  ✓ 33 Core modules loaded" -ForegroundColor Green

# VBAF.Art.Show20-QLearning.ps1
. "$basePath\VBAF.RL.QTable.ps1"
. "$basePath\VBAF.RL.ExperienceReplay.ps1"
. "$basePath\VBAF.RL.QLearningAgent.ps1" 
# VBAF.Business.CompanyAgent.ps1
. "$basePath\VBAF.RL.QLearningAgent.ps1"
. "$basePath\VBAF.RL.ExperienceReplay.ps1"
. "$basePath\VBAF.Business.CompanyState.ps1"
. "$basePath\VBAF.Business.BusinessAction.ps1" 
# VBAF.Business.Dashboard-Demo.ps1                                                      # Dashboard 2
. "$basePath\VBAF.Business.CompanyAgent.ps1"
. "$basePath\VBAF.Business.MarketEnvironment.ps1"
. "$basePath\VBAF.Visualization.MarketDashboard.ps1"                                    # Dashboard 2 
# VBAF.Business.MarketEnvironment.ps1
. "$basePath\VBAF.Business.CompanyAgent.ps1" 
# VBAF.Business.Test.CompanyMarket.ps1
. "$basePath\VBAF.RL.QLearningAgent.ps1"
. "$basePath\VBAF.RL.ExperienceReplay.ps1"
. "$basePath\VBAF.Business.CompanyState.ps1"
. "$basePath\VBAF.Business.BusinessAction.ps1"
. "$basePath\VBAF.Business.CompanyAgent.ps1"
. "$basePath\VBAF.Business.MarketEnvironment.ps1" 
# VBAF.Company.TestLearning.ps1 
. "$basePath\VBAF.RL.QLearningAgent.ps1"
. "$basePath\VBAF.RL.ExperienceReplay.ps1"
. "$basePath\VBAF.Business.CompanyState.ps1"
. "$basePath\VBAF.Business.BusinessAction.ps1"
. "$basePath\VBAF.Business.CompanyAgent.ps1" 
# VBAF.Core.Example-XOR.ps1
. "$basePath\VBAF.Core.AllClasses.ps1" 
# VBAF.RL.Example-CastleLearning.ps1
. "$basePath\VBAF.RL.QTable.ps1"
. "$basePath\VBAF.RL.ExperienceReplay.ps1"
. "$basePath\VBAF.RL.QLearningAgent.ps1" 
# VBAF.RL.QLearningAgent.ps1
. "$basePath\VBAF.RL.QTable.ps1"
. "$basePath\VBAF.RL.ExperienceReplay.ps1" 
# VBAF.Visualization.Example-Dashboard.ps1                                                 # Dashboard 1
. "$basePath\VBAF.Visualization.MetricsCollector.ps1"
. "$basePath\VBAF.Visualization.GraphRenderer.ps1"
. "$basePath\VBAF.Visualization.LearningDashboard.ps1"                                     # Dashboard 1 
# VBAF.Visualization.LearningDashboard.ps1
. "$basePath\VBAF.Visualization.MetricsCollector.ps1"
. "$basePath\VBAF.Visualization.GraphRenderer.ps1" 
# VBAF.Core.Test-ValidationDashboard.ps1                                                   # Dashboard 3
. "$basePath\VBAF.Core.AllClasses.ps1"
. "$basePath\VBAF.RL.QTable.ps1"
. "$basePath\VBAF.RL.ExperienceReplay.ps1"
. "$basePath\VBAF.RL.QLearningAgent.ps1"
# VBAF.Art.CastleCompetition.ps1
. "$basePath\VBAF.RL.QTable.ps1"
. "$basePath\VBAF.RL.ExperienceReplay.ps1"
. "$basePath\VBAF.RL.QLearningAgent.ps1"
. "$basePath\VBAF.Art.AestheticReward.ps1"

# Write-Host "  ✓ Visualization modules loaded" -ForegroundColor Green
Write-Host "VBAF Framework ready!" -ForegroundColor Green

Write-Host "      - oo00oo - " -ForegroundColor Yellow 
Write-Host "LOADABLES FOR TESTING" -ForegroundColor Green

Write-Host "VBAF.Art.Show20-QLearning.ps1" -ForegroundColor Cyan
Write-Host "VBAF.RL.Example-CastleLearning.ps1" -ForegroundColor Cyan
Write-Host "VBAF.Company.TestLearning.ps1" -ForegroundColor Cyan
Write-Host "VBAF.Core.Example-XOR.ps1" -ForegroundColor Cyan
Write-Host "VBAF.LoadAll.ps1" -ForegroundColor Cyan
Write-Host "VBAF.Business.Test.CompanyMarket.ps1" -ForegroundColor Cyan
Write-Host "VBAF.Visualization.Example-Dashboard.ps1" -ForegroundColor Cyan                  # Dashboard 1
Write-Host "VBAF.Business.Dashboard-Demo.ps1" -ForegroundColor Cyan                          # Dashboard 2
Write-Host "VBAF.Core.Test-ValidationDashboard.ps1"                                          # Dashboard 3  

Write-Host "      - oo00oo - " -ForegroundColor Yellow 
Write-Host "The 3 Dashboards" -ForegroundColor Green



