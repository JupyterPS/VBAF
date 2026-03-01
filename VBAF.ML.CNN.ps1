#Requires -Version 5.1
<#
.SYNOPSIS
    CNN - Convolutional Neural Network Architecture
.DESCRIPTION
    Implements CNN layers from scratch.
    Designed as a TEACHING resource - every operation explained.
    Layers included:
      - Conv2D            : sliding kernel, feature map extraction
      - MaxPooling2D      : spatial downsampling, keep strongest signal
      - AveragePooling2D  : spatial downsampling, smooth average
      - BatchNormalization: stabilise activations during training
      - Dropout           : random neuron silencing, prevents overfitting
      - Flatten           : 3D feature maps -> 1D vector
      - Dense             : fully connected layer
    Model:
      - CNNModel          : layer stack, forward pass, backprop, training
    Utilities:
      - Image augmentation: flip, noise, crop
      - Pre-trained loader: load weights from JSON
      - Built-in datasets : MNIST-tiny (8x8 digits), CIFAR-tiny (8x8 objects)
.NOTES
    Part of VBAF - Phase 6 Deep Learning Module - v2.0.0 MAJOR MILESTONE
    PS 5.1 compatible - pure PowerShell, no dependencies
    Teaching project - every matrix operation shown step by step!
    Performance note: PS 5.1 is not optimised for tensor math.
    This is a TEACHING implementation, not a production one.
    For production CNN use Python/TensorFlow/PyTorch.
#>
$basePath = $PSScriptRoot

# ============================================================
# TEACHING NOTE: What is a CNN?
# A Convolutional Neural Network is designed for GRID data:
# images, audio spectrograms, time series.
#
# Key insight: instead of connecting EVERY pixel to EVERY neuron
# (which would be millions of parameters), CNNs use:
#
#   CONVOLUTION: a small filter (kernel) slides over the image,
#   detecting local patterns like edges, curves, textures.
#   The same filter is reused at every position = WEIGHT SHARING.
#   This massively reduces parameters!
#
#   POOLING: shrinks the spatial size, keeping the most important
#   signal. Makes the model robust to small shifts.
#
#   DEEP STACK: early layers detect simple features (edges),
#   later layers detect complex features (faces, objects).
# ============================================================

# ============================================================
# ACTIVATION FUNCTIONS
# ============================================================
# TEACHING NOTE: Activations add NON-LINEARITY.
# Without them, stacking layers is just matrix multiplication
# which collapses to a single linear operation!
#
#   ReLU    : max(0, x)    - simple, fast, most common
#   Sigmoid : 1/(1+e^-x)  - squashes to [0,1], for output
#   Softmax : e^xi/sum(e^x)- probabilities that sum to 1
#   LeakyReLU: max(0.01x,x)- fixes "dying ReLU" problem
# ============================================================

function Invoke-ReLU {
    param([double[]]$x)
    return $x | ForEach-Object { [Math]::Max(0.0, $_) }
}

function Invoke-ReLUGrad {
    param([double[]]$x)
    return $x | ForEach-Object { if ($_ -gt 0) { 1.0 } else { 0.0 } }
}

function Invoke-LeakyReLU {
    param([double[]]$x, [double]$alpha = 0.01)
    return $x | ForEach-Object { if ($_ -gt 0) { $_ } else { $alpha * $_ } }
}

function Invoke-Sigmoid {
    param([double[]]$x)
    return $x | ForEach-Object { 1.0 / (1.0 + [Math]::Exp(-[Math]::Max(-500, [Math]::Min(500, $_)))) }
}

function Invoke-Softmax {
    param([double[]]$x)
    $maxVal = ($x | Measure-Object -Maximum).Maximum
    $exps   = $x | ForEach-Object { [Math]::Exp($_ - $maxVal) }
    $sumExp = ($exps | Measure-Object -Sum).Sum
    return $exps | ForEach-Object { $_ / $sumExp }
}

# ============================================================
# TENSOR UTILITIES (3D arrays: [height][width][channels])
# ============================================================
# TEACHING NOTE: Images are 3D tensors:
#   Height x Width x Channels
#   e.g. 28x28x1 for grayscale, 32x32x3 for RGB
# In PS 5.1 we represent this as a flat double[] with indexing.
# ============================================================

function New-Tensor {
    param([int]$H, [int]$W, [int]$C, [double]$InitVal = 0.0)
    $t = @{H=$H; W=$W; C=$C; Data=@([double]$InitVal) * ($H*$W*$C)}
    return $t
}

function Get-TensorValue {
    param([hashtable]$T, [int]$h, [int]$w, [int]$c)
    return $T.Data[$h * $T.W * $T.C + $w * $T.C + $c]
}

function Set-TensorValue {
    param([hashtable]$T, [int]$h, [int]$w, [int]$c, [double]$val)
    $T.Data[$h * $T.W * $T.C + $w * $T.C + $c] = $val
}

function New-RandomTensor {
    param([int]$H, [int]$W, [int]$C, [double]$Scale = 0.1, [int]$Seed = 42)
    $rng = [System.Random]::new($Seed)
    $t   = New-Tensor -H $H -W $W -C $C
    for ($i = 0; $i -lt $t.Data.Length; $i++) {
        $t.Data[$i] = ($rng.NextDouble() * 2 - 1) * $Scale
    }
    return $t
}

