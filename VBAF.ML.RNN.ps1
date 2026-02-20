#Requires -Version 5.1
<#
.SYNOPSIS
    Recurrent Neural Networks - Sequence Learning Architectures
.DESCRIPTION
    Implements recurrent architectures from scratch.
    Designed as a TEACHING resource - every gate explained.
    Architectures included:
      - BasicRNN         : simple recurrent cell, vanishing gradient problem
      - LSTM             : Long Short-Term Memory, forget/input/output gates
      - GRU              : Gated Recurrent Unit, simpler than LSTM
      - BidirectionalRNN : processes sequence forward AND backward
      - Seq2Seq          : encoder-decoder for sequence translation
      - Attention        : learn WHICH part of input to focus on
    Utilities:
      - Sequence datasets : sine wave, text, number sequences
      - Gradient clipping : prevent exploding gradients
      - Teacher forcing   : seq2seq training trick
.NOTES
    Part of VBAF - Phase 6 Deep Learning Module
    PS 5.1 compatible - pure PowerShell, no dependencies
    Teaching project - every gate equation shown step by step!
#>
$basePath = $PSScriptRoot

# ============================================================
# TEACHING NOTE: Why Recurrent Networks?
# Standard networks treat each input INDEPENDENTLY.
# But sequences have CONTEXT - what came before matters!
#
# "The cat sat on the ___" -> "mat" (context from earlier words)
# Stock price tomorrow depends on prices OVER TIME
# Music note depends on what was played BEFORE
#
# RNNs maintain a HIDDEN STATE - a memory of past inputs.
# At each step: h_t = f(x_t, h_{t-1})
# The hidden state carries information forward through time.
#
# Problem: Basic RNNs suffer from VANISHING GRADIENTS.
# Information from many steps ago fades away.
# LSTM and GRU solve this with GATES that control memory flow.
# ============================================================

# ============================================================
# ACTIVATION FUNCTIONS
# ============================================================

function Invoke-RNNSigmoid { param([double[]]$x)
    return $x | ForEach-Object { 1.0 / (1.0 + [Math]::Exp(-[Math]::Max(-500, [Math]::Min(500, $_)))) }
}

function Invoke-RNNTanh { param([double[]]$x)
    return $x | ForEach-Object {
        $e2 = [Math]::Exp(2 * [Math]::Max(-250, [Math]::Min(250, $_)))
        ($e2 - 1) / ($e2 + 1)
    }
}

function Invoke-RNNSoftmax { param([double[]]$x)
    $maxV = ($x | Measure-Object -Maximum).Maximum
    $exps = $x | ForEach-Object { [Math]::Exp($_ - $maxV) }
    $sumE = ($exps | Measure-Object -Sum).Sum
    return $exps | ForEach-Object { $_ / $sumE }
}

# Vector operations
function Add-Vectors { param([double[]]$a, [double[]]$b)
    $r = @(0.0) * $a.Length
    for ($i = 0; $i -lt $a.Length; $i++) { $r[$i] = $a[$i] + $b[$i] }
    return $r
}

function Mul-Vectors { param([double[]]$a, [double[]]$b)
    $r = @(0.0) * $a.Length
    for ($i = 0; $i -lt $a.Length; $i++) { $r[$i] = $a[$i] * $b[$i] }
    return $r
}

# Matrix-vector multiply: W (rows x cols) * x (cols) -> (rows)
function MatVec { param([double[]]$W, [double[]]$x, [int]$rows, [int]$cols)
    $r = @(0.0) * $rows
    for ($i = 0; $i -lt $rows; $i++) {
        $sum = 0.0
        for ($j = 0; $j -lt $cols; $j++) { $sum += $W[$i * $cols + $j] * $x[$j] }
        $r[$i] = $sum
    }
    return $r
}

# Random weight matrix initialization (Xavier)
function New-RNNWeights { param([int]$rows, [int]$cols, [int]$seed = 42)
    $rng   = [System.Random]::new($seed)
    $scale = [Math]::Sqrt(2.0 / ($rows + $cols))
    $W     = @(0.0) * ($rows * $cols)
    for ($i = 0; $i -lt $W.Length; $i++) {
        $W[$i] = ($rng.NextDouble() * 2 - 1) * $scale
    }
    return $W
}

# Gradient clipping - prevent exploding gradients
function Invoke-GradientClip { param([double[]]$grads, [double]$threshold = 1.0)
    $norm = 0.0
    foreach ($g in $grads) { $norm += $g * $g }
    $norm = [Math]::Sqrt($norm)
    if ($norm -gt $threshold) {
        $scale = $threshold / $norm
        return $grads | ForEach-Object { $_ * $scale }
    }
    return $grads
}

# ============================================================
# BASIC RNN CELL
# ============================================================
# TEACHING NOTE: The simplest recurrent cell.
# At each timestep t:
#   h_t = tanh(W_xh * x_t + W_hh * h_{t-1} + b_h)
#   y_t = W_hy * h_t + b_y
#
# W_xh : input  -> hidden weights
# W_hh : hidden -> hidden weights (the recurrent connection!)
# W_hy : hidden -> output weights
#
# PROBLEM: tanh gradient < 1, so after many timesteps
# gradients shrink to zero = VANISHING GRADIENT.
# The network forgets events from many steps ago!
# ============================================================

class BasicRNNCell {
    [int]      $InputSize
    [int]      $HiddenSize
    [double[]] $Wxh        # input->hidden
    [double[]] $Whh        # hidden->hidden
    [double[]] $Bh         # hidden bias
    [double[]] $H          # current hidden state
    [System.Collections.ArrayList] $HHistory  # hidden states over time

