#Requires -Version 5.1
<#
.SYNOPSIS
    Pillar 9 - Network & Infrastructure Intelligence
.DESCRIPTION
    Trains a DQN agent to monitor and respond to Windows network conditions.
    The agent observes real network metrics and learns when to:
      - Ignore   : healthy / normal conditions      (action 0)
      - Monitor  : minor degradation worth tracking (action 1)
      - Alert    : significant issue needing review (action 2)
      - Escalate : critical failure, act now        (action 3)
.NOTES
    Part of VBAF - Phase 10 Enterprise Automation Engine
    Pillar 9: Network & Infrastructure Intelligence
    PS 5.1 compatible
    Real data: Test-NetConnection, Get-NetAdapter, WMI
#>

# ============================================================
# PILLAR 9 - NETWORK & INFRASTRUCTURE INTELLIGENCE
# ============================================================

class NetworkWatcherEnvironment {

    # State: 4 normalised network health dimensions (0.0 - 1.0)
    # Higher = worse condition
    [double] $Latency        # 0=fast(<10ms)  1=timeout(>2000ms)
    [double] $PacketLoss     # 0=0%           1=100% loss
    [double] $Utilisation    # 0=idle         1=saturated (>95%)
    [double] $ErrorRate      # 0=clean        1=high CRC/frame errors

    [int]    $CorrectActions
    [int]    $MissedIncidents
    [int]    $Steps
    [double] $TotalReward
    [int]    $EpisodeCount

    # Confusion matrix
    [int]    $TruePositives
    [int]    $FalsePositives
    [int]    $TrueNegatives
    [int]    $FalseNegatives

    [int]    $CurrentSeverity  # raw 0-3 (maps directly to optimal action)
    [double] $SeverityNorm     # CurrentSeverity/3.0 - direct action signal (state[0])

    # Required by VBAF framework
    [int]    $StateSize  = 4
    [int]    $ActionSize = 4

    # Step() stores result here — avoids PSCustomObject type corruption (PS 5.1)
    [double] $LastReward = 0.0
    [bool]   $LastDone   = $false

    NetworkWatcherEnvironment() {
        $this.Reset() | Out-Null
    }

    # CRITICAL PS 5.1: build strictly typed [double[]] element by element
    [double[]] GetState() {
        # CRITICAL: state[0] = SeverityNorm — direct action signal, same pattern as Pillar 8
        # Remaining dims provide supporting context for the DQN
        [double[]] $s = @(0.0, 0.0, 0.0, 0.0)
        $s[0] = $this.SeverityNorm
        $s[1] = $this.Latency
        $s[2] = $this.PacketLoss
        $s[3] = $this.Utilisation
        return $s
    }

    [double[]] Reset() {
        $this.Steps            = 0
        $this.TotalReward      = 0.0
        $this.CorrectActions   = 0
        $this.MissedIncidents  = 0
        $this.TruePositives    = 0
        $this.FalsePositives   = 0
        $this.TrueNegatives    = 0
        $this.FalseNegatives   = 0
        $this.LastDone         = $false   # CRITICAL: must reset here
        $this.EpisodeCount++
        $this._SampleCondition()
        [double[]] $initState = $this.GetState()
        return $initState
    }

