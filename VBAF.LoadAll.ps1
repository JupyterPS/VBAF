#Requires -Version 5.1

<#
.SYNOPSIS
    Master loader for the VBAF framework
.DESCRIPTION
    Loads all VBAF components in correct dependency order.

    WHAT YOU ARE LEARNING HERE:
    ============================
    This file is the entry point for the entire VBAF framework.
    Run this once at the start of every PowerShell session.

    WHY DOT-SOURCING
    =================
    The dot (.) before each file path is called "dot-sourcing".
    It loads the file into the CURRENT scope -- making all classes
    and functions available in your session.

    Without the dot:   & .\VBAF.Core.AllClasses.ps1  -> runs in child scope, gone when done
    With the dot:      . .\VBAF.Core.AllClasses.ps1  -> stays in current scope

    WHY LOAD ORDER MATTERS:
    =======================
    PowerShell 5.1 classes must be defined BEFORE they are used.
    If VBAF.RL.DQN.ps1 is loaded before VBAF.Core.AllClasses.ps1,
    the NeuralNetwork class does not exist yet -- runtime error.

    The order below is the correct dependency chain:
      Core classes first (no dependencies)
      RL classes next (depend on Core)
      Business classes next (depend on RL)
      Visualization last (depends on everything)
      Enterprise last (the advanced layer)

    HOW TO USE:
    ===========
    Open PowerShell (not ISE for production -- separate consoles work better)
    Then dot-source this file:

      . .\VBAF.LoadAll.ps1

    Everything is then available. Run any example:

      & .\VBAF.Core.Example-XOR.ps1
      & .\VBAF.RL.Example-CastleLearning.ps1
      & .\VBAF.Business.Test.CompanyMarket.ps1

.NOTES
    Part of VBAF (Visual AI & Reinforcement Learning Framework)
    Run this file first -- every session, every time.
#>

$basePath = $PSScriptRoot

Write-Host ""
Write-Host "  Loading VBAF Framework..." -ForegroundColor Cyan
Write-Host ""

#  PHASE 1 -- CORE NEURAL NETWORK 
# Activation, Neuron, Layer, NeuralNetwork classes.
# Everything else depends on these -- load first.
Write-Host "  [Phase 1] Core neural network..." -ForegroundColor Gray
. (Join-Path $basePath "VBAF.Core.AllClasses.ps1")

#  PHASE 2 -- REINFORCEMENT LEARNING 
# Q-table, experience replay, Q-learning agent, DQN agent, environments.
# These depend on Core -- load after Core.
Write-Host "  [Phase 2] Reinforcement learning..." -ForegroundColor Gray
. (Join-Path $basePath "VBAF.RL.QTable.ps1")
. (Join-Path $basePath "VBAF.RL.ExperienceReplay.ps1")
. (Join-Path $basePath "VBAF.RL.QLearningAgent.ps1")
. (Join-Path $basePath "VBAF.RL.Environment.ps1")
. (Join-Path $basePath "VBAF.RL.DQN.ps1")
. (Join-Path $basePath "VBAF.RL.PPO.ps1")
. (Join-Path $basePath "VBAF.RL.A3C.ps1")

#  PHASE 3 -- BUSINESS / MULTI-AGENT 
# Company state, actions, agents and market environment.
# Multi-agent competition -- four companies learning simultaneously.
Write-Host "  [Phase 3] Business and multi-agent..." -ForegroundColor Gray
. (Join-Path $basePath "VBAF.Business.CompanyState.ps1")
. (Join-Path $basePath "VBAF.Business.BusinessAction.ps1")
. (Join-Path $basePath "VBAF.Business.CompanyAgent.ps1")
. (Join-Path $basePath "VBAF.Business.MarketEnvironment.ps1")

