#Requires -Version 5.1

<#
.SYNOPSIS
    VBAF Core - All Classes in One File
.DESCRIPTION
    Combined file containing all neural network classes.
    This avoids PowerShell 5.1 class loading order issues.
.NOTES
    Part of VBAF (Visual Business Automation Framework)
#>

# ============================================================================
# ACTIVATION FUNCTIONS
# ============================================================================

class Activation {
    
    static [double] Sigmoid([double]$x) {
        if ($x -lt -500) { return 0.0 }
        if ($x -gt 500) { return 1.0 }
        return 1.0 / (1.0 + [Math]::Exp(-$x))
    }
    
    static [double] SigmoidDerivative([double]$x) {
        $s = [Activation]::Sigmoid($x)
        return $s * (1.0 - $s)
    }
    
    static [double] ReLU([double]$x) {
        if ($x -gt 0) { return $x } else { return 0.0 }
    }
    
    static [double] ReLUDerivative([double]$x) {
        if ($x -gt 0) { return 1.0 } else { return 0.0 }
    }
    
    static [double] Tanh([double]$x) {
        if ($x -lt -500) { return -1.0 }
        if ($x -gt 500) { return 1.0 }
        return [Math]::Tanh($x)
    }
    
    static [double] TanhDerivative([double]$x) {
        $t = [Math]::Tanh($x)
        return 1.0 - ($t * $t)
    }
    
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

class Neuron {
    [double[]]$Weights
    [double]$Bias
    [double]$Output
    [double]$WeightedSum
    [double]$Delta
    
    Neuron([int]$inputCount) {
        $this.Weights = New-Object double[] $inputCount
        
        for ($i = 0; $i -lt $inputCount; $i++) {
            $this.Weights[$i] = (Get-Random -Minimum -0.5 -Maximum 0.5)
        }
        
        $this.Bias = Get-Random -Minimum -0.5 -Maximum 0.5
        $this.Output = 0.0
        $this.WeightedSum = 0.0
        $this.Delta = 0.0
    }
    
    [double] CalculateWeightedSum([double[]]$inputs) {
        if ($inputs.Count -ne $this.Weights.Count) {
            throw "Input count mismatch"
        }
        
        $sum = $this.Bias
        for ($i = 0; $i -lt $inputs.Count; $i++) {
            $sum += $inputs[$i] * $this.Weights[$i]
        }
        return $sum
    }
    
    [double] Forward([double[]]$inputs, [string]$activationType) {
        $this.WeightedSum = $this.CalculateWeightedSum($inputs)
        
        switch ($activationType) {
            "Sigmoid" { $this.Output = [Activation]::Sigmoid($this.WeightedSum) }
            "ReLU" { $this.Output = [Activation]::ReLU($this.WeightedSum) }
            "Tanh" { $this.Output = [Activation]::Tanh($this.WeightedSum) }
            "Linear" { $this.Output = [Activation]::Linear($this.WeightedSum) }
            default { throw "Unknown activation: $activationType" }
        }
        
        return $this.Output
    }
    
    [void] UpdateWeights([double[]]$inputs, [double]$learningRate) {
        for ($i = 0; $i -lt $this.Weights.Count; $i++) {
            $this.Weights[$i] += $learningRate * $this.Delta * $inputs[$i]
        }
        $this.Bias += $learningRate * $this.Delta
    }
    
    [hashtable] ExportState() {
        return @{ Weights = $this.Weights; Bias = $this.Bias }
    }
    
    [void] ImportState([hashtable]$state) {
        $this.Weights = $state.Weights
        $this.Bias = $state.Bias
    }
}

# ============================================================================
# LAYER
# ============================================================================

class Layer {
    [Neuron[]]$Neurons
    [int]$Size
    [string]$ActivationType
    [double[]]$Outputs
    [double[]]$Inputs
    
    Layer([int]$neuronCount, [int]$inputsPerNeuron, [string]$activation) {
        $this.Size = $neuronCount
        $this.ActivationType = $activation
        $this.Neurons = New-Object Neuron[] $neuronCount
        
        for ($i = 0; $i -lt $neuronCount; $i++) {
            $this.Neurons[$i] = New-Object Neuron -ArgumentList $inputsPerNeuron
        }
        
        $this.Outputs = New-Object double[] $neuronCount
        $this.Inputs = @()
    }
    
