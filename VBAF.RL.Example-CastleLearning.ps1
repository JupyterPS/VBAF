#Requires -Version 5.1

<#
.SYNOPSIS
    Q-Learning Castle Agent -- Training Demo
.DESCRIPTION
    Demonstrates a Q-Learning agent learning to generate castle sequences.

    WHAT YOU ARE LEARNING HERE:
    ============================
    This example shows Q-Learning applied to a creative problem --
    generating sequences of castle types that are visually varied
    and engaging.

    Unlike XOR (which has one correct answer), this is an OPTIMISATION
    problem -- there is no single right sequence, but some sequences
    are better than others according to a reward function.

    THE ENVIRONMENT:
    ================
    State:  the last 1-2 castle types chosen (recent history)
    Actions: choose the next castle type from 8 options
    Reward: +2 for variety, -1 for repetition, plus visual balance
            and engagement scores (simulated here with random values)

    WHAT THE AGENT LEARNS:
    =======================
    Over 100 episodes the agent discovers that:
    - Repeating the same castle type is penalised
    - Mixing different types earns higher rewards
    - Some transitions (e.g. Gothic -> Fairy Tale) score better
      than others on average

    THE Q-TABLE GROWS AS THE AGENT EXPLORES:
    =========================================
    Episode 1:   Q-table has ~0 entries (nothing visited yet)
    Episode 10:  Q-table growing -- common transitions recorded
    Episode 100: Q-table stable -- agent exploiting learned values

    Watch the Q-table size grow during training.
    Watch epsilon decay from 1.0 (random) toward 0.01 (learned).
    Watch recent average reward increase as the agent improves.

    EXPLORATION vs EXPLOITATION IN PRACTICE:
    =========================================
    Early episodes: epsilon ~1.0 -- agent tries everything randomly
    Middle episodes: epsilon ~0.5 -- mix of random and learned choices
    Late episodes: epsilon ~0.01 -- agent mostly uses learned Q-values

    This gradual shift is called the epsilon schedule.
    Too fast: agent stops exploring before finding good strategies.
    Too slow: agent wastes time exploring when it already knows what works.

    REWARD DESIGN NOTE:
    ===================
    In this example, visual balance and engagement are SIMULATED
    with random values. In a real application, these would come from
    user feedback, aesthetic scoring algorithms, or A/B test results.
    The random simulation still teaches the variety reward correctly.

.NOTES
    Part of VBAF (Visual AI & Reinforcement Learning Framework)
    Educational use -- compare output with VBAF.RL.DQN.ps1 to see
    how neural networks handle larger state spaces.
    Requires: VBAF.RL.QTable.ps1, VBAF.RL.ExperienceReplay.ps1,
              VBAF.RL.QLearningAgent.ps1
#>

$basePath = $PSScriptRoot

. (Join-Path $basePath "VBAF.RL.QTable.ps1")
. (Join-Path $basePath "VBAF.RL.ExperienceReplay.ps1")
. (Join-Path $basePath "VBAF.RL.QLearningAgent.ps1")

Write-Host ""
Write-Host "+----------------------------------------------+" -ForegroundColor Cyan
Write-Host "|   Q-LEARNING CASTLE AGENT - TRAINING DEMO   |" -ForegroundColor Cyan
Write-Host "+----------------------------------------------+" -ForegroundColor Cyan

#  THE ACTION SPACE 
# These are the castle types the agent can choose from.
# Each is a discrete action -- the agent picks one per step.
# 8 actions x 8 possible states = 64 Q-table entries at most.
# This is small enough for a Q-table (no neural network needed).
$castleTypes = @(
    "Gothic", "FairyTale", "Fortress", "Palace",
    "Wizard", "Cathedral", "Oriental", "Ruins"
)

Write-Host ""
Write-Host "Available Castle Types (the action space):" -ForegroundColor Yellow
foreach ($type in $castleTypes) {
    Write-Host "  - $type"
}

#  CREATE THE AGENT 
# Default constructor uses:
#   alpha (learning rate) = 0.1
#   gamma (discount)      = 0.9
#   epsilon               = 1.0 (start fully random)
Write-Host ""
Write-Host "Creating Q-Learning Agent..." -ForegroundColor Yellow
$agent = New-Object QLearningAgent -ArgumentList @(,$castleTypes)