#  PHASE 4 -- ML SUPERVISED LEARNING 
# Classical machine learning: regression, trees, clustering, naive Bayes.
Write-Host "  [Phase 4] Supervised learning..." -ForegroundColor Gray
. (Join-Path $basePath "VBAF.ML.Regression.ps1")
. (Join-Path $basePath "VBAF.ML.Trees.ps1")
. (Join-Path $basePath "VBAF.ML.Clustering.ps1")
. (Join-Path $basePath "VBAF.ML.NaiveBayes.ps1")

#  PHASE 5 -- ML DATA PIPELINE 
# Data preparation, feature engineering, I/O, time series.
Write-Host "  [Phase 5] Data pipeline..." -ForegroundColor Gray
. (Join-Path $basePath "VBAF.ML.DataPipeline.ps1")
. (Join-Path $basePath "VBAF.ML.FeatureEngineering.ps1")
. (Join-Path $basePath "VBAF.ML.DataIO.ps1")
. (Join-Path $basePath "VBAF.ML.TimeSeries.ps1")

#  PHASE 6 -- ML DEEP LEARNING 
# CNN, RNN, Autoencoder, Transfer Learning.
Write-Host "  [Phase 6] Deep learning..." -ForegroundColor Gray
. (Join-Path $basePath "VBAF.ML.CNN.ps1")
. (Join-Path $basePath "VBAF.ML.RNN.ps1")
. (Join-Path $basePath "VBAF.ML.Autoencoder.ps1")
. (Join-Path $basePath "VBAF.ML.TransferLearning.ps1")

#  PHASE 7 -- ML PRODUCTION 
# Model registry, serving, MLOps, AutoML, explainability.
Write-Host "  [Phase 7] ML production..." -ForegroundColor Gray
. (Join-Path $basePath "VBAF.ML.ModelRegistry.ps1")
. (Join-Path $basePath "VBAF.ML.ModelServer.ps1")
. (Join-Path $basePath "VBAF.ML.MLOps.ps1")
. (Join-Path $basePath "VBAF.ML.AutoML.ps1")
. (Join-Path $basePath "VBAF.ML.Explainability.ps1")

#  PHASE 8 -- VISUALIZATION 
# Metrics collection, graph rendering, learning dashboards.
Write-Host "  [Phase 8] Visualization..." -ForegroundColor Gray
. (Join-Path $basePath "VBAF.Visualization.MetricsCollector.ps1")
. (Join-Path $basePath "VBAF.Visualization.GraphRenderer.ps1")
. (Join-Path $basePath "VBAF.Visualization.LearningDashboard.ps1")
. (Join-Path $basePath "VBAF.Visualization.MarketDashboard.ps1")

#  PHASE 8 -- ART / CREATIVE 
# Aesthetic reward functions, castle competition visualisation.
Write-Host "  [Phase 8] Creative AI..." -ForegroundColor Gray
. (Join-Path $basePath "VBAF.Art.AestheticReward.ps1")