    BasicRNNCell([int]$inputSize, [int]$hiddenSize) {
        $this.InputSize  = $inputSize
        $this.HiddenSize = $hiddenSize
        $this.Wxh = New-RNNWeights -rows $hiddenSize -cols $inputSize  -seed 42
        $this.Whh = New-RNNWeights -rows $hiddenSize -cols $hiddenSize -seed 43
        $this.Bh  = @(0.0) * $hiddenSize
        $this.H   = @(0.0) * $hiddenSize
        $this.HHistory = [System.Collections.ArrayList]::new()
    }

    [void] Reset() {
        $this.H = @(0.0) * $this.HiddenSize
        $this.HHistory.Clear()
    }

    # One step forward
    [double[]] Step([double[]]$x) {
        $xh   = MatVec $this.Wxh $x  $this.HiddenSize $this.InputSize
        $hh   = MatVec $this.Whh $this.H $this.HiddenSize $this.HiddenSize
        $preact = Add-Vectors (Add-Vectors $xh $hh) $this.Bh
        $this.H = Invoke-RNNTanh $preact
        $this.HHistory.Add($this.H.Clone()) | Out-Null
        return $this.H
    }

    # Process full sequence, return all hidden states
    [double[][]] Forward([double[][]]$sequence) {
        $this.Reset()
        $outputs = @()
        foreach ($x in $sequence) {
            $stepOut = $this.Step($x)
            $outputs += ,$stepOut
        }
        return $outputs
    }

    [void] PrintSummary() {
        Write-Host ""
        Write-Host "╔══════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║         Basic RNN Cell               ║" -ForegroundColor Cyan
        Write-Host "╠══════════════════════════════════════╣" -ForegroundColor Cyan
        Write-Host ("║  Input size  : {0,-22}║" -f $this.InputSize)  -ForegroundColor White
        Write-Host ("║  Hidden size : {0,-22}║" -f $this.HiddenSize) -ForegroundColor White
        $params = $this.HiddenSize * $this.InputSize + $this.HiddenSize * $this.HiddenSize + $this.HiddenSize
        Write-Host ("║  Parameters  : {0,-22}║" -f $params)          -ForegroundColor Yellow
        Write-Host ("║  Equation    : h=tanh(Wx+Uh+b){0,-8}║" -f "") -ForegroundColor DarkGray
        Write-Host "╚══════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
    }
}

# ============================================================
# LSTM CELL
# ============================================================
# TEACHING NOTE: LSTM solves the vanishing gradient problem!
# Key idea: a CELL STATE (c_t) acts as a "conveyor belt"
# carrying information through time with minimal modification.
#
# Three GATES control information flow:
#
#   FORGET GATE:  f_t = sigmoid(W_f * [h_{t-1}, x_t] + b_f)
#   "How much of the old cell state do we keep?"
#   f_t=0 : forget everything, f_t=1 : keep everything
#
#   INPUT GATE:   i_t = sigmoid(W_i * [h_{t-1}, x_t] + b_i)
#   g_t   = tanh(W_g * [h_{t-1}, x_t] + b_g)
#   "What new information do we store in the cell state?"
#
#   OUTPUT GATE:  o_t = sigmoid(W_o * [h_{t-1}, x_t] + b_o)
#   "What do we output based on the cell state?"
#
#   CELL UPDATE:  c_t = f_t * c_{t-1} + i_t * g_t
#   HIDDEN STATE: h_t = o_t * tanh(c_t)
#
# The cell state highway lets gradients flow without vanishing!
# ============================================================

class LSTMCell {
    [int]      $InputSize
    [int]      $HiddenSize
    # Gate weights [hidden+input] -> hidden
    [double[]] $Wf   # forget gate
    [double[]] $Wi   # input gate
    [double[]] $Wg   # cell gate (candidate)
    [double[]] $Wo   # output gate
    [double[]] $Bf   # forget bias
    [double[]] $Bi   # input bias
    [double[]] $Bg   # cell bias
    [double[]] $Bo   # output bias
    [double[]] $H    # hidden state
    [double[]] $C    # cell state
    [System.Collections.ArrayList] $HHistory
    [System.Collections.ArrayList] $CHistory

    LSTMCell([int]$inputSize, [int]$hiddenSize) {
        $this.InputSize  = $inputSize
        $this.HiddenSize = $hiddenSize
        $combined        = $inputSize + $hiddenSize

        # Each gate: (hidden+input) -> hidden
        $this.Wf = New-RNNWeights -rows $hiddenSize -cols $combined -seed 10
        $this.Wi = New-RNNWeights -rows $hiddenSize -cols $combined -seed 11
        $this.Wg = New-RNNWeights -rows $hiddenSize -cols $combined -seed 12
        $this.Wo = New-RNNWeights -rows $hiddenSize -cols $combined -seed 13
        $this.Bf = @(1.0) * $hiddenSize  # forget bias=1 helps remember by default
        $this.Bi = @(0.0) * $hiddenSize
        $this.Bg = @(0.0) * $hiddenSize
        $this.Bo = @(0.0) * $hiddenSize
        $this.H  = @(0.0) * $hiddenSize
        $this.C  = @(0.0) * $hiddenSize
        $this.HHistory = [System.Collections.ArrayList]::new()
        $this.CHistory = [System.Collections.ArrayList]::new()
    }

