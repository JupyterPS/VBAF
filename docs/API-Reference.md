# API Reference
Complete function and class reference for VBAF v4.0.0.
See also [VBAF.CheatSheet.md](../VBAF.CheatSheet.md) for a quick one-page summary.

---

## Loading the Framework

```powershell
cd "C:\Users\henni\OneDrive\WindowsPowerShell"
. .\VBAF.LoadAll.ps1
```

Always run this first -- every session, every time.

---

## Neural Network

### NeuralNetwork class

```powershell
# Create a network
$nn = [NeuralNetwork]::new(@(2, 4, 1), 0.5)   # architecture, learningRate

# Train on labelled data
$data = @(
    @{ Input = @(0.0, 0.0); Expected = @(0.0) }
    @{ Input = @(0.0, 1.0); Expected = @(1.0) }
)
$results = $nn.Train($data, 5000)   # returns @{ FinalError=... }

# Predict
$output = $nn.Predict(@(1.0, 0.0))   # returns double[]

# Evaluate accuracy
$eval = $nn.Evaluate($data)
# Returns: $eval.Accuracy, $eval.Correct, $eval.Total
```

---

## Q-Learning

### QLearningAgent class

```powershell
# Create agent
$actions = @("Gothic", "FairyTale", "Fortress", "Palace")
$agent   = [QLearningAgent]::new($actions)
# Full constructor with custom learning rate and epsilon:
$agent   = [QLearningAgent]::new($actions, 0.1, 1.0)

# Core methods
$state   = $agent.GetState($context)              # context = @{ RecentTypes = $list }
$action  = $agent.ChooseAction($state)            # epsilon-greedy
$reward  = $agent.CalculateReward($outcome)       # domain-specific reward
$agent.Learn($state, $action, $reward, $nextState) # Bellman update
$agent.EndEpisode($episodeReward)                  # decay epsilon

# Inspect learning
$qValues = $agent.GetQValues("Gothic|Fortress")   # hashtable: action -> value
$best    = $agent.GetBestAction("Gothic|Fortress") # string: best action
$q       = $agent.GetQValue("Gothic|Fortress", "Palace") # double

# Statistics
$stats = $agent.GetStats()
# Returns: Episode, TotalReward, AverageReward, RecentAverageReward,
#          QTableSize, Epsilon, ExplorationCount, ExploitationCount, MemorySize
```

---

## Deep Q-Network (DQN)

### DQNConfig class

```powershell
$config              = [DQNConfig]::new()
$config.StateSize    = 4        # number of state signals
$config.ActionSize   = 4        # number of actions
$config.LearningRate = 0.001    # neural network learning rate
$config.Gamma        = 0.95     # discount factor
$config.Epsilon      = 1.0      # starting exploration rate
$config.EpsilonDecay = 0.9995   # per-step decay
$config.EpsilonMin   = 0.05     # minimum exploration rate
$config.MemorySize   = 10000    # replay buffer capacity
$config.BatchSize    = 32       # training batch size
$config.TargetUpdateFreq = 10   # sync target network every N episodes
```

### DQNAgent class

```powershell
# Create agent manually
[int[]] $arch   = @(4, 24, 24, 4)
$main           = [NeuralNetwork]::new($arch, $config.LearningRate)
$target         = [NeuralNetwork]::new($arch, $config.LearningRate)
$memory         = [ExperienceReplay]::new($config.MemorySize)
$agent          = [DQNAgent]::new($config, $main, $target, $memory)

# Core methods
$action = $agent.Act($state)                              # returns int
$agent.Remember($state, $action, $reward, $next, $done)   # store transition
$agent.Replay()                                           # train on batch
$agent.EndEpisode($episodeReward)                         # update epsilon
$agent.PrintStats()                                       # print summary
```

### Invoke-DQNTraining

```powershell
# Train on built-in CartPole environment
$results = Invoke-DQNTraining -Episodes 100 -PrintEvery 10
$results = Invoke-DQNTraining -Episodes 50  -PrintEvery 5 -FastMode

# Get the final trained agent
$agent = $results[-1]
$agent.PrintStats()

# Returns array of agent snapshots (one per PrintEvery interval)
# Last element is the fully trained agent
```

