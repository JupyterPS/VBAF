#Requires -Version 5.1
 
<#
.SYNOPSIS
    Master loader for VBAF framework
.DESCRIPTION
    Loads all VBAF components in correct dependency order
.EXAMPLE
    
#>

$basePath = $PSScriptRoot

Write-Host "      - oo00oo - " -ForegroundColor Yellow 
Write-Host "Loading VBAF Framework..." -ForegroundColor Cyan

. (Join-Path $basePath "VBAF.Core.AllClasses.ps1")
Write-Host "33 Core modules loaded" -ForegroundColor Green

# VBAF.Art.Show20-QLearning.ps1
. (Join-Path $basePath "VBAF.RL.QTable.ps1")
. (Join-Path $basePath "VBAF.RL.ExperienceReplay.ps1")
. (Join-Path $basePath "VBAF.RL.QLearningAgent.ps1") 
# VBAF.Business.CompanyAgent.ps1
. (Join-Path $basePath "VBAF.RL.QLearningAgent.ps1")
. (Join-Path $basePath "VBAF.RL.ExperienceReplay.ps1")
. (Join-Path $basePath "VBAF.Business.CompanyState.ps1")
. (Join-Path $basePath "VBAF.Business.BusinessAction.ps1") 
# VBAF.Business.Dashboard-Demo.ps1                                                         # Dashboard 2
. (Join-Path $basePath "VBAF.Business.CompanyAgent.ps1")
. (Join-Path $basePath "VBAF.Business.MarketEnvironment.ps1")
. (Join-Path $basePath "VBAF.Visualization.MarketDashboard.ps1") 
. (Join-Path $basePath "VBAF.RL.QLearningAgent.ps1")
. (Join-Path $basePath "VBAF.RL.ExperienceReplay.ps1")
. (Join-Path $basePath "VBAF.Business.CompanyState.ps1")
. (Join-Path $basePath "VBAF.Business.BusinessAction.ps1")                         
# VBAF.Business.MarketEnvironment.ps1
. (Join-Path $basePath "VBAF.Business.CompanyAgent.ps1") 
# VBAF.Business.Test.CompanyMarket.ps1
. (Join-Path $basePath "VBAF.RL.QLearningAgent.ps1")
. (Join-Path $basePath "VBAF.RL.ExperienceReplay.ps1")
. (Join-Path $basePath "VBAF.Business.CompanyState.ps1")
. (Join-Path $basePath "VBAF.Business.BusinessAction.ps1")
. (Join-Path $basePath "VBAF.Business.CompanyAgent.ps1")
. (Join-Path $basePath "VBAF.Business.MarketEnvironment.ps1") 
# VBAF.Company.TestLearning.ps1 
. (Join-Path $basePath "VBAF.RL.QLearningAgent.ps1")
. (Join-Path $basePath "VBAF.RL.ExperienceReplay.ps1")
. (Join-Path $basePath "VBAF.Business.CompanyState.ps1")
. (Join-Path $basePath "VBAF.Business.BusinessAction.ps1")
. (Join-Path $basePath "VBAF.Business.CompanyAgent.ps1") 
# VBAF.Core.Example-XOR.ps1
. (Join-Path $basePath "VBAF.Core.AllClasses.ps1") 
# VBAF.RL.Example-CastleLearning.ps1
. (Join-Path $basePath "VBAF.RL.QTable.ps1")
. (Join-Path $basePath "VBAF.RL.ExperienceReplay.ps1")
. (Join-Path $basePath "VBAF.RL.QLearningAgent.ps1") 
# VBAF.RL.QLearningAgent.ps1
. (Join-Path $basePath "VBAF.RL.QTable.ps1")
. (Join-Path $basePath "VBAF.RL.ExperienceReplay.ps1") 
# VBAF.Visualization.Example-Dashboard.ps1                                                 # Dashboard 1
. (Join-Path $basePath "VBAF.Visualization.MetricsCollector.ps1")
. (Join-Path $basePath "VBAF.Visualization.GraphRenderer.ps1")
. (Join-Path $basePath "VBAF.Visualization.LearningDashboard.ps1")                          
# VBAF.Visualization.LearningDashboard.ps1
. (Join-Path $basePath "VBAF.Visualization.MetricsCollector.ps1")
. (Join-Path $basePath "VBAF.Visualization.GraphRenderer.ps1") 
# VBAF.Core.Test-ValidationDashboard.ps1                                                   # Dashboard 3
. (Join-Path $basePath "VBAF.Core.AllClasses.ps1")
. (Join-Path $basePath "VBAF.RL.QTable.ps1")
. (Join-Path $basePath "VBAF.RL.ExperienceReplay.ps1")
. (Join-Path $basePath "VBAF.RL.QLearningAgent.ps1")
# VBAF.Art.CastleCompetition.ps1
. (Join-Path $basePath "VBAF.RL.QTable.ps1")
. (Join-Path $basePath "VBAF.RL.ExperienceReplay.ps1")
. (Join-Path $basePath "VBAF.RL.QLearningAgent.ps1")
. (Join-Path $basePath "VBAF.Art.AestheticReward.ps1")
# Phase 3 - RL Algorithms
. (Join-Path $basePath "VBAF.RL.Environment.ps1")
. (Join-Path $basePath "VBAF.RL.DQN.ps1")    
. (Join-Path $basePath "VBAF.RL.PPO.ps1")  
. (Join-Path $basePath "VBAF.RL.A3C.ps1")  
# Phase 4 - ML Supervised Learning
. (Join-Path $basePath "VBAF.ML.Regression.ps1")
. (Join-Path $basePath "VBAF.ML.Trees.ps1")
. (Join-Path $basePath "VBAF.ML.Clustering.ps1") 
. (Join-Path $basePath "VBAF.ML.NaiveBayes.ps1")
# Phase 5 - ML Data Pipeline
. (Join-Path $basePath "VBAF.ML.DataPipeline.ps1")
. (Join-Path $basePath "VBAF.ML.FeatureEngineering.ps1")
. (Join-Path $basePath "VBAF.ML.DataIO.ps1")
. (Join-Path $basePath "VBAF.ML.TimeSeries.ps1")
# Phase 6 - ML Deep Learning
. (Join-Path $basePath "VBAF.ML.CNN.ps1")
. (Join-Path $basePath "VBAF.ML.RNN.ps1")
. (Join-Path $basePath "VBAF.ML.Autoencoder.ps1") 
. (Join-Path $basePath "VBAF.ML.TransferLearning.ps1")
# Phase 7 - ML Production Features
. (Join-Path $basePath "VBAF.ML.ModelRegistry.ps1")
. (Join-Path $basePath "VBAF.ML.ModelServer.ps1")
. (Join-Path $basePath "VBAF.ML.MLOps.ps1")
. (Join-Path $basePath "VBAF.ML.AutoML.ps1")
. (Join-Path $basePath "VBAF.ML.Explainability.ps1")
# Phase 9 - Enterprise Automation Engine
. (Join-Path $basePath "VBAF.Enterprise.Environment.ps1")
. (Join-Path $basePath "VBAF.Enterprise.JobScheduler.ps1")
. (Join-Path $basePath "VBAF.Enterprise.ResourceOptimizer.ps1")
. (Join-Path $basePath "VBAF.Enterprise.AlertRouter.ps1")
. (Join-Path $basePath "VBAF.Enterprise.SupplyChain.ps1")
# Phase 10 - Enterprise Intelligence (Pillars 8-10)
. (Join-Path $basePath "VBAF.Enterprise.SecurityMonitor.ps1")
. (Join-Path $basePath "VBAF.Enterprise.NetworkWatcher.ps1")
. (Join-Path $basePath "VBAF.Enterprise.DataFlowOptimizer.ps1")
# Phase 11 - Multi-Agent Collaboration
. (Join-Path $basePath "VBAF.Enterprise.MultiAgentCoordinator.ps1")
# Phase 12 - Predictive Maintenance
. (Join-Path $basePath "VBAF.Enterprise.PredictiveMaintenance.ps1")
# Phase 13 - Natural Language Interface
. (Join-Path $basePath "VBAF.Enterprise.NLInterface.ps1")
# Phase 14 - Self-Healing Infrastructure
. (Join-Path $basePath "VBAF.Enterprise.SelfHealing.ps1")
# Phase 15 - Enterprise Dashboard
. (Join-Path $basePath "VBAF.Enterprise.Dashboard.ps1")
# Phase 16 - Federated Learning
. (Join-Path $basePath "VBAF.Enterprise.FederatedLearning.ps1")

