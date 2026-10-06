#Requires -Version 5.1
<#
.SYNOPSIS
    The production cell: a small, honest world for learning to schedule (VBAF v6.0).
.DESCRIPTION
    One machine, an order queue, deadlines. A shift is one episode of 200 minutes; orders arrive at random, each
    with a processing time and a deadline. The brain sees the first 3 orders in the queue and picks one.
    On time: +1. Late: a penalty that grows with the lateness. The same seed gives exactly the same shift.
    Test shifts: seeds 1001-1030 (never for training or selection). Validation shifts: seeds 2001-2010.
    Hand-written rules for comparison: Random, FIFO, EDF, SPT (shortest job first, "Brain 0"), LST.
    Comes from VBAF-Evolution-Lab (phases 1-5), where it was used to prove that the kernel can build a brain,
    measure it and evolve a better one.
.EXAMPLE
    $world = [ProductionCellEnvironment]::new(1)
    Measure-VBAFProductionPolicy -World $world -Policy (Get-VBAFProductionRules)['SPT'].Policy -Seeds (Get-VBAFProductionTestSeeds)
#>
class ProductionCellEnvironment : VBAFEnvironment {
    # --- World settings ---
    [int]    $ShiftLength = 200     # ticks per shift (one episode)
    [double] $ArrivalProb = 0.30    # chance of a new order each tick
    [int]    $MinProc     = 1
    [int]    $MaxProc     = 5
    [int]    $MinSlack    = 2
    [int]    $MaxSlack    = 15
    [int]    $Slots       = 3       # orders the brain can see and choose from

    # --- Live state ---
    [int] $Clock
    [int] $Seed
    hidden [System.Random] $Rng
    hidden [System.Collections.Generic.List[hashtable]] $Pending   # generated, not yet arrived
    hidden [System.Collections.Generic.List[hashtable]] $Queue     # arrived, waiting

    # --- Shift statistics ---
    [int]    $Arrived
    [int]    $OnTime
    [int]    $Late
    [int]    $InvalidChoices
    [int]    $IdleTicks
    [double] $TotalLateness

    ProductionCellEnvironment([int]$seed) : base("ProductionCell", 1000) {
        $this.Seed             = $seed
        $this.Rng              = [System.Random]::new($seed)
        $this.ObservationSpace = [VBAFSpace]::new("continuous", 11, -1.0, 1.0)
        $this.ActionSpace      = [VBAFSpace]::new("discrete",    3,  0.0, 1.0)
        $this.Reset()
    }

    # Next shift, continuing the random stream (variety during training)
    [double[]] Reset() {
        $this.Clock          = 0
        $this.Steps          = 0
        $this.TotalReward    = 0.0
        $this.EpisodeCount++
        $this.Arrived        = 0
        $this.OnTime         = 0
        $this.Late           = 0
        $this.InvalidChoices = 0
        $this.IdleTicks      = 0
        $this.TotalLateness  = 0.0
        $this.Pending = [System.Collections.Generic.List[hashtable]]::new()
        $this.Queue   = [System.Collections.Generic.List[hashtable]]::new()

        $id = 0
        for ($t = 0; $t -lt $this.ShiftLength; $t++) {
            if ($this.Rng.NextDouble() -lt $this.ArrivalProb) {
                $proc  = $this.Rng.Next($this.MinProc,  $this.MaxProc  + 1)
                $slack = $this.Rng.Next($this.MinSlack, $this.MaxSlack + 1)
                $id++
                $this.Pending.Add(@{ Id = $id; Arrival = $t; Proc = $proc; Deadline = $t + $proc + $slack })
            }
        }
        $this.AdmitArrivals()
        return $this.GetState()
    }

    # Fixed shift: the same seed always gives the exact same orders (testing and measuring)
    [double[]] ResetWithSeed([int]$seed) {
        $this.Seed = $seed
        $this.Rng  = [System.Random]::new($seed)
        return $this.Reset()
    }

