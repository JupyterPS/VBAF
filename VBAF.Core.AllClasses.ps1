#Requires -Version 5.1

<#
.SYNOPSIS
    VBAF Core -- All Neural Network Classes
.DESCRIPTION
    This file contains the complete building blocks of a neural network
    implemented from scratch in PowerShell 5.1.

    WHAT YOU ARE LEARNING HERE:
    ============================
    A neural network is a mathematical system loosely inspired by the brain.
    It consists of layers of simple units (neurons), each connected to the
    next layer by weights. Learning happens by adjusting those weights
    based on how wrong the network's predictions are.

    This file implements four classes that build up from simple to complex:

      Activation  -- the mathematical functions that make neurons non-linear
      Neuron      -- one unit that receives inputs and produces one output
      Layer       -- a collection of neurons that process inputs in parallel
      NeuralNetwork -- the full network: forward pass + backpropagation

    READ IN ORDER: Activation -> Neuron -> Layer -> NeuralNetwork

    THEORY REFERENCE:
    =================
    Rumelhart, D.E., Hinton, G.E., & Williams, R.J. (1986).
    "Learning representations by back-propagating errors."
    Nature, 323, 533-536.

    This paper introduced backpropagation -- the algorithm that makes
    training neural networks practical. Every function in this file
    is a direct implementation of that paper.
.NOTES
    Part of VBAF (Visual AI & Reinforcement Learning Framework)
    Educational use -- read the comments, not just the code.
#>

# ============================================================================
# ACTIVATION FUNCTIONS
# ============================================================================
#
# WHAT IS AN ACTIVATION FUNCTION
# --------------------------------
# Without activation functions, a neural network is just a series of matrix
# multiplications -- which can only learn linear relationships.
# Activation functions introduce non-linearity, which allows the network
# to learn complex patterns like XOR, image recognition or game strategies.
#
# Think of it like a light switch with a dimmer:
#   - Linear: always passes through the full signal (useless for learning)
#   - Sigmoid: squashes any input to a value between 0 and 1 (like a probability)
#   - ReLU: passes positive values unchanged, blocks negative values
#   - Tanh: squashes any input to a value between -1 and 1
#
# WHY DO WE NEED THE DERIVATIVE
# --------------------------------
# During backpropagation (the learning step), we need to know HOW MUCH
# each neuron contributed to the error. The derivative tells us the
# slope of the activation function at a given point -- how sensitive
# the output is to small changes in the input.
#
# Large derivative = this neuron strongly affects the output -> adjust weights more
# Small derivative = this neuron barely affects the output -> adjust weights less
#
# CLAMPING (-500 to 500):
# ------------------------
# Sigmoid and Tanh use Math::Exp(), which overflows at extreme values.
# We clamp inputs to prevent NaN (Not a Number) errors during training.
# This is a practical engineering choice, not a mathematical one.

class Activation {

    # -- Sigmoid --------------------------------------------------------------
    # Formula: sigmoid(x)(x) = 1 / (1 + e^(-x))
    # Output range: (0, 1)
    # Use when: output layer of a binary classifier (yes/no, true/false)
    # Named after the Greek letter sigmoid(x) (sigma) -- looks like an S-curve
    static [double] Sigmoid([double]$x) {
        if ($x -lt -500) { return 0.0 }   # Prevent underflow
        if ($x -gt  500) { return 1.0 }   # Prevent overflow
        return 1.0 / (1.0 + [Math]::Exp(-$x))
    }

    # Formula: sigmoid(x)'(x) = sigmoid(x)(x) . (1 - sigmoid(x)(x))
    # This elegant property means we can compute the derivative
    # from the output we already calculated -- no extra computation needed.
    static [double] SigmoidDerivative([double]$x) {
        $s = [Activation]::Sigmoid($x)
        return $s * (1.0 - $s)
    }

    # -- ReLU (Rectified Linear Unit) -----------------------------------------
    # Formula: ReLU(x) = max(0, x)
    # Output range: [0, infinity)
    # Use when: hidden layers of deep networks
    # Most popular activation in modern deep learning -- fast and simple.
    # "Rectified" means negative values are set to zero (rectified = corrected).
    static [double] ReLU([double]$x) {
        if ($x -gt 0) { return $x } else { return 0.0 }
    }

