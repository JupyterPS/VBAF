[← Back to Tutorials](README.md) | [🏠 Home](../../README.md)

# Tutorial 01: Your First Neural Network

**From zero to neural network in 15 minutes** ⚡

> **Prerequisites:** VBAF installed, PowerShell 5.1+
> **Time:** 15-20 minutes
> **Difficulty:** Beginner

---

## What You Will Learn

- How a single artificial neuron works
- How to build a multi-layer neural network
- How to train a network using backpropagation
- How to solve the classic XOR problem

---

## Step 1: Load the Framework
```powershell
. .\VBAF.LoadAll.ps1
```

You should see:
```
Loading VBAF Framework...
33 Core modules loaded
VBAF Framework ready!
```

---

## Step 2: Create a Single Neuron (5 minutes)

A neuron is the smallest unit of intelligence in a neural network.
```powershell
# Create a neuron with 2 inputs
$neuron = New-Object Neuron -ArgumentList 2

Write-Host "Created neuron with:"
Write-Host "  Weights: $($neuron.Weights -join ', ')"
Write-Host "  Bias: $($neuron.Bias)"
```

**Expected output:**
```
Created neuron with:
  Weights: -0.3421, 0.7234
  Bias: 0.1523
```
(Your numbers will differ - they are random!)

Now make a prediction:
```powershell
$inputs = @(0.5, 0.8)
$output = $neuron.Forward($inputs)

Write-Host "Input: $($inputs -join ', ')"
Write-Host "Output: $output"
```

**What just happened?**
1. Neuron multiplied inputs by weights
2. Added bias
3. Applied sigmoid activation: `1 / (1 + e^-sum)`
4. Returned a value between 0 and 1

Congratulations - you just used an artificial neuron!

---

## Step 3: Build a Neural Network (10 minutes)

Now let us solve XOR - a problem that requires **multiple layers**.

XOR outputs 1 only when inputs are different:
```
Input A | Input B | Output
--------|---------|--------
   0    |    0    |   0
   0    |    1    |   1
   1    |    0    |   1
   1    |    1    |   0
```

A single neuron cannot learn this. We need a network!
```powershell
# Architecture: 2 inputs, 3 hidden neurons, 1 output
$nn = New-Object NeuralNetwork -ArgumentList @(2, 3, 1), 0.1

Write-Host "Neural network created: 2 inputs, 3 hidden, 1 output"
```

---

## Step 4: Prepare Training Data
```powershell
$xorData = @(
    @{Input=@(0,0); Expected=0},
    @{Input=@(0,1); Expected=1},
    @{Input=@(1,0); Expected=1},
    @{Input=@(1,1); Expected=0}
)

Write-Host "Training data: 4 XOR examples ready"
```

---

## Step 5: Train the Network
```powershell
Write-Host "Training for 1000 epochs..." -ForegroundColor Cyan

$results = $nn.Train($xorData, 1000)

Write-Host "Training complete!" -ForegroundColor Green
Write-Host "Final error: $($results[-1].Error.ToString('F6'))"
```

**Expected output:**
```
Training complete!
Final error: 0.001234
```

---

## Step 6: Test the Results
```powershell
Write-Host "`n=== Testing XOR ===" -ForegroundColor Cyan

foreach ($sample in $xorData) {
    $prediction = $nn.Predict($sample.Input)
    $rounded = [Math]::Round($prediction[0])
    $status = if ($rounded -eq $sample.Expected) { "Correct" } else { "Wrong" }
    Write-Host ("XOR({0},{1}) = {2} (expected {3}) - {4}" -f `
        $sample.Input[0], $sample.Input[1], $rounded, $sample.Expected, $status)
}
```

**Expected output:**
```
XOR(0,0) = 0 (expected 0) - Correct
XOR(0,1) = 1 (expected 1) - Correct
XOR(1,0) = 1 (expected 1) - Correct
XOR(1,1) = 0 (expected 0) - Correct
```

Your network learned XOR from scratch!

---

## Troubleshooting

**Network not learning?** Try:
- Lower learning rate: change `0.1` to `0.01`
- More epochs: change `1000` to `5000`
- More hidden neurons: change `@(2, 3, 1)` to `@(2, 5, 1)`

**Execution policy error?**
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

---

## What You Learned

- A neuron multiplies inputs by weights, adds bias, applies activation
- Hidden layers allow networks to solve non-linear problems like XOR
- Backpropagation adjusts weights to reduce error over time
- 1000 training epochs is enough for simple problems

---

## Next Steps

- **Tutorial 02:** Building and understanding the XOR network in depth
- **Tutorial 03:** Your first Q-Learning agent
- **Tutorial 06:** Visualizing training with live dashboards

---

*VBAF Version: 1.0.0 | PowerShell 5.1+ | Windows 10/11*


---
[← Back to Tutorials](README.md) | [Next: Tutorial 02 →](02-Building-XOR-Net.md)
