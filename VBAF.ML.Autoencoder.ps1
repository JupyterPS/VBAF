# ==============================================================================
#  VBAF.ML.Autoencoder.ps1
#  Visual Brain AI Framework — Autoencoder Module
#  Version  : v1.0.0  |  Requires PS 5.1  |  Part of VBAF v2.1.0
# ==============================================================================
#
#  ARCHITECTURE
#  ------------
#  BasicAutoencoder  — symmetric encoder/decoder, MSE loss, SGD
#
#  PS 5.1 IMPLEMENTATION STRATEGY
#  --------------------------------
#  • Layers are HASHTABLES stored in ArrayLists (always references → mutations persist)
#  • Forward / backward are STANDALONE FUNCTIONS (not class methods)
#  • Class is a thin WRAPPER: stores ArrayLists, delegates work to functions
#  • Functions called inside class methods use:  & (Get-Command FuncName) -Param val
#  • No typed [Type[]] properties — all arrays live inside hashtables
#  • Index loops (for) everywhere — no foreach/ForEach-Object/switch on arrays
#
#  QUICK START
#  -----------
#    . .\VBAF.ML.Autoencoder.ps1
#    $ds  = Get-VBAFAEDataset -Name Shapes2D
#    $ae  = [BasicAutoencoder]::new(16, @(8, 4), 2)
#    $r   = Invoke-VBAFAETrain -Model $ae -Data $ds.X -Epochs 200 -LR 0.05 -PrintEvery 20
#    $r.FinalLoss                                        # should be < 0.15
#    $enc = Get-VBAFLatent -Model $ae -Data $ds.X -Labels $ds.Labels
#    Show-VBAFLatentSpace -Latents $enc -ClassNames $ds.ClassNames
#    Show-VBAFReconstruction -Model $ae -X $ds.X[0] -Label 'HBar'
# ==============================================================================

Write-Host ''
Write-Host '  ╔══════════════════════════════════════════════╗' -ForegroundColor Cyan
Write-Host '  ║   VBAF · Autoencoder Module  v1.0.0          ║' -ForegroundColor Cyan
Write-Host '  ║   BasicAutoencoder  |  Shapes2D dataset       ║' -ForegroundColor Cyan
Write-Host '  ║   PS 5.1  |  Hashtable-reference backprop     ║' -ForegroundColor Cyan
Write-Host '  ╚══════════════════════════════════════════════╝' -ForegroundColor Cyan
Write-Host ''

# ==============================================================================
#  DATASET
# ==============================================================================

function Get-VBAFAEDataset {
<#
.SYNOPSIS
    Returns a named dataset for autoencoder experiments.

.PARAMETER Name
    'Shapes2D'  — 16-dim binary patterns, 3 classes, 30 samples.
    Each class is a 4×4 grid representing a distinct geometric shape.

.OUTPUTS
    Hashtable:
        X          — ArrayList of [double[]]  (30 × 16)
        Labels     — ArrayList of [int]
        ClassNames — string[]  ('HBar','VBar','Diag')
        InputDim   — 16
        NumClasses — 3
        NumSamples — 30

.EXAMPLE
    $ds = Get-VBAFAEDataset -Name Shapes2D
    $ds.X[0]       # first sample as double[]
    $ds.Labels[0]  # class index
#>
    param(
        [Parameter(Mandatory)][string]$Name
    )

    if ($Name -ne 'Shapes2D') {
        throw "Unknown dataset '$Name'. Available: Shapes2D"
    }

    # ── Base patterns (4×4 binary grids, row-major) ──────────────────────────
    #
    # Class 0 – HBar  (top and bottom rows lit)
    # █ █ █ █
    # · · · ·
    # · · · ·
    # █ █ █ █
    $base0 = [double[]](1,1,1,1, 0,0,0,0, 0,0,0,0, 1,1,1,1)

    # Class 1 – VBar  (left and right columns lit)
    # █ · · █
    # █ · · █
    # █ · · █
    # █ · · █
    $base1 = [double[]](1,0,0,1, 1,0,0,1, 1,0,0,1, 1,0,0,1)

    # Class 2 – Diag  (main diagonal lit)
    # █ · · ·
    # · █ · ·
    # · · █ ·
    # · · · █
    $base2 = [double[]](1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1)

    $bases  = @($base0, $base1, $base2)
    $X      = [System.Collections.ArrayList]::new()
    $Labels = [System.Collections.ArrayList]::new()

    # 10 samples per class — each is the base pattern with ~10% random bit flips
    # Seeds are deterministic so the dataset is reproducible
    for ($cls = 0; $cls -lt 3; $cls++) {
        $base = $bases[$cls]
        for ($s = 0; $s -lt 10; $s++) {
            $rng    = [System.Random]::new($cls * 100 + $s)
            $sample = [double[]]::new(16)
            for ($i = 0; $i -lt 16; $i++) {
                if ($rng.NextDouble() -lt 0.10) {
                    $sample[$i] = 1.0 - $base[$i]   # flip bit (noise)
                } else {
                    $sample[$i] = $base[$i]
                }
            }
            $X.Add($sample)  | Out-Null
            $Labels.Add($cls) | Out-Null
        }
    }

    return @{
        X          = $X
        Labels     = $Labels
        ClassNames = @('HBar', 'VBar', 'Diag')
        InputDim   = 16
        NumClasses = 3
        NumSamples = 30
    }
}

