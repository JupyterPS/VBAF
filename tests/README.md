# VBAF Tests

Validation and regression tests for all VBAF components.

## Running All Tests
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
| DQNAgent | Enterprise pillar | Positive improvement |
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