    # Formula: ReLU'(x) = 1 if x > 0, else 0
    # The derivative is simply 1 (pass through) or 0 (blocked).
    # This makes ReLU extremely fast to compute during backpropagation.
    static [double] ReLUDerivative([double]$x) {
        if ($x -gt 0) { return 1.0 } else { return 0.0 }
    }

    # -- Tanh (Hyperbolic Tangent) ---------------------------------------------
    # Formula: tanh(x) = (e^x - e^(-x)) / (e^x + e^(-x))
    # Output range: (-1, 1)
    # Use when: hidden layers where negative outputs are meaningful
    # Zero-centred (unlike Sigmoid) -- often trains faster in practice.
    static [double] Tanh([double]$x) {
        if ($x -lt -500) { return -1.0 }
        if ($x -gt  500) { return  1.0 }
        return [Math]::Tanh($x)
    }

    # Formula: tanh'(x) = 1 - tanh^2(x)
    # Same elegant pattern as Sigmoid -- derivative computable from output.
    static [double] TanhDerivative([double]$x) {
        $t = [Math]::Tanh($x)
        return 1.0 - ($t * $t)
    }

    # -- Linear ----------------------------------------------------------------
    # Formula: f(x) = x (identity function -- passes input unchanged)
    # Output range: (-infinity, infinity)
    # Use when: output layer of a regression network (predicting a real number)
    # Derivative is always 1.0 -- gradient flows through unchanged.
    static [double] Linear([double]$x) {
        return $x
    }

    static [double] LinearDerivative([double]$x) {
        return 1.0
    }
}


# ============================================================================
# NEURON
# ============================================================================
#
# WHAT IS A NEURON
# -----------------
# A neuron is the fundamental unit of a neural network. It:
#   1. Receives N inputs (one from each neuron in the previous layer)
#   2. Multiplies each input by a weight (its "importance")
#   3. Adds a bias (a baseline offset)
#   4. Passes the result through an activation function
#   5. Produces one output value
#
# Mathematically: output = activation(w1.x1 + w2.x2 + ... + wn.xn + b)
# Where w = weights, x = inputs, b = bias
#
# WEIGHTS AND BIAS:
# -----------------
# Weights are initialised randomly between -0.5 and 0.5.
# Random initialisation is essential -- if all weights started at 0,
# all neurons would learn the same thing and the network would never
# develop specialised features.
#
# The bias allows the neuron to fire (activate) even when all inputs are 0.
# Think of it as the neuron's "default mood" -- its baseline tendency to activate.
#
# DELTA:
# ------
# Delta (delta) is the error signal flowing backwards through the network
# during backpropagation. It tells this neuron how much it contributed
# to the overall error, so its weights can be adjusted accordingly.
# Large delta = large contribution to error = large weight update needed.

class Neuron {
    [double[]]$Weights      # One weight per input connection
    [double]$Bias           # Baseline offset -- shifts activation threshold
    [double]$Output         # Result after activation function
    [double]$WeightedSum    # Raw result before activation (needed for derivative)
    [double]$Delta          # Error signal from backpropagation

    Neuron([int]$inputCount) {
        $this.Weights = New-Object double[] $inputCount

        # Random initialisation -- critical for breaking symmetry
        # If all weights were equal, all neurons would learn identically
        for ($i = 0; $i -lt $inputCount; $i++) {
            $this.Weights[$i] = (Get-Random -Minimum -0.5 -Maximum 0.5)
        }

        $this.Bias        = Get-Random -Minimum -0.5 -Maximum 0.5
        $this.Output      = 0.0
        $this.WeightedSum = 0.0
        $this.Delta       = 0.0
    }

    # Compute: w1.x1 + w2.x2 + ... + wn.xn + b
    # This is the "linear" part of the neuron before activation.
    [double] CalculateWeightedSum([double[]]$inputs) {
        if ($inputs.Count -ne $this.Weights.Count) {
            throw "Input count mismatch: expected $($this.Weights.Count), got $($inputs.Count)"
        }

        $sum = $this.Bias
        for ($i = 0; $i -lt $inputs.Count; $i++) {
            $sum += $inputs[$i] * $this.Weights[$i]
        }
        return $sum
    }