### Invoke-PPOTraining

```powershell
$results = Invoke-PPOTraining -Episodes 50 -PrintEvery 5
$results = Invoke-PPOTraining -Episodes 50 -PrintEvery 5 -FastMode
$agent   = $results[-1]
$agent.PrintStats()
```

### Invoke-A3CTraining

```powershell
$results = Invoke-A3CTraining -Episodes 20 -PrintEvery 2
$results = Invoke-A3CTraining -Episodes 20 -PrintEvery 2 -FastMode
$agent   = $results[-1]
$agent.PrintStats()
```

---

## Experience Replay

### ExperienceReplay class

```powershell
$memory = [ExperienceReplay]::new(10000)   # capacity

# Store a transition
$experience = @{
    State     = $state
    Action    = $action
    Reward    = $reward
    NextState = $nextState
    Done      = $done
}
$memory.Add($experience)

# Sample a random batch
$batch = $memory.Sample(32)   # returns ArrayList of 32 experiences

# Query
$memory.Size()       # current number of stored experiences
$memory.IsFull()     # bool -- has capacity been reached
```

---

## Environments

### New-VBAFEnvironment

```powershell
$env = New-VBAFEnvironment -Name "CartPole"   # CartPole, GridWorld, RandomWalk
$env = New-VBAFEnvironment -Name "CartPole" -MaxSteps 200
$env.PrintInfo()

# Standard interface
$state = $env.Reset()                  # double[] -- initial state
$env.Step($action)                     # apply action
$reward = $env.LastReward              # double
$done   = $env.LastDone                # bool
$state  = $env.GetState()              # double[] -- current state
```

### Invoke-VBAFBenchmark

```powershell
$env    = New-VBAFEnvironment -Name "CartPole" -MaxSteps 200
$result = Invoke-VBAFBenchmark -Agent $agent -Environment $env -Episodes 20 -Label "DQN"
# Prints per-episode reward and summary statistics
```

### New-RewardShaper

```powershell
$shaper = New-RewardShaper -Type "Sparse"    # Sparse, Dense, Shaped
```

---

## Datasets

### Supervised Learning Datasets

```powershell
$data = Get-VBAFDataset -Name "HousePrice"
# Returns: $data.X (double[][]), $data.y (double[]), $data.Features (string[])
# Available names: "HousePrice"

$data = Get-VBAFNBDataset -Name "Iris3Class"
# Available: "Iris3Class"

$data = Get-VBAFPipelineDataset -Name "MessyHousePrice"
# Messy dataset with missing values and outliers

$data = Get-VBAFTreeDataset -Name "HousePrice"
# Formatted for decision tree training

$data = Get-VBAFClusterDataset -Name "Blobs"
# Available: "Blobs"
```

### Time Series Datasets

```powershell
$ts = Get-VBAFTimeSeriesDataset -Name "Sales"
$ts.PrintSummary()
$ts.Plot()
```

### Image Datasets

```powershell
$data = Get-VBAFImageDataset -Name "Shapes"
# Returns images as tensors for CNN training
```

### Sequence Datasets

```powershell
$data = Get-VBAFSequenceDataset -Name "SineWave"
# Returns: $data.Sequences (double[][][]), $data.Targets
```

---

## Preprocessing

### Split-TrainTest

```powershell
$split = Split-TrainTest -X $data.X -y $data.y -TestSize 0.2 -Seed 42
# Returns: $split.XTrain, $split.yTrain, $split.XTest, $split.yTest
```

### Scalers

```powershell
$sc = [StandardScaler]::new()      # zero mean, unit variance
$sc = [MinMaxScaler]::new()        # scale to [0,1]
$sc = [RobustScaler]::new()        # median/IQR, robust to outliers

$Xs = $sc.FitTransform($Xtrain)    # fit on train, transform train
$Xt = $sc.Transform($Xtest)        # transform test (never fit on test)
$sc.PrintSummary()
```

### Imputation and Outliers