    [void] Reset() {
        $this.H = @(0.0) * $this.HiddenSize
        $this.C = @(0.0) * $this.HiddenSize
        $this.HHistory.Clear()
        $this.CHistory.Clear()
    }

    [double[]] Step([double[]]$x) {
        # Concatenate [h_{t-1}, x_t]
        $combined = $this.HiddenSize + $this.InputSize
        $hx = @(0.0) * $combined
        for ($i = 0; $i -lt $this.HiddenSize; $i++) { $hx[$i] = $this.H[$i] }
        for ($i = 0; $i -lt $this.InputSize;  $i++) { $hx[$this.HiddenSize + $i] = $x[$i] }

        # Gates
        $fRaw = Add-Vectors (MatVec $this.Wf $hx $this.HiddenSize $combined) $this.Bf
        $iRaw = Add-Vectors (MatVec $this.Wi $hx $this.HiddenSize $combined) $this.Bi
        $gRaw = Add-Vectors (MatVec $this.Wg $hx $this.HiddenSize $combined) $this.Bg
        $oRaw = Add-Vectors (MatVec $this.Wo $hx $this.HiddenSize $combined) $this.Bo

        $f = Invoke-RNNSigmoid $fRaw  # forget gate
        $i = Invoke-RNNSigmoid $iRaw  # input gate
        $g = Invoke-RNNTanh    $gRaw  # candidate cell
        $o = Invoke-RNNSigmoid $oRaw  # output gate

        # Cell state update: c_t = f * c_{t-1} + i * g
        $this.C = Add-Vectors (Mul-Vectors $f $this.C) (Mul-Vectors $i $g)
        # Hidden state: h_t = o * tanh(c_t)
        $this.H = Mul-Vectors $o (Invoke-RNNTanh $this.C)

        $this.HHistory.Add($this.H.Clone()) | Out-Null
        $this.CHistory.Add($this.C.Clone()) | Out-Null
        return $this.H
    }

    [double[][]] Forward([double[][]]$sequence) {
        $this.Reset()
        $outputs = @()
        foreach ($x in $sequence) {
            $stepOut = $this.Step($x)
            $outputs += ,$stepOut
        }
        return $outputs
    }

    [void] PrintSummary() {
        Write-Host ""
        Write-Host "╔══════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║            LSTM Cell                 ║" -ForegroundColor Cyan
        Write-Host "╠══════════════════════════════════════╣" -ForegroundColor Cyan
        Write-Host ("║  Input size  : {0,-22}║" -f $this.InputSize)  -ForegroundColor White
        Write-Host ("║  Hidden size : {0,-22}║" -f $this.HiddenSize) -ForegroundColor White
        $combined = $this.InputSize + $this.HiddenSize
        $params   = 4 * ($this.HiddenSize * $combined + $this.HiddenSize)
        Write-Host ("║  Parameters  : {0,-22}║" -f $params)          -ForegroundColor Yellow
        Write-Host ("║  Gates       : forget,input,cell,out{0,-1}║" -f "") -ForegroundColor DarkGray
        Write-Host ("║  Cell state  : long-term memory{0,-6}║" -f "") -ForegroundColor DarkGray
        Write-Host "╚══════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
    }

    [void] PrintGateActivity([int]$step) {
        if ($step -ge $this.HHistory.Count) { Write-Host "Step out of range" -ForegroundColor Red; return }
        $hState = $this.HHistory[$step]
        $cState = $this.CHistory[$step]
        Write-Host ""
        Write-Host ("🔦 LSTM Gate Activity at step {0}:" -f $step) -ForegroundColor Green
        Write-Host "   Hidden state (h):" -ForegroundColor Cyan -NoNewline
        for ($i = 0; $i -lt [Math]::Min(8, $hState.Length); $i++) {
            $bar = if ($hState[$i] -gt 0) { "+" } else { "-" }
            Write-Host (" {0}{1:F2}" -f $bar, [Math]::Abs($hState[$i])) -ForegroundColor White -NoNewline
        }
        Write-Host ""
        Write-Host "   Cell state  (c):" -ForegroundColor Cyan -NoNewline
        for ($i = 0; $i -lt [Math]::Min(8, $cState.Length); $i++) {
            $bar = if ($cState[$i] -gt 0) { "+" } else { "-" }
            Write-Host (" {0}{1:F2}" -f $bar, [Math]::Abs($cState[$i])) -ForegroundColor Yellow -NoNewline
        }
        Write-Host ""
        Write-Host ""
    }
}

# ============================================================
# GRU CELL
# ============================================================
# TEACHING NOTE: GRU = Gated Recurrent Unit (2014)
# Simpler than LSTM - only 2 gates, no separate cell state.
# Often performs as well as LSTM with fewer parameters!
#
#   RESET GATE:  r_t = sigmoid(W_r * [h_{t-1}, x_t])
#   "How much of past hidden state do we use?"
#   r_t=0 : ignore past completely (start fresh)
#
#   UPDATE GATE: z_t = sigmoid(W_z * [h_{t-1}, x_t])
#   "How much do we update the hidden state?"
#   z_t=0 : keep old state, z_t=1 : use new candidate
#
#   CANDIDATE:   h~_t = tanh(W * [r_t * h_{t-1}, x_t])
#   HIDDEN:      h_t = (1-z_t) * h_{t-1} + z_t * h~_t
#
# GRU vs LSTM:
#   LSTM: 4 weight matrices, separate cell state
#   GRU : 3 weight matrices, single hidden state
#   Rule of thumb: try GRU first, use LSTM if more memory needed
# ============================================================