    hidden [void] AdmitArrivals() {
        while ($this.Pending.Count -gt 0 -and $this.Pending[0].Arrival -le $this.Clock) {
            $this.Queue.Add($this.Pending[0])
            $this.Pending.RemoveAt(0)
            $this.Arrived++
        }
    }

    [double[]] GetState() {
        $s = [double[]]::new(11)
        for ($i = 0; $i -lt $this.Slots; $i++) {
            if ($i -lt $this.Queue.Count) {
                $o = $this.Queue[$i]
                $slack = [int]$o.Deadline - $this.Clock - [int]$o.Proc
                $s[$i * 3]     = 1.0
                $s[$i * 3 + 1] = [double]$o.Proc / $this.MaxProc
                $s[$i * 3 + 2] = [Math]::Max(-1.0, [Math]::Min(1.0, [double]$slack / $this.MaxSlack))
            }
        }
        $s[9]  = [Math]::Min(1.0, [double]$this.Queue.Count / 10.0)
        $s[10] = [Math]::Max(0.0, [double]($this.ShiftLength - $this.Clock) / $this.ShiftLength)
        return $s
    }

    [hashtable] Step([int]$action) {
        $this.Steps++
        $reward = 0.0
        $choosable = [Math]::Min($this.Slots, $this.Queue.Count)

        if ($this.Queue.Count -eq 0) {
            # Nothing to do: machine waits one tick
            $this.Clock++
            $this.IdleTicks++
        } elseif ($action -lt 0 -or $action -ge $choosable) {
            # Picked an empty slot: wasted tick
            $reward = -0.2
            $this.Clock++
            $this.IdleTicks++
            $this.InvalidChoices++
        } else {
            $o = $this.Queue[$action]
            $this.Queue.RemoveAt($action)
            $this.Clock += [int]$o.Proc
            $lateness = $this.Clock - [int]$o.Deadline
            if ($lateness -le 0) {
                $this.OnTime++
                $reward = 1.0
            } else {
                $this.Late++
                $this.TotalLateness += $lateness
                $reward = -(0.5 + [Math]::Min([int]$lateness, 10) / 20.0)
            }
        }

        $this.AdmitArrivals()
        $done = ($this.Clock -ge $this.ShiftLength) -or ($this.Steps -ge $this.MaxSteps)
        if ($done) {
            # Orders still waiting and already past their deadline count against the brain
            foreach ($q in $this.Queue) {
                if ([int]$q.Deadline -lt $this.Clock) { $reward -= 0.5 }
            }
        }
        $this.TotalReward += $reward
        return @{ NextState = $this.GetState(); Reward = $reward; Done = $done }
    }

    [hashtable] GetShiftStats() {
        $total = $this.Arrived + $this.Pending.Count
        $pct = 0.0
        if ($total -gt 0) { $pct = [Math]::Round(100.0 * $this.OnTime / $total, 1) }
        $avgLate = 0.0
        if ($this.Late -gt 0) { $avgLate = [Math]::Round($this.TotalLateness / $this.Late, 2) }
        return @{
            Orders      = $total
            OnTime      = $this.OnTime
            Late        = $this.Late
            Unfinished  = $this.Queue.Count + $this.Pending.Count
            OnTimePct   = $pct
            AvgLateness = $avgLate
            Invalid     = $this.InvalidChoices
            IdleTicks   = $this.IdleTicks
            Clock       = $this.Clock
            TotalReward = [Math]::Round($this.TotalReward, 2)
        }
    }
}

function Get-VBAFProductionTestSeeds { return [int[]](1001..1030) }

# Pick the visible slot (0-2) with the LOWEST key value. Ties go to the oldest order.
function Select-VBAFProductionSlot {
    param([double[]]$State, [scriptblock]$Key)
    $best = 0
    $bestVal = [double]::MaxValue
    for ($i = 0; $i -lt 3; $i++) {
        if ($State[$i * 3] -gt 0.5) {
            $v = & $Key $State[$i * 3 + 1] $State[$i * 3 + 2]
            if ($v -lt $bestVal) { $bestVal = $v; $best = $i }
        }
    }
    return $best
}

