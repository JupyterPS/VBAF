# Perceptron class with multiple inputs
class Perceptron {

    [double[]] $Weights
    [double]   $Bias
    [double]   $LearningRate
    [double]   $LastSum

    Perceptron([int]$inputCount, [double]$learningRate) {

        # Random weights for each input
        $this.Weights = @()
        for ($i = 0; $i -lt $inputCount; $i++) {
            $this.Weights += (Get-Random -Minimum -1.0 -Maximum 1.0)
        }

        $this.Bias         = (Get-Random -Minimum -1.0 -Maximum 1.0)
        $this.LearningRate = $learningRate
        $this.LastSum      = 0
    }

    [int] Activate([double]$value) {
        if ($value -ge 0) { return 1 }
        return 0
    }

    [hashtable] Predict([double[]]$inputs) {

        # Dot product: sum(w_i * x_i) + bias
        $sum = 0
        for ($i = 0; $i -lt $this.Weights.Count; $i++) {
            $sum += $inputs[$i] * $this.Weights[$i]
        }

        $sum += $this.Bias
        $this.LastSum = $sum

        return @{
            Sum        = $sum
            Activation = $this.Activate($sum)
        }
    }

    [hashtable] Learn([double[]]$inputs, [int]$expected) {

        $prediction = $this.Predict($inputs)
        $actual     = $prediction.Activation
        $error      = $expected - $actual

        # Update each weight
        for ($i = 0; $i -lt $this.Weights.Count; $i++) {
            $this.Weights[$i] += ($this.LearningRate * $error * $inputs[$i])
        }

        # Update bias
        $this.Bias += ($this.LearningRate * $error)

        return @{
            Inputs     = $inputs
            Expected   = $expected
            Actual     = $actual
            Error      = $error
            NewWeights = $this.Weights
            NewBias    = $this.Bias
            Sum        = $this.LastSum
        }
    }

    [hashtable] ExportMemory() {
        return @{
            Version      = 1
            Weights      = $this.Weights
            Bias         = $this.Bias
            LearningRate = $this.LearningRate
        }
    }

    [void] ImportMemory([hashtable]$memory) {
        $this.Weights      = [double[]]$memory.Weights
        $this.Bias         = [double]$memory.Bias
        $this.LearningRate = [double]$memory.LearningRate
    }
}

#___________________________________________________________________

# Usage
$P = [Perceptron]::new(3, 0.1)

$P.Predict( @(1, 0.5, -1) )

$P.Learn( @(1, 0.5, -1), 1 )

$P.ExportMemory()



# Full trainingloop
$data = @(
    @{ Input = @(0,0); Expected = 0 }
    @{ Input = @(0,1); Expected = 1 }
    @{ Input = @(1,0); Expected = 1 }
    @{ Input = @(1,1); Expected = 1 }
)

for ($epoch = 0; $epoch -lt 50; $epoch++) {
    foreach ($sample in $data) {
        $P.Learn($sample.Input, $sample.Expected) | Out-Null
    }
}

#__________________________________________________________________

# Training loop example (OR problem)
# Create a perceptron with 2 inputs and learning rate 0.1
$P = [Perceptron]::new(2, 0.1)

# Training data for OR
$data = @(
    @{ Input = @(0, 0); Expected = 0 }
    @{ Input = @(0, 1); Expected = 1 }
    @{ Input = @(1, 0); Expected = 1 }
    @{ Input = @(1, 1); Expected = 1 }
)

$epochs = 30

for ($epoch = 1; $epoch -le $epochs; $epoch++) {

    $totalError = 0

    foreach ($sample in $data) {
        $result = $P.Learn($sample.Input, $sample.Expected)
        $totalError += [math]::Abs($result.Error)
    }

    Write-Host "Epoch $epoch - Total Error: $totalError"
}

Write-Host "`nFinal weights: $($P.Weights -join ', ')"
Write-Host "Final bias:     $($P.Bias)"

# Test after training
foreach ($sample in $data) {
    $pred = $P.Predict($sample.Input)
    Write-Host "Input: $($sample.Input -join ', ')  Expected: $($sample.Expected)  Predicted: $($pred.Activation)"
}

