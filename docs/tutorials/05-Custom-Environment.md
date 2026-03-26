# 05 — Custom Environment

## What You Will Learn

- How to define your own RL environment
- The required interface: GetState, Step, Reset
- How to design a reward function
- The proven VBAF pillar pattern

## The Environment Interface

Every VBAF environment must implement:
```powershell
class MyEnvironment {
    [int]    $StateSize  = 4
    [int]    $ActionSize = 4
    [double] $LastReward = 0.0
    [bool]   $LastDone   = $false

    [double[]] GetState() { ... }
    [double[]] Reset()    { ... }
    [void]     Step([int]$action) { ... }
}
```

## The Proven Pattern

4 state signals, normalised 0.0-1.0, ordered low-to-high severity.
4 actions, ordered low-to-high response strength.
Reward: +2 correct, -1 dist=1, -2 dist=2, -3 dist=3.
Distribution: 15/40/30/15 across severity levels.

## Full Template

See [tutorials/13_Enterprise_CustomPillar.ps1](../../tutorials/13_Enterprise_CustomPillar.ps1)
for a complete working example of Phase 28 — Network Traffic Manager.

## Reward Design Tips

- The reward must clearly distinguish good from bad actions
- Symmetric rewards (+2/-3) create strong learning signals
- Avoid sparse rewards — the agent needs feedback at every step
- The distribution determines which action the agent learns to prefer

## Next Step

[06 — Using Dashboards](06-Using-Dashboards.md)
