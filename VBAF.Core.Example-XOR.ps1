#Requires -Version 5.1
<#
.SYNOPSIS
    XOR Problem -- Neural Network Example
.DESCRIPTION
    Trains a neural network to solve the XOR problem.

    WHAT YOU ARE LEARNING HERE:
    ============================
    XOR is the classic benchmark that proves neural networks can learn
    patterns that simple linear models cannot.

    XOR Truth Table:
      0 XOR 0 = 0   (both same -> 0)
      0 XOR 1 = 1   (different -> 1)
      1 XOR 0 = 1   (different -> 1)
      1 XOR 1 = 0   (both same -> 0)

    WHY XOR IS IMPORTANT:
    =====================
    XOR is NOT linearly separable. You cannot draw a single straight line
    that separates the 0-outputs from the 1-outputs on a 2D graph.

    A single neuron (perceptron) can only learn linear boundaries.
    Minsky & Papert proved this in 1969 -- killing AI research funding
    for a decade (the first "AI winter").

    The solution: ADD A HIDDEN LAYER.
    A network with one hidden layer can learn ANY non-linear function.
    This is called the Universal Approximation Theorem (Cybenko, 1989).

    XOR is the simplest possible proof that hidden layers work.
    If your network solves XOR, backpropagation is working correctly.

    WHAT TO WATCH:
    ==============
    Error:    starts high (random weights), should drop toward 0.001
    Accuracy: should reach 100% (all 4 XOR cases correct)
    Epochs:   typically converges between 500 and 5000 epochs
              (varies due to random weight initialisation)

    If it does not converge -- just run it again.
    Different random starting weights = different convergence speed.
    This is normal and expected behaviour.

    NETWORK ARCHITECTURE:
    =====================
    2 inputs -> 3 hidden neurons -> 1 output
    [2, 3, 1]

    Why 3 hidden neurons
    XOR can technically be solved with 2 hidden neurons,
    but 3 gives the network more capacity and converges faster.
    More neurons = more ways to learn the pattern.

.NOTES
    Part of VBAF (Visual AI & Reinforcement Learning Framework)
    Educational use -- run this first before any other example.
    Requires: VBAF.Core.AllClasses.ps1
#>

$basePath = $PSScriptRoot

# Load the neural network classes
# AllClasses.ps1 defines: Activation, Neuron, Layer, NeuralNetwork
. (Join-Path $basePath "VBAF.Core.AllClasses.ps1")

Write-Host ""
Write-Host "+--------------------------------------+" -ForegroundColor Cyan
Write-Host "|     XOR PROBLEM - NEURAL NETWORK    |" -ForegroundColor Cyan
Write-Host "+--------------------------------------+" -ForegroundColor Cyan

# -- THE TRAINING DATA --------------------------------------------------------
# XOR has only 4 possible inputs -- one of the smallest possible datasets.
# This is intentional: we want to see if the network can memorise all 4 cases.
# In real problems, datasets have thousands or millions of examples.
#
# Each sample has:
#   Input    -- the two binary values being XOR'd
#   Expected -- the correct output (what we want the network to predict)
$xorData = @(
    @{ Input = @(0.0, 0.0); Expected = @(0.0) }   # 0 XOR 0 = 0
    @{ Input = @(0.0, 1.0); Expected = @(1.0) }   # 0 XOR 1 = 1
    @{ Input = @(1.0, 0.0); Expected = @(1.0) }   # 1 XOR 0 = 1
    @{ Input = @(1.0, 1.0); Expected = @(0.0) }   # 1 XOR 1 = 0
)

Write-Host ""
Write-Host "XOR Truth Table:" -ForegroundColor Yellow
Write-Host "  0 XOR 0 = 0"
Write-Host "  0 XOR 1 = 1"
Write-Host "  1 XOR 0 = 1"
Write-Host "  1 XOR 1 = 0"
Write-Host ""
Write-Host "  Goal: train a neural network to reproduce this table" -ForegroundColor DarkGray

# -- CREATE THE NETWORK -------------------------------------------------------
# Architecture [2, 3, 1] means:
#   2 input neurons  (one per XOR input)
#   3 hidden neurons (learn the non-linear transformation)
#   1 output neuron  (the XOR result: 0 or 1)
#
# Learning rate 0.5 is higher than typical (0.01-0.1) because XOR is simple.
# Higher learning rate = faster convergence on simple problems.
# On complex problems, high learning rate causes instability.
$architecture = @(2, 3, 1)
$learningRate = 0.5

