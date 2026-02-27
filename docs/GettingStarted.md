C:\Users\henni# Getting Started with VBAF

> 🚧 **Placeholder** — full guide coming soon.

## Requirements
- Windows PowerShell 5.1 (not PS Core)
- Git

## Installation

\\\powershell
git clone https://github.com/JupyterPS/VBAF.git
cd VBAF
. .\VBAF.LoadAll.ps1
\\\

## Your first run

\\\powershell
# Train a basic autoencoder on shape patterns
Test-VBAFAutoencoder -Epochs 300 -LR 0.15

# Run a Q-Learning agent on CartPole
 = (Invoke-DQNTraining -Episodes 100 -PrintEvery 10)[-1]
.PrintStats()
\\\

See the [tutorials/](tutorials/README.md) folder for step-by-step guides.


