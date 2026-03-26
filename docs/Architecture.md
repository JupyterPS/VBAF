# VBAF Architecture

## Overview

VBAF is a layered framework. Each layer builds on the one below it.
```
Layer 4 — Enterprise AutoPilot (Phase 27)
           One master agent orchestrating all 13 pillars

Layer 3 — Enterprise Pillars (Phases 14-26)
           13 domain-specific DQN agents
           SelfHealing, Dashboard, FederatedLearning, CloudBridge,
           AnomalyDetector, CapacityPlanner, IncidentResponder,
           ComplianceReporter, UserBehaviorAnalytics, PatchIntelligence,
           BackupOptimizer, EnergyOptimizer, MultiSiteCoordinator

Layer 2 — DQN Engine (Phases 8-13)
           DQNAgent, NeuralNetwork, ExperienceReplay, DQNConfig

Layer 1 — Core ML (Phases 1-7)
           NeuralNetwork, Q-Learning, Supervised Learning,
           Regression, Classification, Clustering
```

## Core Components

### NeuralNetwork
Fully connected feedforward network with backpropagation.
Configurable architecture: any number of layers and neurons.
Used by both supervised learning and DQN agents.

### DQNAgent
Deep Q-Network agent. Maintains main and target networks.
Uses epsilon-greedy exploration with configurable decay.
Experience replay for stable training.

### ExperienceReplay
Circular buffer storing (state, action, reward, next_state, done) tuples.
Random sampling breaks temporal correlations in training data.

### Enterprise Environment
Each pillar defines a class with:
- `GetState()` — returns 4 real-time signals (0.0-1.0)
- `Step(action)` — applies action, computes reward
- `Reset()` — starts a new episode

## Data Flow
```
Windows signals (WMI, Get-WinEvent, Get-Service)
    -> Environment.GetState() -> double[4]
    -> DQNAgent.Act(state)    -> int (0-3)
    -> Environment.Step(action)
    -> reward signal
    -> DQNAgent.Remember() + Replay()
    -> improved policy
```

## File Structure
```
VBAF.Core.*           — neural network, math utilities
VBAF.RL.*             — Q-learning, DQN, experience replay
VBAF.ML.*             — supervised learning, clustering, pipelines
VBAF.Business.*       — market simulation, company agents
VBAF.Visualization.*  — dashboards, charts
VBAF.Enterprise.*     — 14 enterprise automation pillars
VBAF.LoadAll.ps1      — loads everything in correct order
```
