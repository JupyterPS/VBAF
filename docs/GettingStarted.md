# Getting Started with VBAF

## Requirements

- Windows 10 or 11
- PowerShell 5.1 (included with Windows — no install needed)
- No Python, no dependencies, no internet after install

## Installation
```powershell
Install-Module VBAF -Scope CurrentUser
```

Or clone from GitHub:
```powershell
git clone https://github.com/JupyterPS/VBAF.git
cd VBAF
. .\VBAF.LoadAll.ps1
```

## Your First Agent — 60 Seconds
```powershell
. .\VBAF.LoadAll.ps1

# Run the AutoPilot — orchestrates all 13 enterprise pillars
$r = Invoke-VBAFAutoPilotTraining -Episodes 100 -PrintEvery 10 -SimMode
```

Expected output:
```
Phase 1: Baseline (random agent)...  avg reward: -120
Phase 2: Training DQN agent...
  Ep  10/100  AvgReward: -115
  Ep  50/100  AvgReward:  -80
  Ep 100/100  AvgReward:  -55
Phase 3: Evaluation...  avg reward: -44
Improvement: +63.3%
```

## Try the Tutorials
```powershell
& ".\tutorials\02_Beginner_FirstClassifier.ps1"
& ".\tutorials\06_Beginner_Regression.ps1"
& ".\tutorials\12_Enterprise_YourFirstDQN.ps1"
```

## Quick Reference

See [VBAF.CheatSheet.md](../VBAF.CheatSheet.md) for all functions and parameters on one page.

## Next Steps

- Read [Architecture.md](Architecture.md) to understand how VBAF is structured
- Read [Theory.md](Theory.md) to understand the reinforcement learning concepts
- Browse [case-studies/](case-studies/) to see real-world applications