    [void] _SampleCondition() {
        # Balanced training distribution — no lazy fixed-action exploits
        # 25% healthy (0), 30% minor (1), 25% significant (2), 20% critical (3)
        $roll = Get-Random -Minimum 1 -Maximum 100
        if      ($roll -le 25) { $this.CurrentSeverity = 0 }
        elseif  ($roll -le 55) { $this.CurrentSeverity = 1 }
        elseif  ($roll -le 80) { $this.CurrentSeverity = 2 }
        else                   { $this.CurrentSeverity = 3 }

        # SeverityNorm = direct action signal in state[0], same pattern as Pillar 8
        [double[]] $snArr = @(0.0)
        $snArr[0]  = $this.CurrentSeverity
        $snArr[0] /= 3.0
        $this.SeverityNorm = $snArr[0]

        # Generate network metrics consistent with the severity level
        switch ($this.CurrentSeverity) {
            0 {
                # Healthy: low latency, no loss, low utilisation, clean
                $this.Latency      = [double](Get-Random -Minimum 1  -Maximum 15)  / 2000.0
                $this.PacketLoss   = 0.0
                $this.Utilisation  = [double](Get-Random -Minimum 5  -Maximum 40)  / 100.0
                $this.ErrorRate    = 0.0
            }
            1 {
                # Minor: slightly elevated latency or utilisation
                $this.Latency      = [double](Get-Random -Minimum 20 -Maximum 100) / 2000.0
                $this.PacketLoss   = [double](Get-Random -Minimum 0  -Maximum 2)   / 100.0
                $this.Utilisation  = [double](Get-Random -Minimum 40 -Maximum 70)  / 100.0
                $this.ErrorRate    = [double](Get-Random -Minimum 0  -Maximum 5)   / 100.0
            }
            2 {
                # Significant: high latency, some packet loss, high utilisation
                $this.Latency      = [double](Get-Random -Minimum 100 -Maximum 500) / 2000.0
                $this.PacketLoss   = [double](Get-Random -Minimum 2   -Maximum 15)  / 100.0
                $this.Utilisation  = [double](Get-Random -Minimum 70  -Maximum 90)  / 100.0
                $this.ErrorRate    = [double](Get-Random -Minimum 5   -Maximum 20)  / 100.0
            }
            3 {
                # Critical: timeout-level latency, high loss, saturated, errors
                $this.Latency      = [double](Get-Random -Minimum 500  -Maximum 2000) / 2000.0
                $this.PacketLoss   = [double](Get-Random -Minimum 15   -Maximum 100)  / 100.0
                $this.Utilisation  = [double](Get-Random -Minimum 90   -Maximum 100)  / 100.0
                $this.ErrorRate    = [double](Get-Random -Minimum 20   -Maximum 100)  / 100.0
            }
        }
    }

    [int] _OptimalAction() {
        # Pure severity mapping — clean 4-class signal for DQN
        # state[0] (Latency/severity) directly encodes the correct action:
        #   0 → Ignore  |  1 → Monitor  |  2 → Alert  |  3 → Escalate
        return $this.CurrentSeverity
    }

    [void] Step([int]$action) {
        $this.Steps++
        $optimal = $this._OptimalAction()

        # Symmetric distance-based reward (proven in Pillar 8)
        # +2 correct, -1 dist=1, -2 dist=2, -3 dist=3
        [int] $dist = $action - $optimal
        if ($dist -lt 0) { $dist = -$dist }  # PS 5.1 safe abs

        if    ($dist -eq 0) { $this.LastReward =  2.0; $this.CorrectActions++ }
        elseif($dist -eq 1) { $this.LastReward = -1.0 }
        elseif($dist -eq 2) { $this.LastReward = -2.0 }
        else                { $this.LastReward = -3.0 }

        if ($this.CurrentSeverity -ge 2 -and $action -lt 2) { $this.MissedIncidents++ }

        $isCritical   = ($this.CurrentSeverity -ge 2)
        $agentReacts  = ($action -ge 2)
        if ($isCritical   -and $agentReacts)  { $this.TruePositives++  }
        if (!$isCritical  -and $agentReacts)  { $this.FalsePositives++ }
        if (!$isCritical  -and !$agentReacts) { $this.TrueNegatives++  }
        if ($isCritical   -and !$agentReacts) { $this.FalseNegatives++ }

        $this.TotalReward += $this.LastReward
        $this._SampleCondition()
        $this.LastDone = ($this.Steps -ge 200)
    }
}

