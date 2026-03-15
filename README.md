# VBAF - Visual Business Automation Framework

> **v4.0.0** · PowerShell 5.1 · DQN Reinforcement Learning · Enterprise Automation Engine

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/VBAF.svg)](https://www.powershellgallery.com/packages/VBAF)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/VBAF.svg)](https://www.powershellgallery.com/packages/VBAF)
[![GitHub stars](https://img.shields.io/github/stars/JupyterPS/VBAF.svg)](https://github.com/JupyterPS/VBAF/stargazers)

---

## Architecture

[![VBAF Enterprise Architecture](VBAF-Architecture.svg)](https://github.com/users/JupyterPS/projects)

---

## What is VBAF?

VBAF is a PowerShell 5.1 framework that trains Deep Q-Network (DQN) agents to make autonomous enterprise IT decisions. Each agent observes real Windows system signals and learns the optimal action through reinforcement learning - no hardcoded rules, no thresholds, no if/else chains.

**27 phases. 14 enterprise pillars. 1 AutoPilot to rule them all.**

---

## Quick Start

Install-Module VBAF -Scope CurrentUser

. .\VBAF.LoadAll.ps1

$r = Invoke-VBAFAutoPilotTraining -Episodes 100 -PrintEvery 10 -SimMode

---

## Two Entry Points

| Loader | Purpose |
|--------|---------|
| VBAF.LoadAll.ps1 | Full Enterprise Engine - all 27 phases |
| VBAF.LoadCore.ps1 | Core algorithms only - DQN, Neural Networks, RL |

Core for builders. All for operators.

---

## Enterprise Automation Engine (Phases 14-27)

| Phase | Pillar | Improvement |
|-------|--------|-------------|
| 14 | Self-Healing Infrastructure | +63.0% |
| 15 | Enterprise Dashboard | +59.1% |
| 16 | Federated Learning | +62.1% |
| 17 | Cloud Bridge | +24.5% |
| 18 | Anomaly Detector | +30.6% |
| 19 | Capacity Planner | +32.6% |
| 20 | Incident Responder | +26.9% |
| 21 | Compliance Reporter | +107.2% |
| 22 | User Behavior Analytics | +103.4% |
| 23 | Patch Intelligence | +65.5% |
| 24 | Backup Optimizer | +116.3% |
| 25 | Energy Optimizer | +117.5% |
| 26 | Multi-Site Coordinator | +47.4% |
| 27 | AutoPilot - Crown Jewel | +63.3% |

---

## Version History

| Version | Phase | Highlight |
|---------|-------|-----------|
| v4.0.0 | Phase 27 | AutoPilot - crown jewel, all 13 pillars |
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

---

## Requirements

- Windows 10 or 11
- PowerShell 5.1 (included with Windows)
- No additional dependencies

---

## License

MIT License - see LICENSE for details.

---

## Author

**Henning** - Roskilde, Denmark

Built with Claude (Anthropic) - PowerShell ISE - PS 5.1

*"Intelligent automation for the Windows environments that power the world."*
