#Requires -Version 5.1

<#
.SYNOPSIS
    Metrics Collector for ML/RL training
.DESCRIPTION
    Collects, stores, and provides access to training metrics
    for visualization and analysis.
.NOTES
    Part of VBAF (Visual Business Automation Framework)
    FIXED: Ensures all stored values are [double] not arrays
#>

class MetricsCollector {
    # Properties
    [System.Collections.ArrayList]$ErrorHistory        # Neural network errors
    [System.Collections.ArrayList]$RewardHistory       # RL rewards
    [System.Collections.ArrayList]$EpsilonHistory      # Exploration rate
    [System.Collections.ArrayList]$LossHistory         # Loss values
    [System.Collections.ArrayList]$AccuracyHistory     # Accuracy over time
    [hashtable]$CustomMetrics                          # User-defined metrics
    [int]$MaxHistory                                   # Maximum history size
    
    # Constructor
    MetricsCollector([int]$maxHistory) {
        $this.ErrorHistory = New-Object System.Collections.ArrayList
        $this.RewardHistory = New-Object System.Collections.ArrayList
        $this.EpsilonHistory = New-Object System.Collections.ArrayList
        $this.LossHistory = New-Object System.Collections.ArrayList
        $this.AccuracyHistory = New-Object System.Collections.ArrayList
        $this.CustomMetrics = @{}
        $this.MaxHistory = $maxHistory
    }
    
    # Default constructor
    MetricsCollector() {
        $this.ErrorHistory = New-Object System.Collections.ArrayList
        $this.RewardHistory = New-Object System.Collections.ArrayList
        $this.EpsilonHistory = New-Object System.Collections.ArrayList
        $this.LossHistory = New-Object System.Collections.ArrayList
        $this.AccuracyHistory = New-Object System.Collections.ArrayList
        $this.CustomMetrics = @{}
        $this.MaxHistory = 1000
    }
    
    # Record error (neural networks)
    [void] RecordError([double]$error) {
        $this.ErrorHistory.Add($error) | Out-Null
        $this.TrimHistory($this.ErrorHistory)
    }
    
    # Record reward (RL)
    [void] RecordReward([double]$reward) {
        $this.RewardHistory.Add($reward) | Out-Null
        $this.TrimHistory($this.RewardHistory)
    }
    
    # Record epsilon (RL exploration)
    [void] RecordEpsilon([double]$epsilon) {
        $this.EpsilonHistory.Add($epsilon) | Out-Null
        $this.TrimHistory($this.EpsilonHistory)
    }
    
    # Record loss
    [void] RecordLoss([double]$loss) {
        $this.LossHistory.Add($loss) | Out-Null
        $this.TrimHistory($this.LossHistory)
    }
    
    # Record accuracy
    [void] RecordAccuracy([double]$accuracy) {
        $this.AccuracyHistory.Add($accuracy) | Out-Null
        $this.TrimHistory($this.AccuracyHistory)
    }
    
    # Record custom metric
    [void] RecordCustom([string]$name, [double]$value) {
        if (-not $this.CustomMetrics.ContainsKey($name)) {
            $this.CustomMetrics[$name] = New-Object System.Collections.ArrayList
        }
        
        $this.CustomMetrics[$name].Add($value) | Out-Null
        $this.TrimHistory($this.CustomMetrics[$name])
    }
    
    # Trim history to max size
    hidden [void] TrimHistory([System.Collections.ArrayList]$history) {
        if ($history.Count -gt $this.MaxHistory) {
            $removeCount = $history.Count - $this.MaxHistory
            $history.RemoveRange(0, $removeCount)
        }
    }
    
    # Get moving average - FIXED VERSION WITH EXPLICIT TYPE CASTING
    [double[]] GetMovingAverage([System.Collections.ArrayList]$data, [int]$windowSize) {
        if ($data.Count -eq 0) {
            return @()
        }
        
        $result = New-Object System.Collections.ArrayList
        
        for ($i = 0; $i -lt $data.Count; $i++) {
            $start = [Math]::Max(0, $i - $windowSize + 1)
            $sum = 0.0
            $count = 0
            
            for ($j = $start; $j -le $i; $j++) {
                # Explicit cast to double to avoid array operation issues
                $val = [double]($data[$j])
                $sum = $sum + $val
                $count++
            }
            
            $average = $sum / $count
            $result.Add($average) | Out-Null
        }
        
        return $result.ToArray()
    }
    
    # Get statistics for a metric - FIXED VERSION WITH EXPLICIT TYPE CASTING
    [hashtable] GetStats([System.Collections.ArrayList]$data) {
        if ($data.Count -eq 0) {
            return @{
                Count = 0
                Min = 0.0
                Max = 0.0
                Mean = 0.0
                Latest = 0.0
            }
        }
        
        # Explicit casting for first element
        $min = [double]($data[0])
        $max = [double]($data[0])
        $sum = 0.0
        
        foreach ($item in $data) {
            # Explicit cast each value to double
            $value = [double]$item
            
            if ($value -lt $min) { $min = $value }
            if ($value -gt $max) { $max = $value }
            $sum = $sum + $value
        }
        
        $mean = $sum / $data.Count
        $latest = [double]($data[$data.Count - 1])
        
        return @{
            Count = $data.Count
            Min = $min
            Max = $max
            Mean = $mean
            Latest = $latest
        }
    }
    
    # Get all metrics summary
    [hashtable] GetSummary() {
        return @{
            Error = $this.GetStats($this.ErrorHistory)
            Reward = $this.GetStats($this.RewardHistory)
            Epsilon = $this.GetStats($this.EpsilonHistory)
            Loss = $this.GetStats($this.LossHistory)
            Accuracy = $this.GetStats($this.AccuracyHistory)
            TotalDataPoints = $this.ErrorHistory.Count + $this.RewardHistory.Count
        }
    }
    
    # Clear all metrics
    [void] Reset() {
        $this.ErrorHistory.Clear()
        $this.RewardHistory.Clear()
        $this.EpsilonHistory.Clear()
        $this.LossHistory.Clear()
        $this.AccuracyHistory.Clear()
        $this.CustomMetrics.Clear()
    }
}

