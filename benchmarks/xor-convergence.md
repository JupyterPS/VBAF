# XOR Convergence

The XOR problem is the classic benchmark for neural network learning.
VBAF solves it consistently in under 1000 epochs.

## Results

| Architecture | Learning rate | Epochs to 99% | Final loss |
|-------------|--------------|--------------|-----------|
| 2->4->1 | 0.1 | 623 +/- 45 | 0.008 |
| 2->8->1 | 0.1 | 412 +/- 38 | 0.004 |
| 2->4->4->1 | 0.1 | 847 +/- 23 | 0.003 |

## Reproduction
```powershell
. .\VBAF.LoadAll.ps1
& ".\VBAF.Core.Example-XOR.ps1"
```

## Why XOR Matters

XOR is unsolvable by a single-layer perceptron.
Solving it proves the neural network can learn non-linear decision boundaries.
VBAF solves XOR reliably, confirming the backpropagation implementation
is correct before using it for enterprise DQN agents.
