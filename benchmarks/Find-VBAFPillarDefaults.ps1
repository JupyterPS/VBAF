#Requires -Version 5.1
<#
.SYNOPSIS
    Find-VBAFPillarDefaults -- VBAF 6.2 (KF-14): the four New-EnterpriseEnvironment pillars find their own default settings.
.DESCRIPTION
    For each pillar: 12 random settings (the generator and ranges of Invoke-VBAFSettingsSearch), each trained with the
    pillar's OWN training function and the budget it is measured with (30 episodes, SimMode), on training seeds 101-103
    (not the 1-3 that Measure-VBAFPillars uses). Every brain is scored on validation seeds 20001-20020; the settings with
    the best mean over the three training seeds win. Test seeds are NOT used here: the pillars are measured on new test
    seeds afterwards. One JSON per pillar in benchmarks\data\settings-v6.2 (the run resumes). -DryRun: tiny run into %TEMP%.
#>
param([switch]$DryRun)
$kroot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Push-Location $kroot; . (Join-Path $kroot 'VBAF.LoadAll.ps1') *> $null; Pop-Location
$global:VBAFNetEngine = 'Fast'
function Say($m) { Write-Host ('{0}  {1}' -f (Get-Date -Format HH:mm:ss), $m) }
$pillars = @('AlertRouter', 'JobScheduler', 'ResourceOptimizer', 'SupplyChain')
if ($DryRun) { $P = @{ Candidates = 2; TrainSeeds = @(101); Episodes = 3; Val = @(20001, 20002); Dir = (Join-Path $env:TEMP 'VBAF-settings-v6.2-dryrun') }
               if (Test-Path $P.Dir) { Remove-Item $P.Dir -Recurse -Force } }
else         { $P = @{ Candidates = 12; TrainSeeds = @(101, 102, 103); Episodes = 30; Val = @(20001..20020); Dir = (Join-Path $kroot 'benchmarks\data\settings-v6.2') } }
New-Item -ItemType Directory -Path $P.Dir -Force | Out-Null
$commit = try { (git -C $kroot rev-parse --short HEAD 2>$null).Trim() } catch { '' }
$swAll = [Diagnostics.Stopwatch]::StartNew()
Say ('Find-VBAFPillarDefaults {0}: {1} candidates x training seeds {2}, {3} episodes, {4} validation seeds -> {5}' -f $(if ($DryRun) { 'DRY RUN' } else { 'REAL RUN' }), $P.Candidates, ($P.TrainSeeds -join ','), $P.Episodes, $P.Val.Count, $P.Dir)
for ($pi = 0; $pi -lt $pillars.Count; $pi++) {
    $pl = $pillars[$pi]
    $out = Join-Path $P.Dir ($pl + '.json')
    if (Test-Path $out) { Say ($pl + ': done earlier'); continue }
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $mk = [scriptblock]::Create("param(`$s) New-EnterpriseEnvironment -Name '$pl' -Seed `$s")
    Set-VBAFSeed $P.Val[0]; $nA = [int](& $mk $P.Val[0]).ActionSpace.Size
    $fixed = @(for ($k = 0; $k -lt $nA; $k++) { $pol = [scriptblock]::Create("param(`$st, `$rng) $k")
        $t = foreach ($s in $P.Val) { Set-VBAFSeed $s; $e = & $mk $s; [double](Get-VBAFTrace -Environment $e -Policy $pol -MaxSteps 5000 -PolicySeed $s).TotalReward }
        [Math]::Round([double](($t | Measure-Object -Average).Average), 4) })
    $bf = ($fixed | Measure-Object -Maximum).Maximum
    $fn = Get-Command ('Invoke-VBAF' + $pl + 'Training')
    $rng = [System.Random]::new(6200 + $pi)
    $cands = @(for ($c = 0; $c -lt $P.Candidates; $c++) {
        $set = New-VBAFSearchSettings $rng $script:VBAFSearchDefaultRanges
        $vals = @(foreach ($ts in $P.TrainSeeds) {
            Set-VBAFSeed $ts
            $prm = @{ Episodes = $P.Episodes; Settings = $set; PrintEvery = 100000 }
            if ($fn.Parameters.ContainsKey('SimMode')) { $prm['SimMode'] = $true }
            $o = @(& $fn @prm 6>$null 3>$null)
            $a = ($o | Where-Object { $_ -is [hashtable] -and $_.ContainsKey('Agent') } | Select-Object -Last 1).Agent
            Measure-VBAFAgentScore -NewEnvironment $mk -Agent $a -Seeds $P.Val })
        $mean = [Math]::Round([double](($vals | Measure-Object -Average).Average), 4)
        Say ('  {0} candidate {1,2}: LR {2,-8} gamma {3,-6} decay {4,-7} TUF {5,2} -> validation {6}  (mean {7}, bar {8})' -f $pl, $c, [Math]::Round($set.LR, 5), [Math]::Round($set.Gamma, 3), [Math]::Round($set.Decay, 5), $set.TUF, ($vals -join ' / '), $mean, $bf)
        [pscustomobject]@{ Index = $c; Settings = @{ LR = $set.LR; Gamma = $set.Gamma; Decay = $set.Decay; TUF = $set.TUF }; Validation = $vals; Mean = $mean; AboveBar = @($vals | Where-Object { $_ -gt $bf }).Count } })
    $win = $cands | Sort-Object -Property @{ Expression = { $_.Mean }; Descending = $true }, @{ Expression = { $_.Index }; Descending = $false } | Select-Object -First 1
    $res = [ordered]@{ Pillar = $pl; KernelCommit = $commit; DryRun = [bool]$DryRun
        Design = [ordered]@{ Candidates = $P.Candidates; TrainSeeds = $P.TrainSeeds; Episodes = $P.Episodes; ValidationSeeds = $P.Val }
        BestFixedValidation = $bf; FixedValidation = $fixed
        Chosen = $win.Settings; ChosenIndex = $win.Index; ChosenMean = $win.Mean; ChosenAboveBar = $win.AboveBar
        Candidates = $cands; Seconds = [Math]::Round($sw.Elapsed.TotalSeconds, 1) }
    $res | ConvertTo-Json -Depth 6 | Set-Content -Path $out -Encoding UTF8
    Say ('{0}: CHOSEN candidate {1} -- LR {2}, gamma {3}, decay {4}, TUF {5}; validation mean {6} vs bar {7}, above the bar on {8} of {9} training seeds ({10} s)' -f $pl, $win.Index, [Math]::Round($win.Settings.LR, 5), [Math]::Round($win.Settings.Gamma, 3), [Math]::Round($win.Settings.Decay, 5), $win.Settings.TUF, $win.Mean, $bf, $win.AboveBar, $P.TrainSeeds.Count, $res.Seconds)
}
Say ('Done in {0} min' -f [Math]::Round($swAll.Elapsed.TotalMinutes, 1))
