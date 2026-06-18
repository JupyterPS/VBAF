 #Requires -Version 5.1

<#
.SYNOPSIS
    VBAF Playground -- Start-VBAFPlayground
.DESCRIPTION
    Interactive console menu where a student picks an algorithm,
    configures it, watches it train, and sees the results.
    No coding required -- everything driven by menu choices.

    WHAT YOU ARE LEARNING HERE:
    ============================
    The Playground is a guided experiment station.
    It lets you explore the effect of hyperparameters
    without writing any code.

    You will see firsthand how these settings change outcomes:
      - Learning rate: too high = unstable, too low = slow
      - Epsilon decay: too fast = premature convergence
      - Episodes: more = better policy (usually)
      - Architecture: more neurons = more capacity

    HOW TO USE:
    ===========
    . .\VBAF.LoadAll.ps1
    Start-VBAFPlayground                  -- full interactive menu
    Start-VBAFPlayground -Algorithm "DQN" -- skip to DQN directly
    Start-VBAFPlayground -Algorithm "QLearning"
    Start-VBAFPlayground -Algorithm "Enterprise"
    Start-VBAFPlayground -Algorithm "Supervised"

.NOTES
    Part of VBAF (Visual AI & Reinforcement Learning Framework)
    Phase 7 -- interactive playground.
    ASCII only -- no Unicode, no emoji, no box-drawing characters.
    Requires: VBAF.LoadAll.ps1
#>


# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Write-PlayHeader {
    param([string]$Title)
    Write-Host ""
    Write-Host ("=" * 65) -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host ("=" * 65) -ForegroundColor Cyan
    Write-Host ""
}

function Write-PlaySection {
    param([string]$Title)
    Write-Host ""
    Write-Host "  -- $Title --" -ForegroundColor Yellow
    Write-Host ""
}

function Read-PlayChoice {
    param([string]$Prompt, [string[]]$Options)
    Write-Host ""
    for ($i = 0; $i -lt $Options.Count; $i++) {
        Write-Host "  [$($i+1)] $($Options[$i])" -ForegroundColor White
    }
    Write-Host ""
    do {
        $input = Read-Host "  $Prompt"
        $idx   = 0
        $valid = [int]::TryParse($input, [ref]$idx) -and $idx -ge 1 -and $idx -le $Options.Count
        if (-not $valid) {
            Write-Host "  Please enter a number between 1 and $($Options.Count)" -ForegroundColor Red
        }
    } while (-not $valid)
    return $idx - 1
}

function Read-PlayInt {
    param([string]$Prompt, [int]$Default, [int]$Min, [int]$Max)
    Write-Host ""
    do {
        $raw   = Read-Host "  $Prompt (default: $Default, range: $Min-$Max)"
        if ($raw -eq "") { return $Default }
        $val   = 0
        $valid = [int]::TryParse($raw, [ref]$val) -and $val -ge $Min -and $val -le $Max
        if (-not $valid) {
            Write-Host "  Please enter a number between $Min and $Max" -ForegroundColor Red
        }
    } while (-not $valid)
    return $val
}

function Read-PlayDouble {
    param([string]$Prompt, [double]$Default)
    Write-Host ""
    $raw = Read-Host "  $Prompt (default: $Default)"
    if ($raw -eq "") { return $Default }
    $val = 0.0
    if ([double]::TryParse($raw, [ref]$val)) { return $val }
    return $Default
}

function Write-PlayResult {
    param([string]$Label, [double]$Value, [string]$Unit = "", [string]$Color = "White")
    Write-Host ("  {0,-30} {1,10:F2}{2}" -f $Label, $Value, $Unit) -ForegroundColor $Color
}


# ============================================================================
# PLAYGROUND 1 -- DQN EXPERIMENT
# ============================================================================

