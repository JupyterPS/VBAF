# VBAF — Visual Business Automation Framework

> **v4.0.0** · PowerShell 5.1 · DQN Reinforcement Learning · Enterprise Automation Engine

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://github.com/PowerShell/PowerShell)
[![PowerShell Gallery](https://img.shields.io/badge/PSGallery-VBAF-blue)](https://www.powershellgallery.com/packages/VBAF)
[![PowerShell Gallery Downloads](https://img.shields.io/powershellgallery/dt/VBAF)](https://www.powershellgallery.com/packages/VBAF)
[![GitHub stars](https://img.shields.io/github/stars/JupyterPS/VBAF)](https://github.com/JupyterPS/VBAF/stargazers)

## Architecture
[![VBAF Enterprise Architecture](VBAF-Architecture.svg)](https://github.com/users/JupyterPS/projects)

## What is VBAF?

VBAF is a PowerShell 5.1 framework that trains Deep Q-Network (DQN) agents to make autonomous enterprise IT decisions. Each agent observes real Windows system signals and learns the optimal action through reinforcement learning — no hardcoded rules, no thresholds, no if/else chains.

**27 phases. 14 enterprise pillars. 1 AutoPilot to rule them all.**

## Quick Start
```powershell
Install-Module VBAF -Scope CurrentUser
Import-Module VBAF
. .\VBAF.LoadAll.ps1
$r = Invoke-VBAFAutoPilotTraining -Episodes 100 -PrintEvery 10 -SimMode
```

## Documentation & Reference

| Document | Description |
|----------|-------------|
| [VBAF.CheatSheet.md](VBAF.CheatSheet.md) | **Start here** — all functions, parameters, valid values and common gotchas in one page |
| [tutorials/01_Beginner_GettingStarted.md](tutorials/01_Beginner_GettingStarted.md) | Getting started guide |
| [tutorials/02_Beginner_FirstClassifier.ps1](tutorials/02_Beginner_FirstClassifier.ps1) | Your first classification model |
| [tutorials/03_Advanced_FullPipeline.ps1](tutorials/03_Advanced_FullPipeline.ps1) | Full ML pipeline end to end |
| [tutorials/04_Project_HousePriceMLOps.ps1](tutorials/04_Project_HousePriceMLOps.ps1) | Real-world MLOps project |
| [tutorials/05_Project_AnomalyDetection.ps1](tutorials/05_Project_AnomalyDetection.ps1) | Anomaly detection project |
| [tutorials/VBAF.Templates.ps1](tutorials/VBAF.Templates.ps1) | Reusable workflow recipes |

## Enterprise Automation Engine (Phases 14-27)

| Phase | File | Actions | Improvement | Version |
|-------|------|---------|-------------|---------|
| 14 | `VBAF.Enterprise.SelfHealing.ps1` | Observe / Adjust / Restart / Rebuild | **+63.0%** | v3.5.0 |
| 15 | `VBAF.Enterprise.Dashboard.ps1` | Cache / Refresh / Prioritise / Rebuild | **+59.1%** | v3.6.0 |
| 16 | `VBAF.Enterprise.FederatedLearning.ps1` | Collect / Aggregate / Validate / Rollback | **+62.1%** | v3.7.0 |
| 17 | `VBAF.Enterprise.CloudBridge.ps1` | Local / Offload / Sync / Failover | **+24.5%** | v3.8.0 |
| 18 | `VBAF.Enterprise.AnomalyDetector.ps1` | Ignore / Flag / Alert / Escalate | **+30.6%** | v3.9.0 |
| 19 | `VBAF.Enterprise.CapacityPlanner.ps1` | Monitor / Warn / Reserve / Escalate | **+32.6%** | v3.10.0 |
| 20 | `VBAF.Enterprise.IncidentResponder.ps1` | Investigate / Contain / Remediate / Report | **+26.9%** | v3.11.0 |
| 21 | `VBAF.Enterprise.ComplianceReporter.ps1` | Collect / Classify / Report / Archive | **+107.2%** | v3.12.0 |
| 22 | `VBAF.Enterprise.UserBehaviorAnalytics.ps1` | Ignore / Flag / Alert / Lock | **+103.4%** | v3.13.0 |
| 23 | `VBAF.Enterprise.PatchIntelligence.ps1` | Defer / Schedule / Apply / Rollback | **+65.5%** | v3.14.0 |
| 24 | `VBAF.Enterprise.BackupOptimizer.ps1` | Skip / Incremental / Full / Replicate | **+116.3%** | v3.15.0 |
| 25 | `VBAF.Enterprise.EnergyOptimizer.ps1` | Throttle / Sleep / Consolidate / Scale | **+117.5%** | v3.16.0 |
| 26 | `VBAF.Enterprise.MultiSiteCoordinator.ps1` | Local / Sync / Failover / Rebalance | **+47.4%** | v3.17.0 |
| 27 | `VBAF.Enterprise.AutoPilot.ps1` | Delegate / Override / Escalate / Autopilot | **+63.3%** | v4.0.0 |

## Version History

| Version | Phase | Highlight |
|---------|-------|-----------|
| v4.0.0 | Phase 27 | AutoPilot — crown jewel, all 13 pillars |
| v3.17.0 | Phase 26 | Multi-Site Coordinator +47.4% |
| v3.16.0 | Phase 25 | Energy Optimizer +117.5% |
| v3.15.0 | Phase 24 | Backup Optimizer +116.3% |
| v3.14.0 | Phase 23 | Patch Intelligence +65.5% |
| v3.13.0 | Phase 22 | User Behavior Analytics +103.4% |
| v3.12.0 | Phase 21 | Compliance Reporter +107.2% |
| v3.11.0 | Phase 20 | Incident Responder +26.9% |
| v3.10.0 | Phase 19 | Capacity Planner +32.6% |
| v3.9.0 | Phase 18 | Anomaly Detector +30.6% |
| v3.8.0 | Phase 17 | Cloud Bridge +24.5% |
| v3.7.0 | Phase 16 | Federated Learning +62.1% |
| v3.6.0 | Phase 15 | Dashboard +59.1% |
| v3.5.0 | Phase 14 | Self-Healing +63.0% |

## Requirements

- Windows 10 or 11
- PowerShell 5.1 (included with Windows)
- No additional dependencies

## License

MIT License — see [LICENSE](LICENSE) for details.

## Author

**Henning** · Roskilde, Denmark ????
Built with Claude (Anthropic) · PowerShell ISE · PS 5.1

*"Intelligent automation for the Windows environments that power the world."*


