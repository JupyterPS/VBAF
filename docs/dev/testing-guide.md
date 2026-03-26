# Testing Guide

## Running All Tests
```powershell
. .\VBAF.LoadAll.ps1
& ".\tests\Run-AllTests.ps1"
```

## Testing a New Pillar

Before submitting a new enterprise pillar, verify:
```powershell
. .\VBAF.LoadAll.ps1
. ".\VBAF.Enterprise.MyNewPillar.ps1"

# Test 1: SimMode runs without errors
$r = Invoke-VBAFMyNewPillarTraining -Episodes 30 -PrintEvery 10 -SimMode
Write-Host "Improvement: $($r.Improvement)%"

# Test 2: Improvement is positive (run 3 times, average should be positive)
$improvements = @()
for ($i = 1; $i -le 3; $i++) {
    $r = Invoke-VBAFMyNewPillarTraining -Episodes 100 -PrintEvery 100 -SimMode
    $improvements += $r.Improvement
}
$avg = ($improvements | Measure-Object -Average).Average
Write-Host "Average improvement over 3 runs: $($avg.ToString('F1'))%"
```

## Minimum Acceptance Criteria

- SimMode completes without errors
- Average improvement > 0% over 3 runs with 100 episodes
- No unhandled exceptions
- Load message displays correctly
- Function appears in LoadAll.ps1

## Testing ML Models
```powershell
# Verify Split-TrainTest property names
$split = Split-TrainTest -X $data.X -y $data.y -TestSize 0.2 -Seed 42
Write-Host $split.XTrain.Length   # must work
Write-Host $split.yTrain.Length   # must work

# Verify OutlierDetector returns .Data
$out   = [OutlierDetector]::new("iqr", "clip", 1.5)
$out.Fit($X)
$Xclip = ($out.Transform($X)).Data   # always use .Data
```