# ==============================================================================
#  ACTIVATION FUNCTIONS  (standalone — callable anywhere including class methods)
# ==============================================================================

function Invoke-VBAFAEActivation {
<#
.SYNOPSIS
    Apply an activation function to a preactivation array.

.PARAMETER Z      Preactivation values  [double[]]
.PARAMETER Name   'relu' | 'sigmoid' | 'linear'

.OUTPUTS  [double[]]  — activated values  (comma-protected against unrolling)

.NOTES
    Sigmoid clamps input to [-500, 500] to prevent Exp overflow.
#>
    param(
        [double[]]$Z,
        [string]  $Name
    )
    $n   = $Z.Length
    $out = [double[]]::new($n)

    if ($Name -eq 'relu') {
        for ($i = 0; $i -lt $n; $i++) {
            $out[$i] = if ($Z[$i] -gt 0.0) { $Z[$i] } else { 0.0 }
        }
    } elseif ($Name -eq 'sigmoid') {
        for ($i = 0; $i -lt $n; $i++) {
            # Clamp to avoid [Math]::Exp overflow
            $z_safe  = [Math]::Max(-500.0, [Math]::Min(500.0, $Z[$i]))
            $out[$i] = 1.0 / (1.0 + [Math]::Exp(-$z_safe))
        }
    } else {
        # 'linear' — identity
        for ($i = 0; $i -lt $n; $i++) { $out[$i] = $Z[$i] }
    }
    return ,$out     # comma prevents pipeline unrolling
}

function Invoke-VBAFAEActivationGrad {
<#
.SYNOPSIS
    Multiply upstream gradient by the activation derivative (elementwise).
    This is the 'delta' step in backpropagation.

.PARAMETER DOut   Upstream gradient  [double[]]
.PARAMETER Z      Preactivation (needed for ReLU gate)  [double[]]
.PARAMETER A      Activation output (needed for sigmoid shortcut)  [double[]]
.PARAMETER Name   'relu' | 'sigmoid' | 'linear'

.OUTPUTS  [double[]]  dPreact = DOut ⊙ activation'  (comma-protected)
#>
    param(
        [double[]]$DOut,
        [double[]]$Z,
        [double[]]$A,
        [string]  $Name
    )
    $n = $DOut.Length
    $d = [double[]]::new($n)

    if ($Name -eq 'relu') {
        # relu' = 1 if Z > 0 else 0
        for ($i = 0; $i -lt $n; $i++) {
            $d[$i] = if ($Z[$i] -gt 0.0) { $DOut[$i] } else { 0.0 }
        }
    } elseif ($Name -eq 'sigmoid') {
        # sigmoid' = sigmoid * (1 - sigmoid)  — uses cached output A
        for ($i = 0; $i -lt $n; $i++) {
            $d[$i] = $DOut[$i] * $A[$i] * (1.0 - $A[$i])
        }
    } else {
        # linear' = 1
        for ($i = 0; $i -lt $n; $i++) { $d[$i] = $DOut[$i] }
    }
    return ,$d
}

# ==============================================================================
#  LAYER  (hashtable — guaranteed reference semantics in ArrayList)
# ==============================================================================

function New-AELayer {
<#
.SYNOPSIS
    Create a fully-connected layer as a hashtable.

.DESCRIPTION
    KEY DESIGN: all mutable state (W, B, caches) lives in a hashtable.
    Hashtables stored in ArrayList are always references in PS 5.1.
    Direct element assignment  $layer.W[$i] = value  persists. ✅

.PARAMETER InSize      Input dimension
.PARAMETER OutSize     Output dimension
.PARAMETER Activation  'relu' | 'sigmoid' | 'linear'
.PARAMETER Seed        RNG seed for reproducible init

.OUTPUTS  Hashtable with keys:
    W, B, InSize, OutSize, Activation, Frozen
    LastInput, LastPreact, LastOutput  (filled during forward pass)

.EXAMPLE
    $l = New-AELayer -InSize 16 -OutSize 8 -Activation relu -Seed 1
#>
    param(
        [int]   $InSize,
        [int]   $OutSize,
        [string]$Activation = 'relu',
        [int]   $Seed       = 42
    )

    $rng   = [System.Random]::new($Seed)
    # He initialisation scale — good default for ReLU networks
    $scale = [Math]::Sqrt(2.0 / $InSize)

    $wLen = $InSize * $OutSize
    # Use @(0.0) * N  (object[] with N zeros — mutations via index persist in hashtable)
    $W = @(0.0) * $wLen
    $B = @(0.0) * $OutSize

    for ($i = 0; $i -lt $wLen; $i++) {
        $W[$i] = ($rng.NextDouble() * 2.0 - 1.0) * $scale
    }
    # Biases initialised to zero

    return @{
        W          = $W
        B          = $B
        InSize     = $InSize
        OutSize    = $OutSize
        Activation = $Activation
        Frozen     = $false
        # Forward-pass cache (null until first forward call)
        LastInput  = $null
        LastPreact = $null
        LastOutput = $null
    }
}

# ==============================================================================
#  FORWARD PASS  (standalone function — safe to call from anywhere)
# ==============================================================================

