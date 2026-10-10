#Requires -Version 5.1
# VBAF 6.2 -- Invoke-VBAFSettingsSearch: 5 checks, each able to fail. Run: .\tests\Test-SettingsSearch.ps1 (about 2 minutes)
$kroot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Push-Location $kroot; . .\VBAF.LoadAll.ps1 *> $null; Pop-Location
$global:VBAFNetEngine = 'Auto'
$checks = [ordered]@{}
$ar = { param($s) New-EnterpriseEnvironment -Name 'AlertRouter' -Seed $s }
$probe = @(@(0.05, 0.5, 0.7, 0.2), @(0.4, 0.5, 0.7, 0.2), @(0.8, 0.5, 0.7, 0.2))
function QText($a) { (@(foreach ($x in $probe) { ($a.MainNetwork.Predict([double[]]$x) | ForEach-Object { $_.ToString('R') }) -join ',' }) -join ';') }
Write-Host ('kernel ' + $kroot + ', engine ' + $global:VBAFNetEngine)

# 1 settings in range
$rng = [System.Random]::new(5); $g = @(1..200 | ForEach-Object { New-VBAFSearchSettings $rng $script:VBAFSearchDefaultRanges })
$rg = $script:VBAFSearchDefaultRanges
$bad = @($g | Where-Object { $_.LR -lt $rg.LR[0] -or $_.LR -gt $rg.LR[1] -or $_.Gamma -lt $rg.Gamma[0] -or $_.Gamma -gt $rg.Gamma[1] -or $_.Decay -lt $rg.Decay[0] -or $_.Decay -gt $rg.Decay[1] -or $_.TUF -lt $rg.TUF[0] -or $_.TUF -gt $rg.TUF[1] }).Count
$lrs = @($g | ForEach-Object { $_.LR })
$checks["1 settings: 200 in range ($bad out), LR below 0.001 and between 0.01-0.03 both present"] = ($bad -eq 0 -and @($lrs | Where-Object { $_ -lt 0.001 }).Count -gt 0 -and @($lrs | Where-Object { $_ -gt 0.01 -and $_ -lt 0.03 }).Count -gt 0)

# 2 determinism
$small = @{ NewEnvironment = $ar; Candidates = 2; Episodes = 4; Rounds = 2; ValidationSeeds = @(20001, 20002); Seed = 3; Quiet = $true }
$a = Invoke-VBAFSettingsSearch @small; $b = Invoke-VBAFSettingsSearch @small
$checks['2 determinism: same seed -> same settings, same validation score, identical Q-values'] = ($a.Settings.LR -eq $b.Settings.LR -and $a.Settings.TUF -eq $b.Settings.TUF -and $a.ValidationScore -eq $b.ValidationScore -and (QText $a.Agent) -ceq (QText $b.Agent))

# 3 the returned brain is the restored best checkpoint
$re = Measure-VBAFAgentScore -NewEnvironment $ar -Agent $a.Agent -Seeds @(20001, 20002)
$checks["3 restore: the returned brain reproduces its validation score ($re = $($a.ValidationScore))"] = ($re -eq $a.ValidationScore)

# 4 sensitivity on AlertRouter
$val = @(20001..20005)
$fixed = @(for ($k = 0; $k -lt 4; $k++) { $pol = [scriptblock]::Create("param(`$st, `$rng) $k")
    $t = foreach ($s in $val) { Set-VBAFSeed $s; $e = & $ar $s; [double](Get-VBAFTrace -Environment $e -Policy $pol -MaxSteps 5000 -PolicySeed $s).TotalReward }
    [Math]::Round([double](($t | Measure-Object -Average).Average), 4) })
$bf = ($fixed | Measure-Object -Maximum).Maximum
$hi = Invoke-VBAFSettingsSearch -NewEnvironment $ar -Candidates 4 -Episodes 40 -Rounds 2 -ValidationSeeds $val -Seed 9 -Quiet
$lowRanges = @{ LR = @(0.0005, 0.001); Gamma = @(0.8, 0.99); Decay = @(0.99, 0.9995); TUF = @(2, 20) }
$lo = Invoke-VBAFSettingsSearch -NewEnvironment $ar -Candidates 4 -Episodes 40 -Rounds 2 -ValidationSeeds $val -Seed 9 -Ranges $lowRanges -Quiet
$checks["4 sensitivity (AlertRouter): search $($hi.ValidationScore) (LR $([Math]::Round($hi.Settings.LR, 4))), LR forced to 0.0005-0.001 $($lo.ValidationScore), best fixed $bf"] = ($hi.ValidationScore -gt $bf -and $lo.ValidationScore -le $bf)

# 5 bad input
$err = $null; try { [void](Invoke-VBAFSettingsSearch -NewEnvironment $ar -Episodes 10 -Rounds 3 -Quiet) } catch { $err = $_.Exception.Message }
$checks["5 bad input: 10 episodes in 3 rounds is refused ($([bool]$err))"] = ([bool]$err -and $err -like '*multiple of -Rounds*')

$fail = 0
foreach ($k in $checks.Keys) { $ok = [bool]$checks[$k]; if (-not $ok) { $fail++ }; Write-Host ('{0}  {1}' -f $(if ($ok) { 'PASS' } else { 'FAIL' }), $k) }
if ($fail -eq 0) { Write-Host ('ALL {0} CHECKS PASS' -f $checks.Count) -ForegroundColor Green; exit 0 } else { Write-Host ('{0} of {1} CHECKS FAIL' -f $fail, $checks.Count) -ForegroundColor Red; exit 1 }
