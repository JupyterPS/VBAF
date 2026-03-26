# 01 — Your First Neural Network

## What You Will Learn

- What a neural network is and why it works
- How to create a NeuralNetwork in VBAF
- How to train it with backpropagation
- How to read the loss curve

## Concept

A neural network is a stack of layers. Each layer applies a weighted sum
followed by a non-linear activation function. Training adjusts the weights
using backpropagation — the gradient of the loss with respect to each weight.

## Code
```powershell
. .\VBAF.LoadAll.ps1

# XOR dataset — the classic neural network benchmark
$X = @([double[]]@(0,0), [double[]]@(0,1), [double[]]@(1,0), [double[]]@(1,1))
$y = @(0.0, 1.0, 1.0, 0.0)

# Create a 2->4->1 network
[int[]] $arch = @(2, 4, 1)
$net = [NeuralNetwork]::new($arch, 0.1)

# Train for 1000 epochs
for ($i = 1; $i -le 1000; $i++) {
    $loss = $net.Train($X, $y)
    if ($i % 200 -eq 0) { Write-Host "Epoch $i  Loss: $($loss.ToString('F4'))" }
}

# Predict
foreach ($x in $X) {
    $pred = $net.Predict($x)
    Write-Host "$($x[0]) XOR $($x[1]) = $($pred[0].ToString('F2'))"
}
```

## What to Look For

- Loss should decrease steadily from ~0.25 to ~0.01
- Predictions should be close to 0 for (0,0) and (1,1), close to 1 for (0,1) and (1,0)
- If loss stops decreasing, try a higher learning rate or more neurons

## Next Step

[02 — Building the XOR Network](02-Building-XOR-Net.md)
