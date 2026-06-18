# Example 03: Market Simulation

Four companies compete for market share over 10 simulated years.
No strategy is programmed. Price wars, innovation races and tacit
collusion emerge entirely from Q-learning agents optimising their rewards.

## Why This Example?

Examples 01 and 02 had one agent learning alone.
This is different -- four agents learn simultaneously in a shared environment.
Every agent's actions change the environment for all other agents.
This is multi-agent reinforcement learning.

It is also economics. The same emergent behaviours studied in game theory
and oligopoly models appear here -- without any equations being programmed.

## The Four Competitors

  TechCorp:     1,000,000 capital -- balanced start
  InnovateCo:   1,000,000 capital -- same as TechCorp
  MarketLeader: 1,500,000 capital + 15% market share -- established player
  StartupX:       800,000 capital -- underdog, no market share

MarketLeader has the advantage at t=0.
Does it maintain dominance or do the others catch up?
The outcome varies every run -- that is the point.

## What To Watch For

Price war:
  Companies undercut each other on price to gain market share.
  Detected when average price varies widely across companies.
  Hurts everyone -- a classic prisoner's dilemma.

Tacit collusion:
  Companies independently learn to avoid price wars.
  Prices converge without any communication.
  Emerges because mutual price cuts reduce everyone's profit.

Innovation race:
  Companies invest in R&D to gain product advantage.
  Emerges when Q-learning discovers innovation beats price cuts.

Market segmentation:
  Companies find niches where they dominate.
  Emerges when direct competition becomes too costly.

## The Herfindahl Index

  H = sum of (market_share ^ 2) for all companies
  H > 0.25 -- one company dominates (monopoly tendency)
  H < 0.15 -- competitive market (evenly distributed)

Named after economists Herfindahl and Hirschman.
Used by regulators worldwide to measure market concentration.
VBAF computes it automatically and flags consolidation.

## What To Watch While It Runs

  Year 1:  agents exploring randomly, market share shifting unpredictably
  Year 5:  strategies emerging, price patterns becoming visible
  Year 10: strategies converged, emergent behaviours clearly visible

If epsilon < 0.15 at the end -- agents found stable strategies.
If epsilon is still high -- run for 100+ quarters to see full convergence.

## Run It

```powershell
cd "C:\Users\henni\OneDrive\WindowsPowerShell\examples\03-Market-Simulation"
. .\Run-Example-03.ps1
```

## Expected Output
YEAR 2 COMPLETE - MARKET REPORT

Most Profitable : MarketLeader ($124,000)

Market Leader   : MarketLeader (18.4% share)

Best Learner    : TechCorp (reward: 312)
YEAR 10 COMPLETE - MARKET REPORT

Most Profitable : InnovateCo ($287,000)

Market Leader   : InnovateCo (29.1% share)

Best Learner    : InnovateCo (reward: 891)
EMERGENT BEHAVIOUR ANALYSIS

TACIT COLLUSION DETECTED

INNOVATION RACE DETECTED

Herfindahl Index: 0.198 -- BALANCED COMPETITION

STRATEGIES CONVERGED -- all agents found stable strategies

## What To Try Next

1. Run for 100+ quarters -- watch strategies fully converge
2. Change StartupX capital to 2,000,000 -- does the underdog win?
3. Give all companies equal starting capital -- pure skill test
4. Move on to examples\04-Learning-Dashboard\ -- visualising training

## Key Concepts

- Multi-agent reinforcement learning (independent learners)
- Emergent behaviour without programmed rules
- Game theory -- Nash equilibrium, prisoner's dilemma
- Herfindahl-Hirschman Index (market concentration)
- Oligopoly dynamics (Cournot competition)

## Files

- `Run-Example-03.ps1` -- run this to start the example
- `VBAF.Business.Test.CompanyMarket.ps1` -- full simulation with educational comments
- Source: `..\..\VBAF.Business.CompanyAgent.ps1` -- company agent class
- Source: `..\..\VBAF.Business.MarketEnvironment.ps1` -- market environment class
