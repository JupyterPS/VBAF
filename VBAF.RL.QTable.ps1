#Requires -Version 5.1

<#
.SYNOPSIS
    Q-Table -- hashtable storage for Q-Learning values
.DESCRIPTION
    Maps (state, action) pairs to Q-values and implements
    the Bellman update rule directly.

    WHAT YOU ARE LEARNING HERE:
    ============================
    The Q-Table is the memory of a Q-Learning agent.
    It stores one number for every (state, action) pair the agent
    has ever visited -- the estimated total future reward of taking
    that action in that state.

    HOW THE Q-TABLE WORKS:
    ======================
    Think of the Q-Table as a two-dimensional lookup table:

                  Action0   Action1   Action2
    State "A"      2.3       0.8      -1.2
    State "B"      0.0       3.1       1.5
    State "C"     -0.5       0.2       4.8

    To choose an action in state "B":
      Look up row "B": [0.0, 3.1, 1.5]
      Best value is 3.1 at Action1
      Agent chooses Action1

    This is "exploitation" -- using learned knowledge.
    During exploration, the agent ignores the table and picks randomly.

    HASHTABLE IMPLEMENTATION:
    =========================
    We cannot use a real 2D array because:
    - States are strings (not integers)
    - We do not know all states in advance
    - Most state-action pairs are never visited

    Solution: use a hashtable with "state|action" as the key.
    Key: "TowerA|Gothic" -> Value: 2.3
    Key: "TowerA|Palace" -> Value: -0.5

    This is called a SPARSE representation -- only visited pairs stored.
    Much more memory efficient than a full 2D array for large state spaces.

    DEFAULT VALUE:
    ==============
    When a state-action pair has never been visited, we return DefaultValue.
    DefaultValue = 0.0 is the standard (neutral starting point).
    DefaultValue > 0 = OPTIMISTIC initialisation (encourages exploration).
    DefaultValue < 0 = PESSIMISTIC initialisation (discourages unvisited states).

    THE BELLMAN UPDATE (built into QTable.Update()):
    ================================================
    Q(s,a) <- Q(s,a) + alpha * [r + gamma * max Q(s',a') - Q(s,a)]

    This is the same formula used in QLearningAgent.Learn().
    QTable encapsulates the formula so you do not have to repeat it.

    STATISTICS (AccessCount, UpdateCount):
    =======================================
    These counters help diagnose learning:
    - AccessCount grows fast early (agent exploring many states)
    - UpdateCount shows how many Q-values have been refined
    - High Access but low Update = agent not learning (bug)
    - TotalEntries shows how much of the state space was visited

    EXPORT/IMPORT:
    ==============
    ExportTable() and ImportTable() allow saving learned knowledge.
    Export to JSON, save to disk, reload in next session.
    The agent "remembers" what it learned across sessions.

.NOTES
    Part of VBAF (Visual AI & Reinforcement Learning Framework)
    Educational use -- inspect the Table hashtable to see what was learned.
    Used by: VBAF.RL.QLearningAgent.ps1
#>

class QTable {

    [hashtable]$Table         # The actual Q-value storage: "state|action" -> double
    [double]$DefaultValue     # Value returned for unseen state-action pairs
    [int]$AccessCount         # Total number of Q-value lookups (diagnostic)
    [int]$UpdateCount         # Total number of Q-value updates (diagnostic)

    # Constructor with custom default value
    # Use DefaultValue > 0 for optimistic initialisation
    # (encourages agent to try every action at least once)
    QTable([double]$defaultValue) {
        $this.Table        = @{}
        $this.DefaultValue = $defaultValue
        $this.AccessCount  = 0
        $this.UpdateCount  = 0
    }

    # Default constructor -- Q-values start at 0.0 (neutral)
    QTable() {
        $this.Table        = @{}
        $this.DefaultValue = 0.0
        $this.AccessCount  = 0
        $this.UpdateCount  = 0
    }

    # Create a unique key for each (state, action) pair.
    # The pipe character | is the separator -- states and actions
    # should not contain | to avoid key collisions.
    hidden [string] MakeKey([string]$state, [string]$action) {
        return "$state|$action"
    }

    # Look up Q(state, action).
    # Returns DefaultValue if this pair has never been seen.
    # Increments AccessCount for diagnostics.
    [double] Get([string]$state, [string]$action) {
        $key = $this.MakeKey($state, $action)
        $this.AccessCount++

        if ($this.Table.ContainsKey($key)) {
            return $this.Table[$key]
        } else {
            return $this.DefaultValue   # Unseen pair -- return neutral value
        }
    }

    # Store Q(state, action) = value.
    # Creates a new entry or overwrites an existing one.
    [void] Set([string]$state, [string]$action, [double]$value) {
        $key = $this.MakeKey($state, $action)
        $this.Table[$key] = $value
        $this.UpdateCount++
    }

