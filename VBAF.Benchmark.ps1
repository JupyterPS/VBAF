#Requires -Version 5.1

<#
.SYNOPSIS
    VBAF Benchmark Module -- Invoke-VBAFAgentBenchmark
.DESCRIPTION
    Compare multiple RL agents side by side on the same environment.
    Outputs a formatted comparison table and optional CSV export.
.NOTES
    Part of VBAF (Visual AI & Reinforcement Learning Framework)
    Phase 6 -- benchmark module.
    ASCII only -- no Unicode, no emoji, no box-drawing characters.
    Requires: VBAF.LoadAll.ps1
#>


function Invoke-VBAFSingleAgentBenchmark {
    param(
        [string]$AgentName,
        [object]$Environment,
        [int]$Episodes,
        [switch]$Silent
    )

    $rewards   = [System.Collections.Generic.List[double]]::new()
    $startTime = Get-Date

    if (-not $Silent) {
        Write-Host "    Running $AgentName for $Episodes episodes..." -ForegroundColor DarkGray
    }

    switch ($AgentName) {
        "DQN" {
            $config              = [DQNConfig]::new()
            $config.StateSize    = $Environment.ObservationSpace.Size
            $config.ActionSize   = $Environment.ActionSpace.Size
            $config.EpsilonDecay = 0.9995
            $config.EpsilonMin   = 0.05
            [int[]] $arch = @($Environment.ObservationSpace.Size, 24, 24, $Environment.ActionSpace.Size)
            $main   = [NeuralNetwork]::new($arch, $config.LearningRate)
            $target = [NeuralNetwork]::new($arch, $config.LearningRate)
            $memory = [ExperienceReplay]::new($config.MemorySize)
            $agent  = [DQNAgent]::new($config, $main, $target, $memory)

            for ($ep = 1; $ep -le $Episodes; $ep++) {
                [double[]] $state = $Environment.Reset()
                $epReward = 0.0
                $step     = 0
                $stepDone = $false

                while (-not $stepDone -and $step -lt 500) {
                    $action          = $agent.Act($state)
                    $sr              = $Environment.Step($action)
                    [double[]] $next = $sr.NextState
                    $agent.Remember($state, $action, $sr.Reward, $next, $sr.Done)
                    if ($step % 4 -eq 0) { $agent.Replay() | Out-Null }
                    $stepDone  = $sr.Done
                    $state     = $next
                    $epReward += $sr.Reward
                    $step++
                }
                $agent.EndEpisode($epReward) | Out-Null
                $rewards.Add($epReward)
            }
        }

        "PPO" {
            $results = Invoke-PPOTraining -Episodes $Episodes -PrintEvery ($Episodes + 1) -FastMode
            if ($results -and $results[-1].PSObject.Properties['EpisodeRewards']) {
                foreach ($r in $results[-1].EpisodeRewards) { $rewards.Add([double]$r) }
            }
        }

        "A3C" {
            $results = Invoke-A3CTraining -Episodes $Episodes -PrintEvery ($Episodes + 1) -FastMode
            if ($results -and $results[-1].PSObject.Properties['EpisodeRewards']) {
                foreach ($r in $results[-1].EpisodeRewards) { $rewards.Add([double]$r) }
            }
        }

        "QLearning" {
            $actionNames = @(0..($Environment.ActionSpace.Size - 1) | ForEach-Object { "$_" })
            $agent       = [QLearningAgent]::new($actionNames)

            for ($ep = 1; $ep -le $Episodes; $ep++) {
                [double[]] $stateArr = $Environment.Reset()
                $stateStr = ($stateArr | ForEach-Object { [Math]::Round($_, 1) }) -join "|"
                $epReward = 0.0
                $step     = 0
                $stepDone = $false

                while (-not $stepDone -and $step -lt 200) {
                    $action          = [int]$agent.ChooseAction($stateStr)
                    $sr              = $Environment.Step($action)
                    [double[]] $nextArr = $sr.NextState
                    $nextStr         = ($nextArr | ForEach-Object { [Math]::Round($_, 1) }) -join "|"
                    $agent.Learn($stateStr, "$action", $sr.Reward, $nextStr)
                    $stateStr  = $nextStr
                    $epReward += $sr.Reward
                    $stepDone  = $sr.Done
                    $step++
                }
                $agent.EndEpisode($epReward)
                $rewards.Add($epReward)
            }
        }
    }

    $elapsed = (Get-Date) - $startTime

    if ($rewards.Count -eq 0) {
        return @{
            Agent = $AgentName; Episodes = $Episodes; Rewards = @()
            Mean = 0.0; Best = 0.0; Worst = 0.0
            First10Avg = 0.0; Last10Avg = 0.0; Improvement = 0.0
            TimeSeconds = $elapsed.TotalSeconds
        }
    }

    $rewardArr   = $rewards.ToArray()
    $mean        = ($rewardArr | Measure-Object -Average).Average
    $best        = ($rewardArr | Measure-Object -Maximum).Maximum
    $worst       = ($rewardArr | Measure-Object -Minimum).Minimum
    $first10     = $rewardArr[0..([Math]::Min(9, $rewardArr.Count - 1))]
    $last10start = [Math]::Max(0, $rewardArr.Count - 10)
    $last10      = $rewardArr[$last10start..($rewardArr.Count - 1)]
    $first10Avg  = ($first10 | Measure-Object -Average).Average
    $last10Avg   = ($last10  | Measure-Object -Average).Average
    $improvement = if ($first10Avg -ne 0) { ($last10Avg - $first10Avg) / [Math]::Abs($first10Avg) * 100 } else { 0.0 }

    return @{
        Agent       = $AgentName
        Episodes    = $Episodes
        Rewards     = $rewardArr
        Mean        = $mean
        Best        = $best
        Worst       = $worst
        First10Avg  = $first10Avg
        Last10Avg   = $last10Avg
        Improvement = $improvement
        TimeSeconds = $elapsed.TotalSeconds
    }
}