#  PHASE 9 -- ENTERPRISE AUTOMATION 
# The enterprise layer -- 14 pillars built on the foundation above.
# Study Phase 1-8 first, then read these to see concepts at scale.
Write-Host "  [Phase 9-27] Enterprise automation..." -ForegroundColor Gray
. (Join-Path $basePath "VBAF.Enterprise.Environment.ps1")
. (Join-Path $basePath "VBAF.Enterprise.JobScheduler.ps1")
. (Join-Path $basePath "VBAF.Enterprise.ResourceOptimizer.ps1")
. (Join-Path $basePath "VBAF.Enterprise.AlertRouter.ps1")
. (Join-Path $basePath "VBAF.Enterprise.SupplyChain.ps1")
. (Join-Path $basePath "VBAF.Enterprise.SecurityMonitor.ps1")
. (Join-Path $basePath "VBAF.Enterprise.NetworkWatcher.ps1")
. (Join-Path $basePath "VBAF.Enterprise.DataFlowOptimizer.ps1")
. (Join-Path $basePath "VBAF.Enterprise.MultiAgentCoordinator.ps1")
. (Join-Path $basePath "VBAF.Enterprise.PredictiveMaintenance.ps1")
. (Join-Path $basePath "VBAF.Enterprise.NLInterface.ps1")
. (Join-Path $basePath "VBAF.Enterprise.SelfHealing.ps1")
. (Join-Path $basePath "VBAF.Enterprise.Dashboard.ps1")
. (Join-Path $basePath "VBAF.Enterprise.FederatedLearning.ps1")
. (Join-Path $basePath "VBAF.Enterprise.CloudBridge.ps1")
. (Join-Path $basePath "VBAF.Enterprise.AnomalyDetector.ps1")
. (Join-Path $basePath "VBAF.Enterprise.CapacityPlanner.ps1")
. (Join-Path $basePath "VBAF.Enterprise.IncidentResponder.ps1")
. (Join-Path $basePath "VBAF.Enterprise.ComplianceReporter.ps1")
. (Join-Path $basePath "VBAF.Enterprise.UserBehaviorAnalytics.ps1")
. (Join-Path $basePath "VBAF.Enterprise.PatchIntelligence.ps1")
. (Join-Path $basePath "VBAF.Enterprise.BackupOptimizer.ps1")
. (Join-Path $basePath "VBAF.Enterprise.EnergyOptimizer.ps1")
. (Join-Path $basePath "VBAF.Enterprise.MultiSiteCoordinator.ps1")
. (Join-Path $basePath "VBAF.Enterprise.AutoPilot.ps1")
. (Join-Path $basePath "VBAF.Enterprise.FleetDispatch.ps1")
. (Join-Path $basePath "VBAF.Enterprise.HealthcareMonitor.ps1")
#  PHASE 10 -- EDUCATIONAL TOOLS 
# Teaching, benchmarking and playground -- depend on all phases above.
# Start-VBAFTeach       -- console teacher, 6 topics, press Enter to advance
# Start-VBAFPlayground  -- interactive menu, pick algorithm, watch it train
Write-Host "  [Phase 10] Educational tools..." -ForegroundColor Gray
. (Join-Path $basePath "VBAF.Teach.ps1")
# . (Join-Path $basePath "VBAF.Benchmark.ps1")  -- excluded pending repair
. (Join-Path $basePath "VBAF.Playground.ps1")
Write-Host ""
Write-Host "  VBAF Framework ready!" -ForegroundColor Green
Write-Host ""
Write-Host "  LEARNING PATH (run in order):" -ForegroundColor Yellow
Write-Host "    1. & .\VBAF.Core.Example-XOR.ps1                  -- neural networks" -ForegroundColor White
Write-Host "    2. & .\VBAF.RL.Example-CastleLearning.ps1         -- Q-learning" -ForegroundColor White
Write-Host "    3. & .\VBAF.Business.Test.CompanyMarket.ps1       -- multi-agent" -ForegroundColor White
Write-Host "    4. & .\VBAF.Visualization.Example-Dashboard.ps1   -- dashboards" -ForegroundColor White
Write-Host ""
Write-Host "  THE 5 DASHBOARDS:" -ForegroundColor Yellow
Write-Host "    1. VBAF.Visualization.Example-Dashboard.ps1       -- learning curves" -ForegroundColor White
Write-Host "    2. VBAF.Business.Dashboard-Demo.ps1               -- market competition" -ForegroundColor White
Write-Host "    3. VBAF.Core.Test-ValidationDashboard.ps1         -- model validation" -ForegroundColor White
Write-Host "    4. VBAF.Art.Show20-QLearning.ps1                  -- Q-learning visual" -ForegroundColor White
Write-Host "    5. VBAF.Art.CastleCompetition.ps1                 -- castle battle" -ForegroundColor White
Write-Host ""
Write-Host "  EDUCATIONAL TOOLS:" -ForegroundColor Yellow
Write-Host "    Start-VBAFTeach                    -- console teacher (6 topics)" -ForegroundColor White
Write-Host "    Start-VBAFPlayground               -- interactive experiment station" -ForegroundColor White
Write-Host ""