```powershell
$imp = [MissingValueImputer]::new("median")   # "median"|"mean"|"zero"
$Xi  = $imp.FitTransform($X)
$imp.PrintSummary()

$out = [OutlierDetector]::new("iqr", "clip", 1.5)
$out.Fit($X)
$Xc  = ($out.Transform($X)).Data   # always use .Data property
```

### Encoders

```powershell
$le  = [LabelEncoder]::new()
$ohe = [OneHotEncoder]::new()
$te  = [TargetEncoder]::new()
$Xe  = $le.FitTransform($X)
```

### Feature Engineering

```powershell
$poly = [PolynomialFeatures]::new(2)   # degree 2 or 3
$Xp   = $poly.FitTransform($X, $featureNames)
$poly.PrintSummary()

$pca = [PCA]::new(2)   # n_components
$Xr  = $pca.FitTransform($X)

# Pipeline (applies steps in order, prevents leakage)
$pipe = [TransformerPipeline]::new()
$pipe.Add([MissingValueImputer]::new("median"))
$pipe.Add([StandardScaler]::new())
$pipe.Add([PolynomialFeatures]::new(2))
$Xp = $pipe.FitTransform($Xtrain, $featureNames)
$Xt = $pipe.Transform($Xtest)
```

---

## Regression Models

```powershell
$lr    = [LinearRegression]::new()
$ridge = [RidgeRegression]::new(0.01)     # lambda
$lasso = [LassoRegression]::new(0.01)     # lambda
$dt    = [DecisionTree]::new("regression", 3, 2)   # task, maxDepth, minSamples
$rf    = [RandomForest]::new(10, 3, 2)    # nTrees, maxDepth, minSamples

# All models: same interface
$model.Fit($Xtrain, $ytrain)
$preds = $model.Predict($Xtest)
$model.PrintSummary()
```

---

## Classification Models

```powershell
$gnb  = [GaussianNaiveBayes]::new()
$mnb  = [MultinomialNaiveBayes]::new()
$bnb  = [BernoulliNaiveBayes]::new()
$logr = [LogisticRegression]::new()
$dt   = [DecisionTree]::new("classification", 3, 2)
$rf   = [RandomForest]::new(10, 3, 2)

# All models: same interface
$model.Fit($Xtrain, $ytrain)
$preds  = $model.Predict($Xtest)
$probas = $model.PredictProba($Xtest)   # where supported
$model.PrintSummary()
```

---

## Clustering

```powershell
$km   = [KMeans]::new(3)                  # k
$hier = [HierarchicalClustering]::new(3)  # k
$db   = [DBSCAN]::new(0.5, 5)            # eps, minSamples

$km.Fit($X)
$labels    = $km.Predict($X)
$centroids = $km.Centroids
$km.PrintSummary()

$score = Get-SilhouetteScore -X $X -Labels $labels
Invoke-ElbowMethod -X $X -MaxK 10
```

---

## Metrics

```powershell
$m = Get-RegressionMetrics $ytrue $ypred
# Returns: $m.R2, $m.RMSE, $m.MAE, $m.MSE

$m = Get-ClassificationMetrics $ytrue $ypred
# Returns: $m.Accuracy, $m.Precision, $m.Recall, $m.F1

$cv = Invoke-KFoldCV -Model $model -X $X -y $y -Folds 5 -Metric "R2"
# Returns: $cv.Scores (double[]), $cv.Mean, $cv.Std
```

---

## Model Selection

```powershell
# Algorithm selection -- tries multiple models, returns ranked results
$r = Invoke-VBAFAlgorithmSelection -X $X -y $y -Task "regression" -Folds 5 -Metric "R2"

# Grid search
$r = Invoke-VBAFGridSearch `
    -ModelFactory { param($p) [RidgeRegression]::new($p.Lambda) } `
    -ParamSpace @{ Lambda = @(0.001, 0.01, 0.1, 1.0) } `
    -X $X -y $y -Folds 5 -Metric "R2"

# Random search
$r = Invoke-VBAFRandomSearch `
    -ModelFactory { param($p) [RidgeRegression]::new($p.Lambda) } `
    -ParamSpace @{ Lambda = @(0.001, 0.01, 0.1, 1.0) } `
    -X $X -y $y -NTrials 8 -Folds 5 -Metric "R2"

# Bayesian search
$r = Invoke-VBAFBayesianSearch `
    -ModelFactory { param($p) [RidgeRegression]::new($p.Lambda) } `
    -ParamSpace @{ Lambda = @(0.001, 0.01, 0.1, 1.0) } `
    -X $X -y $y -NTrials 20 -Folds 5 -Metric "R2"

