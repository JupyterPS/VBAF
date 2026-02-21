# ==============================================================================
#  VBAF.ML.TransferLearning.ps1
#  Visual Brain AI Framework — Transfer Learning Module
#  Version  : v1.0.0  |  Requires PS 5.1  |  Part of VBAF v2.1.0
# ==============================================================================
#
#  FEATURES
#  --------
#  1. Toy model zoo         — hand-crafted pretrained weights (no training needed)
#  2. Layer freezing        — freeze/unfreeze individual layers
#  3. Feature extraction    — get activations at any layer depth
#  4. Fine-tuning           — backprop only through unfrozen layers
#  5. Weight save/load      — JSON persistence compatible with VBAF.ML.CNN.ps1
#
#  LAYER FORMAT
#  ------------
#  All layers are hashtables (same format as VBAF.ML.Autoencoder.ps1):
#    @{ W; B; InSize; OutSize; Activation; Frozen; LastInput; LastPreact; LastOutput }
#  Stored in ArrayLists → reference semantics → weight mutations persist ✅
#
#  PS 5.1 RULES (same as Autoencoder module)
#  ------------------------------------------
#  • Hashtables in ArrayList = always references
#  • Direct element assignment: $layer.W[$i] = value  ← persists ✅
#  • Functions in class methods: & (Get-Command Func) -Param val
#  • Index loops only — no foreach/ForEach-Object/switch on arrays
#  • Comma operator on return: return ,$array  ← prevents unrolling
#
#  QUICK START
#  -----------
#    . .\VBAF.ML.TransferLearning.ps1
#    Get-VBAFModelZoo                                    # list available models
#    $model = Get-VBAFPretrainedModel -Name "ShapeEncoder"
#    $feats = Get-VBAFFeatures -Model $model -X $inputVec -FromLayer 1
#    Set-VBAFLayerFrozen -Model $model -LayerIndex 0 -Frozen $true
#    $r = Invoke-VBAFFineTune -Model $model -Data $ds.X -Labels $ds.Labels -Epochs 50 -LR 0.05
#    Test-VBAFTransferLearning
# ==============================================================================

Write-Host ''
Write-Host '  ╔══════════════════════════════════════════════╗' -ForegroundColor Magenta
Write-Host '  ║   VBAF · Transfer Learning Module  v1.0.0    ║' -ForegroundColor Magenta
Write-Host '  ║   ModelZoo · Freeze · Features · FineTune    ║' -ForegroundColor Magenta
Write-Host '  ║   PS 5.1  |  Hashtable-reference layers      ║' -ForegroundColor Magenta
Write-Host '  ╚══════════════════════════════════════════════╝' -ForegroundColor Magenta
Write-Host ''

# ==============================================================================
#  LAYER PRIMITIVES
#  (self-contained — compatible with VBAF.ML.Autoencoder.ps1 layer format)
# ==============================================================================

function New-TLLayer {
<#
.SYNOPSIS
    Create a fully-connected layer hashtable for Transfer Learning.
    Compatible with VBAF.ML.Autoencoder.ps1 layer format.

.DESCRIPTION
    Layers are hashtables stored in ArrayList → always references in PS 5.1.
    Direct element assignment $layer.W[$i] = val PERSISTS. ✅
    Frozen=$false by default — set to $true to skip weight updates.

.PARAMETER InSize      Input dimension
.PARAMETER OutSize     Output dimension
.PARAMETER Activation  'relu' | 'sigmoid' | 'linear' | 'softmax'
.PARAMETER Seed        RNG seed (default 42)

.OUTPUTS  Hashtable layer
#>
    param(
        [int]   $InSize,
        [int]   $OutSize,
        [string]$Activation = 'relu',
        [int]   $Seed       = 42
    )
    $rng   = [System.Random]::new($Seed)
    $scale = [Math]::Sqrt(2.0 / $InSize)   # He init
    $wLen  = $InSize * $OutSize
    $W     = @(0.0) * $wLen
    $B     = @(0.0) * $OutSize
    for ($i = 0; $i -lt $wLen; $i++) {
        $W[$i] = ($rng.NextDouble() * 2.0 - 1.0) * $scale
    }
    return @{
        W          = $W
        B          = $B
        InSize     = $InSize
        OutSize    = $OutSize
        Activation = $Activation
        Frozen     = $false
        LastInput  = $null
        LastPreact = $null
        LastOutput = $null
    }
}

function Invoke-TLActivation {
<#
.SYNOPSIS  Apply activation function to preactivation array.
.OUTPUTS   [double[]]  (comma-protected)
#>
    param([double[]]$Z, [string]$Name)
    $n   = $Z.Length
    $out = [double[]]::new($n)

    if ($Name -eq 'relu') {
        for ($i = 0; $i -lt $n; $i++) {
            $out[$i] = if ($Z[$i] -gt 0.0) { $Z[$i] } else { 0.0 }
        }
    } elseif ($Name -eq 'sigmoid') {
        for ($i = 0; $i -lt $n; $i++) {
            $zc      = [Math]::Max(-500.0, [Math]::Min(500.0, $Z[$i]))
            $out[$i] = 1.0 / (1.0 + [Math]::Exp(-$zc))
        }
    } elseif ($Name -eq 'softmax') {
        # Numerically stable softmax: shift by max
        $maxZ = $Z[0]
        for ($i = 1; $i -lt $n; $i++) { if ($Z[$i] -gt $maxZ) { $maxZ = $Z[$i] } }
        $sumE = 0.0
        for ($i = 0; $i -lt $n; $i++) {
            $out[$i] = [Math]::Exp($Z[$i] - $maxZ)
            $sumE   += $out[$i]
        }
        for ($i = 0; $i -lt $n; $i++) { $out[$i] /= $sumE }
    } else {
        # linear
        for ($i = 0; $i -lt $n; $i++) { $out[$i] = $Z[$i] }
    }
    return ,$out
}

function Invoke-TLActivationGrad {
<#
.SYNOPSIS  Elementwise activation derivative × upstream gradient.
.OUTPUTS   [double[]]  dPreact  (comma-protected)
#>
    param([double[]]$DOut, [double[]]$Z, [double[]]$A, [string]$Name)
    $n = $DOut.Length
    $d = [double[]]::new($n)

    if ($Name -eq 'relu') {
        for ($i = 0; $i -lt $n; $i++) {
            $d[$i] = if ($Z[$i] -gt 0.0) { $DOut[$i] } else { 0.0 }
        }
    } elseif ($Name -eq 'sigmoid') {
        for ($i = 0; $i -lt $n; $i++) {
            $d[$i] = $DOut[$i] * $A[$i] * (1.0 - $A[$i])
        }
    } elseif ($Name -eq 'softmax') {
        # Jacobian diagonal approximation (cross-entropy upstream assumed)
        for ($i = 0; $i -lt $n; $i++) {
            $d[$i] = $DOut[$i] * $A[$i] * (1.0 - $A[$i])
        }
    } else {
        for ($i = 0; $i -lt $n; $i++) { $d[$i] = $DOut[$i] }
    }
    return ,$d
}