Write-Host ""
Write-Host "Creating Neural Network..." -ForegroundColor Yellow
Write-Host "  Architecture : $($architecture -join ' -> ')" -ForegroundColor DarkGray
Write-Host "  Learning rate: $learningRate" -ForegroundColor DarkGray
Write-Host "  Activation   : Sigmoid (outputs values between 0 and 1)" -ForegroundColor DarkGray

$nn = New-Object NeuralNetwork -ArgumentList $architecture, $learningRate

# -- TRAIN THE NETWORK --------------------------------------------------------
# 5000 epochs = 5000 passes through all 4 training samples = 20,000 updates.
# Watch the error decrease as the network learns.
# A good result: final error below 0.01, accuracy 100%.
$epochs  = 5000
$results = $nn.Train($xorData, $epochs)

# -- EVALUATE ACCURACY --------------------------------------------------------
# Evaluate classifies each output as 0 (below 0.5) or 1 (above 0.5).
# This threshold (0.5) is the standard decision boundary for binary outputs.
Write-Host ""
Write-Host ("-" * 50) -ForegroundColor Cyan
Write-Host "EVALUATION RESULTS" -ForegroundColor Cyan
Write-Host ("-" * 50) -ForegroundColor Cyan

$evaluation = $nn.Evaluate($xorData)
$accuracyColor = if ($evaluation.Accuracy -ge 95) { "Green" }
                 elseif ($evaluation.Accuracy -ge 75) { "Yellow" }
                 else { "Red" }

Write-Host ""
Write-Host "  Accuracy   : $($evaluation.Accuracy.ToString('F2'))%" -ForegroundColor $accuracyColor
Write-Host "  Correct    : $($evaluation.Correct) / $($evaluation.Total)"
Write-Host "  Final Error: $($results.FinalError.ToString('F6'))"

# -- SHOW DETAILED PREDICTIONS ------------------------------------------------
# The raw output is a value between 0 and 1 (Sigmoid activation).
# Values near 0.0 = network predicts 0.
# Values near 1.0 = network predicts 1.
# Values near 0.5 = network is uncertain -- this should not happen after training.
Write-Host ""
Write-Host "Detailed Predictions:" -ForegroundColor Yellow
Write-Host ("-" * 50)
Write-Host ("  Input     Expected   Predicted   Correct") -ForegroundColor Gray
Write-Host ("-" * 50)

foreach ($sample in $xorData) {
    $output    = $nn.Predict($sample.Input)
    $predicted = if ($output[0] -ge 0.5) { 1 } else { 0 }
    $expected  = [int]$sample.Expected[0]
    $isCorrect = if ($predicted -eq $expected) { "YES" } else { "NO " }
    $color     = if ($predicted -eq $expected) { "Green" } else { "Red" }

    $inputStr = "$($sample.Input[0]), $($sample.Input[1])"
    $line = "  {0,-8}  {1,-9}  {2,-10}  {3}" -f $inputStr, $expected, $output[0].ToString('F4'), $isCorrect

    Write-Host $line -ForegroundColor $color
}

Write-Host ("-" * 50)

# -- RESULT SUMMARY -----------------------------------------------------------
if ($evaluation.Accuracy -ge 95) {
    Write-Host ""
    Write-Host "  SUCCESS! Network learned XOR!" -ForegroundColor Green
    Write-Host "  Multi-layer backpropagation working correctly." -ForegroundColor Green
    Write-Host ""
    Write-Host "  What just happened:" -ForegroundColor DarkGray
    Write-Host "  3 hidden neurons learned internal representations" -ForegroundColor DarkGray
    Write-Host "  that make XOR linearly separable in hidden space." -ForegroundColor DarkGray
    Write-Host "  Backpropagation found the right weights automatically." -ForegroundColor DarkGray
} elseif ($evaluation.Accuracy -ge 75) {
    Write-Host ""
    Write-Host "  PARTIAL SUCCESS -- network learning but not converged yet." -ForegroundColor Yellow
    Write-Host "  Try: run again (different random init) or increase epochs." -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "  FAILED -- network did not learn XOR this run." -ForegroundColor Red
    Write-Host "  This is normal -- random weight init can get stuck." -ForegroundColor Red
    Write-Host "  Run the script again for a fresh attempt." -ForegroundColor Red
}

Write-Host ""

# ============================================================================
# WHAT TO TRY NEXT:
# =================
# 1. Run it again -- different random weights, different convergence
# 2. Change architecture to [2, 2, 1] -- can it still solve XOR with 2 hidden
# 3. Change learning rate to 0.1 -- slower convergence, watch the error
# 4. Change epochs to 500 -- does it converge fast enough
# 5. Move on to: examples\02-Castle-Learning\ for reinforcement learning
# ============================================================================