# Example 03: Market Simulation

Multiple company agents compete for market share in a shared pricing environment.
Emergent behaviours include price leadership, undercutting cycles and
tacit cooperation — none of which are programmed directly.

## What It Does

- 3-5 company agents each set prices and production levels
- Each agent learns to maximise its own profit
- Market dynamics emerge from individual agent decisions

## Run It
```powershell
. .\VBAF.LoadAll.ps1
& ".\VBAF.Business.Test.CompanyMarket.ps1"
& ".\VBAF.Business.Dashboard-Demo.ps1"
```

## Expected Output
```
Episode 100:
  Company A: share=34%  profit=+8.2
  Company B: share=41%  profit=+9.1
  Company C: share=25%  profit=+5.8
Price leader: Company B
```

## Key Concepts

- Multi-agent Q-learning in a competitive environment
- Emergent market dynamics
- Independent learners with shared environment

## Files

- `VBAF.Business.Test.CompanyMarket.ps1` — simulation
- `VBAF.Business.Dashboard-Demo.ps1` — visualisation
- See [docs/papers/multi-agent-study.md](../../docs/papers/multi-agent-study.md)