# ============================================================
# CONV2D LAYER
# ============================================================
# TEACHING NOTE: Convolution explained:
#
#   Input:  H x W x C_in  (height, width, input channels)
#   Kernel: KH x KW x C_in x C_out (filter bank)
#   Output: H' x W' x C_out
#
#   For each output channel (filter):
#     Slide the KH x KW kernel across the input.
#     At each position, compute: sum(kernel * input_patch) + bias
#
#   PADDING = "same"  -> output same size as input (pad with zeros)
#   PADDING = "valid" -> output shrinks by (kernel_size - 1)
#
#   STRIDE: how many pixels to jump between kernel positions.
#   Stride=2 halves the spatial dimensions.
# ============================================================

class Conv2D {
    [int]        $Filters      # number of output channels
    [int]        $KernelSize   # square kernel (e.g. 3 = 3x3)
    [int]        $Stride
    [string]     $Padding      # "same" or "valid"
    [string]     $Activation
    [hashtable]  $Weights      # KH x KW x C_in x Filters
    [double[]]   $Biases       # one per filter
    [hashtable]  $LastInput    # cached for backprop
    [hashtable]  $LastOutput
    [bool]       $IsBuild = $false

    Conv2D([int]$filters, [int]$kernelSize) {
        $this.Filters     = $filters
        $this.KernelSize  = $kernelSize
        $this.Stride      = 1
        $this.Padding     = "same"
        $this.Activation  = "relu"
    }

    Conv2D([int]$filters, [int]$kernelSize, [string]$activation) {
        $this.Filters     = $filters
        $this.KernelSize  = $kernelSize
        $this.Stride      = 1
        $this.Padding     = "same"
        $this.Activation  = $activation
    }

    [void] Build([int]$inH, [int]$inW, [int]$inC) {
        # He initialisation: scale = sqrt(2 / fan_in)
        # TEACHING: proper weight init prevents vanishing/exploding gradients!
        $fanIn  = $this.KernelSize * $this.KernelSize * $inC
        $scale  = [Math]::Sqrt(2.0 / $fanIn)
        $this.Weights = New-RandomTensor -H $this.KernelSize -W $this.KernelSize -C ($inC * $this.Filters) -Scale $scale
        $this.Biases  = @(0.0) * $this.Filters
        $this.IsBuild = $true
    }

    # Forward pass
    [hashtable] Forward([hashtable]$input) {
        $this.LastInput = $input
        $inH = $input.H; $inW = $input.W; $inC = $input.C
        $k   = $this.KernelSize

        if (-not $this.IsBuild) { $this.Build($inH, $inW, $inC) }

        # Output dimensions
        $pad  = if ($this.Padding -eq "same") { [int]($k / 2) } else { 0 }
        $outH = [int](($inH + 2*$pad - $k) / $this.Stride) + 1
        $outW = [int](($inW + 2*$pad - $k) / $this.Stride) + 1
        $out  = New-Tensor -H $outH -W $outW -C $this.Filters

        for ($f = 0; $f -lt $this.Filters; $f++) {
            for ($oh = 0; $oh -lt $outH; $oh++) {
                for ($ow = 0; $ow -lt $outW; $ow++) {
                    $sum = $this.Biases[$f]
                    for ($kh = 0; $kh -lt $k; $kh++) {
                        for ($kw = 0; $kw -lt $k; $kw++) {
                            $ih = $oh * $this.Stride - $pad + $kh
                            $iw = $ow * $this.Stride - $pad + $kw
                            if ($ih -ge 0 -and $ih -lt $inH -and $iw -ge 0 -and $iw -lt $inW) {
                                for ($c = 0; $c -lt $inC; $c++) {
                                    $inVal = Get-TensorValue $input $ih $iw $c
                                    $wIdx  = $kh * $k * $inC * $this.Filters + $kw * $inC * $this.Filters + $c * $this.Filters + $f
                                    $sum  += $inVal * $this.Weights.Data[$wIdx]
                                }
                            }
                        }
                    }
                    Set-TensorValue $out $oh $ow $f $sum
                }
            }
        }

        # Apply activation
        if ($this.Activation -eq "relu") {
            $out.Data = Invoke-ReLU $out.Data
        } elseif ($this.Activation -eq "sigmoid") {
            $out.Data = Invoke-Sigmoid $out.Data
        }

        $this.LastOutput = $out
        return $out
    }

