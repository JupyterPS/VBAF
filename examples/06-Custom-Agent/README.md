# Example 06: Custom Agent

A template and walkthrough for building your own enterprise automation agent.
This is the starting point for Phase 28 and beyond.

## What It Does

Demonstrates the complete pattern for a custom DQN enterprise agent:
- Define 4 state signals relevant to your domain
- Define 4 ordered response actions
- Implement the proven reward function
- Train and evaluate in SimMode

## Run It
```powershell
. .\VBAF.LoadAll.ps1
& ".\tutorials\13_Enterprise_CustomPillar.ps1"
```

## The Pattern
```powershell
class MyEnvironment {
    [int]    $StateSize  = 4
    [int]    $ActionSize = 4
    [double] $LastReward = 0.0
    [bool]   $LastDone   = $false

    [double[]] GetState() { return [double[]]@($s1, $s2, $s3, $s4) }
    [double[]] Reset()    { $this.LastDone = $false; $this._Sample(); return $this.GetState() }
    [void]     Step([int]$action) {
        $dist = [Math]::Abs($action - $this.CurrentSeverity)
        $this.LastReward = @(2.0, -1.0, -2.0, -3.0)[$dist]
        $this._Sample()
        $this.LastDone = ($this.Steps++ -ge 200)
    }
}
```

## Key Concepts

- Environment interface requirements
- Distribution 15/40/30/15 for guaranteed positive improvement
- SimMode vs real Windows data mode

## Files

- `tutorials/13_Enterprise_CustomPillar.ps1` — full working template
- See [docs/tutorials/05-Custom-Environment.md](../../docs/tutorials/05-Custom-Environment.md)
