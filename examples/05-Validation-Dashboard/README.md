# Example 05: Validation Dashboard

A comprehensive validation suite that tests all VBAF components
and displays results in a formatted dashboard. Use this to verify
your VBAF installation is working correctly.

## What It Does

- Tests NeuralNetwork, DQNAgent, ML models and enterprise pillars
- Displays pass/fail status for each component
- Shows performance benchmarks

## Run It
```powershell
. .\VBAF.LoadAll.ps1
& ".\VBAF.Core.Test-ValidationDashboard.ps1"
```

## Expected Output
```
VBAF Validation Dashboard
========================
NeuralNetwork (XOR)     PASS  847 epochs
GaussianNaiveBayes      PASS  Acc=83.3%
RidgeRegression         PASS  R2=0.994
KMeans (k=3)            PASS  Inertia=1.64
DQNAgent                PASS  Improvement=+63%
========================
All tests passed!
```

## Key Concepts

- Systematic component validation
- Regression testing after changes
- Performance baseline verification

## Files

- `VBAF.Core.Test-ValidationDashboard.ps1` — validation suite