class GRUCell {
    [int]      $InputSize
    [int]      $HiddenSize
    [double[]] $Wr    # reset gate
    [double[]] $Wz    # update gate
    [double[]] $Wh    # candidate hidden
    [double[]] $Br
    [double[]] $Bz
    [double[]] $Bh
    [double[]] $H
    [System.Collections.ArrayList] $HHistory

    GRUCell([int]$inputSize, [int]$hiddenSize) {
        $this.InputSize  = $inputSize
        $this.HiddenSize = $hiddenSize
        $combined        = $inputSize + $hiddenSize

        $this.Wr = New-RNNWeights -rows $hiddenSize -cols $combined -seed 20
        $this.Wz = New-RNNWeights -rows $hiddenSize -cols $combined -seed 21
        $this.Wh = New-RNNWeights -rows $hiddenSize -cols $combined -seed 22
        $this.Br = @(0.0) * $hiddenSize
        $this.Bz = @(0.0) * $hiddenSize
        $this.Bh = @(0.0) * $hiddenSize
        $this.H  = @(0.0) * $hiddenSize
        $this.HHistory = [System.Collections.ArrayList]::new()
    }

    [void] Reset() {
        $this.H = @(0.0) * $this.HiddenSize
        $this.HHistory.Clear()
    }

    [double[]] Step([double[]]$x) {
        $combined = $this.HiddenSize + $this.InputSize
        # Concatenate [h, x]
        $hx = @(0.0) * $combined
        for ($i = 0; $i -lt $this.HiddenSize; $i++) { $hx[$i] = $this.H[$i] }
        for ($i = 0; $i -lt $this.InputSize;  $i++) { $hx[$this.HiddenSize + $i] = $x[$i] }

        # Reset and update gates
        $r = Invoke-RNNSigmoid (Add-Vectors (MatVec $this.Wr $hx $this.HiddenSize $combined) $this.Br)
        $z = Invoke-RNNSigmoid (Add-Vectors (MatVec $this.Wz $hx $this.HiddenSize $combined) $this.Bz)

        # Candidate: [r * h, x]
        $rh = Mul-Vectors $r $this.H
        $rhx = @(0.0) * $combined
        for ($i = 0; $i -lt $this.HiddenSize; $i++) { $rhx[$i] = $rh[$i] }
        for ($i = 0; $i -lt $this.InputSize;  $i++) { $rhx[$this.HiddenSize + $i] = $x[$i] }
        $hCand = Invoke-RNNTanh (Add-Vectors (MatVec $this.Wh $rhx $this.HiddenSize $combined) $this.Bh)

        # Update: h_t = (1-z)*h + z*h_cand
        $newH = @(0.0) * $this.HiddenSize
        for ($i = 0; $i -lt $this.HiddenSize; $i++) {
            $newH[$i] = (1 - $z[$i]) * $this.H[$i] + $z[$i] * $hCand[$i]
        }
        $this.H = $newH
        $this.HHistory.Add($this.H.Clone()) | Out-Null
        return $this.H
    }

    [double[][]] Forward([double[][]]$sequence) {
        $this.Reset()
        $outputs = @()
        foreach ($x in $sequence) { $outputs += ,$this.Step($x) }
        return $outputs
    }

    [void] PrintSummary() {
        Write-Host ""
        Write-Host "╔══════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║             GRU Cell                 ║" -ForegroundColor Cyan
        Write-Host "╠══════════════════════════════════════╣" -ForegroundColor Cyan
        Write-Host ("║  Input size  : {0,-22}║" -f $this.InputSize)  -ForegroundColor White
        Write-Host ("║  Hidden size : {0,-22}║" -f $this.HiddenSize) -ForegroundColor White
        $combined = $this.InputSize + $this.HiddenSize
        $params   = 3 * ($this.HiddenSize * $combined + $this.HiddenSize)
        Write-Host ("║  Parameters  : {0,-22}║" -f $params)          -ForegroundColor Yellow
        Write-Host ("║  Gates       : reset, update{0,-9}║" -f "")   -ForegroundColor DarkGray
        Write-Host ("║  vs LSTM     : 25% fewer params{0,-5}║" -f "") -ForegroundColor Green
        Write-Host "╚══════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
    }
}

# ============================================================
# BIDIRECTIONAL RNN WRAPPER
# ============================================================
# TEACHING NOTE: Standard RNN only sees the PAST.
# Bidirectional processes the sequence BOTH ways:
#   Forward  pass: x_1 -> x_2 -> x_3 ... x_T
#   Backward pass: x_T -> x_{T-1} ... x_1
# Then concatenates both hidden states at each timestep.
#
# Why? Some tasks need future context too!
# "The bank was steep" vs "The bank was closed"
# The word "bank" meaning depends on what comes AFTER it!
# ============================================================

class BidirectionalRNN {
    [object] $ForwardCell
    [object] $BackwardCell
    [string] $CellType     # "RNN", "LSTM", "GRU"
    [int]    $InputSize
    [int]    $HiddenSize

    BidirectionalRNN([string]$cellType, [int]$inputSize, [int]$hiddenSize) {
        $this.CellType   = $cellType
        $this.InputSize  = $inputSize
        $this.HiddenSize = $hiddenSize

        switch ($cellType) {
            "LSTM" {
                $this.ForwardCell  = [LSTMCell]::new($inputSize, $hiddenSize)
                $this.BackwardCell = [LSTMCell]::new($inputSize, $hiddenSize)
            }
            "GRU" {
                $this.ForwardCell  = [GRUCell]::new($inputSize, $hiddenSize)
                $this.BackwardCell = [GRUCell]::new($inputSize, $hiddenSize)
            }
            default {
                $this.ForwardCell  = [BasicRNNCell]::new($inputSize, $hiddenSize)
                $this.BackwardCell = [BasicRNNCell]::new($inputSize, $hiddenSize)
            }
        }
    }