# AutoML -- runs everything and returns best model
$auto = Invoke-VBAFAutoML `
    -X $Xs -y $data.y `
    -FeatureNames @("size_sqm", "bedrooms", "age_years") `
    -OptMethod "bayesian"   # "grid"|"random"|"bayesian"
```

---

## Explainability

```powershell
# Permutation importance
Get-VBAFPermutationImportance `
    -Model $model -ModelType "LinearRegression" `
    -X $Xs -y $data.y `
    -FeatureNames @("size_sqm", "bedrooms", "age_years")

# SHAP values
$shap = Get-VBAFSHAPValues -Model $model -ModelType "LinearRegression" -X $Xs
Show-VBAFSHAPExplanation -SHAPValues $shap -FeatureNames $featureNames

# LIME explanation (local -- one prediction at a time)
$lime = Get-VBAFLIMEExplanation `
    -Model $model -ModelType "LinearRegression" `
    -Instance $Xs[0] -X $Xs -FeatureNames $featureNames

# Partial dependence plot
Get-VBAFPartialDependence `
    -Model $model -ModelType "LinearRegression" `
    -X $Xs -FeatureIndex 0 -FeatureName "size_sqm"
```

---

## Model Registry

```powershell
# Initialise registry (run once)
Initialize-VBAFRegistry
Set-VBAFRegistryPath -Path "C:\MyModels"   # optional custom path

# Save a model
Save-VBAFModel `
    -ModelName "HousePrice" `
    -Model $model `
    -ModelType "LinearRegression" `
    -Metrics @{ R2 = 0.99; RMSE = 12.3 }

# Load and list
$model = Load-VBAFModel -ModelName "HousePrice"
Get-VBAFModelList
Get-VBAFModelInfo -ModelName "HousePrice"
Compare-VBAFModels -ModelName "HousePrice"
Remove-VBAFModel -ModelName "HousePrice" -Version "1.0.0"
```

---

## Model Server

```powershell
# Single prediction
$r = Invoke-VBAFPrediction `
    -Model $model -ModelType "LinearRegression" `
    -Features @(120.0, 3.0, 5.0) -Scaler $scaler
Write-Host "Prediction: $($r.Prediction)  Latency: $($r.LatencyMs)ms"

# Batch prediction
$results = Invoke-VBAFBatchPrediction `
    -Model $model -ModelType "LinearRegression" `
    -X $Xtest -Scaler $scaler

# A/B testing
Start-VBAFABTest `
    -TestName "v1vsv2" `
    -ModelA $m1 -ModelAName "HP" -ModelAVersion "1.0" -ModelAType "LinearRegression" `
    -ModelB $m2 -ModelBName "HP" -ModelBVersion "1.1" -ModelBType "RidgeRegression"
$pred = Invoke-VBAFABPredict -TestName "v1vsv2" -Features @(120.0, 3.0, 5.0) -Scaler $scaler
$stats = Get-VBAFABStats -TestName "v1vsv2"
Stop-VBAFABTest -TestName "v1vsv2"

# Monitoring
$stats = Get-VBAFMonitoringStats
Export-VBAFMonitoringLog -Path "C:\Temp\monitoring.csv"
```

---

## MLOps

```powershell
# Experiment tracking
New-VBAFExperiment -Name "HousePriceV2"
Start-VBAFRun -RunName "ridge-lambda-0.01" -ModelType "RidgeRegression" `
    -Params @{ Lambda = 0.01; Scaler = "Standard" }
Set-VBAFRunMetric -Key "R2"   -Value 0.998
Set-VBAFRunMetric -Key "RMSE" -Value 8.2
Set-VBAFRunParam  -Key "Folds" -Value 5
Set-VBAFRunTag    -Key "Dataset" -Value "HousePrice-v2"
Stop-VBAFRun
Get-VBAFExperimentRuns
Compare-VBAFRuns