    # Forward pass: compute weighted sum, then apply activation function.
    # We store WeightedSum because the derivative needs it during backpropagation.
    [double] Forward([double[]]$inputs, [string]$activationType) {
        $this.WeightedSum = $this.CalculateWeightedSum($inputs)

        switch ($activationType) {
            "Sigmoid" { $this.Output = [Activation]::Sigmoid($this.WeightedSum) }
            "ReLU"    { $this.Output = [Activation]::ReLU($this.WeightedSum)    }
            "Tanh"    { $this.Output = [Activation]::Tanh($this.WeightedSum)    }
            "Linear"  { $this.Output = [Activation]::Linear($this.WeightedSum)  }
            default   { throw "Unknown activation: $activationType"              }
        }

        return $this.Output
    }

    # Update weights using gradient descent:
    # new_weight = old_weight + learning_rate x delta x input
    #
    # WHY THIS FORMULA
    # -----------------
    # Delta tells us the direction and magnitude of the error.
    # Input tells us how much this weight "caused" that error.
    # Learning rate controls how big a step we take (too big = overshooting,
    # too small = very slow learning).
    # We ADD because we want to move in the direction that reduces error.
    [void] UpdateWeights([double[]]$inputs, [double]$learningRate) {
        for ($i = 0; $i -lt $this.Weights.Count; $i++) {
            $this.Weights[$i] += $learningRate * $this.Delta * $inputs[$i]
        }
        # Bias has no input -- treated as if its input is always 1.0
        $this.Bias += $learningRate * $this.Delta
    }

    [hashtable] ExportState() {
        return @{ Weights = $this.Weights; Bias = $this.Bias }
    }

    [void] ImportState([hashtable]$state) {
        $this.Weights = $state.Weights
        $this.Bias    = $state.Bias
    }
}


# ============================================================================
# LAYER
# ============================================================================
#
# WHAT IS A LAYER
# -----------------
# A layer is a collection of neurons that all receive the same inputs
# and each produce one output. Layers are stacked to form the network:
#
#   Input layer  -> Hidden layer(s) -> Output layer
#
# Every neuron in a layer is independent -- they all see the same inputs
# but have different weights, so they learn to detect different features.
#
# THE FORWARD PASS (left to right):
# ----------------------------------
# Data flows forward through the network, each layer transforming it:
#   raw input -> hidden representation -> final prediction
#
# THE BACKWARD PASS (right to left):
# ------------------------------------
# Error flows backwards through the network, each layer receiving
# a signal telling it how much it contributed to the mistake.
# This is backpropagation -- the learning step.
#
# OUTPUT LAYER vs HIDDEN LAYER BACKPROPAGATION:
# ----------------------------------------------
# Output layer: delta = (target - output) x activation_derivative
#   We know directly how wrong the output was.
#
# Hidden layer: delta = (weighted sum of next layer deltas) x activation_derivative
#   We infer how wrong this layer was from how wrong the next layer was.
#   This is the "chain rule" from calculus -- errors propagate backwards
#   through the weights that connected the layers.

class Layer {
    [Neuron[]]$Neurons
    [int]$Size
    [string]$ActivationType
    [double[]]$Outputs
    [double[]]$Inputs      # Stored for weight updates during backprop

    Layer([int]$neuronCount, [int]$inputsPerNeuron, [string]$activation) {
        $this.Size           = $neuronCount
        $this.ActivationType = $activation
        $this.Neurons        = New-Object Neuron[] $neuronCount

        for ($i = 0; $i -lt $neuronCount; $i++) {
            $this.Neurons[$i] = New-Object Neuron -ArgumentList $inputsPerNeuron
        }

        $this.Outputs = New-Object double[] $neuronCount
        $this.Inputs  = @()
    }

    # Forward pass: each neuron independently processes the inputs
    # and produces one output. All outputs collected into Outputs array.
    [double[]] Forward([double[]]$inputs) {
        $this.Inputs = $inputs   # Store inputs -- needed for weight update

        for ($i = 0; $i -lt $this.Size; $i++) {
            $this.Outputs[$i] = $this.Neurons[$i].Forward($inputs, $this.ActivationType)
        }

        return $this.Outputs
    }

