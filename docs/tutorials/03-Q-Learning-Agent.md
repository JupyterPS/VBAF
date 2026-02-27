[← Back to Tutorials](README.md) | [🏠 Home](../../README.md)

# Tutorial 03: Your First Q-Learning Agent

**Teach an agent to navigate through trial and error** 🤖

> **Prerequisites:** Tutorial 01 completed, VBAF loaded
> **Time:** 20-25 minutes
> **Difficulty:** Beginner-Intermediate

---

## What You Will Learn

- What reinforcement learning is and why it matters
- How a Q-Learning agent makes decisions
- How agents improve through trial and error
- How to read and interpret Q-values

---

## The Concept: Learning by Doing

Unlike neural networks that learn from labeled examples, a reinforcement learning
agent learns by **interacting with an environment**:

1. Agent observes current **state**
2. Agent chooses an **action**
3. Environment returns a **reward** (positive or negative)
4. Agent updates its knowledge
5. Repeat until agent masters the task

---

## The Problem: Grid World

Imagine a simple grid:
```
[S] [ ] [G]    S = Start
[ ] [X] [ ]    G = Goal  (+10 reward)
[ ] [ ] [ ]    X = Trap  (-5 reward)
```

The agent must learn to reach the Goal while avoiding the Trap.

---

## Step 1: Load the Framework
```powershell
. .\VBAF.LoadAll.ps1
```

---

## Step 2: Create the Agent
```powershell
$actions = @("Up", "Down", "Left", "Right")

$agent = New-Object QLearningAgent -ArgumentList $actions, 0.1, 0.3

Write-Host "RL Agent created:"
Write-Host "  Actions: $($actions -join ', ')"
Write-Host "  Learning Rate: 0.1"
Write-Host "  Exploration (epsilon): 0.3"
```

**Parameters explained:**
- **Learning Rate (0.1):** How fast the agent updates its knowledge
- **Epsilon (0.3):** 30% chance of random exploration vs using what it knows

---

## Step 3: Define the Environment
```powershell
function Simulate-Step {
    param($state, $action)

    $outcomes = @{
        "Start-Right"      = @{NextState="Middle"; Reward=0}
        "Start-Down"       = @{NextState="BottomLeft"; Reward=0}
        "Middle-Right"     = @{NextState="Goal"; Reward=10}
        "Middle-Up"        = @{NextState="Trap"; Reward=-5}
        "BottomLeft-Right" = @{NextState="Bottom"; Reward=0}
        "Bottom-Up"        = @{NextState="Middle"; Reward=0}
    }

    $key = "$state-$action"
    if ($outcomes.ContainsKey($key)) {
        return $outcomes[$key]
    } else {
        return @{NextState=$state; Reward=-1}
    }
}
```

---

## Step 4: Train the Agent
```powershell
Write-Host "Training for 100 episodes..." -ForegroundColor Cyan

$totalRewards = @()

for ($episode = 0; $episode -lt 100; $episode++) {
    $state = "Start"
    $episodeReward = 0

    for ($step = 0; $step -lt 10; $step++) {
        $action = $agent.ChooseAction($state)
        $result = Simulate-Step $state $action
        $agent.Learn($state, $action, $result.Reward, $result.NextState)

        $episodeReward += $result.Reward
        $state = $result.NextState

        if ($state -eq "Goal") { break }
    }

    $totalRewards += $episodeReward
    $agent.DecayEpsilon(0.99)

    if (($episode + 1) % 20 -eq 0) {
        $avgReward = ($totalRewards[-20..-1] | Measure-Object -Average).Average
        Write-Host ("Episode {0}: Avg Reward = {1:F2}, epsilon = {2:F3}" -f `
            ($episode + 1), $avgReward, $agent.Epsilon)
    }
}

Write-Host "Training complete!" -ForegroundColor Green
```

**Expected output:**
```
Episode 20: Avg Reward = -8.50, epsilon = 0.818
Episode 40: Avg Reward =  2.30, epsilon = 0.670
Episode 60: Avg Reward =  6.20, epsilon = 0.548
Episode 80: Avg Reward =  8.40, epsilon = 0.449
Episode 100: Avg Reward = 9.10, epsilon = 0.367
Training complete!
```

Notice how rewards **increase over time** — the agent is learning!

---

## Step 5: Inspect What the Agent Learned
```powershell
Write-Host "`n=== Learned Q-Values ===" -ForegroundColor Cyan

$agent.QTable.GetEnumerator() |
    Sort-Object Value -Descending |
    Select-Object -First 8 |
    ForEach-Object {
        Write-Host ("{0,-25} = {1:F2}" -f $_.Key, $_.Value)
    }
```

**Expected output:**
```
Middle-Right              =  8.92   <- Best move: reach goal!
Start-Right               =  7.15
Bottom-Up                 =  6.32
Start-Down                =  5.41
Middle-Up                 = -3.87   <- Learned: avoid trap!
```

The agent discovered the optimal path entirely through trial and error:
- **Start → Right → Middle → Right → Goal**

---

## Understanding Q-Values

A Q-value represents how good an action is from a given state:

- **High Q-value:** This action leads toward reward
- **Low/negative Q-value:** This action leads toward penalty
- **Agent strategy:** Always pick the highest Q-value action (when not exploring)

---

## Troubleshooting

**Agent not improving?**
- Train for more episodes: change `100` to `500`
- Adjust epsilon decay: change `0.99` to `0.995` for slower decay

**All Q-values are zero?**
- Make sure `$agent.Learn()` is being called inside the loop
- Check that rewards are non-zero in your environment

---

## What You Learned

- Reinforcement learning agents improve through trial and error
- Epsilon controls the balance between exploration and exploitation
- Q-values store the agent learned knowledge about state-action pairs
- Epsilon decay shifts the agent from exploring to exploiting over time

---

## Next Steps

- **Tutorial 04:** Multi-agent market simulation with 4 competing companies
- **Tutorial 06:** Visualize your agent learning in real-time on a dashboard
- **Examples/02-Castle-Learning:** See Q-Learning used for generative art

---

*VBAF Version: 1.0.0 | PowerShell 5.1+ | Windows 10/11*


---
[← Back to Tutorials](README.md) | [Next: Tutorial 04 →](04-Multi-Agent-Market.md)