function Invoke-VBAFAgentBenchmark {
    param(
        [string]$Environment       = "CartPole",
        [object]$CustomEnvironment = $null,
        [int]$Episodes             = 50,
        [int]$Runs                 = 1,
        [string[]]$Agents          = @("DQN", "PPO", "A3C"),
        [string]$ExportCsv         = "",
        [int]$PrintEvery           = 10
    )

    Write-Host ""
    Write-Host ("=" * 65) -ForegroundColor Cyan
    Write-Host "  VBAF AGENT BENCHMARK" -ForegroundColor Cyan
    Write-Host ("=" * 65) -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Environment : $Environment" -ForegroundColor White
    Write-Host "  Agents      : $($Agents -join ', ')" -ForegroundColor White
    Write-Host "  Episodes    : $Episodes per agent" -ForegroundColor White
    Write-Host "  Runs        : $Runs per agent" -ForegroundColor White
    Write-Host ""

    $env = if ($CustomEnvironment) { $CustomEnvironment } else { New-VBAFEnvironment -Name $Environment -MaxSteps 200 }
    Write-Host "  State size  : $($env.ObservationSpace.Size)" -ForegroundColor DarkGray
    Write-Host "  Action size : $($env.ActionSpace.Size)" -ForegroundColor DarkGray
    Write-Host ""

    $allResults = [System.Collections.Generic.List[hashtable]]::new()
    $csvRows    = [System.Collections.Generic.List[hashtable]]::new()
    $agentNum   = 0

    foreach ($agentName in $Agents) {
        $agentNum++
        Write-Host ("-" * 65) -ForegroundColor Yellow
        Write-Host "  Agent $agentNum/$($Agents.Count) : $agentName" -ForegroundColor Yellow
        Write-Host ("-" * 65) -ForegroundColor Yellow

        $runResults = [System.Collections.Generic.List[hashtable]]::new()

        for ($run = 1; $run -le $Runs; $run++) {
            if ($Runs -gt 1) { Write-Host "    Run $run of $Runs..." -ForegroundColor DarkGray }

            $result = Invoke-VBAFSingleAgentBenchmark -AgentName $agentName -Environment $env -Episodes $Episodes

            $runResults.Add($result)

            Write-Host ("    Mean reward : {0,8:F2}" -f $result.Mean)        -ForegroundColor White
            Write-Host ("    Best reward : {0,8:F2}" -f $result.Best)        -ForegroundColor Green
            Write-Host ("    Worst reward: {0,8:F2}" -f $result.Worst)       -ForegroundColor Red
            Write-Host ("    First 10 avg: {0,8:F2}" -f $result.First10Avg)  -ForegroundColor DarkGray
            Write-Host ("    Last  10 avg: {0,8:F2}" -f $result.Last10Avg)   -ForegroundColor DarkGray
            $impColor = if ($result.Improvement -gt 0) { "Green" } else { "Red" }
            Write-Host ("    Improvement : {0,7:F1}%" -f $result.Improvement) -ForegroundColor $impColor
            Write-Host ("    Time        : {0,7:F1}s" -f $result.TimeSeconds) -ForegroundColor DarkGray
            Write-Host ""

            $csvRows.Add(@{
                Agent = $agentName; Environment = $Environment; Run = $run
                Episodes = $Episodes
                Mean = [Math]::Round($result.Mean, 4)
                Best = [Math]::Round($result.Best, 4)
                Worst = [Math]::Round($result.Worst, 4)
                First10Avg = [Math]::Round($result.First10Avg, 4)
                Last10Avg = [Math]::Round($result.Last10Avg, 4)
                Improvement = [Math]::Round($result.Improvement, 2)
                TimeSeconds = [Math]::Round($result.TimeSeconds, 1)
            })
        }

        $r = $runResults[0]
        $allResults.Add(@{
            Agent    = $agentName
            AvgMean  = ($runResults | ForEach-Object { $_.Mean } | Measure-Object -Average).Average
            AvgImp   = ($runResults | ForEach-Object { $_.Improvement } | Measure-Object -Average).Average
            BestMean = $r.Best
            Runs     = $Runs
        })
    }

    Write-Host ""
    Write-Host ("=" * 65) -ForegroundColor Cyan
    Write-Host "  BENCHMARK RESULTS -- $Environment -- $Episodes episodes" -ForegroundColor Cyan
    Write-Host ("=" * 65) -ForegroundColor Cyan
    Write-Host ""
    Write-Host ("  {0,-12} {1,12} {2,12} {3,12}" -f "Agent", "Avg Reward", "Improvement", "Best Reward") -ForegroundColor Gray
    Write-Host ("  {0,-12} {1,12} {2,12} {3,12}" -f "-----", "----------", "-----------", "-----------") -ForegroundColor DarkGray

    $ranked = $allResults | Sort-Object { $_.AvgMean } -Descending
    $rank   = 1
    foreach ($r in $ranked) {
        $impColor  = if ($r.AvgImp -gt 0) { "Green" } else { "Red" }
        $rankColor = if ($rank -eq 1) { "Yellow" } else { "White" }
        Write-Host -NoNewline ("  [{0}] {1,-10}" -f $rank, $r.Agent) -ForegroundColor $rankColor
        Write-Host -NoNewline ("{0,10:F2}  " -f $r.AvgMean) -ForegroundColor White
        Write-Host -NoNewline ("{0,10:F1}%  " -f $r.AvgImp) -ForegroundColor $impColor
        Write-Host ("{0,10:F2}" -f $r.BestMean) -ForegroundColor Green
        $rank++
    }

    Write-Host ""
    $winner = $ranked[0]
    Write-Host "  Best agent: $($winner.Agent)  Avg: $($winner.AvgMean.ToString('F2'))  Improvement: $($winner.AvgImp.ToString('F1'))%" -ForegroundColor Yellow
    Write-Host ""

    if ($ExportCsv) {
        try {
            $csvRows | ForEach-Object { [PSCustomObject]$_ } | Export-Csv -Path $ExportCsv -NoTypeInformation -Encoding UTF8
            Write-Host "  Results exported to: $ExportCsv" -ForegroundColor Green
        } catch {
            Write-Host "  CSV export failed: $_" -ForegroundColor Red
        }
    }

    return @{ Environment = $Environment; Episodes = $Episodes; Results = $allResults; Winner = $winner.Agent }
}