Write-Host "VBAF Framework ready!" -ForegroundColor Green

Write-Host "      - oo00oo - " -ForegroundColor Yellow 
Write-Host "VISIBLE LOADABLES FOR TESTING" -ForegroundColor Green

Write-Host "VBAF.LoadAll.ps1" -ForegroundColor Cyan
Write-Host "VBAF.Art.Show20-QLearning.ps1" -ForegroundColor Cyan
Write-Host "VBAF.RL.Example-CastleLearning.ps1" -ForegroundColor Cyan
Write-Host "VBAF.Company.TestLearning.ps1" -ForegroundColor Cyan
Write-Host "VBAF.Core.Example-XOR.ps1" -ForegroundColor Cyan
Write-Host "VBAF.Business.Test.CompanyMarket.ps1" -ForegroundColor Cyan

Write-Host "      - oo00oo - " -ForegroundColor Yellow 
Write-Host "The 3 Dashboards" -ForegroundColor Green
Write-Host "VBAF.Visualization.Example-Dashboard.ps1" -ForegroundColor Cyan                # Dashboard 1
Write-Host "VBAF.Business.Dashboard-Demo.ps1" -ForegroundColor Cyan                        # Dashboard 2
Write-Host "VBAF.Core.Test-ValidationDashboard.ps1" -ForegroundColor Cyan                  # Dashboard 3n                  # Dashboard 3




