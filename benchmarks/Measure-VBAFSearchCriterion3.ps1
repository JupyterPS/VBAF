#Requires -Version 5.1
<#
.SYNOPSIS
    VBAF 6.2 success criterion 3: on an environment not used to build it, does Invoke-VBAFSettingsSearch beat the default settings?
.DESCRIPTION
    The production cell (ProductionCellEnvironment; the search was built on AlertRouter). Default settings (LR 0.001, gamma 0.95,
    epsilon decay 0.995, target update 10) run through the SAME machinery with one candidate, so the only difference is whether the
    settings were searched. Search: 6 candidates. Both: 150 episodes in 6 rounds, validation seeds 2001-2010, population seeds 1-3,
    scored on the 30 test seeds 1001-1030. Met if the search has the higher mean AND wins on at least 2 of 3 seeds (locked in the
    CHANGELOG before running). -DryRun: tiny run into %TEMP%.
#>
param([switch]$DryRun)
$kroot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Push-Location $kroot; . (Join-Path $kroot 'VBAF.LoadAll.ps1') *> $null; Pop-Location
$global:VBAFNetEngine = 'Fast'
function Say($m) { Write-Host ('{0}  {1}' -f (Get-Date -Format HH:mm:ss), $m) }
$mk = { param($s) [ProductionCellEnvironment]::new($s) }
if ($DryRun) { $P = @{ Cand = 2; Ep = 2; Rounds = 1; Val = @(2001, 2002); Test = @(1001, 1002); Seeds = @(1); Dir = (Join-Path $env:TEMP 'VBAF-criterion3-dryrun') }
               if (Test-Path $P.Dir) { Remove-Item $P.Dir -Recurse -Force } }
else         { $P = @{ Cand = 6; Ep = 150; Rounds = 6; Val = @(Get-VBAFProductionValidationSeeds); Test = @(Get-VBAFProductionTestSeeds); Seeds = @(1, 2, 3); Dir = (Join-Path $kroot 'benchmarks\data\criterion3-v6.2') } }
New-Item -ItemType Directory -Path $P.Dir -Force | Out-Null
$point = @{ LR = @(0.001, 0.001); Gamma = @(0.95, 0.95); Decay = @(0.995, 0.995); TUF = @(10, 10) }
$commit = try { (git -C $kroot rev-parse --short HEAD 2>$null).Trim() } catch { '' }
$swAll = [Diagnostics.Stopwatch]::StartNew()
Say ('Criterion 3 {0}: production cell, search {1} candidates vs default settings, {2} episodes in {3} rounds, seeds {4}, {5} test seeds' -f $(if ($DryRun) { 'DRY RUN' } else { 'REAL RUN' }), $P.Cand, $P.Ep, $P.Rounds, ($P.Seeds -join ','), $P.Test.Count)
foreach ($s in $P.Seeds) {
    $f = Join-Path $P.Dir ('seed{0}.json' -f $s)
    if (Test-Path $f) { Say ("seed ${s}: done earlier"); continue }
    $srch = Invoke-VBAFSettingsSearch -NewEnvironment $mk -Candidates $P.Cand -Episodes $P.Ep -Rounds $P.Rounds -ValidationSeeds $P.Val -Seed $s -Quiet
    $dflt = Invoke-VBAFSettingsSearch -NewEnvironment $mk -Candidates 1 -Episodes $P.Ep -Rounds $P.Rounds -ValidationSeeds $P.Val -Seed $s -Ranges $point -Quiet
    $tS = Measure-VBAFAgentScore -NewEnvironment $mk -Agent $srch.Agent -Seeds $P.Test
    $tD = Measure-VBAFAgentScore -NewEnvironment $mk -Agent $dflt.Agent -Seeds $P.Test
    $res = [ordered]@{ Seed = $s; KernelCommit = $commit; DryRun = [bool]$DryRun; SearchTest = $tS; DefaultTest = $tD; SearchWins = ($tS -gt $tD)
        SearchSettings = $srch.Settings; SearchValidation = $srch.ValidationScore; DefaultSettings = $dflt.Settings; DefaultValidation = $dflt.ValidationScore
        Candidates = $srch.Candidates; Seconds = [Math]::Round($srch.Seconds + $dflt.Seconds, 1) }
    $res | ConvertTo-Json -Depth 6 | Set-Content -Path $f -Encoding UTF8
    Say ('seed {0}: search {1} (LR {2})   default {3}   -> search wins: {4}   ({5} s)' -f $s, $tS, [Math]::Round($srch.Settings.LR, 4), $tD, ($tS -gt $tD), $res.Seconds) }
$rows = @(foreach ($s in $P.Seeds) { $f = Join-Path $P.Dir ('seed{0}.json' -f $s); if (Test-Path $f) { Get-Content $f -Raw | ConvertFrom-Json } })
$ms = ($rows | ForEach-Object { [double]$_.SearchTest } | Measure-Object -Average).Average; $md = ($rows | ForEach-Object { [double]$_.DefaultTest } | Measure-Object -Average).Average
$wins = @($rows | Where-Object { [double]$_.SearchTest -gt [double]$_.DefaultTest }).Count
$met = ($rows.Count -eq $P.Seeds.Count -and $ms -gt $md -and $wins -ge [Math]::Ceiling(2 * $P.Seeds.Count / 3))
$sum = [ordered]@{ DryRun = [bool]$DryRun; SearchMean = [Math]::Round($ms, 3); DefaultMean = [Math]::Round($md, 3); SearchWins = $wins; Of = $P.Seeds.Count; Criterion3 = $(if ($met) { 'MET' } else { 'NOT MET' }); Minutes = [Math]::Round($swAll.Elapsed.TotalMinutes, 1) }
$sum | ConvertTo-Json | Set-Content -Path (Join-Path $P.Dir 'criterion3-summary.json') -Encoding UTF8
Write-Host ''
Write-Host ('CRITERION 3: {0}   search mean {1} vs default mean {2}, search wins {3} of {4}{5}' -f $sum.Criterion3, $sum.SearchMean, $sum.DefaultMean, $wins, $P.Seeds.Count, $(if ($DryRun) { '   (DRY RUN -- means nothing)' } else { '' })) -ForegroundColor $(if ($met) { 'Green' } else { 'Red' })
Say ('Done in {0} min' -f $sum.Minutes)
