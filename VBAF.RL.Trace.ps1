#Requires -Version 5.1
<#
.SYNOPSIS
    Get-VBAFTrace -- run an agent or a policy through one episode of ANY VBAF environment and record every step.
.DESCRIPTION
    VBAF environments follow one of two contracts (found while building v5.0):
      style A  Step($a) returns @{ NextState; Reward; Done }       (VBAFEnvironment and its children, DQN/PPO/A3C)
      style B  Step($a) returns nothing; read LastReward, LastDone   (the enterprise pillar environments)
               and GetState() afterwards
    The style is detected after the first step and reported. An environment without Step/Reset (style C, e.g.
    the Market and CastleCompetition simulations) gives a clear error instead of an empty trace.
    -Snapshot is an optional scriptblock param($env) taken BEFORE every step and once at the end, so an
    environment can add its own details (the value "after" step k is snapshot k+1).
.EXAMPLE
    $env = New-VBAFEnvironment -Name GridWorld -MaxSteps 50
    $t   = Get-VBAFTrace -Environment $env -Agent $agent
    $t.Steps | Format-Table Step, Action, Reward, Total, Done
#>
function Get-VBAFTrace {
    param(
        [Parameter(Mandatory = $true)] $Environment,
        $Agent = $null,
        [scriptblock] $Policy = $null,
        [int] $Seed = -1,
        [int] $MaxSteps = 10000,
        [scriptblock] $Snapshot = $null,
        [int] $PolicySeed = 7
    )
    if ($null -eq $Agent -and $null -eq $Policy) { throw 'Get-VBAFTrace: give -Agent or -Policy.' }
    $e = $Environment
    $methods = @($e.PSObject.Methods.Name)
    if (-not ($methods -contains 'Step') -or -not ($methods -contains 'Reset')) {
        throw ('Get-VBAFTrace: {0} has no Step/Reset (style C) and cannot be traced.' -f $e.GetType().Name)
    }
    $seedMethod = 'none'
    if ($Seed -ge 0 -and ($methods -contains 'ResetWithSeed')) {
        $state = $e.ResetWithSeed($Seed); $seedMethod = 'ResetWithSeed'
    } else {
        if ($Seed -ge 0) {
            if (Get-Command Set-VBAFSeed -ErrorAction SilentlyContinue) { Set-VBAFSeed $Seed; $seedMethod = 'Set-VBAFSeed' }
            else { Get-Random -SetSeed $Seed | Out-Null; $seedMethod = 'Get-Random' }
        }
        $state = $e.Reset()
    }
    $rng   = [System.Random]::new($PolicySeed)
    $steps = [System.Collections.Generic.List[object]]::new()
    $snaps = [System.Collections.Generic.List[object]]::new()
    $total = 0.0; $done = $false; $style = ''; $k = 0
    while (-not $done -and $k -lt $MaxSteps) {
        if ($null -ne $Snapshot) { $snaps.Add((& $Snapshot $e)) }
        $s0 = [double[]]@($state)
        if ($null -ne $Agent) { $a = [int]$Agent.Predict($s0) } else { $a = [int](& $Policy $s0 $rng) }
        $ret = $e.Step($a)
        if ($ret -is [hashtable] -and $ret.ContainsKey('NextState') -and $ret.ContainsKey('Reward') -and $ret.ContainsKey('Done')) {
            $thisStyle = 'A'; $r = [double]$ret.Reward; $done = [bool]$ret.Done; $state = $ret.NextState
        } elseif ((@($e.PSObject.Properties.Name) -contains 'LastReward') -and (@($e.PSObject.Properties.Name) -contains 'LastDone')) {
            $thisStyle = 'B'; $r = [double]$e.LastReward; $done = [bool]$e.LastDone; $state = $e.GetState()
        } else {
            throw ('Get-VBAFTrace: {0}.Step() returned neither NextState/Reward/Done (style A) nor set LastReward/LastDone (style B).' -f $e.GetType().Name)
        }
        if ($style -eq '') { $style = $thisStyle }
        $total += $r; $k++
        $steps.Add([pscustomobject]@{ Step = $k; State = $s0; Action = $a; Reward = $r; Total = $total; Done = $done })
    }
    if ($null -ne $Snapshot) { $snaps.Add((& $Snapshot $e)) }
    return [pscustomobject]@{ Environment = $e.GetType().Name; Style = $style; Seed = $Seed; SeedMethod = $seedMethod
        Steps = @($steps); StepCount = $k; TotalReward = $total; Finished = $done; Snapshots = @($snaps) }
}