Write-Host "  Alpha (learning rate) : $($agent.Alpha)   -- how fast Q-values update"
Write-Host "  Gamma (discount)      : $($agent.Gamma)   -- how much future rewards matter"
Write-Host "  Epsilon (exploration) : $($agent.Epsilon) -- start 100% random"

#  TRAINING CONFIGURATION 
# 100 episodes x 10 steps = 1000 total (state, action, reward) interactions.
# Each interaction potentially updates one Q-table entry.
# After 1000 updates the agent has a reasonable Q-table.
$episodes        = 100
$stepsPerEpisode = 10

Write-Host ""
Write-Host "Training Configuration:" -ForegroundColor Yellow
Write-Host "  Episodes           : $episodes"
Write-Host "  Steps per episode  : $stepsPerEpisode"
Write-Host "  Total interactions : $($episodes * $stepsPerEpisode)"

# recentCastles tracks the last few castle types chosen.
# This becomes the STATE that the agent observes.
# State = what the agent currently knows about the sequence so far.
$recentCastles = New-Object System.Collections.ArrayList

Write-Host ""
Write-Host ("-" * 60) -ForegroundColor Cyan
Write-Host "TRAINING IN PROGRESS" -ForegroundColor Cyan
Write-Host ("-" * 60) -ForegroundColor Cyan
Write-Host ""