function Invoke-AELayerForward {
<#
.SYNOPSIS
    Run one fully-connected layer's forward pass.
    Caches input / preactivation / output inside $Layer for backprop.

.PARAMETER Layer  Hashtable created by New-AELayer
.PARAMETER X      Input vector  [double[]]

.OUTPUTS  [double[]]  activated output  (comma-protected)

.NOTES
    z[j] = Σ_i W[j·InSize + i] · x[i]  +  B[j]
    a[j] = activation(z[j])
#>
    param(
        [hashtable]$Layer,
        [double[]] $X
    )

    $inSz  = [int]$Layer.InSize
    $outSz = [int]$Layer.OutSize
    $W     = $Layer.W
    $B     = $Layer.B

    # Cache a copy of the input (needed for dW computation in backward pass)
    $inputCopy = [double[]]::new($inSz)
    for ($i = 0; $i -lt $inSz; $i++) { $inputCopy[$i] = [double]$X[$i] }
    $Layer.LastInput = $inputCopy

    # Preactivation: z[j] = W[j,:] · x + B[j]
    $Z = [double[]]::new($outSz)
    for ($j = 0; $j -lt $outSz; $j++) {
        $sum  = [double]$B[$j]
        $base = $j * $inSz
        for ($i = 0; $i -lt $inSz; $i++) {
            $sum += [double]$W[$base + $i] * [double]$X[$i]
        }
        $Z[$j] = $sum
    }
    $Layer.LastPreact = $Z

    # Activation
    $A = Invoke-VBAFAEActivation -Z $Z -Name $Layer.Activation
    $Layer.LastOutput = $A

    return ,$A
}

# ==============================================================================
#  BACKWARD PASS  (standalone function)
# ==============================================================================

function Invoke-AELayerBackward {
<#
.SYNOPSIS
    Backward pass for one layer: compute gradients, update W and B in-place,
    return gradient w.r.t. layer input (to propagate further back).

.DESCRIPTION
    WEIGHT UPDATE PERSISTENCE:
        $Layer.W[$idx] = newValue   ← direct element assignment on hashtable array
        This PERSISTS in PS 5.1 because the array lives inside a hashtable. ✅

    If $Layer.Frozen is $true, gradients are still computed and returned
    (for layers below) but W and B are NOT updated.

.PARAMETER Layer  Hashtable (must have valid LastInput/LastPreact/LastOutput)
.PARAMETER DOut   Upstream gradient dLoss/dOutput  [double[]]
.PARAMETER LR     Learning rate

.OUTPUTS  [double[]]  gradient w.r.t. layer input (dLoss/dX)  (comma-protected)
#>
    param(
        [hashtable]$Layer,
        [double[]] $DOut,
        [double]   $LR
    )

    $inSz  = [int]$Layer.InSize
    $outSz = [int]$Layer.OutSize
    $X     = [double[]]$Layer.LastInput
    $Z     = [double[]]$Layer.LastPreact
    $A     = [double[]]$Layer.LastOutput

    # ── Step 1: activation derivative  dZ = DOut ⊙ activation'(Z) ──────────
    $DZ = Invoke-VBAFAEActivationGrad -DOut $DOut -Z $Z -A $A -Name $Layer.Activation

    # ── Step 2: gradient w.r.t. input  dX[i] = Σ_j DZ[j] * W[j,i] ─────────
    $DX = [double[]]::new($inSz)
    for ($i = 0; $i -lt $inSz; $i++) {
        $sum = 0.0
        for ($j = 0; $j -lt $outSz; $j++) {
            $sum += [double]$DZ[$j] * [double]$Layer.W[$j * $inSz + $i]
        }
        $DX[$i] = $sum
    }

    # ── Step 3: update W and B (skipped if layer is frozen) ─────────────────
    if (-not $Layer.Frozen) {
        for ($j = 0; $j -lt $outSz; $j++) {
            $dz_j = [double]$DZ[$j]
            $base = $j * $inSz
            for ($i = 0; $i -lt $inSz; $i++) {
                # Direct element assignment on hashtable array — persists! ✅
                $Layer.W[$base + $i] = [double]$Layer.W[$base + $i] - $LR * $dz_j * [double]$X[$i]
            }
            $Layer.B[$j] = [double]$Layer.B[$j] - $LR * $dz_j
        }
    }

    return ,$DX
}

# ==============================================================================
#  LOSS  (standalone helpers)
# ==============================================================================

function Get-VBAFAEMSELoss {
<#
.SYNOPSIS  Scalar MSE loss between reconstruction and target.
           L = (1/n) Σ (recon_i - target_i)²
#>
    param([double[]]$Recon, [double[]]$Target)
    $sum = 0.0
    $n   = $Recon.Length
    for ($i = 0; $i -lt $n; $i++) {
        $d    = [double]$Recon[$i] - [double]$Target[$i]
        $sum += $d * $d
    }
    return ($sum / $n)
}

function Get-VBAFAEMSEGrad {
<#
.SYNOPSIS  Gradient of MSE loss w.r.t. reconstruction.
           dL/d(recon_i) = 2·(recon_i - target_i) / n
.OUTPUTS   [double[]]  (comma-protected)
#>
    param([double[]]$Recon, [double[]]$Target)
    $n  = $Recon.Length
    $dL = [double[]]::new($n)
    for ($i = 0; $i -lt $n; $i++) {
        $dL[$i] = 2.0 * ([double]$Recon[$i] - [double]$Target[$i]) / $n
    }
    return ,$dL
}

# ==============================================================================
#  CLASS  BasicAutoencoder
#  Thin wrapper — no weights stored here. All mutable state lives in hashtables.
# ==============================================================================

