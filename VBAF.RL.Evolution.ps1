#Requires -Version 5.1
<#
.SYNOPSIS
    Build, train and evolve a learning brain (DQN): "build a better brain" (VBAF v6.0).
.DESCRIPTION
    New-VBAFBrainConfig, New-VBAFBrain and Invoke-VBAFBrainTraining build and train a seeded DQN brain.
    Invoke-VBAFEvolution evolves genomes (learning rate, batch size, replay frequency, epsilon, ...):
      - fitness = mean over several brain seeds of each seed's BEST moment on the validation shifts
        (one seed is not a result -- shown in VBAF-Evolution-Lab phase 4b);
      - every candidate trains for the same fixed number of shifts; the best checkpoint is kept;
      - every run is saved at once and is resumable (long runs survive a restart);
      - Invoke-VBAFFinalTest trains the champion AND a control (the baseline genome) on new seeds and
        measures both on the test shifts, so genome gain and checkpoint gain can be told apart.
    Proven in VBAF-Evolution-Lab phase 4c: champion 39.39 +/- 0.37 vs control 37.17 +/- 1.64 (bar 39.17).
    The world is a parameter; seeds and the measurer come from VBAF.RL.ProductionCell.ps1.
#>
function New-VBAFBrainConfig {
    param(
        [int[]]  $HiddenLayers     = @(16),
        [double] $LearningRate     = 0.01,
        [double] $Gamma            = 0.95,
        [double] $EpsilonDecay     = 0.995,
        [double] $EpsilonMin       = 0.05,
        [int]    $BatchSize        = 16,
        [int]    $MemorySize       = 5000,
        [int]    $TargetUpdateFreq = 5
    )
    $c = [DQNConfig]::new()
    $c.StateSize        = 11
    $c.ActionSize       = 3
    $c.HiddenLayers     = [int[]]$HiddenLayers
    $c.LearningRate     = $LearningRate
    $c.Gamma            = $Gamma
    $c.Epsilon          = 1.0
    $c.EpsilonDecay     = $EpsilonDecay
    $c.EpsilonMin       = $EpsilonMin
    $c.BatchSize        = $BatchSize
    $c.MemorySize       = $MemorySize
    $c.TargetUpdateFreq = $TargetUpdateFreq
    return $c
}

# A network: hidden layers $HiddenActivation, output $OutputActivation.
# -Seed >= 0 gives the same starting weights every time (constructor NeuralNetwork(arch, lr, seed)).
function New-VBAFBrainNetwork {
    param([int[]]$Architecture, [double]$LearningRate,
          [string]$HiddenActivation = 'Sigmoid', [string]$OutputActivation = 'Linear', [int]$Seed = -1)
    if ($Seed -ge 0) { $net = [VBAFNetworkFactory]::Create([int[]]$Architecture, [double]$LearningRate, [int]$Seed) }
    else             { $net = [VBAFNetworkFactory]::Create([int[]]$Architecture, [double]$LearningRate) }
    for ($i = 0; $i -lt $net.Layers.Count - 1; $i++) { $net.Layers[$i].ActivationType = $HiddenActivation }
    $net.SetOutputActivation($OutputActivation)
    return $net
}

# A complete, reproducible brain built from its config (the genome).
# Three separate seeded generators: network weights, replay sampling, exploration.
function New-VBAFBrain {
    param($Config, [int]$Seed)
    $arch   = [int[]](@($Config.StateSize) + @($Config.HiddenLayers) + @($Config.ActionSize))
    $main   = New-VBAFBrainNetwork -Architecture $arch -LearningRate $Config.LearningRate -Seed $Seed
    $target = New-VBAFBrainNetwork -Architecture $arch -LearningRate $Config.LearningRate -Seed ($Seed + 1000000)
    $mem    = [ExperienceReplay]::new([int]$Config.MemorySize, [int]($Seed + 2000000))
    $agent  = & { [DQNAgent]::new($Config, $main, $target, $mem) } 6>$null
    $agent.SetSeed($Seed + 3000000)
    return $agent
}

