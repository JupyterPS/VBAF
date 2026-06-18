# VBAF Architecture

This document describes how VBAF is structured -- the layers, the files,
the data flow, and the design decisions behind them.

---

## The Four-Layer Stack

VBAF is a layered framework. Each layer builds on the one below it.
You can use any layer independently, or combine them all.
Layer 4 -- Enterprise AutoPilot (Phase 27)

One master DQN agent orchestrating all 13 pillars simultaneously

File: VBAF.Enterprise.AutoPilot.ps1
Layer 3 -- Enterprise Pillars (Phases 14-26 + FleetDispatch + Healthcare)

14 domain-specific DQN agents, each solving one automation problem

SelfHealing, Dashboard, FederatedLearning, CloudBridge,

AnomalyDetector, CapacityPlanner, IncidentResponder,

ComplianceReporter, UserBehaviorAnalytics, PatchIntelligence,

BackupOptimizer, EnergyOptimizer, MultiSiteCoordinator,

FleetDispatch, HealthcareMonitor

Files: VBAF.Enterprise.*.ps1
Layer 2 -- RL Engine (Phases 1-3 of LoadAll)

Q-learning, DQN, PPO, A3C, experience replay, environments

Files: VBAF.RL.*.ps1
Layer 1 -- Core ML (Phases 4-8 of LoadAll)

Neural networks, supervised learning, data pipeline,

deep learning, ML production, visualization

Files: VBAF.Core..ps1, VBAF.ML..ps1, VBAF.Visualization.*.ps1

---

## Layer 1 -- Core ML

### Neural Network (VBAF.Core.AllClasses.ps1)

The foundation of all learning in VBAF.
Four classes in dependency order:
Activation    -- sigmoid, ReLU, tanh functions

Neuron        -- single processing unit with weights and bias

Layer         -- collection of neurons with shared activation

NeuralNetwork -- full feedforward network with backpropagation

Constructor: `[NeuralNetwork]::new(@(inputSize, hidden1, hidden2, outputSize), learningRate)`

Used by: DQNAgent (main and target networks), supervised learning models,
validation dashboard, XOR example.

### Supervised Learning (VBAF.ML.*.ps1)

Eight files covering the full ML pipeline:
VBAF.ML.Regression.ps1        -- LinearRegression, RidgeRegression,

LassoRegression, LogisticRegression,

StandardScaler, MinMaxScaler

VBAF.ML.Trees.ps1             -- DecisionTree, RandomForest

VBAF.ML.Clustering.ps1        -- KMeans, HierarchicalClustering, DBSCAN

VBAF.ML.NaiveBayes.ps1        -- GaussianNaiveBayes, MultinomialNaiveBayes,

BernoulliNaiveBayes

VBAF.ML.DataPipeline.ps1      -- MissingValueImputer, OutlierDetector,

RobustScaler, LabelEncoder, OneHotEncoder

VBAF.ML.FeatureEngineering.ps1 -- PolynomialFeatures, PCA, TransformerPipeline

VBAF.ML.DataIO.ps1            -- Import/Export CSV, JSON, Excel, SQL, API

VBAF.ML.TimeSeries.ps1        -- TimeSeries, lag features, rolling features,

seasonal decomposition

### Deep Learning (VBAF.ML.CNN.ps1, VBAF.ML.RNN.ps1, etc.)
VBAF.ML.CNN.ps1               -- Conv2D, MaxPooling2D, BatchNormalization,

Dropout, Flatten, DenseLayer, CNNModel

VBAF.ML.RNN.ps1               -- BasicRNNCell, LSTMCell, GRUCell,

BidirectionalRNN, Seq2SeqModel

VBAF.ML.Autoencoder.ps1       -- BasicAutoencoder, latent space visualisation

VBAF.ML.TransferLearning.ps1  -- ModelZoo, freeze layers, fine-tuning

### ML Production (VBAF.ML.ModelRegistry.ps1, etc.)
VBAF.ML.ModelRegistry.ps1     -- Save/Load/Compare models with versioning

VBAF.ML.ModelServer.ps1       -- Invoke-VBAFPrediction, A/B testing, monitoring

VBAF.ML.MLOps.ps1             -- Experiment tracking, drift detection, CI/CD

VBAF.ML.AutoML.ps1            -- Grid/Random/Bayesian search, algorithm selection

VBAF.ML.Explainability.ps1    -- SHAP values, LIME, permutation importance,

