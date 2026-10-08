#Requires -Version 5.1
<#
.SYNOPSIS
    Measure-VBAFPillars -- re-measure every enterprise pillar honestly (VBAF v6.0).
.DESCRIPTION
    Before v6.0 the pillars reported "improvement over random", but nothing was learned (KF-4): the figures were
    "one fixed action vs random", and some environments were even built so that one fixed action guarantees a
    positive "improvement". This script trains each pillar with its OWN training function (unchanged, -SimMode),
    then evaluates on the SAME evaluation episodes (same seeds for every policy) with Get-VBAFTrace:
        random choices | every fixed action | the trained agent (greedy)
    and reports: did it learn (non-zero losses), trained vs random (the old measure), trained vs the BEST FIXED
    action (the honest bar), and whether the agent uses more than one action. Several seeds -> mean +/- SD.
    Every pillar x seed runs in its own powershell.exe (a crash never stops the rest) and is saved at once, so an
    interrupted run resumes. Test-NetConnection is stubbed during the run (CloudBridge would ping real hosts).
    -Engine PowerShell|Auto|Fast (6.1): the network engine the child processes use. The engine is bit-identical, so it changes only the speed.
.EXAMPLE
    .\benchmarks\Measure-VBAFPillars.ps1 -OutDir C:\Temp\pillars -Episodes 30 -Seeds 1,2,3 -EvalEpisodes 10
.EXAMPLE
    .\benchmarks\Measure-VBAFPillars.ps1 -OutDir C:\Temp\pillars-dry -Episodes 1 -Seeds 1 -EvalEpisodes 2   # timing dry run
#>
param(
    [string]$OutDir = '', [int]$Episodes = 30, [int[]]$Seeds = @(1, 2, 3), [int]$EvalEpisodes = 10, [string[]]$Pillars = @(), [ValidateSet('PowerShell', 'Auto', 'Fast')][string]$Engine = 'PowerShell',
    [string]$ChildPillar = '', [int]$ChildSeed = 0, [string]$ChildOut = ''
)
$kroot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
function Say([string]$m) { [Console]::WriteLine(('{0:HH:mm:ss}  {1}' -f (Get-Date), $m)) }
function Get-VBAFPillarList([string]$Root) {
    $list = @()
    foreach ($f in @(Get-ChildItem $Root -Filter 'VBAF.Enterprise.*.ps1' -File | Where-Object { $_.Name -ne 'VBAF.Enterprise.Environment.ps1' } | Sort-Object Name)) {
        $t = Get-Content $f.FullName -Raw -Encoding UTF8
        $fn = [regex]::Match($t, 'function\s+(Invoke-VBAF\w+Training)')
        if (-not $fn.Success) { continue }
        $cls = [regex]::Match($t, '\[(\w+Environment)\]::new')
        $ent = [regex]::Match($t, 'New-EnterpriseEnvironment\s+-Name\s+"(\w+)"')
        $list += [pscustomobject]@{ Pillar = $f.BaseName.Replace('VBAF.Enterprise.', ''); Function = $fn.Groups[1].Value
            EnvClass = $(if ($cls.Success) { $cls.Groups[1].Value } else { '' }); EnterpriseName = $(if ($ent.Success) { $ent.Groups[1].Value } else { '' }) }
    }
    return $list
}

