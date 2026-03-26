# 04 — Multi-Agent Market Simulation

## What You Will Learn

- How multiple agents interact in a shared environment
- How competition and cooperation emerge from simple rules
- How to read a market simulation dashboard

## Concept

The VBAF market simulation runs multiple company agents in the same environment.
Each agent has its own Q-table and learns independently.
The emergent behaviour — pricing wars, market dominance, cooperation — arises
from the individual agents all optimising their own reward.

## Running the Simulation
```powershell
. .\VBAF.LoadAll.ps1
& ".\VBAF.Business.Test.CompanyMarket.ps1"
```

## Reading the Output

- Market share: percentage of total sales each company captures
- Profit: revenue minus costs for each episode
- Strategy: the action each company takes most frequently

## Key Insight

No company is programmed with a strategy. The strategy emerges from learning.
A company that learns to undercut competitors gains market share,
which forces competitors to adapt — exactly like real markets.

## Next Step

[05 — Custom Environment](05-Custom-Environment.md)