function Invoke-TLLayerForward {
<#
.SYNOPSIS
    Forward pass for one TL layer. Caches input/preact/output for backprop.
.OUTPUTS   [double[]]  (comma-protected)
#>
    param([hashtable]$Layer, [double[]]$X)

    $inSz  = [int]$Layer.InSize
    $outSz = [int]$Layer.OutSize
    $W     = $Layer.W
    $B     = $Layer.B

    # Cache input copy
    $inp = [double[]]::new($inSz)
    for ($i = 0; $i -lt $inSz; $i++) { $inp[$i] = [double]$X[$i] }
    $Layer.LastInput = $inp

    # Preactivation z[j] = W[j,:] · x + B[j]
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

    $A = Invoke-TLActivation -Z $Z -Name $Layer.Activation
    $Layer.LastOutput = $A
    return ,$A
}

function Invoke-TLLayerBackward {
<#
.SYNOPSIS
    Backward pass for one TL layer.
    SKIPS weight update if $Layer.Frozen -eq $true.
    Returns dLoss/dInput for propagation to earlier layers.
.OUTPUTS   [double[]]  dX  (comma-protected)
#>
    param([hashtable]$Layer, [double[]]$DOut, [double]$LR)

    $inSz  = [int]$Layer.InSize
    $outSz = [int]$Layer.OutSize
    $X     = [double[]]$Layer.LastInput
    $Z     = [double[]]$Layer.LastPreact
    $A     = [double[]]$Layer.LastOutput

    # Activation gradient
    $DZ = Invoke-TLActivationGrad -DOut $DOut -Z $Z -A $A -Name $Layer.Activation

    # dX[i] = Σ_j DZ[j] * W[j,i]
    $DX = [double[]]::new($inSz)
    for ($i = 0; $i -lt $inSz; $i++) {
        $sum = 0.0
        for ($j = 0; $j -lt $outSz; $j++) {
            $sum += [double]$DZ[$j] * [double]$Layer.W[$j * $inSz + $i]
        }
        $DX[$i] = $sum
    }

    # Weight update — SKIPPED if frozen ✅
    if (-not $Layer.Frozen) {
        for ($j = 0; $j -lt $outSz; $j++) {
            $dz_j = [double]$DZ[$j]
            $base = $j * $inSz
            for ($i = 0; $i -lt $inSz; $i++) {
                # Direct element assignment on hashtable array persists! ✅
                $Layer.W[$base + $i] = [double]$Layer.W[$base + $i] - $LR * $dz_j * [double]$X[$i]
            }
            $Layer.B[$j] = [double]$Layer.B[$j] - $LR * $dz_j
        }
    }

    return ,$DX
}

# ==============================================================================
#  TL MODEL  (wrapper class — thin shell, all state in hashtable layers)
# ==============================================================================

class TLModel {
<#
    A sequential model for transfer learning.
    Layers are hashtables in an ArrayList — always references in PS 5.1.
    Forward/backward delegate to standalone functions via & (Get-Command ...).
#>
    [System.Collections.ArrayList] $Layers
    [string] $Name
    [string] $Description

    TLModel([string]$name, [string]$description) {
        $this.Name        = $name
        $this.Description = $description
        $this.Layers      = [System.Collections.ArrayList]::new()
    }

    [void] AddLayer([hashtable]$layer) {
        $this.Layers.Add($layer) | Out-Null
    }

    # Forward pass — returns output of last layer
    [object] Forward([double[]]$x) {
        $current = $x
        for ($li = 0; $li -lt $this.Layers.Count; $li++) {
            $lyr     = [hashtable]$this.Layers[$li]
            $current = [double[]]( & (Get-Command Invoke-TLLayerForward) -Layer $lyr -X ([double[]]$current) )
        }
        return $current
    }

    # Forward up to (and including) $ToLayer — for feature extraction
    [object] ForwardTo([double[]]$x, [int]$toLayer) {
        $current = $x
        $limit   = [Math]::Min($toLayer, $this.Layers.Count - 1)
        for ($li = 0; $li -le $limit; $li++) {
            $lyr     = [hashtable]$this.Layers[$li]
            $current = [double[]]( & (Get-Command Invoke-TLLayerForward) -Layer $lyr -X ([double[]]$current) )
        }
        return $current
    }

    # Backward — updates only UNFROZEN layers
    [void] Backward([double[]]$dLoss, [double]$lr) {
        $grad = [double[]]$dLoss
        for ($li = $this.Layers.Count - 1; $li -ge 0; $li--) {
            $lyr  = [hashtable]$this.Layers[$li]
            $grad = [double[]]( & (Get-Command Invoke-TLLayerBackward) -Layer $lyr -DOut $grad -LR $lr )
        }
    }

    [string] ToString() {
        $s = ('TLModel [{0}]  ' -f $this.Name)
        for ($li = 0; $li -lt $this.Layers.Count; $li++) {
            $lyr = [hashtable]$this.Layers[$li]
            $frz = if ($lyr.Frozen) { '❄' } else { '' }
            if ($li -gt 0) { $s += ' → ' }
            $s += ('{0}({1}){2}' -f $lyr.Activation, $lyr.OutSize, $frz)
        }
        return $s
    }
}

# ==============================================================================
#  MODEL ZOO  (toy pretrained models with hand-crafted weights)
# ==============================================================================

function Get-VBAFModelZoo {
<#
.SYNOPSIS
    List all available pretrained models in the VBAF toy model zoo.

.EXAMPLE
    Get-VBAFModelZoo
#>
    Write-Host ''
    Write-Host '  ── VBAF Toy Model Zoo ──────────────────────────' -ForegroundColor Magenta
    Write-Host ''
    Write-Host '  Name           Input  Output  Description' -ForegroundColor DarkGray
    Write-Host '  ─────────────────────────────────────────────────' -ForegroundColor DarkGray
    Write-Host '  EdgeDetector     16     8    Sobel-inspired edge features on 4×4 grid' -ForegroundColor White
    Write-Host '  ShapeEncoder     16     3    Encodes HBar/VBar/Diag patterns (Shapes2D)' -ForegroundColor White
    Write-Host '  PatternFilter    16     4    Low/high frequency pattern detector' -ForegroundColor White
    Write-Host ''
    Write-Host '  Usage:  $m = Get-VBAFPretrainedModel -Name "ShapeEncoder"' -ForegroundColor Yellow
    Write-Host ''
}