if ($ChildPillar -ne '') {
    # ===================== CHILD: one pillar, one seed =====================
    Push-Location $kroot; . (Join-Path $kroot 'VBAF.LoadAll.ps1') *> $null; Pop-Location; $global:VBAFNetEngine = $Engine
    function global:Test-NetConnection {
        param([Parameter(Position = 0)]$ComputerName, $Port, [switch]$InformationLevel, [switch]$WarningAction)
        [pscustomobject]@{ ComputerName = $ComputerName; RemoteAddress = $ComputerName; PingSucceeded = $true; TcpTestSucceeded = $true
            NameResolutionSucceeded = $true; PingReplyDetails = [pscustomobject]@{ RoundtripTime = 20; Status = 'Success' } }
    }
    $info = @(Get-VBAFPillarList $kroot | Where-Object { $_.Pillar -eq $ChildPillar })[0]
    $res = [ordered]@{ Pillar = $ChildPillar; Seed = $ChildSeed; Episodes = $Episodes; EvalEpisodes = $EvalEpisodes; Error = '' }
    try {
        Set-VBAFSeed $ChildSeed
        $fn = Get-Command $info.Function
        $p = @{}
        if ($fn.Parameters.ContainsKey('Episodes'))   { $p['Episodes']   = $Episodes }
        if ($fn.Parameters.ContainsKey('PrintEvery')) { $p['PrintEvery'] = 100000 }
        if ($fn.Parameters.ContainsKey('SimMode'))    { $p['SimMode']    = $true }
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $out = @(& $info.Function @p 6>$null 3>$null)
        $res.TrainSeconds = [Math]::Round($sw.Elapsed.TotalSeconds, 1)
        $r = $out | Where-Object { $_ -is [hashtable] -and $_.ContainsKey('Agent') } | Select-Object -Last 1
        if ($null -eq $r) { throw 'the training function returned no agent' }
        $a = $r.Agent
        $losses = @($a.LossHistory)
        $res.TrainSteps = [int]$a.TrainingSteps; $res.Losses = $losses.Count; $res.NonZero = @($losses | Where-Object { $_ -ne 0 }).Count
        $res.Learned = ($res.NonZero -gt 0)
        $nAct = [int]$a.ActionSize; $res.Actions = $nAct
        if ($r.Baseline) { $res.PillarReportBaseline = [double]$r.Baseline.Avg }
        if ($r.Trained)  { $res.PillarReportTrained  = [double]$r.Trained.Avg }
        function New-EvalEnv([int]$s) {
            Set-VBAFSeed $s
            if ($info.EnterpriseName -ne '') { return (New-EnterpriseEnvironment -Name $info.EnterpriseName -Seed $s) }
            return (Invoke-Expression ('[' + $info.EnvClass + ']::new()'))
        }
        $sw2 = [System.Diagnostics.Stopwatch]::StartNew()
        $policies = [ordered]@{ 'random' = @{ Policy = { param($st, $rng) $rng.Next(0, $nAct) }.GetNewClosure() } }
        for ($k = 0; $k -lt $nAct; $k++) { $policies["fixed$k"] = @{ Policy = [scriptblock]::Create("param(`$st, `$rng) $k") } }
        $policies['trained'] = @{ Agent = $a }
        $means = [ordered]@{}; $trainedActs = New-Object int[] $nAct; $style = ''
        foreach ($pn in $policies.Keys) {
            $tot = @()
            for ($e = 1; $e -le $EvalEpisodes; $e++) {
                $s = 10000 + $e
                $env = New-EvalEnv $s
                if ($policies[$pn].ContainsKey('Agent')) { $tr = Get-VBAFTrace -Environment $env -Agent $policies[$pn].Agent -MaxSteps 5000 -PolicySeed $s }
                else { $tr = Get-VBAFTrace -Environment $env -Policy $policies[$pn].Policy -MaxSteps 5000 -PolicySeed $s }
                $tot += [double]$tr.TotalReward; $style = $tr.Style
                if ($pn -eq 'trained') { foreach ($st in @($tr.Steps)) { if ($st.Action -ge 0 -and $st.Action -lt $nAct) { $trainedActs[$st.Action]++ } } }
            }
            $means[$pn] = [Math]::Round([double](($tot | Measure-Object -Average).Average), 3)
        }
        $res.EvalSeconds = [Math]::Round($sw2.Elapsed.TotalSeconds, 1); $res.Style = $style
        $res.Random = $means['random']; $res.Trained = $means['trained']
        $fixed = @(for ($k = 0; $k -lt $nAct; $k++) { $means["fixed$k"] })
        $res.Fixed = $fixed
        $best = ($fixed | Measure-Object -Maximum).Maximum
        $res.BestFixed = $best; $res.BestFixedAction = [Array]::IndexOf([double[]]$fixed, [double]$best)
        $res.VsRandomPct = $(if ($res.Random -ne 0) { [Math]::Round(($res.Trained - $res.Random) / [Math]::Abs($res.Random) * 100, 1) } else { $null })
        $res.VsBestFixed = [Math]::Round($res.Trained - $best, 3)
        $res.TrainedActions = ($trainedActs -join '/'); $res.Varied = (@($trainedActs | Where-Object { $_ -gt 0 }).Count -gt 1)
    } catch { $res.Error = $_.Exception.Message }
    if ($res -is [System.Collections.IDictionary]) { $res['Engine'] = $Engine; $res['UsesFast'] = [VBAFNetworkFactory]::UseFast() } else { $res | Add-Member -NotePropertyName Engine -NotePropertyValue $Engine -Force; $res | Add-Member -NotePropertyName UsesFast -NotePropertyValue ([VBAFNetworkFactory]::UseFast()) -Force }
    $res | ConvertTo-Json -Depth 4 | Set-Content -Path $ChildOut -Encoding UTF8
    return
}