    # Returns concatenated [forward, backward] at each timestep
    [double[][]] Forward([double[][]]$sequence) {
        $n = $sequence.Length

        # Forward pass
        $fwdOutputs = $this.ForwardCell.Forward($sequence)

        # Backward pass (reverse sequence)
        $revSeq = @()
        for ($i = $n-1; $i -ge 0; $i--) { $revSeq += ,$sequence[$i] }
        $bwdOutputsRev = $this.BackwardCell.Forward($revSeq)

        # Reverse backward outputs to align with original positions
        $bwdOutputs = @()
        for ($i = $n-1; $i -ge 0; $i--) { $bwdOutputs += ,$bwdOutputsRev[$i] }

        # Concatenate at each position
        $combined = @()
        for ($i = 0; $i -lt $n; $i++) {
            $fwd  = $fwdOutputs[$i]
            $bwd  = $bwdOutputs[$i]
            $cat  = @(0.0) * ($fwd.Length + $bwd.Length)
            for ($j = 0; $j -lt $fwd.Length; $j++) { $cat[$j] = $fwd[$j] }
            for ($j = 0; $j -lt $bwd.Length; $j++) { $cat[$fwd.Length + $j] = $bwd[$j] }
            $combined += ,$cat
        }
        return $combined
    }

    [void] PrintSummary() {
        Write-Host ""
        Write-Host "╔══════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║       Bidirectional RNN              ║" -ForegroundColor Cyan
        Write-Host "╠══════════════════════════════════════╣" -ForegroundColor Cyan
        Write-Host ("║  Cell type   : {0,-22}║" -f $this.CellType)          -ForegroundColor White
        Write-Host ("║  Input size  : {0,-22}║" -f $this.InputSize)         -ForegroundColor White
        Write-Host ("║  Hidden size : {0,-22}║" -f $this.HiddenSize)        -ForegroundColor White
        Write-Host ("║  Output size : {0,-22}║" -f ($this.HiddenSize * 2))  -ForegroundColor Yellow
        Write-Host ("║  Direction   : forward + backward{0,-3}║" -f "")     -ForegroundColor DarkGray
        Write-Host "╚══════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
    }
}

# ============================================================
# ATTENTION MECHANISM
# ============================================================
# TEACHING NOTE: Attention = "Where should I look?"
# Instead of compressing the WHOLE sequence into one vector,
# attention lets the model focus on RELEVANT parts.
#
# For each output step, compute a weight for each input step:
#   score(q, k) = q · k  (dot product attention)
#   weights = softmax(scores)
#   context = sum(weights * values)
#
# Q = Query  : what we're looking for
# K = Keys   : what each encoder step "offers"
# V = Values : what we actually read when we attend
#
# This is the foundation of TRANSFORMERS!
# "Attention is All You Need" (2017) revolutionized NLP.
# ============================================================

class DotProductAttention {
    [double[]] $AttentionWeights  # last computed weights

    DotProductAttention() {}

    # query: (d,)  keys: (T, d)  values: (T, dv)
    [double[]] Forward([double[]]$query, [double[][]]$keys, [double[][]]$values) {
        $T = $keys.Length
        $d = $query.Length

        # Score = query · key_t for each t
        $scores = @(0.0) * $T
        for ($t = 0; $t -lt $T; $t++) {
            $dot = 0.0
            for ($i = 0; $i -lt $d; $i++) { $dot += $query[$i] * $keys[$t][$i] }
            $scores[$t] = $dot / [Math]::Sqrt($d)  # scale by sqrt(d)
        }

        # Attention weights = softmax(scores)
        $this.AttentionWeights = Invoke-RNNSoftmax $scores

        # Context = weighted sum of values
        $dv      = $values[0].Length
        $context = @(0.0) * $dv
        for ($t = 0; $t -lt $T; $t++) {
            for ($i = 0; $i -lt $dv; $i++) {
                $context[$i] += $this.AttentionWeights[$t] * $values[$t][$i]
            }
        }
        return $context
    }

    [void] PrintAttentionMap([string[]]$tokens) {
        Write-Host ""
        Write-Host "🔍 Attention Weights:" -ForegroundColor Green
        $bars = "░▒▓█"
        for ($t = 0; $t -lt $this.AttentionWeights.Length; $t++) {
            $w     = $this.AttentionWeights[$t]
            $barN  = [int]($w * 20)
            $bar   = "█" * $barN
            $tok   = if ($t -lt $tokens.Length) { $tokens[$t] } else { "t$t" }
            $color = if ($w -gt 0.3) { "Green" } elseif ($w -gt 0.1) { "Yellow" } else { "DarkGray" }
            Write-Host ("  {0,-12} {1,6:F4}  {2}" -f $tok, $w, $bar) -ForegroundColor $color
        }
        Write-Host ""
    }
}

# ============================================================
# SEQ2SEQ MODEL (Encoder-Decoder)
# ============================================================
# TEACHING NOTE: Seq2Seq translates one sequence to another.
# Examples: English -> French, Question -> Answer
#
# ENCODER: reads the input sequence, produces a context vector
#   "Summarise the input into a fixed-size memory"
#
# DECODER: generates the output sequence from context
#   "Expand the memory into the output sequence"
#
# TEACHER FORCING: during training, feed the CORRECT previous
# output as the next decoder input (not the predicted one).
# This speeds up training but can cause "exposure bias" at test.
# ============================================================

