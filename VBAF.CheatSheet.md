# VBAF Cheat Sheet
## "I want to..." -- find your situation, copy the code

> One rule: always run `. .\VBAF.LoadAll.ps1` first.

---

## I WANT TO LEARN

### ...understand what VBAF is
```powershell
Get-Content docs\GettingStarted.md
```

### ...follow a guided tour of all 6 concepts
```powershell
Start-VBAFTeach
```

### ...learn one specific topic
```powershell
Start-VBAFTeach -Topic "MachineLearning"
Start-VBAFTeach -Topic "NeuralNetwork"
Start-VBAFTeach -Topic "QLearning"
Start-VBAFTeach -Topic "DQN"
Start-VBAFTeach -Topic "MultiAgent"
Start-VBAFTeach -Topic "Enterprise"
```

### ...experiment without writing code
```powershell
Start-VBAFPlayground
Start-VBAFPlayground -Algorithm "DQN"
Start-VBAFPlayground -Algorithm "QLearning"
Start-VBAFPlayground -Algorithm "Enterprise"
Start-VBAFPlayground -Algorithm "Supervised"
```

---

## I WANT TO RUN AN EXAMPLE

### ...see a neural network learn from scratch
```powershell
cd examples\01-XOR-Network
. .\Run-Example-01.ps1
```

### ...see a Q-learning agent discover strategy
```powershell
cd examples\02-Castle-Learning
. .\Run-Example-02.ps1
```

### ...see four companies compete in a market
```powershell
cd examples\03-Market-Simulation
. .\Run-Example-03.ps1
```

### ...see a live training dashboard
```powershell
cd examples\04-Learning-Dashboard
. .\Run-Example-04.ps1   # run from standalone console, not ISE
```

### ...see three panels of validation live
```powershell
cd examples\05-Validation-Dashboard
. .\Run-Example-05.ps1   # run from standalone console, not ISE
```

### ...build my own enterprise agent
```powershell
cd examples\06-Custom-Agent
. .\Run-Example-06.ps1
```

---

## I WANT TO TRAIN AN RL AGENT

### ...train a DQN agent on CartPole
```powershell
$agent = (Invoke-DQNTraining -Episodes 100 -PrintEvery 10)[-1]
$agent.PrintStats()
```

### ...train PPO or A3C
```powershell
$ppo = (Invoke-PPOTraining -Episodes 50 -PrintEvery 5 -FastMode)[-1]
$a3c = (Invoke-A3CTraining -Episodes 20 -PrintEvery 2 -FastMode)[-1]
```

### ...compare DQN vs PPO vs A3C head to head
```powershell
Invoke-VBAFQuickBenchmark -AgentName "DQN" -Environment "CartPole" -Episodes 50
Invoke-VBAFAgentBenchmark -Agents @("DQN","PPO","A3C") -Episodes 50
```

### ...train a Q-learning agent on castle sequences
```powershell
$castleTypes = @("Gothic","FairyTale","Fortress","Palace","Wizard","Cathedral","Oriental","Ruins")
$agent = [QLearningAgent]::new($castleTypes)
# then run examples\02-Castle-Learning\Run-Example-02.ps1
```

### ...inspect what a Q-learning agent learned
```powershell
$agent.GetQValues("Gothic|Fortress")
$agent.GetBestAction("Gothic|Fortress")
$agent.GetStats()
```

---

## I WANT TO RUN AN ENTERPRISE PILLAR

### ...run any pillar in safe simulation mode
```powershell
$r = Invoke-VBAFSecurityMonitorTraining     -Episodes 100 -SimMode
$r = Invoke-VBAFAnomalyDetectorTraining     -Episodes 100 -SimMode
$r = Invoke-VBAFSelfHealingTraining         -Episodes 100 -SimMode
$r = Invoke-VBAFCapacityPlannerTraining     -Episodes 100 -SimMode
$r = Invoke-VBAFEnergyOptimizerTraining     -Episodes 100 -SimMode
$r = Invoke-VBAFAutoPilotTraining           -Episodes 100 -SimMode
```

