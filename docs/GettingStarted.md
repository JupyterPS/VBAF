# Getting Started with VBAF

VBAF (Visual AI & Reinforcement Learning Framework) is a complete machine
learning and enterprise automation framework written entirely in PowerShell 5.1.
No Python. No dependencies. No internet after install.

---

## Requirements

- Windows 10 or 11
- PowerShell 5.1 (included with Windows -- no install needed)
- Git (optional, for cloning)

---

## Installation

**Option 1 -- PSGallery (easiest):**
```powershell
Install-Module VBAF -Scope CurrentUser
```

**Option 2 -- Clone from GitHub:**
```powershell
git clone https://github.com/JupyterPS/VBAF.git
cd VBAF
. .\VBAF.LoadAll.ps1
```

---

## Load the Framework

Run this at the start of every PowerShell session:

```powershell
cd "C:\Users\henni\OneDrive\WindowsPowerShell"
. .\VBAF.LoadAll.ps1
```

You will see all modules load in order across 9 phases:
- Phase 1: Core neural network classes
- Phase 2: Reinforcement learning (Q-learning, DQN, PPO, A3C)
- Phase 3: Business and multi-agent simulation
- Phase 4-7: Supervised learning, data pipeline, deep learning, ML production
- Phase 8: Visualization and creative AI
- Phase 9-27: Enterprise automation pillars

When you see `VBAF Framework ready!` -- everything is loaded.

**Important:** Never dot-source individual files directly if they depend on
other classes. Always load via VBAF.LoadAll.ps1.
If you get "Unable to find type" errors -- run LoadAll first.

---

## The Learning Path

Work through the 6 examples in order. Each builds on the previous.

**Example 01 -- XOR Network (neural networks)**
```powershell
cd "C:\Users\henni\OneDrive\WindowsPowerShell\examples\01-XOR-Network"
. .\Run-Example-01.ps1
```
A 2-4-1 neural network learns XOR through backpropagation.
The classic proof that hidden layers work.

**Example 02 -- Castle Learning (Q-learning)**
```powershell
cd "C:\Users\henni\OneDrive\WindowsPowerShell\examples\02-Castle-Learning"
. .\Run-Example-02.ps1
```
A Q-learning agent discovers that variety is rewarded and repetition is penalised.
Watch the Q-table grow and epsilon decay during training.

**Example 03 -- Market Simulation (multi-agent RL)**
```powershell
cd "C:\Users\henni\OneDrive\WindowsPowerShell\examples\03-Market-Simulation"
. .\Run-Example-03.ps1
```
Four companies compete for market share over 10 simulated years.
Price wars, innovation races and tacit collusion emerge without being programmed.

**Example 04 -- Learning Dashboard (visualisation)**
```powershell
cd "C:\Users\henni\OneDrive\WindowsPowerShell\examples\04-Learning-Dashboard"
. .\Run-Example-04.ps1
```
Watch error decrease, reward increase and epsilon decay in real time.
Note: WinForms window requires standalone PowerShell console, not ISE.

**Example 05 -- Validation Dashboard (three panels)**
```powershell
cd "C:\Users\henni\OneDrive\WindowsPowerShell\examples\05-Validation-Dashboard"
. .\Run-Example-05.ps1
```
Three simultaneous live panels: neural network training, Q-learning grid world,
and experience replay buffer filling. Click Start NN Training to begin.

**Example 06 -- Custom Agent (build your own)**
```powershell
cd "C:\Users\henni\OneDrive\WindowsPowerShell\examples\06-Custom-Agent"
. .\Run-Example-06.ps1
```
Build a complete Phase 28 enterprise pillar from scratch.
The NetworkTrafficManager template shows the exact pattern for any new pillar.

---

## Quick Commands

```powershell
# Train a DQN agent
$agent = (Invoke-DQNTraining -Episodes 100 -PrintEvery 10)[-1]
$agent.PrintStats()

# Train PPO and A3C
$ppo = (Invoke-PPOTraining -Episodes 50 -PrintEvery 5 -FastMode)[-1]
$a3c = (Invoke-A3CTraining -Episodes 20 -PrintEvery 2 -FastMode)[-1]

# Run the AutoPilot -- orchestrates all 13 enterprise pillars
$r = Invoke-VBAFAutoPilotTraining -Episodes 100 -PrintEvery 10 -SimMode

# Benchmark an agent
$env = New-VBAFEnvironment -Name "CartPole" -MaxSteps 200
Invoke-VBAFBenchmark -Agent $agent -Environment $env -Episodes 20 -Label "DQN"

# Supervised learning -- house price prediction
$data   = Get-VBAFDataset -Name "HousePrice"
$scaler = [StandardScaler]::new()
$Xs     = $scaler.FitTransform($data.X)
$model  = [LinearRegression]::new()
$model.Fit($Xs, $data.y)
$model.PrintSummary()
```

---

## The 5 Dashboards

All dashboards open a WinForms window. Run from standalone PowerShell console.

```powershell
# 1. Learning curves (error, reward, epsilon over time)
& .\VBAF.Visualization.Example-Dashboard.ps1

# 2. Market competition (four companies, live market share)
& .\VBAF.Business.Dashboard-Demo.ps1

# 3. Validation (neural network + Q-learning + replay buffer)
& .\VBAF.Core.Test-ValidationDashboard.ps1

# 4. Q-learning visual (20-step sequence visualisation)
& .\VBAF.Art.Show20-QLearning.ps1

# 5. Castle battle (competitive castle generation)
& .\VBAF.Art.CastleCompetition.ps1
```

---

## Tutorials

13 step-by-step tutorials in `tutorials\`:
01 -- Your First Neural Network

02 -- First Classifier

03 -- Q-Learning Agent

06 -- First Regression Model

07 -- KMeans Clustering

08 -- Load Your Own CSV

09 -- Feature Engineering

10 -- Model Comparison

11 -- Correct Pipeline Pattern

12 -- Your First DQN Agent

13 -- Custom Enterprise Pillar

---

## Enterprise Automation

Run any enterprise pillar in SimMode:

```powershell
$r = Invoke-VBAFJobSchedulerTraining        -Episodes 50  -SimMode
$r = Invoke-VBAFSecurityMonitorTraining     -Episodes 100 -SimMode
$r = Invoke-VBAFAnomalyDetectorTraining     -Episodes 100 -SimMode
$r = Invoke-VBAFAutoPilotTraining           -Episodes 100 -SimMode
```

Each returns `$r.Baseline.Avg`, `$r.Trained.Avg` and improvement percentage.
Replace -SimMode with real Windows data sources when ready for production.

---

## Next Steps

- `docs\Theory.md` -- reinforcement learning concepts explained
- `docs\Architecture.md` -- how VBAF is structured layer by layer
- `docs\API-Reference.md` -- complete function and class reference
- `docs\teaching\course-outline.md` -- 4-week course for IT professionals
- `VBAF.CheatSheet.md` -- one-page quick reference for all functions