# ===================== RUNNER =====================
if ($OutDir -eq '') { throw 'Measure-VBAFPillars: -OutDir is required (one result file per pillar and seed; the run is resumable).' }
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
$list = @(Get-VBAFPillarList $kroot)
if ($Pillars.Count -gt 0) { $list = @($list | Where-Object { $Pillars -contains $_.Pillar }) }
Write-Host ('=== Measure-VBAFPillars: {0} pillars x {1} seeds, {2} training episodes, {3} evaluation episodes, engine {5} -> {4} ===' -f $list.Count, $Seeds.Count, $Episodes, $EvalEpisodes, $OutDir, $Engine) -ForegroundColor Cyan
$i = 0
foreach ($s in $Seeds) {
    foreach ($pl in $list) {
        $i++
        $f = Join-Path $OutDir ('{0}-s{1}.json' -f $pl.Pillar, $s)
        if (Test-Path $f) { Say ('[{0}/{1}] {2} seed {3}: done earlier' -f $i, ($list.Count * $Seeds.Count), $pl.Pillar, $s); continue }
        Say ('[{0}/{1}] {2} seed {3} ...' -f $i, ($list.Count * $Seeds.Count), $pl.Pillar, $s)
        & powershell.exe -NoProfile -NonInteractive -InputFormat None -ExecutionPolicy Bypass -File $PSCommandPath -ChildPillar $pl.Pillar -ChildSeed $s -ChildOut $f -Episodes $Episodes -EvalEpisodes $EvalEpisodes -Engine $Engine 2>&1 | ForEach-Object { Write-Host ('      ' + [string]$_) }
        if (Test-Path $f) {
            $x = (Get-Content $f -Raw -Encoding UTF8 | ConvertFrom-Json)
            if ($x.Error) { Say ('      ERROR: ' + $x.Error) }
            else { Say ('      learned {0} | trained {1} random {2} best fixed {3} (action {4}) | vs random {5}% vs best fixed {6} | actions {7} | train {8}s eval {9}s' -f $x.Learned, $x.Trained, $x.Random, $x.BestFixed, $x.BestFixedAction, $x.VsRandomPct, $x.VsBestFixed, $x.TrainedActions, $x.TrainSeconds, $x.EvalSeconds) }
        } else { Say '      no result file (the child process failed)' }
    }
}
# ---------- summary over seeds ----------
function Get-MS($v) { $x = @($v | Where-Object { $null -ne $_ } | ForEach-Object { [double]$_ }); if ($x.Count -eq 0) { return $null }; $m = ($x | Measure-Object -Average).Average; $sd = 0.0; if ($x.Count -gt 1) { $sd = [Math]::Sqrt((($x | ForEach-Object { ($_ - $m) * ($_ - $m) }) | Measure-Object -Sum).Sum / ($x.Count - 1)) }; return [pscustomobject]@{ Mean = [Math]::Round($m, 2); SD = [Math]::Round($sd, 2); N = $x.Count } }
$rows = foreach ($pl in $list) {
    $rs = @($Seeds | ForEach-Object { $f = Join-Path $OutDir ('{0}-s{1}.json' -f $pl.Pillar, $_); if (Test-Path $f) { Get-Content $f -Raw -Encoding UTF8 | ConvertFrom-Json } } | Where-Object { $_ -and -not $_.Error })
    if ($rs.Count -eq 0) { continue }
    [pscustomobject]@{ Pillar = $pl.Pillar; Seeds = $rs.Count; Learned = (@($rs | Where-Object { $_.Learned }).Count -eq $rs.Count)
        Trained = (Get-MS ($rs | ForEach-Object { $_.Trained })); Random = (Get-MS ($rs | ForEach-Object { $_.Random })); BestFixed = (Get-MS ($rs | ForEach-Object { $_.BestFixed }))
        VsRandomPct = (Get-MS ($rs | ForEach-Object { $_.VsRandomPct })); VsBestFixed = (Get-MS ($rs | ForEach-Object { $_.VsBestFixed }))
        BeatsBestFixed = @($rs | Where-Object { $_.VsBestFixed -gt 0 }).Count; Varied = @($rs | Where-Object { $_.Varied }).Count
        TrainSeconds = [Math]::Round([double](($rs | Measure-Object TrainSeconds -Sum).Sum), 0); EvalSeconds = [Math]::Round([double](($rs | Measure-Object EvalSeconds -Sum).Sum), 0) }
}
$rows | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $OutDir 'pillars-summary.json') -Encoding UTF8
$md = @('| Pillar | Learned | Trained | Random | Best fixed action | vs random | vs best fixed | beats best fixed | uses >1 action |', '|---|---|---|---|---|---|---|---|---|')
foreach ($r in $rows) { $md += ('| {0} | {1} | {2} +/- {3} | {4} | {5} | {6}% | {7} +/- {8} | {9} of {10} | {11} of {10} |' -f $r.Pillar, $(if ($r.Learned) { 'yes' } else { 'NO' }), $r.Trained.Mean, $r.Trained.SD, $r.Random.Mean, $r.BestFixed.Mean, $r.VsRandomPct.Mean, $r.VsBestFixed.Mean, $r.VsBestFixed.SD, $r.BeatsBestFixed, $r.Seeds, $r.Varied) }
$md -join "`n" | Set-Content (Join-Path $OutDir 'pillars-summary.md') -Encoding UTF8
Write-Host ''
Write-Host '=== Summary (mean over seeds) ===' -ForegroundColor Cyan
$rows | ForEach-Object { '{0,-24} learned {1,-5} trained {2,9} | random {3,9} | best fixed {4,9} | vs random {5,7}% | vs best fixed {6,8} | beats best fixed {7}/{8} | train {9}s eval {10}s' -f $_.Pillar, $_.Learned, $_.Trained.Mean, $_.Random.Mean, $_.BestFixed.Mean, $_.VsRandomPct.Mean, $_.VsBestFixed.Mean, $_.BeatsBestFixed, $_.Seeds, $_.TrainSeconds, $_.EvalSeconds } | Write-Host
$errs = @(Get-ChildItem $OutDir -Filter '*-s*.json' | Where-Object { $_.Name -match '-s\d+\.json$' } | ForEach-Object { Get-Content $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } | Where-Object { $_.Error })
if ($errs.Count -gt 0) { Write-Host ('Errors ({0}):' -f $errs.Count) -ForegroundColor Yellow; $errs | ForEach-Object { '  {0} seed {1}: {2}' -f $_.Pillar, $_.Seed, $_.Error } | Write-Host }