class BasicAutoencoder {
<#
    Architecture:
        Encoder: InputSize → encoderDims[0] → ... → encoderDims[-1] → LatentSize (linear)
        Decoder: LatentSize → encoderDims[-1] → ... → encoderDims[0] → InputSize (sigmoid)

    The symmetric decoder mirrors the encoder dims in reverse.
    Output activation is sigmoid: produces values in (0,1), suitable for binary targets.

    PS 5.1 RULES APPLIED HERE:
        - All functions called with  & (Get-Command Func) -Param val
        - No foreach / ForEach-Object / switch on arrays
        - No typed [Type[]] properties — only ArrayList and primitives
        - Layers are hashtable references in ArrayLists → weight updates persist
#>

    [System.Collections.ArrayList] $EncoderLayers   # ArrayList of hashtables
    [System.Collections.ArrayList] $DecoderLayers   # ArrayList of hashtables
    [int]    $InputSize
    [int]    $LatentSize
    [double] $LearningRate

    BasicAutoencoder([int]$inputSize, [int[]]$encoderDims, [int]$latentSize) {
        $this.InputSize     = $inputSize
        $this.LatentSize    = $latentSize
        $this.LearningRate  = 0.01
        $this.EncoderLayers = [System.Collections.ArrayList]::new()
        $this.DecoderLayers = [System.Collections.ArrayList]::new()

        # ── Build Encoder ────────────────────────────────────────────────────
        # inputSize → encoderDims[0] → ... → latentSize (linear activation)
        $prev = $inputSize
        $seed = 1
        for ($di = 0; $di -lt $encoderDims.Length; $di++) {
            $dim = [int]$encoderDims[$di]
            $layer = & (Get-Command New-AELayer) -InSize $prev -OutSize $dim -Activation 'relu' -Seed $seed
            $this.EncoderLayers.Add($layer) | Out-Null
            $prev = $dim
            $seed++
        }
        # Latent layer — linear so the latent space is unconstrained
        $latLayer = & (Get-Command New-AELayer) -InSize $prev -OutSize $latentSize -Activation 'linear' -Seed $seed
        $this.EncoderLayers.Add($latLayer) | Out-Null
        $seed++

        # ── Build Decoder ────────────────────────────────────────────────────
        # latentSize → encoderDims[-1] → ... → encoderDims[0] → inputSize (sigmoid)
        $prev = $latentSize
        for ($di = $encoderDims.Length - 1; $di -ge 0; $di--) {
            $dim = [int]$encoderDims[$di]
            $layer = & (Get-Command New-AELayer) -InSize $prev -OutSize $dim -Activation 'relu' -Seed $seed
            $this.DecoderLayers.Add($layer) | Out-Null
            $prev = $dim
            $seed++
        }
        # Output layer — sigmoid maps to (0,1) for binary reconstruction
        $outLayer = & (Get-Command New-AELayer) -InSize $prev -OutSize $inputSize -Activation 'sigmoid' -Seed $seed
        $this.DecoderLayers.Add($outLayer) | Out-Null
    }

    # ── Encode: input → latent vector ────────────────────────────────────────
    [object] Encode([double[]]$x) {
        $current = $x
        for ($li = 0; $li -lt $this.EncoderLayers.Count; $li++) {
            $lyr     = [hashtable]$this.EncoderLayers[$li]
            $current = [double[]]( & (Get-Command Invoke-AELayerForward) -Layer $lyr -X ([double[]]$current) )
        }
        return $current   # returns as [object]; caller casts to [double[]]
    }

    # ── Decode: latent vector → reconstruction ───────────────────────────────
    [object] Decode([double[]]$z) {
        $current = $z
        for ($li = 0; $li -lt $this.DecoderLayers.Count; $li++) {
            $lyr     = [hashtable]$this.DecoderLayers[$li]
            $current = [double[]]( & (Get-Command Invoke-AELayerForward) -Layer $lyr -X ([double[]]$current) )
        }
        return $current
    }

    # ── Forward: input → reconstruction (encode then decode) ─────────────────
    [object] Forward([double[]]$x) {
        $z     = [double[]]$this.Encode($x)
        $recon = [double[]]$this.Decode($z)
        return $recon
    }

    # ── Backward: backprop through decoder then encoder ───────────────────────
    # $dLoss  — gradient of loss w.r.t. reconstruction output  [double[]]
    [void] Backward([double[]]$dLoss) {
        # Backprop through decoder (reverse layer order)
        $grad = [double[]]$dLoss
        for ($li = $this.DecoderLayers.Count - 1; $li -ge 0; $li--) {
            $lyr  = [hashtable]$this.DecoderLayers[$li]
            $grad = [double[]]( & (Get-Command Invoke-AELayerBackward) -Layer $lyr -DOut $grad -LR $this.LearningRate )
        }
        # Backprop through encoder (reverse layer order)
        for ($li = $this.EncoderLayers.Count - 1; $li -ge 0; $li--) {
            $lyr  = [hashtable]$this.EncoderLayers[$li]
            $grad = [double[]]( & (Get-Command Invoke-AELayerBackward) -Layer $lyr -DOut $grad -LR $this.LearningRate )
        }
        # $grad is now dLoss/dInput — discarded (autoencoder has no upstream)
    }

