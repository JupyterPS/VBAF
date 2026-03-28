# Getting Started with VBAF

**Your First Steps into AI and Reinforcement Learning with PowerShell**

*From zero to neural network in 30 minutes* ⚡

---

## Table of Contents

1. [Installation & Setup](#installation--setup)
2. [Your First Neuron](#your-first-neuron-5-minutes)
3. [Your First Neural Network](#your-first-neural-network-15-minutes)
4. [Your First RL Agent](#your-first-rl-agent-20-minutes)
5. [Visualization](#visualization-optional)
6. [Next Steps](#next-steps)
7. [Troubleshooting](#troubleshooting)

---

## Installation & Setup

### Requirements

- **PowerShell 5.1+** (comes with Windows 10/11)
- **Windows 10/11** (for WinForms visualization)
- **No additional dependencies!** Pure PowerShell

### Check Your PowerShell Version

```powershell
$PSVersionTable.PSVersion
```

Should show: `5.1.x` or higher

### Download VBAF

**Option 1: Git Clone**
```powershell
git clone https://github.com/[your-repo]/VBAF.git
cd VBAF
```

**Option 2: Download ZIP**
1. Download from [GitHub releases]
2. Extract to `C:\VBAF\`
3. Open PowerShell
4. `cd C:\VBAF\`

### Verify Installation

```powershell
# Load a core component
. ".\Core\Neuron.ps1"

# Create a test neuron
$neuron = New-Object Neuron -ArgumentList 2

# If no errors → You're ready! ✓
Write-Host "VBAF installed successfully!" -ForegroundColor Green
```

---

## Your First Neuron (5 minutes)

Let's build the smallest unit of intelligence - a single neuron.

### Step 1: Create the Neuron

```powershell
# Load the neuron class
. ".\Core\Neuron.ps1"

# Create a neuron with 2 inputs
$neuron = New-Object Neuron -ArgumentList 2

Write-Host "Created neuron with:"
Write-Host "  Weights: $($neuron.Weights -join ', ')"
Write-Host "  Bias: $($neuron.Bias)"
```

**Output:**
```
Created neuron with:
  Weights: -0.3421, 0.7234
  Bias: 0.1523
```

(Your numbers will be different - they're random!)

### Step 2: Make a Prediction

```powershell
# Give it two inputs
$inputs = @(0.5, 0.8)

# Get output
$output = $neuron.Forward($inputs)

Write-Host "Input: $($inputs -join ', ')"
Write-Host "Output: $output"
```

**Output:**
```
Input: 0.5, 0.8
Output: 0.6823
```

**What just happened?**
1. Neuron multiplied inputs by weights: `0.5×(-0.3421) + 0.8×0.7234`
2. Added bias: `+ 0.1523`
3. Applied sigmoid activation: `1 / (1 + e^-sum)`
4. Returned value between 0 and 1

🎉 **Congratulations!** You just created and used an artificial neuron!

---

## Your First Neural Network (15 minutes)

Now let's solve a problem that requires **actual intelligence** - the XOR problem.

### What is XOR?

XOR (exclusive or) outputs 1 when inputs are **different**:

```
Input A | Input B | Output
--------|---------|--------
   0    |    0    |   0
   0    |    1    |   1    ← Different
   1    |    0    |   1    ← Different
   1    |    1    |   0
```

**Why XOR is special:** A single neuron **cannot** learn this. We need a network!

### Step 1: Load the Framework

```powershell
# Load neural network classes
. ".\Core\Activation.ps1"
. ".\Core\Neuron.ps1"
. ".\Core\Layer.ps1"
. ".\Core\NeuralNetwork.ps1"
```

### Step 2: Create the Network

```powershell
# Architecture: 2 inputs → 3 hidden → 1 output
$architecture = @(2, 3, 1)
$learningRate = 0.1

$nn = New-Object NeuralNetwork -ArgumentList $architecture, $learningRate

Write-Host "Created neural network:"
Write-Host "  Input neurons: 2"
Write-Host "  Hidden neurons: 3"
Write-Host "  Output neurons: 1"
Write-Host "  Total connections: ~13"
```

### Step 3: Prepare Training Data

```powershell
$xorData = @(
    @{Input=@(0,0); Expected=0},
    @{Input=@(0,1); Expected=1},
    @{Input=@(1,0); Expected=1},
    @{Input=@(1,1); Expected=0}
)

Write-Host "Training data prepared: 4 XOR examples"
```

### Step 4: Train the Network

```powershell
Write-Host "`nTraining for 1000 epochs..."
Write-Host "(This will take ~10 seconds)"

$results = $nn.Train($xorData, 1000)

Write-Host "`nTraining complete!"
Write-Host "Final error: $($results[-1].Error.ToString('F6'))"
```

**Output:**
```
Training for 1000 epochs...
(This will take ~10 seconds)

Training complete!
Final error: 0.001234
```

**What happened?**
- Network tried all 4 XOR examples 1000 times
- Each time, it adjusted weights to reduce error
- Final error < 0.01 = network learned XOR! ✓

### Step 5: Test the Trained Network

```powershell
Write-Host "`n=== Testing XOR ==="
Write-Host ""

foreach ($sample in $xorData) {
    $prediction = $nn.Predict($sample.Input)
    $rounded = [Math]::Round($prediction[0])
    
    $status = if ($rounded -eq $sample.Expected) {
        "✓ Correct"
    } else {
        "✗ Wrong"
    }
    
    Write-Host ("XOR({0},{1}) = {2} (expected {3}) {4}" -f `
        $sample.Input[0], `
        $sample.Input[1], `
        $rounded, `
        $sample.Expected, `
        $status)
}
```

**Output:**
```
=== Testing XOR ===

XOR(0,0) = 0 (expected 0) ✓ Correct
XOR(0,1) = 1 (expected 1) ✓ Correct
XOR(1,0) = 1 (expected 1) ✓ Correct
XOR(1,1) = 0 (expected 0) ✓ Correct
```

🎉 **Amazing!** Your network learned XOR from scratch!

### Complete Script

Save this as `MyFirstNetwork.ps1`:

```powershell
# Load framework
. ".\Core\Activation.ps1"
. ".\Core\Neuron.ps1"
. ".\Core\Layer.ps1"
. ".\Core\NeuralNetwork.ps1"

# Create network
$nn = New-Object NeuralNetwork -ArgumentList @(2, 3, 1), 0.1

# Training data
$xorData = @(
    @{Input=@(0,0); Expected=0},
    @{Input=@(0,1); Expected=1},
    @{Input=@(1,0); Expected=1},
    @{Input=@(1,1); Expected=0}
)

# Train
Write-Host "Training..." -ForegroundColor Cyan
$results = $nn.Train($xorData, 1000)
Write-Host "Done! Error: $($results[-1].Error.ToString('F4'))" -ForegroundColor Green

# Test
Write-Host "`nTesting:" -ForegroundColor Cyan
foreach ($sample in $xorData) {
    $prediction = $nn.Predict($sample.Input)
    $rounded = [Math]::Round($prediction[0])
    Write-Host "XOR$($sample.Input) = $rounded"
}
```

Run it:
```powershell
.\MyFirstNetwork.ps1
```

---

## Your First RL Agent (20 minutes)

Now let's build an agent that **learns from experience** - reinforcement learning!

### The Problem: Simple Grid World

Imagine a 3x3 grid:
```
[S] [ ] [G]    S = Start
[ ] [X] [ ]    G = Goal (+10 reward)
[ ] [ ] [ ]    X = Trap (-5 reward)
```

Agent learns to reach goal while avoiding trap.

### Step 1: Load RL Framework

```powershell
. ".\RL\QLearningAgent.ps1"
. ".\RL\ExperienceReplay.ps1"
```

### Step 2: Create the Agent

```powershell
# Available actions
$actions = @("Up", "Down", "Left", "Right")

# Create Q-Learning agent
$agent = New-Object QLearningAgent -ArgumentList $actions, 0.1, 0.3

Write-Host "Created RL Agent:"
Write-Host "  Actions: $($actions -join ', ')"
Write-Host "  Learning Rate: 0.1"
Write-Host "  Exploration (ε): 0.3"
```

### Step 3: Simple Environment Simulator

```powershell
function Simulate-Step {
    param($state, $action)
    
    # Simple rules for our grid
    $outcomes = @{
        "Start-Right" = @{NextState="Middle"; Reward=0}
        "Start-Down"  = @{NextState="BottomLeft"; Reward=0}
        "Middle-Right" = @{NextState="Goal"; Reward=10}
        "Middle-Up"   = @{NextState="Trap"; Reward=-5}
        "BottomLeft-Right" = @{NextState="Bottom"; Reward=0}
        "Bottom-Up"   = @{NextState="Middle"; Reward=0}
    }
    
    $key = "$state-$action"
    if ($outcomes.ContainsKey($key)) {
        return $outcomes[$key]
    } else {
        # Invalid move = stay in place, small penalty
        return @{NextState=$state; Reward=-1}
    }
}
```

### Step 4: Training Loop

```powershell
Write-Host "`nTraining for 100 episodes..." -ForegroundColor Cyan

$totalRewards = @()

for ($episode = 0; $episode -lt 100; $episode++) {
    $state = "Start"
    $episodeReward = 0
    
    # Each episode = max 10 steps
    for ($step = 0; $step -lt 10; $step++) {
        # Agent chooses action
        $action = $agent.ChooseAction($state)
        
        # Environment responds
        $result = Simulate-Step $state $action
        $nextState = $result.NextState
        $reward = $result.Reward
        
        # Agent learns
        $agent.Learn($state, $action, $reward, $nextState)
        
        # Update state
        $episodeReward += $reward
        $state = $nextState
        
        # If reached goal, episode ends
        if ($state -eq "Goal") {
            break
        }
    }
    
    $totalRewards += $episodeReward
    
    # Reduce exploration over time
    $agent.DecayEpsilon(0.99)
    
    # Print progress every 20 episodes
    if (($episode + 1) % 20 -eq 0) {
        $avgReward = ($totalRewards[-20..-1] | Measure-Object -Average).Average
        Write-Host ("Episode {0}: Avg Reward = {1:F2}, ε = {2:F3}" -f `
            ($episode + 1), $avgReward, $agent.Epsilon)
    }
}

Write-Host "`nTraining complete!" -ForegroundColor Green
```

**Output:**
```
Training for 100 episodes...
Episode 20: Avg Reward = -8.50, ε = 0.818
Episode 40: Avg Reward = 2.30, ε = 0.670
Episode 60: Avg Reward = 6.20, ε = 0.548
Episode 80: Avg Reward = 8.40, ε = 0.449
Episode 100: Avg Reward = 9.10, ε = 0.367

Training complete!
```

**What you see:**
- Early episodes: Low reward (random exploration)
- Later episodes: High reward (learned optimal path)
- Epsilon decreases (less exploration, more exploitation)

### Step 5: View What Agent Learned

```powershell
Write-Host "`n=== Learned Q-Values ===" -ForegroundColor Cyan

# Show top 10 state-action pairs
$topPairs = $agent.QTable.GetEnumerator() | 
    Sort-Object Value -Descending | 
    Select-Object -First 10

foreach ($pair in $topPairs) {
    Write-Host ("{0,-20} = {1:F2}" -f $pair.Key, $pair.Value)
}
```

**Output:**
```
=== Learned Q-Values ===
Middle-Right         = 8.92   ← Best action: reach goal!
Start-Right          = 7.15
Bottom-Up            = 6.32
Start-Down           = 5.41
Middle-Down          = 2.14
Middle-Up            = -3.87  ← Learned to avoid trap
```

**Agent learned:**
- ✓ "Middle-Right" leads to goal → high Q-value
- ✓ "Middle-Up" leads to trap → negative Q-value
- ✓ Optimal path: Start → Right → Middle → Right → Goal

🎉 **Incredible!** Your agent learned through trial and error!

### Complete RL Script

Save as `MyFirstRLAgent.ps1`:

```powershell
. ".\RL\QLearningAgent.ps1"

# Create agent
$agent = New-Object QLearningAgent -ArgumentList @("Up","Down","Left","Right"), 0.1, 0.3

# Simple environment
function Simulate-Step {
    param($state, $action)
    $outcomes = @{
        "A-Right" = @{NextState="B"; Reward=0}
        "B-Right" = @{NextState="Goal"; Reward=10}
        "B-Up"    = @{NextState="Trap"; Reward=-5}
    }
    $key = "$state-$action"
    if ($outcomes.ContainsKey($key)) { return $outcomes[$key] }
    else { return @{NextState=$state; Reward=-1} }
}

# Train
Write-Host "Training 100 episodes..."
for ($ep = 0; $ep -lt 100; $ep++) {
    $state = "A"
    for ($step = 0; $step -lt 5; $step++) {
        $action = $agent.ChooseAction($state)
        $result = Simulate-Step $state $action
        $agent.Learn($state, $action, $result.Reward, $result.NextState)
        $state = $result.NextState
        if ($state -eq "Goal") { break }
    }
    $agent.DecayEpsilon(0.99)
}

# Show results
Write-Host "`nTop learned values:"
$agent.QTable.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 5 | 
    ForEach-Object { Write-Host "$($_.Key) = $($_.Value)" }
```

---

## Visualization (Optional)

Want to **see** your network learn in real-time? Add the dashboard!

### Basic Visualization

```powershell
# Load visualization
. ".\Visualization\MetricsCollector.ps1"
. ".\Visualization\LearningDashboard.ps1"

# Create dashboard
$dashboard = New-Object LearningDashboard -ArgumentList "Training Monitor"

# Show it (non-blocking)
$dashboard.ShowNonBlocking()

# Training loop with updates
$nn = New-Object NeuralNetwork -ArgumentList @(2, 3, 1), 0.1

for ($epoch = 0; $epoch -lt 1000; $epoch++) {
    foreach ($sample in $xorData) {
        $output = $nn.Forward($sample.Input)
        $error = [Math]::Abs($sample.Expected - $output[0])
        $nn.Backward($sample.Expected)
        
        # Update dashboard
        $dashboard.UpdateFromNeuralNetwork(@{Error=$error})
    }
    
    # Refresh display every 10 epochs
    if ($epoch % 10 -eq 0) {
        $dashboard.Refresh()
    }
}

Write-Host "Training complete! Close dashboard window when done."
```

You'll see:
- **Error graph** decreasing in real-time
- **Statistics** updating
- **Live feedback** as network learns

**Note:** If visualization has issues (it can be temperamental in PS 5.1), just skip it. The core learning still works!

---

## Next Steps

### Beginner Path

1. ✅ Built a neuron
2. ✅ Trained XOR network
3. ✅ Created RL agent
4. **Next:** Experiment!
   - Try different learning rates (0.01, 0.5, 1.0)
   - Add more hidden neurons (5, 10)
   - Create your own simple problems

### Intermediate Path

5. **Study the code:**
   - Open `NeuralNetwork.ps1`
   - Read the `Backward()` method
   - Understand backpropagation line-by-line

6. **Modify the network:**
   - Add a third hidden layer
   - Try different activation functions (ReLU, Tanh)
   - Solve AND, OR, NAND problems

7. **Enhance the RL agent:**
   - Add experience replay
   - Implement more complex environments
   - Track learning progress

### Advanced Path

8. **Explore examples:**
   - `Examples/01-XOR-Network/XOR-Visualized.ps1`
   - `Examples/02-Castle-QLearning/Castle-Basic.ps1`
   - Study how they work

9. **Read documentation:**
   - `Docs/Theory.md` - Understand the math
   - `Docs/API-Reference.md` - Master all features

10. **Build something new:**
    - Text classification
    - Game AI
    - Business simulation
    - Your own creative idea!

### Expert Path

11. **Phase 2 content** (when released):
    - Multi-agent systems
    - Company strategy agents
    - Market simulations

12. **Contribute:**
    - Add features
    - Fix bugs
    - Share your creations
    - Help others learn

---

## Troubleshooting

### Common Issues

#### "Cannot find path"

**Problem:**
```
. : Cannot find path 'C:\VBAF\Core\Neuron.ps1'
```

**Solution:**
```powershell
# Check current directory
Get-Location

# Navigate to VBAF folder
cd C:\VBAF\

# Or use full paths
. "C:\VBAF\Core\Neuron.ps1"
```

#### "Execution policy" Error

**Problem:**
```
cannot be loaded because running scripts is disabled
```

**Solution:**
```powershell
# Allow scripts for current session only
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# Then run your script
.\MyFirstNetwork.ps1
```

#### Network Not Learning

**Problem:** Error stays high, doesn't decrease.

**Solutions:**
```powershell
# 1. Lower learning rate
$nn = New-Object NeuralNetwork -ArgumentList @(2, 3, 1), 0.01  # Try 0.01

# 2. More epochs
$results = $nn.Train($xorData, 5000)  # Try 5000

# 3. More hidden neurons
$nn = New-Object NeuralNetwork -ArgumentList @(2, 5, 1), 0.1  # Try 5 hidden
```

#### Visualization Crashes

**Problem:** Dashboard window errors or freezes.

**Solution:**
```powershell
# Just skip visualization for now
# Core learning works fine without it!

# Train without dashboard:
$results = $nn.Train($xorData, 1000)
```

### Getting Help

**Resources:**
- 📖 Read `Docs/Theory.md` for concepts
- 📘 Check `Docs/API-Reference.md` for syntax
- 💬 GitHub Discussions: [link]
- 🐛 Report bugs: [link]/issues
- 📧 Email: [your-email]

**Before asking:**
1. Check error message carefully
2. Verify PowerShell version (5.1+)
3. Try the example scripts
4. Search existing issues

---

## Quick Reference

### Load Framework

```powershell
# Neural Networks
. ".\Core\Activation.ps1"
. ".\Core\Neuron.ps1"
. ".\Core\Layer.ps1"
. ".\Core\NeuralNetwork.ps1"

# Reinforcement Learning
. ".\RL\QLearningAgent.ps1"
. ".\RL\ExperienceReplay.ps1"

# Visualization
. ".\Visualization\MetricsCollector.ps1"
. ".\Visualization\LearningDashboard.ps1"
```

### Create Components

```powershell
# Neuron
$neuron = New-Object Neuron -ArgumentList 3

# Neural Network (2 inputs, 4 hidden, 1 output)
$nn = New-Object NeuralNetwork -ArgumentList @(2, 4, 1), 0.1

# RL Agent
$agent = New-Object QLearningAgent -ArgumentList @("A","B","C"), 0.1, 0.2

# Dashboard
$dashboard = New-Object LearningDashboard -ArgumentList "Title"
```

### Training Data Format

```powershell
# Neural Network
$data = @(
    @{Input=@(0,0); Expected=0},
    @{Input=@(1,1); Expected=1}
)

# RL Experience
$exp = @{
    State = "StateA"
    Action = "ActionX"
    Reward = 5.0
    NextState = "StateB"
}
```

---

## Success Checklist

After completing this guide, you should be able to:

- [x] Create and use a single neuron
- [x] Build a multi-layer neural network
- [x] Train a network using backpropagation
- [x] Solve the XOR problem
- [x] Create a Q-Learning agent
- [x] Train an agent through trial and error
- [x] Understand reward-based learning
- [x] (Optional) Visualize training progress

**If you checked all boxes:** Congratulations! You're ready to build AI systems in PowerShell! 🚀

**If you struggled:** That's normal! AI is complex. Try:
1. Re-read the sections you found difficult
2. Run the examples multiple times
3. Experiment with different parameters
4. Read `Theory.md` for deeper understanding
5. Ask for help (see "Getting Help" above)

---

## What You've Learned

### Technical Skills
- Building neural networks from scratch
- Implementing backpropagation
- Q-Learning algorithm
- Epsilon-greedy exploration
- Experience replay concept
- Real-time visualization

### Conceptual Understanding
- How neurons work
- Why hidden layers matter
- Gradient descent optimization
- Reinforcement learning loop
- Exploration vs exploitation
- Trial-and-error learning

### PowerShell Skills
- Object-oriented programming
- Class definitions and methods
- Array manipulation
- Hashtable usage
- WinForms (if you did visualization)

---

## Your Journey Continues

**This is just the beginning!**

You've learned the fundamentals. Now you can:
- Build more complex networks
- Create smarter agents
- Solve real problems
- Share your creations
- Help others learn

**Remember:** Every AI researcher started exactly where you are now. Keep experimenting, keep learning, and most importantly - **have fun!**

Welcome to the world of AI and Reinforcement Learning! 🎉

---

*Questions? Stuck? Found this helpful? Let us know!*

*Next: Check out `Examples/` folder for more advanced projects*

---

*Last updated: [Date]*  
*VBAF Version: 1.0.0*  
*Tested on: PowerShell 5.1, Windows 10/11*