# VBAF — Visual AI & Reinforcement Learning Framework

> **v5.0.0** · PowerShell 5.1 · Educational AI Framework · Learn by doing

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://github.com/PowerShell/PowerShell)
[![PowerShell Gallery](https://img.shields.io/badge/PSGallery-VBAF-blue)](https://www.powershellgallery.com/packages/VBAF)
[![PowerShell Gallery Downloads](https://img.shields.io/powershellgallery/dt/VBAF)](https://www.powershellgallery.com/packages/VBAF)
[![GitHub stars](https://img.shields.io/github/stars/JupyterPS/VBAF)](https://github.com/JupyterPS/VBAF/stargazers)

## Architecture

[![VBAF Architecture](VBAF-Architecture.svg)](https://github.com/JupyterPS/VBAF)

## What is VBAF?

VBAF is a **hands-on educational framework** for learning artificial intelligence and reinforcement learning concepts — written entirely in PowerShell 5.1 that ships with every Windows PC.

No Python. No Jupyter. No cloud dependencies. Just open PowerShell and start learning.

**What you can learn with VBAF:**

- How neural networks learn through backpropagation
- How Q-learning agents discover optimal strategies without being told the rules
- How Deep Q-Networks (DQN) scale reinforcement learning to complex problems
- How multiple agents compete and cooperate in shared environments
- How to normalise, scale and clean data before feeding it to an AI model

**Why PowerShell?**

Because the code is readable. Every function in VBAF is written to be understood — not just executed. You can open any `.ps1` file and see exactly what the algorithm is doing, line by line. That is the point.

---

## Getting Started

| Guide | Who it is for |
|-------|--------------|
| [Quick Start Guide](docs/GettingStarted.md) | Developers who want to get moving fast -- commands first |
| [Learning Trail](docs/GettingStarted-Trail.md) | Complete beginners -- 5 camps, 24 steps, hand-holding all the way |

---

## Quick Start

```powershell
# Install
Install-Module VBAF -Scope CurrentUser

# Navigate to your working folder
cd "C:\Users\<your-name>\OneDrive\WindowsPowerShell"

# Load everything
. .\VBAF.LoadAll.ps1

# Run the XOR example — the classic neural network benchmark
& ".\examples\01-XOR-Network\VBAF.Core.Example-XOR.ps1"

# Watch a Q-learning agent learn castle defence
& ".\examples\02-Castle-Learning\VBAF.RL.Example-CastleLearning.ps1"

# See competing market agents emerge pricing strategies
& ".\examples\03-Market-Simulation\VBAF.Business.Test.CompanyMarket.ps1"
```

---

## Learning Path

Start here and work through in order:

| Step | Example | What you learn |
|------|---------|----------------|
| 1 | [XOR Network](examples/01-XOR-Network/) | Neural networks, backpropagation, convergence |
| 2 | [Castle Learning](examples/02-Castle-Learning/) | Q-learning, rewards, emergent strategy |
| 3 | [Market Simulation](examples/03-Market-Simulation/) | Multi-agent competition, Nash equilibrium |
| 4 | [Learning Dashboard](examples/04-Learning-Dashboard/) | Visualising training progress |
| 5 | [Validation Dashboard](examples/05-Validation-Dashboard/) | Evaluating model quality |
| 6 | [Custom Agent](examples/06-Custom-Agent/) | Build your own RL environment |

---

## Documentation

| Document | Description |
|----------|-------------|
| [Quick Start](docs/GettingStarted.md) | Developers -- commands first, get moving fast |
| [Learning Trail](docs/GettingStarted-Trail.md) | Beginners -- 5 camps, 24 steps, hand-holding all the way |
| [Theory](docs/Theory.md) | The AI/RL concepts behind VBAF explained simply |
| [API Reference](docs/API-Reference.md) | All functions, parameters and return values |
| [Architecture](docs/Architecture.md) | How the framework is structured |
| [FAQ](docs/FAQ.md) | Common questions and answers |
| [Tutorials](docs/tutorials/) | Step-by-step walkthroughs |
| [Teaching Materials](docs/teaching/) | Course outlines, exam questions, semester plans |
| [Case Studies](docs/case-studies/) | Real learning experiments and results |
| [Benchmarks](benchmarks/) | Performance data and learning curves |

---

## What is in the box?

### Core AI modules

| Module | What it teaches |
|--------|----------------|
| `VBAF.Core.AllClasses.ps1` | Neural network architecture — layers, weights, activations |
| `VBAF.Core.Training.ps1` | Backpropagation — how networks learn from errors |
| `VBAF.Core.Validation.ps1` | Evaluation — how to measure if a model is actually good |
| `VBAF.Core.Preprocessing.ps1` | Data preparation — scaling, normalisation, missing values |

### Reinforcement learning modules

| Module | What it teaches |
|--------|----------------|
| `VBAF.RL.QAgent.ps1` | Q-learning — the foundation of modern RL |
| `VBAF.RL.DQNAgent.ps1` | Deep Q-Networks — combining neural nets with RL |
| `VBAF.RL.MultiAgent.ps1` | Multi-agent systems — competition and cooperation |
| `VBAF.RL.Environment.ps1` | Environments — how agents observe and act |

### Visualisation

| Module | What it teaches |
|--------|----------------|
| `VBAF.Visualization.Dashboard.ps1` | How to track and display learning progress |
| `VBAF.Art.CastleCompetition.ps1` | Visualising multi-agent competition |

---

## The XOR benchmark

XOR is the classic test of whether a neural network can learn non-linear patterns.
A linear model cannot solve it — you need at least one hidden layer.

```powershell
. .\VBAF.LoadAll.ps1
& ".\examples\01-XOR-Network\VBAF.Core.Example-XOR.ps1"

# Expected output:
# XOR Truth Table:
#   0 XOR 0 = 0  (predicted: 0.02)
#   0 XOR 1 = 1  (predicted: 0.97)
#   1 XOR 0 = 1  (predicted: 0.96)
#   1 XOR 1 = 0  (predicted: 0.03)
# Epochs: 847  Loss: 0.008
```

If you see predictions close to 0 and 1 — the network learned. That is backpropagation working.

---

## The Castle Learning experiment

Two agents compete: Builder places walls and towers. Attacker probes for weaknesses.
Neither is given a strategy. Optimal defence and attack patterns emerge from experience alone.

```powershell
& ".\examples\02-Castle-Learning\VBAF.RL.Example-CastleLearning.ps1"

# Watch the scores evolve:
# Episode 1:   Builder: -45  Attacker: +12
# Episode 50:  Builder: -12  Attacker: -8
# Episode 100: Builder: +18  Attacker: -22
# Castle defence learned — no gaps in perimeter
```

This is reinforcement learning in its purest form — learning from reward signals, not from labelled examples.


---

## Beyond the basics — Enterprise Automation

Once you understand the foundation phases (1-9), VBAF includes 14 enterprise pillars built on the same core — each one a working DQN agent solving a real IT automation problem.

These are not teaching examples. They are production-grade agents that emerged from the same learning concepts you studied in Phase 1-9. Read them when you are ready to see where the fundamentals lead.

| Phase | Pillar | What it automates | Improvement |
|-------|--------|------------------|-------------|
| 14 | Self-Healing | Detects and fixes system problems automatically | +63.0% |
| 15 | Dashboard | Intelligent cache and refresh management | +59.1% |
| 16 | Federated Learning | Distributed model training across nodes | +62.1% |
| 17 | Cloud Bridge | Local vs cloud workload balancing | +24.5% |
| 18 | Anomaly Detector | Spots unusual patterns before they become incidents | +30.6% |
| 19 | Capacity Planner | Predicts resource needs before you run out | +32.6% |
| 20 | Incident Responder | Automated incident triage and containment | +26.9% |
| 21 | Compliance Reporter | GDPR/ISO27001 compliance monitoring | +107.2% |
| 22 | User Behavior Analytics | Detects insider threats and anomalous access | +103.4% |
| 23 | Patch Intelligence | Risk-aware patch scheduling and rollback | +65.5% |
| 24 | Backup Optimizer | Adaptive backup strategy optimisation | +116.3% |
| 25 | Energy Optimizer | Reduces power consumption intelligently | +117.5% |
| 26 | Multi-Site Coordinator | Cross-datacenter workload balancing | +47.4% |
| 27 | AutoPilot | Orchestrates all 13 pillars simultaneously | +63.3% |

The improvement figures are measured against a random dispatcher baseline — the same evaluation method used throughout the foundation phases.

**The learning ladder:**
```
Phase 1-9   — Foundation: understand HOW agents learn
Phase 10-27 — Enterprise: see WHAT agents can do
```

Study the foundation first. Then open any enterprise file and trace exactly which foundation concepts it uses. The code is the curriculum.

---

## Requirements

- Windows 10 or 11
- PowerShell 5.1 (included with Windows — no install needed)
- No Python, no Jupyter, no cloud account, no dependencies

---

## For teachers

VBAF is designed to be taught. The `docs/teaching/` folder contains:

- A full 4-week course outline with session plans and lab exercises
- Weekly lab exercises with working PowerShell code
- Exam questions at beginner, intermediate and advanced levels
- Suggested reading alongside each topic

Every example is written to be projected on a classroom screen and understood immediately.

---

## Version history

| Version | Highlight |
|---------|-----------|
| v5.0.0 | Repositioned as educational framework — new era |
| v4.0.0 | AutoPilot — 27 phases, 14 enterprise pillars complete |
| v3.5.0 | Self-healing agents — first enterprise phase |
| v2.0.0 | DQN agents — deep reinforcement learning |
| v1.0.0 | Q-learning foundation |

---

## License

MIT License — see [LICENSE](LICENSE) for details.
Free to use, teach, modify and share.

## Author

**Henning** · Roskilde, Denmark 🇩🇰  
Built with Claude (Anthropic) · PowerShell ISE · PS 5.1

*"The best way to understand AI is to build it yourself — line by line."*
