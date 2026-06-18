#Requires -Version 5.1

<#
.SYNOPSIS
    VBAF Console Teacher -- Start-VBAFTeach
.DESCRIPTION
    Interactive console teacher that guides a student through VBAF
    concepts one step at a time. Press Enter to advance.

    WHAT YOU ARE LEARNING HERE:
    ============================
    This file is the VBAF teaching engine.
    It covers 6 topics in the correct learning order:

      Topic 1 -- What is machine learning?
      Topic 2 -- Neural networks and backpropagation
      Topic 3 -- Q-learning and the Q-table
      Topic 4 -- Deep Q-Networks (DQN)
      Topic 5 -- Multi-agent reinforcement learning
      Topic 6 -- Enterprise automation pillars

    HOW TO USE:
    ===========
    . .\VBAF.LoadAll.ps1
    Start-VBAFTeach                        -- full course (all 6 topics)
    Start-VBAFTeach -Topic "NeuralNetwork" -- one topic only
    Start-VBAFTeach -Topic "QLearning"
    Start-VBAFTeach -Topic "DQN"
    Start-VBAFTeach -Topic "MultiAgent"
    Start-VBAFTeach -Topic "Enterprise"

.NOTES
    Part of VBAF (Visual AI & Reinforcement Learning Framework)
    Phase 5 -- educational console teacher.
    ASCII only -- no Unicode, no emoji, no box-drawing characters.
#>


# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Write-TeachHeader {
    param([string]$Title, [string]$Subtitle = "")
    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    if ($Subtitle) {
        Write-Host "  $Subtitle" -ForegroundColor DarkGray
    }
    Write-Host ("=" * 60) -ForegroundColor Cyan
    Write-Host ""
}

function Write-TeachSection {
    param([string]$Title)
    Write-Host ""
    Write-Host "  -- $Title --" -ForegroundColor Yellow
    Write-Host ""
}

function Write-TeachText {
    param([string]$Text, [string]$Color = "White")
    foreach ($line in $Text -split "`n") {
        Write-Host "  $line" -ForegroundColor $Color
    }
}

function Write-TeachCode {
    param([string]$Code)
    Write-Host ""
    foreach ($line in $Code -split "`n") {
        Write-Host "    $line" -ForegroundColor Green
    }
    Write-Host ""
}

function Wait-ForEnter {
    param([string]$Prompt = "Press Enter to continue...")
    Write-Host ""
    Write-Host "  $Prompt" -ForegroundColor DarkGray
    Read-Host | Out-Null
}

function Write-TeachProgress {
    param([int]$Current, [int]$Total, [string]$TopicName)
    Write-Host ""
    Write-Host "  [ Topic $Current of $Total : $TopicName ]" -ForegroundColor Magenta
}


# ============================================================================
# TOPIC 1 -- WHAT IS MACHINE LEARNING
# ============================================================================

