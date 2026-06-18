# Example 01: XOR Network

The classic neural network benchmark -- and the best place to start with VBAF.

## Why XOR?

XOR is the simplest problem that a single neuron CANNOT solve.
In 1969, Minsky and Papert proved this mathematically -- and it killed
AI research funding for a decade (the first "AI winter").

The solution was the hidden layer. Add one hidden layer and the network
can learn ANY non-linear function. This is the Universal Approximation
Theorem (Cybenko, 1989).

XOR is the proof. If your network solves XOR, backpropagation works.

## The Problem

XOR Truth Table:

```
0 XOR 0 = 0   (both same   -> 0)
0 XOR 1 = 1   (different   -> 1)
1 XOR 0 = 1   (different   -> 1)
1 XOR 1 = 0   (both same   -> 0)
```

Plot these four points on a 2D graph. You cannot draw a single straight
line that separates the 0s from the 1s. That is what "not linearly
separable" means -- and why one neuron fails.

## The Solution

A network with architecture [2, 3, 1]:
- 2 input neurons  -- one per XOR input
- 3 hidden neurons -- learn the non-linear transformation
- 1 output neuron  -- predicts 0 or 1

The 3 hidden neurons learn internal representations that make XOR
linearly separable in hidden space. Backpropagation finds the right
weights automatically.

## What To Watch While It Runs

- Error starts high (random weights) and should drop toward 0.001
- Accuracy should reach 100% -- all 4 XOR cases correct
- Epochs to converge: typically 500 to 5000 (random init varies)
- If it fails -- run again. Different starting weights = different result.
  This is normal and expected.

## Run It

```powershell
cd "C:\Users\henni\OneDrive\WindowsPowerShell\examples\01-XOR-Network"
. .\Run-Example-01.ps1
```

## Expected Output

```
+--------------------------------------+
|     XOR PROBLEM - NEURAL NETWORK    |
+--------------------------------------+

XOR Truth Table:
  0 XOR 0 = 0
  0 XOR 1 = 1
  1 XOR 0 = 1
  1 XOR 1 = 0

  Accuracy   : 100.00%
  Correct    : 4 / 4
  Final Error: 0.008432

  0, 0      0          0.0201      YES
  0, 1      1          0.9731      YES
  1, 0      1          0.9698      YES
  1, 1      0          0.0187      YES

  SUCCESS! Network learned XOR!
```

## What To Try Next

1. Run it again -- different random weights, different convergence speed
2. Change architecture to [2, 2, 1] -- can 2 hidden neurons still solve it?
3. Change learning rate to 0.1 -- slower convergence, watch the error curve
4. Change epochs to 500 -- does it converge fast enough?
5. Move on to examples\02-Castle-Learning\ -- reinforcement learning

## Key Concepts

- Backpropagation (Rumelhart, Hinton & Williams, 1986)
- Universal Approximation Theorem (Cybenko, 1989)
- Linear separability and why it matters
- Random weight initialisation and convergence variance

## Files

- `Run-Example-01.ps1` -- run this to start the example
- `VBAF.Core.Example-XOR.ps1` -- the full example with educational comments
- Source: `..\..\VBAF.Core.AllClasses.ps1` -- NeuralNetwork class