function Play-DQN {
    Write-PlayHeader "PLAYGROUND: DEEP Q-NETWORK (DQN)"

    Write-Host "  Train a DQN agent and watch it learn." -ForegroundColor Gray
    Write-Host "  Experiment with hyperparameters to see their effect." -ForegroundColor Gray

    Write-PlaySection "Step 1: Choose Your Environment"
    $envChoice = Read-PlayChoice "Pick environment" @(
        "CartPole    -- balance a pole on a cart (classic RL benchmark)"
        "GridWorld   -- navigate a grid to reach a goal"
        "RandomWalk  -- simple 1D random walk"
    )
    $envName = @("CartPole", "GridWorld", "RandomWalk")[$envChoice]
    Write-Host "  Selected: $envName" -ForegroundColor Green

    Write-PlaySection "Step 2: Configure Training"
    $episodes   = Read-PlayInt    "Number of episodes"  50  10  500
    $printEvery = Read-PlayInt    "Print progress every N episodes" 10 1 50

    Write-PlaySection "Step 3: Configure Hyperparameters"
    Write-Host "  Press Enter to accept defaults (recommended for first run)." -ForegroundColor DarkGray

    $lrChoice = Read-PlayChoice "Learning rate" @(
        "0.001  -- default, stable"
        "0.01   -- faster but less stable"
        "0.0001 -- very slow, very stable"
        "Custom -- enter your own"
    )
    $lr = switch ($lrChoice) {
        0 { 0.001 }
        1 { 0.01  }
        2 { 0.0001 }
        3 { Read-PlayDouble "Enter learning rate" 0.001 }
    }

    $epsDecayChoice = Read-PlayChoice "Epsilon decay speed" @(
        "0.9995 -- default, gradual decay"
        "0.999  -- faster decay, less exploration"
        "0.9999 -- slower decay, more exploration"
    )
    $epsDecay = @(0.9995, 0.999, 0.9999)[$epsDecayChoice]

    $archChoice = Read-PlayChoice "Network architecture" @(
        "[4, 24, 24, 4] -- default, two hidden layers of 24"
        "[4, 64, 64, 4] -- larger, more capacity"
        "[4, 12, 12, 4] -- smaller, faster training"
    )

    Write-PlaySection "Step 4: Training"
    Write-Host "  Environment  : $envName" -ForegroundColor White
    Write-Host "  Episodes     : $episodes" -ForegroundColor White
    Write-Host "  Learning rate: $lr" -ForegroundColor White
    Write-Host "  Epsilon decay: $epsDecay" -ForegroundColor White
    Write-Host ""
    Write-Host "  Starting training..." -ForegroundColor Yellow
    Write-Host ""

    $startTime = Get-Date

    # Build config
    $config              = [DQNConfig]::new()
    $config.LearningRate = $lr
    $config.EpsilonDecay = $epsDecay
    $config.EpsilonMin   = 0.05

    [int[]] $arch = switch ($archChoice) {
        0 { @(4, 24, 24, 4) }
        1 { @(4, 64, 64, 4) }
        2 { @(4, 12, 12, 4) }
    }

    $main   = [NeuralNetwork]::new($arch, $config.LearningRate)
    $target = [NeuralNetwork]::new($arch, $config.LearningRate)
    $memory = [ExperienceReplay]::new($config.MemorySize)
    $agent  = [DQNAgent]::new($config, $main, $target, $memory)

    # Use built-in training
    $results = Invoke-DQNTraining -Episodes $episodes -PrintEvery $printEvery -FastMode
    $trained = $results[-1]

    $elapsed = (Get-Date) - $startTime

    Write-PlaySection "Step 5: Results"
    $trained.PrintStats()

    Write-Host ""
    Write-Host ("  Training time: {0:F1} seconds" -f $elapsed.TotalSeconds) -ForegroundColor DarkGray

    Write-PlaySection "What Did You Learn?"
    Write-Host "  - Higher learning rate: faster early progress, less stable later" -ForegroundColor DarkGray
    Write-Host "  - Faster epsilon decay: agent commits to strategy sooner" -ForegroundColor DarkGray
    Write-Host "  - Larger network: more capacity, slower training" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Try again with different settings and compare the results!" -ForegroundColor Yellow
    Write-Host ""
}


# ============================================================================
# PLAYGROUND 2 -- Q-LEARNING EXPERIMENT
# ============================================================================

