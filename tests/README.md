# tests/

> 🚧 **Placeholder** — formal test suite coming in v2.2.0.

## Current testing approach

Each VBAF module ships with a built-in smoke test function:

\\\powershell
Test-VBAFAutoencoder          # VBAF.ML.Autoencoder.ps1
Test-VBAFTransferLearning     # VBAF.ML.TransferLearning.ps1
Invoke-DQNTraining            # VBAF.RL.DQN.ps1
\\\

## Planned

A Pester-compatible test suite will be added here once the API stabilises.
Pester 5.x on PS 5.1 is the target.