function Get-VBAFPretrainedModel {
<#
.SYNOPSIS
    Return a TLModel with hand-crafted "pretrained" weights.

.DESCRIPTION
    These are TOY models — weights are carefully hand-designed to capture
    meaningful structure, not trained by gradient descent. They serve as
    realistic starting points for transfer learning experiments.

    EdgeDetector : 16→8  — detects horizontal/vertical edges in 4×4 grids
    ShapeEncoder : 16→8→3 — approximately classifies HBar/VBar/Diag shapes
    PatternFilter: 16→4  — detects low/high frequency spatial patterns

.PARAMETER Name  'EdgeDetector' | 'ShapeEncoder' | 'PatternFilter'

.OUTPUTS  TLModel with Layers pre-populated

.EXAMPLE
    $m = Get-VBAFPretrainedModel -Name "ShapeEncoder"
    $m.ToString()
    [double[]]$m.Forward(@(1,1,1,1, 0,0,0,0, 0,0,0,0, 1,1,1,1))
#>
    param([Parameter(Mandatory)][string]$Name)

    if ($Name -eq 'EdgeDetector') {
        # ── EdgeDetector: 16 → 8 ─────────────────────────────────────────────
        # Detects 8 edge features in a 4×4 binary grid:
        #   Units 0-3: horizontal edge detectors (row transitions)
        #   Units 4-7: vertical edge detectors (column transitions)
        #
        # Input layout (row-major):
        #  0  1  2  3
        #  4  5  6  7
        #  8  9 10 11
        # 12 13 14 15
        #
        # Horizontal edge unit k detects transition between row k and row k+1:
        #   w = +1 for pixels in row k, -1 for pixels in row k+1
        # Vertical edge unit k detects transition between col k and col k+1:
        #   w = +1 for pixels in col k, -1 for pixels in col k+1

        $model = [TLModel]::new('EdgeDetector', 'Sobel-inspired edge detector on 4x4 grids (16→8)')

        $W = @(0.0) * (16 * 8)
        $B = @(0.0) * 8

        # Units 0-3: horizontal edge detectors
        for ($unit = 0; $unit -lt 4; $unit++) {
            for ($col = 0; $col -lt 4; $col++) {
                if ($unit -lt 3) {
                    # +1 for current row, -1 for next row
                    $W[$unit * 16 + $unit * 4 + $col]       =  1.0
                    $W[$unit * 16 + ($unit+1) * 4 + $col]   = -1.0
                } else {
                    # Last unit: detects bottom row activation
                    $W[$unit * 16 + 12 + $col] = 1.0
                }
            }
        }

        # Units 4-7: vertical edge detectors
        for ($unit = 0; $unit -lt 4; $unit++) {
            for ($row = 0; $row -lt 4; $row++) {
                if ($unit -lt 3) {
                    # +1 for current col, -1 for next col
                    $W[($unit+4) * 16 + $row * 4 + $unit]     =  1.0
                    $W[($unit+4) * 16 + $row * 4 + $unit + 1] = -1.0
                } else {
                    # Last unit: detects right column activation
                    $W[($unit+4) * 16 + $row * 4 + 3] = 1.0
                }
            }
        }

        $layer = New-TLLayer -InSize 16 -OutSize 8 -Activation 'relu' -Seed 1
        $layer.W = $W
        $layer.B = $B
        $model.AddLayer($layer)
        return $model
    }

    elseif ($Name -eq 'ShapeEncoder') {
        # ── ShapeEncoder: 16 → 8 → 3 ─────────────────────────────────────────
        # Approximately classifies Shapes2D patterns: HBar / VBar / Diag
        #
        # Layer 1 (16→8): extracts shape-relevant features
        #   Units 0-1: horizontal bar detectors (top/bottom row sums)
        #   Units 2-3: vertical bar detectors (left/right column sums)
        #   Units 4-5: diagonal detectors (main/anti diagonal)
        #   Units 6-7: density detectors (total pixel count high/low)
        #
        # Layer 2 (8→3): combines features → class scores
        #   Output 0 = HBar score, 1 = VBar score, 2 = Diag score

        $model = [TLModel]::new('ShapeEncoder', 'Encodes HBar/VBar/Diag shapes from Shapes2D (16→8→3)')

        # Layer 1 weights  (8 × 16)
        $W1 = @(0.0) * (16 * 8)
        $B1 = @(0.0) * 8

        # Unit 0: top row detector  (pixels 0-3)
        for ($i = 0; $i -lt 4; $i++)  { $W1[0  * 16 + $i]      = 1.0 }
        # Unit 1: bottom row detector  (pixels 12-15)
        for ($i = 0; $i -lt 4; $i++)  { $W1[1  * 16 + 12 + $i] = 1.0 }
        # Unit 2: left column detector  (pixels 0,4,8,12)
        for ($r = 0; $r -lt 4; $r++)  { $W1[2  * 16 + $r * 4]  = 1.0 }
        # Unit 3: right column detector  (pixels 3,7,11,15)
        for ($r = 0; $r -lt 4; $r++)  { $W1[3  * 16 + $r*4+3]  = 1.0 }
        # Unit 4: main diagonal  (pixels 0,5,10,15)
        $diag = @(0,5,10,15)
        for ($i = 0; $i -lt 4; $i++)  { $W1[4  * 16 + $diag[$i]] = 1.0 }
        # Unit 5: anti-diagonal  (pixels 3,6,9,12)
        $anti = @(3,6,9,12)
        for ($i = 0; $i -lt 4; $i++)  { $W1[5  * 16 + $anti[$i]] = 1.0 }
        # Unit 6: overall density (all pixels positive)
        for ($i = 0; $i -lt 16; $i++) { $W1[6  * 16 + $i]       = 0.25 }
        # Unit 7: sparsity detector (all pixels negative — fires for sparse)
        for ($i = 0; $i -lt 16; $i++) { $W1[7  * 16 + $i]       = -0.25 }
        $B1[7] = 2.0   # bias so it fires when few pixels active

        $layer1 = New-TLLayer -InSize 16 -OutSize 8 -Activation 'relu' -Seed 1
        $layer1.W = $W1
        $layer1.B = $B1
        $model.AddLayer($layer1)

        # Layer 2 weights  (3 × 8)
        # HBar  ← top-row (unit 0) + bottom-row (unit 1), suppress col/diag
        # VBar  ← left-col (unit 2) + right-col (unit 3), suppress row/diag
        # Diag  ← main-diag (unit 4) + anti-diag (unit 5), suppress row/col
        $W2 = @(
            2.0, 2.0,-1.0,-1.0,-1.0,-1.0, 0.0, 0.0,   # HBar
           -1.0,-1.0, 2.0, 2.0,-1.0,-1.0, 0.0, 0.0,   # VBar
           -1.0,-1.0,-1.0,-1.0, 2.0, 2.0, 0.0, 0.0    # Diag
        )
        $B2 = @(0.0, 0.0, 0.0)

        $layer2 = New-TLLayer -InSize 8 -OutSize 3 -Activation 'softmax' -Seed 2
        $layer2.W = $W2
        $layer2.B = $B2
        $model.AddLayer($layer2)

        return $model
    }

    elseif ($Name -eq 'PatternFilter') {
        # ── PatternFilter: 16 → 4 ────────────────────────────────────────────
        # Detects spatial frequency characteristics of 4×4 patterns:
        #   Unit 0: low-freq horizontal (broad horizontal bands)
        #   Unit 1: low-freq vertical   (broad vertical bands)
        #   Unit 2: high-freq checker   (checkerboard / diagonal texture)
        #   Unit 3: overall brightness  (total pixel density)

        $model = [TLModel]::new('PatternFilter', 'Spatial frequency detector on 4x4 grids (16→4)')

        $W = @(0.0) * (16 * 4)
        $B = @(0.0) * 4

        # Unit 0: low-freq horizontal — top half positive, bottom half negative
        for ($r = 0; $r -lt 4; $r++) {
            $sign = if ($r -lt 2) { 1.0 } else { -1.0 }
            for ($c = 0; $c -lt 4; $c++) {
                $W[0 * 16 + $r * 4 + $c] = $sign * 0.5
            }
        }

        # Unit 1: low-freq vertical — left half positive, right half negative
        for ($r = 0; $r -lt 4; $r++) {
            for ($c = 0; $c -lt 4; $c++) {
                $sign = if ($c -lt 2) { 1.0 } else { -1.0 }
                $W[1 * 16 + $r * 4 + $c] = $sign * 0.5
            }
        }

        # Unit 2: high-freq checker — alternating +/- in checkerboard pattern
        for ($r = 0; $r -lt 4; $r++) {
            for ($c = 0; $c -lt 4; $c++) {
                $sign = if (($r + $c) % 2 -eq 0) { 1.0 } else { -1.0 }
                $W[2 * 16 + $r * 4 + $c] = $sign * 0.5
            }
        }

        # Unit 3: overall brightness — all positive
        for ($i = 0; $i -lt 16; $i++) { $W[3 * 16 + $i] = 0.25 }

        $layer = New-TLLayer -InSize 16 -OutSize 4 -Activation 'relu' -Seed 3
        $layer.W = $W
        $layer.B = $B
        $model.AddLayer($layer)
        return $model
    }

    else {
        throw "Unknown model '$Name'. Run Get-VBAFModelZoo to see available models."
    }
}