    [double[]] Forward([double[]]$inputs) {
        $this.Inputs = $inputs
        
        for ($i = 0; $i -lt $this.Size; $i++) {
            $this.Outputs[$i] = $this.Neurons[$i].Forward($inputs, $this.ActivationType)
        }
        
        return $this.Outputs
    }
    
    [void] Backward([double[]]$nextLayerDeltas, [Neuron[]]$nextLayerNeurons, [bool]$isOutputLayer) {
        if ($isOutputLayer) {
            for ($i = 0; $i -lt $this.Size; $i++) {
                $derivative = $this.GetActivationDerivative($this.Neurons[$i].WeightedSum)
                $this.Neurons[$i].Delta = $nextLayerDeltas[$i] * $derivative
            }
        } else {
            for ($i = 0; $i -lt $this.Size; $i++) {
                $sum = 0.0
                
                for ($j = 0; $j -lt $nextLayerDeltas.Count; $j++) {
                    $weight = $nextLayerNeurons[$j].Weights[$i]
                    $sum += $nextLayerDeltas[$j] * $weight
                }
                
                $derivative = $this.GetActivationDerivative($this.Neurons[$i].WeightedSum)
                $this.Neurons[$i].Delta = $sum * $derivative
            }
        }
    }
    
    hidden [double] GetActivationDerivative([double]$weightedSum) {
        $result = 0.0
        
        switch ($this.ActivationType) {
            "Sigmoid" { $result = [Activation]::SigmoidDerivative($weightedSum) }
            "ReLU" { $result = [Activation]::ReLUDerivative($weightedSum) }
            "Tanh" { $result = [Activation]::TanhDerivative($weightedSum) }
            "Linear" { $result = [Activation]::LinearDerivative($weightedSum) }
            default { throw "Unknown activation: $($this.ActivationType)" }
        }
        
        return $result
    }
    
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
            Size = $this.Size
            ActivationType = $this.ActivationType
            Neurons = $neuronsState
        }
    }
    
    [void] ImportState([hashtable]$state) {
        if ($state.Size -ne $this.Size) {
            throw "Layer size mismatch"
        }
        for ($i = 0; $i -lt $this.Size; $i++) {
            $this.Neurons[$i].ImportState($state.Neurons[$i])
        }
    }
}

# ============================================================================
# NEURAL NETWORK
# ============================================================================

class NeuralNetwork {
    [Layer[]]$Layers
    [double]$LearningRate
    [int[]]$Architecture
    [System.Collections.ArrayList]$TrainingHistory
    
    NeuralNetwork([int[]]$architecture, [double]$learningRate) {
        $this.Architecture = $architecture
        $this.LearningRate = $learningRate
        $this.TrainingHistory = New-Object System.Collections.ArrayList
        
        $layerCount = $architecture.Count
        $this.Layers = New-Object Layer[] ($layerCount - 1)
        
        for ($i = 1; $i -lt $layerCount; $i++) {
            $inputSize = $architecture[$i - 1]
            $outputSize = $architecture[$i]
            
            if ($i -eq ($layerCount - 1)) {
                $activation = "Sigmoid"
            } else {
                $activation = "Sigmoid"
            }
            
            $this.Layers[$i - 1] = New-Object Layer -ArgumentList $outputSize, $inputSize, $activation
        }
    }
    
    [double[]] Forward([double[]]$inputs) {
        $current = $inputs
        foreach ($layer in $this.Layers) {
            $current = $layer.Forward($current)
        }
        return $current
    }
    
    [double[]] Predict([double[]]$inputs) {
        return $this.Forward($inputs)
    }
    
