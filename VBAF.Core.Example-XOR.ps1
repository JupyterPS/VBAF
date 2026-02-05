#Requires -Version 5.1

<#
.SYNOPSIS
    XOR Problem - Neural Network Test
.DESCRIPTION
    Trains a neural network to solve the XOR problem.
    This is the classic test that proves multi-layer networks can learn
    non-linearly separable functions.
.NOTES
    XOR Truth Table:
    0 XOR 0 = 0
    0 XOR 1 = 1
    1 XOR 0 = 1
    1 XOR 1 = 0
#>

# Set base path
$basePath = $PSScriptRoot

# Load VBAF Core
. (Join-Path $basePath "VBAF.Core.AllClasses.ps1")

Write-Host "`n+--------------------------------------+" -ForegroundColor Cyan
Write-Host "¦     XOR PROBLEM - NEURAL NETWORK    ¦" -ForegroundColor Cyan
Write-Host "+--------------------------------------+" -ForegroundColor Cyan

# XOR Training Data
$xorData = @(
    @{ Input = @(0.0, 0.0); Expected = @(0.0) }
    @{ Input = @(0.0, 1.0); Expected = @(1.0) }
    @{ Input = @(1.0, 0.0); Expected = @(1.0) }
    @{ Input = @(1.0, 1.0); Expected = @(0.0) }
)

Write-Host "`nXOR Truth Table:" -ForegroundColor Yellow
Write-Host "  0 XOR 0 = 0"
Write-Host "  0 XOR 1 = 1"
Write-Host "  1 XOR 0 = 1"
Write-Host "  1 XOR 1 = 0"

# Create Neural Network
# Architecture: 2 inputs ? 3 hidden ? 1 output
$architecture = @(2, 3, 1)
$learningRate = 0.5

Write-Host "`nCreating Neural Network..." -ForegroundColor Yellow
$nn = New-Object NeuralNetwork -ArgumentList $architecture, $learningRate

# Train the network
$epochs = 5000
$results = $nn.Train($xorData, $epochs)

# Evaluate accuracy
Write-Host "`n" + ("-" * 50) -ForegroundColor Cyan
Write-Host "EVALUATION RESULTS" -ForegroundColor Cyan
Write-Host ("-" * 50) -ForegroundColor Cyan

$evaluation = $nn.Evaluate($xorData)

Write-Host "`nAccuracy: $($evaluation.Accuracy.ToString('F2'))%" -ForegroundColor $(
    if ($evaluation.Accuracy -ge 95) { "Green" } 
    elseif ($evaluation.Accuracy -ge 75) { "Yellow" } 
    else { "Red" }
)
Write-Host "Correct: $($evaluation.Correct) / $($evaluation.Total)"
Write-Host "Final Error: $($results.FinalError.ToString('F6'))"

# Test each case
Write-Host "`nDetailed Predictions:" -ForegroundColor Yellow
Write-Host ("-" * 50)
Write-Host ("  Input     Expected   Predicted   Correct") -ForegroundColor Gray
Write-Host ("-" * 50)

foreach ($sample in $xorData) {
    $output = $nn.Predict($sample.Input)
    $predicted = if ($output[0] -ge 0.5) { 1 } else { 0 }
    $expected = [int]$sample.Expected[0]
    $isCorrect = if ($predicted -eq $expected) { "?" } else { "?" }
    $color = if ($predicted -eq $expected) { "Green" } else { "Red" }
    
    $inputStr = "$($sample.Input[0]), $($sample.Input[1])"
    $line = "  {0,-8}  {1,-9}  {2,-10}  {3}" -f $inputStr, $expected, $output[0].ToString('F4'), $isCorrect
    
    Write-Host $line -ForegroundColor $color
}

Write-Host ("-" * 50)

# Success check
if ($evaluation.Accuracy -ge 95) {
    Write-Host "`n?? SUCCESS! Network learned XOR!" -ForegroundColor Green
    Write-Host "   Multi-layer backpropagation working correctly!" -ForegroundColor Green
} elseif ($evaluation.Accuracy -ge 75) {
    Write-Host "`n? PARTIAL SUCCESS - Network learning but not converged" -ForegroundColor Yellow
    Write-Host "   Try: More epochs, different learning rate, or re-run (random init)" -ForegroundColor Yellow
} else {
    Write-Host "`n? FAILURE - Network did not learn XOR" -ForegroundColor Red
    Write-Host "   Debug: Check backpropagation implementation" -ForegroundColor Red
}

Write-Host ""