function Play-QLearning {
    Write-PlayHeader "PLAYGROUND: Q-LEARNING"

    Write-Host "  Train a Q-learning agent on the Castle problem." -ForegroundColor Gray
    Write-Host "  Watch the Q-table grow as the agent learns." -ForegroundColor Gray

    Write-PlaySection "Step 1: Configure Training"
    $episodes       = Read-PlayInt "Number of episodes" 100 10 1000
    $stepsPerEp     = Read-PlayInt "Steps per episode"  10  5  50

    Write-PlaySection "Step 2: Configure Hyperparameters"
    $alphaChoice = Read-PlayChoice "Alpha (learning rate)" @(
        "0.1  -- default, moderate updates"
        "0.5  -- faster learning, less smooth"
        "0.01 -- very slow, very stable"
    )
    $alpha = @(0.1, 0.5, 0.01)[$alphaChoice]

    $gammaChoice = Read-PlayChoice "Gamma (discount factor)" @(
        "0.9  -- default, values future rewards highly"
        "0.5  -- short-sighted, focuses on immediate reward"
        "0.99 -- far-sighted, plans many steps ahead"
    )
    $gamma = @(0.9, 0.5, 0.99)[$gammaChoice]

    Write-PlaySection "Step 3: Training"
    Write-Host "  Episodes        : $episodes" -ForegroundColor White
    Write-Host "  Steps/episode   : $stepsPerEp" -ForegroundColor White
    Write-Host "  Alpha           : $alpha" -ForegroundColor White
    Write-Host "  Gamma           : $gamma" -ForegroundColor White
    Write-Host ""
    Write-Host "  Starting training..." -ForegroundColor Yellow
    Write-Host ""

    $castleTypes   = @("Gothic","FairyTale","Fortress","Palace","Wizard","Cathedral","Oriental","Ruins")
    $agent         = [QLearningAgent]::new($castleTypes)
    $agent.Alpha   = $alpha
    $agent.Gamma   = $gamma
    $recentCastles = New-Object System.Collections.ArrayList

    $startTime = Get-Date

    for ($ep = 1; $ep -le $episodes; $ep++) {
        $episodeReward = 0.0
        for ($step = 1; $step -le $stepsPerEp; $step++) {
            $context  = @{ RecentTypes = $recentCastles }
            $state    = $agent.GetState($context)
            $action   = $agent.ChooseAction($state)
            $isVaried = ($recentCastles.Count -eq 0) -or ($recentCastles[-1] -ne $action)
            $outcome  = @{
                CastleType    = $action
                IsVaried      = $isVaried
                VisualBalance = Get-Random -Minimum 0.0 -Maximum 1.0
                Engagement    = Get-Random -Minimum 0.0 -Maximum 1.0
            }
            $reward        = $agent.CalculateReward($outcome)
            $episodeReward += $reward
            $recentCastles.Add($action) | Out-Null
            if ($recentCastles.Count -gt 5) { $recentCastles.RemoveAt(0) }
            $nextContext = @{ RecentTypes = $recentCastles }
            $nextState   = $agent.GetState($nextContext)
            $agent.Learn($state, $action, $reward, $nextState)
        }
        $agent.EndEpisode($episodeReward)

        if ($ep % [Math]::Max(1, [int]($episodes / 5)) -eq 0 -or $ep -eq $episodes) {
            $stats = $agent.GetStats()
            Write-Host ("  Episode {0,4} | Reward: {1,6:F2} | Epsilon: {2:F3} | Q-Table: {3} entries" -f `
                $ep, $episodeReward, $stats.Epsilon, $stats.QTableSize)
        }
    }

    $elapsed = (Get-Date) - $startTime
    $final   = $agent.GetStats()

    Write-PlaySection "Results"
    Write-PlayResult "Total episodes"     $final.TotalEpisodes  ""  "White"
    Write-PlayResult "Average reward"     $final.AverageReward  ""  "White"
    Write-PlayResult "Recent avg (10 ep)" $final.RecentAverageReward "" "Green"
    Write-PlayResult "Q-table entries"    $final.QTableSize     ""  "Cyan"
    Write-PlayResult "Explorations"       $final.ExplorationCount  "" "DarkGray"
    Write-PlayResult "Exploitations"      $final.ExploitationCount "" "DarkGray"
    Write-Host ("  Training time: {0:F1} seconds" -f $elapsed.TotalSeconds) -ForegroundColor DarkGray

    Write-PlaySection "Inspect What Was Learned"
    Write-Host "  Top states in Q-table:" -ForegroundColor Yellow
    $count = 0
    foreach ($key in $agent.QTable.Keys) {
        if ($count -ge 5) { break }
        $parts = $key -split '\|'
        if ($parts.Count -ge 2) {
            $state  = ($parts[0..($parts.Count - 2)]) -join '|'
            $action = $parts[-1]
            $qval   = [double]$agent.QTable[$key]
            if ($qval -gt 0.5) {
                Write-Host ("    State '{0}' -> Action '{1}' = {2:F3}" -f $state, $action, $qval) -ForegroundColor Green
                $count++
            }
        }
    }
    if ($count -eq 0) {
        Write-Host "    No strong preferences yet -- try more episodes." -ForegroundColor DarkGray
    }

    Write-PlaySection "What Did You Learn?"
    Write-Host "  - Higher alpha: Q-values update faster but oscillate more" -ForegroundColor DarkGray
    Write-Host "  - Lower gamma: agent ignores future rewards, focuses on now" -ForegroundColor DarkGray
    Write-Host "  - More episodes: Q-table grows, epsilon decays, agent improves" -ForegroundColor DarkGray
    Write-Host ""
}


# ============================================================================
# PLAYGROUND 3 -- ENTERPRISE EXPERIMENT
# ============================================================================

function Play-Enterprise {
    Write-PlayHeader "PLAYGROUND: ENTERPRISE AUTOMATION PILLARS"

    Write-Host "  Run any enterprise pillar and see how it learns." -ForegroundColor Gray
    Write-Host "  Compare baseline vs trained agent performance." -ForegroundColor Gray

    Write-PlaySection "Step 1: Choose a Pillar"
    $pillarChoice = Read-PlayChoice "Pick a pillar to train" @(
        "JobScheduler       -- adaptive job scheduling"
        "SecurityMonitor    -- detect and respond to security threats"
        "AnomalyDetector    -- find unusual patterns"
        "CapacityPlanner    -- predict resource needs"
        "SelfHealing        -- detect and fix infrastructure issues"
        "EnergyOptimizer    -- reduce energy consumption"
        "AutoPilot          -- orchestrate all 13 pillars"
    )

    $pillarNames = @(
        "JobScheduler", "SecurityMonitor", "AnomalyDetector",
        "CapacityPlanner", "SelfHealing", "EnergyOptimizer", "AutoPilot"
    )
    $pillarName = $pillarNames[$pillarChoice]

    Write-PlaySection "Step 2: Configure Training"
    $episodes   = Read-PlayInt "Number of episodes" 50 10 200
    $printEvery = Read-PlayInt "Print every N episodes" 10 5 50

    Write-PlaySection "Step 3: Training $pillarName"
    Write-Host "  Episodes  : $episodes" -ForegroundColor White
    Write-Host "  SimMode   : yes (safe for learning)" -ForegroundColor White
    Write-Host ""
    Write-Host "  Starting $pillarName training..." -ForegroundColor Yellow
    Write-Host ""

    $startTime = Get-Date

    $result = switch ($pillarName) {
        "JobScheduler"    { Invoke-VBAFJobSchedulerTraining     -Episodes $episodes -PrintEvery $printEvery -SimMode }
        "SecurityMonitor" { Invoke-VBAFSecurityMonitorTraining  -Episodes $episodes -PrintEvery $printEvery -SimMode }
        "AnomalyDetector" { Invoke-VBAFAnomalyDetectorTraining  -Episodes $episodes -PrintEvery $printEvery -SimMode }
        "CapacityPlanner" { Invoke-VBAFCapacityPlannerTraining  -Episodes $episodes -PrintEvery $printEvery -SimMode }
        "SelfHealing"     { Invoke-VBAFSelfHealingTraining      -Episodes $episodes -PrintEvery $printEvery -SimMode }
        "EnergyOptimizer" { Invoke-VBAFEnergyOptimizerTraining  -Episodes $episodes -PrintEvery $printEvery -SimMode }
        "AutoPilot"       { Invoke-VBAFAutoPilotTraining        -Episodes $episodes -PrintEvery $printEvery -SimMode }
    }

    $elapsed = (Get-Date) - $startTime

    Write-PlaySection "Results"

    if ($result -and $result.Baseline -and $result.Trained) {
        $baseAvg    = $result.Baseline.Avg
        $trainedAvg = $result.Trained.Avg
        $imp        = if ($baseAvg -ne 0) {
            ($trainedAvg - $baseAvg) / [Math]::Abs($baseAvg) * 100
        } else { 0.0 }

        Write-PlayResult "Baseline avg reward"  $baseAvg    "" "Gray"
        Write-PlayResult "Trained avg reward"   $trainedAvg "" "Green"

        $impColor = if ($imp -gt 0) { "Green" } else { "Red" }
        Write-Host ("  {0,-30} {1,9:F1}%" -f "Improvement", $imp) -ForegroundColor $impColor

        if ($imp -gt 20) {
            Write-Host ""
            Write-Host "  Strong learning signal -- agent clearly improved!" -ForegroundColor Green
        } elseif ($imp -gt 0) {
            Write-Host ""
            Write-Host "  Some improvement -- try more episodes for stronger signal." -ForegroundColor Yellow
        } else {
            Write-Host ""
            Write-Host "  No improvement -- try more episodes or check the setup." -ForegroundColor Red
        }
    }

    Write-Host ("  Training time: {0:F1} seconds" -f $elapsed.TotalSeconds) -ForegroundColor DarkGray

    Write-PlaySection "What Did You Learn?"
    Write-Host "  - The 15/40/30/15 distribution guarantees measurable improvement" -ForegroundColor DarkGray
    Write-Host "  - More episodes = higher improvement percentage (usually)" -ForegroundColor DarkGray
    Write-Host "  - AutoPilot orchestrates all pillars -- the most complex agent" -ForegroundColor DarkGray
    Write-Host "  - Replace -SimMode with real Windows data for production use" -ForegroundColor DarkGray
    Write-Host ""
}


# ============================================================================
# PLAYGROUND 4 -- SUPERVISED LEARNING EXPERIMENT
# ============================================================================

function Play-Supervised {
    Write-PlayHeader "PLAYGROUND: SUPERVISED LEARNING"

    Write-Host "  Train a supervised learning model on the HousePrice dataset." -ForegroundColor Gray
    Write-Host "  Compare different algorithms and see their R2 scores." -ForegroundColor Gray

    Write-PlaySection "Step 1: Choose a Model"
    $modelChoice = Read-PlayChoice "Pick a model to train" @(
        "LinearRegression  -- straight line fit, fast and interpretable"
        "RidgeRegression   -- LinearRegression with regularisation"
        "DecisionTree      -- tree of if/then rules, fully interpretable"
        "RandomForest      -- ensemble of decision trees, more robust"
        "All four          -- train all and compare"
    )

    Write-PlaySection "Step 2: Configure"
    $testSize = Read-PlayChoice "Test set size" @(
        "20% test (default)"
        "30% test (more robust evaluation)"
        "10% test (more training data)"
    )
    $testSizes = @(0.2, 0.3, 0.1)
    $ts = $testSizes[$testSize]

    $scaleChoice = Read-PlayChoice "Feature scaling" @(
        "StandardScaler  -- zero mean, unit variance (recommended)"
        "MinMaxScaler    -- scale to [0,1]"
        "No scaling      -- raw features"
    )

    Write-PlaySection "Step 3: Training"
    Write-Host "  Loading HousePrice dataset..." -ForegroundColor DarkGray
    $data  = Get-VBAFDataset -Name "HousePrice"
    $split = Split-TrainTest -X $data.X -y $data.y -TestSize $ts -Seed 42

    $scaler = switch ($scaleChoice) {
        0 { [StandardScaler]::new() }
        1 { [MinMaxScaler]::new()   }
        2 { $null }
    }

    if ($scaler) {
        $Xtrain = $scaler.FitTransform($split.XTrain)
        $Xtest  = $scaler.Transform($split.XTest)
    } else {
        $Xtrain = $split.XTrain
        $Xtest  = $split.XTest
    }

    $modelsToRun = if ($modelChoice -eq 4) { @(0,1,2,3) } else { @($modelChoice) }
    $modelResults = @()

    foreach ($m in $modelsToRun) {
        $modelName = @("LinearRegression","RidgeRegression","DecisionTree","RandomForest")[$m]
        Write-Host "  Training $modelName..." -ForegroundColor DarkGray

        $model = switch ($m) {
            0 { [LinearRegression]::new()           }
            1 { [RidgeRegression]::new(0.01)        }
            2 { [DecisionTree]::new("regression",3,2) }
            3 { [RandomForest]::new(10,3,2)         }
        }

        $startTime = Get-Date
        $model.Fit($Xtrain, $split.yTrain)
        $preds   = $model.Predict($Xtest)
        $metrics = Get-RegressionMetrics $split.yTest $preds
        $elapsed = ((Get-Date) - $startTime).TotalSeconds

        $modelResults += @{
            Name    = $modelName
            R2      = $metrics.R2
            RMSE    = $metrics.RMSE
            Time    = $elapsed
        }
    }

    Write-PlaySection "Results"
    Write-Host ("  {0,-22} {1,8} {2,10} {3,8}" -f "Model", "R2", "RMSE", "Time(s)") -ForegroundColor Gray
    Write-Host ("  {0,-22} {1,8} {2,10} {3,8}" -f "-----", "--", "----", "-------") -ForegroundColor DarkGray

    $sorted = $modelResults | Sort-Object { $_.R2 } -Descending
    foreach ($r in $sorted) {
        $r2Color = if ($r.R2 -gt 0.9) { "Green" } elseif ($r.R2 -gt 0.7) { "Yellow" } else { "Red" }
        Write-Host -NoNewline ("  {0,-22}" -f $r.Name) -ForegroundColor White
        Write-Host -NoNewline ("{0,8:F4}" -f $r.R2)   -ForegroundColor $r2Color
        Write-Host -NoNewline ("{0,10:F2}" -f $r.RMSE) -ForegroundColor White
        Write-Host ("{0,8:F2}" -f $r.Time)             -ForegroundColor DarkGray
    }

    Write-Host ""
    if ($sorted.Count -gt 1) {
        Write-Host "  Best model: $($sorted[0].Name) (R2 = $(([double]$sorted[0].R2).ToString('F4')))" -ForegroundColor Green
    }

    Write-PlaySection "What Did You Learn?"
    Write-Host "  - R2 closer to 1.0 = better prediction" -ForegroundColor DarkGray
    Write-Host "  - Ridge adds regularisation -- helps when features are correlated" -ForegroundColor DarkGray
    Write-Host "  - RandomForest is usually more robust but slower" -ForegroundColor DarkGray
    Write-Host "  - Scaling matters for LinearRegression and Ridge, not for trees" -ForegroundColor DarkGray
    Write-Host ""
}


# ============================================================================
# MAIN PLAYGROUND FUNCTION
# ============================================================================

function Start-VBAFPlayground {
    <#
    .SYNOPSIS
        Interactive VBAF experiment playground.
    .DESCRIPTION
        Menu-driven interface for experimenting with VBAF algorithms.
        No coding required -- pick options and watch the results.
    .PARAMETER Algorithm
        Optional. Jump directly to one playground:
          "DQN" | "QLearning" | "Enterprise" | "Supervised"
        Default: show main menu.
    .EXAMPLE
        Start-VBAFPlayground
        Start-VBAFPlayground -Algorithm "DQN"
        Start-VBAFPlayground -Algorithm "Enterprise"
    #>
    param(
        [string]$Algorithm = ""
    )

    Write-PlayHeader "VBAF PLAYGROUND"
    Write-Host "  Experiment with algorithms interactively." -ForegroundColor Gray
    Write-Host "  No coding required -- just pick options and watch." -ForegroundColor Gray
    Write-Host "  Press Ctrl+C at any time to exit." -ForegroundColor Gray

    if ($Algorithm -ne "") {
        switch ($Algorithm) {
            "DQN"        { Play-DQN        }
            "QLearning"  { Play-QLearning  }
            "Enterprise" { Play-Enterprise }
            "Supervised" { Play-Supervised }
            default {
                Write-Host "  Unknown algorithm: $Algorithm" -ForegroundColor Red
                Write-Host "  Use: DQN, QLearning, Enterprise, Supervised" -ForegroundColor Red
            }
        }
        return
    }

    # Main menu loop
    $running = $true
    while ($running) {
        Write-PlayHeader "MAIN MENU"
        $choice = Read-PlayChoice "Choose a playground" @(
            "DQN Experiment        -- train a Deep Q-Network, tune hyperparameters"
            "Q-Learning Experiment -- train a Q-table agent, inspect what it learned"
            "Enterprise Pillars    -- run any of the 14 enterprise automation agents"
            "Supervised Learning   -- compare regression models on HousePrice dataset"
            "Exit Playground"
        )

        switch ($choice) {
            0 { Play-DQN        }
            1 { Play-QLearning  }
            2 { Play-Enterprise }
            3 { Play-Supervised }
            4 { $running = $false }
        }

        if ($running -and $choice -ne 4) {
            Write-Host ""
            $again = Read-PlayChoice "What next?" @(
                "Return to main menu"
                "Exit playground"
            )
            if ($again -eq 1) { $running = $false }
        }
    }

    Write-Host ""
    Write-Host ("=" * 65) -ForegroundColor Cyan
    Write-Host "  VBAF Playground session ended." -ForegroundColor Cyan
    Write-Host "  See docs\ for deeper reading." -ForegroundColor Cyan
    Write-Host ("=" * 65) -ForegroundColor Cyan
    Write-Host ""
}