# Hand-written rules. Each policy: param($s, $rng) -> action (0-2).
# State per slot: present, proc/5, slack/15  (time to deadline = proc + slack)
function Get-VBAFProductionRules {
    $rules = [ordered]@{}
    $rules['Random'] = @{ Description = 'Random choice (floor)'
        Policy = { param($s, $rng)
            $valid = [int]$s[0] + [int]$s[3] + [int]$s[6]
            if ($valid -eq 0) { 0 } else { $rng.Next(0, $valid) } } }
    $rules['FIFO'] = @{ Description = 'Oldest order first'
        Policy = { param($s, $rng) 0 } }
    $rules['EDF'] = @{ Description = 'Earliest deadline first'
        Policy = { param($s, $rng) Select-VBAFProductionSlot -State $s -Key { param($p, $sl) $p * 5 + $sl * 15 } } }
    $rules['SPT'] = @{ Description = 'Shortest job first'
        Policy = { param($s, $rng) Select-VBAFProductionSlot -State $s -Key { param($p, $sl) $p } } }
    $rules['LST'] = @{ Description = 'Least slack first'
        Policy = { param($s, $rng) Select-VBAFProductionSlot -State $s -Key { param($p, $sl) $sl } } }
    return $rules
}

# Run a policy over every test seed and summarise.
function Measure-VBAFProductionPolicy {
    param($World, [scriptblock]$Policy, [int[]]$Seeds, [int]$PolicySeed = 7)
    $rng  = [System.Random]::new($PolicySeed)
    $rows = foreach ($seed in $Seeds) {
        $state = $World.ResetWithSeed($seed)
        $done  = $false
        while (-not $done) {
            $a = [int](& $Policy $state $rng)
            $r = $World.Step($a)
            $state = $r.NextState
            $done  = $r.Done
        }
        $st = $World.GetShiftStats()
        [pscustomobject]@{ Seed = $seed; Reward = $st.TotalReward; OnTimePct = $st.OnTimePct; AvgLateness = $st.AvgLateness }
    }
    $rw   = @($rows | ForEach-Object { [double]$_.Reward })
    $mean = ($rw | Measure-Object -Average).Average
    $var  = ($rw | ForEach-Object { ($_ - $mean) * ($_ - $mean) } | Measure-Object -Average).Average
    return [pscustomobject]@{
        Score       = [Math]::Round($mean, 2)
        ScoreStd    = [Math]::Round([Math]::Sqrt($var), 2)
        MinReward   = ($rw | Measure-Object -Minimum).Minimum
        MaxReward   = ($rw | Measure-Object -Maximum).Maximum
        OnTimePct   = [Math]::Round(($rows | Measure-Object -Property OnTimePct   -Average).Average, 1)
        AvgLateness = [Math]::Round(($rows | Measure-Object -Property AvgLateness -Average).Average, 2)
        Seeds       = $Seeds.Count
        PerSeed     = $rows
    }
}

# Validation shifts (seeds 2001-2010): for checkpoints and fitness, never the test set.
function Get-VBAFProductionValidationSeeds { return [int[]](2001..2010) }