    [void] Backward([double[]]$target) {
        $outputLayer = $this.Layers[$this.Layers.Count - 1]
        $output = $outputLayer.Outputs
        
        $outputDeltas = New-Object double[] $output.Count
        for ($i = 0; $i -lt $output.Count; $i++) {
            $outputDeltas[$i] = $target[$i] - $output[$i]
        }
        
        for ($layerIndex = $this.Layers.Count - 1; $layerIndex -ge 0; $layerIndex--) {
            $currentLayer = $this.Layers[$layerIndex]
            
            if ($layerIndex -eq ($this.Layers.Count - 1)) {
                $currentLayer.Backward($outputDeltas, $null, $true)
            } else {
                $nextLayer = $this.Layers[$layerIndex + 1]
                $nextDeltas = New-Object double[] $nextLayer.Size
                
                for ($i = 0; $i -lt $nextLayer.Size; $i++) {
                    $nextDeltas[$i] = $nextLayer.Neurons[$i].Delta
                }
                
                $currentLayer.Backward($nextDeltas, $nextLayer.Neurons, $false)
            }
            
            $currentLayer.UpdateWeights($this.LearningRate)
        }
    }
    
    [double] TrainSample([double[]]$input, [double[]]$target) {
        $output = $this.Forward($input)
        
        $error = 0.0
        for ($i = 0; $i -lt $output.Count; $i++) {
            $diff = $target[$i] - $output[$i]
            $error += $diff * $diff
        }
        $error = $error / $output.Count
        
        $this.Backward($target)
        return $error
    }
    
    [hashtable] Train([array]$data, [int]$epochs, [int]$verbose) {
        $this.TrainingHistory.Clear()
        
        Write-Host "`nTraining Neural Network..." -ForegroundColor Cyan
        Write-Host "Architecture: $($this.Architecture -join ' → ')" -ForegroundColor Gray
        Write-Host "Learning Rate: $($this.LearningRate)" -ForegroundColor Gray
        Write-Host "Epochs: $epochs" -ForegroundColor Gray
        Write-Host "Training Samples: $($data.Count)" -ForegroundColor Gray
        Write-Host ""
        
        for ($epoch = 1; $epoch -le $epochs; $epoch++) {
            $totalError = 0.0
            
            foreach ($sample in $data) {
                $error = $this.TrainSample($sample.Input, $sample.Expected)
                $totalError += $error
            }
            
            $avgError = $totalError / $data.Count
            $this.TrainingHistory.Add($avgError) | Out-Null
            
            if ($verbose -gt 0 -and ($epoch % $verbose -eq 0 -or $epoch -eq 1 -or $epoch -eq $epochs)) {
                $progress = ($epoch / $epochs) * 100
                Write-Host ("Epoch {0,5} / {1} ({2,5:N1}%) - Error: {3:F6}" -f $epoch, $epochs, $progress, $avgError)
            }
        }
        
        Write-Host "`n✓ Training complete!" -ForegroundColor Green
        
        return @{
            FinalError = $this.TrainingHistory[$this.TrainingHistory.Count - 1]
            ErrorHistory = $this.TrainingHistory
            Epochs = $epochs
        }
    }
    
    [hashtable] Train([array]$data, [int]$epochs) {
        $verbose = [Math]::Max(1, [int]($epochs / 10))
        return $this.Train($data, $epochs, $verbose)
    }
    
    [hashtable] Evaluate([array]$data, [double]$threshold) {
        $correct = 0
        $total = $data.Count
        
        foreach ($sample in $data) {
            $output = $this.Predict($sample.Input)
            $predicted = if ($output[0] -ge $threshold) { 1 } else { 0 }
            $expected = [int]$sample.Expected[0]
            
            if ($predicted -eq $expected) {
                $correct++
            }
        }
        
        $accuracy = ($correct / $total) * 100
        
        return @{
            Correct = $correct
            Total = $total
            Accuracy = $accuracy
        }
    }
    
    [hashtable] Evaluate([array]$data) {
        return $this.Evaluate($data, 0.5)
    }
    
    [hashtable] ExportState() {
        $layersState = New-Object System.Collections.ArrayList
        foreach ($layer in $this.Layers) {
            $layersState.Add($layer.ExportState()) | Out-Null
        }
        return @{
            Architecture = $this.Architecture
            LearningRate = $this.LearningRate
            Layers = $layersState
        }
    }
    
    [void] ImportState([hashtable]$state) {
        if ($state.Layers.Count -ne $this.Layers.Count) {
            throw "Layer count mismatch"
        }
        for ($i = 0; $i -lt $this.Layers.Count; $i++) {
            $this.Layers[$i].ImportState($state.Layers[$i])
        }
        $this.LearningRate = $state.LearningRate
    }
}

 