# VBAF Benchmarks

Reproducible performance benchmarks for all VBAF algorithms and enterprise pillars.
All benchmarks run on Windows 10/11, PowerShell 5.1, no external dependencies.

## Results Summary

| Benchmark | Metric | Result |
|-----------|--------|--------|
| XOR convergence | Epochs to 99% accuracy | 847 ± 23 |
| DQN vs random | Average improvement | +63% to +117% |
| Q-Learning agent | Episodes to stable policy | 150–300 |
| Enterprise pillars | Best improvement (Phase 25) | +117.5% |

## Running Benchmarks
```powershell
. .\VBAF.LoadAll.ps1
```

## Files

| File | Description |
|------|-------------|
| [agent-learning-curves.md](agent-learning-curves.md) | Q-Learning and DQN convergence speed |
| [performance-comparison.md](performance-comparison.md) | Training time and memory across model types |
| [xor-convergence.md](xor-convergence.md) | XOR network epochs to convergence |

## Methodology

All benchmarks use fixed random seeds for reproducibility.
Results are averaged across 10 independent runs.
Hardware: standard Windows laptop, no GPU required.

