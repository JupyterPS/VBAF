# tests/

> 🚧 **Placeholder** — formal test suite coming in v2.2.0.

## Current testing approach

Every VBAF module ships with a built-in smoke test:

```powershell
Test-VBAFAutoencoder        # VBAF.ML.Autoencoder.ps1
Test-VBAFTransferLearning   # VBAF.ML.TransferLearning.ps1
```

## Planned

A Pester-compatible test suite will be added once the API stabilises.
Target: Pester 5.x on PS 5.1.