#  MAIN TRAINING LOOP 
for ($ep = 1; $ep -le $episodes; $ep++) {
    $episodeReward = 0.0

    for ($step = 1; $step -le $stepsPerEpisode; $step++) {

        # OBSERVE: convert recent history into a state string
        # e.g. "Gothic|Fortress" = last two castle types
        $context = @{ RecentTypes = $recentCastles }
        $state   = $agent.GetState($context)

        # ACT: epsilon-greedy -- random or best known action
        $action  = $agent.ChooseAction($state)

        # ENVIRONMENT RESPONSE:
        # IsVaried = true if this castle differs from the previous one
        # VisualBalance and Engagement are simulated here with random values.
        # In a real system these would come from user ratings or scoring.
        $isVaried     = ($recentCastles.Count -eq 0) -or ($recentCastles[-1] -ne $action)
        $visualBalance = Get-Random -Minimum 0.0 -Maximum 1.0
        $engagement    = Get-Random -Minimum 0.0 -Maximum 1.0

        $outcome = @{
            CastleType    = $action
            IsVaried      = $isVaried
            VisualBalance = $visualBalance
            Engagement    = $engagement
        }

        # REWARD: shaped to encourage variety and quality
        $reward         = $agent.CalculateReward($outcome)
        $episodeReward += $reward

        # UPDATE STATE: add chosen castle to recent history
        $recentCastles.Add($action) | Out-Null
        if ($recentCastles.Count -gt 5) {
            $recentCastles.RemoveAt(0)   # Keep only last 5
        }

        # OBSERVE NEXT STATE: what does the agent see now
        $nextContext = @{ RecentTypes = $recentCastles }
        $nextState   = $agent.GetState($nextContext)

        # LEARN: update Q(state, action) using Bellman equation
        $agent.Learn($state, $action, $reward, $nextState)
    }

    # END EPISODE: record reward, decay epsilon
    $agent.EndEpisode($episodeReward)

    # Print progress every 10 episodes
    if ($ep % 10 -eq 0 -or $ep -eq 1 -or $ep -eq $episodes) {
        $stats      = $agent.GetStats()
        $exploitPct = (1.0 - $stats.ExplorationRatio) * 100

        Write-Host ("Episode {0,3} | Reward: {1,6:F2} | Epsilon: {2:F3} | Exploit: {3,5:F1}% | Q-Table: {4,3} entries" -f `
            $ep, $episodeReward, $stats.Epsilon, $exploitPct, $stats.QTableSize)
    }
}

Write-Host ""
Write-Host "  Training complete!" -ForegroundColor Green

#  FINAL RESULTS 
Write-Host ""
Write-Host ("-" * 60) -ForegroundColor Cyan
Write-Host "FINAL RESULTS" -ForegroundColor Cyan
Write-Host ("-" * 60) -ForegroundColor Cyan

$finalStats = $agent.GetStats()

Write-Host ""
Write-Host "Learning Progress:" -ForegroundColor Yellow
Write-Host "  Total Episodes         : $($finalStats.Episode)"
Write-Host "  Total Reward           : $($finalStats.TotalReward.ToString('F2'))"
Write-Host "  Average Reward         : $($finalStats.AverageReward.ToString('F2'))"
Write-Host "  Recent Average (last 10): $($finalStats.RecentAverageReward.ToString('F2'))"

Write-Host ""
Write-Host "Exploration vs Exploitation:" -ForegroundColor Yellow
Write-Host "  Explorations  : $($finalStats.ExplorationCount)  (random actions taken)"
Write-Host "  Exploitations : $($finalStats.ExploitationCount)  (learned actions taken)"
Write-Host "  Final Epsilon : $($finalStats.Epsilon.ToString('F3'))  (target: 0.010)"

Write-Host ""
Write-Host "Knowledge Base:" -ForegroundColor Yellow
Write-Host "  Q-Table Entries    : $($finalStats.QTableSize)  (state-action pairs learned)"
Write-Host "  Experiences Stored : $($finalStats.MemorySize)"

#  INSPECT WHAT WAS LEARNED 
# This is the unique advantage of Q-learning over DQN:
# you can READ the Q-table and understand exactly what the agent learned.
# A DQN stores knowledge in neural network weights -- much harder to inspect.
Write-Host ""
Write-Host "Learned Q-Values by State:" -ForegroundColor Yellow
Write-Host "  (Positive = agent prefers this castle type in this state)" -ForegroundColor DarkGray
Write-Host "  (Negative = agent avoids this castle type in this state)" -ForegroundColor DarkGray

$statesFound = @()

for ($stateNum = 0; $stateNum -le 5; $stateNum++) {
    $qValues = $agent.GetQValues("$stateNum")

    $hasLearning = $false
    foreach ($val in $qValues.Values) {
        if ($val -ne 0) { $hasLearning = $true; break }
    }

    if ($hasLearning) {
        $statesFound += $stateNum
        Write-Host ""
        Write-Host "  State '$stateNum':" -ForegroundColor Cyan

        $sorted = $qValues.GetEnumerator() | Sort-Object Value -Descending

        foreach ($item in $sorted) {
            if ($item.Value -ne 0) {
                $color = if ($item.Value -gt 0) { "Green" }
                         elseif ($item.Value -lt 0) { "Red" }
                         else { "Gray" }
                Write-Host ("    {0,-15} {1,8:F4}" -f $item.Key, $item.Value) -ForegroundColor $color
            }
        }
    }
}

if ($statesFound.Count -eq 0) {
    Write-Host ""
    Write-Host "  No learning detected -- Q-Learning update may not be working." -ForegroundColor Red
} else {
    Write-Host ""
    Write-Host "  Learning detected in states: $($statesFound -join ', ')" -ForegroundColor Green
}

#  IMPROVEMENT CHECK 
# If recent average > overall average, the agent improved during training.
# This is the key sign that Q-learning is working correctly.
if ($finalStats.RecentAverageReward -gt $finalStats.AverageReward) {
    Write-Host ""
    Write-Host "  Agent IMPROVED -- recent rewards higher than overall average!" -ForegroundColor Green
    Write-Host "  Q-learning successfully shifted from exploration to exploitation." -ForegroundColor DarkGray
} else {
    Write-Host ""
    Write-Host "  Agent performance stable -- try more episodes for further improvement." -ForegroundColor Yellow
}

Write-Host ""

# ============================================================================
# WHAT TO TRY NEXT:
# =================
# 1. Increase episodes to 500 -- watch Q-table grow and epsilon reach 0.01
# 2. Change stepsPerEpisode to 20 -- more interactions per episode
# 3. Print agent.QTable directly to see every learned value:
#       $agent.QTable | Format-Table
# 4. Compare with DQN on the same problem -- does neural network learn faster
# 5. Move on to: VBAF.Business.Test.CompanyMarket.ps1 -- multi-agent competition
# ============================================================================