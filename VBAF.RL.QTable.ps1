#Requires -Version 5.1

<#
.SYNOPSIS
    Q-Table for storing state-action values
.DESCRIPTION
    Hash table-based storage for Q-Learning.
    Maps (state, action) pairs to Q-values.
.NOTES
    Part of VBAF (Visual Business Automation Framework)
#>

class QTable {
    # Properties
    [hashtable]$Table           # Stores Q-values
    [double]$DefaultValue       # Initial Q-value for new state-action pairs
    [int]$AccessCount           # Statistics: total lookups
    [int]$UpdateCount           # Statistics: total updates
    
    # Constructor
    QTable([double]$defaultValue) {
        $this.Table = @{}
        $this.DefaultValue = $defaultValue
        $this.AccessCount = 0
        $this.UpdateCount = 0
    }
    
    # Default constructor (Q-values start at 0)
    QTable() {
        $this.Table = @{}
        $this.DefaultValue = 0.0
        $this.AccessCount = 0
        $this.UpdateCount = 0
    }
    
    # Create key from state and action
    hidden [string] MakeKey([string]$state, [string]$action) {
        return "$state|$action"
    }
    
    # Get Q-value for (state, action)
    [double] Get([string]$state, [string]$action) {
        $key = $this.MakeKey($state, $action)
        $this.AccessCount++
        
        if ($this.Table.ContainsKey($key)) {
            return $this.Table[$key]
        } else {
            # First time seeing this state-action: return default
            return $this.DefaultValue
        }
    }
    
    # Set Q-value for (state, action)
    [void] Set([string]$state, [string]$action, [double]$value) {
        $key = $this.MakeKey($state, $action)
        $this.Table[$key] = $value
        $this.UpdateCount++
    }
    
    # Update Q-value using Q-Learning formula
    # Q(s,a) ← Q(s,a) + α[r + γ·max(Q(s',a')) - Q(s,a)]
    [void] Update([string]$state, [string]$action, [double]$reward, 
                  [string]$nextState, [string[]]$possibleActions, 
                  [double]$alpha, [double]$gamma) {
        
        # Current Q-value
        $currentQ = $this.Get($state, $action)
        
        # Maximum Q-value in next state
        $maxNextQ = $this.DefaultValue
        if ($possibleActions.Count -gt 0) {
            foreach ($nextAction in $possibleActions) {
                $nextQ = $this.Get($nextState, $nextAction)
                if ($nextQ -gt $maxNextQ) {
                    $maxNextQ = $nextQ
                }
            }
        }
        
        # Q-Learning update
        $newQ = $currentQ + $alpha * ($reward + $gamma * $maxNextQ - $currentQ)
        
        # Store updated value
        $this.Set($state, $action, $newQ)
    }
    
    # Get best action for a state (highest Q-value)
    [string] GetBestAction([string]$state, [string[]]$possibleActions) {
        if ($possibleActions.Count -eq 0) {
            throw "No possible actions provided"
        }
        
        $bestAction = $possibleActions[0]
        $bestQ = $this.Get($state, $bestAction)
        
        for ($i = 1; $i -lt $possibleActions.Count; $i++) {
            $action = $possibleActions[$i]
            $q = $this.Get($state, $action)
            
            if ($q -gt $bestQ) {
                $bestQ = $q
                $bestAction = $action
            }
        }
        
        return $bestAction
    }
    
    # Get all Q-values for a state
    [hashtable] GetStateValues([string]$state, [string[]]$possibleActions) {
        $values = @{}
        
        foreach ($action in $possibleActions) {
            $values[$action] = $this.Get($state, $action)
        }
        
        return $values
    }
    
    # Export Q-table (save learned knowledge)
    [hashtable] ExportTable() {
        return @{
            Table = $this.Table
            DefaultValue = $this.DefaultValue
            AccessCount = $this.AccessCount
            UpdateCount = $this.UpdateCount
        }
    }
    
    # Import Q-table (load learned knowledge)
    [void] ImportTable([hashtable]$data) {
        $this.Table = $data.Table
        $this.DefaultValue = $data.DefaultValue
        $this.AccessCount = $data.AccessCount
        $this.UpdateCount = $data.UpdateCount
    }
    
    # Get statistics
    [hashtable] GetStats() {
        return @{
            TotalEntries = $this.Table.Count
            AccessCount = $this.AccessCount
            UpdateCount = $this.UpdateCount
            DefaultValue = $this.DefaultValue
        }
    }
    
    # Clear all learned values
    [void] Reset() {
        $this.Table.Clear()
        $this.AccessCount = 0
        $this.UpdateCount = 0
    }
}

 