partial dependence plots

---

## Layer 2 -- RL Engine

### Q-Learning Stack
VBAF.RL.QTable.ps1            -- Q-table data structure (hashtable wrapper)

VBAF.RL.ExperienceReplay.ps1  -- Circular buffer for DQN training

VBAF.RL.QLearningAgent.ps1    -- Full Q-learning agent with epsilon-greedy,

Bellman update, state encoding, statistics

Dependency order: QTable -> ExperienceReplay -> QLearningAgent.
Never dot-source QLearningAgent without loading QTable first.
Always use VBAF.LoadAll.ps1.

### DQN Stack
VBAF.RL.DQN.ps1               -- DQNConfig, DQNAgent, DQNEnvironment

Main network + target network

Invoke-DQNTraining

DQNAgent depends on: NeuralNetwork (Layer 1), ExperienceReplay.
DQNConfig holds all hyperparameters:
  StateSize, ActionSize, LearningRate, Gamma, Epsilon, EpsilonDecay,
  EpsilonMin, MemorySize, BatchSize, TargetUpdateFreq.

### Policy Gradient Stack
VBAF.RL.PPO.ps1               -- PPOConfig, PPOAgent, PPOEnvironment

Invoke-PPOTraining

VBAF.RL.A3C.ps1               -- A3CConfig, A3CAgent, A3CWorker, A3CEnvironment

Invoke-A3CTraining

### Environments
VBAF.RL.Environment.ps1       -- VBAFSpace, VBAFEnvironment

CartPole, GridWorld, RandomWalk

New-VBAFEnvironment, Invoke-VBAFBenchmark

Standard environment interface:
  GetState()    -- returns double[] of state signals
  Step(action)  -- applies action, sets LastReward and LastDone
  Reset()       -- starts a new episode, returns initial state

All enterprise environments follow this same interface.

---

## Layer 3 -- Enterprise Pillars

### The Standard Pillar Pattern

Every enterprise pillar follows identical structure:

```powershell
class MyDomainEnvironment {
    [int]    $StateSize  = 4
    [int]    $ActionSize = 4
    [double] $LastReward = 0.0
    [bool]   $LastDone   = $false

    [double[]] GetState() { ... }   # 4 normalised signals (0.0-1.0)
    [double[]] Reset()    { ... }   # start new episode
    [void]     Step([int]$action) { # apply action, compute reward
        $dist = [Math]::Abs($action - $this.CurrentSeverity)
        $this.LastReward = @(2.0, -1.0, -2.0, -3.0)[$dist]
    }
    hidden [void] _Sample() { ... } # generate next state (SimMode or real data)
}
```

Four design rules:
1. 4 state signals normalised to 0.0-1.0
2. 4 actions ordered by severity (0=minimal, 3=maximum response)
3. Reward: +2 correct, -1/-2/-3 for distance 1/2/3 from correct
4. Distribution 15/40/30/15 across severity levels

### Training Function Pattern

Every pillar exposes one training function:

```powershell
function Invoke-VBAFXxxTraining {
    param([int]$Episodes=100, [int]$PrintEvery=10, [switch]$SimMode, [switch]$FastMode)
    # Phase 1: baseline (random agent)
    # Phase 2: DQN training
    # Phase 3: evaluation (epsilon=0)
    # Returns: @{ Agent=$agent; Baseline=@{Avg=$b}; Trained=@{Avg=$t} }
}
```

### SimMode vs Real Data

SimMode (default): `_Sample()` generates synthetic data using Get-Random.
Real data: replace `_Sample()` ranges with actual Windows data sources:

```powershell
# SimMode
$this.CpuLoad = [double](Get-Random -Minimum 0 -Maximum 100) / 100.0

# Real data
$cpu = (Get-WmiObject Win32_Processor).LoadPercentage
$this.CpuLoad = [double]$cpu / 100.0
```

All 14 pillars work in both modes without changing any other code.

---

## Layer 4 -- Enterprise AutoPilot

AutoPilot (Phase 27) is a master DQN agent that observes the state of
all 13 enterprise pillars simultaneously and decides which pillar to
prioritise each episode.

State: 13 x 4 = 52 signals (all pillar states concatenated)
Actions: 13 (one per pillar -- which to focus training on)
Reward: weighted sum of improvement across all active pillars

This is VBAF's most complex component -- read Phases 14-26 first.

