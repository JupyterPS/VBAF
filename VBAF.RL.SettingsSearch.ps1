#Requires -Version 5.1
<#
.SYNOPSIS
    VBAF 6.2 -- Invoke-VBAFSettingsSearch: a DQN brain that finds its own settings.
.DESCRIPTION
    WHAT  : tries several random settings (learning rate, gamma, epsilon decay, target update), trains a DQN brain with
            each, checks every brain on validation episodes after each round, keeps every brain's best checkpoint, and
            returns the best brain together with its settings.
    WHY   : VBAF-Evolution-Lab Phase 8 showed that the default learning rate (0.001) is far too low for environments with
            small rewards (kernel finding KF-14): 0 of 12 pillar-seeds beat the best fixed action. This search lifted 12 of
            12. A population that inherits weights (population-based training) did NOT do better than this plain search.
    HOW   : random search with a best checkpoint per brain. The validation seeds pick the winner -- keep your TEST seeds
            apart, or you measure your own choice instead of the brain.
    UNITS : epsilon decays once per Replay() (here every ReplayEvery steps); TargetUpdateFreq counts episodes. The learning
            rate lives in the networks, so it is set when they are created.
.EXAMPLE
    $r = Invoke-VBAFSettingsSearch -NewEnvironment { param($s) New-EnterpriseEnvironment -Name 'AlertRouter' -Seed $s }
    $r.Settings
    Measure-VBAFAgentScore -NewEnvironment { param($s) New-EnterpriseEnvironment -Name 'AlertRouter' -Seed $s } -Agent $r.Agent -Seeds (30001..30010)
#>

$script:VBAFSearchDefaultRanges = @{ LR = @(0.0005, 0.05); Gamma = @(0.8, 0.99); Decay = @(0.99, 0.9995); TUF = @(2, 20) }

function New-VBAFSearchSettings([System.Random]$Rng, $Ranges) {
    $lo = [Math]::Log([double]$Ranges.LR[0]); $hi = [Math]::Log([double]$Ranges.LR[1])
    @{ LR    = [Math]::Exp($lo + $Rng.NextDouble() * ($hi - $lo))
       Gamma = [double]$Ranges.Gamma[0] + $Rng.NextDouble() * ([double]$Ranges.Gamma[1] - [double]$Ranges.Gamma[0])
       Decay = [double]$Ranges.Decay[0] + $Rng.NextDouble() * ([double]$Ranges.Decay[1] - [double]$Ranges.Decay[0])
       TUF   = $Rng.Next([int]$Ranges.TUF[0], [int]$Ranges.TUF[1] + 1) }
}

function New-VBAFSearchBrain([int]$StateSize, [int]$ActionSize, $Settings, [int[]]$Hidden, [int]$Seed) {
    Set-VBAFSeed $Seed
    $cfg = [DQNConfig]::new(); $cfg.StateSize = $StateSize; $cfg.ActionSize = $ActionSize
    $cfg.LearningRate = [double]$Settings.LR; $cfg.Gamma = [double]$Settings.Gamma
    $cfg.EpsilonDecay = [double]$Settings.Decay; $cfg.TargetUpdateFreq = [int]$Settings.TUF
    [int[]]$arch = @($StateSize) + @($Hidden) + @($ActionSize)
    $main = [VBAFNetworkFactory]::Create($arch, $cfg.LearningRate); $tgt = [VBAFNetworkFactory]::Create($arch, $cfg.LearningRate)
    $mem = [ExperienceReplay]::new($cfg.MemorySize)
    $agent = & { [DQNAgent]::new($cfg, $main, $tgt, $mem) } 3>$null 6>$null
    $agent.SetSeed($Seed)
    return $agent
}

# Training episodes use their own seeds (1,000,000 + stream x 1000 + episode), never the validation or test seeds.
function Invoke-VBAFSearchTraining($Agent, [scriptblock]$NewEnvironment, [int]$FirstEpisode, [int]$Episodes, [int]$Stream, [int]$ReplayEvery) {
    for ($k = 0; $k -lt $Episodes; $k++) {
        $s = 1000000 + $Stream * 1000 + $FirstEpisode + $k
        Set-VBAFSeed $s
        $env = & $NewEnvironment $s
        $st = $env.Reset(); $done = $false; $steps = 0; $tot = 0.0
        while (-not $done) {
            $act = $Agent.Act($st); $r = $env.Step($act)
            $Agent.Remember($st, $act, [double]$r.Reward, $r.NextState, [bool]$r.Done)
            $steps++
            if ($steps % $ReplayEvery -eq 0) { & { [void]$Agent.Replay() } 6>$null }
            $st = $r.NextState; $done = [bool]$r.Done; $tot += [double]$r.Reward }
        & { $Agent.EndEpisode($tot) } 6>$null }
}