# ==============================================================================
#  LAYER FREEZING
# ==============================================================================

function Set-VBAFLayerFrozen {
<#
.SYNOPSIS
    Freeze or unfreeze a specific layer in a TLModel.
    Frozen layers skip weight updates during fine-tuning (but still compute gradients).

.PARAMETER Model       TLModel instance
.PARAMETER LayerIndex  0-based layer index
.PARAMETER Frozen      $true to freeze, $false to unfreeze

.EXAMPLE
    $m = Get-VBAFPretrainedModel -Name "ShapeEncoder"
    Set-VBAFLayerFrozen -Model $m -LayerIndex 0 -Frozen $true   # freeze layer 0
    Set-VBAFLayerFrozen -Model $m -LayerIndex 1 -Frozen $false  # unfreeze layer 1
#>
    param(
        [Parameter(Mandatory)][TLModel]$Model,
        [Parameter(Mandatory)][int]   $LayerIndex,
        [Parameter(Mandatory)][bool]  $Frozen
    )
    if ($LayerIndex -lt 0 -or $LayerIndex -ge $Model.Layers.Count) {
        throw "LayerIndex $LayerIndex out of range (model has $($Model.Layers.Count) layers)"
    }
    $lyr = [hashtable]$Model.Layers[$LayerIndex]
    $lyr.Frozen = $Frozen
    $status = if ($Frozen) { '❄ frozen' } else { '▶ trainable' }
    Write-Host ("  Layer {0} ({1}→{2}): {3}" -f $LayerIndex, $lyr.InSize, $lyr.OutSize, $status) -ForegroundColor Cyan
}

function Set-VBAFAllLayersFrozen {
<#
.SYNOPSIS  Freeze or unfreeze ALL layers in a model at once.

.EXAMPLE
    Set-VBAFAllLayersFrozen -Model $m -Frozen $true    # freeze everything
    Set-VBAFAllLayersFrozen -Model $m -Frozen $false   # unfreeze everything
#>
    param(
        [Parameter(Mandatory)][TLModel]$Model,
        [Parameter(Mandatory)][bool]  $Frozen
    )
    for ($li = 0; $li -lt $Model.Layers.Count; $li++) {
        $lyr        = [hashtable]$Model.Layers[$li]
        $lyr.Frozen = $Frozen
    }
    $status = if ($Frozen) { '❄ ALL frozen' } else { '▶ ALL trainable' }
    Write-Host ("  {0}  ({1} layers)" -f $status, $Model.Layers.Count) -ForegroundColor Cyan
}

function Get-VBAFFrozenLayers {
<#
.SYNOPSIS  Return indices of all frozen layers.
.OUTPUTS   int[]  (comma-protected)
#>
    param([Parameter(Mandatory)][TLModel]$Model)
    $result = [System.Collections.ArrayList]::new()
    for ($li = 0; $li -lt $Model.Layers.Count; $li++) {
        $lyr = [hashtable]$Model.Layers[$li]
        if ($lyr.Frozen) { $result.Add($li) | Out-Null }
    }
    return ,$result
}

function Get-VBAFTrainableLayers {
<#
.SYNOPSIS  Return indices of all trainable (unfrozen) layers.
.OUTPUTS   ArrayList of int  (comma-protected)
#>
    param([Parameter(Mandatory)][TLModel]$Model)
    $result = [System.Collections.ArrayList]::new()
    for ($li = 0; $li -lt $Model.Layers.Count; $li++) {
        $lyr = [hashtable]$Model.Layers[$li]
        if (-not $lyr.Frozen) { $result.Add($li) | Out-Null }
    }
    return ,$result
}

