# Neuron class with multiple inputs
class Neuron {

    [double]$Weight
    [double]$Bias
    [double]$LearningRate
    [double]$LastSum

    Neuron([double]$learningRate) {
        $this.Weight = (Get-Random -Minimum -1.0 -Maximum 1.0)
        $this.Bias   = (Get-Random -Minimum -1.0 -Maximum 1.0)
        $this.LearningRate = $learningRate
        $this.LastSum = 0
    }

    [int] Activate([double]$value) {
        if ($value -ge 0) { return 1 }
        return 0
    }

    [hashtable] Predict([double]$input) {
        $this.LastSum = ($input * $this.Weight) + $this.Bias
        $activation   = $this.Activate($this.LastSum)

        return @{
            Sum        = $this.LastSum
            Activation = $activation
        }
    }

    [hashtable] Learn([double]$input, [int]$expected) {
        $prediction = $this.Predict($input)
        $actual     = $prediction.Activation
        $error      = $expected - $actual

        $this.Weight += ($this.LearningRate * $error * $input)
        $this.Bias   += ($this.LearningRate * $error)

        return @{
            Input      = $input
            Expected   = $expected
            Actual     = $actual
            Error      = $error
            NewWeight  = $this.Weight
            NewBias    = $this.Bias
            Sum        = $this.LastSum
        }
    }

    [hashtable] ExportMemory() {
        return @{
            Version      = 1
            Weight       = $this.Weight
            Bias         = $this.Bias
            LearningRate = $this.LearningRate
        }
    }

    [void] ImportMemory([hashtable]$memory) {
        $this.Weight       = [double]$memory.Weight
        $this.Bias         = [double]$memory.Bias
        $this.LearningRate = [double]$memory.LearningRate
    }
}

$N = [Neuron]::new(0.1); $N
$N | Get-Member          # DET SAMME SOM NEDENSTÅENDE 
$members = Get-Member -InputObject $N; $members 
$N.Predict(1)
$N.Learn(1,0)
$exp = $N.ExportMemory(); $exp
$N.ImportMemory($exp); $exp

$N | Format-List *        # DET SAMME SOM NEDENSTÅENDE
Write-Host "Weight:       $($N.Weight)"
Write-Host "Bias:         $($N.Bias)"
Write-Host "LearningRate: $($N.LearningRate)"
Write-Host "LastSum:      $($N.LastSum)" 

$prediction = $N.Predict(1.5)
$prediction
$prediction | Get-Member

$result = $N.Learn(1.5, 1)
$result | Format-List *
$result | Get-Member

Write-Host "Weight after learning: $($N.Weight)"
Write-Host "Bias after learning:   $($N.Bias)"
Write-Host "LastSum stored:        $($N.LastSum)"



<#

If you want, I can help you extend this into:

✅ a multi‑input perceptron
✅ a full training loop
✅ a neural network with layers
✅ visualization of learning

#>