    # Backward pass: compute delta (error signal) for each neuron.
    # isOutputLayer determines which backprop formula to use.
    [void] Backward([double[]]$nextLayerDeltas, [Neuron[]]$nextLayerNeurons, [bool]$isOutputLayer) {
        if ($isOutputLayer) {
            # Output layer: delta comes directly from the error
            # delta = error_signal x activation_derivative
            for ($i = 0; $i -lt $this.Size; $i++) {
                $derivative = $this.GetActivationDerivative($this.Neurons[$i].WeightedSum)
                $this.Neurons[$i].Delta = $nextLayerDeltas[$i] * $derivative
            }
        } else {
            # Hidden layer: delta comes from the NEXT layer's deltas,
            # weighted by the connections going forward.
            # delta_i = activation_derivative x sum(delta_j x weight_ji)
            # This is the chain rule -- errors flow backwards through weights.
            for ($i = 0; $i -lt $this.Size; $i++) {
                $sum = 0.0

                for ($j = 0; $j -lt $nextLayerDeltas.Count; $j++) {
                    # weight_ji = weight FROM this neuron i TO next neuron j
                    $weight = $nextLayerNeurons[$j].Weights[$i]
                    $sum   += $nextLayerDeltas[$j] * $weight
                }

                $derivative = $this.GetActivationDerivative($this.Neurons[$i].WeightedSum)
                $this.Neurons[$i].Delta = $sum * $derivative
            }
        }
    }

    # Helper: get derivative of the activation function at the stored WeightedSum.
    # We use WeightedSum (before activation) because that is what the derivative needs.
    hidden [double] GetActivationDerivative([double]$weightedSum) {
        $result = 0.0

        switch ($this.ActivationType) {
            "Sigmoid" { $result = [Activation]::SigmoidDerivative($weightedSum) }
            "ReLU"    { $result = [Activation]::ReLUDerivative($weightedSum)    }
            "Tanh"    { $result = [Activation]::TanhDerivative($weightedSum)    }
            "Linear"  { $result = [Activation]::LinearDerivative($weightedSum)  }
            default   { throw "Unknown activation: $($this.ActivationType)"     }
        }

        return $result
    }

    # After deltas are computed, update every neuron's weights.
    # This is gradient descent -- moving weights in the direction that reduces error.
    [void] UpdateWeights([double]$learningRate) {
        foreach ($neuron in $this.Neurons) {
            $neuron.UpdateWeights($this.Inputs, $learningRate)
        }
    }

    [hashtable] ExportState() {
        $neuronsState = New-Object System.Collections.ArrayList
        foreach ($neuron in $this.Neurons) {
            $neuronsState.Add($neuron.ExportState()) | Out-Null
        }
        return @{
            Size           = $this.Size
            ActivationType = $this.ActivationType
            Neurons        = $neuronsState
        }
    }

    [void] ImportState([hashtable]$state) {
        if ($state.Size -ne $this.Size) {
            throw "Layer size mismatch: expected $($this.Size), got $($state.Size)"
        }
        for ($i = 0; $i -lt $this.Size; $i++) {
            $this.Neurons[$i].ImportState($state.Neurons[$i])
        }
    }
}


# ============================================================================
# NEURAL NETWORK
# ============================================================================
#
# THE COMPLETE TRAINING LOOP:
# ---------------------------
# Neural network training follows the same cycle for every sample:
#
#   1. FORWARD PASS
#      Feed input through all layers left to right.
#      Each layer transforms the data until we get a prediction.
#
#   2. COMPUTE ERROR
#      Compare prediction to the correct answer.
#      Error = (target - output)^2 / n  (Mean Squared Error)
#      Smaller error = better prediction.
#
#   3. BACKWARD PASS (Backpropagation)
#      Send the error signal backwards through all layers right to left.
#      Each layer computes how much it contributed to the error (delta).
#
#   4. UPDATE WEIGHTS
#      Adjust every weight slightly in the direction that reduces error.
#      learning_rate controls how big each adjustment is.
#
#   5. REPEAT
#      Do this thousands of times across all training samples.
#      Gradually the network learns to predict correctly.
#
# ARCHITECTURE:
# -------------
# The architecture is specified as an array of integers:
#   [2, 4, 1] = 2 inputs -> 4 hidden neurons -> 1 output
#   [3, 8, 8, 2] = 3 inputs -> 8 -> 8 -> 2 outputs
#
# More hidden neurons = more capacity to learn complex patterns.
# More layers = can learn more abstract representations.
# But more is not always better -- too many neurons causes overfitting
# (memorising training data instead of learning general patterns).
#
# MEAN SQUARED ERROR (MSE):
# --------------------------
# MSE = sum(target - output)^2 / n
# We square the difference so negative and positive errors don't cancel out.
# We divide by n to get an average across all outputs.
# A perfect prediction gives MSE = 0.