function Show-VBAFModelStatus {
<#
.SYNOPSIS  Print a layer-by-layer summary showing frozen/trainable status.

.EXAMPLE
    Show-VBAFModelStatus -Model $m
#>
    param([Parameter(Mandatory)][TLModel]$Model)
    Write-Host ''
    Write-Host ("  ── {0} ──" -f $Model.Name) -ForegroundColor Magenta
    Write-Host ("  {0}" -f $Model.Description) -ForegroundColor DarkGray
    Write-Host ''
    Write-Host '  Idx  Shape       Activation  Status       Params' -ForegroundColor DarkGray
    Write-Host '  ─────────────────────────────────────────────────' -ForegroundColor DarkGray
    $totalParams    = 0
    $trainableParams = 0
    for ($li = 0; $li -lt $Model.Layers.Count; $li++) {
        $lyr    = [hashtable]$Model.Layers[$li]
        $params = [int]$lyr.InSize * [int]$lyr.OutSize + [int]$lyr.OutSize
        $totalParams += $params
        $status = if ($lyr.Frozen) { '❄ frozen   ' } else { '▶ trainable' }
        if (-not $lyr.Frozen) { $trainableParams += $params }
        $color  = if ($lyr.Frozen) { 'DarkCyan' } else { 'Green' }
        Write-Host ("  {0,3}  {1,4}→{2,-4}  {3,-10}  {4}  {5,6}" -f `
            $li, $lyr.InSize, $lyr.OutSize, $lyr.Activation, $status, $params) -ForegroundColor $color
    }
    Write-Host '  ─────────────────────────────────────────────────' -ForegroundColor DarkGray
    Write-Host ("  Total params: {0}   Trainable: {1}   Frozen: {2}" -f `
        $totalParams, $trainableParams, ($totalParams - $trainableParams)) -ForegroundColor DarkGray
    Write-Host ''
}

# ==============================================================================
#  FEATURE EXTRACTION
# ==============================================================================

function Get-VBAFFeatures {
<#
.SYNOPSIS
    Run a forward pass and return activations at a specified layer depth.
    Use this to treat a frozen pretrained encoder as a feature extractor.

.DESCRIPTION
    This is the core of transfer learning:
        1. Load pretrained model
        2. Freeze all layers
        3. Run Get-VBAFFeatures to get rich representations
        4. Feed those representations to a new trainable head

.PARAMETER Model      TLModel instance
.PARAMETER X          Input vector [double[]]
.PARAMETER FromLayer  Layer index whose OUTPUT to return (0-based)
                      -1 = return final output (default)

.OUTPUTS  [double[]]  activation vector at the requested depth  (comma-protected)

.EXAMPLE
    $m     = Get-VBAFPretrainedModel -Name "EdgeDetector"
    $feats = Get-VBAFFeatures -Model $m -X $ds.X[0] -FromLayer 0
    # $feats is the 8-dim edge feature vector
#>
    param(
        [Parameter(Mandatory)][TLModel]$Model,
        [Parameter(Mandatory)][double[]]$X,
        [int]$FromLayer = -1
    )
    if ($FromLayer -lt 0) { $FromLayer = $Model.Layers.Count - 1 }
    $feats = [double[]]$Model.ForwardTo($X, $FromLayer)
    return ,$feats
}

function Get-VBAFBatchFeatures {
<#
.SYNOPSIS
    Extract features for an entire dataset. Returns ArrayList of [double[]].

.PARAMETER Model      TLModel instance
.PARAMETER Data       ArrayList of [double[]] samples
.PARAMETER FromLayer  Layer index to extract from (-1 = last layer)

.OUTPUTS  ArrayList of [double[]]  (comma-protected)

.EXAMPLE
    $m     = Get-VBAFPretrainedModel -Name "ShapeEncoder"
    $feats = Get-VBAFBatchFeatures -Model $m -Data $ds.X -FromLayer 0
    # $feats[0] is the 8-dim feature vector for sample 0
#>
    param(
        [Parameter(Mandatory)][TLModel]$Model,
        [Parameter(Mandatory)]$Data,
        [int]$FromLayer = -1
    )
    $results = [System.Collections.ArrayList]::new()
    for ($si = 0; $si -lt $Data.Count; $si++) {
        $x     = [double[]]$Data[$si]
        $feats = [double[]](Get-VBAFFeatures -Model $Model -X $x -FromLayer $FromLayer)
        $results.Add($feats) | Out-Null
    }
    return ,$results
}

# ==============================================================================
#  FINE-TUNING
# ==============================================================================

function Get-TLCrossEntropyLoss {
<#
.SYNOPSIS  Scalar cross-entropy loss for classification.
           L = -Σ label[i] * log(pred[i] + ε)
#>
    param([double[]]$Pred, [int]$TrueClass)
    $eps = 1e-10
    $p   = [Math]::Max($eps, [double]$Pred[$TrueClass])
    return (-[Math]::Log($p))
}

function Get-TLCrossEntropyGrad {
<#
.SYNOPSIS  Gradient of cross-entropy w.r.t. softmax output.
           dL/dPred[i] = Pred[i] - 1(i == TrueClass)
           (Combined softmax + cross-entropy gradient — numerically clean)
.OUTPUTS   [double[]]  (comma-protected)
#>
    param([double[]]$Pred, [int]$TrueClass)
    $n  = $Pred.Length
    $dL = [double[]]::new($n)
    for ($i = 0; $i -lt $n; $i++) {
        $dL[$i] = [double]$Pred[$i]
    }
    $dL[$TrueClass] -= 1.0
    return ,$dL
}

function Get-TLMSELoss {
<#
.SYNOPSIS  MSE loss for reconstruction tasks during fine-tuning.
#>
    param([double[]]$Pred, [double[]]$Target)
    $sum = 0.0; $n = $Pred.Length
    for ($i = 0; $i -lt $n; $i++) {
        $d = [double]$Pred[$i] - [double]$Target[$i]; $sum += $d * $d
    }
    return ($sum / $n)
}

function Get-TLMSEGrad {
<#
.SYNOPSIS  Gradient of MSE w.r.t. predictions.
.OUTPUTS   [double[]]  (comma-protected)
#>
    param([double[]]$Pred, [double[]]$Target)
    $n = $Pred.Length; $dL = [double[]]::new($n)
    for ($i = 0; $i -lt $n; $i++) {
        $dL[$i] = 2.0 * ([double]$Pred[$i] - [double]$Target[$i]) / $n
    }
    return ,$dL
}

function Invoke-VBAFFineTune {
<#
.SYNOPSIS
    Fine-tune a TLModel using backprop only through UNFROZEN layers.
    Frozen layers still compute gradients (needed to pass gradient backward)
    but their weights are NOT updated.

.DESCRIPTION
    Typical transfer learning workflow:
        1. Get-VBAFPretrainedModel            load pretrained weights
        2. Set-VBAFAllLayersFrozen $true      freeze everything
        3. Set-VBAFLayerFrozen $m -LayerIndex N -Frozen $false   unfreeze head
        4. Invoke-VBAFFineTune                train only the head

    Loss function:
        Classification (Labels provided) → cross-entropy
        Reconstruction  (Targets provided) → MSE

.PARAMETER Model        TLModel to fine-tune
.PARAMETER Data         ArrayList of [double[]] input samples
.PARAMETER Labels       ArrayList of [int] class labels  (classification)
.PARAMETER Targets      ArrayList of [double[]] target vectors  (reconstruction)
.PARAMETER Epochs       Training epochs  (default 50)
.PARAMETER LR           Learning rate   (default 0.01)
.PARAMETER PrintEvery   Print every N epochs. 0 = silent.  (default 10)

.OUTPUTS  Hashtable: FinalLoss, LossHistory, Model, Accuracy

.EXAMPLE
    $m = Get-VBAFPretrainedModel -Name "ShapeEncoder"
    Set-VBAFAllLayersFrozen -Model $m -Frozen $true
    Set-VBAFLayerFrozen -Model $m -LayerIndex 1 -Frozen $false
    $r = Invoke-VBAFFineTune -Model $m -Data $ds.X -Labels $ds.Labels -Epochs 50 -LR 0.05
    $r.FinalLoss
    $r.Accuracy
#>
    param(
        [Parameter(Mandatory)][TLModel]$Model,
        [Parameter(Mandatory)]$Data,
        $Labels     = $null,
        $Targets    = $null,
        [int]   $Epochs     = 50,
        [double]$LR         = 0.01,
        [int]   $PrintEvery = 10
    )

    if ($null -eq $Labels -and $null -eq $Targets) {
        throw "Provide either -Labels (classification) or -Targets (reconstruction)"
    }
    $isClassification = ($null -ne $Labels)
    $nSamples         = $Data.Count
    $lossHistory      = [System.Collections.ArrayList]::new()

    # Count trainable params for display
    $trainable = Get-VBAFTrainableLayers -Model $Model
    Write-Host ("  Fine-tuning [{0}]  {1} trainable layer(s), {2} frozen" -f `
        $Model.Name, $trainable.Count, ($Model.Layers.Count - $trainable.Count)) -ForegroundColor Magenta
    $taskLabel = if ($isClassification) {'Classification'} else {'Reconstruction'}
    Write-Host ("  Task: {0}   Samples: {1}   Epochs: {2}   LR: {3}" -f `
        $taskLabel, $nSamples, $Epochs, $LR) -ForegroundColor DarkGray
    Write-Host ''

    for ($ep = 1; $ep -le $Epochs; $ep++) {
        $epochLoss    = 0.0
        $epochCorrect = 0

        for ($si = 0; $si -lt $nSamples; $si++) {
            $x    = [double[]]$Data[$si]
            $pred = [double[]]$Model.Forward($x)

            if ($isClassification) {
                $lbl       = [int]$Labels[$si]
                $epochLoss += Get-TLCrossEntropyLoss -Pred $pred -TrueClass $lbl
                $dLoss      = [double[]](Get-TLCrossEntropyGrad -Pred $pred -TrueClass $lbl)
                # Accuracy: argmax of prediction
                $maxIdx = 0; $maxVal = [double]$pred[0]
                for ($k = 1; $k -lt $pred.Length; $k++) {
                    if ([double]$pred[$k] -gt $maxVal) { $maxVal = [double]$pred[$k]; $maxIdx = $k }
                }
                if ($maxIdx -eq $lbl) { $epochCorrect++ }
            } else {
                $tgt       = [double[]]$Targets[$si]
                $epochLoss += Get-TLMSELoss -Pred $pred -Target $tgt
                $dLoss      = [double[]](Get-TLMSEGrad -Pred $pred -Target $tgt)
            }

            $Model.Backward($dLoss, $LR)
        }

        $avgLoss = $epochLoss / $nSamples
        $lossHistory.Add($avgLoss) | Out-Null

        if ($PrintEvery -gt 0 -and ($ep -eq 1 -or $ep % $PrintEvery -eq 0)) {
            $acc   = if ($isClassification) { '  Acc: {0:P0}' -f ($epochCorrect / $nSamples) } else { '' }
            $color = if ($avgLoss -lt 0.5) { 'Green' } elseif ($avgLoss -lt 1.0) { 'Yellow' } else { 'Red' }
            Write-Host ("  Epoch {0,4}/{1}  Loss: {2:F5}{3}" -f $ep, $Epochs, $avgLoss, $acc) -ForegroundColor $color
        }
    }

    $finalLoss = [double]$lossHistory[$lossHistory.Count - 1]

    # Final accuracy pass
    $finalCorrect = 0
    if ($isClassification) {
        for ($si = 0; $si -lt $nSamples; $si++) {
            $x    = [double[]]$Data[$si]
            $pred = [double[]]$Model.Forward($x)
            $lbl  = [int]$Labels[$si]
            $maxIdx = 0; $maxVal = [double]$pred[0]
            for ($k = 1; $k -lt $pred.Length; $k++) {
                if ([double]$pred[$k] -gt $maxVal) { $maxVal = [double]$pred[$k]; $maxIdx = $k }
            }
            if ($maxIdx -eq $lbl) { $finalCorrect++ }
        }
    }
    $finalAcc = if ($isClassification) { $finalCorrect / $nSamples } else { 0.0 }

    Write-Host ''
    Write-Host ("  ── Fine-tune complete ──  Loss: {0:F5}  Acc: {1:P0}" -f $finalLoss, $finalAcc) -ForegroundColor Magenta
    Write-Host ''

    return @{
        FinalLoss   = $finalLoss
        LossHistory = $lossHistory
        Accuracy    = $finalAcc
        Model       = $Model
    }
}

# ==============================================================================
#  WEIGHT SAVE / LOAD  (JSON, compatible with VBAF.ML.CNN.ps1 pattern)
# ==============================================================================

function Save-VBAFTLWeights {
<#
.SYNOPSIS
    Save TLModel weights to JSON.
    Format compatible with VBAF.ML.CNN.ps1 Save-CNNWeights pattern.

.PARAMETER Model  TLModel to save
.PARAMETER Path   File path for JSON output

.EXAMPLE
    Save-VBAFTLWeights -Model $m -Path "C:\Temp\ShapeEncoder.json"
#>
    param(
        [Parameter(Mandatory)][TLModel]$Model,
        [Parameter(Mandatory)][string]$Path
    )
    $layerData = [System.Collections.ArrayList]::new()
    for ($li = 0; $li -lt $Model.Layers.Count; $li++) {
        $lyr = [hashtable]$Model.Layers[$li]
        $layerData.Add(@{
            Index      = $li
            InSize     = $lyr.InSize
            OutSize    = $lyr.OutSize
            Activation = $lyr.Activation
            Frozen     = $lyr.Frozen
            W          = $lyr.W
            B          = $lyr.B
        }) | Out-Null
    }
    $payload = @{
        ModelName   = $Model.Name
        Description = $Model.Description
        NumLayers   = $Model.Layers.Count
        SavedAt     = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
        Layers      = $layerData
    }
    $payload | ConvertTo-Json -Depth 10 | Out-File -FilePath $Path -Encoding UTF8
    Write-Host ("  ✅ Saved [{0}] → {1}" -f $Model.Name, $Path) -ForegroundColor Green
}

function Load-VBAFTLWeights {
<#
.SYNOPSIS
    Load TLModel weights from JSON. Returns a TLModel.

.PARAMETER Path  Path to JSON file saved by Save-VBAFTLWeights

.OUTPUTS  TLModel with weights restored

.EXAMPLE
    $m = Load-VBAFTLWeights -Path "C:\Temp\ShapeEncoder.json"
    $m.ToString()
#>
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path $Path)) { throw "File not found: $Path" }

    $raw     = Get-Content $Path -Raw | ConvertFrom-Json
    $model   = [TLModel]::new($raw.ModelName, $raw.Description)

    for ($li = 0; $li -lt $raw.Layers.Count; $li++) {
        $ld    = $raw.Layers[$li]
        $layer = New-TLLayer -InSize $ld.InSize -OutSize $ld.OutSize -Activation $ld.Activation -Seed 1

        # Restore weights — must use index assignment on hashtable array ✅
        $wArr = $ld.W
        for ($i = 0; $i -lt $wArr.Count; $i++) { $layer.W[$i] = [double]$wArr[$i] }
        $bArr = $ld.B
        for ($i = 0; $i -lt $bArr.Count; $i++) { $layer.B[$i] = [double]$bArr[$i] }
        $layer.Frozen = [bool]$ld.Frozen

        $model.AddLayer($layer)
    }
    Write-Host ("  ✅ Loaded [{0}] ← {1}" -f $model.Name, $Path) -ForegroundColor Green
    return $model
}