    # ── Info ──────────────────────────────────────────────────────────────────
    [string] ToString() {
        $enc = ''
        for ($li = 0; $li -lt $this.EncoderLayers.Count; $li++) {
            $lyr = [hashtable]$this.EncoderLayers[$li]
            if ($li -gt 0) { $enc += '→' }
            $enc += ('{0}({1})' -f $lyr.Activation, $lyr.OutSize)
        }
        $dec = ''
        for ($li = 0; $li -lt $this.DecoderLayers.Count; $li++) {
            $lyr = [hashtable]$this.DecoderLayers[$li]
            if ($li -gt 0) { $dec += '→' }
            $dec += ('{0}({1})' -f $lyr.Activation, $lyr.OutSize)
        }
        return ('BasicAutoencoder  in={0}  enc=[{1}]  lat={2}  dec=[{3}]  LR={4}' -f `
            $this.InputSize, $enc, $this.LatentSize, $dec, $this.LearningRate)
    }
}

# ==============================================================================
#  TRAINING
# ==============================================================================

function Invoke-VBAFAETrain {
<#
.SYNOPSIS
    Train a BasicAutoencoder with online SGD (one sample per weight update).

.PARAMETER Model    A BasicAutoencoder instance
.PARAMETER Data     ArrayList (or array) of [double[]] samples
.PARAMETER Epochs   Full passes through the training data  (default 100)
.PARAMETER LR       Learning rate — overrides $Model.LearningRate if > 0  (default: use model's)
.PARAMETER PrintEvery  Print loss every N epochs. 0 = silent.  (default 10)
    NOTE: Parameter is named PrintEvery (not Verbose) to avoid conflict with
    PS 5.1's built-in -Verbose common parameter.

.OUTPUTS
    Hashtable:
        FinalLoss   — [double]   loss at last epoch
        LossHistory — ArrayList of [double] per-epoch average loss
        Model       — the trained BasicAutoencoder (same reference)

.EXAMPLE
    $ds  = Get-VBAFAEDataset -Name Shapes2D
    $ae  = [BasicAutoencoder]::new(16, @(8,4), 2)
    $r   = Invoke-VBAFAETrain -Model $ae -Data $ds.X -Epochs 200 -LR 0.05 -PrintEvery 20
    $r.FinalLoss
    # → should be well below 0.15 after 200 epochs
#>
    param(
        [Parameter(Mandatory)][BasicAutoencoder]$Model,
        [Parameter(Mandatory)]$Data,
        [int]   $Epochs     = 100,
        [double]$LR         = -1.0,
        [int]   $PrintEvery = 10
    )

    if ($LR -gt 0.0) { $Model.LearningRate = $LR }

    $nSamples    = $Data.Count
    $lossHistory = [System.Collections.ArrayList]::new()

    Write-Host ("  Training {0}  ({1} samples, {2} epochs, LR={3})" -f `
        $Model.ToString(), $nSamples, $Epochs, $Model.LearningRate) -ForegroundColor Gray
    Write-Host ''

    for ($ep = 1; $ep -le $Epochs; $ep++) {
        $epochLoss = 0.0

        for ($si = 0; $si -lt $nSamples; $si++) {
            $x = [double[]]$Data[$si]

            # Forward pass — fills layer caches
            $recon = [double[]]$Model.Forward($x)

            # Per-sample loss
            $epochLoss += Get-VBAFAEMSELoss -Recon $recon -Target $x

            # Gradient of MSE loss w.r.t. reconstruction
            $dLoss = [double[]](Get-VBAFAEMSEGrad -Recon $recon -Target $x)

            # Backward pass — updates all unfrozen W and B in-place
            $Model.Backward($dLoss)
        }

        $avgLoss = $epochLoss / $nSamples
        $lossHistory.Add($avgLoss) | Out-Null

        if ($PrintEvery -gt 0 -and ($ep -eq 1 -or $ep % $PrintEvery -eq 0)) {
            $bar   = ''
            $ticks = [int]($avgLoss * 100)
            $ticks = [Math]::Min($ticks, 40)
            for ($t = 0; $t -lt $ticks; $t++) { $bar += '█' }
            $color = if ($avgLoss -lt 0.10) { 'Green' } `
                elseif ($avgLoss -lt 0.20)  { 'Yellow' } else { 'Red' }
            Write-Host ("  Epoch {0,4}/{1}  Loss: {2:F6}  {3}" -f `
                $ep, $Epochs, $avgLoss, $bar) -ForegroundColor $color
        }
    }

    $finalLoss = [double]$lossHistory[$lossHistory.Count - 1]

