# Example 06: Custom Agent

Build your own enterprise automation pillar from scratch.
This is the template and walkthrough for Phase 28 and beyond.
Every Phase 14-27 pillar in VBAF was built using exactly this pattern.

## The VBAF Pillar Pattern

Every enterprise pillar follows five rules:

  Rule 1 -- 4 state signals (0.0 to 1.0) from real Windows data
  Rule 2 -- 4 actions ordered by severity (low -> high response)
  Rule 3 -- Reward: +2 correct, -1 dist=1, -2 dist=2, -3 dist=3
  Rule 4 -- Distribution 15/40/30/15 -- math-proven formula
  Rule 5 -- No inversion needed -- distribution does the work

## What This Example Builds

Phase 28: Network Traffic Manager

  State signals:
    BandwidthUsage  -- 0=idle,       1=saturated
    PacketLoss      -- 0=no loss,    1=high loss
    Latency         -- 0=low,        1=high
    ConnectionCount -- 0=few,        1=many

  Actions (ordered by severity):
    0 = Monitor   -- watch, no action needed
    1 = Throttle  -- slow down traffic, reduce load
    2 = Reroute   -- redirect traffic to other paths
    3 = Block     -- emergency block, critical threat

The agent learns to match action severity to state severity.
Nobody programs which action to use when -- the DQN discovers it.

## The Distribution 15/40/30/15

This is the key insight behind all VBAF enterprise pillars.

  15% of steps: severity 0 (normal)
  40% of steps: severity 1 (elevated)
  30% of steps: severity 2 (high)
  15% of steps: severity 3 (critical)

Why this distribution?
A random agent scores negative on average (wrong actions cost -1 to -3).
A trained agent scores positive (correct actions earn +2).
The gap between random and trained is always measurable improvement.
This guarantees that training always produces a detectable result.

## What To Watch While It Runs

Phase 1 -- Baseline:
  Random agent, negative average reward.
  This is the floor -- trained agent must beat this.

Phase 2 -- Training (30 episodes):
  Watch AvgReward climb from negative toward positive.
  Watch Epsilon decay from ~1.0 toward 0.05.
  Watch action counts -- early episodes show all four actions randomly,
  later episodes show the agent preferring matched responses.

Phase 3 -- Evaluation:
  Epsilon set to 0.0 -- pure exploitation, no random actions.
  Trained avg reward should be significantly higher than baseline.
  Improvement % confirms learning worked.

## Adapting The Pattern To Your Domain

To build your own pillar:

  Step 1 -- Choose your domain (storage, HR systems, printers, etc.)
  Step 2 -- Pick 4 state signals that indicate severity
  Step 3 -- Pick 4 actions ordered from least to most aggressive
  Step 4 -- Copy the NetworkTrafficEnvironment class and rename it
  Step 5 -- Replace _Sample() ranges with real Windows data:
              Get-WmiObject, Get-Counter, Get-WinEvent, Get-Process
  Step 6 -- Train, evaluate, commit as Phase 28+

## Run It

```powershell
cd "C:\Users\henni\OneDrive\WindowsPowerShell\examples\06-Custom-Agent"
. .\Run-Example-06.ps1
```

## Expected Output
--- Phase 1: Baseline (random agent) ---

Baseline avg reward: -42.31--- Phase 2: Training DQN Agent (30 episodes) ---

Ep   10/30  AvgReward:  -38.4  Eps: 0.951  Mon:12 Thr:14 Rer:11 Blk:13

Ep   20/30  AvgReward:  -18.2  Eps: 0.905  Mon:18 Thr:16 Rer:9  Blk:7

Ep   30/30  AvgReward:   +8.7  Eps: 0.861  Mon:22 Thr:18 Rer:7  Blk:3--- Phase 3: Evaluation (epsilon=0) ---

Trained avg reward: +14.82  Baseline  (random) avg reward :   -42.31

Trained   (DQN)    avg reward :   +14.82

Improvement                   :   135.0%

## What To Try Next

1. Change Episodes to 100 -- watch improvement percentage grow
2. Replace _Sample() with Get-Counter '\Network Interface(*)\Bytes Total/sec'
3. Add a 5th action -- does more choice help or hurt learning?
4. Submit your pillar as a GitHub PR to extend VBAF beyond Phase 27

## Key Concepts

- DQN agent (Mnih 2013/2015) applied to enterprise automation
- Reward shaping -- designing the +2/-1/-2/-3 feedback signal
- Distribution engineering -- 15/40/30/15 guarantees measurable improvement
- SimMode vs real Windows data -- same agent, different data source
- The environment interface -- StateSize, ActionSize, Reset(), Step(), GetState()

## Files

- `Run-Example-06.ps1` -- run this to start the example
- `tutorials\13_Enterprise_CustomPillar.ps1` -- full working template
- Source: `..\..\VBAF.RL.DQN.ps1` -- DQN agent class
- Source: `..\..\VBAF.Core.AllClasses.ps1` -- NeuralNetwork class
