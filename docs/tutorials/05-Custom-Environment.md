# Tutorial 05: Building a Custom RL Environment

**Design your own world for an agent to learn in** 🌍

> **Prerequisites:** Tutorial 03 completed
> **Time:** 25-30 minutes
> **Difficulty:** Intermediate

---

## What You Will Learn

- What makes a good RL environment
- How to design states, actions, and rewards
- How to build a custom environment in PowerShell
- How to connect your environment to a VBAF agent

---

## The Three Elements of Any RL Environment

Every RL environment needs exactly three things:

**1. States** — What the agent can observe
Examples: grid position, temperature, account balance, inventory level

**2. Actions** — What the agent can do
Examples: move left/right, buy/sell, increase/decrease price

**3. Rewards** — Feedback signal after each action
Positive reward = good outcome, negative reward = bad outcome

The art of RL environment design is making rewards meaningful
without giving away the solution.

---

## Example: Building a Temperature Control Environment

An agent controls a thermostat. It must learn to keep temperature
in the comfort zone (18-22°C) using minimal energy.

### States
- Current temperature (rounded to nearest degree)
- Trend: rising, stable, or falling

### Actions
- HeatHigh: +3°C per step, costs 3 energy
- HeatLow: +1°C per step, costs 1 energy
- Off: no change, costs 0 energy
- Cool: -1°C per step, costs 1 energy

### Rewards
- Temperature in 18-22°C range: +5
- Temperature in 15-25°C range: +1
- Temperature outside 15-25°C: -5
- Energy penalty: -0.5 per energy unit used

---

## Step 1: Load the Framework
```powershell
. .\VBAF.LoadAll.ps1
```

---

## Step 2: Build the Environment
```powershell
# Environment state
$envState = @{
    Temperature = 15.0
    OutdoorTemp = 10.0
    EnergyUsed  = 0.0
}

# Step function: agent takes action, environment responds
function Invoke-EnvironmentStep {
    param($state, $action)

    $temp = $state.Temperature
    $energy = 0

    switch ($action) {
        "HeatHigh" { $temp += 3; $energy = 3 }
        "HeatLow"  { $temp += 1; $energy = 1 }
        "Off"      { $temp += ($state.OutdoorTemp - $temp) * 0.1; $energy = 0 }
        "Cool"     { $temp -= 1; $energy = 1 }
    }

    # Add natural drift toward outdoor temperature
    $temp += ($state.OutdoorTemp - $temp) * 0.05

    # Add small random noise
    $temp += (Get-Random -Minimum -10 -Maximum 10) / 10.0

    # Calculate reward
    $reward = 0
    if ($temp -ge 18 -and $temp -le 22) { $reward += 5 }
    elseif ($temp -ge 15 -and $temp -le 25) { $reward += 1 }
    else { $reward -= 5 }
    $reward -= $energy * 0.5

    # Update state
    $newState = @{
        Temperature = [Math]::Round($temp, 1)
        OutdoorTemp = $state.OutdoorTemp
        EnergyUsed  = $state.EnergyUsed + $energy
    }

    return @{ NewState = $newState; Reward = $reward; Energy = $energy }
}

Write-Host "Temperature environment ready!" -ForegroundColor Green
```

---

## Step 3: Create the Agent
```powershell
$actions = @("HeatHigh", "HeatLow", "Off", "Cool")
$agent = New-Object QLearningAgent -ArgumentList $actions, 0.1, 0.4

Write-Host "Agent created with actions: $($actions -join ', ')"
```

---

## Step 4: Convert State to String Key

Q-Learning needs states as string keys for the Q-table:
```powershell
function Get-StateKey {
    param($state)

    $tempBucket = [Math]::Floor($state.Temperature)
    $trend = if ($state.Temperature -gt 22) { "Hot" }
             elseif ($state.Temperature -lt 18) { "Cold" }
             else { "OK" }

    return "Temp${tempBucket}_${trend}"
}

Write-Host "State key example: $(Get-StateKey $envState)"
```

---

## Step 5: Training Loop
```powershell
Write-Host "`nTraining for 200 episodes..." -ForegroundColor Cyan

$episodeRewards = @()