    # THE BELLMAN UPDATE -- the core of Q-Learning.
    #
    # Q(s,a) <- Q(s,a) + alpha * [r + gamma * max Q(s',a') - Q(s,a)]
    #
    # Parameters:
    #   state           -- current state s
    #   action          -- action taken a
    #   reward          -- reward received r
    #   nextState       -- resulting state s'
    #   possibleActions -- all actions available in s' (to find max Q(s',a'))
    #   alpha           -- learning rate (how much to update)
    #   gamma           -- discount factor (how much to value future rewards)
    #
    # Step by step:
    #   1. Look up current estimate: Q(s,a)
    #   2. Find best future value: max Q(s',a') over all actions
    #   3. Compute Bellman target: r + gamma * max Q(s',a')
    #   4. Compute TD error: target - current estimate
    #   5. Update: new Q = old Q + alpha * TD error
    [void] Update([string]$state, [string]$action, [double]$reward,
                  [string]$nextState, [string[]]$possibleActions,
                  [double]$alpha, [double]$gamma) {

        $currentQ = $this.Get($state, $action)

        # Find max Q-value over all actions in the next state
        $maxNextQ = $this.DefaultValue
        if ($possibleActions.Count -gt 0) {
            foreach ($nextAction in $possibleActions) {
                $nextQ = $this.Get($nextState, $nextAction)
                if ($nextQ -gt $maxNextQ) { $maxNextQ = $nextQ }
            }
        }

        # Bellman update: move Q(s,a) toward the target
        $newQ = $currentQ + $alpha * ($reward + $gamma * $maxNextQ - $currentQ)

        $this.Set($state, $action, $newQ)
    }

    # Return the action with the highest Q-value in this state.
    # This is the GREEDY action -- what the agent believes is best.
    # Used during exploitation (when epsilon-greedy picks the best action).
    [string] GetBestAction([string]$state, [string[]]$possibleActions) {
        if ($possibleActions.Count -eq 0) {
            throw "No possible actions provided to GetBestAction"
        }

        $bestAction = $possibleActions[0]
        $bestQ      = $this.Get($state, $bestAction)

        for ($i = 1; $i -lt $possibleActions.Count; $i++) {
            $action = $possibleActions[$i]
            $q      = $this.Get($state, $action)
            if ($q -gt $bestQ) {
                $bestQ      = $q
                $bestAction = $action
            }
        }

        return $bestAction
    }

    # Return Q-values for ALL actions in this state.
    # Useful for printing what the agent learned about a specific state.
    # Example: $table.GetStateValues("TowerA", $actions)
    #   -> @{ "Gothic" = 2.3; "Palace" = -0.5; "Ruins" = 1.1 }
    [hashtable] GetStateValues([string]$state, [string[]]$possibleActions) {
        $values = @{}
        foreach ($action in $possibleActions) {
            $values[$action] = $this.Get($state, $action)
        }
        return $values
    }

    # Export the entire Q-table to a hashtable for saving.
    # Use ConvertTo-Json and Set-Content to save to disk.
    # Example:
    #   $table.ExportTable() | ConvertTo-Json | Set-Content "qtable.json"
    [hashtable] ExportTable() {
        return @{
            Table        = $this.Table
            DefaultValue = $this.DefaultValue
            AccessCount  = $this.AccessCount
            UpdateCount  = $this.UpdateCount
        }
    }

    # Restore a previously saved Q-table.
    # The agent picks up exactly where it left off.
    [void] ImportTable([hashtable]$data) {
        $this.Table        = $data.Table
        $this.DefaultValue = $data.DefaultValue
        $this.AccessCount  = $data.AccessCount
        $this.UpdateCount  = $data.UpdateCount
    }

    # Return diagnostic statistics.
    # TotalEntries: how many unique (state, action) pairs were visited
    # AccessCount: how many times Q-values were looked up
    # UpdateCount: how many times Q-values were changed
    [hashtable] GetStats() {
        return @{
            TotalEntries = $this.Table.Count
            AccessCount  = $this.AccessCount
            UpdateCount  = $this.UpdateCount
            DefaultValue = $this.DefaultValue
        }
    }

    # Wipe all learned values -- start fresh.
    # AccessCount and UpdateCount also reset.
    [void] Reset() {
        $this.Table.Clear()
        $this.AccessCount = 0
        $this.UpdateCount = 0
    }
}

# ============================================================================
# QUICK REFERENCE
# ============================================================================
#
# CREATE A Q-TABLE:
#   $table = [QTable]::new()         # default value 0.0
#   $table = [QTable]::new(1.0)      # optimistic default (encourages exploration)
#
# READ AND WRITE:
#   $value = $table.Get("StateA", "ActionLeft")
#   $table.Set("StateA", "ActionLeft", 2.5)
#
# ONE-STEP UPDATE (Bellman equation built in):
#   $table.Update("StateA", "ActionLeft", 1.0, "StateB", $actions, 0.1, 0.9)
#
# FIND BEST ACTION:
#   $best = $table.GetBestAction("StateA", $actions)
#
# INSPECT WHAT WAS LEARNED:
#   $table.GetStateValues("StateA", $actions)
#   $table.GetStats()
#   $table.Table    # raw hashtable -- all keys and values
#
# SAVE AND LOAD:
#   $table.ExportTable() | ConvertTo-Json | Set-Content "qtable.json"
#   $data = Get-Content "qtable.json" | ConvertFrom-Json
#   $table.ImportTable($data)
#
# SEE ALSO:
#   VBAF.RL.QLearningAgent.ps1  -- uses QTable internally
# ============================================================================