---

## Business and Multi-Agent Layer

Separate from the enterprise pillars, VBAF also has a full market
simulation for studying multi-agent reinforcement learning:
VBAF.Business.CompanyState.ps1      -- company state variables

VBAF.Business.BusinessAction.ps1    -- action definitions

VBAF.Business.CompanyAgent.ps1      -- QLearningAgent in business context

VBAF.Business.MarketEnvironment.ps1 -- shared market, Bertrand competition,

random events, Herfindahl index

---

## Visualization Layer
VBAF.Visualization.MetricsCollector.ps1  -- record error, reward, epsilon

VBAF.Visualization.GraphRenderer.ps1     -- ASCII and WinForms chart rendering

VBAF.Visualization.LearningDashboard.ps1 -- live training dashboard

VBAF.Visualization.MarketDashboard.ps1   -- live market competition dashboard

VBAF.Art.AestheticReward.ps1             -- reward functions for creative tasks

All WinForms dashboards require standalone PowerShell console (not ISE).
ISE blocks when a WinForms window opens -- this is a known ISE limitation.

---

## Load Order and Dependencies

VBAF.LoadAll.ps1 loads everything in strict dependency order.
The phases in LoadAll correspond to dependency layers:
Phase 1:   VBAF.Core.AllClasses.ps1          (no dependencies)

Phase 2:   VBAF.RL..ps1                     (depends on Core)

Phase 3:   VBAF.Business..ps1               (depends on RL)

Phase 4:   VBAF.ML.Regression.ps1            (depends on Core)

Phase 5:   VBAF.ML.DataPipeline.ps1          (depends on Regression)

Phase 6:   VBAF.ML.CNN.ps1, RNN.ps1          (depends on Core)

Phase 7:   VBAF.ML.ModelRegistry.ps1         (depends on all ML)

Phase 8:   VBAF.Visualization..ps1          (depends on RL, ML)

Phase 9+:  VBAF.Enterprise..ps1             (depends on everything)

PowerShell 5.1 classes must be defined before they are used.
If you load DQN before AllClasses, NeuralNetwork does not exist yet.
This is why VBAF.LoadAll.ps1 must always be run first -- every session.

---

## Data Flow -- Enterprise Automation
Windows system (real mode) or Get-Random (SimMode)

|

v

Environment._Sample()

Generates 4 state signals (0.0-1.0 normalised)

|

v

DQNAgent.Act(state)

Neural network forward pass

Returns action (0, 1, 2 or 3)

|

v

Environment.Step(action)

Computes reward (+2 / -1 / -2 / -3)

Sets LastDone after N steps

|

v

DQNAgent.Remember(s, a, r, s', done)

Stores transition in ExperienceReplay buffer

|

v

DQNAgent.Replay()

Samples random batch from buffer

Computes Bellman targets using target network

Updates main network weights via backpropagation

|

v

(every 10 episodes)

DQNAgent syncs target network from main network

|

v

Improved policy -- agent makes better decisions next episode

---

## File Naming Convention
VBAF.Core.*           -- neural network and math primitives

VBAF.RL.*             -- reinforcement learning algorithms and environments

VBAF.ML.*             -- supervised learning, data pipeline, production ML

VBAF.Business.*       -- market simulation and company agents

VBAF.Visualization.*  -- dashboards, charts, metrics collection

VBAF.Art.*            -- creative AI and aesthetic reward functions

VBAF.Enterprise.*     -- enterprise automation pillars (Phases 14-27)

VBAF.LoadAll.ps1      -- master loader, always run this first

---

## Design Principles

**Pure PowerShell 5.1:**
No external dependencies. Runs on any Windows 10/11 machine with no setup.
Tradeoff: no GPU, no vectorised operations, slower than Python frameworks.
Benefit: deployable anywhere, readable by any PowerShell professional.

**ASCII-only comments:**
PS 5.1 has encoding issues with Unicode in comment blocks.
All educational comments use plain ASCII: alpha, gamma, epsilon, ->, sum, ^2.

**Classes before functions:**
All PS 5.1 classes must be defined in the same dot-sourcing scope.
This is why everything loads via VBAF.LoadAll.ps1 -- never run files directly.

**Educational transparency:**
Every file explains WHAT it does, WHY it does it, and HOW it works.
Q-learning uses a readable hashtable (not an opaque array) so students
can inspect `$agent.QTable` and understand what was learned.