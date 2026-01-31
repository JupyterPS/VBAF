# Getting Started with VBAF

Welcome! This guide will get you up and running with VBAF in 15 minutes.

---

## What You'll Learn

1. How to install VBAF
2. Run your first neural network
3. Create a Q-Learning agent
4. Open the learning dashboard

---

## Prerequisites

**Required:**
- Windows 10 or 11
- PowerShell 5.1+ (included with Windows)

**Optional:**
- PowerShell ISE (for code editing)
- Git (for cloning repository)

**No Python, no dependencies, no installation hassles!**

---

## Installation

### Option 1: Clone from GitHub (Recommended)
```powershell
# Clone repository
git clone https://github.com/[your-username]/VBAF.git
cd VBAF

# Load framework
. .\VBAF.LoadAll.ps1
```

### Option 2: Download ZIP

1. Download ZIP from GitHub
2. Extract to desired location
3. Open PowerShell in that directory
4. Run: `. .\VBAF.LoadAll.ps1`

### Verify Installation
```powershell
# Check version
Get-VBAFVersion

# Expected output:
# VBAF v1.0.0
# Visual Business Automation Framework
```

**If you see this, you're ready!** ✅

---

## Your First Neural Network (5 minutes)

Let's solve the XOR problem - the classic neural network test.

### Step 1: Create Training Data
```powershell
# XOR truth table
$xorData = @(
    @{Input=@(0,0); Expected=0},
    @{Input=@(0,1); Expected=1},
    @{Input=@(1,0); Expected=1},
    @{Input=@(1,1); Expected=0}
)
```

### Step 2: Create Neural Network
```powershell
# Architecture: 2 inputs → 3 hidden neurons → 1 output
$nn = New-VBAFNeuralNetwork -Architecture @(2, 3, 1) -LearningRate 0.1
```

### Step 3: Train the Network
```powershell
# Train for 1000 epochs
$results = $nn.Train($xorData, 1000)

# Watch error decrease over time
Write-Host "Final error: $($results.FinalError)"
```

### Step 4: Test the Network
```powershell
# Test each XOR case
foreach ($sample in $xorData) {
    $prediction = $nn.Predict($sample.Input)
    $rounded = [Math]::Round($prediction[0])
    
    Write-Host "Input: $($sample.Input) → Expected: $($sample.Expected), Got: $rounded"
}
```

**Expected output:**
```
Input: 0 0 → Expected: 0, Got: 0
Input: 0 1 → Expected: 1, Got: 1
Input: 1 0 → Expected: 1, Got: 1
Input: 1 1 → Expected: 0, Got: 0
```

**Success!** Your first neural network works! 🎉

---

## Your First Q-Learning Agent (5 minutes)

Now let's create an agent that learns through trial and error.

### Step 1: Create an Agent
```powershell
# Agent with 4 actions
$agent = New-VBAFAgent -Actions @("up", "down", "left", "right")
```

### Step 2: Simulate Learning
```powershell
# Simple grid world simulation
$state = "position_0_0"

for ($episode = 1; $episode -le 100; $episode++) {
    # Agent chooses action (explores at first, exploits later)
    $action = $agent.ChooseAction($state)
    
    # Simulate environment response
    $reward = Get-Random -Minimum -1 -Maximum 10
    $nextState = "position_1_1"
    
    # Agent learns from experience
    $agent.Learn($state, $action, $reward, $nextState)
    
    # Move to next state
    $state = $nextState
    
    # End episode
    if ($episode % 10 -eq 0) {
        $agent.EndEpisode($reward)
        Write-Host "Episode $episode: Epsilon = $($agent.Epsilon)"
    }
}
```

**Watch epsilon (exploration) decrease over time!**

### Step 3: Check What Agent Learned
```powershell
# Get agent statistics
$stats = $agent.GetStats()

Write-Host "Total episodes: $($stats.TotalEpisodes)"
Write-Host "Total reward: $($stats.TotalReward)"
Write-Host "Exploration: $($stats.ExplorationCount)"
Write-Host "Exploitation: $($stats.ExploitationCount)"
```

**The agent learned to balance exploration and exploitation!** 🎯

---

## Open the Learning Dashboard (5 minutes)

See learning happen in real-time with visual dashboards.

