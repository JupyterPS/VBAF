# Example 01: XOR Network

> Runnable script: see \VBAF.Core.Example-XOR.ps1\ in the repo root.

Demonstrates a 2-layer neural network solving the XOR problem from scratch.

## What you'll learn
- Forward pass through a simple network
- Backpropagation by hand
- Effect of learning rate on convergence

## Run it
\\\powershell
. .\VBAF.LoadAll.ps1
. .\VBAF.Core.Example-XOR.ps1
\\\
"@

Write-Placeholder "examples/02-Castle-Learning/README.md" @"
# Example 02: Castle Learning

> Runnable script: see \VBAF.RL.Example-CastleLearning.ps1\ in the repo root.

A Q-Learning agent explores a grid world and learns to build aesthetically
scored castle layouts using a custom reward function.

## What you'll learn
- Q-Table initialisation and update
- Custom reward shaping
- Visualising agent policy

## Run it
\\\powershell
. .\VBAF.LoadAll.ps1
. .\VBAF.RL.Example-CastleLearning.ps1
\\\
"@

Write-Placeholder "examples/03-Market-Simulation/README.md" @"
# Example 03: Multi-Agent Market Simulation

> Runnable script: see \VBAF.Business.Test.CompanyMarket.ps1\ in the repo root.

Multiple company agents compete in a simulated market environment.
Demonstrates emergent competitive and cooperative strategies.

## What you'll learn
- Multi-agent reinforcement learning
- Market environment design
- Reading agent performance dashboards

## Run it
\\\powershell
. .\VBAF.LoadAll.ps1
. .\VBAF.Business.Test.CompanyMarket.ps1
\\\
"@

Write-Placeholder "examples/04-Learning-Dashboard/README.md" @"
# Example 04: Learning Dashboard

> Runnable script: see \VBAF.Visualization.Example-Dashboard.ps1\ in the repo root.

Visualises a Q-Learning agent's training progress in real time using
VBAF's ASCII dashboard (Dashboard 1).

## Run it
\\\powershell
. .\VBAF.LoadAll.ps1
. .\VBAF.Visualization.Example-Dashboard.ps1
\\\
"@

Write-Placeholder "examples/05-Validation-Dashboard/README.md" @"
# Example 05: Validation Dashboard

> Runnable script: see \VBAF.Core.Test-ValidationDashboard.ps1\ in the repo root.

Dashboard 3 — validates core VBAF components and displays a live metrics panel.

## Run it
\\\powershell
. .\VBAF.LoadAll.ps1
. .\VBAF.Core.Test-ValidationDashboard.ps1
\\\
"@

Write-Placeholder "examples/06-Custom-Agent/README.md" @"
# Example 06: Building a Custom Agent

> 🚧 **Placeholder** — example script coming soon.

Will demonstrate how to subclass \VBAFEnvironment\ and create a custom
RL agent using VBAF's modular building blocks.

## What you'll learn
- Subclassing VBAFEnvironment
- Defining custom state/action spaces
- Hooking a DQN agent into a custom environment