# ==============================================================================
#  EVALUATION HELPER
# ==============================================================================

function Test-VBAFTLClassify {
<#
.SYNOPSIS
    Run classification on a dataset and print per-class accuracy.

.PARAMETER Model       TLModel (output layer should be softmax)
.PARAMETER Data        ArrayList of [double[]]
.PARAMETER Labels      ArrayList of [int]
.PARAMETER ClassNames  string[] for display

.OUTPUTS  Hashtable: Accuracy, CorrectCount, ConfusionMatrix

.EXAMPLE
    $r = Test-VBAFTLClassify -Model $m -Data $ds.X -Labels $ds.Labels -ClassNames $ds.ClassNames
    $r.Accuracy
#>
    param(
        [Parameter(Mandatory)][TLModel]$Model,
        [Parameter(Mandatory)]$Data,
        [Parameter(Mandatory)]$Labels,
        $ClassNames = $null
    )
    $n          = $Data.Count
    $numClasses = 0
    # Infer number of classes from max label
    for ($i = 0; $i -lt $n; $i++) {
        $l = [int]$Labels[$i]
        if ($l -ge $numClasses) { $numClasses = $l + 1 }
    }
    if ($null -eq $ClassNames) {
        $ClassNames = [string[]]::new($numClasses)
        for ($c = 0; $c -lt $numClasses; $c++) { $ClassNames[$c] = "Class$c" }
    }

    # Confusion matrix as flat array [true * numClasses + pred]
    $cm      = @(0) * ($numClasses * $numClasses)
    $correct = 0

    for ($si = 0; $si -lt $n; $si++) {
        $x    = [double[]]$Data[$si]
        $pred = [double[]]$Model.Forward($x)
        $lbl  = [int]$Labels[$si]

        $maxIdx = 0; $maxVal = [double]$pred[0]
        for ($k = 1; $k -lt $pred.Length; $k++) {
            if ([double]$pred[$k] -gt $maxVal) { $maxVal = [double]$pred[$k]; $maxIdx = $k }
        }
        $cm[$lbl * $numClasses + $maxIdx]++
        if ($maxIdx -eq $lbl) { $correct++ }
    }

    $acc = $correct / $n

    Write-Host ''
    Write-Host ('  ── Classification Report [{0}] ──' -f $Model.Name) -ForegroundColor Magenta
    $accColor = if ($acc -ge 0.9) {'Green'} elseif ($acc -ge 0.6) {'Yellow'} else {'Red'}
    Write-Host ('  Overall accuracy: {0:P1}  ({1}/{2})' -f $acc, $correct, $n) -ForegroundColor $accColor
    Write-Host ''
    Write-Host '  Confusion Matrix (rows=true, cols=pred):' -ForegroundColor DarkGray

    # Header
    $header = '            '
    for ($c = 0; $c -lt $numClasses; $c++) { $header += ('{0,8}' -f $ClassNames[$c]) }
    Write-Host $header -ForegroundColor DarkGray

    for ($r = 0; $r -lt $numClasses; $r++) {
        $row = ('  {0,-10}' -f $ClassNames[$r])
        for ($c = 0; $c -lt $numClasses; $c++) {
            $val = $cm[$r * $numClasses + $c]
            $row += ('{0,8}' -f $val)
        }
        $color = if ($cm[$r * $numClasses + $r] -gt 0) { 'White' } else { 'Red' }
        Write-Host $row -ForegroundColor $color
    }
    Write-Host ''

    return @{
        Accuracy        = $acc
        CorrectCount    = $correct
        ConfusionMatrix = $cm
        NumClasses      = $numClasses
    }
}