# Drift detection
$report = Get-VBAFDriftReport -Reference $Xtrain -Current $Xnew
# Returns per-feature drift scores and overall drift flag

# Retraining policy
$policy = New-VBAFRetrainingPolicy -DriftThreshold 0.15 -MaxAgeDays 30
$needed = Test-VBAFRetrainingNeeded -Policy $policy -DriftReport $report

# CI/CD pipeline
$pipeline = Invoke-VBAFMLPipeline `
    -Data $data -ModelType "RidgeRegression" -Metric "R2" -Threshold 0.95
$gate = Test-VBAFModelGate -Model $model -ModelType "RidgeRegression" `
    -X $Xtest -y $ytest -Metric "R2" -Threshold 0.95
Export-VBAFPipelineScript -Path "C:\Pipelines\house-price.ps1"
```

---

## Enterprise Agents

All enterprise training functions follow the same pattern:

```powershell
$r = Invoke-VBAFXxxTraining -Episodes 100 -PrintEvery 10 -SimMode
# Returns: $r.Agent, $r.Baseline.Avg, $r.Trained.Avg
# Improvement = ($r.Trained.Avg - $r.Baseline.Avg) / |$r.Baseline.Avg| * 100
```

### Available Training Functions

```powershell
# Core RL
Invoke-DQNTraining                      -Episodes 100 -PrintEvery 10
Invoke-PPOTraining                      -Episodes 50  -PrintEvery 5  -FastMode
Invoke-A3CTraining                      -Episodes 20  -PrintEvery 2  -FastMode

# Business
Invoke-VBAFJobSchedulerTraining         -Episodes 50  -FastMode
Invoke-VBAFResourceOptimizerTraining    -Episodes 200 -PrintEvery 50 -SimMode
Invoke-VBAFAlertRouterTraining          -Episodes 50  -PrintEvery 10 -SimMode
Invoke-VBAFSupplyChainTraining          -Episodes 100 -PrintEvery 20

# Security and network
Invoke-VBAFSecurityMonitorTraining      -Episodes 100 -PrintEvery 10 -SimMode
Invoke-VBAFNetworkWatcherTraining       -Episodes 100 -PrintEvery 10 -SimMode
Invoke-VBAFDataFlowOptimizerTraining    -Episodes 100 -PrintEvery 10 -SimMode

# Enterprise pillars (Phases 11-27)
Invoke-VBAFMultiAgentTraining           -Episodes 100 -PrintEvery 10 -SimMode
Invoke-VBAFPredictiveMaintenanceTraining -Episodes 100 -PrintEvery 10 -SimMode
Invoke-VBAFNLInterfaceTraining          -Episodes 100 -PrintEvery 10 -SimMode
Invoke-VBAFSelfHealingTraining          -Episodes 100 -PrintEvery 10 -SimMode
Invoke-VBAFDashboardTraining            -Episodes 100 -PrintEvery 10 -SimMode
Invoke-VBAFFederatedLearningTraining    -Episodes 100 -PrintEvery 10 -SimMode
Invoke-VBAFCloudBridgeTraining          -Episodes 100 -PrintEvery 10 -SimMode
Invoke-VBAFAnomalyDetectorTraining      -Episodes 100 -PrintEvery 10 -SimMode
Invoke-VBAFCapacityPlannerTraining      -Episodes 100 -PrintEvery 10 -SimMode
Invoke-VBAFIncidentResponderTraining    -Episodes 100 -PrintEvery 10 -SimMode
Invoke-VBAFComplianceReporterTraining   -Episodes 100 -PrintEvery 10 -SimMode
Invoke-VBAFUserBehaviorAnalyticsTraining -Episodes 100 -PrintEvery 10 -SimMode
Invoke-VBAFPatchIntelligenceTraining    -Episodes 100 -PrintEvery 10 -SimMode
Invoke-VBAFBackupOptimizerTraining      -Episodes 100 -PrintEvery 10 -SimMode
Invoke-VBAFEnergyOptimizerTraining      -Episodes 100 -PrintEvery 10 -SimMode
Invoke-VBAFMultiSiteCoordinatorTraining -Episodes 100 -PrintEvery 10 -SimMode
Invoke-VBAFAutoPilotTraining            -Episodes 100 -PrintEvery 10 -SimMode