function Teach-MachineLearning {
    Write-TeachProgress -Current 1 -Total 6 -TopicName "What is Machine Learning?"
    Write-TeachHeader "TOPIC 1: WHAT IS MACHINE LEARNING?"

    Write-TeachSection "The Core Idea"
    Write-TeachText "Traditional programming:
  You write rules -> computer follows them.
  Example: IF temperature > 80 THEN send alert.

Machine learning:
  You show examples -> computer discovers the rules.
  Example: show 10,000 sensor readings, computer learns
  when to send alerts without being told the threshold."
    Wait-ForEnter

    Write-TeachSection "Three Paradigms"
    Write-TeachText "SUPERVISED LEARNING
  Learn from labelled examples (input -> correct output).
  Example: 1,000 house photos labelled 'cheap' or 'expensive'.
  The model learns what makes a house expensive.
  VBAF: LinearRegression, DecisionTree, NaiveBayes"
    Wait-ForEnter

    Write-TeachText "REINFORCEMENT LEARNING
  Learn from interaction (action -> reward).
  No labels -- the agent discovers good behaviour through trial and error.
  Example: a game-playing agent tries moves and learns which ones score points.
  VBAF: Q-learning, DQN, PPO, A3C, enterprise pillars"
    Wait-ForEnter

    Write-TeachText "UNSUPERVISED LEARNING
  Find structure in unlabelled data.
  Example: group 10,000 customers into segments without being told the segments.
  VBAF: KMeans, DBSCAN, HierarchicalClustering, Autoencoder"
    Wait-ForEnter

    Write-TeachSection "Why PowerShell?"
    Write-TeachText "VBAF is the only ML framework written entirely in PowerShell 5.1.

  No Python. No pip install. No virtual environments.
  No internet required after installation.
  Runs on any Windows 10/11 machine.

  Every IT professional who knows PowerShell can read and modify VBAF.
  This is the educational advantage -- the code explains itself."
    Wait-ForEnter

    Write-TeachSection "Try It Now"
    Write-TeachText "Run your first supervised learning model:" -Color "Cyan"
    Write-TeachCode '$data   = Get-VBAFDataset -Name "HousePrice"
$scaler = [StandardScaler]::new()
$Xs     = $scaler.FitTransform($data.X)
$model  = [LinearRegression]::new()
$model.Fit($Xs, $data.y)
$model.PrintSummary()'
    Wait-ForEnter "Topic 1 complete. Press Enter for Topic 2: Neural Networks..."
}


# ============================================================================
# TOPIC 2 -- NEURAL NETWORKS
# ============================================================================

function Teach-NeuralNetwork {
    Write-TeachProgress -Current 2 -Total 6 -TopicName "Neural Networks"
    Write-TeachHeader "TOPIC 2: NEURAL NETWORKS AND BACKPROPAGATION"

    Write-TeachSection "The Perceptron (1958)"
    Write-TeachText "A single neuron computes:

  output = activation(w1*x1 + w2*x2 + ... + wn*xn + bias)

  w = weights (what the neuron has learned)
  x = inputs  (the data coming in)
  bias = offset (shifts the decision boundary)
  activation = sigmoid, ReLU, tanh (adds non-linearity)"
    Wait-ForEnter

    Write-TeachSection "The XOR Problem"
    Write-TeachText "XOR truth table:
  0 XOR 0 = 0   (both same    -> 0)
  0 XOR 1 = 1   (different    -> 1)
  1 XOR 0 = 1   (different    -> 1)
  1 XOR 1 = 0   (both same    -> 0)

  Plot these 4 points on a 2D graph.
  You CANNOT draw one straight line separating the 0s from the 1s.
  This is called: NOT LINEARLY SEPARABLE.

  A single neuron can only learn linearly separable functions.
  Minsky and Papert proved this in 1969 -- killing AI funding for a decade.
  The first AI winter."
    Wait-ForEnter

    Write-TeachSection "The Solution: Hidden Layers"
    Write-TeachText "Add a hidden layer between input and output:

  Input layer (2 neurons)
      |
  Hidden layer (3 neurons) -- learns non-linear transformations
      |
  Output layer (1 neuron)

  The hidden neurons learn internal representations that make
  XOR linearly separable in a higher-dimensional space.

  Universal Approximation Theorem (Cybenko, 1989):
  A network with one hidden layer can approximate ANY continuous function."
    Wait-ForEnter

    Write-TeachSection "Backpropagation"
    Write-TeachText "How does the network learn the right weights?

  1. FORWARD PASS: input flows forward, output is computed
  2. COMPUTE ERROR: how wrong was the output?
  3. BACKWARD PASS: propagate error gradient back through layers
  4. UPDATE WEIGHTS: adjust each weight by learning_rate * gradient

  This is repeated thousands of times.
  Each iteration: weights get slightly better.
  Eventually: the network solves the problem.

  Rumelhart, Hinton & Williams (1986) -- the paper that started modern AI."
    Wait-ForEnter

    Write-TeachSection "Try It Now"
    Write-TeachText "Run the XOR example and watch backpropagation work:" -Color "Cyan"
    Write-TeachCode 'cd "C:\Users\henni\OneDrive\WindowsPowerShell\examples\01-XOR-Network"
. .\Run-Example-01.ps1

# Watch:
# Error starts high (random weights)
# Error drops toward 0.001 as backpropagation finds the right weights
# Accuracy reaches 100% -- all 4 XOR cases correct'
    Wait-ForEnter

    Write-TeachSection "Key Numbers"
    Write-TeachText "Learning rate:
  Too high (0.5+): weights overshoot, training oscillates
  Too low (0.0001): stable but very slow
  VBAF default for XOR: 0.5 (simple problem)
  VBAF default for DQN: 0.001 (complex, stability matters)

Architecture [2, 3, 1] means:
  2 input neurons
  3 hidden neurons
  1 output neuron

  Why 3 hidden? More neurons = more ways to learn the pattern.
  XOR works with 2 hidden but 3 converges faster."
    Wait-ForEnter "Topic 2 complete. Press Enter for Topic 3: Q-Learning..."
}


