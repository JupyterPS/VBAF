# Testing Guide

> 🚧 **Placeholder** — full testing guide coming soon.

## Smoke tests

Every module has a \Test-VBAF<Module>\ function:

\\\powershell
Test-VBAFAutoencoder          # VBAF.ML.Autoencoder.ps1
Test-VBAFTransferLearning     # VBAF.ML.TransferLearning.ps1
\\\

## What a passing test looks like

- Loss / accuracy meets documented target
- No PS 5.1 runtime errors
- All visualisation functions render without exception
