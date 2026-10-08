#Requires -Version 5.1
<#
.SYNOPSIS
    VBAF 6.1 -- the "battery": an optional C# engine for NeuralNetwork, compiled in memory with Add-Type.
.DESCRIPTION
    No external dependencies: Add-Type uses the C# compiler that ships with .NET Framework 4.x on every Windows.
    The engine computes Forward, Predict and TrainSample in EXACTLY the order of VBAF.Core.AllClasses.ps1, so the
    results are bit-identical to pure PowerShell (proven in VBAF-Evolution-Lab and locked by tests\Test-VBAF.ps1):
      weighted sum = bias first, then input x weight in rising index order; Sigmoid/Tanh with the kernel's +-500
      limits; backward from the output layer, each layer UPDATES its weights before the layer below reads them
      (kernel finding KF-12, reproduced on purpose); weight += (lr x delta) x input, then bias += lr x delta.

    HOW TO USE
      $global:VBAFNetEngine = 'PowerShell'   default: the readable kernel, nothing changes
      $global:VBAFNetEngine = 'Auto'         use the engine when it is available, otherwise pure PowerShell
      $global:VBAFNetEngine = 'Fast'         use the engine, and STOP with an error if it is not available
      Get-VBAFNetEngine                      shows the setting, whether the engine is available, and why not
    Networks are created through [VBAFNetworkFactory]::Create(...), which reads the setting.

    WHEN THE ENGINE IS NOT AVAILABLE
      Add-Type is only tried in FullLanguage mode (it is blocked in Constrained Language Mode), and inside
      try/catch (a policy may block the compiler). $global:VBAFFastEngineDisable = $true before loading simulates
      a blocked system (used by the test suite).

    ONE RULE FOR FastNeuralNetwork
      After the first Forward/Predict/TrainSample the engine holds the weights. Read and write them through
      ExportState/ImportState, not by editing Layers[..].Neurons[..].Weights directly.
#>