### ...read the results
```powershell
$r.Baseline.Avg    # random agent average reward
$r.Trained.Avg     # trained agent average reward
# Improvement = (Trained - Baseline) / |Baseline| * 100
```

### ...run all pillars at once
```powershell
$r = Invoke-VBAFAutoPilotTraining -Episodes 100 -PrintEvery 10 -SimMode
```

---

## I WANT TO DO SUPERVISED LEARNING

### ...predict house prices
```powershell
$data   = Get-VBAFDataset -Name "HousePrice"
$scaler = [StandardScaler]::new()
$Xs     = $scaler.FitTransform($data.X)
$model  = [RidgeRegression]::new(0.01)
$model.Fit($Xs, $data.y)
$preds  = $model.Predict($Xs)
$m      = Get-RegressionMetrics $data.y $preds
Write-Host "R2: $($m.R2)  RMSE: $($m.RMSE)"
```

### ...classify with Naive Bayes
```powershell
$data = Get-VBAFNBDataset -Name "Iris3Class"
$gnb  = [GaussianNaiveBayes]::new()
$gnb.Fit($data.X, $data.y)
$gnb.PrintSummary()
```

### ...find the best model automatically
```powershell
$data  = Get-VBAFDataset -Name "HousePrice"
$Xs    = ([StandardScaler]::new()).FitTransform($data.X)
$auto  = Invoke-VBAFAutoML -X $Xs -y $data.y -FeatureNames $data.Features -OptMethod "bayesian"
```

### ...clean messy data
```powershell
$data = Get-VBAFPipelineDataset -Name "MessyHousePrice"
$imp  = [MissingValueImputer]::new("median")
$Ximp = $imp.FitTransform($data.X)
$out  = [OutlierDetector]::new("iqr", "clip", 1.5)
$out.Fit($Ximp)
$Xclean = ($out.Transform($Ximp)).Data   # always use .Data
```

---

## I WANT TO SEE A DASHBOARD

> All dashboards require standalone PowerShell console -- not ISE.
> If the window hides behind other windows, click it once to bring it forward.

```powershell
& .\VBAF.Visualization.Example-Dashboard.ps1   # learning curves
& .\VBAF.Business.Dashboard-Demo.ps1           # market competition
& .\VBAF.Core.Test-ValidationDashboard.ps1     # three panel validation
& .\VBAF.Art.Show20-QLearning.ps1              # Q-learning visual
& .\VBAF.Art.CastleCompetition.ps1             # castle battle
```

---

## I WANT TO TRACK EXPERIMENTS

```powershell
New-VBAFExperiment -Name "MyExperiment"
Start-VBAFRun -RunName "run1" -ModelType "RidgeRegression" -Params @{ Lambda=0.01 }
Set-VBAFRunMetric -Key "R2" -Value 0.99
Stop-VBAFRun
Compare-VBAFRuns
```

---

## I WANT TO SAVE AND LOAD A MODEL

```powershell
Initialize-VBAFRegistry
Save-VBAFModel -ModelName "MyModel" -Model $model -ModelType "RidgeRegression" -Metrics @{ R2=0.99 }
$loaded = Load-VBAFModel -ModelName "MyModel"
Get-VBAFModelList
```

---

## COMMON FIXES

| Problem | Fix |
|---------|-----|
| "Unable to find type" | Run `. .\VBAF.LoadAll.ps1` first |
| Dashboard not visible | Click it in the taskbar to bring to front |
| OutlierDetector returns hashtable | Use `($out.Transform($X)).Data` |
| Class not updated after edit | Close and reopen PowerShell -- PS 5.1 caches classes |
| LF/CRLF warning from Git | Safe to ignore -- always |
| "master -> master" in red | Not an error -- push succeeded |

---

## FULL LEARNING PATH

See [docs/LEARNING-PATH.md](docs/LEARNING-PATH.md) for the complete 119-step guide.

---

*github.com/JupyterPS/VBAF · Install-Module VBAF · v5.0.3 · Built in Roskilde, Denmark 🇩🇰*
