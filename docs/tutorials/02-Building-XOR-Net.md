# Tutorial 02: Building the XOR Network in Depth

**Understand exactly how a neural network learns** 🧠

> **Prerequisites:** Tutorial 01 completed
> **Time:** 20-25 minutes
> **Difficulty:** Beginner-Intermediate

---

## What You Will Learn

- Why XOR requires multiple layers
- How backpropagation adjusts weights step by step
- How to monitor training progress
- How to experiment with network architecture

---

## Why XOR is the "Hello World" of Neural Networks

XOR cannot be solved by a straight line (linear separator).
Plot the four XOR points:
```
(0,0)=0   (0,1)=1
(1,0)=1   (1,1)=0
```

No single line can separate the 0s from the 1s.
A **hidden layer** creates a non-linear boundary that can.

This is why XOR proves a network can learn beyond simple patterns.

---

## Step 1: Load the Framework
```powershell
. .\VBAF.LoadAll.ps1
```

---

## Step 2: Create Networks of Different Sizes

Let us compare two architectures:
```powershell
# Small network: 2 inputs, 2 hidden, 1 output
$smallNet = New-Object NeuralNetwork -ArgumentList @(2, 2, 1), 0.1

# Larger network: 2 inputs, 5 hidden, 1 output
$largeNet = New-Object NeuralNetwork -ArgumentList @(2, 5, 1), 0.1

Write-Host "Small network:  2-2-1 architecture"
Write-Host "Larger network: 2-5-1 architecture"
```

---

## Step 3: Training Data
```powershell
$xorData = @(
    @{Input=@(0,0); Expected=0},
    @{Input=@(0,1); Expected=1},
    @{Input=@(1,0); Expected=1},
    @{Input=@(1,1); Expected=0}
)
```

---

## Step 4: Train Both and Compare
```powershell
Write-Host "Training small network (2-2-1)..." -ForegroundColor Cyan
$smallResults = $smallNet.Train($xorData, 2000)

Write-Host "Training larger network (2-5-1)..." -ForegroundColor Cyan
$largeResults = $largeNet.Train($xorData, 2000)

$smallFinal = $smallResults[-1].Error
$largeFinal = $largeResults[-1].Error

Write-Host "`nResults after 2000 epochs:" -ForegroundColor Green
Write-Host ("  Small  (2-2-1): Final error = {0:F6}" -f $smallFinal)
Write-Host ("  Larger (2-5-1): Final error = {0:F6}" -f $largeFinal)

if ($largeFinal -lt $smallFinal) {
    Write-Host "  Larger network learned better!" -ForegroundColor Yellow
} else {
    Write-Host "  Small network held its own!" -ForegroundColor Yellow
}
```

---

## Step 5: Watch Learning Progress Over Time
```powershell
Write-Host "`nLearning curve (every 200 epochs):" -ForegroundColor Cyan

$checkpoints = @(0, 199, 399, 599, 799, 999, 1499, 1999)
foreach ($i in $checkpoints) {
    if ($i -lt $largeResults.Count) {
        Write-Host ("  Epoch {0,4}: error = {1:F6}" -f ($i+1), $largeResults[$i].Error)
    }
}
```

**Expected output:**
```
Learning curve (every 200 epochs):
  Epoch    1: error = 0.251832
  Epoch  200: error = 0.089234
  Epoch  400: error = 0.031456
  Epoch  600: error = 0.012341
  Epoch  800: error = 0.005672
  Epoch 1000: error = 0.003124
  Epoch 1500: error = 0.001823
  Epoch 2000: error = 0.000934
```

Error consistently dropping = healthy training!

---

## Step 6: Test Final Accuracy
```powershell
Write-Host "`n=== Final Accuracy Test ===" -ForegroundColor Cyan

$correct = 0
foreach ($sample in $xorData) {
    $prediction = $largeNet.Predict($sample.Input)
    $rounded = [Math]::Round($prediction[0])
    $isCorrect = ($rounded -eq $sample.Expected)
    if ($isCorrect) { $correct++ }

    Write-Host ("XOR({0},{1}) = {2:F4} -> {3} (expected {4}) {5}" -f `
        $sample.Input[0], $sample.Input[1], `
        $prediction[0], $rounded, `
        $sample.Expected, `
        $(if ($isCorrect) { "✓" } else { "✗" }))
}

Write-Host "`nAccuracy: $correct/4 = $([Math]::Round($correct/4*100))%" -ForegroundColor Green
```

---

## Step 7: Experiment with Learning Rate

Learning rate controls how big each weight update step is:
```powershell
$fastNet = New-Object NeuralNetwork -ArgumentList @(2, 3, 1), 0.5   # Fast
$slowNet = New-Object NeuralNetwork -ArgumentList @(2, 3, 1), 0.01  # Slow
$goodNet = New-Object NeuralNetwork -ArgumentList @(2, 3, 1), 0.1   # Balanced

$fastResults = $fastNet.Train($xorData, 1000)
$slowResults = $slowNet.Train($xorData, 1000)
$goodResults = $goodNet.Train($xorData, 1000)

Write-Host "`nLearning rate comparison after 1000 epochs:" -ForegroundColor Cyan
Write-Host ("  Rate 0.50 (fast):     error = {0:F6}" -f $fastResults[-1].Error)
Write-Host ("  Rate 0.10 (balanced): error = {0:F6}" -f $goodResults[-1].Error)
Write-Host ("  Rate 0.01 (slow):     error = {0:F6}" -f $slowResults[-1].Error)
```

**What you will observe:**
- Too fast (0.5): May overshoot, unstable learning
- Balanced (0.1): Reliable convergence
- Too slow (0.01): Learns safely but needs more epochs

---

## Key Concepts Explained

**Backpropagation:** After each prediction, the network measures how wrong it was
(the error) and works backwards through the layers adjusting weights to reduce
that error next time.

**Epochs:** One complete pass through all training examples. More epochs = more
chances to learn.

**Hidden layers:** Allow the network to create internal representations that
capture non-linear patterns like XOR.

**Learning rate:** The size of each weight adjustment step. Too large = unstable.
Too small = very slow. 0.1 is a reliable starting point.

---

## Troubleshooting

**Error stuck above 0.25?**
- Network may be in a local minimum — rerun to get new random starting weights
- Try learning rate 0.3 or add more hidden neurons

**Error oscillating (going up and down)?**
- Learning rate too high — reduce from 0.1 to 0.05

**Training very slow?**
- Normal for PowerShell — 1000 epochs takes roughly 10 seconds
- This is expected; VBAF prioritizes transparency over speed

---

## What You Learned

- XOR requires hidden layers because it is not linearly separable
- More hidden neurons generally learn faster and more reliably
- Learning rate 0.1 is a safe default for most problems
- Watching the error curve tells you if training is healthy

---

## Next Steps

- **Tutorial 03:** Your first Q-Learning agent
- **Tutorial 06:** Visualize the XOR learning curve on a live dashboard
- **Examples/01-XOR-Network:** See the full visualized XOR example

---

*VBAF Version: 1.0.0 | PowerShell 5.1+ | Windows 10/11*