# ---------- v6.0: a production-cell shift, step by step (for the window's "The shift" and "Side by side") ----------
# Built on the general Get-VBAFTrace plus a production-cell snapshot (clock, queue length, the first Slots orders).
# Each step gets: ClockBefore/After, QueueLen, Visible (Id, Proc, Deadline, Slack), Action, ChosenId,
# Outcome (ontime | late | idle = empty queue, not the brain's fault | invalid = an empty slot was picked), Reward, Total.
function Get-VBAFShiftTrace {
    param($World, $Agent = $null, [scriptblock]$Policy = $null, [int]$Seed, [int]$PolicySeed = 7)
    $snap = {
        param($e)
        $q = $e.Queue; $n = [Math]::Min([int]$e.Slots, [int]$q.Count)
        $vis = @(for ($i = 0; $i -lt $n; $i++) { $o = $q[$i]; [pscustomobject]@{ Id = [int]$o.Id; Proc = [int]$o.Proc; Deadline = [int]$o.Deadline; Slack = ([int]$o.Deadline - [int]$e.Clock - [int]$o.Proc) } })
        [pscustomobject]@{ Clock = [int]$e.Clock; QueueLen = [int]$q.Count; Visible = $vis }
    }
    if ($null -ne $Agent) { $tr = Get-VBAFTrace -Environment $World -Agent $Agent -Seed $Seed -Snapshot $snap -PolicySeed $PolicySeed }
    else { $tr = Get-VBAFTrace -Environment $World -Policy $Policy -Seed $Seed -Snapshot $snap -PolicySeed $PolicySeed }
    $sn = @($tr.Snapshots)
    $steps = [System.Collections.Generic.List[object]]::new()
    $st = @($tr.Steps)
    for ($k = 0; $k -lt $st.Count; $k++) {
        $s = $st[$k]; $b = $sn[$k]; $a = $sn[$k + 1]
        $vis = @($b.Visible)
        $chosenId = 0; $chosenDeadline = 0
        if ($b.QueueLen -gt 0 -and $s.Action -ge 0 -and $s.Action -lt $vis.Count) { $chosenId = $vis[$s.Action].Id; $chosenDeadline = $vis[$s.Action].Deadline }
        $outcome = 'idle'
        if ($b.QueueLen -gt 0) {
            if ($chosenId -eq 0) { $outcome = 'invalid' } elseif ([int]$a.Clock -le $chosenDeadline) { $outcome = 'ontime' } else { $outcome = 'late' }
        }
        $steps.Add([pscustomobject]@{ Step = $k + 1; ClockBefore = [int]$b.Clock; ClockAfter = [int]$a.Clock; QueueLen = [int]$b.QueueLen
            Visible = $vis; Action = [int]$s.Action; ChosenId = $chosenId; Outcome = $outcome; Reward = [double]$s.Reward; Total = [double]$s.Total })
    }
    return [pscustomobject]@{ Seed = $Seed; Steps = @($steps); Stats = $World.GetShiftStats() }
}
# The brains of a study (ResultDir of Invoke-VBAFEvolutionStudy): Brain 0 (the SPT rule), and -- when the final-test
# models exist -- the control (baseline genome) and the champion, both for the FIRST final seed.
function Get-VBAFShiftBrains([string]$ResultDir) {
    $b = [ordered]@{}
    $b['Brain 0 (SPT rule)'] = @{ Policy = (Get-VBAFProductionRules)['SPT'].Policy }
    $sp = $null
    foreach ($n in 'evolution-summary.json', 'phase4c.json') { $p = Join-Path $ResultDir $n; if (Test-Path $p) { $sp = $p; break } }
    if ($null -eq $sp) { return $b }
    $s = (Get-Content $sp -Raw -Encoding UTF8 | ConvertFrom-Json)
    $seed = [int]@($s.FinalSeeds)[0]
    $cm = Join-Path $ResultDir ('final-control-s{0}-best.xml' -f $seed)
    if (Test-Path $cm) { $b[('Control (baseline genome, seed {0})' -f $seed)] = @{ Agent = (Restore-VBAFBrain -Genome (Get-VBAFBaselineGenome) -BrainSeed $seed -ModelPath $cm) } }
    $hm = Join-Path $ResultDir ('final-champion-s{0}-best.xml' -f $seed)
    if (Test-Path $hm) { $b[('Champion {0} (seed {1})' -f $s.Champion, $seed)] = @{ Agent = (Restore-VBAFBrain -Genome (ConvertTo-VBAFGenome $s.ChampionGenome) -BrainSeed $seed -ModelPath $hm) } }
    return $b
}
function Get-VBAFShiftTraceFor($World, $Brain, [int]$Seed) {
    if ($Brain.ContainsKey('Agent')) { return Get-VBAFShiftTrace -World $World -Agent $Brain.Agent -Seed $Seed }
    return Get-VBAFShiftTrace -World $World -Policy $Brain.Policy -Seed $Seed
}
