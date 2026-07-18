# VBAF Benchmarks

Reproducible performance benchmarks for all VBAF algorithms and enterprise pillars.
All benchmarks run on Windows 10/11, PowerShell 5.1, no external dependencies.

---

## Results Summary

| Benchmark | Metric | Result |
|-----------|--------|--------|
| XOR convergence | Epochs to 99% accuracy | 847 +/- 23 |
| DQN vs random | Average improvement | +63% to +117% |
| Q-Learning agent | Episodes to stable policy | 150-300 |
| Enterprise pillars | Best improvement (Phase 25) | +117.5% |

---

## Running Benchmarks

```powershell
. .\VBAF.LoadAll.ps1

# Quick benchmark -- DQN vs random baseline
Invoke-VBAFQuickBenchmark -AgentName "DQN" -Environment "CartPole" -Episodes 50

# Compare DQN, PPO and A3C head to head
Invoke-VBAFAgentBenchmark -Agents @("DQN","PPO","A3C") -Episodes 100

# Run any enterprise pillar and see improvement
$r = Invoke-VBAFAutoPilotTraining -Episodes 100 -SimMode
Write-Host "Improvement: $(($r.Trained.Avg - $r.Baseline.Avg) / [Math]::Abs($r.Baseline.Avg) * 100)%"
```

---

## Benchmark Files

| File | Contents |
|------|----------|
| [xor-convergence.md](xor-convergence.md) | XOR network convergence data |
| [agent-learning-curves.md](agent-learning-curves.md) | DQN, PPO, A3C learning curves |
| [performance-comparison.md](performance-comparison.md) | Algorithm comparison table |
| [data/](data/) | Raw benchmark data |

---

*github.com/JupyterPS/VBAF · Install-Module VBAF · Built in Denmark*