class Seq2SeqModel {
    [LSTMCell] $Encoder
    [LSTMCell] $Decoder
    [double[]] $Wy       # decoder hidden -> output
    [double[]] $By       # output bias
    [int]      $OutputSize
    [DotProductAttention] $Attention

    Seq2SeqModel([int]$inputSize, [int]$hiddenSize, [int]$outputSize) {
        $this.Encoder    = [LSTMCell]::new($inputSize,  $hiddenSize)
        $this.Decoder    = [LSTMCell]::new($outputSize, $hiddenSize)
        $this.Wy         = New-RNNWeights -rows $outputSize -cols $hiddenSize -seed 99
        $this.By         = @(0.0) * $outputSize
        $this.OutputSize = $outputSize
        $this.Attention  = [DotProductAttention]::new()
    }

    # Encode input sequence -> final hidden state
    [hashtable] Encode([double[][]]$inputSeq) {
        $this.Encoder.Reset()
        foreach ($x in $inputSeq) { $this.Encoder.Step($x) | Out-Null }
        return @{ H=$this.Encoder.H.Clone(); C=$this.Encoder.C.Clone() }
    }

    # Decode: generate output sequence of given length
    [double[][]] Decode([hashtable]$context, [int]$outputLen) {
        # Initialize decoder with encoder final state
        $this.Decoder.H = $context.H
        $this.Decoder.C = $context.C

        $outputs = @()
        $input   = @(0.0) * $this.OutputSize  # start token = zeros

        for ($t = 0; $t -lt $outputLen; $t++) {
            $decOut = $this.Decoder.Step($input)
            $out = Add-Vectors (MatVec $this.Wy $decOut $this.OutputSize $this.Decoder.HiddenSize) $this.By
            $prob = Invoke-RNNSoftmax $out
            $outputs += ,$prob
            $input = $prob  # feed output as next input (no teacher forcing at inference)
        }
        return $outputs
    }

    [void] PrintSummary() {
        Write-Host ""
        Write-Host "╔══════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║        Seq2Seq Model                 ║" -ForegroundColor Cyan
        Write-Host "╠══════════════════════════════════════╣" -ForegroundColor Cyan
        Write-Host ("║  Encoder     : LSTM({0}->{1}){2,-12}║" -f $this.Encoder.InputSize, $this.Encoder.HiddenSize, "") -ForegroundColor White
        Write-Host ("║  Decoder     : LSTM({0}->{1}){2,-12}║" -f $this.Decoder.InputSize, $this.Decoder.HiddenSize, "") -ForegroundColor White
        Write-Host ("║  Output size : {0,-22}║" -f $this.OutputSize) -ForegroundColor White
        Write-Host ("║  Attention   : DotProduct{0,-12}║" -f "")     -ForegroundColor Yellow
        Write-Host "╚══════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
    }
}

# ============================================================
# OUTPUT LAYER FOR SEQUENCE CLASSIFICATION/REGRESSION
# ============================================================

class RNNOutputLayer {
    [double[]] $W
    [double[]] $B
    [int]      $InputSize
    [int]      $OutputSize
    [string]   $Activation

    RNNOutputLayer([int]$inputSize, [int]$outputSize, [string]$activation) {
        $this.InputSize  = $inputSize
        $this.OutputSize = $outputSize
        $this.Activation = $activation
        $this.W = New-RNNWeights -rows $outputSize -cols $inputSize -seed 77
        $this.B = @(0.0) * $outputSize
    }

    [double[]] Forward([double[]]$h) {
        $raw = Add-Vectors (MatVec $this.W $h $this.OutputSize $this.InputSize) $this.B
        $out = switch ($this.Activation) {
            "softmax" { Invoke-RNNSoftmax $raw }
            "sigmoid" { Invoke-RNNSigmoid $raw }
            "tanh"    { Invoke-RNNTanh    $raw }
            default   { $raw }
        }
        return $out
    }
}

# ============================================================
# BUILT-IN DATASETS
# ============================================================