class NeuralNetwork {
    [Layer[]]$Layers
    [double]$LearningRate
    [int[]]$Architecture
    [System.Collections.ArrayList]$TrainingHistory   # MSE per epoch

    NeuralNetwork([int[]]$architecture, [double]$learningRate) {
        $this.Architecture    = $architecture
        $this.LearningRate    = $learningRate
        $this.TrainingHistory = New-Object System.Collections.ArrayList

        $layerCount   = $architecture.Count
        $this.Layers  = New-Object Layer[] ($layerCount - 1)

        # Create one layer per gap between architecture numbers.
        # [2, 4, 1] creates: Layer(4 neurons, 2 inputs) and Layer(1 neuron, 4 inputs)
        for ($i = 1; $i -lt $layerCount; $i++) {
            $inputSize  = $architecture[$i - 1]
            $outputSize = $architecture[$i]
            $activation = "Sigmoid"   # Default activation for all layers

            $this.Layers[$i - 1] = New-Object Layer -ArgumentList $outputSize, $inputSize, $activation
        }
    }

    # Forward pass: push input through every layer in sequence.
    # Output of layer N becomes input to layer N+1.
    [double[]] Forward([double[]]$inputs) {
        $current = $inputs
        foreach ($layer in $this.Layers) {
            $current = $layer.Forward($current)
        }
        return $current
    }

    # Predict is an alias for Forward -- same operation, clearer name for inference.
    [double[]] Predict([double[]]$inputs) {
        return $this.Forward($inputs)
    }

    # Backward pass: compute error signals and propagate backwards.
    # Must be called AFTER Forward so all Outputs and WeightedSums are set.
    [void] Backward([double[]]$target) {
        $outputLayer  = $this.Layers[$this.Layers.Count - 1]
        $output       = $outputLayer.Outputs

        # Compute error at output layer: how far off was the prediction
        $outputDeltas = New-Object double[] $output.Count
        for ($i = 0; $i -lt $output.Count; $i++) {
            $outputDeltas[$i] = $target[$i] - $output[$i]
        }

        # Propagate error backwards through all layers (right to left).
        # Each layer receives the error signal from the layer ahead of it.
        for ($layerIndex = $this.Layers.Count - 1; $layerIndex -ge 0; $layerIndex--) {
            $currentLayer = $this.Layers[$layerIndex]

            if ($layerIndex -eq ($this.Layers.Count - 1)) {
                # Output layer -- error comes directly from prediction vs target
                $currentLayer.Backward($outputDeltas, $null, $true)
            } else {
                # Hidden layer -- error comes from the next layer's deltas
                $nextLayer  = $this.Layers[$layerIndex + 1]
                $nextDeltas = New-Object double[] $nextLayer.Size

                for ($i = 0; $i -lt $nextLayer.Size; $i++) {
                    $nextDeltas[$i] = $nextLayer.Neurons[$i].Delta
                }

                $currentLayer.Backward($nextDeltas, $nextLayer.Neurons, $false)
            }

            # Update weights immediately after computing deltas for this layer
            $currentLayer.UpdateWeights($this.LearningRate)
        }
    }

    # Train on one sample: forward -> compute error -> backward -> return error.
    # This is stochastic gradient descent (SGD) -- update after each sample.
    [double] TrainSample([double[]]$input, [double[]]$target) {
        $output = $this.Forward($input)

        # Compute Mean Squared Error for this sample
        $sampleLoss = 0.0
        for ($i = 0; $i -lt $output.Count; $i++) {
            $diff   = $target[$i] - $output[$i]
            $sampleLoss += $diff * $diff
        }
        $sampleLoss = $sampleLoss / $output.Count

        $this.Backward($target)
        return $sampleLoss
    }