for ($episode = 0; $episode -lt 200; $episode++) {

    # Reset environment each episode
    $state = @{
        Temperature = 15.0 + (Get-Random -Minimum 0 -Maximum 100) / 10.0
        OutdoorTemp = 5.0 + (Get-Random -Minimum 0 -Maximum 100) / 10.0
        EnergyUsed  = 0.0
    }

    $totalReward = 0

    # Run 50 steps per episode
    for ($step = 0; $step -lt 50; $step++) {
        $stateKey = Get-StateKey $state
        $action = $agent.ChooseAction($stateKey)
        $result = Invoke-EnvironmentStep $state $action
        $nextKey = Get-StateKey $result.NewState

        $agent.Learn($stateKey, $action, $result.Reward, $nextKey)

        $totalReward += $result.Reward
        $state = $result.NewState
    }

    $episodeRewards += $totalReward
    $agent.DecayEpsilon(0.99)

    if (($episode + 1) % 50 -eq 0) {
        $avg = ($episodeRewards[-50..-1] | Measure-Object -Average).Average
        Write-Host ("  Episode {0,3}: Avg reward = {1:F1}, epsilon = {2:F3}, temp = {3:F1}C" -f `
            ($episode + 1), $avg, $agent.Epsilon, $state.Temperature)
    }
}

Write-Host "`nTraining complete!" -ForegroundColor Green
```

**Expected output:**
```
  Episode  50: Avg reward = 12.3, epsilon = 0.607, temp = 16.2C
  Episode 100: Avg reward = 89.4, epsilon = 0.368, temp = 19.8C
  Episode 150: Avg reward = 142.1, epsilon = 0.223, temp = 20.1C
  Episode 200: Avg reward = 178.6, epsilon = 0.135, temp = 20.4C
```

Rewards increasing = agent learning to maintain comfort temperature!

---

## Step 6: Test the Trained Agent
```powershell
Write-Host "`n=== Testing trained agent (20 steps) ===" -ForegroundColor Cyan

$state = @{ Temperature = 10.0; OutdoorTemp = 8.0; EnergyUsed = 0.0 }
$agent.Epsilon = 0.0  # No exploration - pure exploitation

for ($step = 1; $step -le 20; $step++) {
    $stateKey = Get-StateKey $state
    $action = $agent.ChooseAction($stateKey)
    $result = Invoke-EnvironmentStep $state $action

    $comfort = if ($state.Temperature -ge 18 -and $state.Temperature -le 22) {
        "COMFORT" } else { "      " }

    Write-Host ("  Step {0,2}: {1:F1}C -> {2,-9} -> {3:F1}C  {4}" -f `
        $step, $state.Temperature, $action, $result.NewState.Temperature, $comfort)

    $state = $result.NewState
}

Write-Host "`nTotal energy used: $($state.EnergyUsed)" -ForegroundColor Yellow
```

---

## Design Tips for Your Own Environment

**Keep states discrete:** Q-Learning works best with a manageable number of
distinct states. Use buckets or categories rather than raw floats.

**Make rewards proportional:** A reward of +10 for the goal and -1 for each
step guides the agent better than just +1 at the end.

**Start simple:** Begin with 3-5 states and 2-3 actions. Add complexity once
the agent learns the basics.

**Avoid sparse rewards:** If the agent only gets rewarded at the very end,
it will struggle to learn. Add intermediate rewards for progress.

---

## Troubleshooting

**Agent always picks the same action?**
- Increase epsilon: change `0.4` to `0.6` for more exploration early on

**Rewards not improving after many episodes?**
- Check your state key function — are similar situations mapped to the same key?
- Simplify your reward function — too many signals can confuse the agent

**State space too large?**
- Use coarser buckets: `[Math]::Floor($temp / 5) * 5` groups temperatures in 5-degree bands

---

## What You Learned

- Every RL environment needs states, actions, and rewards
- State keys convert observations into Q-table entries
- Reward shaping guides agents toward desired behavior
- Discrete state buckets make Q-Learning practical for continuous problems

---

## Next Steps

- **Tutorial 06:** Visualize your custom environment training on a dashboard
- **Examples/03-Market-Simulation:** Study a production-quality environment
- **docs/Architecture.md:** Understand how VBAF environments are structured

---

*VBAF Version: 1.0.0 | PowerShell 5.1+ | Windows 10/11*