    Write-Host ''
    $resultColor = if ($finalLoss -lt 0.10) { 'Green' } `
        elseif ($finalLoss -lt 0.20) { 'Yellow' } else { 'Red' }
    Write-Host ("  ── Training complete ──  Final loss: {0:F6}" -f $finalLoss) -ForegroundColor $resultColor
    Write-Host ''

    return @{
        FinalLoss   = $finalLoss
        LossHistory = $lossHistory
        Model       = $Model
    }
}

# ==============================================================================
#  ANALYSIS & VISUALISATION
# ==============================================================================

function Get-VBAFLatent {
<#
.SYNOPSIS
    Encode every sample and collect latent vectors for analysis / plotting.

.PARAMETER Model   Trained BasicAutoencoder
.PARAMETER Data    ArrayList of [double[]]
.PARAMETER Labels  Optional ArrayList of [int] class labels

.OUTPUTS
    ArrayList of hashtables: @{ Z = [double[]]; Label = int; SampleIdx = int }
    (comma-protected against pipeline unrolling)

.EXAMPLE
    $enc = Get-VBAFLatent -Model $ae -Data $ds.X -Labels $ds.Labels
    $enc[0].Z      # latent vector of first sample
    $enc[0].Label  # class index
#>
    param(
        [Parameter(Mandatory)][BasicAutoencoder]$Model,
        [Parameter(Mandatory)]$Data,
        $Labels = $null
    )
    $results = [System.Collections.ArrayList]::new()
    for ($si = 0; $si -lt $Data.Count; $si++) {
        $x = [double[]]$Data[$si]
        $z = [double[]]$Model.Encode($x)
        $results.Add(@{
            Z         = $z
            Label     = if ($null -ne $Labels) { [int]$Labels[$si] } else { -1 }
            SampleIdx = $si
        }) | Out-Null
    }
    return ,$results
}

function Show-VBAFLatentSpace {
<#
.SYNOPSIS
    ASCII scatter plot of a 2D latent space.
    Only works when LatentSize = 2.

.PARAMETER Latents     Output of Get-VBAFLatent
.PARAMETER ClassNames  String array of class names  (used in legend)
.PARAMETER Width       Plot width in chars   (default 48)
.PARAMETER Height      Plot height in chars  (default 20)

.EXAMPLE
    $enc = Get-VBAFLatent -Model $ae -Data $ds.X -Labels $ds.Labels
    Show-VBAFLatentSpace -Latents $enc -ClassNames $ds.ClassNames
#>
    param(
        [Parameter(Mandatory)]$Latents,
        $ClassNames = @('0','1','2','3','4'),
        [int]$Width  = 48,
        [int]$Height = 20
    )

    # Gather all Z[0] and Z[1] to compute axis ranges
    $minX = [double]::MaxValue;  $maxX = [double]::MinValue
    $minY = [double]::MaxValue;  $maxY = [double]::MinValue
    for ($i = 0; $i -lt $Latents.Count; $i++) {
        $z = [double[]]$Latents[$i].Z
        if ($z[0] -lt $minX) { $minX = $z[0] }
        if ($z[0] -gt $maxX) { $maxX = $z[0] }
        if ($z.Length -gt 1) {
            if ($z[1] -lt $minY) { $minY = $z[1] }
            if ($z[1] -gt $maxY) { $maxY = $z[1] }
        }
    }
    $rangeX = $maxX - $minX; if ($rangeX -eq 0.0) { $rangeX = 1.0 }
    $rangeY = $maxY - $minY; if ($rangeY -eq 0.0) { $rangeY = 1.0 }

    # Build grid as ArrayList of char[] rows
    $grid = [System.Collections.ArrayList]::new()
    for ($r = 0; $r -lt $Height; $r++) {
        $row = [char[]]::new($Width)
        for ($c = 0; $c -lt $Width; $c++) { $row[$c] = [char]'·' }
        $grid.Add($row) | Out-Null
    }

    $symbols = [char[]]('O','X','#','+','*')

    # Plot each point — $grid stores char[] references; direct element mutation persists ✅
    for ($i = 0; $i -lt $Latents.Count; $i++) {
        $z      = [double[]]$Latents[$i].Z
        $lbl    = [int]$Latents[$i].Label
        $plotC  = [int](($z[0] - $minX) / $rangeX * ($Width  - 1))
        $plotR  = [int]((1.0 - ($z[1] - $minY) / $rangeY) * ($Height - 1))
        $plotC  = [Math]::Max(0, [Math]::Min($Width  - 1, $plotC))
        $plotR  = [Math]::Max(0, [Math]::Min($Height - 1, $plotR))
        $sym    = if ($lbl -ge 0 -and $lbl -lt $symbols.Length) { $symbols[$lbl] } else { [char]'?' }
        $rowArr = [char[]]$grid[$plotR]    # unbox to char[] — same object reference
        $rowArr[$plotC] = $sym             # mutate in-place; persists in $grid
    }

    # Render
    Write-Host ''
    Write-Host '  ── Latent Space (2D) ────────────────────────────' -ForegroundColor Cyan
    Write-Host ("  X: [{0:F3} … {1:F3}]   Y: [{2:F3} … {3:F3}]" -f $minX,$maxX,$minY,$maxY) -ForegroundColor DarkGray
    Write-Host ("  +" + ('-' * $Width) + '+') -ForegroundColor DarkGray
    for ($r = 0; $r -lt $Height; $r++) {
        Write-Host ("  |" + [string]::new([char[]]$grid[$r]) + '|') -ForegroundColor White
    }
    Write-Host ("  +" + ('-' * $Width) + '+') -ForegroundColor DarkGray

    # Legend
    $legendColors = @('Green','Yellow','Cyan','Magenta','Red')
    for ($c = 0; $c -lt $ClassNames.Length -and $c -lt $symbols.Length; $c++) {
        Write-Host ("  {0} = {1}" -f $symbols[$c], $ClassNames[$c]) -ForegroundColor $legendColors[$c]
    }
    Write-Host ''
}

function Show-VBAFReconstruction {
<#
.SYNOPSIS
    Side-by-side ASCII comparison of original vs reconstructed 4×4 pattern.

.PARAMETER Model      Trained BasicAutoencoder
.PARAMETER X          One sample as [double[]]
.PARAMETER Label      Display label (e.g. class name)
.PARAMETER Threshold  Binarisation threshold for display  (default 0.5)

.EXAMPLE
    Show-VBAFReconstruction -Model $ae -X $ds.X[0]  -Label 'HBar'
    Show-VBAFReconstruction -Model $ae -X $ds.X[10] -Label 'VBar'
#>
    param(
        [Parameter(Mandatory)][BasicAutoencoder]$Model,
        [Parameter(Mandatory)][double[]]$X,
        [string]$Label     = '',
        [double]$Threshold = 0.5
    )
    $recon = [double[]]$Model.Forward($X)
    $side  = [int][Math]::Sqrt($X.Length)   # assume square grid

    Write-Host ("  ── {0} ──" -f $Label) -ForegroundColor Cyan
    Write-Host '  Original        Reconstructed   Error' -ForegroundColor DarkGray

    $errors = 0
    for ($r = 0; $r -lt $side; $r++) {
        $origRow  = ''
        $reconRow = ''
        $errRow   = ''
        for ($c = 0; $c -lt $side; $c++) {
            $idx      = $r * $side + $c
            $origBit  = [double]$X[$idx]     -ge $Threshold
            $reconBit = [double]$recon[$idx]  -ge $Threshold
            $origRow  += if ($origBit)  { '█ ' } else { '· ' }
            $reconRow += if ($reconBit) { '█ ' } else { '· ' }
            if ($origBit -ne $reconBit) { $errRow += '✗ '; $errors++ }
            else                        { $errRow += '  ' }
        }
        Write-Host ("  {0}   {1}   {2}" -f $origRow.TrimEnd(), $reconRow.TrimEnd(), $errRow.TrimEnd())
    }
    $mse = Get-VBAFAEMSELoss -Recon $recon -Target $X
    Write-Host ("  MSE={0:F4}   Pixel errors={1}/{2}" -f $mse, $errors, $X.Length) -ForegroundColor DarkGray
    Write-Host ''
}

function Get-VBAFAELossCurve {
<#
.SYNOPSIS
    Print a compact ASCII loss curve from a LossHistory ArrayList.

.EXAMPLE
    Get-VBAFAELossCurve -LossHistory $r.LossHistory -Title 'Shapes2D'
#>
    param(
        [Parameter(Mandatory)]$LossHistory,
        [string]$Title  = 'Training Loss',
        [int]   $Width  = 60,
        [int]   $Height = 10
    )

    $n    = $LossHistory.Count
    $vals = [double[]]::new($n)
    for ($i = 0; $i -lt $n; $i++) { $vals[$i] = [double]$LossHistory[$i] }

    $minV = $vals[0]; $maxV = $vals[0]
    for ($i = 1; $i -lt $n; $i++) {
        if ($vals[$i] -lt $minV) { $minV = $vals[$i] }
        if ($vals[$i] -gt $maxV) { $maxV = $vals[$i] }
    }
    $rangeV = $maxV - $minV; if ($rangeV -eq 0.0) { $rangeV = 1.0 }

    # Sample $Width points across the history
    $cols = [double[]]::new($Width)
    for ($c = 0; $c -lt $Width; $c++) {
        $idx    = [int]([Math]::Floor($c / ($Width - 1.0) * ($n - 1)))
        $cols[$c] = $vals[$idx]
    }

    Write-Host ''
    Write-Host ("  ── {0} ──" -f $Title) -ForegroundColor Cyan
    Write-Host ("  max={0:F5}" -f $maxV) -ForegroundColor DarkGray
    for ($row = $Height - 1; $row -ge 0; $row--) {
        $line = '  |'
        $threshold = $minV + ($row / ($Height - 1.0)) * $rangeV
        for ($c = 0; $c -lt $Width; $c++) {
            $line += if ($cols[$c] -ge $threshold) { '▄' } else { ' ' }
        }
        Write-Host $line
    }
    Write-Host ('  +' + ('-' * $Width)) -ForegroundColor DarkGray
    Write-Host ("  min={0:F5}   epochs=1..{1}" -f $minV, $n) -ForegroundColor DarkGray
    Write-Host ''
}

# ==============================================================================
#  QUICK-START / SMOKE TEST
# ==============================================================================

function Test-VBAFAutoencoder {
<#
.SYNOPSIS
    End-to-end smoke test: build, train, and visualise a BasicAutoencoder
    on the Shapes2D dataset. Verifies loss < 0.15.

.PARAMETER Epochs  Training epochs  (default 200)
.PARAMETER LR      Learning rate    (default 0.05)

.OUTPUTS   Training result hashtable (same as Invoke-VBAFAETrain)

.EXAMPLE
    Test-VBAFAutoencoder
    Test-VBAFAutoencoder -Epochs 300 -LR 0.08
#>
    param(
        [int]   $Epochs = 200,
        [double]$LR     = 0.05
    )

    Write-Host ''
    Write-Host '  ══════════════════════════════════════════════════' -ForegroundColor Cyan
    Write-Host '  VBAF BasicAutoencoder — Smoke Test' -ForegroundColor Cyan
    Write-Host '  ══════════════════════════════════════════════════' -ForegroundColor Cyan

    # 1. Dataset
    Write-Host '  [1/5] Loading Shapes2D dataset...' -ForegroundColor Gray
    $ds = Get-VBAFAEDataset -Name Shapes2D
    Write-Host ("        {0} samples × {1} dims  ({2} classes: {3})" -f `
        $ds.NumSamples, $ds.InputDim, $ds.NumClasses, ($ds.ClassNames -join ', ')) -ForegroundColor DarkGray

    # 2. Build model
    Write-Host '  [2/5] Building BasicAutoencoder 16→8→4→[2]→4→8→16...' -ForegroundColor Gray
    $ae = [BasicAutoencoder]::new(16, @(8,4), 2)
    Write-Host ("        {0}" -f $ae.ToString()) -ForegroundColor DarkGray

    # 3. Train
    Write-Host ("  [3/5] Training ({0} epochs, LR={1})..." -f $Epochs, $LR) -ForegroundColor Gray
    $result = Invoke-VBAFAETrain -Model $ae -Data $ds.X -Epochs $Epochs -LR $LR -PrintEvery 20

    # 4. Visualise latent space
    Write-Host '  [4/5] Latent space...' -ForegroundColor Gray
    $enc = Get-VBAFLatent -Model $ae -Data $ds.X -Labels $ds.Labels
    Show-VBAFLatentSpace -Latents $enc -ClassNames $ds.ClassNames

    # 5. Sample reconstructions (first sample from each class)
    Write-Host '  [5/5] Reconstructions (first sample per class)...' -ForegroundColor Gray
    Write-Host ''
    for ($cls = 0; $cls -lt $ds.NumClasses; $cls++) {
        $x = [double[]]$ds.X[$cls * 10]
        Show-VBAFReconstruction -Model $ae -X $x -Label ('{0} · sample {1}' -f $ds.ClassNames[$cls], ($cls * 10))
    }

    # Loss curve
    Get-VBAFAELossCurve -LossHistory $result.LossHistory -Title 'Shapes2D Training Loss'

    # Pass / Fail
    $fl = $result.FinalLoss
    Write-Host '  ── Result ─────────────────────────────────────────' -ForegroundColor DarkGray
    if ($fl -lt 0.10) {
        Write-Host ("  ✅  PASS (Excellent)  Final loss: {0:F6}  (target < 0.15)" -f $fl) -ForegroundColor Green
    } elseif ($fl -lt 0.15) {
        Write-Host ("  ✅  PASS               Final loss: {0:F6}  (target < 0.15)" -f $fl) -ForegroundColor Green
    } elseif ($fl -lt 0.20) {
        Write-Host ("  ⚠️  MARGINAL           Final loss: {0:F6}  (target < 0.15 — try more epochs)" -f $fl) -ForegroundColor Yellow
    } else {
        Write-Host ("  ❌  FAIL               Final loss: {0:F6}  (try -Epochs 400 -LR 0.08)" -f $fl) -ForegroundColor Red
    }
    Write-Host ''

    return $result
}