    # Train on all data for multiple epochs.
    # One epoch = one pass through the entire training dataset.
    # Multiple epochs allow the network to refine its weights iteratively.
    [hashtable] Train([array]$data, [int]$epochs, [int]$verbose) {
        $this.TrainingHistory.Clear()

        Write-Host "`nTraining Neural Network..." -ForegroundColor Cyan
        Write-Host "Architecture : $($this.Architecture -join ' -> ')" -ForegroundColor Gray
        Write-Host "Learning Rate: $($this.LearningRate)"             -ForegroundColor Gray
        Write-Host "Epochs       : $epochs"                           -ForegroundColor Gray
        Write-Host "Samples      : $($data.Count)"                    -ForegroundColor Gray
        Write-Host ""

        for ($epoch = 1; $epoch -le $epochs; $epoch++) {
            $totalError = 0.0

            # Train on every sample -- order matters for SGD
            foreach ($sample in $data) {
                $sampleLoss       = $this.TrainSample($sample.Input, $sample.Expected)
                $totalError += $sampleLoss
            }

            # Average error across all samples this epoch
            $avgError = $totalError / $data.Count
            $this.TrainingHistory.Add($avgError) | Out-Null

            if ($verbose -gt 0 -and ($epoch % $verbose -eq 0 -or $epoch -eq 1 -or $epoch -eq $epochs)) {
                $progress = ($epoch / $epochs) * 100
                Write-Host ("Epoch {0,5} / {1} ({2,5:N1}%) -- Error: {3:F6}" -f $epoch, $epochs, $progress, $avgError)
            }
        }

        Write-Host "`n  Training complete!" -ForegroundColor Green

        return @{
            FinalError   = $this.TrainingHistory[$this.TrainingHistory.Count - 1]
            ErrorHistory = $this.TrainingHistory
            Epochs       = $epochs
        }
    }

    # Overload: auto-calculate verbose interval (print 10 progress updates)
    [hashtable] Train([array]$data, [int]$epochs) {
        $verbose = [Math]::Max(1, [int]($epochs / 10))
        return $this.Train($data, $epochs, $verbose)
    }

    # Evaluate classification accuracy on a dataset.
    # threshold: predictions above this are classified as 1, below as 0.
    # Standard threshold is 0.5 -- but can be adjusted for imbalanced datasets.
    [hashtable] Evaluate([array]$data, [double]$threshold) {
        $correct = 0
        $total   = $data.Count

        foreach ($sample in $data) {
            $output    = $this.Predict($sample.Input)
            $predicted = if ($output[0] -ge $threshold) { 1 } else { 0 }
            $expected  = [int]$sample.Expected[0]

            if ($predicted -eq $expected) { $correct++ }
        }

        $accuracy = ($correct / $total) * 100

        return @{
            Correct  = $correct
            Total    = $total
            Accuracy = $accuracy
        }
    }

    # Overload: default threshold of 0.5
    [hashtable] Evaluate([array]$data) {
        return $this.Evaluate($data, 0.5)
    }

    # Export the entire network state to a hashtable for saving/loading.
    # Allows you to save a trained network and restore it later.
    [hashtable] ExportState() {
        $layersState = New-Object System.Collections.ArrayList
        foreach ($layer in $this.Layers) {
            $layersState.Add($layer.ExportState()) | Out-Null
        }
        return @{
            Architecture = $this.Architecture
            LearningRate = $this.LearningRate
            Layers       = $layersState
        }
    }

    [void] ImportState([hashtable]$state) {
        if ($state.Layers.Count -ne $this.Layers.Count) {
            throw "Layer count mismatch: expected $($this.Layers.Count), got $($state.Layers.Count)"
        }
        for ($i = 0; $i -lt $this.Layers.Count; $i++) {
            $this.Layers[$i].ImportState($state.Layers[$i])
        }
        $this.LearningRate = $state.LearningRate
    }
}

# ============================================================================
# QUICK REFERENCE
# ============================================================================
#
# TO USE THIS FILE:
#   . .\VBAF.Core.AllClasses.ps1
#
# TO CREATE A NETWORK:
#   $net = New-Object NeuralNetwork -ArgumentList @(2, 4, 1), 0.1
#   #                                                ^  ^  ^   ^
#   #                              2 inputs, 4 hidden, 1 output, learning rate 0.1
#
# TO TRAIN:
#   $data = @(
#       @{ Input = @(0.0, 0.0); Expected = @(0.0) }
#       @{ Input = @(0.0, 1.0); Expected = @(1.0) }
#   )
#   $result = $net.Train($data, 1000)
#
# TO PREDICT:
#   $output = $net.Predict(@(0.0, 1.0))
#
# TO EVALUATE:
#   $accuracy = $net.Evaluate($data)
#   Write-Host "Accuracy: $($accuracy.Accuracy)%"
#
# SEE ALSO:
#   examples\01-XOR-Network\  -- step-by-step tutorial using these classes
#   VBAF.RL.DQN.ps1           -- how these classes power a reinforcement learning agent
# ============================================================================
