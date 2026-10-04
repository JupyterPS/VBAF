# VBAF Tests

Validation and regression tests for all VBAF components.

## Regression suite (v5.0)

```powershell
.\tests\Test-VBAF.ps1      # about 1 minute; exit code 0 = all checks pass (outside ISE)
```

Self-contained: it loads the kernel from this repository in fresh child processes (PowerShell classes cannot be
reloaded in one session) and writes temporary files to `%TEMP%\VBAF-tests` only -- never into the repository.
Every check protects one fix found in VBAF-Evolution-Lab (KF-1..KF-9) with a FIXED expectation:

| Finding | What the suite checks |
|---------|-----------------------|
| KF-9 | `VBAF.LoadAll.ps1` loads in a normal `powershell.exe` without any ISE workaround (killed after 90 s) |
| Supervised | XOR 2-3-1, 4-6-1, 6-8-1: final errors LOCKED (bit-identical in v4 and v5.0); XOR example settings reach 100% |
| KF-4 | `Predict` returns a copy; `Replay` really learns (weights change, losses non-zero) |
| KF-1 | a DQN uses a Linear output layer; classifiers keep the Sigmoid default |
| KF-8 | a Linear output survives `ExportState`/`ImportState` |
| KF-3 | `Set-VBAFSeed` makes a DQN run reproducible; seed 42 is LOCKED to the tested candidate's fingerprint |
| KF-2 | `DQNAgent` reports the real network, warns on a config mismatch, explores every action |
| KF-6 | the JobScheduler pillar trains with its own config |
| KF-7 | `-MaxSteps` for all four environments, simulated `Reset` by default, `-Live` only on request, `-Seed` |
| Trace | `Get-VBAFTrace` on style A and B environments equals a manual loop; style C gives a clear error; snapshots, agents, seeds |
| Production cell | Brain 0 (SPT) = 37.85 on the test shifts; the same seed gives the same shift |
| Evolution | a small `Invoke-VBAFEvolutionRun` is LOCKED (curve and model file) and resumable |
| Evolution window | `Show-VBAFEvolutionWindow` renders any study (playback, champion in gold only at the end, bar optional); example data in `examples\07-Evolution` |
| The shift | `Get-VBAFShiftTrace` LOCKED to the Lab on shift 1001 (SPT 27.7, control 37.55, champion 35.55; 92 steps, 54 real, 38 idle); the tab renders |
| Side by side | LOCKED to the Lab: means 37.85/38/38.98, champion vs SPT 15/0/15, vs control 15/2/13, all 5 champions 87/4/59, margins 4.63/2.36 |
| Teach | topic 7 (Evolution) runs end to end with simulated keys and shows the real Lab numbers; all topics say "of 7" |

**Locked values.** If a locked value changes, behaviour changed. Do not edit the expected value to make the test
green: find out why first. Change it only for a deliberate, documented behaviour change (with a note in the changelog).

## Validation dashboard (older)
```powershell
. .\VBAF.LoadAll.ps1
& ".\VBAF.Core.Test-ValidationDashboard.ps1"
```

## Test Coverage

| Component | Test | Expected |
|-----------|------|----------|
| NeuralNetwork | XOR convergence | < 1000 epochs |
| GaussianNaiveBayes | Iris3Class accuracy | > 80% |
| RidgeRegression | HousePrice R2 | > 0.95 |
| KMeans | 3-cluster separation | Inertia < 2.0 |
| DQNAgent | Enterprise pillar | Superseded: before v5.0 this "improvement" was one fixed action vs random (KF-4). See the regression suite. |
| Split-TrainTest | Property names | XTrain/yTrain/XTest/yTest |
| OutlierDetector | Transform output | Returns .Data hashtable |
| StandardScaler | Zero mean | Mean < 0.001 after scaling |

## Adding a Test

Each test follows this pattern:
```powershell
$passed = $true
try {
    # run the component
    $result = ...
    # assert the expected outcome
    if ($result -lt $expected) { $passed = $false }
} catch {
    $passed = $false
    Write-Host "ERROR: $_" -ForegroundColor Red
}
Write-Host ("  {0,-30} {1}" -f "ComponentName", $(if ($passed) { "PASS" } else { "FAIL" })) `
    -ForegroundColor $(if ($passed) { "Green" } else { "Red" })
```

## Known PS 5.1 Gotchas

- Classes cannot be redefined in the same session — open fresh ISE after class changes
- `$true` and `$false` are reserved — never use as variable names
- `Replay()` returns Double — always pipe to `Out-Null`
- `OutlierDetector.Transform()` returns a Hashtable — always use `.Data`
- `Split-TrainTest` returns `XTrain/yTrain/XTest/yTest` — not `TrainX/TrainY`
- `r` is an alias for `Invoke-History`: never name a function `R` (or `h`)
- `@($null).Count` is 1: count with `Where-Object { $_ }`, and let no empty value pass a check
- The comma binds tighter than `+`: put each concatenation inside an array in its own parentheses
- `-eq` between two arrays filters instead of comparing
- `Get-Content` without `-Encoding UTF8` reads BOM-less UTF-8 as Windows-1252 (mojibake)
- Before v5.0, `VBAF.LoadAll.ps1` hung forever outside ISE (KF-9); fixed in v5.0
