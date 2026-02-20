# VBAF Tutorial 01 - Getting Started
**VBAF - Visual Basic AI Framework for PowerShell 5.1**
*Beginner Series | Estimated time: 15 minutes*

---

## What is VBAF?

VBAF is a machine learning framework built entirely in PowerShell 5.1.
No Python. No pip install. No Jupyter. Just PowerShell!

Every algorithm is implemented from scratch so you can read the code
and understand exactly what's happening.

---

## Prerequisites

- Windows with PowerShell 5.1 (built into Windows 10/11)
- Git (to clone the repo)
- No other dependencies!

---

## Installation

```powershell
# Clone the repo
git clone https://github.com/JupyterPS/VBAF.git
cd VBAF

# Load everything
. .\VBAF.LoadAll.ps1
```

You should see all modules load with their quick-start examples.

---

## Your First Dataset

```powershell
# Load the HousePrice dataset (built-in, no download needed)
$data = Get-VBAFDataset -Name "HousePrice"

# What did we get?
Write-Host "Samples  : $($data.X.Length)"
Write-Host "Features : $($data.Features -join ', ')"
Write-Host "Target   : price (in £1000s)"
```

Expected output:
```
Samples  : 20
Features : size_sqm, bedrooms, age_years
Target   : price (in £1000s)
```

---

## Your First Model

```powershell
# Step 1: Scale the features (important for linear models!)
$scaler = [StandardScaler]::new()
$Xs     = $scaler.FitTransform($data.X)

# Step 2: Train a linear regression model
$model = [LinearRegression]::new()
$model.Fit($Xs, $data.y)

# Step 3: See the results
$model.PrintSummary()
```

---

## Making a Prediction

```powershell
# Predict price for: 120 sqm, 3 bedrooms, 5 years old
$newHouse   = @(@(120.0, 3.0, 5.0))
$newHouseS  = $scaler.Transform($newHouse)
$prediction = $model.Predict($newHouseS)

Write-Host "Predicted price: £$([Math]::Round($prediction[0], 1))k"
```

---

## What's Next?

- **Tutorial 02** - Your first classification model
- **Tutorial 03** - Data pipelines and preprocessing
- **Tutorial 04** - Evaluating model performance
- **Tutorial 05** - Advanced: full MLOps pipeline

---
*VBAF Phase 8 - Community & Ecosystem*