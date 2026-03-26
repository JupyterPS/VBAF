# Example 01: XOR Network

The classic neural network benchmark. XOR cannot be solved by a linear model —
it requires at least one hidden layer. This example proves VBAF's neural network
implementation is correct before using it for enterprise agents.

## What It Does

Trains a 2->4->1 feedforward network to learn the XOR truth table:
- 0 XOR 0 = 0
- 0 XOR 1 = 1
- 1 XOR 0 = 1
- 1 XOR 1 = 0

## Run It
```powershell
. .\VBAF.LoadAll.ps1
& ".\VBAF.Core.Example-XOR.ps1"
```

## Expected Output
```
XOR Truth Table:
  0 XOR 0 = 0  (predicted: 0.02)
  0 XOR 1 = 1  (predicted: 0.97)
  1 XOR 0 = 1  (predicted: 0.96)
  1 XOR 1 = 0  (predicted: 0.03)
Epochs: 847  Loss: 0.008
```

## Key Concepts

- NeuralNetwork class with configurable architecture
- Backpropagation with sigmoid activation
- Convergence in under 1000 epochs on standard hardware

## Files

- `VBAF.Core.Example-XOR.ps1` — main example script
- See [docs/tutorials/02-Building-XOR-Net.md](../../docs/tutorials/02-Building-XOR-Net.md)