# Domain-specific
Invoke-VBAFFleetDispatchTraining        -SimMode
Invoke-VBAFHealthcareMonitorTraining    -SimMode
```

---

## Market Simulation

```powershell
# Create market
$market = New-Object MarketEnvironment

# Add companies
$company = New-Object CompanyAgent -ArgumentList "TechCorp", "Technology", 1000000.0
$market.AddCompany($company)

# Run simulation
$snapshot = $market.SimulateQuarter()
$market.DisplayMarketStatus()
$summary  = $market.GetMarketSummary()

# Access results
$market.Companies | Sort-Object { $_.State.MarketShare } -Descending
$market.History   # all quarter snapshots
```

---

## Visualization

### Training Metrics

```powershell
$collector = [MetricsCollector]::new()
$collector.RecordError(0.45)
$collector.RecordReward(12.3)
$collector.RecordEpsilon(0.85)
```

### Dashboards (run from standalone console, not ISE)

```powershell
& .\VBAF.Visualization.Example-Dashboard.ps1   # learning curves
& .\VBAF.Business.Dashboard-Demo.ps1           # market competition
& .\VBAF.Core.Test-ValidationDashboard.ps1     # three-panel validation
& .\VBAF.Art.Show20-QLearning.ps1              # Q-learning visual
& .\VBAF.Art.CastleCompetition.ps1             # castle battle
```

---

## Deep Learning

### CNN

```powershell
$model = [CNNModel]::new("ShapeClassifier", 8, 8, 1)  # name, H, W, channels
$model.Add([Conv2D]::new(4, 3))           # filters, kernelSize
$model.Add([MaxPooling2D]::new(2))        # poolSize
$model.Add([BatchNormalization]::new())
$model.Add([Dropout]::new(0.2))           # dropRate
$model.Add([Flatten]::new())
$model.Add([DenseLayer]::new(3, "softmax"))  # units, activation
$model.PrintSummary()

Save-CNNWeights -Model $model -Path "C:\Temp\cnn.json"
$model = Load-CNNWeights -Path "C:\Temp\cnn.json"
$data  = Get-VBAFImageDataset -Name "Shapes"
Show-TensorAscii -Tensor $data.Images[0]
```

### RNN

```powershell
$lstm = [LSTMCell]::new(1, 8)      # inputSize, hiddenSize
$gru  = [GRUCell]::new(1, 8)
$rnn  = [BasicRNNCell]::new(1, 8)
$lstm.PrintSummary()

$data = Get-VBAFSequenceDataset -Name "SineWave"
$out  = $lstm.Forward($data.Sequences[0])
Write-Host "Steps: $($out.Length)  Hidden: $($out[0].Length)"