# ==============================================================================
# TEST
# 1. Run VBAF.LoadAll.ps1
#
# --- Quick smoke test (recommended defaults) ---
# 2. Test-VBAFAutoencoder -Epochs 300 -LR 0.15
#    # Expected: Final loss ~0.066  ✅  PASS (Excellent)
#
# --- Manual step-by-step ---
# 3. # Load dataset
#    $ds = Get-VBAFAEDataset -Name "Shapes2D"
#    # 30 samples × 16 dims  (3 classes: HBar, VBar, Diag)
#
# 4. # Build model  (16 → 8 → 4 → [2] → 4 → 8 → 16)
#    $ae = [BasicAutoencoder]::new(16, @(8,4), 2)
#    $ae.ToString()
#
# 5. # Train
#    $r = Invoke-VBAFAETrain -Model $ae -Data $ds.X -Epochs 300 -LR 0.15 -PrintEvery 20
#    $r.FinalLoss    # should be < 0.15
#
# 6. # Visualise latent space (classes should form 3 distinct clusters)
#    $enc = Get-VBAFLatent -Model $ae -Data $ds.X -Labels $ds.Labels
#    Show-VBAFLatentSpace -Latents $enc -ClassNames $ds.ClassNames
#
# 7. # Inspect reconstructions
#    Show-VBAFReconstruction -Model $ae -X $ds.X[0]  -Label 'HBar · sample 0'
#    Show-VBAFReconstruction -Model $ae -X $ds.X[10] -Label 'VBar · sample 10'
#    Show-VBAFReconstruction -Model $ae -X $ds.X[20] -Label 'Diag · sample 20'
#
# 8. # Loss curve
#    Get-VBAFAELossCurve -LossHistory $r.LossHistory -Title 'Shapes2D'
#
# --- PS 5.1 gotchas documented in this module ---
# -Verbose is a reserved PS 5.1 common parameter — use -PrintEvery instead
# Weight updates require direct element assignment: $layer.W[$i] = value
# Functions inside class methods: & (Get-Command Func) -Param val
# ==============================================================================

# ==============================================================================
#  MODULE FOOTER
# ==============================================================================

Write-Host '  Functions loaded:' -ForegroundColor DarkGray
Write-Host '    Get-VBAFAEDataset          Get-VBAFLatent' -ForegroundColor DarkGray
Write-Host '    Invoke-VBAFAETrain         Show-VBAFLatentSpace' -ForegroundColor DarkGray
Write-Host '    Show-VBAFReconstruction    Get-VBAFAELossCurve' -ForegroundColor DarkGray
Write-Host '    Test-VBAFAutoencoder' -ForegroundColor DarkGray
Write-Host '  Classes: [BasicAutoencoder]' -ForegroundColor DarkGray
Write-Host ''
Write-Host '  Quick start:  Test-VBAFAutoencoder' -ForegroundColor Cyan
Write-Host ''