function Get-VBAFSequenceDataset {
    param([string]$Name = "SineWave")

    $rng = [System.Random]::new(42)

    switch ($Name) {
        "SineWave" {
            Write-Host "📊 Dataset: SineWave (predict next value)" -ForegroundColor Cyan
            Write-Host "   Task: given 10 values, predict the 11th" -ForegroundColor Cyan

            $n        = 200
            $seqLen   = 10
            $step     = 0.1
            $values   = @()
            for ($i = 0; $i -lt ($n + $seqLen + 1); $i++) {
                $values += [Math]::Sin($i * $step) + ($rng.NextDouble() - 0.5) * 0.1
            }

            $sequences = @(); $targets = @()
            for ($i = 0; $i -lt $n; $i++) {
                $seq = @()
                for ($j = 0; $j -lt $seqLen; $j++) {
                    $seq += ,@($values[$i + $j])  # single feature
                }
                $sequences += ,$seq
                $targets   += $values[$i + $seqLen]
            }
            return @{ Sequences=$sequences; Targets=$targets; SeqLen=$seqLen; InputSize=1; Task="regression" }
        }
        "BinaryAdd" {
            Write-Host "📊 Dataset: BinaryAdd (seq2seq)" -ForegroundColor Cyan
            Write-Host "   Task: add two 4-bit binary numbers -> 5-bit result" -ForegroundColor Cyan

            $seqs   = @(); $targets = @()
            for ($i = 0; $i -lt 50; $i++) {
                $a  = $rng.Next(0, 16)
                $b  = $rng.Next(0, 16)
                $cSum = $a + $b
                # Encode as bit sequences (LSB first)
                $aSeq = @(); $bSeq = @(); $cSeq = @()
                for ($bit = 0; $bit -lt 4; $bit++) {
                    $aSeq += ,@([double](($a -shr $bit) -band 1), [double](($b -shr $bit) -band 1))
                }
                for ($bit = 0; $bit -lt 5; $bit++) {
                    $cSeq += ,@([double](($cSum -shr $bit) -band 1))
                }
                $seqs   += ,$aSeq
                $targets += ,$cSeq
            }
            return @{ Sequences=$seqs; Targets=$targets; SeqLen=4; InputSize=2; Task="seq2seq" }
        }
        "SentimentWords" {
            Write-Host "📊 Dataset: SentimentWords (sequence classification)" -ForegroundColor Cyan
            Write-Host "   Task: classify word sequence as positive/negative" -ForegroundColor Cyan

            # Simple word embeddings (2D for teaching)
            $vocab = @{
                "good"=@(0.8,0.2); "great"=@(0.9,0.1); "excellent"=@(1.0,0.0)
                "happy"=@(0.7,0.3); "love"=@(0.85,0.15); "wonderful"=@(0.95,0.05)
                "bad"=@(0.1,0.9);   "terrible"=@(0.0,1.0); "awful"=@(0.05,0.95)
                "sad"=@(0.2,0.8);   "hate"=@(0.1,0.9);  "horrible"=@(0.0,0.95)
                "movie"=@(0.5,0.5); "film"=@(0.5,0.5);  "was"=@(0.5,0.5)
            }

            $posSentences = @(
                @("the","movie","was","great"),
                @("wonderful","film"),
                @("great","excellent","good"),
                @("love","this","film"),
                @("happy","wonderful","movie")
            )
            $negSentences = @(
                @("the","movie","was","terrible"),
                @("horrible","film"),
                @("bad","awful","sad"),
                @("hate","this","film"),
                @("sad","terrible","movie")
            )

            $seqs = @(); $labels = @()
            foreach ($sent in $posSentences) {
                $seq = @()
                foreach ($w in $sent) {
                    $emb = if ($vocab.ContainsKey($w)) { $vocab[$w] } else { @(0.5, 0.5) }
                    $seq += ,@($emb[0], $emb[1])
                }
                $seqs  += ,$seq
                $labels += 1  # positive
            }
            foreach ($sent in $negSentences) {
                $seq = @()
                foreach ($w in $sent) {
                    $emb = if ($vocab.ContainsKey($w)) { $vocab[$w] } else { @(0.5, 0.5) }
                    $seq += ,@($emb[0], $emb[1])
                }
                $seqs  += ,$seq
                $labels += 0  # negative
            }
            return @{ Sequences=$seqs; Labels=$labels; InputSize=2; Task="classification" }
        }
        default {
            Write-Host "❌ Unknown: $Name" -ForegroundColor Red
            Write-Host "   Available: SineWave, BinaryAdd, SentimentWords" -ForegroundColor Yellow
            return $null
        }
    }
}

# ============================================================
# ARCHITECTURE COMPARISON UTILITY
# ============================================================

function Compare-RNNArchitectures {
    param([double[][]]$sequence)

    $n = $sequence.Length
    Write-Host ""
    Write-Host "⚖️  RNN Architecture Comparison" -ForegroundColor Green
    Write-Host ("   Sequence length : {0}" -f $n)      -ForegroundColor Cyan
    Write-Host ("   Input size      : {0}" -f $sequence[0].Length) -ForegroundColor Cyan
    Write-Host ""

    $hiddenSize = 8
    $inputSize  = $sequence[0].Length

    # BasicRNN
    $rnn     = [BasicRNNCell]::new($inputSize, $hiddenSize)
    $rnnOut  = $rnn.Forward($sequence)
    $rnnParams = $hiddenSize * $inputSize + $hiddenSize * $hiddenSize + $hiddenSize

    # LSTM
    $lstm    = [LSTMCell]::new($inputSize, $hiddenSize)
    $lstmOut = $lstm.Forward($sequence)
    $combined = $inputSize + $hiddenSize
    $lstmParams = 4 * ($hiddenSize * $combined + $hiddenSize)

    # GRU
    $gru     = [GRUCell]::new($inputSize, $hiddenSize)
    $gruOut  = $gru.Forward($sequence)
    $gruParams = 3 * ($hiddenSize * $combined + $hiddenSize)

    # Bidirectional LSTM
    $biLSTM  = [BidirectionalRNN]::new("LSTM", $inputSize, $hiddenSize)
    $biOut   = $biLSTM.Forward($sequence)

    Write-Host ("  {0,-20} {1,8} {2,12} {3,10}" -f "Architecture", "Params", "Output Size", "Memory") -ForegroundColor Yellow
    Write-Host ("  {0}" -f ("-" * 55)) -ForegroundColor DarkGray
    Write-Host ("  {0,-20} {1,8} {2,12} {3,10}" -f "BasicRNN",      $rnnParams,       $hiddenSize,       "Short") -ForegroundColor White
    Write-Host ("  {0,-20} {1,8} {2,12} {3,10}" -f "LSTM",          $lstmParams,      $hiddenSize,       "Long")  -ForegroundColor Green
    Write-Host ("  {0,-20} {1,8} {2,12} {3,10}" -f "GRU",           $gruParams,       $hiddenSize,       "Medium") -ForegroundColor Cyan
    Write-Host ("  {0,-20} {1,8} {2,12} {3,10}" -f "Bidirect-LSTM", ($lstmParams * 2), ($hiddenSize * 2), "Long+Context") -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  💡 Rule of thumb:" -ForegroundColor DarkGray
    Write-Host "     Short sequences  -> BasicRNN or GRU" -ForegroundColor DarkGray
    Write-Host "     Long sequences   -> LSTM" -ForegroundColor DarkGray
    Write-Host "     Need context     -> Bidirectional" -ForegroundColor DarkGray
    Write-Host "     Seq translation  -> Seq2Seq + Attention" -ForegroundColor DarkGray
    Write-Host ""
}