# Train a brain on N shifts (training seeds SeedBase .. SeedBase+N-1).
function Invoke-VBAFBrainTraining {
    param($Agent, $World, [int]$Episodes, [int]$ReplayEvery = 4, [int]$SeedBase = 1, [switch]$Quiet)
    $rows = for ($ep = 1; $ep -le $Episodes; $ep++) {
        $sw    = [System.Diagnostics.Stopwatch]::StartNew()
        $state = $World.ResetWithSeed($SeedBase + $ep - 1)
        $done  = $false
        $n     = 0
        while (-not $done) {
            $a = $Agent.Act($state)
            $r = $World.Step($a)
            $Agent.Remember($state, $a, [double]$r.Reward, $r.NextState, [bool]$r.Done)
            $n++
            if ($n % $ReplayEvery -eq 0) { [void]$Agent.Replay() }
            $state = $r.NextState
            $done  = $r.Done
        }
        $st = $World.GetShiftStats()
        $null = & { $Agent.EndEpisode([double]$st.TotalReward) } 6>$null
        $sw.Stop()
        $row = [pscustomobject]@{
            Episode = $ep; Reward = $st.TotalReward; OnTimePct = $st.OnTimePct
            Epsilon = [Math]::Round($Agent.Epsilon, 3); Steps = $n
            Seconds = [Math]::Round($sw.Elapsed.TotalSeconds, 1)
        }
        if (-not $Quiet) {
            Write-Host ("  Episode {0,4}  reward {1,7}  on-time {2,5}%  epsilon {3,5}  {4,5}s" -f `
                $row.Episode, $row.Reward, $row.OnTimePct, $row.Epsilon, $row.Seconds) -ForegroundColor DarkGray
        }
        $row
    }
    return $rows
}

# Greedy policy (no exploration) for the measurer.
function Get-VBAFBrainPolicy {
    param($Agent)
    $a = $Agent
    return { param($s, $rng) $a.Predict($s) }.GetNewClosure()
}

# Sum of absolute values of every number in the network state: changes iff weights change.
function Get-VBAFNetChecksum {
    param($Network)
    $j = $Network.ExportState() | ConvertTo-Json -Depth 8 -Compress
    $sum = 0.0
    foreach ($m in [regex]::Matches($j, '-?\d+(\.\d+)?([Ee][-+]?\d+)?')) { $sum += [Math]::Abs([double]$m.Value) }
    return [Math]::Round($sum, 6)
}

function Get-VBAFGeneSpace {
    $g = [ordered]@{}
    $g['Hidden']           = @('8', '16', '32', '16-16')
    $g['LearningRate']     = @(0.003, 0.01, 0.03)
    $g['Gamma']            = @(0.8, 0.9, 0.95, 0.99)
    $g['EpsilonDecay']     = @(0.99, 0.995, 0.998, 0.999, 0.9995)
    $g['EpsilonMin']       = @(0.01, 0.05, 0.1)
    $g['BatchSize']        = @(16, 32)
    $g['TargetUpdateFreq'] = @(2, 5, 10)
    $g['ReplayEvery']      = @(2, 4, 8)
    return $g
}

function Get-VBAFBaselineGenome {
    return [ordered]@{ Hidden = '16'; LearningRate = 0.01; Gamma = 0.95; EpsilonDecay = 0.995; EpsilonMin = 0.05
                       BatchSize = 16; TargetUpdateFreq = 5; ReplayEvery = 4 }
}

function ConvertTo-VBAFGenome {
    param($Object)
    $h = [ordered]@{}
    foreach ($k in (Get-VBAFGeneSpace).Keys) { $h[$k] = $Object.$k }
    return $h
}

function Get-VBAFGenomeKey {
    param($Genome)
    return (@((Get-VBAFGeneSpace).Keys) | ForEach-Object { "$_=$($Genome.$_)" }) -join ';'
}

# Copy the parent and change 1 or 2 randomly chosen genes to another allowed value.
function New-VBAFMutant {
    param($Parent, [System.Random]$Rng)
    $space = Get-VBAFGeneSpace
    $names = @($space.Keys)
    $child = ConvertTo-VBAFGenome $Parent
    $n = $Rng.Next(1, 3)
    $picked = @()
    while ($picked.Count -lt $n) {
        $k = $names[$Rng.Next(0, $names.Count)]
        if ($picked -notcontains $k) { $picked += $k }
    }
    foreach ($k in $picked) {
        $opts = @($space[$k] | Where-Object { "$_" -ne "$($child[$k])" })
        $child[$k] = $opts[$Rng.Next(0, $opts.Count)]
    }
    return $child
}

function New-VBAFConfigFromGenome {
    param($Genome)
    $hidden = [int[]]@("$($Genome.Hidden)".Split('-') | ForEach-Object { [int]$_ })
    return New-VBAFBrainConfig -HiddenLayers $hidden -LearningRate ([double]$Genome.LearningRate) `
        -Gamma ([double]$Genome.Gamma) -EpsilonDecay ([double]$Genome.EpsilonDecay) -EpsilonMin ([double]$Genome.EpsilonMin) `
        -BatchSize ([int]$Genome.BatchSize) -TargetUpdateFreq ([int]$Genome.TargetUpdateFreq)
}

function Restore-VBAFBrain {
    param($Genome, [int]$BrainSeed, [string]$ModelPath)
    $brain = New-VBAFBrain -Config (New-VBAFConfigFromGenome $Genome) -Seed $BrainSeed
    [void]$brain.MainNetwork.ImportState((Import-Clixml -Path $ModelPath))
    [void]$brain.SyncTargetNetwork()
    return $brain
}

# ONE training run: one genome, one brain seed. Checkpoint = best validation moment. Saved at once; resumable.
function Invoke-VBAFEvolutionRun {
    param([string]$RunId, $Genome, [int]$BrainSeed, $World, [int]$TrainShifts, [int]$Chunk, [int[]]$ValSeeds, [string]$OutDir)
    $json  = Join-Path $OutDir "$RunId.json"
    $model = Join-Path $OutDir "$RunId-best.xml"
    if ((Test-Path $json) -and (Test-Path $model)) {
        $r = Get-Content $json -Raw -Encoding UTF8 | ConvertFrom-Json
        $r | Add-Member -NotePropertyName Resumed -NotePropertyValue $true -Force
        return $r
    }
    $swT = New-Object System.Diagnostics.Stopwatch; $swV = New-Object System.Diagnostics.Stopwatch
    $brain  = New-VBAFBrain -Config (New-VBAFConfigFromGenome $Genome) -Seed $BrainSeed
    $policy = Get-VBAFBrainPolicy -Agent $brain
    $best = [double]::MinValue; $bestAt = 0; $curve = @()
    for ($t = 0; $t -lt $TrainShifts; $t += $Chunk) {
        $swT.Start()
        $null = Invoke-VBAFBrainTraining -Agent $brain -World $World -Episodes $Chunk -ReplayEvery ([int]$Genome.ReplayEvery) -SeedBase (1 + $t) -Quiet
        $swT.Stop(); $swV.Start()
        $v = (Measure-VBAFProductionPolicy -World $World -Policy $policy -Seeds $ValSeeds).Score
        $swV.Stop()
        $curve += [pscustomobject]@{ Shifts = $t + $Chunk; ValScore = $v }
        if ($v -gt $best) { $best = $v; $bestAt = $t + $Chunk; $brain.MainNetwork.ExportState() | Export-Clixml -Path $model -Depth 10 }
    }
    $res = [pscustomobject]@{
        RunId = $RunId; BrainSeed = $BrainSeed; Genome = [pscustomobject]$Genome; Key = (Get-VBAFGenomeKey $Genome)
        TrainShifts = $TrainShifts; Chunk = $Chunk; BestValScore = $best; BestAtShift = $bestAt; FinalValScore = $curve[-1].ValScore
        Curve = $curve; TrainSeconds = [Math]::Round($swT.Elapsed.TotalSeconds, 1); ValSeconds = [Math]::Round($swV.Elapsed.TotalSeconds, 1)
        ValMeasurements = $curve.Count; ModelPath = $model; Resumed = $false
    }
    $res | ConvertTo-Json -Depth 6 | Set-Content -Path $json -Encoding UTF8
    return $res
}

# A candidate genome: one run per fitness seed; fitness = mean of the runs' best validation scores.
function Invoke-VBAFEvolutionCandidate {
    param([string]$Id, [int]$Generation, [string]$Parent, $Genome, $World, [int[]]$FitSeeds,
          [int]$TrainShifts, [int]$Chunk, [int[]]$ValSeeds, [string]$OutDir)
    $runs = @(foreach ($s in $FitSeeds) {
        Invoke-VBAFEvolutionRun -RunId ('{0}-s{1}' -f $Id, $s) -Genome $Genome -BrainSeed $s -World $World `
            -TrainShifts $TrainShifts -Chunk $Chunk -ValSeeds $ValSeeds -OutDir $OutDir
    })
    $x = @($runs | ForEach-Object { [double]$_.BestValScore })
    $mean = ($x | Measure-Object -Average).Average
    $sd = 0.0
    if ($x.Count -gt 1) { $sd = [Math]::Sqrt((($x | ForEach-Object { ($_ - $mean) * ($_ - $mean) }) | Measure-Object -Sum).Sum / ($x.Count - 1)) }
    return [pscustomobject]@{
        Id = $Id; Generation = $Generation; Parent = $Parent; Genome = [pscustomobject]$Genome; Key = (Get-VBAFGenomeKey $Genome)
        Fitness = [Math]::Round($mean, 2); FitnessSD = [Math]::Round($sd, 2); RunScores = ($x -join ' / '); Runs = $runs
        Resumed = (@($runs | Where-Object { -not $_.Resumed }).Count -eq 0)
        Seconds = [Math]::Round((@($runs | ForEach-Object { [double]$_.TrainSeconds + [double]$_.ValSeconds }) | Measure-Object -Sum).Sum, 1)
    }
}

function Select-VBAFChampion {
    param($All)
    return @($All | Sort-Object -Property @{ Expression = 'Fitness'; Descending = $true }, @{ Expression = 'Id'; Descending = $false })[0]
}

# The loop: generation 0 = Brain 1 genome + mutants; then mutate the champion each generation.
function Invoke-VBAFEvolution {
    param($World, [int]$Generations = 3, [int]$Children = 3, [int[]]$FitSeeds = @(101, 102, 103),
          [int]$TrainShifts = 300, [int]$Chunk = 25, [int]$Seed = 2026, [string]$OutDir, [string]$LogPath)
    New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
    $val   = Get-VBAFProductionValidationSeeds
    $all   = [System.Collections.Generic.List[object]]::new()
    $tried = @{}
    $log = { param($msg)
        $line = '{0}  {1}' -f (Get-Date -Format 'HH:mm:ss'), $msg
        Write-Host $line
        Add-Content -Path $LogPath -Value $line -Encoding ASCII }
    & $log ('Evolution 4c: {0} generations x {1} children, fitness = mean of {2} brain seeds ({3}), {4} training shifts each' -f $Generations, $Children, $FitSeeds.Count, ($FitSeeds -join ','), $TrainShifts)
    $champGenome = Get-VBAFBaselineGenome
    $champId     = 'G0-0'
    for ($g = 0; $g -lt $Generations; $g++) {
        $rng   = [System.Random]::new($Seed + $g)
        $batch = @()
        if ($g -eq 0) { $batch += , @('G0-0', 'Brain 1', $champGenome) }
        $tried[(Get-VBAFGenomeKey $champGenome)] = $true
        for ($c = 1; $c -le $Children; $c++) {
            $m = $null
            for ($try = 0; $try -lt 20; $try++) {
                $cand = New-VBAFMutant -Parent $champGenome -Rng $rng
                if (-not $tried.ContainsKey((Get-VBAFGenomeKey $cand))) { $m = $cand; break }
            }
            if ($m) { $tried[(Get-VBAFGenomeKey $m)] = $true; $batch += , @("G$g-$c", $champId, $m) }
        }
        foreach ($b in $batch) {
            $res = Invoke-VBAFEvolutionCandidate -Id $b[0] -Generation $g -Parent $b[1] -Genome $b[2] -World $World -FitSeeds $FitSeeds `
                -TrainShifts $TrainShifts -Chunk $Chunk -ValSeeds $val -OutDir $OutDir
            $all.Add($res)
            $tag = ''; if ($res.Resumed) { $tag = ' (resumed)' }
            & $log ('  {0,-5} parent {1,-7} fitness {2,6} +/- {3,5}  [{4}]  {5,7} s  {6}{7}' -f $res.Id, $res.Parent, $res.Fitness, $res.FitnessSD, $res.RunScores, $res.Seconds, $res.Key, $tag)
        }
        $champ       = Select-VBAFChampion $all
        $champId     = $champ.Id
        $champGenome = ConvertTo-VBAFGenome $champ.Genome
        & $log ('Generation {0} champion: {1} (fitness {2} +/- {3})' -f $g, $champ.Id, $champ.Fitness, $champ.FitnessSD)
    }
    return $all
}

# Final test of one genome: train on NEW seeds (same procedure), restore the checkpoint, measure on the test set.
function Invoke-VBAFFinalTest {
    param($World, $Genome, [string]$Label, [int[]]$FinalSeeds, [int]$TrainShifts, [int]$Chunk, [string]$OutDir, [int[]]$TestSeeds)
    $val = Get-VBAFProductionValidationSeeds
    $rows = foreach ($s in $FinalSeeds) {
        $r = Invoke-VBAFEvolutionRun -RunId ('final-{0}-s{1}' -f $Label, $s) -Genome $Genome -BrainSeed $s -World $World `
            -TrainShifts $TrainShifts -Chunk $Chunk -ValSeeds $val -OutDir $OutDir
        $brain = Restore-VBAFBrain -Genome $Genome -BrainSeed $s -ModelPath $r.ModelPath
        $m = Measure-VBAFProductionPolicy -World $World -Policy (Get-VBAFBrainPolicy -Agent $brain) -Seeds $TestSeeds
        [pscustomobject]@{ Label = $Label; Seed = $s; ValBest = $r.BestValScore; BestAt = $r.BestAtShift
                           TestScore = $m.Score; OnTimePct = $m.OnTimePct; PerSeed = $m.PerSeed
                           TrainSeconds = $r.TrainSeconds; ValSeconds = $r.ValSeconds; ValMeasurements = $r.ValMeasurements; TrainShifts = $r.TrainShifts }
    }
    return @($rows)
}

# ---------- v6.0: the whole study in one call (was the Lab's experiments\Phase4c-Evolution.ps1) ----------
# Evolution -> champion -> final test of the champion AND a control (the baseline genome) on NEW seeds ->
# Brain 0 (SPT) on the same test shifts -> one file, evolution-summary.json (same layout as the Lab's phase4c.json,
# plus Settings). -Bar is an optional, PRE-REGISTERED success criterion; it is written only when given.
# Defaults are the Lab's phase 4c settings (3 generations x 3 children, 3 fitness seeds, 300 shifts, 5 final seeds).
# Every run is saved at once in -OutDir, so an interrupted study resumes where it stopped.
function Get-VBAFEvolutionStats($Values) {
    $x = @($Values | ForEach-Object { [double]$_ })
    $m = ($x | Measure-Object -Average).Average
    $s = 0.0
    if ($x.Count -gt 1) { $s = [Math]::Sqrt((($x | ForEach-Object { ($_ - $m) * ($_ - $m) }) | Measure-Object -Sum).Sum / ($x.Count - 1)) }
    return [pscustomobject]@{ Mean = [Math]::Round($m, 2); SD = [Math]::Round($s, 2) }
}
function Invoke-VBAFEvolutionStudy {
    param($World, [string]$OutDir, [int]$Generations = 3, [int]$Children = 3, [int[]]$FitSeeds = @(101, 102, 103),
          [int]$TrainShifts = 300, [int]$Chunk = 25, [int[]]$FinalSeeds = @(201, 202, 203, 204, 205), [double]$Bar = [double]::NaN)
    if (-not $OutDir) { throw 'Invoke-VBAFEvolutionStudy: -OutDir is required (every run is saved there, so the study is resumable).' }
    New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $all   = Invoke-VBAFEvolution -World $World -Generations $Generations -Children $Children -FitSeeds $FitSeeds -TrainShifts $TrainShifts -Chunk $Chunk -OutDir $OutDir -LogPath (Join-Path $OutDir 'evolution.log')
    $champ = Select-VBAFChampion $all
    $cg    = ConvertTo-VBAFGenome $champ.Genome
    $bg    = Get-VBAFBaselineGenome
    $test  = Get-VBAFProductionTestSeeds
    $fc = Invoke-VBAFFinalTest -World $World -Genome $cg -Label 'champion' -FinalSeeds $FinalSeeds -TrainShifts $TrainShifts -Chunk $Chunk -OutDir $OutDir -TestSeeds $test
    $fk = Invoke-VBAFFinalTest -World $World -Genome $bg -Label 'control'  -FinalSeeds $FinalSeeds -TrainShifts $TrainShifts -Chunk $Chunk -OutDir $OutDir -TestSeeds $test
    $b0 = Measure-VBAFProductionPolicy -World $World -Policy (Get-VBAFProductionRules)['SPT'].Policy -Seeds $test
    $cs = Get-VBAFEvolutionStats ($fc | ForEach-Object { $_.TestScore })
    $ks = Get-VBAFEvolutionStats ($fk | ForEach-Object { $_.TestScore })
    $pairWins = @(for ($i = 0; $i -lt $fc.Count; $i++) { if ([double]$fc[$i].TestScore -gt [double]$fk[$i].TestScore) { 1 } }).Count
    $barOut = $null; if (-not [double]::IsNaN($Bar)) { $barOut = $Bar }
    $summary = [pscustomobject]@{
        Kernel = 'VBAF v6.0'; Champion = $champ.Id; ChampionGenome = $champ.Genome; ChampionFitness = $champ.Fitness; ChampionFitnessSD = $champ.FitnessSD
        FinalSeeds = $FinalSeeds; ChampionTest = $cs; ControlTest = $ks; Brain0 = $b0.Score; Bar = $barOut; PairWins = $pairWins
        Lineage = @($all | Select-Object Id, Generation, Parent, Fitness, FitnessSD, RunScores, Seconds, Key)
        Final = @(($fc + $fk) | Select-Object Label, Seed, ValBest, BestAt, TestScore, OnTimePct)
        Settings = [pscustomobject]@{ Generations = $Generations; Children = $Children; FitSeeds = $FitSeeds; TrainShifts = $TrainShifts; Chunk = $Chunk }
        Minutes = [Math]::Round($sw.Elapsed.TotalMinutes, 1); Date = (Get-Date -Format 'yyyy-MM-dd') }
    $summary | ConvertTo-Json -Depth 6 | Set-Content -Path (Join-Path $OutDir 'evolution-summary.json') -Encoding UTF8
    return $summary
}