### Dashboard 1: Neural Network Training
```powershell
. .\VBAF.Visualization.Example-Dashboard.ps1
```

**What you'll see:**
- Error curve decreasing
- Reward curve increasing
- Epsilon decaying
- Real-time statistics

**Controls:**
- `SPACE` - Pause/Resume
- `R` - Reset metrics

### Dashboard 2: Market Simulation
```powershell
. .\VBAF.Business.Dashboard-Demo.ps1
```

**What you'll see:**
- 4 companies competing
- Profit trends over quarters
- Market share evolution
- Strategic decisions
- Random economic events

**Controls:**
- ▶ Play - Auto-run simulation
- ⏭ Step - Advance one quarter
- 🔄 Reset - Start over
- Speed slider (1x-10x)

### Dashboard 3: Validation
```powershell
. .\VBAF.Core.Test-ValidationDashboard.ps1
```

**What you'll see:**
- XOR network training
- Grid world agent learning
- Proof that framework works correctly

---

## What's Next?

Now that you've seen VBAF in action, explore more:

### Learn the Theory
- [Architecture](Architecture.md) - How VBAF is built
- [Theory](Theory.md) - Neural networks and RL explained
- [API Reference](API-Reference.md) - All functions and classes

### Try Tutorials
1. [Your First Neuron](tutorials/01-Your-First-Neuron.md) - Build from scratch
2. [XOR Network Deep Dive](tutorials/02-Building-XOR-Network.md)
3. [Q-Learning Agent](tutorials/03-Q-Learning-Agent.md)
4. [Multi-Agent Market](tutorials/04-Multi-Agent-Market.md)

### Explore Case Studies
- [Market Simulation](case-studies/market-simulation.md) - Companies competing
- [Castle Generation](case-studies/castle-generation.md) - Aesthetic RL

### Read the Research
- [Main Paper](papers/vbaf-main-paper.md) - Full academic paper

---

## Common Issues

### "Cannot find type [QLearningAgent]"

**Solution:** Make sure you loaded the framework first:
```powershell
. .\VBAF.LoadAll.ps1
```

### "Execution policy" error

**Solution:** Allow script execution (one-time setup):
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Dashboard doesn't open

**Solution:** Check that .NET Framework is installed (included with Windows 10/11).

### Slow performance

**Expected:** PowerShell is interpreted, so it's slower than compiled languages. This is intentional for educational transparency.

**Workaround:** Reduce epochs/episodes for faster results during learning.

---

## Getting Help

- **Questions:** Open GitHub Issue with "question" label
- **Bugs:** Open GitHub Issue with "bug" label
- **Improvements:** Open GitHub Issue with "enhancement" label
- **General discussion:** GitHub Discussions

---

## Quick Reference

### Key Commands
```powershell
# Load framework
. .\VBAF.LoadAll.ps1

# Create neural network
$nn = New-VBAFNeuralNetwork -Architecture @(2,3,1) -LearningRate 0.1

# Create RL agent
$agent = New-VBAFAgent -Actions @("action1", "action2")

# Get version info
Get-VBAFVersion

# List all commands
Get-Command -Module VBAF
```

### File Structure
```
VBAF/
├── VBAF.LoadAll.ps1        # Load framework
├── VBAF.psd1               # Module manifest
├── VBAF.*.ps1              # Core modules
├── docs/                   # Documentation (you are here!)
├── examples/               # Working examples
└── tests/                  # Test suite
```

---

## Next Steps

**Beginner Path:**
1. ✅ Complete this guide (you just did!)
2. → Read [Architecture](Architecture.md) to understand how it works
3. → Try [Tutorial 01](tutorials/01-Your-First-Neuron.md) to build from scratch

**Advanced Path:**
1. ✅ Complete this guide
2. → Read [Main Paper](papers/vbaf-main-paper.md) for research perspective
3. → Explore [Case Studies](case-studies/) for real applications

**Contributor Path:**
1. ✅ Complete this guide
2. → Read [Contributing Guide](dev/contributing.md)
3. → Pick a GitHub Issue to work on

---

**Welcome to VBAF! You're now ready to explore AI and reinforcement learning in PowerShell.** 🚀

**Questions?** Open a GitHub Issue or check the [FAQ](FAQ.md).