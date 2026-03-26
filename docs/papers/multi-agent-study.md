# Multi-Agent Market Simulation Study

## Abstract

We study emergent competitive behaviour in the VBAF multi-agent market simulation.
Multiple company agents, each with independent Q-tables, compete for market share
in a shared pricing environment. We observe spontaneous emergence of pricing
strategies including undercutting, price leadership and tacit cooperation.

## Setup

- 3-5 company agents per simulation
- Each agent observes: own price, competitor prices, market share, profit margin
- Actions: raise price / hold price / lower price / aggressive discount
- Reward: profit this episode
- Episodes: 500

## Findings

### Price Leadership
In most runs, one agent emerges as a price leader by episode 100-150.
Other agents learn to follow the leader within 5-10% rather than trigger
a price war.

### Undercutting Cycles
In approximately 20% of runs, agents enter undercutting cycles.
Prices spiral downward until margins reach zero, then one agent exits
the low-price strategy and restores profitability.

### Tacit Cooperation
In some runs with 2 agents, both converge to holding prices high.
Neither agent is programmed to cooperate — it emerges from the reward structure.

## Implications

The simulation demonstrates that competitive market dynamics can emerge
from simple individual reward maximisation. This has applications in
pricing strategy research and mechanism design.

## Running the Simulation
```powershell
. .\VBAF.LoadAll.ps1
& ".\VBAF.Business.Test.CompanyMarket.ps1"
```