function Measure-VBAFAgentScore {
    param([Parameter(Mandatory)][scriptblock]$NewEnvironment, [Parameter(Mandatory)]$Agent, [Parameter(Mandatory)][int[]]$Seeds, [int]$MaxSteps = 5000)
    $t = foreach ($s in $Seeds) { Set-VBAFSeed $s; $env = & $NewEnvironment $s
        [double](Get-VBAFTrace -Environment $env -Agent $Agent -MaxSteps $MaxSteps).TotalReward }
    [Math]::Round([double](($t | Measure-Object -Average).Average), 4)
}

function Invoke-VBAFSettingsSearch {
    param(
        [Parameter(Mandatory)][scriptblock]$NewEnvironment,
        [int]$Candidates = 6,
        [int]$Episodes = 150,
        [int]$Rounds = 6,
        [int[]]$ValidationSeeds = @(20001..20020),
        [int]$Seed = 1,
        [int[]]$Hidden = @(16, 16),
        [int]$ReplayEvery = 4,
        [hashtable]$Ranges,
        [switch]$Quiet)
    if ($Candidates -lt 1) { throw 'Invoke-VBAFSettingsSearch: -Candidates must be at least 1' }
    if ($Rounds -lt 1 -or $Episodes -lt $Rounds -or ($Episodes % $Rounds) -ne 0) { throw ("Invoke-VBAFSettingsSearch: -Episodes ($Episodes) must be a multiple of -Rounds ($Rounds)") }
    if (-not $Ranges) { $Ranges = $script:VBAFSearchDefaultRanges }
    $sw = [Diagnostics.Stopwatch]::StartNew()
    Set-VBAFSeed $ValidationSeeds[0]; $probe = & $NewEnvironment $ValidationSeeds[0]
    $nS = @($probe.Reset()).Count; $nA = [int]$probe.ActionSpace.Size
    $rng = [System.Random]::new(1000 * $Seed + 17)
    $per = [int]($Episodes / $Rounds)
    $c = @(for ($i = 0; $i -lt $Candidates; $i++) {
        $set = New-VBAFSearchSettings $rng $Ranges
        [pscustomobject]@{ Index = $i; Settings = $set; Agent = (New-VBAFSearchBrain $nS $nA $set $Hidden (100 * $Seed + $i)); Best = [double]::NegativeInfinity; Snap = $null } })
    for ($r = 1; $r -le $Rounds; $r++) {
        foreach ($x in $c) {
            Invoke-VBAFSearchTraining $x.Agent $NewEnvironment (($r - 1) * $per) $per (100 * $Seed + $x.Index) $ReplayEvery
            $v = Measure-VBAFAgentScore -NewEnvironment $NewEnvironment -Agent $x.Agent -Seeds $ValidationSeeds
            if ($v -gt $x.Best) { $x.Best = $v; $x.Snap = @{ Main = $x.Agent.MainNetwork.ExportState(); Target = $x.Agent.TargetNetwork.ExportState(); Epsilon = $x.Agent.Epsilon } } }
        if (-not $Quiet) { Write-Host ('  round {0}/{1}: best validation so far {2}' -f $r, $Rounds, (($c | ForEach-Object { $_.Best }) | Measure-Object -Maximum).Maximum) } }
    $w = $c | Sort-Object -Property @{ Expression = { $_.Best }; Descending = $true }, @{ Expression = { $_.Index }; Descending = $false } | Select-Object -First 1
    $w.Agent.MainNetwork.ImportState($w.Snap.Main); $w.Agent.TargetNetwork.ImportState($w.Snap.Target); $w.Agent.Epsilon = $w.Snap.Epsilon
    [pscustomobject]@{
        Agent           = $w.Agent
        Settings        = @{ LR = $w.Settings.LR; Gamma = $w.Settings.Gamma; Decay = $w.Settings.Decay; TUF = $w.Settings.TUF }
        ValidationScore = $w.Best
        Candidates      = @($c | ForEach-Object { [pscustomobject]@{ Index = $_.Index; LR = [Math]::Round($_.Settings.LR, 5); Gamma = [Math]::Round($_.Settings.Gamma, 4); Decay = [Math]::Round($_.Settings.Decay, 5); TUF = $_.Settings.TUF; BestValidation = $_.Best } })
        StateSize = $nS; ActionSize = $nA; Episodes = $Episodes; Rounds = $Rounds; ValidationSeeds = $ValidationSeeds
        Seconds = [Math]::Round($sw.Elapsed.TotalSeconds, 1) }
}
