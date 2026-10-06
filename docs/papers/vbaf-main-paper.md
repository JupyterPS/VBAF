# VBAF: Visual Business Automation Framework

## Erratum (October 2026, VBAF v5.0)

The original text below is kept unchanged. Read it with these corrections:

1. **The results in the Abstract and Section 4 are withdrawn.** Before v5.0 the DQN agents did not learn: the output
   layer could not represent the rewards and experience replay trained on overwritten data (kernel findings KF-1 and
   KF-4). The "improvement over random" figures measured one fixed action against random choices.
2. **Section 3 does not describe a learning mechanism.** The 15/40/30/15 distribution makes one fixed action beat random
   choices; that is why every pillar showed a positive "improvement" without learning anything.
3. **Layers 3 and 4.** The pillars run on only 11 distinct environments (KF-5), and AutoPilot does not read the other
   pillars: it decides from 4 simulated aggregate signals.
4. **Corrected results.** Re-measured on v5.0 against the honest bar -- the BEST FIXED ACTION -- with 3 training seeds:
   22 of 26 pillars beat the best fixed action on every seed, by +146 (SecurityMonitor) to +404 (IncidentResponder) reward points (mean over
   seeds). Four pillars do not yet: AlertRouter, JobScheduler, ResourceOptimizer and SupplyChain. Method, table and raw
   data: [benchmarks/agent-learning-curves.md](../../benchmarks/agent-learning-curves.md).

---

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