Compare-RNNArchitectures
```

### Autoencoder

```powershell
Test-VBAFAutoencoder              # quick demo
$data    = Get-VBAFAEDataset -Name "Shapes2D"
$model   = [BasicAutoencoder]::new(...)
$history = Invoke-VBAFAETrain -Model $model -Data $data -Epochs 50
$latent  = Get-VBAFLatent -Model $model -Data $data
Show-VBAFLatentSpace -Latent $latent
Show-VBAFReconstruction -Model $model -Data $data
```

### Transfer Learning

```powershell
Test-VBAFTransferLearning         # quick demo
$zoo   = Get-VBAFModelZoo
$model = Get-VBAFPretrainedModel -Name "VGG-Mini"
Set-VBAFAllLayersFrozen -Model $model
Show-VBAFModelStatus -Model $model
$feat  = Get-VBAFFeatures -Model $model -X $data.X
Invoke-VBAFFineTune -Model $model -X $Xtrain -y $ytrain -Epochs 20
Save-VBAFTLWeights -Model $model -Path "C:\Temp\tl.json"
```

---

## Data I/O

```powershell
# CSV
Export-VBAFCsv -Data $rows -Path "C:\Temp\data.csv"
$rows   = Import-VBAFCsv -Path "C:\Temp\data.csv"
$matrix = Convert-RowsToMatrix `
    -Rows $rows `
    -FeatureColumns @("size_sqm", "bedrooms") `
    -TargetColumn "price"

# Streaming (large files)
Import-VBAFCsvStreaming -Path "C:\Temp\big.csv" -ChunkSize 1000 -ProcessChunk {
    param($chunk) Write-Host "Processing $($chunk.Count) rows"
}

# JSON
Export-VBAFJson -Data $data -Path "C:\Temp\data.json"
$data = Import-VBAFJson -Path "C:\Temp\data.json"

# Excel
Export-VBAFExcel -Data $rows -Path "C:\Temp\data.xlsx" -SheetName "Results"
$rows = Import-VBAFExcel -Path "C:\Temp\data.xlsx" -SheetName "Results"

# SQL
$rows = Invoke-VBAFSqlQuery `
    -ConnectionString "Server=.\SQLEXPRESS;Database=MyDB;Trusted_Connection=True" `
    -Query "SELECT * FROM HousePrices"
Export-VBAFSqlTable -Data $rows -ConnectionString $cs -TableName "Predictions"

# API
$data = Get-VBAFApiData -Url "https://api.example.com/data" -Headers @{ ApiKey = "xxx" }

# Validation
$validator = [DataValidator]::new()
$report    = $validator.Validate($rows, @{ price = "numeric"; city = "string" })
Get-DataSummary -Data $rows
```

---

## Time Series

```powershell
$ts = Get-VBAFTimeSeriesDataset -Name "Sales"
$ts.PrintSummary()
$ts.Plot()

$dt   = ConvertTo-VBAFDateTime -DateString "2024-01-15"
$feat = Get-DatetimeFeatures -Dates $dateColumn
$Xl   = Add-LagFeatures -X $X -Lags @(1, 7, 30)
$Xr   = Add-RollingFeatures -X $X -Windows @(7, 30) -Functions @("mean", "std")

$decomp = Invoke-SeasonalDecomposition -TimeSeries $ts -Period 12
# Returns: $decomp.Trend, $decomp.Seasonal, $decomp.Residual

$resampled = Invoke-TimeSeriesResample -TimeSeries $ts -Frequency "monthly" -Aggregation "sum"
```

---

## Common Patterns

### Full supervised learning pipeline

```powershell
. .\VBAF.LoadAll.ps1
$data   = Get-VBAFDataset -Name "HousePrice"
$split  = Split-TrainTest -X $data.X -y $data.y -TestSize 0.2 -Seed 42
$scaler = [StandardScaler]::new()
$Xtrain = $scaler.FitTransform($split.XTrain)
$Xtest  = $scaler.Transform($split.XTest)
$model  = [RidgeRegression]::new(0.01)
$model.Fit($Xtrain, $split.yTrain)
$preds  = $model.Predict($Xtest)
$m      = Get-RegressionMetrics $split.yTest $preds
Write-Host "R2: $($m.R2)  RMSE: $($m.RMSE)"
```

### Full DQN training pipeline

```powershell
. .\VBAF.LoadAll.ps1
$config           = [DQNConfig]::new()
$config.StateSize = 4
$config.ActionSize = 4
[int[]] $arch     = @(4, 24, 24, 4)
$main             = [NeuralNetwork]::new($arch, $config.LearningRate)
$target           = [NeuralNetwork]::new($arch, $config.LearningRate)
$memory           = [ExperienceReplay]::new($config.MemorySize)
$agent            = [DQNAgent]::new($config, $main, $target, $memory)
$env              = [MyCustomEnvironment]::new()

for ($ep = 1; $ep -le 100; $ep++) {
    [double[]] $state = $env.Reset()
    $epReward = 0.0
    while (-not $env.LastDone) {
        $action = $agent.Act($state)
        $env.Step($action)
        [double[]] $next = $env.GetState()
        $agent.Remember($state, $action, $env.LastReward, $next, $env.LastDone)
        if ($ep % 4 -eq 0) { $agent.Replay() | Out-Null }
        $state     = $next
        $epReward += $env.LastReward
    }
    $agent.EndEpisode($epReward) | Out-Null
}
$agent.PrintStats()
```