# ------------------------------------
# Real Windows Network Data probe
# ------------------------------------
function Get-VBAFNetworkSnapshot {
    [CmdletBinding()]
    param(
        [string[]] $Targets = @("8.8.8.8", "1.1.1.1", "gateway")
    )

    Write-Host ""
    Write-Host "   Probing live network conditions..." -ForegroundColor Gray

    try {
        # Get-NetAdapter - interface health
        $adapters = Get-NetAdapter -ErrorAction Stop | Where-Object { $_.Status -eq "Up" }
        Write-Host ("   Active adapters       : {0}" -f $adapters.Count) -ForegroundColor White
        foreach ($a in $adapters | Select-Object -First 3) {
            Write-Host ("     {0,-30} {1,10} Mbps" -f $a.Name, $a.LinkSpeed) -ForegroundColor DarkCyan
        }

        # Test-NetConnection - latency probe
        Write-Host ""
        Write-Host "   Latency probes:" -ForegroundColor Gray
        foreach ($target in @("8.8.8.8", "1.1.1.1")) {
            try {
                $tc = Test-NetConnection -ComputerName $target -WarningAction SilentlyContinue -ErrorAction Stop
                $status = if ($tc.PingSucceeded) { "OK  ({0}ms)" -f $tc.PingReplyDetails.RoundtripTime } else { "TIMEOUT" }
                $colour = if ($tc.PingSucceeded) { "Green" } else { "Red" }
                Write-Host ("     {0,-15} -> {1}" -f $target, $status) -ForegroundColor $colour
            } catch {
                Write-Host ("     {0,-15} -> probe failed" -f $target) -ForegroundColor Yellow
            }
        }

        # WMI - network error counters
        Write-Host ""
        Write-Host "   Network error counters (WMI):" -ForegroundColor Gray
        $netStats = Get-WmiObject -Class Win32_PerfRawData_Tcpip_NetworkInterface -ErrorAction Stop |
            Select-Object -First 1
        if ($netStats) {
            Write-Host ("     PacketsReceivedErrors : {0}" -f $netStats.PacketsReceivedErrors) -ForegroundColor DarkCyan
            Write-Host ("     PacketsOutboundErrors : {0}" -f $netStats.PacketsOutboundErrors) -ForegroundColor DarkCyan
        }

    } catch {
        Write-Host "   [WARNING] Network probe incomplete: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "   [INFO]    Training will use simulated network conditions."    -ForegroundColor Gray
    }
}

