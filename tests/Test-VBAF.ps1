#Requires -Version 5.1
<#
.SYNOPSIS
    VBAF v6.0 regression suite. Run:  .\tests\Test-VBAF.ps1   (exit code 0 = all checks pass, outside ISE)
.DESCRIPTION
    Each check protects one fix from VBAF-Evolution-Lab (KF-1..KF-9) with a FIXED expectation, measured on the
    tested kernel candidate (candidate-v1). The kernel is loaded from this repository ($PSScriptRoot\..) in fresh
    child processes (PowerShell classes cannot be reloaded in one session). Nothing is written into the repository;
    temporary files go to %TEMP%\VBAF-tests.
      KF-9  LoadAll loads in a normal powershell.exe without any ISE workaround (killed after 90 s).
      Supervised results are LOCKED: they were bit-identical in VBAF v4 and v6.0 and must stay so.
      KF-1/KF-4  a DQN outputs Q-values through a Linear layer and Replay really learns.
      KF-3  one seed (Set-VBAFSeed) makes a DQN run reproducible; seed 42 is locked to candidate-v1's fingerprint.
      KF-2  DQNAgent reports the real network, warns on a config mismatch and explores every action.
      KF-6  the JobScheduler pillar trains with its own config.   KF-7  MaxSteps, seeds and -Live in the environments.
      KF-8  Layer.ImportState restores the activation.
#>
param([switch]$Child, [switch]$LoadOnly, [string]$OutFile = '')
$kroot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
function Say([string]$m) { [Console]::WriteLine(('{0:HH:mm:ss}  {1}' -f (Get-Date), $m)) }

if ($LoadOnly) {
    Push-Location $kroot
    . (Join-Path $kroot 'VBAF.LoadAll.ps1') *> $null
    Pop-Location
    [Console]::WriteLine('LOADED')
    exit 0
}

