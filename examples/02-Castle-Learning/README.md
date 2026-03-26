# Example 02: Castle Learning

Two competing Q-learning agents — Builder and Attacker — play thousands of
castle defence games. Neither agent is programmed with a strategy.
Optimal defence and attack patterns emerge entirely from reinforcement learning.

## What It Does

- Builder places walls, towers and gates to maximise defence score
- Attacker probes for weaknesses to maximise breach score
- Both agents improve simultaneously through competition

## Run It
```powershell
. .\VBAF.LoadAll.ps1
& ".\VBAF.RL.Example-CastleLearning.ps1"
```

## Expected Output
```
Episode 1:   Builder: -45  Attacker: +12
Episode 50:  Builder: -12  Attacker: -8
Episode 100: Builder: +18  Attacker: -22
Castle defence learned — no gaps in perimeter
```

## Key Concepts

- Competitive multi-agent reinforcement learning
- Emergent strategy without hardcoded rules
- Q-table learning in a discrete action space

## Files

- `VBAF.RL.Example-CastleLearning.ps1` — main example
- `VBAF.Art.CastleCompetition.ps1` — visualisation
- See [docs/case-studies/castle-generation.md](../../docs/case-studies/castle-generation.md)
