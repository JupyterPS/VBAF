# VBAF API Reference

**Visual Business Automation Framework - Complete API Documentation**

*Version 1.0 | PowerShell 5.1+*

---

## Table of Contents

- [Core Classes](#core-classes)
  - [Neuron](#neuron)
  - [Layer](#layer)
  - [NeuralNetwork](#neuralnetwork)
  - [Activation](#activation)
- [Reinforcement Learning](#reinforcement-learning)
  - [QLearningAgent](#qlearningagent)
  - [ExperienceReplay](#experiencereplay)
- [Visualization](#visualization)
  - [LearningDashboard](#learningdashboard)
  - [MetricsCollector](#metricscollector)
  - [GraphRenderer](#graphrenderer)
- [Business Applications](#business-applications)
  - [CompanyAgent](#companyagent)
  - [MarketEnvironment](#marketenvironment)

---

## Core Classes

### Neuron

**Purpose:** Represents a single artificial neuron with weighted inputs and bias.

**Location:** `Core/Neuron.ps1`

#### Constructor

```powershell
Neuron([int]$inputCount)
```

**Parameters:**
- `$inputCount` - Number of inputs this neuron accepts

**Example:**
```powershell
# Create neuron that accepts 3 inputs
$neuron = New-Object Neuron -ArgumentList 3
```

#### Properties

| Property  | Type       | Description                       |
|---------- |------      |-------------                      |
| `Weights` | `double[]` | Array of input weights            |
| `Bias`    | `double`   | Bias value added to weighted sum  |
| `Output`  | `double`   | Last computed output value        |
| `Delta`   | `double`   | Error gradient (used in backprop) |

#### Methods

##### Forward()

```powershell
[double] Forward([double[]]$inputs)
```

Computes neuron output using weighted sum + bias + activation.

**Parameters:**
- `$inputs` - Array of input values

**Returns:** Output value (0.0 to 1.0 after sigmoid)

**Example:**
```powershell
$output = $neuron.Forward(@(0.5, 0.3, 0.8))
Write-Host "Neuron output: $output"
# Output: 0.7234 (example)
```

##### UpdateWeights()

```powershell
[void] UpdateWeights([double[]]$inputs, [double]$learningRate)
```

Updates weights and bias using gradient descent.

**Parameters:**
- `$inputs` - Input values from forward pass
- `$learningRate` - Learning rate (typically 0.01 to 0.5)

**Example:**
```powershell
$neuron.Delta = 0.15  # Set from backprop
$neuron.UpdateWeights(@(0.5, 0.3, 0.8), 0.1)
```

---

### Layer

**Purpose:** Collection of neurons that process inputs in parallel.

**Location:** `Core/Layer.ps1`

#### Constructor

```powershell
Layer([int]$neuronCount, [int]$inputsPerNeuron)
```

**Parameters:**
- `$neuronCount` - Number of neurons in this layer
- `$inputsPerNeuron` - Number of inputs each neuron receives

**Example:**
```powershell
# Create hidden layer: 5 neurons, each with 3 inputs
$hiddenLayer = New-Object Layer -ArgumentList 5, 3
```

#### Properties

| Property  | Type       | Description                      |
|---------- |------      |-------------                     |
| `Neurons` | `Neuron[]` | Array of neurons in layer        |
| `Outputs` | `double[]` | Output from each neuron          |
| `Inputs`  | `double[]` | Last input values (for backprop) |

#### Methods

##### Forward()

```powershell
[double[]] Forward([double[]]$inputs)
```

Propagates inputs through all neurons in parallel.

**Parameters:**
- `$inputs` - Input values for the layer

**Returns:** Array of outputs from all neurons

**Example:**
```powershell
$outputs = $hiddenLayer.Forward(@(0.5, 0.3, 0.8))
Write-Host "Layer outputs: $($outputs -join ', ')"
# Output: 0.65, 0.72, 0.81, 0.45, 0.59
```

---

### NeuralNetwork

**Purpose:** Multi-layer neural network with backpropagation training.

**Location:** `Core/NeuralNetwork.ps1`

#### Constructor

```powershell
NeuralNetwork([int[]]$architecture, [double]$learningRate)
```

**Parameters:**
- `$architecture` - Array defining network structure (e.g., @(2, 3, 1))
- `$learningRate` - Learning rate for training (0.01 to 0.5 typical)

**Example:**
```powershell
# Create network: 2 inputs, 3 hidden, 1 output
$nn = New-Object NeuralNetwork -ArgumentList @(2, 3, 1), 0.1
```

#### Properties

| Property | Type      | Description                           |
|----------|------     |-------------                          |
| `Layers` | `Layer[]` | Array of layers in network            |
| `LearningRate`       | `double` | Learning rate for training |

#### Methods

##### Forward()

```powershell
[double[]] Forward([double[]]$inputs)
```

Forward propagation through entire network.

**Parameters:**
- `$inputs` - Input values

**Returns:** Final output from network

**Example:**
```powershell
$output = $nn.Forward(@(0.5, 0.8))
Write-Host "Network output: $($output[0])"
```

##### Backward()

```powershell
[void] Backward([double]$target)
```

Backpropagation algorithm - updates all weights based on error.

**Parameters:**
- `$target` - Expected output value

**Example:**
```powershell
$output = $nn.Forward(@(1, 0))
$nn.Backward(1.0)  # Train it to output 1
```

##### Train()

```powershell
[hashtable[]] Train([hashtable[]]$data, [int]$epochs)
```

Complete training loop with error tracking.

**Parameters:**
- `$data` - Array of training samples: `@{Input=@(...); Expected=...}`
- `$epochs` - Number of training iterations

**Returns:** Array of training results (error per epoch)

**Example:**
```powershell
$xorData = @(
    @{Input=@(0,0); Expected=0},
    @{Input=@(0,1); Expected=1},
    @{Input=@(1,0); Expected=1},
    @{Input=@(1,1); Expected=0}
)

$results = $nn.Train($xorData, 1000)
Write-Host "Final error: $($results[-1].Error)"
```

##### Predict()

```powershell
[double[]] Predict([double[]]$inputs)
```

Inference mode - just forward pass, no training.

**Parameters:**
- `$inputs` - Input values

**Returns:** Network output

**Example:**
```powershell
$prediction = $nn.Predict(@(1, 0))
$rounded = [Math]::Round($prediction[0])
Write-Host "XOR(1,0) = $rounded"
```

---

### Activation

**Purpose:** Static class with activation functions and derivatives.

**Location:** `Core/Activation.ps1`

#### Static Methods

##### Sigmoid()

```powershell
[double] Sigmoid([double]$x)
```

Sigmoid activation: `1 / (1 + e^-x)`

**Range:** 0.0 to 1.0

**Example:**
```powershell
$output = [Activation]::Sigmoid(0.5)
# Output: 0.6225
```

##### SigmoidDerivative()

```powershell
[double] SigmoidDerivative([double]$x)
```

Derivative of sigmoid (for backprop): `sigmoid(x) * (1 - sigmoid(x))`

**Example:**
```powershell
$gradient = [Activation]::SigmoidDerivative(0.5)
# Output: 0.2350
```

##### ReLU()

```powershell
[double] ReLU([double]$x)
```

Rectified Linear Unit: `max(0, x)`

**Example:**
```powershell
[Activation]::ReLU(-0.5)  # Output: 0
[Activation]::ReLU(2.0)   # Output: 2.0
```

##### ReLUDerivative()

```powershell
[double] ReLUDerivative([double]$x)
```

Derivative: `1 if x > 0, else 0`

##### Tanh()

```powershell
[double] Tanh([double]$x)
```

Hyperbolic tangent: `tanh(x)`

**Range:** -1.0 to 1.0

---

## Reinforcement Learning

### QLearningAgent

**Purpose:** Q-Learning agent for reinforcement learning tasks.

**Location:** `RL/QLearningAgent.ps1`

#### Constructor

```powershell
QLearningAgent([string[]]$actions, [double]$learningRate, [double]$epsilon)
```

**Parameters:**
- `$actions` - Available actions (e.g., @("Up", "Down", "Left", "Right"))
- `$learningRate` - Learning rate (0.01 to 0.5)
- `$epsilon` - Exploration rate (0.0 to 1.0)

**Example:**
```powershell
$agent = New-Object QLearningAgent -ArgumentList @("Buy", "Sell", "Hold"), 0.1, 0.2
```

#### Properties

| Property       | Type               | Description                   |
|----------      |------              |-------------                  |
| `QTable`       | `hashtable`        | State-action value table      |
| `Actions`      | `string[]`         | Available actions             |
| `LearningRate` | `double`           | Alpha (α) learning rate       |
| `Epsilon`      | `double`           | Exploration probability       |
| `Gamma`        | `double`           | Discount factor (default 0.9) |
| `Memory`       | `ExperienceReplay` | Experience replay buffer      |

#### Methods

##### ChooseAction()

```powershell
[string] ChooseAction([string]$state)
```

Epsilon-greedy action selection.

**Parameters:**
- `$state` - Current state (string representation)

**Returns:** Selected action

**Example:**
```powershell
$action = $agent.ChooseAction("MarketBullish")
Write-Host "Agent chose: $action"
```

##### Learn()

```powershell
[void] Learn([string]$state, [string]$action, [double]$reward, [string]$nextState)
```

Q-Learning update: `Q(s,a) ← Q(s,a) + α[r + γ·max(Q(s',a')) - Q(s,a)]`

**Parameters:**
- `$state` - Current state
- `$action` - Action taken
- `$reward` - Reward received
- `$nextState` - Resulting state

**Example:**
```powershell
$agent.Learn("MarketBullish", "Buy", 10.5, "MarketNeutral")
```

##### GetQValue()

```powershell
[double] GetQValue([string]$state, [string]$action)
```

Retrieve Q-value for state-action pair.

**Returns:** Q-value (0.0 if never seen)

**Example:**
```powershell
$qValue = $agent.GetQValue("MarketBullish", "Buy")
Write-Host "Q(Bullish, Buy) = $qValue"
```

##### DecayEpsilon()

```powershell
[void] DecayEpsilon([double]$decayRate)
```

Reduce exploration over time.

**Parameters:**
- `$decayRate` - Multiply epsilon by this (e.g., 0.995)

**Example:**
```powershell
# Decay epsilon by 0.5% each episode
$agent.DecayEpsilon(0.995)
```

---

### ExperienceReplay

**Purpose:** Memory buffer for experience replay in RL.

**Location:** `RL/ExperienceReplay.ps1`

#### Constructor

```powershell
ExperienceReplay([int]$maxSize)
```

**Parameters:**
- `$maxSize` - Maximum number of experiences to store

**Example:**
```powershell
$memory = New-Object ExperienceReplay -ArgumentList 1000
```

#### Methods

##### Add()

```powershell
[void] Add([hashtable]$experience)
```

Store experience: `@{State=...; Action=...; Reward=...; NextState=...}`

**Example:**
```powershell
$memory.Add(@{
    State = "MarketBullish"
    Action = "Buy"
    Reward = 10.5
    NextState = "MarketNeutral"
})
```

##### Sample()

```powershell
[hashtable[]] Sample([int]$batchSize)
```

Random sample for training.

**Parameters:**
- `$batchSize` - Number of experiences to sample

**Returns:** Array of random experiences

**Example:**
```powershell
$batch = $memory.Sample(32)
foreach ($exp in $batch) {
    # Train on experience
    $agent.Learn($exp.State, $exp.Action, $exp.Reward, $exp.NextState)
}
```

---

## Visualization

### LearningDashboard

**Purpose:** Real-time visualization of training progress.

**Location:** `Visualization/LearningDashboard.ps1`

#### Constructor

```powershell
LearningDashboard([string]$title)
```

**Parameters:**
- `$title` - Window title

**Example:**
```powershell
$dashboard = New-Object LearningDashboard -ArgumentList "Training Progress"
```

#### Properties

| Property      Type                | Description          |
|----------    |------              |-------------         |
| `Metrics`    | `MetricsCollector` | Metrics storage      |
| `AutoUpdate` | `bool`             | Auto-refresh enabled |
| `Form`       | `Form`             | WinForms window      |

#### Methods

##### UpdateFromNeuralNetwork()

```powershell
[void] UpdateFromNeuralNetwork([hashtable]$trainingData)
```

Update dashboard with neural network metrics.

**Parameters:**
- `$trainingData` - Hashtable with `Error`, `Loss`, `Accuracy` keys

**Example:**
```powershell
$dashboard.UpdateFromNeuralNetwork(@{
    Error = 0.05
    Accuracy = 0.95
})
```

##### UpdateFromRLAgent()

```powershell
[void] UpdateFromRLAgent([hashtable]$agentStats)
```

Update with RL agent metrics.

**Parameters:**
- `$agentStats` - Hashtable with `Reward`, `Epsilon` keys

**Example:**
```powershell
$dashboard.UpdateFromRLAgent(@{
    Reward = 15.3
    Epsilon = 0.2
})
```

##### Show()

```powershell
[void] Show()
```

Display dashboard (blocking - window stays open).

**Example:**
```powershell
$dashboard.Show()
```

##### ShowNonBlocking()

```powershell
[void] ShowNonBlocking()
```

Display dashboard (non-blocking - script continues).

**Example:**
```powershell
$dashboard.ShowNonBlocking()

# Training continues while dashboard is visible
for ($i = 0; $i -lt 1000; $i++) {
    # Train...
    $dashboard.Refresh()
}
```

---

### MetricsCollector

**Purpose:** Collect and aggregate training metrics.

**Location:** `Visualization/MetricsCollector.ps1`

#### Methods

##### RecordError()

```powershell
[void] RecordError([double]$error)
```

Record neural network error.

##### RecordReward()

```powershell
[void] RecordReward([double]$reward)
```

Record RL reward.

##### RecordEpsilon()

```powershell
[void] RecordEpsilon([double]$epsilon)
```

Record exploration rate.

##### GetSummary()

```powershell
[hashtable] GetSummary()
```

Get statistics summary.

**Returns:** Hashtable with min/max/mean/latest for each metric

**Example:**
```powershell
$summary = $dashboard.Metrics.GetSummary()
Write-Host "Average reward: $($summary.Reward.Mean)"
Write-Host "Best reward: $($summary.Reward.Max)"
```

---

### GraphRenderer

**Purpose:** Static methods for drawing graphs.

**Location:** `Visualization/GraphRenderer.ps1`

#### Static Methods

##### DrawLineGraph()

```powershell
[void] DrawLineGraph([Graphics]$g, [Rectangle]$bounds, [array]$data, [string]$title, [Color]$color)
```

Draw a line graph.

**Parameters:**
- `$g` - Graphics object
- `$bounds` - Drawing area rectangle
- `$data` - Array of values
- `$title` - Graph title
- `$color` - Line color

---

## Business Applications

### CompanyAgent

**Purpose:** RL agent for business strategy simulation.

**Location:** `Business/CompanyAgent.ps1`

*Coming in Phase 2 - Week 5*

#### Constructor (Planned)

```powershell
CompanyAgent([string]$name, [string]$industry, [double]$startingCapital)
```

#### Methods (Planned)

- `ObserveMarket($market)` - Gather market state
- `DecideAction($state)` - Choose business action
- `ExecuteAction($action, $market)` - Apply decision
- `CalculateReward($outcome)` - Evaluate performance

---

### MarketEnvironment

**Purpose:** Multi-agent market simulation environment.

**Location:** `Business/MarketEnvironment.ps1`

*Coming in Phase 2 - Week 6*

#### Methods (Planned)

- `AddCompany($agent)` - Add competitor
- `SimulateQuarter()` - Run one time step
- `ResolveInteractions()` - Handle competition
- `GetMarketState()` - Current conditions

---

## Complete Examples

### Example 1: XOR Neural Network

```powershell
# Load framework
. ".\Core\NeuralNetwork.ps1"

# Create network
$nn = New-Object NeuralNetwork -ArgumentList @(2, 3, 1), 0.1

# Prepare data
$xorData = @(
    @{Input=@(0,0); Expected=0},
    @{Input=@(0,1); Expected=1},
    @{Input=@(1,0); Expected=1},
    @{Input=@(1,1); Expected=0}
)

# Train
Write-Host "Training..."
$results = $nn.Train($xorData, 1000)

# Test
Write-Host "`nTesting:"
foreach ($sample in $xorData) {
    $prediction = $nn.Predict($sample.Input)
    $rounded = [Math]::Round($prediction[0])
    Write-Host "XOR$($sample.Input) = $rounded"
}
```

### Example 2: Q-Learning Agent

```powershell
# Load framework
. ".\RL\QLearningAgent.ps1"

# Create agent
$agent = New-Object QLearningAgent -ArgumentList @("North", "South", "East", "West"), 0.1, 0.3

# Training loop
for ($episode = 0; $episode -lt 100; $episode++) {
    $state = "Start"
    
    for ($step = 0; $step -lt 10; $step++) {
        $action = $agent.ChooseAction($state)
        
        # Simulate environment
        $reward = Get-Random -Minimum -1.0 -Maximum 10.0
        $nextState = "State_$step"
        
        # Learn
        $agent.Learn($state, $action, $reward, $nextState)
        $state = $nextState
    }
    
    # Reduce exploration
    $agent.DecayEpsilon(0.99)
}

Write-Host "Training complete!"
Write-Host "Epsilon: $($agent.Epsilon)"
```

### Example 3: Training with Dashboard

```powershell
# Load framework
. ".\Visualization\LearningDashboard.ps1"

# Create components
$nn = New-Object NeuralNetwork -ArgumentList @(2, 3, 1), 0.1
$dashboard = New-Object LearningDashboard -ArgumentList "XOR Training"

# Show dashboard
$dashboard.ShowNonBlocking()

# Train with live updates
for ($epoch = 0; $epoch -lt 1000; $epoch++) {
    foreach ($sample in $xorData) {
        $output = $nn.Forward($sample.Input)
        $error = [Math]::Abs($sample.Expected - $output[0])
        $nn.Backward($sample.Expected)
        
        # Update dashboard
        $dashboard.UpdateFromNeuralNetwork(@{Error = $error})
    }
    
    if ($epoch % 10 -eq 0) {
        $dashboard.Refresh()
    }
}
```

---

## Error Handling

All VBAF classes use PowerShell's standard error handling:

```powershell
try {
    $nn = New-Object NeuralNetwork -ArgumentList @(2, 3, 1), 0.1
    $output = $nn.Predict(@(0.5, 0.8))
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace
}
```

---

## Version History

**v1.0.0** (Current)
- Neural networks with backpropagation
- Q-Learning agents
- Experience replay
- Learning visualization dashboard
- PowerShell 5.1 compatibility

**Planned:**
- v1.1.0: Company agents and market simulation
- v1.2.0: Advanced RL algorithms (PPO, A3C)
- v2.0.0: Computer vision and NLP modules

---

## Support

- **GitHub Issues:** [repo-link]/issues
- **Documentation:** [repo-link]/docs
- **Examples:** [repo-link]/examples
- **Discussions:** [repo-link]/discussions

---

*Last updated: [Date]*  
*VBAF Version: 1.0.0*