if ($Child) {
    # ===================== CHILD: measure =====================
    function ConvertTo-RText([double]$v) { return $v.ToString('R', [System.Globalization.CultureInfo]::InvariantCulture) }
    function Get-ShaText([string]$s) { $h = [System.Security.Cryptography.SHA256]::Create(); (($h.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($s)) | ForEach-Object { $_.ToString('x2') }) -join '') }
    function ConvertTo-FlatText($o) {
        if ($null -eq $o) { return 'null' }
        if ($o -is [double] -or $o -is [single]) { return ([double]$o).ToString('R', [System.Globalization.CultureInfo]::InvariantCulture) }
        if ($o -is [string]) { return $o }
        if ($o -is [System.Collections.IDictionary]) { return '{' + ((@($o.Keys) | Sort-Object | ForEach-Object { "$_=" + (ConvertTo-FlatText $o[$_]) }) -join ';') + '}' }
        if ($o -is [System.Management.Automation.PSCustomObject]) { return '{' + ((@($o.PSObject.Properties) | Sort-Object Name | ForEach-Object { $_.Name + '=' + (ConvertTo-FlatText $_.Value) }) -join ';') + '}' }
        if ($o -is [System.Collections.IEnumerable]) { return '[' + ((@($o) | ForEach-Object { ConvertTo-FlatText $_ }) -join ',') + ']' }
        return [string]$o
    }
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    Say ('Loading the kernel from ' + $kroot)
    Push-Location $kroot
    . (Join-Path $kroot 'VBAF.LoadAll.ps1') *> $null
    if (-not (Get-Command Invoke-VBAFJobSchedulerTraining -ErrorAction SilentlyContinue)) { . (Join-Path $kroot 'VBAF.Enterprise.JobScheduler.ps1') *> $null }
    Pop-Location
    Say ('Kernel loaded in {0:N1} s' -f $sw.Elapsed.TotalSeconds)
    $res = [ordered]@{ Errors = @() }

    # --- supervised, locked (same procedure as the Lab regression test) ---
    try {
        $res.Sup = [ordered]@{}
        $cases = @(
            @{ Name = 'XOR 2-3-1';          Arch = @(2,3,1); Lr = 0.5; Epochs = 1000; Data = 'xor' },
            @{ Name = 'Agent9-like 4-6-1';  Arch = @(4,6,1); Lr = 0.1; Epochs = 300;  Data = 'rand' },
            @{ Name = 'Agent14-like 6-8-1'; Arch = @(6,8,1); Lr = 0.1; Epochs = 300;  Data = 'rand' })
        foreach ($c in $cases) {
            $nIn = $c.Arch[0]
            if ($c.Data -eq 'xor') {
                $data = @(
                    @{ Input = [double[]]@(0.0, 0.0); Expected = [double[]]@(0.0) },
                    @{ Input = [double[]]@(0.0, 1.0); Expected = [double[]]@(1.0) },
                    @{ Input = [double[]]@(1.0, 0.0); Expected = [double[]]@(1.0) },
                    @{ Input = [double[]]@(1.0, 1.0); Expected = [double[]]@(0.0) })
            } else {
                Get-Random -SetSeed 7 | Out-Null
                $data = @(for ($s = 0; $s -lt 20; $s++) {
                    $x = [double[]]@(for ($j = 0; $j -lt $nIn; $j++) { Get-Random -Minimum 0.0 -Maximum 1.0 })
                    $y = 0.0; if (($x | Measure-Object -Sum).Sum -gt ($nIn / 2.0)) { $y = 1.0 }
                    @{ Input = $x; Expected = [double[]]@($y) }
                })
            }
            Get-Random -SetSeed 42 | Out-Null
            $nn = [NeuralNetwork]::new([int[]]$c.Arch, [double]$c.Lr)
            $chunk = [int]($c.Epochs / 10); $done = 0; $r = $null
            while ($done -lt $c.Epochs) { $r = & { $nn.Train($data, $chunk, 0) } 6>$null; $done += $chunk }
            $res.Sup[$c.Name] = ConvertTo-RText ([double]$r.FinalError)
            Say ('Supervised {0}: final error {1}' -f $c.Name, $res.Sup[$c.Name])
        }
    } catch { $res.Errors += ('supervised: ' + $_.Exception.Message) }

    # --- XOR with the official example settings ---
    try {
        $xor = @(@{ Input = @(0.0, 0.0); Expected = @(0.0) }, @{ Input = @(0.0, 1.0); Expected = @(1.0) }, @{ Input = @(1.0, 0.0); Expected = @(1.0) }, @{ Input = @(1.0, 1.0); Expected = @(0.0) })
        Get-Random -SetSeed 1 | Out-Null
        $nn = New-Object NeuralNetwork -ArgumentList @(2, 3, 1), 0.5
        for ($b = 1; $b -le 5; $b++) { $null = & { $nn.Train($xor, 1000, 0) } 6>$null }
        $res.XorAccuracy = [double]$nn.Evaluate($xor).Accuracy
        Say ('XOR (official settings, seed 1): accuracy {0}%' -f $res.XorAccuracy)
    } catch { $res.Errors += ('xor: ' + $_.Exception.Message) }

    # --- KF-4 copy, default activation, KF-8 ---
    try {
        Get-Random -SetSeed 3 | Out-Null
        $nn = [NeuralNetwork]::new([int[]]@(2,3,1), 0.5)
        $p1 = $nn.Predict([double[]]@(0.0, 1.0)); $p2 = $nn.Predict([double[]]@(1.0, 0.0))
        $res.PredictAliased = [object]::ReferenceEquals($p1, $p2)
        $res.DefaultOutput = $nn.Layers[$nn.Layers.Count - 1].ActivationType
        $nn.SetOutputActivation('Linear')
        $nb = [NeuralNetwork]::new([int[]]@(2,3,1), 0.5)
        $nb.ImportState($nn.ExportState())
        $res.KF8 = $nb.Layers[$nb.Layers.Count - 1].ActivationType
        Say ('Predict aliased {0}, default output {1}, activation after import {2}' -f $res.PredictAliased, $res.DefaultOutput, $res.KF8)
    } catch { $res.Errors += ('kf4/kf8: ' + $_.Exception.Message) }

    # --- KF-1 + KF-4: DQN probe ---
    try {
        Get-Random -SetSeed 5 | Out-Null
        $cfg = [DQNConfig]::new(); $cfg.StateSize = 4; $cfg.ActionSize = 3
        [int[]]$arch = @(4, 16, 3)
        $main = [NeuralNetwork]::new($arch, $cfg.LearningRate); $tgt = [NeuralNetwork]::new($arch, $cfg.LearningRate)
        $mem = [ExperienceReplay]::new($cfg.MemorySize)
        $agent = & { [DQNAgent]::new($cfg, $main, $tgt, $mem) } 3>$null 6>$null
        $res.DQNOutput = $main.Layers[$main.Layers.Count - 1].ActivationType
        for ($k = 0; $k -lt 64; $k++) {
            $s1 = [double[]]@(for ($j = 0; $j -lt 4; $j++) { Get-Random -Minimum 0.0 -Maximum 1.0 })
            $s2 = [double[]]@(for ($j = 0; $j -lt 4; $j++) { Get-Random -Minimum 0.0 -Maximum 1.0 })
            $agent.Remember($s1, (Get-Random -Maximum 3), (Get-Random -Minimum -1.0 -Maximum 1.0), $s2, $false)
        }
        $before = Get-ShaText (ConvertTo-FlatText $main.ExportState())
        for ($k = 0; $k -lt 10; $k++) { & { [void]$agent.Replay() } 6>$null }
        $res.DQNWeightsChanged = ($before -ne (Get-ShaText (ConvertTo-FlatText $main.ExportState())))
        $res.DQNLossNonZero = @($agent.LossHistory | Where-Object { [double]$_ -ne 0.0 }).Count
        $res.DQNLossCount = @($agent.LossHistory).Count
        Say ('DQN: output {0}, weights changed {1}, non-zero losses {2}/{3}' -f $res.DQNOutput, $res.DQNWeightsChanged, $res.DQNLossNonZero, $res.DQNLossCount)
    } catch { $res.Errors += ('dqn: ' + $_.Exception.Message) }

    # --- KF-3: seed (same procedure as the Lab KF-3 test) ---
    function Invoke-SeedRun([int]$Seed) {
        Set-VBAFSeed $Seed
        $cfg = [DQNConfig]::new(); $cfg.StateSize = 4; $cfg.ActionSize = 3
        [int[]]$arch = @(4, 16, 3)
        $main = [NeuralNetwork]::new($arch, $cfg.LearningRate); $tgt = [NeuralNetwork]::new($arch, $cfg.LearningRate)
        $mem = [ExperienceReplay]::new($cfg.MemorySize)
        $agent = & { [DQNAgent]::new($cfg, $main, $tgt, $mem) } 3>$null 6>$null
        $actions = New-Object System.Collections.Generic.List[int]
        for ($k = 1; $k -le 200; $k++) {
            $s1 = [double[]]@(for ($j = 0; $j -lt 4; $j++) { Get-Random -Minimum 0.0 -Maximum 1.0 })
            $a  = $agent.Act($s1)
            $r  = Get-Random -Minimum -1.0 -Maximum 1.0
            $s2 = [double[]]@(for ($j = 0; $j -lt 4; $j++) { Get-Random -Minimum 0.0 -Maximum 1.0 })
            $agent.Remember($s1, $a, $r, $s2, $false)
            $actions.Add($a)
            if ($k % 2 -eq 0) { & { [void]$agent.Replay() } 6>$null }
        }
        $lossTxt = (@($agent.LossHistory) | ForEach-Object { ([double]$_).ToString('R', [System.Globalization.CultureInfo]::InvariantCulture) }) -join ','
        return [ordered]@{ ActionsSha = Get-ShaText (($actions | ForEach-Object { [string]$_ }) -join ','); LossSha = Get-ShaText $lossTxt; WeightsSha = Get-ShaText (ConvertTo-FlatText ($main.ExportState())) }
    }
    try {
        $res.Seed42a = Invoke-SeedRun 42; $res.Seed42b = Invoke-SeedRun 42; $res.Seed43 = Invoke-SeedRun 43
        Say ('KF-3: seed 42 actions {0}..., weights {1}...' -f $res.Seed42a.ActionsSha.Substring(0, 12), $res.Seed42a.WeightsSha.Substring(0, 12))
    } catch { $res.Errors += ('kf3: ' + $_.Exception.Message) }

    # --- KF-2: config truth ---
    try {
        Set-VBAFSeed 7
        function Invoke-ConfigCase($cfg) {
            [int[]]$arch = @(4, 16, 3)
            $main = [NeuralNetwork]::new($arch, $cfg.LearningRate); $tgt = [NeuralNetwork]::new($arch, $cfg.LearningRate)
            $mem = [ExperienceReplay]::new($cfg.MemorySize)
            $o = @(& { [DQNAgent]::new($cfg, $main, $tgt, $mem) } 3>&1 6>$null)
            $agent = @($o | Where-Object { $_ -is [DQNAgent] })[0]
            $warn = @($o | Where-Object { $_ -is [System.Management.Automation.WarningRecord] } | ForEach-Object { $_.Message })
            $counts = @(0, 0, 0, 0)
            for ($k = 0; $k -lt 300; $k++) {
                $a = $agent.Act([double[]]@(for ($j = 0; $j -lt 4; $j++) { Get-Random -Minimum 0.0 -Maximum 1.0 }))
                if ($a -ge 0 -and $a -le 2) { $counts[$a]++ } else { $counts[3]++ }
            }
            return [ordered]@{ Warnings = $warn; Counts = $counts }
        }
        $mis = [DQNConfig]::new()
        $mat = [DQNConfig]::new(); $mat.ActionSize = 3; $mat.HiddenLayers = @(16)
        $res.KF2Mis = Invoke-ConfigCase $mis; $res.KF2Mat = Invoke-ConfigCase $mat
        Say ('KF-2: mismatch warnings {0}, actions {1}; match warnings {2}, actions {3}' -f @($res.KF2Mis.Warnings).Count, ($res.KF2Mis.Counts -join '/'), @($res.KF2Mat.Warnings).Count, ($res.KF2Mat.Counts -join '/'))
    } catch { $res.Errors += ('kf2: ' + $_.Exception.Message) }

    # --- KF-6: the JobScheduler pillar ---
    try {
        Set-VBAFSeed 7
        $o = @(& { Invoke-VBAFJobSchedulerTraining -Episodes 5 -SimMode } 6>$null 3>&1)
        $r6 = @($o | Where-Object { $_ -is [hashtable] -and $_.ContainsKey('Agent') })[-1]
        $a6 = $r6.Agent
        $res.KF6 = [ordered]@{ Losses = @($a6.LossHistory).Count; Epsilon = [double]$a6.Epsilon; BatchSize = $a6.Config.BatchSize
                               EpsilonDecay = [double]$a6.Config.EpsilonDecay; Hidden = ($a6.Config.HiddenLayers -join ' -> ')
                               Warnings = @($o | Where-Object { $_ -is [System.Management.Automation.WarningRecord] }).Count }
        Say ('KF-6: losses {0}, epsilon {1:F4}, BatchSize {2}, EpsilonDecay {3}, Hidden {4}, warnings {5}' -f $res.KF6.Losses, $res.KF6.Epsilon, $res.KF6.BatchSize, $res.KF6.EpsilonDecay, $res.KF6.Hidden, $res.KF6.Warnings)
    } catch { $res.Errors += ('kf6: ' + $_.Exception.Message) }

    # --- KF-7: environments ---
    try {
        $res.MaxSteps = [ordered]@{}; $res.EpisodeSteps = [ordered]@{}
        foreach ($n in 'JobScheduler', 'ResourceOptimizer', 'AlertRouter', 'SupplyChain') {
            $e = New-EnterpriseEnvironment -Name $n -MaxSteps 20
            [void]$e.Reset(); $k = 0; $done = $false
            while (-not $done -and $k -lt 500) { $st = $e.Step($k % 3); $done = [bool]$st.Done; $k++ }
            $res.MaxSteps[$n] = $e.MaxSteps; $res.EpisodeSteps[$n] = $k
        }
        $ro = New-EnterpriseEnvironment -Name 'ResourceOptimizer'; $js = New-EnterpriseEnvironment -Name 'JobScheduler'
        $res.ResetRO = (Measure-Command { [void]$ro.Reset() }).TotalSeconds
        $res.ResetJS = (Measure-Command { [void]$js.Reset() }).TotalSeconds
        $lv = New-EnterpriseEnvironment -Name 'ResourceOptimizer' -Live
        $res.ResetLive = (Measure-Command { [void]$lv.Reset() }).TotalSeconds
        function Get-EnvFingerprint($e) {
            $parts = @(((@($e.Reset()) | ForEach-Object { ConvertTo-RText $_ }) -join ','))
            foreach ($a in 0, 1, 2, 0, 1, 2, 0, 1, 2, 0) { $st = $e.Step($a); $parts += ((ConvertTo-RText $st.Reward) + '|' + ((@($st.NextState) | ForEach-Object { ConvertTo-RText $_ }) -join ',')); if ($st.Done) { break } }
            return ($parts -join ';')
        }
        $res.Seed = [ordered]@{}
        foreach ($n in 'ResourceOptimizer', 'JobScheduler') {
            $a1 = Get-EnvFingerprint (New-EnterpriseEnvironment -Name $n -Seed 5); $a2 = Get-EnvFingerprint (New-EnterpriseEnvironment -Name $n -Seed 5); $b1 = Get-EnvFingerprint (New-EnterpriseEnvironment -Name $n -Seed 6)
            $res.Seed[$n] = [ordered]@{ SameSeedEqual = ($a1 -eq $a2); OtherSeedDiffers = ($a1 -ne $b1) }
        }
        Say ('KF-7: MaxSteps {0}; Reset RO {1:N3} s, JS {2:N3} s, -Live {3:N3} s' -f (($res.MaxSteps.Values) -join '/'), $res.ResetRO, $res.ResetJS, $res.ResetLive)
    } catch { $res.Errors += ('kf7: ' + $_.Exception.Message) }

    # --- Trace (v6.0 step 4): Get-VBAFTrace ---
    try {
        $fix = { param($s, $rng) 1 }
        Set-VBAFSeed 11; $gw = New-VBAFEnvironment -Name 'GridWorld' -MaxSteps 50 -GridSize 5
        $tA = Get-VBAFTrace -Environment $gw -Policy $fix
        Set-VBAFSeed 11; $gw2 = New-VBAFEnvironment -Name 'GridWorld' -MaxSteps 50 -GridSize 5
        [void]$gw2.Reset(); $mt = 0.0; $mn = 0; $dn = $false
        while (-not $dn -and $mn -lt 10000) { $st = $gw2.Step(1); $mt += [double]$st.Reward; $dn = [bool]$st.Done; $mn++ }
        $res.TraceA = [ordered]@{ Style = $tA.Style; Total = (ConvertTo-RText $tA.TotalReward); Steps = $tA.StepCount; ManualTotal = (ConvertTo-RText $mt); ManualSteps = $mn }
        Set-VBAFSeed 12; $eo = [EnergyOptimizerEnvironment]::new()
        $tB = Get-VBAFTrace -Environment $eo -Policy $fix -MaxSteps 500
        Set-VBAFSeed 12; $eo2 = [EnergyOptimizerEnvironment]::new()
        [void]$eo2.Reset(); $mt = 0.0; $mn = 0
        while (-not $eo2.LastDone -and $mn -lt 500) { $eo2.Step(1); $mt += [double]$eo2.LastReward; [void]$eo2.GetState(); $mn++ }
        $res.TraceB = [ordered]@{ Style = $tB.Style; Total = (ConvertTo-RText $tB.TotalReward); Steps = $tB.StepCount; ManualTotal = (ConvertTo-RText $mt); ManualSteps = $mn }
        $res.TraceC = ''
        try { $null = Get-VBAFTrace -Environment ([pscustomobject]@{ Name = 'no step' }) -Policy $fix } catch { $res.TraceC = $_.Exception.Message }
        $rnd = { param($s, $rng) $rng.Next(0, 2) }
        Set-VBAFSeed 21; $cp1 = New-VBAFEnvironment -Name 'CartPole' -MaxSteps 100
        $t1 = Get-VBAFTrace -Environment $cp1 -Policy $rnd
        Set-VBAFSeed 21; $cp2 = New-VBAFEnvironment -Name 'CartPole' -MaxSteps 100
        $t2 = Get-VBAFTrace -Environment $cp2 -Policy $rnd
        $res.TraceSame = ((ConvertTo-FlatText @($t1.Steps)) -ceq (ConvertTo-FlatText @($t2.Steps))) -and ($t1.StepCount -gt 1)
        $res.TraceSameSteps = $t1.StepCount
        Set-VBAFSeed 31
        $gw3 = New-VBAFEnvironment -Name 'GridWorld' -MaxSteps 30 -GridSize 5
        $nAct = [int]$gw3.ActionSpace.Size; $nObs = @($gw3.Reset()).Count
        $cfgT = [DQNConfig]::new(); $cfgT.StateSize = $nObs; $cfgT.ActionSize = $nAct; $cfgT.HiddenLayers = @(16)
        [int[]]$archT = @($nObs, 16, $nAct)
        $agT = & { [DQNAgent]::new($cfgT, [NeuralNetwork]::new($archT, 0.01), [NeuralNetwork]::new($archT, 0.01), [ExperienceReplay]::new(1000)) } 3>$null 6>$null
        $tG = Get-VBAFTrace -Environment $gw3 -Agent $agT
        $res.TraceAgent = [ordered]@{ Steps = $tG.StepCount; Invalid = @($tG.Steps | Where-Object { $_.Action -lt 0 -or $_.Action -ge $nAct }).Count; Actions = $nAct }
        Set-VBAFSeed 41; $gw4 = New-VBAFEnvironment -Name 'GridWorld' -MaxSteps 20 -GridSize 5
        $tS = Get-VBAFTrace -Environment $gw4 -Policy $fix -Snapshot { param($x) [int]$x.Steps }
        $sn = @($tS.Snapshots)
        $res.TraceSnap = [ordered]@{ Count = $sn.Count; Steps = $tS.StepCount; First = $sn[0]; Last = $sn[$sn.Count - 1] }
        Say ('Trace: A {0} {1}/{2} steps, B {3} {4}/{5} steps, C error {6}, same {7}, agent steps {8}, snapshots {9} for {10} steps' -f $tA.Style, $tA.StepCount, $res.TraceA.ManualSteps, $tB.Style, $tB.StepCount, $res.TraceB.ManualSteps, ($res.TraceC -ne ''), $res.TraceSame, $tG.StepCount, $sn.Count, $tS.StepCount)
    } catch { $res.Errors += ('trace: ' + $_.Exception.Message) }
    # --- Production cell + evolution (v6.0 step 5) ---
    try {
        $world = [ProductionCellEnvironment]::new(1)
        $res.B0 = [double](Measure-VBAFProductionPolicy -World $world -Policy (Get-VBAFProductionRules)['SPT'].Policy -Seeds (Get-VBAFProductionTestSeeds)).Score
        $w1 = (@($world.ResetWithSeed(1005)) | ForEach-Object { ConvertTo-RText $_ }) -join ','
        $w2 = (@($world.ResetWithSeed(1005)) | ForEach-Object { ConvertTo-RText $_ }) -join ','
        $w3 = (@($world.ResetWithSeed(1006)) | ForEach-Object { ConvertTo-RText $_ }) -join ','
        $res.WorldSame = ($w1 -ceq $w2) -and ($w1 -cne $w3)
        Say ('Production cell: Brain 0 (SPT) {0}, same seed same shift {1}' -f $res.B0, $res.WorldSame)
        $evDir = Join-Path $env:TEMP 'VBAF-tests\evolution'
        if (Test-Path $evDir) { Remove-Item $evDir -Recurse -Force }
        New-Item -ItemType Directory -Path $evDir -Force | Out-Null
        Say 'Evolution run: baseline genome, brain seed 101, 50 shifts, checkpoint every 25 (about 70 s) ...'
        $swE = [System.Diagnostics.Stopwatch]::StartNew()
        $null = Invoke-VBAFEvolutionRun -RunId 'suite' -Genome (Get-VBAFBaselineGenome) -BrainSeed 101 -World $world -TrainShifts 50 -Chunk 25 -ValSeeds (Get-VBAFProductionValidationSeeds) -OutDir $evDir 6>$null
        $sec1 = $swE.Elapsed.TotalSeconds
        $je = (Get-Content (Join-Path $evDir 'suite.json') -Raw -Encoding UTF8 | ConvertFrom-Json)
        $sha1 = (Get-FileHash (Join-Path $evDir 'suite-best.xml') -Algorithm SHA256).Hash.Substring(0, 16)
        $res.Evo = [ordered]@{ Curve = ((@($je.Curve) | ForEach-Object { '{0}:{1}' -f $_.Shifts, $_.ValScore }) -join ' '); ModelSha = $sha1; Seconds = [Math]::Round($sec1, 1) }
        $swR = [System.Diagnostics.Stopwatch]::StartNew()
        $null = Invoke-VBAFEvolutionRun -RunId 'suite' -Genome (Get-VBAFBaselineGenome) -BrainSeed 101 -World $world -TrainShifts 50 -Chunk 25 -ValSeeds (Get-VBAFProductionValidationSeeds) -OutDir $evDir 6>$null
        $sha2 = (Get-FileHash (Join-Path $evDir 'suite-best.xml') -Algorithm SHA256).Hash.Substring(0, 16)
        $res.EvoResume = [ordered]@{ Seconds = [Math]::Round($swR.Elapsed.TotalSeconds, 2); SameModel = ($sha1 -ceq $sha2) }
        Say ('Evolution: curve {0}, model {1}, {2} s; resumed call {3} s, same model {4}' -f $res.Evo.Curve, $sha1, $res.Evo.Seconds, $res.EvoResume.Seconds, $res.EvoResume.SameModel)
    } catch { $res.Errors += ('production/evolution: ' + $_.Exception.Message) }
    # --- Evolution window (v6.0 step 6b, part 1) ---
    try {
        $exDir = Join-Path $kroot 'examples\07-Evolution\data'
        $wcs = @(Test-VBAFEvolutionWindow -ResultDir $exDir)
        $res.Window = @($wcs | ForEach-Object { [ordered]@{ Check = $_.Check; Pass = [bool]$_.Pass; Detail = [string]$_.Detail } })
        $wd = Get-VBAFEvolutionData $exDir
        $wb6 = Get-VBAFEvolutionBestSoFar $wd 6
        $res.WindowExample = [ordered]@{ Champion = $wd.Champion; Diff = (@($wd.Nodes | Where-Object { $_.Id -eq 'G1-2' })[0]).Diff; Best6 = $wb6.Id; Nodes = @($wd.Nodes).Count; Finals = @($wd.Finals).Count }
        Say ('Evolution window: {0} of {1} self-checks pass; example champion {2}' -f @($wcs | Where-Object { $_.Pass }).Count, $wcs.Count, $wd.Champion)
    } catch { $res.Errors += ('window: ' + $_.Exception.Message) }
    # --- The shift tab (v6.0 step 6b, part 2) ---
    try {
        $exDir = Join-Path $kroot 'examples\07-Evolution\data'
        $sw2 = [ProductionCellEnvironment]::new(1)
        $sbr = Get-VBAFShiftBrains $exDir
        $snames = @($sbr.Keys)
        $tot = @(); $chs = $null
        foreach ($nm in $snames) { $tr = Get-VBAFShiftTraceFor $sw2 $sbr[$nm] 1001; $tot += (ConvertTo-RText ([double]$tr.Stats.TotalReward)); $chs = $tr }
        $cc = Get-VBAFShiftCounts $chs @($chs.Steps).Count
        $res.ShiftLock = [ordered]@{ Names = ($snames -join ' | '); Totals = ($tot -join '/'); ChampSteps = @($chs.Steps).Count; ChampReal = $cc.Real; ChampIdle = $cc.Idle; ChampChoice = $cc.Choice }
        $vcs = @(Test-VBAFShiftView -ResultDir $exDir)
        $res.ShiftView = @($vcs | ForEach-Object { [ordered]@{ Check = $_.Check; Pass = [bool]$_.Pass; Detail = [string]$_.Detail } })
        Say ('The shift: totals on shift 1001 {0}; champion {1} steps, {2} real, {3} idle; view {4} of {5} self-checks pass' -f $res.ShiftLock.Totals, $res.ShiftLock.ChampSteps, $cc.Real, $cc.Idle, @($vcs | Where-Object { $_.Pass }).Count, $vcs.Count)
    } catch { $res.Errors += ('shift tab: ' + $_.Exception.Message) }
    # --- Side by side tab (v6.0 step 6b, part 3) ---
    try {
        $exDir = Join-Path $kroot 'examples\07-Evolution\data'
        $sv = Test-VBAFSideView -ResultDir $exDir
        $res.SideView = @(@($sv.Checks) | ForEach-Object { [ordered]@{ Check = $_.Check; Pass = [bool]$_.Pass; Detail = [string]$_.Detail } })
        $sd = $sv.Data; $sm = Get-VBAFSideMargins $sd
        $res.SideLock = [ordered]@{ Means = ((@($sd.Brains) | ForEach-Object { ConvertTo-RText $_.Score }) -join '/')
            VsSPT = ('{0}/{1}/{2}' -f $sd.HeadToHead.ChampionVsSPT.W, $sd.HeadToHead.ChampionVsSPT.T, $sd.HeadToHead.ChampionVsSPT.L)
            VsControl = ('{0}/{1}/{2}' -f $sd.HeadToHead.ChampionVsControl.W, $sd.HeadToHead.ChampionVsControl.T, $sd.HeadToHead.ChampionVsControl.L)
            All = $(if ($null -ne $sd.AllChampions) { '{0}: {1}/{2}/{3} of {4}' -f $sd.AllChampions.Brains, $sd.AllChampions.W, $sd.AllChampions.T, $sd.AllChampions.L, $sd.AllChampions.Shifts } else { 'none' })
            Margins = ('{0:F2}/{1:F2}' -f $sm.WinMean, $sm.LossMean) }
        Say ('Side by side: means {0}, vs SPT {1}, vs control {2}, all champions {3}, margins {4}; view {5} of {6} self-checks pass' -f $res.SideLock.Means, $res.SideLock.VsSPT, $res.SideLock.VsControl, $res.SideLock.All, $res.SideLock.Margins, @($sv.Checks | Where-Object { $_.Pass }).Count, @($sv.Checks).Count)
    } catch { $res.Errors += ('side tab: ' + $_.Exception.Message) }
    # --- Teach topic 7 (v6.0 step 6b, part 4b) -- keys simulated: Enter and "n" ---
    try {
        $tt = Get-Content (Join-Path $kroot 'VBAF.Teach.ps1') -Raw -Encoding UTF8
        function Wait-ForEnter { }
        function Read-Host { param([string]$Prompt) 'n' }
        $o = @(& { Teach-Evolution } 6>&1 3>&1 2>&1 | ForEach-Object { [string]$_ })
        $ot = $o -join "`n"
        $res.Teach = [ordered]@{ Lines = $o.Count; Numbers = ($ot.Contains('39.39') -and $ot.Contains('87 won') -and $ot.Contains('4.63')); Command = $ot.Contains('Show-VBAFEvolutionWindow')
            Total7 = ([regex]::Matches($tt, '-Total 7 -TopicName')).Count; Total6 = ([regex]::Matches($tt, '-Total 6 -TopicName')).Count
            InSwitch = ($tt -match '"Evolution"\s+\{\s*Teach-Evolution'); InAll = ($tt -match '(?m)^\s*Teach-Evolution\s*$')
            InHelp = ($tt -match 'Topic 7 -- Evolution'); Examples = ([regex]::Matches($tt, 'Start-VBAFTeach -Topic "Evolution"')).Count }
        Say ('Teach topic 7: {0} lines shown, numbers {1}, command {2}; "of 7" in {3} topics' -f $o.Count, $res.Teach.Numbers, $res.Teach.Command, $res.Teach.Total7)
    } catch { $res.Errors += ('teach: ' + $_.Exception.Message) }
    # --- LoadAll loads without a single error (fresh process; errors are counted, not hidden) ---
    try {
        $lp = Join-Path $env:TEMP 'VBAF-tests\loadall-errors.ps1'
        New-Item -ItemType Directory -Path (Split-Path $lp) -Force | Out-Null
        Set-Content -Path $lp -Encoding UTF8 -Value ('Push-Location ''' + $kroot + '''; $Error.Clear(); . .\VBAF.LoadAll.ps1 *> $null; Pop-Location; ''ERRORS='' + $Error.Count; foreach ($er in $Error) { ''MSG='' + $er.Exception.Message }')
        $lo = @(& powershell.exe -NoProfile -NonInteractive -InputFormat None -ExecutionPolicy Bypass -File $lp 2>&1 | ForEach-Object { [string]$_ })
        $ec = @($lo | Where-Object { $_ -match '^ERRORS=(\d+)$' } | ForEach-Object { [int]($_ -replace '^ERRORS=', '') })
        $res.LoadErrors = [ordered]@{ Count = $(if ($ec.Count -eq 1) { $ec[0] } else { -1 }); Messages = (@($lo | Where-Object { $_ -like 'MSG=*' } | Select-Object -First 3) -join ' | ') }
        Say ('LoadAll in a fresh process: {0} errors' -f $res.LoadErrors.Count)
    } catch { $res.Errors += ('loadall errors: ' + $_.Exception.Message) }
    $res | ConvertTo-Json -Depth 6 | Set-Content -Path $OutFile -Encoding UTF8
    Say ('Result written. Child total {0:N1} s' -f $sw.Elapsed.TotalSeconds)
    return
}

# ===================== RUNNER =====================
$ExpectedSup = [ordered]@{ 'XOR 2-3-1' = '0.27176407352813781'; 'Agent9-like 4-6-1' = '0.058366696125746409'; 'Agent14-like 6-8-1' = '0.14516136481322664' }
$ExpectedKF3 = @{ ActionsSha = 'daf7ee2f0a39b441b7d20fb45c2d5d4e4d21c31fd67a2c7d0b1bd99eeb07fd05'; LossSha = '2470a106d66e6ab6841e703f0eb30846048bf21ecb69e90fb08feef139936068'; WeightsSha = '59a51cf5c0edb48db80f685133a7420648ded359d02b64ec5b5234625e7f9810' }
$tmp = Join-Path $env:TEMP 'VBAF-tests'
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
$checks = [System.Collections.Generic.List[object]]::new()
function Add-Check([string]$what, [bool]$pass, [string]$detail) { $checks.Add([pscustomobject]@{ Result = $(if ($pass) { 'PASS' } else { 'FAIL' }); Check = $what; Detail = $detail }) }
function Test-Has($v) { return ($null -ne $v -and "$v" -ne '') }
Write-Host ''
Write-Host ('=== VBAF regression suite -- kernel ' + $kroot + ' ===') -ForegroundColor Cyan
Write-Host 'Step 1/2: KF-9 -- LoadAll in a normal powershell.exe without any ISE workaround (killed after 90 s)'
$sw9 = [System.Diagnostics.Stopwatch]::StartNew()
$p9 = Start-Process -FilePath 'powershell.exe' -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"' + $PSCommandPath + '"'), '-LoadOnly') -PassThru -WindowStyle Hidden
$ok9 = $p9.WaitForExit(90000)
if (-not $ok9) { try { $p9.Kill() } catch { } }
Add-Check 'KF-9: LoadAll loads outside ISE, no workaround' ($ok9 -and $p9.ExitCode -eq 0) ('finished {0} in {1:N1} s, exit code {2}' -f $ok9, $sw9.Elapsed.TotalSeconds, $(if ($ok9) { $p9.ExitCode } else { 'killed' }))
Write-Host ('   ' + $checks[0].Result + '  ' + $checks[0].Detail)
if (-not $ok9) { Write-Host 'STOP: the kernel hangs when loaded outside ISE -- the rest of the suite is skipped' -ForegroundColor Red; return }
Write-Host 'Step 2/2: measurements in a fresh child process (every step prints a line)'
$out = Join-Path $tmp 'measure.json'; if (Test-Path $out) { Remove-Item $out }
& powershell.exe -NoProfile -NonInteractive -InputFormat None -ExecutionPolicy Bypass -File $PSCommandPath -Child -OutFile $out 2>&1 | ForEach-Object { Write-Host ('   ' + [string]$_) }
if (-not (Test-Path $out)) { Write-Host 'STOP: no result from the child process' -ForegroundColor Red; return }
$m = (Get-Content $out -Raw -Encoding UTF8 | ConvertFrom-Json)
foreach ($k in $ExpectedSup.Keys) { Add-Check ('Supervised locked: ' + $k) ($m.Sup.$k -ceq $ExpectedSup[$k]) ('{0} (expected {1})' -f $m.Sup.$k, $ExpectedSup[$k]) }
Add-Check 'XOR, official example settings (seed 1): 100% accuracy' ($m.XorAccuracy -eq 100) ('accuracy ' + $m.XorAccuracy)
Add-Check 'KF-4: Predict returns a copy' ((Test-Has $m.PredictAliased) -and ($m.PredictAliased -eq $false)) ('aliased: ' + $m.PredictAliased)
Add-Check 'Default output layer stays Sigmoid (classifiers)' ($m.DefaultOutput -eq 'Sigmoid') ('' + $m.DefaultOutput)
Add-Check 'KF-8: Linear survives export/import' ($m.KF8 -eq 'Linear') ('' + $m.KF8)
Add-Check 'KF-1: DQN output layer is Linear' ($m.DQNOutput -eq 'Linear') ('' + $m.DQNOutput)
Add-Check 'KF-4: Replay learns (weights change, losses non-zero)' (($m.DQNWeightsChanged -eq $true) -and ($m.DQNLossNonZero -eq 10) -and ($m.DQNLossCount -eq 10)) ('changed {0}, non-zero {1}/{2}' -f $m.DQNWeightsChanged, $m.DQNLossNonZero, $m.DQNLossCount)
$s42 = $m.Seed42a
Add-Check 'KF-3: seed 42 = candidate-v1 fingerprint (actions, losses, weights)' ((Test-Has $s42) -and ($s42.ActionsSha -eq $ExpectedKF3.ActionsSha) -and ($s42.LossSha -eq $ExpectedKF3.LossSha) -and ($s42.WeightsSha -eq $ExpectedKF3.WeightsSha)) ('actions {0}, losses {1}, weights {2}' -f ($s42.ActionsSha -eq $ExpectedKF3.ActionsSha), ($s42.LossSha -eq $ExpectedKF3.LossSha), ($s42.WeightsSha -eq $ExpectedKF3.WeightsSha))
Add-Check 'KF-3: seed 42 twice in one process is identical' ((Test-Has $m.Seed42b) -and ($m.Seed42a.ActionsSha -eq $m.Seed42b.ActionsSha) -and ($m.Seed42a.LossSha -eq $m.Seed42b.LossSha) -and ($m.Seed42a.WeightsSha -eq $m.Seed42b.WeightsSha)) ''
Add-Check 'KF-3: seed 43 differs from seed 42' ((Test-Has $m.Seed43) -and ($m.Seed43.ActionsSha -ne $m.Seed42a.ActionsSha) -and ($m.Seed43.WeightsSha -ne $m.Seed42a.WeightsSha)) ''
$mw = @($m.KF2Mis.Warnings)
Add-Check 'KF-2: config mismatch warns about ActionSize and HiddenLayers (not StateSize)' (($mw.Count -eq 2) -and (@($mw | Where-Object { $_ -match 'ActionSize' }).Count -eq 1) -and (@($mw | Where-Object { $_ -match 'HiddenLayers' }).Count -eq 1) -and (@($mw | Where-Object { $_ -match 'StateSize' }).Count -eq 0)) ($mw -join ' | ')
Add-Check 'KF-2: mismatch still explores action 2 (>= 50 of 300)' ((Test-Has $m.KF2Mis) -and ($m.KF2Mis.Counts[2] -ge 50)) ('0/1/2 = ' + (@($m.KF2Mis.Counts)[0..2] -join '/'))
Add-Check 'KF-2: matching config gives no warnings and explores all 3 actions' ((Test-Has $m.KF2Mat) -and (@($m.KF2Mat.Warnings).Count -eq 0) -and (@(@($m.KF2Mat.Counts)[0..2] | Where-Object { $_ -gt 0 }).Count -eq 3) -and (@($m.KF2Mat.Counts)[3] -eq 0)) ('warnings {0}, 0/1/2 = {1}' -f @($m.KF2Mat.Warnings).Count, (@($m.KF2Mat.Counts)[0..2] -join '/'))
Add-Check 'KF-6: JobScheduler trains with its own config, no warnings' ((Test-Has $m.KF6) -and ($m.KF6.Losses -gt 0) -and ($m.KF6.Epsilon -lt 1.0) -and ($m.KF6.BatchSize -eq 16) -and ($m.KF6.EpsilonDecay -eq 0.99) -and ($m.KF6.Hidden -eq '16 -> 16') -and ($m.KF6.Warnings -eq 0)) ('losses {0}, BatchSize {1}, EpsilonDecay {2}, Hidden {3}, warnings {4}' -f $m.KF6.Losses, $m.KF6.BatchSize, $m.KF6.EpsilonDecay, $m.KF6.Hidden, $m.KF6.Warnings)
$all4 = @('JobScheduler', 'ResourceOptimizer', 'AlertRouter', 'SupplyChain' | Where-Object { ($m.MaxSteps.$_ -eq 20) -and ($m.EpisodeSteps.$_ -le 20) -and (Test-Has $m.EpisodeSteps.$_) }).Count
Add-Check 'KF-7: -MaxSteps 20 reaches all four environments' (($all4 -eq 4) -and ($m.EpisodeSteps.ResourceOptimizer -eq 20)) ('MaxSteps ' + (@($m.MaxSteps.PSObject.Properties | ForEach-Object { $_.Value }) -join '/'))
Add-Check 'KF-7: Reset without -Live is simulated (< 0.3 s)' ((Test-Has $m.ResetRO) -and ($m.ResetRO -lt 0.3) -and ($m.ResetJS -lt 0.3)) ('RO {0:N3} s, JS {1:N3} s' -f $m.ResetRO, $m.ResetJS)
Add-Check 'KF-7: -Live reads the real PC (>= 0.9 s)' ((Test-Has $m.ResetLive) -and ($m.ResetLive -ge 0.9)) ('{0:N3} s' -f $m.ResetLive)
Add-Check 'KF-7: -Seed 5 twice identical, seed 6 differs (RO + JS)' ((Test-Has $m.Seed) -and ($m.Seed.ResourceOptimizer.SameSeedEqual -eq $true) -and ($m.Seed.ResourceOptimizer.OtherSeedDiffers -eq $true) -and ($m.Seed.JobScheduler.SameSeedEqual -eq $true) -and ($m.Seed.JobScheduler.OtherSeedDiffers -eq $true)) ''
$ta = $m.TraceA
Add-Check 'Trace style A (GridWorld): total and steps = manual loop' ((Test-Has $ta) -and ($ta.Style -eq 'A') -and ($ta.Total -ceq $ta.ManualTotal) -and ($ta.Steps -eq $ta.ManualSteps) -and ($ta.Steps -gt 0)) ('style {0}, total {1} / {2}, steps {3} / {4}' -f $ta.Style, $ta.Total, $ta.ManualTotal, $ta.Steps, $ta.ManualSteps)
$tb = $m.TraceB
Add-Check 'Trace style B (EnergyOptimizer): total and steps = manual loop' ((Test-Has $tb) -and ($tb.Style -eq 'B') -and ($tb.Total -ceq $tb.ManualTotal) -and ($tb.Steps -eq $tb.ManualSteps) -and ($tb.Steps -gt 0)) ('style {0}, total {1} / {2}, steps {3} / {4}' -f $tb.Style, $tb.Total, $tb.ManualTotal, $tb.Steps, $tb.ManualSteps)
Add-Check 'Trace style C (no Step/Reset): a clear error, not an empty trace' ($m.TraceC -match 'style C') ('' + $m.TraceC)
Add-Check 'Trace: the same setup twice gives an identical trace' ($m.TraceSame -eq $true) ('steps ' + $m.TraceSameSteps)
Add-Check 'Trace -Agent works with a DQN agent (valid actions only)' ((Test-Has $m.TraceAgent) -and ($m.TraceAgent.Steps -gt 0) -and ($m.TraceAgent.Invalid -eq 0)) ('steps {0}, invalid {1}, actions {2}' -f $m.TraceAgent.Steps, $m.TraceAgent.Invalid, $m.TraceAgent.Actions)
Add-Check 'Trace -Snapshot: one before every step plus one at the end' ((Test-Has $m.TraceSnap) -and ($m.TraceSnap.Count -eq ($m.TraceSnap.Steps + 1)) -and ($m.TraceSnap.First -eq 0) -and ($m.TraceSnap.Last -eq $m.TraceSnap.Steps)) ('snapshots {0} for {1} steps, first {2}, last {3}' -f $m.TraceSnap.Count, $m.TraceSnap.Steps, $m.TraceSnap.First, $m.TraceSnap.Last)
Add-Check 'Production cell: Brain 0 (SPT) = 37.85 on the test shifts' ($m.B0 -eq 37.85) ('' + $m.B0)
Add-Check 'Production cell: the same seed gives the same shift (another seed does not)' ($m.WorldSame -eq $true) ('' + $m.WorldSame)
Add-Check 'Evolution run LOCKED: curve 25:20.58 50:23.52, model BBC7739C62F0FC96' ((Test-Has $m.Evo) -and ($m.Evo.Curve -ceq '25:20.58 50:23.52') -and ($m.Evo.ModelSha -ceq 'BBC7739C62F0FC96')) ('curve {0}, model {1}, {2} s' -f $m.Evo.Curve, $m.Evo.ModelSha, $m.Evo.Seconds)
Add-Check 'Evolution run is resumable (a second call reuses the saved run: < 5 s, same model)' ((Test-Has $m.EvoResume) -and ($m.EvoResume.Seconds -lt 5) -and ($m.EvoResume.SameModel -eq $true)) ('{0} s, same model {1}' -f $m.EvoResume.Seconds, $m.EvoResume.SameModel)
if (@($m.Window).Count -eq 0) { Add-Check 'Evolution window self-test ran' $false 'no window results' }
foreach ($wc in @($m.Window)) { Add-Check ('Evolution window: ' + $wc.Check) ([bool]$wc.Pass) ([string]$wc.Detail) }
$we = $m.WindowExample
Add-Check 'Evolution window example: 10 candidates, 10 final rows, champion G1-2, its genes BatchSize 16->32 and ReplayEvery 4->2' ((Test-Has $we) -and ($we.Nodes -eq 10) -and ($we.Finals -eq 10) -and ($we.Champion -eq 'G1-2') -and ($we.Diff -ceq 'BatchSize 16->32, ReplayEvery 4->2')) ('{0} / {1} / {2} / {3}' -f $we.Nodes, $we.Finals, $we.Champion, $we.Diff)
Add-Check 'Evolution window example: best so far after step 6 is G1-2' ($we.Best6 -eq 'G1-2') ('' + $we.Best6)
$sl = $m.ShiftLock
Add-Check 'The shift LOCKED to the Lab (shift 1001): SPT 27.7, control 37.55, champion 35.55' ((Test-Has $sl) -and ($sl.Totals -ceq '27.7/37.55/35.55')) ('totals {0}  ({1})' -f $sl.Totals, $sl.Names)
Add-Check 'The shift LOCKED: champion 92 steps, 54 real choices, 38 idle' ((Test-Has $sl) -and ($sl.ChampSteps -eq 92) -and ($sl.ChampReal -eq 54) -and ($sl.ChampIdle -eq 38)) ('{0} steps, {1} real ({2} with a real choice), {3} idle' -f $sl.ChampSteps, $sl.ChampReal, $sl.ChampChoice, $sl.ChampIdle)
if (@($m.ShiftView).Count -eq 0) { Add-Check 'The shift view self-test ran' $false 'no results' }
foreach ($vc in @($m.ShiftView)) { Add-Check ('The shift view: ' + $vc.Check) ([bool]$vc.Pass) ([string]$vc.Detail) }
$sk = $m.SideLock
Add-Check 'Side by side LOCKED: means over 30 test shifts SPT 37.85, control 38, champion 38.98' ((Test-Has $sk) -and ($sk.Means -ceq '37.85/38/38.98')) ('' + $sk.Means)
Add-Check 'Side by side LOCKED: champion vs SPT 15/0/15, vs control 15/2/13' ((Test-Has $sk) -and ($sk.VsSPT -eq '15/0/15') -and ($sk.VsControl -eq '15/2/13')) ('vs SPT {0}, vs control {1}' -f $sk.VsSPT, $sk.VsControl)
Add-Check 'Side by side LOCKED: all 5 champion brains vs SPT 87/4/59 of 150 (Lab head-to-head)' ((Test-Has $sk) -and ($sk.All -eq '5: 87/4/59 of 150')) ('' + $sk.All)
Add-Check 'Side by side LOCKED: win margin 4.63, loss margin 2.36' ((Test-Has $sk) -and ($sk.Margins -eq '4.63/2.36')) ('' + $sk.Margins)
if (@($m.SideView).Count -eq 0) { Add-Check 'Side view self-test ran' $false 'no results' }
foreach ($vc in @($m.SideView)) { Add-Check ('Side view: ' + $vc.Check) ([bool]$vc.Pass) ([string]$vc.Detail) }
$tc = $m.Teach
Add-Check 'Teach topic 7 runs end to end (keys simulated) and shows the real numbers and the command' ((Test-Has $tc) -and ($tc.Lines -gt 20) -and ($tc.Numbers -eq $true) -and ($tc.Command -eq $true)) ('lines {0}, numbers {1}, command {2}' -f $tc.Lines, $tc.Numbers, $tc.Command)
Add-Check 'Teach: all 7 topics say "of 7"; Evolution in -Topic, in All, in the help (topic 7) and in both usage lists' ((Test-Has $tc) -and ($tc.Total7 -eq 7) -and ($tc.Total6 -eq 0) -and ($tc.InSwitch -eq $true) -and ($tc.InAll -eq $true) -and ($tc.InHelp -eq $true) -and ($tc.Examples -eq 2)) ('of 7: {0}, of 6: {1}, switch {2}, All {3}, help {4}, usage lists {5}' -f $tc.Total7, $tc.Total6, $tc.InSwitch, $tc.InAll, $tc.InHelp, $tc.Examples)
$laText = Get-Content (Join-Path $kroot 'VBAF.LoadAll.ps1') -Raw -Encoding UTF8
$laFiles = @([regex]::Matches($laText, '\.\s*\(Join-Path\s+\$basePath\s+"([^"]+)"\)') | ForEach-Object { $_.Groups[1].Value })
$laMissing = @($laFiles | Where-Object { -not (Test-Path (Join-Path $kroot $_)) })
$laUntracked = @($laFiles | Where-Object { -not (git -C $kroot ls-files -- $_) })
Add-Check 'Every file LoadAll loads exists AND is tracked by git (what GitHub users get)' (($laFiles.Count -gt 50) -and ($laMissing.Count -eq 0) -and ($laUntracked.Count -eq 0)) ('{0} files; missing [{1}]; untracked [{2}]' -f $laFiles.Count, ($laMissing -join ', '), ($laUntracked -join ', '))
Add-Check 'LoadAll loads without a single error (fresh process, errors counted)' ((Test-Has $m.LoadErrors) -and ($m.LoadErrors.Count -eq 0)) ('errors {0} {1}' -f $m.LoadErrors.Count, $m.LoadErrors.Messages)
Add-Check 'No errors during the measurements' (@($m.Errors | Where-Object { $_ }).Count -eq 0) ((@($m.Errors) -join ' | '))
Write-Host ''
Write-Host '=== VBAF regression suite: result ===' -ForegroundColor Cyan
$checks | Format-Table Result, Check, Detail -AutoSize -Wrap | Out-String -Width 220 | Write-Host
$fails = @($checks | Where-Object { $_.Result -eq 'FAIL' }).Count
if ($fails -eq 0) { Write-Host ('ALL {0} CHECKS PASS' -f $checks.Count) -ForegroundColor Green } else { Write-Host ('{0} of {1} CHECKS FAIL' -f $fails, $checks.Count) -ForegroundColor Red }
if ($Host.Name -notmatch 'ISE') { if ($fails -eq 0) { exit 0 } else { exit 1 } }