# ============================================================
# TEST
# 1. Run VBAF.LoadAll.ps1
#
# --- BasicRNN forward pass ---
# 2. $rnn  = [BasicRNNCell]::new(1, 8)
#    $rnn.PrintSummary()
#    $data  = Get-VBAFSequenceDataset -Name "SineWave"
#    $out   = $rnn.Forward($data.Sequences[0])
#    Write-Host "Processed $($data.Sequences[0].Length) steps, output size: $($out[0].Length)"
#
# --- LSTM forward pass ---
# 3. $lstm = [LSTMCell]::new(1, 8)
#    $lstm.PrintSummary()
#    $out2  = $lstm.Forward($data.Sequences[0])
#    $lstm.PrintGateActivity(5)  # show gates at step 5
#
# --- GRU forward pass ---
# 4. $gru  = [GRUCell]::new(1, 8)
#    $gru.PrintSummary()
#    $out3  = $gru.Forward($data.Sequences[0])
#
# --- Bidirectional ---
# 5. $bi   = [BidirectionalRNN]::new("LSTM", 1, 8)
#    $bi.PrintSummary()
#    $biOut = $bi.Forward($data.Sequences[0])
#    Write-Host "Bidirectional output size: $($biOut[0].Length)  (should be 16 = 8*2)"
#
# --- Attention ---
# 6. $attn  = [DotProductAttention]::new()
#    $keys   = $out2   # LSTM hidden states as keys
#    $query  = $out2[-1]  # last hidden state as query
#    $context = $attn.Forward($query, $keys, $keys)
#    $attn.PrintAttentionMap(@("t0","t1","t2","t3","t4","t5","t6","t7","t8","t9"))
#
# --- Architecture comparison ---
# 7. Compare-RNNArchitectures -sequence $data.Sequences[0]
#
# --- Seq2Seq ---
# 8. $s2s   = [Seq2SeqModel]::new(2, 8, 1)
#    $s2s.PrintSummary()
#    $binData = Get-VBAFSequenceDataset -Name "BinaryAdd"
#    $ctx     = $s2s.Encode($binData.Sequences[0])
#    $decoded = $s2s.Decode($ctx, 5)
#    Write-Host "Encoded and decoded binary addition sequence"
#
# --- Sentiment classification ---
# 9. $sentData = Get-VBAFSequenceDataset -Name "SentimentWords"
#    $lstm2 = [LSTMCell]::new(2, 8)
#    $outLayer = [RNNOutputLayer]::new(8, 2, "softmax")
#    $correct = 0
#    for ($i = 0; $i -lt $sentData.Sequences.Length; $i++) {
#        $hiddens = $lstm2.Forward($sentData.Sequences[$i])
#        $probs   = $outLayer.Forward($hiddens[-1])
#        $pred    = if ($probs[0] -gt $probs[1]) { 0 } else { 1 }
#        if ($pred -eq $sentData.Labels[$i]) { $correct++ }
#    }
#    Write-Host "Sentiment accuracy (untrained): $correct / $($sentData.Sequences.Length)"
# ============================================================
Write-Host "📦 VBAF.ML.RNN.ps1 loaded  [Phase 6 🧠]" -ForegroundColor Green
Write-Host "   Classes   : BasicRNNCell"               -ForegroundColor Cyan
Write-Host "              LSTMCell"                    -ForegroundColor Cyan
Write-Host "              GRUCell"                     -ForegroundColor Cyan
Write-Host "              BidirectionalRNN"            -ForegroundColor Cyan
Write-Host "              DotProductAttention"         -ForegroundColor Cyan
Write-Host "              Seq2SeqModel"                -ForegroundColor Cyan
Write-Host "              RNNOutputLayer"              -ForegroundColor Cyan
Write-Host "   Functions : Compare-RNNArchitectures"  -ForegroundColor Cyan
Write-Host "              Get-VBAFSequenceDataset"     -ForegroundColor Cyan
Write-Host "              Invoke-GradientClip"         -ForegroundColor Cyan
Write-Host ""
Write-Host "   Quick start:" -ForegroundColor Yellow
Write-Host '   $lstm = [LSTMCell]::new(1, 8)'                       -ForegroundColor White
Write-Host '   $lstm.PrintSummary()'                                 -ForegroundColor White
Write-Host '   $data = Get-VBAFSequenceDataset -Name "SineWave"'    -ForegroundColor White
Write-Host '   $out  = $lstm.Forward($data.Sequences[0])'           -ForegroundColor White
Write-Host '   Write-Host "Steps: $($out.Length)  Hidden: $($out[0].Length)"' -ForegroundColor White
Write-Host ""