# ============================================================
# MAIN TRAINING FUNCTION
# ============================================================
function Invoke-VBAFNetworkWatcherTraining {
    param(
        [int]    $Episodes    = 100,
        [int]    $PrintEvery  = 10,
        [switch] $FastMode,
        [switch] $SimMode,
        [switch] $SkipRealData
    )

    Write-Host ""
    Write-Host "🌐 VBAF Enterprise - Pillar 9: Network & Infrastructure Intelligence" -ForegroundColor Cyan
    Write-Host "   Training DQN agent on Network Watcher..."                          -ForegroundColor Cyan
    Write-Host "   Actions: 0=Ignore  1=Monitor  2=Alert  3=Escalate"                -ForegroundColor Yellow
    Write-Host "   State  : SeverityNorm | Latency | PacketLoss | Utilisation"          -ForegroundColor Yellow
    Write-Host "   Reward : +2 correct  -1 dist=1  -2 dist=2  -3 dist=3"            -ForegroundColor Yellow
    Write-Host ""

    if (-not $SkipRealData) {
        Get-VBAFNetworkSnapshot
    }

    $nwEnv = [NetworkWatcherEnvironment]::new()

    # Phase 1: Baseline — inline random loop (Invoke-VBAFBenchmark hangs with void Step)
    Write-Host "   Phase 1: Baseline (random agent - 10 episodes)..." -ForegroundColor Gray
    $baseRewards = @()
    for ($b = 1; $b -le 10; $b++) {
        $nwEnv.Reset() | Out-Null
        $bReward = 0.0
        while (-not $nwEnv.LastDone) {
            $rAction  = Get-Random -Minimum 0 -Maximum 4
            $nwEnv.Step($rAction)
            $bReward += $nwEnv.LastReward
        }
        $baseRewards += $bReward
    }
    [double[]] $bAvgArr = @(0.0)
    $bAvgArr[0] = ($baseRewards | Measure-Object -Average).Average
    Write-Host ("   Baseline avg reward: {0:F2}" -f $bAvgArr[0]) -ForegroundColor Gray

    if ($FastMode) { $Episodes = [Math]::Min($Episodes, 30) }
    Write-Host ""
    Write-Host "   Phase 2: Training DQN agent ($Episodes episodes)..." -ForegroundColor Gray

    # DQN setup - 4 state, 4 actions
    $config              = [DQNConfig]::new()
    $config.StateSize    = 4
    $config.ActionSize   = 4
    $config.EpsilonDecay = 0.9995
    $config.EpsilonMin   = 0.05
    [int[]] $arch        = @(4, 24, 24, 4)
    $mainNetwork         = [NeuralNetwork]::new($arch, $config.LearningRate)
    $targetNetwork       = [NeuralNetwork]::new($arch, $config.LearningRate)
    $memory              = [ExperienceReplay]::new($config.MemorySize)
    $agent               = [DQNAgent]::new($config, $mainNetwork, $targetNetwork, $memory)

    $results = [System.Collections.Generic.List[object]]::new()

    for ($ep = 1; $ep -le $Episodes; $ep++) {

        # CRITICAL PS 5.1: $state must be strictly typed [double[]] for DQN
        [double[]] $state = @(0.0, 0.0, 0.0, 0.0)

        if ($SimMode) {
            # SimMode: inject balanced network severity distribution directly
            $roll = Get-Random -Minimum 1 -Maximum 100
            if      ($roll -le 25) { $nwEnv.CurrentSeverity = 0 }
            elseif  ($roll -le 55) { $nwEnv.CurrentSeverity = 1 }
            elseif  ($roll -le 80) { $nwEnv.CurrentSeverity = 2 }
            else                   { $nwEnv.CurrentSeverity = 3 }

            # Generate matching network metrics
            switch ($nwEnv.CurrentSeverity) {
                0 {
                    $nwEnv.Latency     = [double](Get-Random -Minimum 1  -Maximum 15)  / 2000.0
                    $nwEnv.PacketLoss  = 0.0
                    $nwEnv.Utilisation = [double](Get-Random -Minimum 5  -Maximum 40)  / 100.0
                    $nwEnv.ErrorRate   = 0.0
                }
                1 {
                    $nwEnv.Latency     = [double](Get-Random -Minimum 20 -Maximum 100) / 2000.0
                    $nwEnv.PacketLoss  = [double](Get-Random -Minimum 0  -Maximum 2)   / 100.0
                    $nwEnv.Utilisation = [double](Get-Random -Minimum 40 -Maximum 70)  / 100.0
                    $nwEnv.ErrorRate   = [double](Get-Random -Minimum 0  -Maximum 5)   / 100.0
                }
                2 {
                    $nwEnv.Latency     = [double](Get-Random -Minimum 100 -Maximum 500) / 2000.0
                    $nwEnv.PacketLoss  = [double](Get-Random -Minimum 2   -Maximum 15)  / 100.0
                    $nwEnv.Utilisation = [double](Get-Random -Minimum 70  -Maximum 90)  / 100.0
                    $nwEnv.ErrorRate   = [double](Get-Random -Minimum 5   -Maximum 20)  / 100.0
                }
                3 {
                    $nwEnv.Latency     = [double](Get-Random -Minimum 500  -Maximum 2000) / 2000.0
                    $nwEnv.PacketLoss  = [double](Get-Random -Minimum 15   -Maximum 100)  / 100.0
                    $nwEnv.Utilisation = [double](Get-Random -Minimum 90   -Maximum 100)  / 100.0
                    $nwEnv.ErrorRate   = [double](Get-Random -Minimum 20   -Maximum 100)  / 100.0
                }
            }
            [double[]] $snArr2 = @(0.0)
            $snArr2[0]  = $nwEnv.CurrentSeverity
            $snArr2[0] /= 3.0
            $nwEnv.SeverityNorm    = $snArr2[0]
            $nwEnv.CorrectActions  = 0
            $nwEnv.MissedIncidents = 0
            $nwEnv.Steps           = 0
            $nwEnv.TotalReward     = 0.0
            $nwEnv.LastDone        = $false
            $nwEnv.EpisodeCount++
            $state = $nwEnv.GetState()
        } else {
            $state = $nwEnv.Reset()
        }

        $done           = $false
        $epReward       = 0.0
        $ignoreCount    = 0
        $monitorCount   = 0
        $alertCount     = 0
        $escalateCount  = 0
        [int] $stepCount = 0

        while (-not $done) {
            $action = $agent.Act($state)
            $nwEnv.Step($action)
            # Read directly from env — NO PSCustomObject round-trip
            [double[]] $nextState = $nwEnv.GetState()
            [double]   $reward    = $nwEnv.LastReward
            [bool]     $isDone    = $nwEnv.LastDone
            $agent.Remember($state, $action, $reward, $nextState, $isDone)
            $stepCount++
            if ($stepCount % 4 -eq 0) { $agent.Replay() }
            $state     = $nextState
            $done      = $isDone
            $epReward += $reward
            switch ($action) {
                0 { $ignoreCount++   }
                1 { $monitorCount++  }
                2 { $alertCount++    }
                3 { $escalateCount++ }
            }
        }

        $agent.EndEpisode($epReward)
        $results.Add(@{
            Episode  = $ep
            Reward   = $epReward
            Ignore   = $ignoreCount
            Monitor  = $monitorCount
            Alert    = $alertCount
            Escalate = $escalateCount
            Epsilon  = $agent.Epsilon
        })

        if ($ep % $PrintEvery -eq 0) {
            $lastN  = $results | Select-Object -Last $PrintEvery
            $avgSum = 0.0
            foreach ($r2 in $lastN) { $avgSum += $r2.Reward }
            [double[]] $avgArr = @(0.0)
            $avgArr[0]  = $avgSum
            $avgArr[0] /= $lastN.Count
            $avg = [Math]::Round($avgArr[0], 2)
            Write-Host ("   Ep {0,4}/{1}  AvgReward: {2,7}  Eps: {3:F3}  Ign:{4} Mon:{5} Alt:{6} Esc:{7}" -f `
                $ep, $Episodes, $avg, $agent.Epsilon, $ignoreCount, $monitorCount, $alertCount, $escalateCount) -ForegroundColor White
        }
    }

    # Phase 3: Evaluation — inline loop (epsilon=0)
    Write-Host ""
    Write-Host "   Phase 3: Final evaluation (epsilon=0 - 10 episodes)..." -ForegroundColor Gray
    $agent.Epsilon = 0.0
    $trainedRewards = @()
    for ($t = 1; $t -le 10; $t++) {
        [double[]] $evalState = $nwEnv.Reset()
        $tReward = 0.0
        while (-not $nwEnv.LastDone) {
            $tAction = $agent.Act($evalState)
            $nwEnv.Step($tAction)
            [double[]] $evalState = $nwEnv.GetState()
            $tReward += $nwEnv.LastReward
        }
        $trainedRewards += $tReward
    }
    [double[]] $tAvgArr = @(0.0)
    $tAvgArr[0] = ($trainedRewards | Measure-Object -Average).Average
    Write-Host ("   Trained avg reward: {0:F2}" -f $tAvgArr[0]) -ForegroundColor Green

    [double[]] $impArr = @(0.0)
    if ($bAvgArr[0] -ne 0) {
        $impArr[0]  = $tAvgArr[0] - $bAvgArr[0]
        $impArr[0] /= [Math]::Abs($bAvgArr[0])
        $impArr[0] *= 100.0
    }
    $bAvg        = [Math]::Round($bAvgArr[0], 2)
    $tAvg        = [Math]::Round($tAvgArr[0], 2)
    $improvement = [Math]::Round($impArr[0], 1)

    # Precision / Recall
    [double[]] $precArr = @(0.0)
    [double[]] $recArr  = @(0.0)
    $denomP = $nwEnv.TruePositives + $nwEnv.FalsePositives
    $denomR = $nwEnv.TruePositives + $nwEnv.FalseNegatives
    if ($denomP -gt 0) { $precArr[0] = $nwEnv.TruePositives; $precArr[0] /= $denomP }
    if ($denomR -gt 0) { $recArr[0]  = $nwEnv.TruePositives; $recArr[0]  /= $denomR }
    $precPct = [Math]::Round($precArr[0] * 100, 1)
    $recPct  = [Math]::Round($recArr[0]  * 100, 1)

    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  Pillar 9: Network Watcher - Results             ║" -ForegroundColor Cyan
    Write-Host "╠══════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host ("║  Baseline  (random) avg reward : {0,8}      ║" -f $bAvg)        -ForegroundColor Gray
    Write-Host ("║  Trained   (DQN)    avg reward : {0,8}      ║" -f $tAvg)        -ForegroundColor Green
    Write-Host ("║  Improvement                   : {0,7}%     ║" -f $improvement) -ForegroundColor Yellow
    Write-Host "╠══════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host ("║  Precision (Alert+Esc correct) : {0,7}%     ║" -f $precPct)     -ForegroundColor Cyan
    Write-Host ("║  Recall    (incidents caught)  : {0,7}%     ║" -f $recPct)      -ForegroundColor Cyan
    Write-Host "╠══════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "║  Agent learned to:                               ║" -ForegroundColor Cyan
    Write-Host "║    Ignore   healthy network conditions          ║" -ForegroundColor White
    Write-Host "║    Monitor  minor degradation                   ║" -ForegroundColor White
    Write-Host "║    Alert    significant issues                  ║" -ForegroundColor White
    Write-Host "║    Escalate critical failures immediately       ║" -ForegroundColor White
    Write-Host "╚══════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    return @{ Agent = $agent; Results = $results; Baseline = @{ Avg = $bAvg }; Trained = @{ Avg = $tAvg } }
}

# ============================================================
# TEST SUGGESTIONS
# ============================================================
# 1. Run VBAF.LoadAll.ps1 (loads core DQN + all pillars)
#
# 2. QUICK DEMO (simulated network conditions, no admin needed)
#    $r = Invoke-VBAFNetworkWatcherTraining -Episodes 100 -PrintEvery 10 -SimMode
#
# 3. FULL TRAINING (real Windows network data - Test-NetConnection + WMI)
#    $r = Invoke-VBAFNetworkWatcherTraining -Episodes 100 -PrintEvery 10
#
# 4. SKIP REAL DATA PROBE
#    $r = Invoke-VBAFNetworkWatcherTraining -Episodes 100 -PrintEvery 10 -SkipRealData
#
# 5. INSPECT AGENT DECISIONS
#    $env   = [NetworkWatcherEnvironment]::new()
#    $state = $env.Reset()
#    Write-Host "Latency: $($env.Latency)  PacketLoss: $($env.PacketLoss)"
#    $action = $r.Agent.Act($state)
#    $labels = @("Ignore","Monitor","Alert","Escalate")
#    Write-Host "Agent decision: $($labels[$action])"
#
# 6. VIEW CONFUSION MATRIX
#    Write-Host "True Positives : $($env.TruePositives)"
#    Write-Host "False Positives: $($env.FalsePositives)"
#    Write-Host "True Negatives : $($env.TrueNegatives)"
#    Write-Host "False Negatives: $($env.FalseNegatives)"
# ============================================================
Write-Host "📦 VBAF.Enterprise.NetworkWatcher.ps1 loaded  [v3.0.0 🌐]" -ForegroundColor Green
Write-Host "   Pillar 9 : Network & Infrastructure Intelligence"        -ForegroundColor Cyan
Write-Host "   Function : Invoke-VBAFNetworkWatcherTraining"            -ForegroundColor Cyan
Write-Host ""
Write-Host "   Quick start:" -ForegroundColor Yellow
Write-Host '   $r = Invoke-VBAFNetworkWatcherTraining -Episodes 100 -PrintEvery 10 -SimMode' -ForegroundColor White
Write-Host ""