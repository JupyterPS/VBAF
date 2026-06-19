#Requires -Version 5.1

<#
.SYNOPSIS
    Lightweight loader for the VBAF core engine
.DESCRIPTION
    Loads only the core VBAF components -- no enterprise pillars,
    no ML production stack, no visualization dashboards.

    USE THIS WHEN:
    ==============
    You only need the RL and ML engine -- not the full framework.
    Loads faster than VBAF.LoadAll.ps1.
    Good for: experiments, custom agents, teaching, quick testing.

    USE VBAF.LoadAll.ps1 WHEN:
    ===========================
    You need enterprise pillars, dashboards or production ML tools.
    Always use LoadAll for the 6 examples and educational tools.

    WHAT THIS LOADS:
    ================
    Phase 1 -- Core neural network (NeuralNetwork, Neuron, Layer)
    Phase 2 -- Reinforcement learning (Q-learning, DQN, PPO, A3C)
    Phase 3 -- Business / multi-agent (CompanyAgent, MarketEnvironment)
    Phase 4 -- Supervised learning (regression, trees, clustering)
    Phase 5 -- Data pipeline (imputation, scaling, feature engineering)
    Phase 6 -- Deep learning (CNN, RNN, Autoencoder, TransferLearning)
    Phase 7 -- ML production (registry, server, MLOps, AutoML)
    Phase 8 -- Visualization (dashboards, metrics, art)

    HOW TO USE:
    ===========
    . .\VBAF.LoadCore.ps1

    Everything is then available. Run any example:
      & .\VBAF.Core.Example-XOR.ps1
      & .\VBAF.RL.Example-CastleLearning.ps1

.NOTES
    Part of VBAF (Visual AI & Reinforcement Learning Framework)
    For the full framework including enterprise pillars use VBAF.LoadAll.ps1
#>

$basePath = $PSScriptRoot

Write-Host ""
Write-Host "  Loading VBAF Core Engine..." -ForegroundColor Cyan
Write-Host ""

#  PHASE 1 -- CORE NEURAL NETWORK
Write-Host "  [Phase 1] Core neural network..." -ForegroundColor Gray
. (Join-Path $basePath "VBAF.Core.AllClasses.ps1")

#  PHASE 2 -- REINFORCEMENT LEARNING
Write-Host "  [Phase 2] Reinforcement learning..." -ForegroundColor Gray
. (Join-Path $basePath "VBAF.RL.QTable.ps1")
. (Join-Path $basePath "VBAF.RL.ExperienceReplay.ps1")
. (Join-Path $basePath "VBAF.RL.QLearningAgent.ps1")
. (Join-Path $basePath "VBAF.RL.Environment.ps1")
. (Join-Path $basePath "VBAF.RL.DQN.ps1")
. (Join-Path $basePath "VBAF.RL.PPO.ps1")
. (Join-Path $basePath "VBAF.RL.A3C.ps1")

#  PHASE 3 -- BUSINESS / MULTI-AGENT
Write-Host "  [Phase 3] Business and multi-agent..." -ForegroundColor Gray
. (Join-Path $basePath "VBAF.Business.CompanyState.ps1")
. (Join-Path $basePath "VBAF.Business.BusinessAction.ps1")
. (Join-Path $basePath "VBAF.Business.CompanyAgent.ps1")
. (Join-Path $basePath "VBAF.Business.MarketEnvironment.ps1")

#  PHASE 4 -- SUPERVISED LEARNING
Write-Host "  [Phase 4] Supervised learning..." -ForegroundColor Gray
. (Join-Path $basePath "VBAF.ML.Regression.ps1")
. (Join-Path $basePath "VBAF.ML.Trees.ps1")
. (Join-Path $basePath "VBAF.ML.Clustering.ps1")
. (Join-Path $basePath "VBAF.ML.NaiveBayes.ps1")

#  PHASE 5 -- DATA PIPELINE
Write-Host "  [Phase 5] Data pipeline..." -ForegroundColor Gray
. (Join-Path $basePath "VBAF.ML.DataPipeline.ps1")
. (Join-Path $basePath "VBAF.ML.FeatureEngineering.ps1")
. (Join-Path $basePath "VBAF.ML.DataIO.ps1")
. (Join-Path $basePath "VBAF.ML.TimeSeries.ps1")

#  PHASE 6 -- DEEP LEARNING
Write-Host "  [Phase 6] Deep learning..." -ForegroundColor Gray
. (Join-Path $basePath "VBAF.ML.CNN.ps1")
. (Join-Path $basePath "VBAF.ML.RNN.ps1")
. (Join-Path $basePath "VBAF.ML.Autoencoder.ps1")
. (Join-Path $basePath "VBAF.ML.TransferLearning.ps1")

#  PHASE 7 -- ML PRODUCTION
Write-Host "  [Phase 7] ML production..." -ForegroundColor Gray
. (Join-Path $basePath "VBAF.ML.ModelRegistry.ps1")
. (Join-Path $basePath "VBAF.ML.ModelServer.ps1")
. (Join-Path $basePath "VBAF.ML.MLOps.ps1")
. (Join-Path $basePath "VBAF.ML.AutoML.ps1")
. (Join-Path $basePath "VBAF.ML.Explainability.ps1")

#  PHASE 8 -- VISUALIZATION
Write-Host "  [Phase 8] Visualization..." -ForegroundColor Gray
. (Join-Path $basePath "VBAF.Visualization.MetricsCollector.ps1")
. (Join-Path $basePath "VBAF.Visualization.GraphRenderer.ps1")
. (Join-Path $basePath "VBAF.Visualization.LearningDashboard.ps1")
. (Join-Path $basePath "VBAF.Visualization.MarketDashboard.ps1")
. (Join-Path $basePath "VBAF.Art.AestheticReward.ps1")

Write-Host ""
Write-Host "  VBAF Core Engine ready!" -ForegroundColor Green
Write-Host ""
Write-Host "  LEARNING PATH (run in order):" -ForegroundColor Yellow
Write-Host "    1. & .\VBAF.Core.Example-XOR.ps1              -- neural networks" -ForegroundColor White
Write-Host "    2. & .\VBAF.RL.Example-CastleLearning.ps1     -- Q-learning" -ForegroundColor White
Write-Host "    3. & .\VBAF.Business.Test.CompanyMarket.ps1   -- multi-agent" -ForegroundColor White
Write-Host ""
Write-Host "  THE 3 DASHBOARDS:" -ForegroundColor Yellow
Write-Host "    VBAF.Visualization.Example-Dashboard.ps1      -- learning curves" -ForegroundColor White
Write-Host "    VBAF.Business.Dashboard-Demo.ps1              -- market competition" -ForegroundColor White
Write-Host "    VBAF.Core.Test-ValidationDashboard.ps1        -- model validation" -ForegroundColor White
Write-Host ""
Write-Host "  For enterprise pillars use: . .\VBAF.LoadAll.ps1" -ForegroundColor DarkGray
Write-Host ""