# ============================================================================
# TOPIC 3 -- Q-LEARNING
# ============================================================================

function Teach-QLearning {
    Write-TeachProgress -Current 3 -Total 6 -TopicName "Q-Learning"
    Write-TeachHeader "TOPIC 3: Q-LEARNING AND THE Q-TABLE"

    Write-TeachSection "The RL Loop"
    Write-TeachText "Reinforcement learning is a loop:

  State(t) -> Agent -> Action(t) -> Environment -> Reward(t) + State(t+1)

  State:   what the agent currently sees
  Action:  what the agent chooses to do
  Reward:  feedback (+good, -bad)
  Policy:  what the agent has learned to do in each state

  The agent's goal: maximise total reward over time."
    Wait-ForEnter

    Write-TeachSection "The Q-Table"
    Write-TeachText "Q-learning stores a table: Q(state, action) = expected future reward.

  Example Q-table after training:
    State 'Gothic|Fortress'    -> FairyTale:  1.89  (prefer this)
    State 'Gothic|Fortress'    -> Gothic:    -0.45  (avoid this)
    State 'Palace|Wizard'      -> Cathedral:  1.72  (prefer this)

  The table is a hashtable in PowerShell -- you can READ it directly.
  This is the unique advantage of Q-learning over DQN:
  full transparency -- you can see exactly what the agent learned."
    Wait-ForEnter

    Write-TeachSection "The Bellman Equation"
    Write-TeachText "How Q-values are updated after each step:

  Q(s,a) = Q(s,a) + alpha * [r + gamma * max(Q(s',a')) - Q(s,a)]

  alpha  = learning rate    (how fast to update -- typically 0.1)
  gamma  = discount factor  (how much to value future rewards -- 0.9)
  r      = immediate reward received
  s'     = next state after taking action
  max Q(s',a') = best Q-value achievable from the next state
  TD error = r + gamma * max(Q(s',a')) - Q(s,a) -- how wrong we were

  Each update nudges Q(s,a) toward the true value.
  Over many episodes: Q-values converge to optimal.

  Watkins (1989/1992) -- the Q-learning paper."
    Wait-ForEnter

    Write-TeachSection "Exploration vs Exploitation"
    Write-TeachText "Epsilon-greedy strategy:

  With probability epsilon:     choose RANDOM action (explore)
  With probability 1-epsilon:   choose BEST known action (exploit)

  Epsilon starts at 1.0 -- pure exploration (try everything)
  Epsilon decays each episode -- gradually trust what was learned
  Epsilon reaches 0.01 -- mostly exploitation

  Why explore at all?
  If the agent always does what it already knows is best,
  it never discovers better strategies it has not tried yet."
    Wait-ForEnter

    Write-TeachSection "Try It Now"
    Write-TeachText "Run the Castle Learning example:" -Color "Cyan"
    Write-TeachCode 'cd "C:\Users\henni\OneDrive\WindowsPowerShell\examples\02-Castle-Learning"
. .\Run-Example-02.ps1

# Watch:
# Q-Table entries grow from 0 to 400+
# Epsilon decays from 1.0 toward 0.01
# Exploit% rises from 0% toward 20%+
# After training, inspect what was learned:
#   $agent.GetQValues("Gothic|Fortress")'
    Wait-ForEnter

    Write-TeachSection "When Q-Learning Fails"
    Write-TeachText "Q-learning works when the state space is SMALL and DISCRETE.

  8 castle types = 64 possible states maximum.
  Fine for a Q-table.

  But what if you had 1,000 castle types?
  64,000,000 possible states -- the table becomes huge.
  Or what if states are continuous numbers (like CartPole sensor readings)?
  Infinite states -- no table can store them all.

  Solution: replace the Q-table with a neural network.
  That is what DQN does."
    Wait-ForEnter "Topic 3 complete. Press Enter for Topic 4: DQN..."
}