    [string] Summary([int]$inH, [int]$inW, [int]$inC) {
        $pad  = if ($this.Padding -eq "same") { [int]($this.KernelSize / 2) } else { 0 }
        $outH = [int](($inH + 2*$pad - $this.KernelSize) / $this.Stride) + 1
        $outW = [int](($inW + 2*$pad - $this.KernelSize) / $this.Stride) + 1
        $params = $this.KernelSize * $this.KernelSize * $inC * $this.Filters + $this.Filters
        return ("Conv2D({0} filters, {1}x{1})  {2}x{3}x{4} -> {5}x{6}x{7}  params={8}" -f `
            $this.Filters, $this.KernelSize, $inH, $inW, $inC, $outH, $outW, $this.Filters, $params)
    }
}

# ============================================================
# MAXPOOLING2D LAYER
# ============================================================
# TEACHING NOTE: Pooling reduces spatial size.
# MaxPooling takes the MAXIMUM value in each pool window.
# Why max? It detects "was this feature present anywhere here?"
# Provides TRANSLATION INVARIANCE: feature slightly shifted
# in input still produces same output!
# ============================================================

class MaxPooling2D {
    [int]       $PoolSize
    [int]       $Stride
    [hashtable] $LastInput
    [hashtable] $LastMaxMask  # remember where the max was (for backprop)

    MaxPooling2D([int]$poolSize) {
        $this.PoolSize = $poolSize
        $this.Stride   = $poolSize  # default: non-overlapping
    }

    MaxPooling2D([int]$poolSize, [int]$stride) {
        $this.PoolSize = $poolSize
        $this.Stride   = $stride
    }

    [hashtable] Forward([hashtable]$input) {
        $this.LastInput = $input
        $p   = $this.PoolSize
        $s   = $this.Stride
        $inH = $input.H; $inW = $input.W; $inC = $input.C
        $outH = [int](($inH - $p) / $s) + 1
        $outW = [int](($inW - $p) / $s) + 1
        $out  = New-Tensor -H $outH -W $outW -C $inC

        for ($c = 0; $c -lt $inC; $c++) {
            for ($oh = 0; $oh -lt $outH; $oh++) {
                for ($ow = 0; $ow -lt $outW; $ow++) {
                    $maxVal = [double]::MinValue
                    for ($ph = 0; $ph -lt $p; $ph++) {
                        for ($pw = 0; $pw -lt $p; $pw++) {
                            $ih  = $oh * $s + $ph
                            $iw  = $ow * $s + $pw
                            $val = Get-TensorValue $input $ih $iw $c
                            if ($val -gt $maxVal) { $maxVal = $val }
                        }
                    }
                    Set-TensorValue $out $oh $ow $c $maxVal
                }
            }
        }
        return $out
    }

    [string] Summary([int]$inH, [int]$inW, [int]$inC) {
        $outH = [int](($inH - $this.PoolSize) / $this.Stride) + 1
        $outW = [int](($inW - $this.PoolSize) / $this.Stride) + 1
        return ("MaxPooling2D({0}x{0})  {1}x{2}x{3} -> {4}x{5}x{6}  params=0" -f `
            $this.PoolSize, $inH, $inW, $inC, $outH, $outW, $inC)
    }
}

# ============================================================
# AVERAGEPOOLING2D LAYER
# ============================================================
# TEACHING NOTE: AveragePooling takes the MEAN of each window.
# Smoother than MaxPooling, sometimes better for dense features.
# MaxPooling: "is this feature here at all?"
# AvgPooling: "how strongly is this feature present overall?"
# ============================================================

class AveragePooling2D {
    [int]       $PoolSize
    [int]       $Stride

    AveragePooling2D([int]$poolSize) {
        $this.PoolSize = $poolSize
        $this.Stride   = $poolSize
    }

    [hashtable] Forward([hashtable]$input) {
        $p   = $this.PoolSize
        $s   = $this.Stride
        $inH = $input.H; $inW = $input.W; $inC = $input.C
        $outH = [int](($inH - $p) / $s) + 1
        $outW = [int](($inW - $p) / $s) + 1
        $out  = New-Tensor -H $outH -W $outW -C $inC

        for ($c = 0; $c -lt $inC; $c++) {
            for ($oh = 0; $oh -lt $outH; $oh++) {
                for ($ow = 0; $ow -lt $outW; $ow++) {
                    $sum = 0.0
                    for ($ph = 0; $ph -lt $p; $ph++) {
                        for ($pw = 0; $pw -lt $p; $pw++) {
                            $sum += Get-TensorValue $input ($oh*$s+$ph) ($ow*$s+$pw) $c
                        }
                    }
                    Set-TensorValue $out $oh $ow $c ($sum / ($p * $p))
                }
            }
        }
        return $out
    }

