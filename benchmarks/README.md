# VBAF Benchmarks

Reproducible benchmarks for VBAF algorithms and enterprise pillars.
All benchmarks run on Windows 10/11, PowerShell 5.1, no external dependencies.

---

## Results Summary

| Benchmark | Metric | Result | Status |
|-----------|--------|--------|--------|
| Enterprise pillars (26) | Beat the best fixed action on all 3 seeds | 22 of 26 | re-measured for v5.0 |
| Enterprise pillars (26) | Trained minus best fixed action (pillars that learn) | +146 to +404 | re-measured for v5.0 |
| XOR 2-3-1 (official example settings, seed 1) | Accuracy | 100% | locked in tests\Test-VBAF.ps1 |
| XOR convergence | Epochs to 99% accuracy | 847 +/- 23 | v4 figure, not re-measured |
| Q-Learning agent | Episodes to stable policy | 150-300 | v4 figure, not re-measured |

The old pillar figures ("+63% to +117% over random") are withdrawn: they measured one fixed action against random
choices, not learning. See [agent-learning-curves.md](agent-learning-curves.md) for what changed and the full table.

---

## Running Benchmarks

```powershell
. .\VBAF.LoadAll.ps1

# Every enterprise pillar, measured honestly (random / every fixed action / trained agent, same episodes)
.\benchmarks\Measure-VBAFPillars.ps1 -OutDir C:\Temp\pillars -Episodes 30 -Seeds 1,2,3 -EvalEpisodes 10

# A quick timing dry run first (about 13 minutes)
.\benchmarks\Measure-VBAFPillars.ps1 -OutDir C:\Temp\pillars-dry -Episodes 1 -Seeds 1 -EvalEpisodes 2

# Quick benchmark -- DQN vs random baseline
Invoke-VBAFQuickBenchmark -AgentName "DQN" -Environment "CartPole" -Episodes 50

# Compare DQN, PPO and A3C head to head
Invoke-VBAFAgentBenchmark -Agents @("DQN","PPO","A3C") -Episodes 100
```

---

## Benchmark Files

| File | Contents |
|------|----------|
| [Measure-VBAFPillars.ps1](Measure-VBAFPillars.ps1) | Re-measures every enterprise pillar (resumable) |
| [agent-learning-curves.md](agent-learning-curves.md) | Enterprise pillars (v5.0), DQN and Q-learning |
| [xor-convergence.md](xor-convergence.md) | XOR network convergence data |
| [performance-comparison.md](performance-comparison.md) | Algorithm comparison table |
| [data/pillars-v5.0/](data/pillars-v5.0/) | Raw data of the v5.0 pillar measurement |

---

*github.com/JupyterPS/VBAF · Install-Module VBAF · Built in Denmark*