function Invoke-VBAFQuickBenchmark {
    param(
        [string]$AgentName   = "DQN",
        [string]$Environment = "CartPole",
        [int]$Episodes       = 50
    )

    Write-Host ""
    Write-Host ("=" * 65) -ForegroundColor Cyan
    Write-Host "  VBAF QUICK BENCHMARK: $AgentName vs Random on $Environment" -ForegroundColor Cyan
    Write-Host ("=" * 65) -ForegroundColor Cyan
    Write-Host ""

    $env = New-VBAFEnvironment -Name $Environment -MaxSteps 200

    Write-Host "  Phase 1: Random agent baseline..." -ForegroundColor Gray
    $baseRewards = @()
    for ($ep = 1; $ep -le 10; $ep++) {
        [double[]] $state = $env.Reset()
        $epReward = 0.0
        $stepDone = $false
        $step     = 0
        while (-not $stepDone -and $step -lt 200) {
            $sr        = $env.Step((Get-Random -Minimum 0 -Maximum $env.ActionSpace.Size))
            $epReward += $sr.Reward
            $stepDone  = $sr.Done
            $step++
        }
        $baseRewards += $epReward
    }
    $baseAvg = ($baseRewards | Measure-Object -Average).Average
    Write-Host ("  Baseline avg reward (10 episodes): {0:F2}" -f $baseAvg) -ForegroundColor Gray
    Write-Host ""

    Write-Host "  Phase 2: Training $AgentName for $Episodes episodes..." -ForegroundColor Yellow
    $result = Invoke-VBAFSingleAgentBenchmark -AgentName $AgentName -Environment $env -Episodes $Episodes -Silent

    Write-Host ""
    Write-Host ("=" * 65) -ForegroundColor Cyan
    Write-Host "  QUICK BENCHMARK RESULTS" -ForegroundColor Cyan
    Write-Host ("=" * 65) -ForegroundColor Cyan
    Write-Host ""
    Write-Host ("  Random baseline avg  : {0,8:F2}" -f $baseAvg)       -ForegroundColor Gray
    Write-Host ("  $AgentName trained avg    : {0,8:F2}" -f $result.Mean) -ForegroundColor White

    $totalImp = if ($baseAvg -ne 0) { ($result.Mean - $baseAvg) / [Math]::Abs($baseAvg) * 100 } else { 0.0 }
    $impColor = if ($totalImp -gt 0) { "Green" } else { "Red" }
    Write-Host ("  Improvement vs random: {0,7:F1}%" -f $totalImp)          -ForegroundColor $impColor
    Write-Host ("  Learning improvement : {0,7:F1}%" -f $result.Improvement) -ForegroundColor $impColor
    Write-Host ""

    if ($totalImp -gt 10) {
        Write-Host "  $AgentName successfully outperformed random baseline." -ForegroundColor Green
    } elseif ($totalImp -gt 0) {
        Write-Host "  $AgentName slightly better than random. Try more episodes." -ForegroundColor Yellow
    } else {
        Write-Host "  $AgentName did not outperform random. Try more episodes." -ForegroundColor Red
    }

    Write-Host ""
    return @{ Agent = $AgentName; Baseline = $baseAvg; Trained = $result.Mean; Improvement = $totalImp; Result = $result }
}
