# VBAF: Visual Business Automation Framework

## Abstract

We present VBAF, a PowerShell 5.1 framework for training Deep Q-Network (DQN)
agents to make autonomous enterprise IT decisions. VBAF requires no external
dependencies, runs on any Windows machine, and achieves consistent positive
improvement over random baselines across 14 enterprise automation domains.
The best-performing pillar (EnergyOptimizer, Phase 25) achieves +117.5%
improvement over a random dispatcher in 100 training episodes.

## 1. Introduction

Enterprise IT operations require constant decision-making: when to scale resources,
how to route network traffic, whether to apply a patch now or defer it.
These decisions are currently made by human operators using experience and intuition.

VBAF replaces intuition with a learned policy. The key insight is that most
enterprise IT decisions can be formulated as a 4-state, 4-action reinforcement
learning problem — small enough to train in minutes on standard hardware.

## 2. Architecture

VBAF follows a layered architecture:

- Layer 1: Core neural network with backpropagation
- Layer 2: DQN engine with experience replay and target network
- Layer 3: 13 domain-specific enterprise pillar environments
- Layer 4: AutoPilot — a master agent orchestrating all pillars

Each enterprise pillar observes 4 real-time Windows signals (normalised 0-1)
and selects from 4 ordered response actions.

## 3. The Distribution Formula

The key innovation enabling consistent positive improvement is the
training distribution 15/40/30/15 across severity levels.

This distribution ensures:
- The majority class (40%) creates a strong baseline reward
- The agent cannot achieve positive reward by collapsing to action 0
- Gradient pressure forces exploration of all four actions

## 4. Results

Across all 14 enterprise pillars, VBAF achieves:
- Minimum improvement: +24.5% (CloudBridge, Phase 17)
- Maximum improvement: +117.5% (EnergyOptimizer, Phase 25)
- Mean improvement: +63.5%
- All 14 pillars show positive improvement over random baseline

## 5. Conclusion

VBAF demonstrates that enterprise-grade reinforcement learning is achievable
in PowerShell 5.1 without any external dependencies. The framework is available
on PowerShell Gallery and has been downloaded over 50 times in its first release.
