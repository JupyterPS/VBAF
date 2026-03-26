# 02 — Building the XOR Network

## What You Will Learn

- Why XOR cannot be solved by a linear model
- How hidden layers enable non-linear learning
- How to verify your network is working correctly

## Why XOR is Special

XOR is not linearly separable. You cannot draw a straight line that separates
the 1s from the 0s in XOR. A single-layer perceptron fails completely.
Adding one hidden layer solves it — proving the network can learn non-linear patterns.

## The Full Working Example
```powershell
. .\VBAF.LoadAll.ps1
& ".\VBAF.Core.Example-XOR.ps1"
```

## Verification Checklist

After training, check:
- (0,0) -> close to 0.0
- (0,1) -> close to 1.0
- (1,0) -> close to 1.0
- (1,1) -> close to 0.0

If any prediction is wrong (e.g. 0.5), the network got stuck in a local minimum.
Run again with a different random seed.

## Architecture Experiment

Try different architectures and compare convergence speed:
```powershell
[int[]] $small  = @(2, 4, 1)     # fast but sometimes unstable
[int[]] $medium = @(2, 8, 1)     # good balance
[int[]] $deep   = @(2, 4, 4, 1)  # slower but more stable
```

## Next Step

[03 — Q-Learning Agent](03-Q-Learning-Agent.md)