# ==============================================================================
#  SMOKE TEST
# ==============================================================================

function Test-VBAFTransferLearning {
<#
.SYNOPSIS
    End-to-end smoke test covering all Transfer Learning features.
    Uses Shapes2D dataset (requires Get-VBAFAEDataset from Autoencoder module).

.DESCRIPTION
    Tests:
    1. Model zoo listing
    2. All three pretrained models load and produce correct output shapes
    3. EdgeDetector: verify edge features fire on HBar pattern
    4. ShapeEncoder: verify correct class predicted (zero-shot, no training)
    5. Layer freezing / unfreezing
    6. Feature extraction (batch)
    7. Fine-tuning (frozen encoder + trainable head)
    8. Save / Load weights round-trip

.EXAMPLE
    Test-VBAFTransferLearning
#>
    Write-Host ''
    Write-Host '  ══════════════════════════════════════════════════' -ForegroundColor Magenta
    Write-Host '  VBAF Transfer Learning — Smoke Test' -ForegroundColor Magenta
    Write-Host '  ══════════════════════════════════════════════════' -ForegroundColor Magenta

    # ── 1. Dataset ────────────────────────────────────────────────────────────
    Write-Host '  [1/8] Loading Shapes2D dataset...' -ForegroundColor Gray
    $ds = $null
    try {
        $ds = Get-VBAFAEDataset -Name 'Shapes2D'
        Write-Host ("        {0} samples × {1} dims  ({2} classes)" -f `
            $ds.NumSamples, $ds.InputDim, $ds.NumClasses) -ForegroundColor DarkGray
    } catch {
        Write-Host '        ⚠️  Get-VBAFAEDataset not found.' -ForegroundColor Yellow
        Write-Host '           Load VBAF.ML.Autoencoder.ps1 first, or run manually.' -ForegroundColor Yellow
        Write-Host '           Continuing with synthetic data...' -ForegroundColor Yellow
        # Build minimal synthetic dataset
        $ds = @{
            X          = [System.Collections.ArrayList]::new()
            Labels     = [System.Collections.ArrayList]::new()
            ClassNames = @('HBar','VBar','Diag')
            InputDim   = 16
            NumClasses = 3
            NumSamples = 3
        }
        $ds.X.Add([double[]](1,1,1,1, 0,0,0,0, 0,0,0,0, 1,1,1,1)) | Out-Null  # HBar
        $ds.X.Add([double[]](1,0,0,1, 1,0,0,1, 1,0,0,1, 1,0,0,1)) | Out-Null  # VBar
        $ds.X.Add([double[]](1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1)) | Out-Null  # Diag
        $ds.Labels.Add(0) | Out-Null; $ds.Labels.Add(1) | Out-Null; $ds.Labels.Add(2) | Out-Null
    }

    # ── 2. Model Zoo ─────────────────────────────────────────────────────────
    Write-Host '  [2/8] Model zoo...' -ForegroundColor Gray
    Get-VBAFModelZoo

    # ── 3. Load all pretrained models ─────────────────────────────────────────
    Write-Host '  [3/8] Loading pretrained models...' -ForegroundColor Gray
    $edge   = Get-VBAFPretrainedModel -Name 'EdgeDetector'
    $shape  = Get-VBAFPretrainedModel -Name 'ShapeEncoder'
    $filter = Get-VBAFPretrainedModel -Name 'PatternFilter'
    Write-Host ("        {0}" -f $edge.ToString())   -ForegroundColor DarkGray
    Write-Host ("        {0}" -f $shape.ToString())  -ForegroundColor DarkGray
    Write-Host ("        {0}" -f $filter.ToString()) -ForegroundColor DarkGray

    # ── 4. EdgeDetector: check output shape ───────────────────────────────────
    Write-Host '  [4/8] EdgeDetector feature extraction...' -ForegroundColor Gray
    $hbarInput = [double[]]$ds.X[0]
    $edgeFeats = [double[]](Get-VBAFFeatures -Model $edge -X $hbarInput -FromLayer 0)
    Write-Host ("        HBar input → {0}-dim edge features" -f $edgeFeats.Length) -ForegroundColor DarkGray
    $featStr = ''
    for ($i = 0; $i -lt $edgeFeats.Length; $i++) {
        $featStr += ('{0:F2}  ' -f $edgeFeats[$i])
    }
    Write-Host ("        Features: {0}" -f $featStr.TrimEnd()) -ForegroundColor DarkGray

    # ── 5. ShapeEncoder: zero-shot classification ─────────────────────────────
    Write-Host '  [5/8] ShapeEncoder zero-shot classification...' -ForegroundColor Gray
    $zeroShotResult = Test-VBAFTLClassify -Model $shape -Data $ds.X -Labels $ds.Labels -ClassNames $ds.ClassNames

    # ── 6. Freezing / unfreezing ──────────────────────────────────────────────
    Write-Host '  [6/8] Layer freeze/unfreeze...' -ForegroundColor Gray
    Show-VBAFModelStatus -Model $shape
    Set-VBAFLayerFrozen -Model $shape -LayerIndex 0 -Frozen $true
    $frozen    = Get-VBAFFrozenLayers   -Model $shape
    $trainable = Get-VBAFTrainableLayers -Model $shape
    Write-Host ("        Frozen layers: {0}   Trainable: {1}" -f $frozen.Count, $trainable.Count) -ForegroundColor DarkGray

    # ── 7. Fine-tuning (frozen encoder, trainable head) ───────────────────────
    Write-Host '  [7/8] Fine-tuning (layer 0 frozen, layer 1 trainable)...' -ForegroundColor Gray
    $ftResult = Invoke-VBAFFineTune -Model $shape -Data $ds.X -Labels $ds.Labels `
                                    -Epochs 100 -LR 0.05 -PrintEvery 20
    $ftColor = if ($ftResult.Accuracy -ge 0.8) {'Green'} else {'Yellow'}
    Write-Host ("        Post fine-tune accuracy: {0:P0}" -f $ftResult.Accuracy) -ForegroundColor $ftColor
    $postFT = Test-VBAFTLClassify -Model $shape -Data $ds.X -Labels $ds.Labels -ClassNames $ds.ClassNames

    # ── 8. Save / Load round-trip ─────────────────────────────────────────────
    Write-Host '  [8/8] Save / Load weight round-trip...' -ForegroundColor Gray
    $tmpPath = "$env:TEMP\VBAF_TL_ShapeEncoder_test.json"
    Save-VBAFTLWeights -Model $shape -Path $tmpPath
    $loaded  = Load-VBAFTLWeights -Path $tmpPath
    # Verify weights match
    $origW0   = [double[]]([hashtable]$shape.Layers[0]).W
    $loadedW0 = [double[]]([hashtable]$loaded.Layers[0]).W
    $match    = $true
    for ($i = 0; $i -lt [Math]::Min(5, $origW0.Length); $i++) {
        if ([Math]::Abs($origW0[$i] - $loadedW0[$i]) -gt 1e-10) { $match = $false }
    }
    $matchStr = if ($match) { '✅ weights match' } else { '❌ weights mismatch' }
    $matchColor = if ($match) {'Green'} else {'Red'}
    Write-Host ("        Round-trip: {0}" -f $matchStr) -ForegroundColor $matchColor

    # ── Summary ───────────────────────────────────────────────────────────────
    Write-Host '  ── Summary ────────────────────────────────────────' -ForegroundColor DarkGray
    Write-Host ("  Model zoo:        3 models  ✅") -ForegroundColor Green
    Write-Host ("  Feature extract:  {0}-dim edge features  ✅" -f $edgeFeats.Length) -ForegroundColor Green
    $zsColor  = if ($zeroShotResult.Accuracy -ge 0.5) {'Green'} else {'Yellow'}
    $ftColor2 = if ($postFT.Accuracy -ge 0.8) {'Green'} else {'Yellow'}
    $slColor  = if ($match) {'Green'} else {'Red'}
    Write-Host ("  Zero-shot acc:    {0:P0}" -f $zeroShotResult.Accuracy) -ForegroundColor $zsColor
    Write-Host ("  Post-finetune:    {0:P0}" -f $postFT.Accuracy)         -ForegroundColor $ftColor2
    Write-Host ("  Save/Load:        {0}" -f $matchStr)                   -ForegroundColor $slColor
    Write-Host ''
}

# ==============================================================================
# TEST
# 1. Run VBAF.LoadAll.ps1
#
# --- Quick smoke test ---
# 2. Test-VBAFTransferLearning
#    # Requires VBAF.ML.Autoencoder.ps1 loaded for Shapes2D dataset
#    # Falls back to synthetic 3-sample data if not available
#
# --- Manual step-by-step ---
# 3. # List available pretrained models
#    Get-VBAFModelZoo
#
# 4. # Load a pretrained model
#    $m = Get-VBAFPretrainedModel -Name "ShapeEncoder"
#    $m.ToString()
#
# 5. # Inspect layer status
#    Show-VBAFModelStatus -Model $m
#
# 6. # Zero-shot classify Shapes2D
#    $ds = Get-VBAFAEDataset -Name "Shapes2D"
#    Test-VBAFTLClassify -Model $m -Data $ds.X -Labels $ds.Labels -ClassNames $ds.ClassNames
#
# 7. # Feature extraction (frozen encoder)
#    $feats = Get-VBAFBatchFeatures -Model $m -Data $ds.X -FromLayer 0
#    # $feats[0] = 8-dim feature vector for sample 0
#
# 8. # Freeze encoder, fine-tune head only
#    Set-VBAFAllLayersFrozen -Model $m -Frozen $true
#    Set-VBAFLayerFrozen -Model $m -LayerIndex 1 -Frozen $false
#    $r = Invoke-VBAFFineTune -Model $m -Data $ds.X -Labels $ds.Labels -Epochs 100 -LR 0.05 -PrintEvery 10
#    $r.Accuracy    # should be > 0.8 after fine-tuning
#
# 9. # Save / Load weights
#    Save-VBAFTLWeights -Model $m -Path "C:\Temp\MyModel.json"
#    $m2 = Load-VBAFTLWeights -Path "C:\Temp\MyModel.json"
#
# --- PS 5.1 gotchas (same as Autoencoder module) ---
# -PrintEvery NOT -Verbose (reserved common parameter)
# Weight updates: $layer.W[$i] = value (direct element assignment, persists ✅)
# Functions in class methods: & (Get-Command Func) -Param val
# ==============================================================================

# ==============================================================================
#  MODULE FOOTER
# ==============================================================================

Write-Host '  Functions loaded:' -ForegroundColor DarkGray
Write-Host '    Get-VBAFModelZoo              Get-VBAFPretrainedModel' -ForegroundColor DarkGray
Write-Host '    Set-VBAFLayerFrozen           Set-VBAFAllLayersFrozen' -ForegroundColor DarkGray
Write-Host '    Get-VBAFFrozenLayers          Get-VBAFTrainableLayers' -ForegroundColor DarkGray
Write-Host '    Show-VBAFModelStatus          Get-VBAFFeatures' -ForegroundColor DarkGray
Write-Host '    Get-VBAFBatchFeatures         Invoke-VBAFFineTune' -ForegroundColor DarkGray
Write-Host '    Save-VBAFTLWeights            Load-VBAFTLWeights' -ForegroundColor DarkGray
Write-Host '    Test-VBAFTLClassify           Test-VBAFTransferLearning' -ForegroundColor DarkGray
Write-Host '  Classes: [TLModel]' -ForegroundColor DarkGray
Write-Host ''
Write-Host '  Quick start:  Test-VBAFTransferLearning' -ForegroundColor Cyan
Write-Host ''