# ============================================================================
# TOPIC 4 -- DQN
# ============================================================================

function Teach-DQN {
    Write-TeachProgress -Current 4 -Total 6 -TopicName "Deep Q-Networks"
    Write-TeachHeader "TOPIC 4: DEEP Q-NETWORKS (DQN)"

    Write-TeachSection "The Key Idea"
    Write-TeachText "DQN replaces the Q-table with a neural network.

  Q-learning:  Q(state, action) stored in a hashtable
  DQN:         Q(state, action) approximated by a neural network

  The network takes a state as input.
  It outputs Q-values for ALL actions simultaneously.
  The agent picks the action with the highest Q-value.

  Benefit: generalises to states never seen before.
  The network interpolates between similar states.
  A Q-table cannot -- it only knows states it has visited."
    Wait-ForEnter

    Write-TeachSection "Problem 1: Correlated Data"
    Write-TeachText "In standard training, consecutive samples are highly correlated:

  Step 1: CartPole at angle 2.1 degrees, falls left
  Step 2: CartPole at angle 2.2 degrees, falls left
  Step 3: CartPole at angle 2.3 degrees, falls left

  Training on correlated data causes the network to overfit
  to one situation and forget how to handle others.

  SOLUTION: Experience Replay (Lin, 1992)
  Store transitions (s, a, r, s') in a circular buffer.
  Sample RANDOM mini-batches for each training step.
  Random sampling breaks the correlations.
  VBAF default: buffer size 10,000, batch size 32."
    Wait-ForEnter

    Write-TeachSection "Problem 2: Moving Target"
    Write-TeachText "During training, the Bellman update is:

  Q(s,a) <- r + gamma * max Q(s',a')

  But Q(s',a') is computed by the SAME network being updated.
  Every weight update changes the target.
  It is like trying to hit a moving bullseye.
  Training becomes unstable and diverges.

  SOLUTION: Target Network
  Keep a COPY of the network frozen.
  Use the copy to compute Q(s',a') -- the target.
  Update the copy every N episodes from the main network.
  Stable target -> stable training.
  VBAF default: sync every 10 episodes."
    Wait-ForEnter

    Write-TeachSection "VBAF DQN Architecture"
    Write-TeachText "Every enterprise pillar uses the same architecture:

  Input:   4 state signals (normalised 0.0 to 1.0)
  Hidden:  24 neurons (sigmoid activation)
  Hidden:  24 neurons (sigmoid activation)
  Output:  4 Q-values (one per action)

  [4] -> [24] -> [24] -> [4]

  Why 24 neurons? Enough capacity to learn the pattern.
  Why sigmoid? Numerically stable in PowerShell 5.1.
  Why 4 states and 4 actions? Validated across all 14 pillars."
    Wait-ForEnter

    Write-TeachSection "Try It Now"
    Write-TeachText "Train a DQN agent on CartPole:" -Color "Cyan"
    Write-TeachCode '# Quick training
$agent = (Invoke-DQNTraining -Episodes 50 -PrintEvery 5 -FastMode)[-1]
$agent.PrintStats()

# Watch:
# Epsilon decays from 1.0 toward 0.05
# Average reward increases over episodes
# Target network syncs every 10 episodes

# Run Example 05 to see DQN training live in three panels:
cd "C:\Users\henni\OneDrive\WindowsPowerShell\examples\05-Validation-Dashboard"
. .\Run-Example-05.ps1'
    Wait-ForEnter

    Write-TeachSection "DQN vs Q-Learning"
    Write-TeachText "When to use Q-learning:
  State space is small and discrete (< 10,000 states)
  You want full transparency -- read the Q-table
  Example: castle sequences, grid worlds, simple games

When to use DQN:
  State space is large or continuous
  You need generalisation to unseen states
  Example: CartPole, enterprise automation, Atari games

VBAF uses Q-learning for Castle Learning (small, transparent)
and DQN for all 14 enterprise pillars (4 continuous signals)."
    Wait-ForEnter "Topic 4 complete. Press Enter for Topic 5: Multi-Agent RL..."
}


# ============================================================================
# TOPIC 5 -- MULTI-AGENT RL
# ============================================================================

function Teach-MultiAgent {
    Write-TeachProgress -Current 5 -Total 6 -TopicName "Multi-Agent Reinforcement Learning"
    Write-TeachHeader "TOPIC 5: MULTI-AGENT REINFORCEMENT LEARNING"

    Write-TeachSection "The Challenge"
    Write-TeachText "In single-agent RL:
  One agent, one environment.
  The environment is STATIONARY -- same action in same state
  always produces the same expected reward.
  Q-values converge because the target is stable.

In multi-agent RL:
  Multiple agents share one environment.
  Every agent's actions change the environment for ALL others.
  This is called NON-STATIONARITY -- the target keeps moving.
  One agent learning changes the optimal strategy for all others.
  Convergence is no longer guaranteed."
    Wait-ForEnter

    Write-TeachSection "Emergent Behaviour"
    Write-TeachText "Nobody programs the agents to cooperate or compete.
These behaviours EMERGE from reward optimisation:

  Price wars:
    Companies undercut each other on price.
    Everyone's profit drops -- a race to the bottom.
    Classic prisoner's dilemma.

  Tacit collusion:
    Companies independently learn to AVOID price wars.
    They converge on similar prices without communicating.
    Emerges because mutual price cuts hurt everyone.

  Innovation race:
    Companies discover R&D beats price competition.
    Emerges when quality advantage outweighs cost of investment.

  Market segmentation:
    Companies find niches to avoid direct competition.
    Emerges when head-to-head competition is too costly."
    Wait-ForEnter

    Write-TeachSection "Game Theory Connections"
    Write-TeachText "The same phenomena are studied in economics and game theory:

  Nash equilibrium:
    No agent can improve by changing strategy alone.
    Q-learning agents sometimes converge to Nash equilibrium.

  Prisoner's dilemma:
    Mutual cooperation is better for all, but each agent
    has an individual incentive to defect.
    Price wars are a prisoner's dilemma in action.

  Bertrand competition:
    Companies compete on price.
    Named after economist Joseph Bertrand (1883).
    VBAF market simulation uses Bertrand price competition.

  Herfindahl-Hirschman Index:
    H = sum of (market_share^2) for all companies.
    H > 0.25: one company dominates.
    H < 0.15: competitive market.
    Used by regulators worldwide. VBAF computes it automatically."
    Wait-ForEnter

    Write-TeachSection "Try It Now"
    Write-TeachText "Run the market simulation:" -Color "Cyan"
    Write-TeachCode 'cd "C:\Users\henni\OneDrive\WindowsPowerShell\examples\03-Market-Simulation"
. .\Run-Example-03.ps1

# Watch:
# Year 1-3:  agents exploring randomly, market share shifting unpredictably
# Year 5-7:  strategies emerging, price patterns becoming visible
# Year 10:   emergent behaviours clearly visible in final report

# Key questions to ask:
# Did a price war or tacit collusion emerge?
# Did the initial advantage of MarketLeader persist?
# What does the Herfindahl Index say about market concentration?'
    Wait-ForEnter "Topic 5 complete. Press Enter for Topic 6: Enterprise Automation..."
}


# ============================================================================
# TOPIC 6 -- ENTERPRISE AUTOMATION
# ============================================================================

function Teach-Enterprise {
    Write-TeachProgress -Current 6 -Total 6 -TopicName "Enterprise Automation"
    Write-TeachHeader "TOPIC 6: ENTERPRISE AUTOMATION PILLARS"

    Write-TeachSection "The Architecture"
    Write-TeachText "VBAF has 14 enterprise automation pillars built on DQN:

  Phase 14: SelfHealing          -- detect and fix infrastructure issues
  Phase 15: Dashboard            -- intelligent monitoring priorities
  Phase 16: FederatedLearning    -- distributed learning coordination
  Phase 17: CloudBridge          -- cloud resource optimisation
  Phase 18: AnomalyDetector      -- detect unusual patterns
  Phase 19: CapacityPlanner      -- predict and plan resource needs
  Phase 20: IncidentResponder    -- automated incident response
  Phase 21: ComplianceReporter   -- compliance monitoring
  Phase 22: UserBehaviorAnalytics -- detect unusual user behaviour
  Phase 23: PatchIntelligence    -- smart patch prioritisation
  Phase 24: BackupOptimizer      -- optimise backup schedules
  Phase 25: EnergyOptimizer      -- reduce energy consumption
  Phase 26: MultiSiteCoordinator -- coordinate across locations
  Phase 27: AutoPilot            -- orchestrate all 13 pillars"
    Wait-ForEnter

    Write-TeachSection "The Standard Pattern"
    Write-TeachText "Every pillar follows the SAME design:

  4 state signals (0.0 to 1.0) -- what the agent observes
  4 actions (ordered by severity) -- what the agent can do
  Reward: +2 correct, -1 dist=1, -2 dist=2, -3 dist=3

  Example -- SecurityMonitor:
    State 1: failed login rate  (0=none, 1=high)
    State 2: anomaly score      (0=normal, 1=critical)
    State 3: network scan rate  (0=none, 1=scanning)
    State 4: privilege escalation attempts (0=none, 1=many)

    Action 0: Monitor   -- log only, no action needed
    Action 1: Alert     -- notify security team
    Action 2: Isolate   -- quarantine the affected system
    Action 3: Lockdown  -- emergency full lockdown"
    Wait-ForEnter

    Write-TeachSection "The Distribution Formula"
    Write-TeachText "Every pillar uses the 15/40/30/15 severity distribution:

  15% of steps: severity 0 (normal)
  40% of steps: severity 1 (elevated -- most common)
  30% of steps: severity 2 (high)
  15% of steps: severity 3 (critical)

  Why this specific distribution?

  A random agent scores:
    0.15*2 + 0.40*(-1) + 0.30*(-2) + 0.15*(-3) = -1.0 per step

  A perfect agent scores: +2.0 per step

  The gap guarantees measurable improvement every training run.
  The distribution was validated across all 14 VBAF pillars."
    Wait-ForEnter

    Write-TeachSection "SimMode vs Real Data"
    Write-TeachText "SimMode (default):
  _Sample() generates synthetic data using Get-Random.
  Safe for learning -- no real systems involved.
  Guaranteed improvement because distribution is controlled.

Real Windows data:
  Replace _Sample() ranges with actual Windows sources:
    Get-WmiObject Win32_Processor  -- CPU load
    Get-Counter                    -- performance counters
    Get-WinEvent                   -- event log
    Get-Service                    -- service status

  Same DQN agent, same training loop.
  Only _Sample() changes.
  No other code modifications needed."
    Wait-ForEnter

    Write-TeachSection "Try It Now"
    Write-TeachText "Run a pillar and build your own:" -Color "Cyan"
    Write-TeachCode '# Run the AutoPilot -- all 13 pillars simultaneously
$r = Invoke-VBAFAutoPilotTraining -Episodes 100 -PrintEvery 10 -SimMode

# Build your own pillar from the template:
cd "C:\Users\henni\OneDrive\WindowsPowerShell\examples\06-Custom-Agent"
. .\Run-Example-06.ps1

# The NetworkTrafficManager in that example is your starting template.
# Copy it, rename it, change the 4 state signals and 4 actions,
# and you have a new enterprise pillar for your own domain.'
    Wait-ForEnter

    Write-TeachSection "What Comes Next"
    Write-TeachText "You have covered the full VBAF learning path:

  Topic 1: Machine learning paradigms
  Topic 2: Neural networks and backpropagation
  Topic 3: Q-learning and the Q-table
  Topic 4: DQN -- neural networks + RL
  Topic 5: Multi-agent RL and emergent behaviour
  Topic 6: Enterprise automation pillars

  Next steps:
  - docs\Theory.md          -- deeper theory with full references
  - docs\API-Reference.md   -- every function and class
  - tutorials\              -- 13 hands-on tutorials
  - examples\               -- 6 runnable examples
  - Build your own pillar and submit a GitHub PR!"
    Wait-ForEnter "Course complete! You are now a VBAF practitioner."
}


# ============================================================================
# MAIN FUNCTION
# ============================================================================

function Start-VBAFTeach {
    <#
    .SYNOPSIS
        Interactive VBAF console teacher.
    .DESCRIPTION
        Guides a student through VBAF concepts one step at a time.
        Press Enter to advance through each concept.
    .PARAMETER Topic
        Optional. Run one topic only:
          "MachineLearning" | "NeuralNetwork" | "QLearning" |
          "DQN" | "MultiAgent" | "Enterprise"
        Default: run all 6 topics in order.
    .EXAMPLE
        Start-VBAFTeach
        Start-VBAFTeach -Topic "DQN"
        Start-VBAFTeach -Topic "Enterprise"
    #>
    param(
        [string]$Topic = "All"
    )

    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor Cyan
    Write-Host "  VBAF CONSOLE TEACHER" -ForegroundColor Cyan
    Write-Host "  Visual AI and Reinforcement Learning Framework" -ForegroundColor Cyan
    Write-Host ("=" * 60) -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Press Enter to advance through each concept." -ForegroundColor Gray
    Write-Host "  Press Ctrl+C at any time to exit." -ForegroundColor Gray
    Write-Host ""

    switch ($Topic) {
        "MachineLearning" { Teach-MachineLearning }
        "NeuralNetwork"   { Teach-NeuralNetwork   }
        "QLearning"       { Teach-QLearning        }
        "DQN"             { Teach-DQN              }
        "MultiAgent"      { Teach-MultiAgent       }
        "Enterprise"      { Teach-Enterprise       }
        default {
            Teach-MachineLearning
            Teach-NeuralNetwork
            Teach-QLearning
            Teach-DQN
            Teach-MultiAgent
            Teach-Enterprise
        }
    }

    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor Cyan
    Write-Host "  VBAF teaching session complete." -ForegroundColor Cyan
    Write-Host "  See docs\ for deeper reading." -ForegroundColor Cyan
    Write-Host ("=" * 60) -ForegroundColor Cyan
    Write-Host ""
}