$VBAFFastSource = @"
using System;
namespace VBAFFast {
    public sealed class FastNet {
        public int[] Arch; public double LearningRate; int L; int[] Act;
        double[][][] W; double[][] B; double[][] Z; double[][] Y; double[][] D; double[][] In;
        public FastNet(int[] arch, double learningRate, string[] acts) {
            Arch = (int[])arch.Clone(); LearningRate = learningRate; L = arch.Length - 1;
            if (acts.Length != L) { throw new ArgumentException("one activation per layer"); }
            Act = new int[L]; W = new double[L][][]; B = new double[L][]; Z = new double[L][]; Y = new double[L][]; D = new double[L][]; In = new double[L][];
            for (int l = 0; l < L; l++) {
                switch (acts[l]) { case "Sigmoid": Act[l] = 0; break; case "ReLU": Act[l] = 1; break; case "Tanh": Act[l] = 2; break; case "Linear": Act[l] = 3; break; default: throw new ArgumentException("Unknown activation: " + acts[l]); }
                int n = arch[l + 1], m = arch[l];
                W[l] = new double[n][]; for (int j = 0; j < n; j++) { W[l][j] = new double[m]; }
                B[l] = new double[n]; Z[l] = new double[n]; Y[l] = new double[n]; D[l] = new double[n];
            }
        }
        public void SetNeuron(int l, int j, double[] w, double b) { if (w.Length != W[l][j].Length) { throw new ArgumentException("weight count"); } Array.Copy(w, W[l][j], w.Length); B[l][j] = b; }
        public double[] GetWeights(int l, int j) { return (double[])W[l][j].Clone(); }
        public double GetBias(int l, int j) { return B[l][j]; }
        static double F(int a, double x) {
            if (a == 0) { if (x < -500) return 0.0; if (x > 500) return 1.0; return 1.0 / (1.0 + Math.Exp(-x)); }
            if (a == 1) { if (x > 0) return x; return 0.0; }
            if (a == 2) { if (x < -500) return -1.0; if (x > 500) return 1.0; return Math.Tanh(x); }
            return x;
        }
        static double Fd(int a, double x) {
            if (a == 0) { double s = F(0, x); return s * (1.0 - s); }
            if (a == 1) { if (x > 0) return 1.0; return 0.0; }
            if (a == 2) { double t = Math.Tanh(x); return 1.0 - (t * t); }
            return 1.0;
        }
        public double[] Forward(double[] x) {
            double[] cur = x;
            for (int l = 0; l < L; l++) {
                In[l] = cur; double[] b = B[l]; double[][] w = W[l]; double[] z = Z[l]; double[] y = Y[l]; int n = b.Length, m = cur.Length;
                for (int j = 0; j < n; j++) { double sum = b[j]; double[] wj = w[j]; for (int i = 0; i < m; i++) { sum += cur[i] * wj[i]; } z[j] = sum; y[j] = F(Act[l], sum); }
                cur = y;
            }
            return cur;
        }
        public double[] Predict(double[] x) { return (double[])Forward(x).Clone(); }
        public double TrainSample(double[] x, double[] t) {
            double[] o = Forward(x); double loss = 0.0;
            for (int i = 0; i < o.Length; i++) { double diff = t[i] - o[i]; loss += diff * diff; }
            loss = loss / o.Length;
            int last = L - 1; double[] outD = new double[o.Length];
            for (int i = 0; i < o.Length; i++) { outD[i] = t[i] - o[i]; }
            for (int l = last; l >= 0; l--) {
                double[] d = D[l]; double[] z = Z[l]; int n = d.Length;
                if (l == last) { for (int i = 0; i < n; i++) { d[i] = outD[i] * Fd(Act[l], z[i]); } }
                else { double[] dn = D[l + 1]; double[][] wn = W[l + 1]; for (int i = 0; i < n; i++) { double sum = 0.0; for (int j = 0; j < dn.Length; j++) { double weight = wn[j][i]; sum += dn[j] * weight; } d[i] = sum * Fd(Act[l], z[i]); } }
                double[] inp = In[l]; double[][] w = W[l]; double[] b = B[l];
                for (int j = 0; j < n; j++) { double[] wj = w[j]; for (int i = 0; i < wj.Length; i++) { wj[i] += LearningRate * d[j] * inp[i]; } b[j] += LearningRate * d[j]; }
            }
            return loss;
        }
    }
}
"@

# ---------- is the engine available? ----------
$global:VBAFFastEngineAvailable = $false
$global:VBAFFastEngineReason    = ''
if ($global:VBAFFastEngineDisable) {
    $global:VBAFFastEngineReason = 'disabled by $global:VBAFFastEngineDisable'
} elseif ($ExecutionContext.SessionState.LanguageMode -ne 'FullLanguage') {
    $global:VBAFFastEngineReason = 'LanguageMode is ' + $ExecutionContext.SessionState.LanguageMode + ' (Add-Type needs FullLanguage)'
} else {
    try {
        if (-not ('VBAFFast.FastNet' -as [type])) { Add-Type -TypeDefinition $VBAFFastSource -Language CSharp -ErrorAction Stop }
        $global:VBAFFastEngineAvailable = $true
    } catch {
        $global:VBAFFastEngineReason = 'Add-Type failed: ' + $_.Exception.Message
    }
}
if ($null -eq $global:VBAFNetEngine) { $global:VBAFNetEngine = 'PowerShell' }

