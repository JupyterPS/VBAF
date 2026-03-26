# Coding Standards

VBAF targets PowerShell 5.1 on Windows. These standards ensure compatibility
and consistency across all modules.

## PS 5.1 Rules

**Class definitions cannot be reloaded in the same session.**
Always open a fresh ISE when changing a class definition.

**Replay() returns Double — suppress output.**
```powershell
$agent.Replay() | Out-Null
```

**EndEpisode() returns Void — no suppression needed.**
```powershell
$agent.EndEpisode($epRew) | Out-Null  # defensive, always safe
```

**Array arithmetic inside constructors fails silently.**
Pre-compute values before passing to double[] arrays:
```powershell
# WRONG
$sample = [double[]]@(70.0 + $rng.NextDouble()*5)

# RIGHT
[double]$v1 = 70.0 + $rng.NextDouble()*5.0
$sample = [double[]]@($v1)
```

**$true and $false are reserved words.**
Never use $true or $false as variable names.

## Naming Conventions

| Item | Convention | Example |
|------|-----------|---------|
| Functions | Verb-VBAFNoun | Invoke-VBAFAutoPilotTraining |
| Classes | PascalCase | FleetDispatchEnvironment |
| Parameters | PascalCase | -Episodes, -SimMode |
| Variables | camelCase | $baseRewards, $trainedAvg |
| Constants | UPPER_CASE | not used in PS 5.1 |

## Enterprise Pillar Template

Every pillar must follow this structure:
- Class named `[Domain]Environment`
- StateSize = 4, ActionSize = 4
- Distribution 15/40/30/15 in `_Sample()` or `_SampleCondition()`
- Reward: +2 correct, -1/-2/-3 for wrong actions
- Training function named `Invoke-VBAF[Name]Training`
- `-SimMode` switch for demo/testing
- Load message at end of file