    [string] Summary([int]$inH, [int]$inW, [int]$inC) {
        $outH = [int](($inH - $this.PoolSize) / $this.Stride) + 1
        $outW = [int](($inW - $this.PoolSize) / $this.Stride) + 1
        return ("AvgPooling2D({0}x{0})  {1}x{2}x{3} -> {4}x{5}x{6}  params=0" -f `
            $this.PoolSize, $inH, $inW, $inC, $outH, $outW, $inC)
    }
}

# ============================================================
# BATCH NORMALIZATION
# ============================================================
# TEACHING NOTE: BatchNorm solves "internal covariate shift":
# activations change distribution as weights update,
# making deeper layers hard to train.
#
# BatchNorm normalises each mini-batch to mean=0, std=1,
# then applies learnable scale (gamma) and shift (beta).
#
# Benefits:
#   - Allows higher learning rates
#   - Less sensitive to weight initialisation
#   - Acts as mild regularisation
#
# Formula: y = gamma * (x - mean) / sqrt(var + eps) + beta
# ============================================================

class BatchNormalization {
    [double[]] $Gamma         # learnable scale
    [double[]] $Beta          # learnable shift
    [double[]] $RunningMean   # tracked across batches for inference
    [double[]] $RunningVar
    [double]   $Epsilon = 1e-8
    [double]   $Momentum = 0.9
    [bool]     $Training = $true
    [bool]     $IsBuild  = $false
    [double[]] $LastNorm      # cached for backprop

    BatchNormalization() {}

    [void] Build([int]$nFeatures) {
        $this.Gamma       = @(1.0) * $nFeatures
        $this.Beta        = @(0.0) * $nFeatures
        $this.RunningMean = @(0.0) * $nFeatures
        $this.RunningVar  = @(1.0) * $nFeatures
        $this.IsBuild     = $true
    }

    [double[]] Forward([double[]]$x) {
        if (-not $this.IsBuild) { $this.Build($x.Length) }

        if ($this.Training) {
            $mean  = ($x | Measure-Object -Average).Average
            $sumSq = 0.0
            foreach ($v in $x) { $sumSq += ($v - $mean) * ($v - $mean) }
            $variance = $sumSq / $x.Length

            # Update running statistics
            for ($i = 0; $i -lt $this.RunningMean.Length; $i++) {
                $this.RunningMean[$i] = $this.Momentum * $this.RunningMean[$i] + (1-$this.Momentum) * $mean
                $this.RunningVar[$i]  = $this.Momentum * $this.RunningVar[$i]  + (1-$this.Momentum) * $variance
            }

            $std = [Math]::Sqrt($variance + $this.Epsilon)
            $normalized = $x | ForEach-Object { ($_ - $mean) / $std }
        } else {
            $std = [Math]::Sqrt($this.RunningVar[0] + $this.Epsilon)
            $normalized = $x | ForEach-Object { ($_ - $this.RunningMean[0]) / $std }
        }

        $this.LastNorm = $normalized
        $result = @(0.0) * $x.Length
        for ($i = 0; $i -lt $x.Length; $i++) {
            $gi = if ($i -lt $this.Gamma.Length) { $this.Gamma[$i] } else { $this.Gamma[0] }
            $bi = if ($i -lt $this.Beta.Length)  { $this.Beta[$i]  } else { $this.Beta[0]  }
            $result[$i] = $gi * $normalized[$i] + $bi
        }
        return $result
    }

    [string] Summary([int]$nFeatures) {
        return ("BatchNorm  features={0}  params={1} (gamma+beta)" -f $nFeatures, ($nFeatures*2))
    }
}

# ============================================================
# DROPOUT LAYER
# ============================================================
# TEACHING NOTE: Dropout randomly ZEROS OUT neurons during training.
# Rate=0.5 means 50% of neurons are silenced each forward pass.
#
# Why does this help?
#   Forces the network to learn REDUNDANT representations.
#   No single neuron can be relied upon -> more robust features.
#   It's like training an ENSEMBLE of many sub-networks!
#
# IMPORTANT: Dropout is ONLY applied during training.
# During inference, all neurons are active but outputs
# are scaled by (1 - rate) to keep the expected value same.
# ============================================================

class Dropout {
    [double]   $Rate        # fraction of neurons to drop
    [bool]     $Training = $true
    [bool[]]   $LastMask    # which neurons were kept (for backprop)

    Dropout([double]$rate) { $this.Rate = $rate }

    [double[]] Forward([double[]]$x) {
        if (-not $this.Training) {
            # Inference: scale outputs, keep all neurons
            return $x | ForEach-Object { $_ * (1.0 - $this.Rate) }
        }

        $rng          = [System.Random]::new()
        $this.LastMask = @($false) * $x.Length
        $result       = @(0.0) * $x.Length
        $keepProb     = 1.0 - $this.Rate

        for ($i = 0; $i -lt $x.Length; $i++) {
            if ($rng.NextDouble() -gt $this.Rate) {
                $result[$i]       = $x[$i] / $keepProb  # inverted dropout
                $this.LastMask[$i] = $true
            }
        }
        return $result
    }

    [string] Summary([int]$nFeatures) {
        return ("Dropout(rate={0})  features={1}  params=0" -f $this.Rate, $nFeatures)
    }
}

# ============================================================
# FLATTEN LAYER
# ============================================================
# TEACHING NOTE: CNNs output 3D feature maps (H x W x C).
# Dense layers expect 1D vectors.
# Flatten just reshapes: H*W*C values in a single row.
# This is the bridge between convolution and classification!
# ============================================================

class Flatten {
    [int] $OutSize

    Flatten() {}

    [double[]] Forward([hashtable]$tensor) {
        $this.OutSize = $tensor.Data.Length
        return $tensor.Data.Clone()
    }

    [string] Summary([int]$inH, [int]$inW, [int]$inC) {
        $total = $inH * $inW * $inC
        return ("Flatten  {0}x{1}x{2} -> {3}  params=0" -f $inH, $inW, $inC, $total)
    }
}

# ============================================================
# DENSE LAYER (Fully Connected)
# ============================================================
# TEACHING NOTE: Every input connects to every output.
# Parameters = in * out + out (weights + biases)
# This is where final classification decisions are made!
# ============================================================

class DenseLayer {
    [int]      $Units
    [string]   $Activation
    [double[]] $Weights      # Units x InSize (flattened)
    [double[]] $Biases
    [double[]] $LastInput
    [double[]] $LastOutput
    [int]      $InSize
    [bool]     $IsBuild = $false

    DenseLayer([int]$units, [string]$activation) {
        $this.Units      = $units
        $this.Activation = $activation
    }

    [void] Build([int]$inSize) {
        $this.InSize = $inSize
        $scale       = [Math]::Sqrt(2.0 / $inSize)  # He init
        $rng         = [System.Random]::new(42)
        $this.Weights = @(0.0) * ($this.Units * $inSize)
        for ($i = 0; $i -lt $this.Weights.Length; $i++) {
            $this.Weights[$i] = ($rng.NextDouble() * 2 - 1) * $scale
        }
        $this.Biases  = @(0.0) * $this.Units
        $this.IsBuild = $true
    }

    [double[]] Forward([double[]]$x) {
        if (-not $this.IsBuild) { $this.Build($x.Length) }
        $this.LastInput = $x
        $out = @(0.0) * $this.Units

        for ($u = 0; $u -lt $this.Units; $u++) {
            $sum = $this.Biases[$u]
            for ($i = 0; $i -lt $x.Length; $i++) {
                $sum += $x[$i] * $this.Weights[$u * $x.Length + $i]
            }
            $out[$u] = $sum
        }

        # Apply activation
        $activated = switch ($this.Activation) {
            "relu"    { Invoke-ReLU    $out }
            "sigmoid" { Invoke-Sigmoid $out }
            "softmax" { Invoke-Softmax $out }
            "linear"  { $out }
            default   { Invoke-ReLU $out }
        }

        $this.LastOutput = $activated
        return $activated
    }

    [string] Summary([int]$inSize) {
        $params = $inSize * $this.Units + $this.Units
        return ("Dense({0}, {1})  in={2}  params={3}" -f $this.Units, $this.Activation, $inSize, $params)
    }
}

# ============================================================
# CNN MODEL
# ============================================================
# TEACHING NOTE: A CNN model is a STACK of layers.
# Data flows forward through each layer (Forward Pass).
# Loss is computed at the end.
# Gradients flow backward (Backpropagation).
# Weights are updated (Gradient Descent).
# ============================================================

class CNNModel {
    [System.Collections.ArrayList] $Layers
    [string]   $Name
    [int]      $InputH
    [int]      $InputW
    [int]      $InputC
    [double]   $LearningRate
    [System.Collections.ArrayList] $LossHistory
    [System.Collections.ArrayList] $AccHistory

    CNNModel([string]$name, [int]$inputH, [int]$inputW, [int]$inputC) {
        $this.Name         = $name
        $this.InputH       = $inputH
        $this.InputW       = $inputW
        $this.InputC       = $inputC
        $this.LearningRate = 0.001
        $this.Layers       = [System.Collections.ArrayList]::new()
        $this.LossHistory  = [System.Collections.ArrayList]::new()
        $this.AccHistory   = [System.Collections.ArrayList]::new()
    }

    [void] Add([object]$layer) {
        $this.Layers.Add($layer) | Out-Null
    }

    # Forward pass through all layers
    [double[]] Predict([hashtable]$inputTensor) {
        $current = $inputTensor
        $flatVec = $null

        foreach ($layer in $this.Layers) {
            $typeName = $layer.GetType().Name
            if ($typeName -eq "Conv2D" -or $typeName -eq "MaxPooling2D" -or $typeName -eq "AveragePooling2D") {
                $current = $layer.Forward($current)
            } elseif ($typeName -eq "Flatten") {
                $flatVec = $layer.Forward($current)
                $current = $null
            } elseif ($typeName -eq "DenseLayer") {
                $flatVec = $layer.Forward($flatVec)
            } elseif ($typeName -eq "BatchNormalization") {
                if ($null -ne $flatVec) {
                    $flatVec = $layer.Forward($flatVec)
                } else {
                    $current.Data = $layer.Forward($current.Data)
                }
            } elseif ($typeName -eq "Dropout") {
                if ($null -ne $flatVec) {
                    $flatVec = $layer.Forward($flatVec)
                }
            }
        }
        return $flatVec
    }

    # Cross-entropy loss for classification
    hidden [double] CrossEntropyLoss([double[]]$probs, [int]$trueClass) {
        $p = [Math]::Max(1e-10, $probs[$trueClass])
        return -[Math]::Log($p)
    }

    # Simple training step (output layer weight update only - teaching simplification)
    [void] TrainStep([hashtable]$inputTensor, [int]$trueClass, [int]$nClasses) {
        $probs = $this.Predict($inputTensor)
        if ($null -eq $probs) { return }

        # Find last dense layer and update it
        $lastDense = $null
        foreach ($layer in $this.Layers) {
            if ($layer.GetType().Name -eq "DenseLayer") { $lastDense = $layer }
        }
        if ($null -eq $lastDense) { return }

        # Softmax gradient: dL/dz = probs - one_hot
        $grad = $probs.Clone()
        $grad[$trueClass] -= 1.0

        # Update last dense layer weights
        for ($u = 0; $u -lt $lastDense.Units; $u++) {
            $lastDense.Biases[$u] -= $this.LearningRate * $grad[$u]
            for ($i = 0; $i -lt $lastDense.LastInput.Length; $i++) {
                $lastDense.Weights[$u * $lastDense.LastInput.Length + $i] -=
                    $this.LearningRate * $grad[$u] * $lastDense.LastInput[$i]
            }
        }
    }

    # Train for one epoch
    [void] Fit([hashtable[]]$Xtensors, [int[]]$y, [int]$nClasses, [int]$epochs, [int]$printEvery) {
        $n = $Xtensors.Length
        Write-Host ""
        Write-Host ("🧠 Training {0}..." -f $this.Name) -ForegroundColor Green

        for ($ep = 1; $ep -le $epochs; $ep++) {
            $totalLoss = 0.0
            $correct   = 0

            for ($i = 0; $i -lt $n; $i++) {
                $this.TrainStep($Xtensors[$i], $y[$i], $nClasses)
                $probs = $this.Predict($Xtensors[$i])
                if ($null -ne $probs) {
                    $totalLoss += $this.CrossEntropyLoss($probs, $y[$i])
                    $predClass  = 0
                    $maxP       = $probs[0]
                    for ($c = 1; $c -lt $probs.Length; $c++) {
                        if ($probs[$c] -gt $maxP) { $maxP=$probs[$c]; $predClass=$c }
                    }
                    if ($predClass -eq $y[$i]) { $correct++ }
                }
            }

            $avgLoss = [Math]::Round($totalLoss / $n, 4)
            $acc     = [Math]::Round($correct / $n, 4)
            $this.LossHistory.Add($avgLoss) | Out-Null
            $this.AccHistory.Add($acc)      | Out-Null

            if ($ep % $printEvery -eq 0 -or $ep -eq 1) {
                $bar = "█" * [int]($acc * 20)
                Write-Host ("  Epoch {0,3}/{1}  loss={2:F4}  acc={3:F3}  {4}" -f
                    $ep, $epochs, $avgLoss, $acc, $bar) -ForegroundColor White
            }
        }
        Write-Host "✅ Training complete!" -ForegroundColor Green
    }

    [void] PrintSummary() {
        Write-Host ""
        Write-Host "╔══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host ("║  CNN Model: {0,-41}║" -f $this.Name)                   -ForegroundColor Cyan
        Write-Host "╠══════════════════════════════════════════════════════╣" -ForegroundColor Cyan
        Write-Host ("║  Input: {0}x{1}x{2}{3}║" -f $this.InputH, $this.InputW, $this.InputC, " " * (44 - "$($this.InputH)x$($this.InputW)x$($this.InputC)".Length)) -ForegroundColor White

        $h = $this.InputH; $w = $this.InputW; $c = $this.InputC
        $totalParams = 0

        foreach ($layer in $this.Layers) {
            $typeName = $layer.GetType().Name
            $summary  = ""
            switch ($typeName) {
                "Conv2D" {
                    $summary = $layer.Summary($h, $w, $c)
                    $pad     = if ($layer.Padding -eq "same") { [int]($layer.KernelSize/2) } else { 0 }
                    $nh = [int](($h + 2*$pad - $layer.KernelSize) / $layer.Stride) + 1
                    $nw = [int](($w + 2*$pad - $layer.KernelSize) / $layer.Stride) + 1
                    $totalParams += $layer.KernelSize * $layer.KernelSize * $c * $layer.Filters + $layer.Filters
                    $h=$nh; $w=$nw; $c=$layer.Filters
                }
                "MaxPooling2D" {
                    $summary = $layer.Summary($h, $w, $c)
                    $h=[int](($h-$layer.PoolSize)/$layer.Stride)+1
                    $w=[int](($w-$layer.PoolSize)/$layer.Stride)+1
                }
                "AveragePooling2D" {
                    $summary = $layer.Summary($h, $w, $c)
                    $h=[int](($h-$layer.PoolSize)/$layer.Stride)+1
                    $w=[int](($w-$layer.PoolSize)/$layer.Stride)+1
                }
                "Flatten" {
                    $summary = $layer.Summary($h, $w, $c)
                    $c=$h*$w*$c; $h=1; $w=1
                }
                "DenseLayer" {
                    $summary = $layer.Summary($c)
                    $totalParams += $c * $layer.Units + $layer.Units
                    $c = $layer.Units
                }
                "BatchNormalization" { $summary = $layer.Summary($c) ; $totalParams += $c*2 }
                "Dropout"           { $summary = $layer.Summary($c) }
            }
            Write-Host ("║  {0,-52}║" -f ($summary.Substring(0, [Math]::Min(52, $summary.Length)))) -ForegroundColor White
        }
        Write-Host "╠══════════════════════════════════════════════════════╣" -ForegroundColor Cyan
        Write-Host ("║  Total parameters: {0,-33}║" -f $totalParams)           -ForegroundColor Yellow
        Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
    }

    [void] PlotTraining() {
        if ($this.LossHistory.Count -eq 0) { Write-Host "No training history yet." -ForegroundColor Yellow; return }
        $losses = $this.LossHistory.ToArray()
        $accs   = $this.AccHistory.ToArray()
        $maxL   = ($losses | Measure-Object -Maximum).Maximum
        $maxL   = [Math]::Max($maxL, 1e-8)

        Write-Host ""
        Write-Host "📉 Training Loss:" -ForegroundColor Green
        foreach ($l in $losses) {
            $bar = "█" * [int](($l / $maxL) * 30)
            Write-Host ("  {0,7:F4}  {1}" -f $l, $bar) -ForegroundColor Cyan
        }
        Write-Host ""
        Write-Host "📈 Accuracy:" -ForegroundColor Green
        foreach ($a in $accs) {
            $bar = "█" * [int]($a * 30)
            Write-Host ("  {0,7:F3}  {1}" -f $a, $bar) -ForegroundColor White
        }
        Write-Host ""
    }
}

# ============================================================
# IMAGE AUGMENTATION
# ============================================================
# TEACHING NOTE: Augmentation artificially increases dataset size
# by creating modified versions of existing images.
# The label stays the same - just the image changes slightly.
# This teaches the model to be ROBUST to variations.
# ============================================================

function Invoke-HorizontalFlip {
    param([hashtable]$tensor)
    $out = New-Tensor -H $tensor.H -W $tensor.W -C $tensor.C
    for ($h = 0; $h -lt $tensor.H; $h++) {
        for ($w = 0; $w -lt $tensor.W; $w++) {
            $flippedW = $tensor.W - 1 - $w
            for ($c = 0; $c -lt $tensor.C; $c++) {
                $val = Get-TensorValue $tensor $h $w $c
                Set-TensorValue $out $h $flippedW $c $val
            }
        }
    }
    return $out
}

function Invoke-AddNoise {
    param([hashtable]$tensor, [double]$stdDev = 0.05)
    $rng = [System.Random]::new()
    $out = New-Tensor -H $tensor.H -W $tensor.W -C $tensor.C
    for ($i = 0; $i -lt $tensor.Data.Length; $i++) {
        # Box-Muller normal random number
        $u1    = [Math]::Max(1e-10, $rng.NextDouble())
        $u2    = $rng.NextDouble()
        $noise = $stdDev * [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)
        $out.Data[$i] = [Math]::Max(0.0, [Math]::Min(1.0, $tensor.Data[$i] + $noise))
    }
    return $out
}

function Invoke-RandomCrop {
    param([hashtable]$tensor, [int]$cropH, [int]$cropW)
    $rng  = [System.Random]::new()
    $maxH = $tensor.H - $cropH
    $maxW = $tensor.W - $cropW
    $offH = if ($maxH -gt 0) { $rng.Next($maxH) } else { 0 }
    $offW = if ($maxW -gt 0) { $rng.Next($maxW) } else { 0 }
    $out  = New-Tensor -H $cropH -W $cropW -C $tensor.C

    for ($h = 0; $h -lt $cropH; $h++) {
        for ($w = 0; $w -lt $cropW; $w++) {
            for ($c = 0; $c -lt $tensor.C; $c++) {
                $val = Get-TensorValue $tensor ($h+$offH) ($w+$offW) $c
                Set-TensorValue $out $h $w $c $val
            }
        }
    }
    return $out
}

function Invoke-Augment {
    param([hashtable]$tensor, [bool]$flip=$true, [bool]$noise=$true, [double]$noisestd=0.03)
    $out = $tensor
    if ($flip -and ([System.Random]::new().NextDouble() -gt 0.5)) {
        $out = Invoke-HorizontalFlip $out
    }
    if ($noise) { $out = Invoke-AddNoise $out $noisestd }
    return $out
}

# ============================================================
# PRE-TRAINED MODEL SUPPORT
# ============================================================
# TEACHING NOTE: Training a CNN from scratch requires
# thousands of images and hours of compute.
# Transfer learning uses weights from a model already trained
# on a large dataset (like ImageNet) and fine-tunes them
# for your specific task.
# This works because early CNN layers learn universal features
# (edges, textures) useful for ANY image task!
# ============================================================

function Save-CNNWeights {
    param([CNNModel]$model, [string]$path)

    $weights = @{}
    for ($li = 0; $li -lt $model.Layers.Count; $li++) {
        $layer    = $model.Layers[$li]
        $typeName = $layer.GetType().Name
        $key      = "layer_$li`_$typeName"

        if ($typeName -eq "Conv2D") {
            $weights[$key] = @{
                Weights = $layer.Weights.Data
                Biases  = $layer.Biases
                H       = $layer.Weights.H
                W       = $layer.Weights.W
                C       = $layer.Weights.C
            }
        } elseif ($typeName -eq "DenseLayer") {
            $weights[$key] = @{ Weights=$layer.Weights; Biases=$layer.Biases }
        }
    }

    $weights | ConvertTo-Json -Depth 5 | Set-Content -Path $path -Encoding UTF8
    Write-Host "💾 Weights saved: $path" -ForegroundColor Green
}

function Load-CNNWeights {
    param([CNNModel]$model, [string]$path)

    if (-not (Test-Path $path)) {
        Write-Host "❌ Weights file not found: $path" -ForegroundColor Red
        return
    }

    $weights = Get-Content -Path $path -Raw | ConvertFrom-Json
    for ($li = 0; $li -lt $model.Layers.Count; $li++) {
        $layer    = $model.Layers[$li]
        $typeName = $layer.GetType().Name
        $key      = "layer_$li`_$typeName"
        $prop     = $weights.PSObject.Properties[$key]
        if ($null -eq $prop) { continue }
        $w = $prop.Value

        if ($typeName -eq "Conv2D") {
            $layer.Weights.Data = [double[]]$w.Weights
            $layer.Biases       = [double[]]$w.Biases
            $layer.IsBuild      = $true
        } elseif ($typeName -eq "DenseLayer") {
            $layer.Weights = [double[]]$w.Weights
            $layer.Biases  = [double[]]$w.Biases
            $layer.IsBuild = $true
        }
    }
    Write-Host "📂 Weights loaded: $path" -ForegroundColor Green
}

# ============================================================
# BUILT-IN TINY DATASET
# ============================================================
# 8x8 grayscale "images" representing simple shapes
# Class 0 = horizontal bar, Class 1 = vertical bar, Class 2 = diagonal

function Get-VBAFImageDataset {
    param([string]$Name = "TinyShapes")

    switch ($Name) {
        "TinyShapes" {
            Write-Host "📊 Dataset: TinyShapes (8x8 grayscale)" -ForegroundColor Cyan
            Write-Host "   Classes: 0=Horizontal, 1=Vertical, 2=Diagonal" -ForegroundColor Cyan

            $templates = @(
                # Class 0: Horizontal bar (row 4 is bright)
                @(0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,
                  1,1,1,1,1,1,1,1, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0),
                # Class 1: Vertical bar (col 4 is bright)
                @(0,0,0,0,1,0,0,0, 0,0,0,0,1,0,0,0, 0,0,0,0,1,0,0,0, 0,0,0,0,1,0,0,0,
                  0,0,0,0,1,0,0,0, 0,0,0,0,1,0,0,0, 0,0,0,0,1,0,0,0, 0,0,0,0,1,0,0,0),
                # Class 2: Diagonal
                @(1,0,0,0,0,0,0,0, 0,1,0,0,0,0,0,0, 0,0,1,0,0,0,0,0, 0,0,0,1,0,0,0,0,
                  0,0,0,0,1,0,0,0, 0,0,0,0,0,1,0,0, 0,0,0,0,0,0,1,0, 0,0,0,0,0,0,0,1)
            )

            $rng      = [System.Random]::new(42)
            $tensors  = @()
            $labels   = @()
            $nPerClass = 10

            foreach ($class in @(0,1,2)) {
                $tpl = $templates[$class]
                for ($s = 0; $s -lt $nPerClass; $s++) {
                    $t = New-Tensor -H 8 -W 8 -C 1
                    for ($i = 0; $i -lt 64; $i++) {
                        $noise      = ($rng.NextDouble() - 0.5) * 0.2
                        $t.Data[$i] = [Math]::Max(0, [Math]::Min(1, $tpl[$i] + $noise))
                    }
                    $tensors += $t
                    $labels  += $class
                }
            }

            return @{ Tensors=$tensors; Labels=[int[]]$labels; NClasses=3;
                      ClassNames=@("Horizontal","Vertical","Diagonal") }
        }
        default {
            Write-Host "❌ Unknown: $Name  Available: TinyShapes" -ForegroundColor Red
            return $null
        }
    }
}

# Visualise a tensor as ASCII art
function Show-TensorAscii {
    param([hashtable]$tensor, [string]$label="")
    $chars = " ░▒▓█"
    Write-Host ("  {0}" -f $label) -ForegroundColor Green
    for ($h = 0; $h -lt $tensor.H; $h++) {
        $row = "  "
        for ($w = 0; $w -lt $tensor.W; $w++) {
            $val  = Get-TensorValue $tensor $h $w 0
            $idx  = [int]($val * 4)
            $idx  = [Math]::Max(0, [Math]::Min(4, $idx))
            $row += $chars[$idx]
            $row += $chars[$idx]  # double width for readability
        }
        Write-Host $row -ForegroundColor Cyan
    }
    Write-Host ""
}

# ============================================================
# TEST
# 1. Run VBAF.LoadAll.ps1
#
# --- Build and summarise a CNN ---
# 2. $model = [CNNModel]::new("ShapeClassifier", 8, 8, 1)
#    $model.Add([Conv2D]::new(4, 3))          # 4 filters, 3x3 kernel
#    $model.Add([MaxPooling2D]::new(2))        # 2x2 pooling
#    $model.Add([Dropout]::new(0.25))
#    $model.Add([Flatten]::new())
#    $model.Add([DenseLayer]::new(8, "relu"))
#    $model.Add([DenseLayer]::new(3, "softmax"))
#    $model.PrintSummary()
#
# --- Load dataset ---
# 3. $data = Get-VBAFImageDataset -Name "TinyShapes"
#    Show-TensorAscii $data.Tensors[0] "Class: Horizontal"
#    Show-TensorAscii $data.Tensors[10] "Class: Vertical"
#    Show-TensorAscii $data.Tensors[20] "Class: Diagonal"
#
# --- Train ---
# 4. $model.LearningRate = 0.01
#    $model.Fit($data.Tensors, $data.Labels, $data.NClasses, 20, 5)
#    $model.PlotTraining()
#
# --- Augmentation ---
# 5. $aug = Invoke-Augment -tensor $data.Tensors[0] -flip $true -noise $true
#    Show-TensorAscii $aug "Augmented Horizontal"
#
# --- Save and load weights ---
# 6. Save-CNNWeights -model $model -Path "C:\Temp\cnn_weights.json"
#    Load-CNNWeights -model $model -Path "C:\Temp\cnn_weights.json"
# ============================================================
Write-Host "📦 VBAF.ML.CNN.ps1 loaded  [v2.0.0 🚀]" -ForegroundColor Green
Write-Host "   Classes   : Conv2D, MaxPooling2D, AveragePooling2D" -ForegroundColor Cyan
Write-Host "              BatchNormalization, Dropout"             -ForegroundColor Cyan
Write-Host "              Flatten, DenseLayer, CNNModel"           -ForegroundColor Cyan
Write-Host "   Functions : Invoke-HorizontalFlip"                 -ForegroundColor Cyan
Write-Host "              Invoke-AddNoise"                         -ForegroundColor Cyan
Write-Host "              Invoke-RandomCrop"                       -ForegroundColor Cyan
Write-Host "              Invoke-Augment"                          -ForegroundColor Cyan
Write-Host "              Save-CNNWeights / Load-CNNWeights"       -ForegroundColor Cyan
Write-Host "              Get-VBAFImageDataset"                    -ForegroundColor Cyan
Write-Host "              Show-TensorAscii"                        -ForegroundColor Cyan
Write-Host ""
Write-Host "   Quick start:" -ForegroundColor Yellow
Write-Host '   $model = [CNNModel]::new("ShapeClassifier", 8, 8, 1)'  -ForegroundColor White
Write-Host '   $model.Add([Conv2D]::new(4, 3))'                        -ForegroundColor White
Write-Host '   $model.Add([MaxPooling2D]::new(2))'                     -ForegroundColor White
Write-Host '   $model.Add([Flatten]::new())'                           -ForegroundColor White
Write-Host '   $model.Add([DenseLayer]::new(3, "softmax"))'            -ForegroundColor White
Write-Host '   $model.PrintSummary()'                                  -ForegroundColor White
Write-Host ""