# ---------- FastNeuralNetwork: the kernel network, computed by the engine ----------
class FastNeuralNetwork : NeuralNetwork {
    hidden [object] $Engine
    hidden [bool]   $Dirty
    FastNeuralNetwork([int[]]$architecture, [double]$learningRate, [int]$seed) : base($architecture, $learningRate, $seed) { }
    FastNeuralNetwork([int[]]$architecture, [double]$learningRate) : base($architecture, $learningRate) { }
    hidden [void] BuildEngine() {
        if (-not $global:VBAFFastEngineAvailable) { throw ('FastNeuralNetwork: the C# engine is not available -- ' + $global:VBAFFastEngineReason) }
        $acts = [string[]]@($this.Layers | ForEach-Object { [string]$_.ActivationType })
        $e = ([type]'VBAFFast.FastNet')::new([int[]]$this.Architecture, [double]$this.LearningRate, $acts)
        for ($l = 0; $l -lt $this.Layers.Count; $l++) { for ($j = 0; $j -lt $this.Layers[$l].Size; $j++) { $n = $this.Layers[$l].Neurons[$j]; $e.SetNeuron($l, $j, [double[]]$n.Weights, [double]$n.Bias) } }
        $this.Engine = $e; $this.Dirty = $false
    }
    hidden [void] SyncToNeurons() {
        if ($null -eq $this.Engine -or -not $this.Dirty) { return }
        for ($l = 0; $l -lt $this.Layers.Count; $l++) { for ($j = 0; $j -lt $this.Layers[$l].Size; $j++) { $n = $this.Layers[$l].Neurons[$j]; $n.Weights = $this.Engine.GetWeights($l, $j); $n.Bias = $this.Engine.GetBias($l, $j) } }
        $this.Dirty = $false
    }
    [double[]] Forward([double[]]$inputs) { if ($null -eq $this.Engine) { $this.BuildEngine() }; return $this.Engine.Forward($inputs) }
    [double[]] Predict([double[]]$inputs) { if ($null -eq $this.Engine) { $this.BuildEngine() }; return $this.Engine.Predict($inputs) }
    [double] TrainSample([double[]]$x, [double[]]$target) { if ($null -eq $this.Engine) { $this.BuildEngine() }; $this.Dirty = $true; return $this.Engine.TrainSample($x, $target) }
    [void] Backward([double[]]$target) { throw 'FastNeuralNetwork: Backward on its own is not supported -- use TrainSample' }
    [hashtable] ExportState() { $this.SyncToNeurons(); return ([NeuralNetwork]$this).ExportState() }
    [void] ImportState([hashtable]$state) { ([NeuralNetwork]$this).ImportState($state); $this.BuildEngine() }
    [void] SetOutputActivation([string]$activation) { $this.SyncToNeurons(); ([NeuralNetwork]$this).SetOutputActivation($activation); if ($null -ne $this.Engine) { $this.BuildEngine() } }
}

# ---------- the factory: every network in VBAF is created here ----------
class VBAFNetworkFactory {
    static [bool] UseFast() {
        $mode = [string]$global:VBAFNetEngine
        if ([string]::IsNullOrEmpty($mode) -or $mode -eq 'PowerShell') { return $false }
        if ($mode -eq 'Auto') { return [bool]$global:VBAFFastEngineAvailable }
        if ($mode -eq 'Fast') {
            if (-not $global:VBAFFastEngineAvailable) { throw ("VBAFNetEngine is 'Fast' but the C# engine is not available -- " + $global:VBAFFastEngineReason) }
            return $true
        }
        throw ("Unknown VBAFNetEngine '" + $mode + "' (use PowerShell, Auto or Fast)")
    }
    static [NeuralNetwork] Create([int[]]$architecture, [double]$learningRate) {
        if ([VBAFNetworkFactory]::UseFast()) { return [FastNeuralNetwork]::new($architecture, $learningRate) }
        return [NeuralNetwork]::new($architecture, $learningRate)
    }
    static [NeuralNetwork] Create([int[]]$architecture, [double]$learningRate, [int]$seed) {
        if ([VBAFNetworkFactory]::UseFast()) { return [FastNeuralNetwork]::new($architecture, $learningRate, $seed) }
        return [NeuralNetwork]::new($architecture, $learningRate, $seed)
    }
}

function Set-VBAFNetEngine {
    param([Parameter(Mandatory)][ValidateSet('PowerShell', 'Auto', 'Fast')][string]$Engine)
    $global:VBAFNetEngine = $Engine
    Get-VBAFNetEngine
}
function Get-VBAFNetEngine {
    [pscustomobject]@{
        Engine    = [string]$global:VBAFNetEngine
        Available = [bool]$global:VBAFFastEngineAvailable
        Reason    = [string]$global:VBAFFastEngineReason
        UsesFast  = $(try { [VBAFNetworkFactory]::UseFast() } catch { $false })
    }
}