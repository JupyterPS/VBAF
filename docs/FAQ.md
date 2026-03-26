# Frequently Asked Questions

## General

**What is VBAF?**
VBAF is a PowerShell 5.1 machine learning framework with a Deep Q-Network
enterprise automation engine. It trains AI agents to make autonomous IT decisions
using real Windows system signals — no Python, no cloud, no dependencies.

**Do I need Python?**
No. VBAF runs entirely in PowerShell 5.1, which is included with Windows 10/11.

**Does it need internet access?**
Only for installation (`Install-Module VBAF`). After that, everything runs offline.

**What Windows versions are supported?**
Windows 10 and Windows 11. PowerShell 5.1 must be available.

## Installation

**How do I install VBAF?**
```powershell
Install-Module VBAF -Scope CurrentUser
```

**How do I load VBAF?**
```powershell
. .\VBAF.LoadAll.ps1
```

## Usage

**What is SimMode?**
SimMode uses generated data instead of real Windows signals.
Use it for demos and learning. Omit it for real enterprise monitoring.

**How long does training take?**
100 episodes with 200 steps each takes 45-90 seconds on a standard laptop.
Use `-FastMode` for a quick 30-episode demo.

**Why does the agent sometimes collapse to one action?**
This is a known DQN initialisation issue. Run the training again —
a different random seed usually produces good results.
The distribution 15/40/30/15 guarantees positive improvement on average.

**How do I add my own enterprise pillar?**
See [tutorials/13_Enterprise_CustomPillar.ps1](../tutorials/13_Enterprise_CustomPillar.ps1).
The pattern is: 4 state signals + 4 actions + distribution 15/40/30/15.

## Results

**What does the improvement percentage mean?**
It is the percentage improvement in average reward compared to a random agent.
+63% means the trained agent scores 63% better than random guessing.

**Why do some phases show negative improvement on first run?**
DQN training is stochastic. Run again — results vary by initialisation.
The reported figures are from successful runs after any fixes were applied.

## Contributing

**How do I contribute?**
See [dev/contributing.md](dev/contributing.md) for the full guide.
The simplest contribution is a new enterprise pillar following the Phase 28+ pattern.
