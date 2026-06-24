# VBAF -- Getting Started
## A Guided Trail from Zero to AI Developer

Welcome. You are about to learn how artificial intelligence actually works --
not by reading about it, but by running it, watching it, and breaking it.

VBAF implements neural networks, reinforcement learning and multi-agent
systems from scratch in PowerShell 5.1. Every algorithm is readable.
Every concept is explained in the code comments.

This guide takes you from installation to building your own AI agent.
Follow the camps in order. Do not skip ahead.

**Time required:** 2-4 hours for Camps 0-3. Camps 4-5 are open-ended.

---

# CAMP 0 -- BASECAMP
## Get VBAF installed and your first output on screen
### Goal: see "VBAF Framework ready!" on your screen

---

## Step 1 of 5 -- Check your PowerShell version

Open PowerShell (not ISE, not VS Code -- just plain PowerShell for now).

```powershell
$PSVersionTable.PSVersion
```

What you will see:
```
Major  Minor  Build  Revision
-----  -----  -----  --------
5      1      ...    ...
```

What it means:
VBAF requires PowerShell 5.1. This version ships with every modern
Windows PC. If you see 5.1 -- you are ready. If you see 7.x -- switch
to Windows PowerShell (search "Windows PowerShell" in the Start menu).

If something goes wrong:
On Windows 10 or 11, PowerShell 5.1 is always present.
Search "Windows PowerShell" in the Start menu -- not "PowerShell".

---

## Step 2 of 5 -- Install VBAF from PSGallery

```powershell
Install-Module VBAF -Scope CurrentUser
```

What you will see:
```
Untrusted repository
Are you sure you want to install the modules from 'PSGallery'?
[Y] Yes  [N] No
```

Type Y and press Enter.

What it means:
PSGallery is the official PowerShell module repository -- the same place
Microsoft publishes its own modules. VBAF is downloaded and installed
in your user profile. Nothing is changed system-wide.

If something goes wrong:
If you get a proxy or network error, try:
  Install-Module VBAF -Scope CurrentUser -Force

---

## Step 3 of 5 -- Navigate to the VBAF folder

```powershell
cd "$env:USERPROFILE\OneDrive\WindowsPowerShell"
```

What you will see:
Your prompt changes to show the new folder.

What it means:
VBAF lives in your OneDrive\WindowsPowerShell folder.
All examples and files are here.

If something goes wrong:
If OneDrive is not set up, try:
  cd "$env:USERPROFILE\Documents\WindowsPowerShell"
Or wherever you cloned the VBAF repository.

---

## Step 4 of 5 -- Load the VBAF framework

```powershell
. .\VBAF.LoadAll.ps1
```

What you will see:
```
  Loading VBAF Framework...

  [Phase 1] Core neural network...
  [Phase 2] Reinforcement learning...
  [Phase 3] Business and multi-agent...
  ...
  VBAF Framework ready!

  LEARNING PATH (run in order):
    1. & .\VBAF.Core.Example-XOR.ps1
    2. & .\VBAF.RL.Example-CastleLearning.ps1
    ...
```

What it means:
All VBAF classes and functions are now loaded into your session.
NeuralNetwork, QLearningAgent, DQNAgent, PPOAgent, A3CAgent --
all available. You need to run this once per PowerShell session.

If something goes wrong:
Make sure you are in the right folder (Step 3) before running this.
The dot-space-dot at the start is important: `. .\VBAF.LoadAll.ps1`

---

## Step 5 of 5 -- Confirm everything loaded

```powershell
[NeuralNetwork]::new(@(2,3,1), 0.1)
```

What you will see:
```
Layers       : {Layer, Layer}
LearningRate : 0.1
Architecture : {2, 3, 1}
```

What it means:
You just created a neural network with 2 inputs, 3 hidden neurons
and 1 output. It exists in memory. It has random weights.
It knows nothing yet. That is about to change.

---

# CAMP 0 COMPLETE
**You have:** PowerShell 5.1, VBAF installed, framework loaded.
**You can:** create neural networks and RL agents from scratch.
**Next:** watch one learn.

---

---

# CAMP 1 -- FIRST FIRE
## Watch a neural network learn something for the first time
### Goal: see "SUCCESS! Network learned XOR!"

---

## Step 6 of 8 -- Understand the problem first

XOR is the simplest problem a single neuron CANNOT solve.

```
0 XOR 0 = 0   (both same   -> 0)
0 XOR 1 = 1   (different   -> 1)
1 XOR 0 = 1   (different   -> 1)
1 XOR 1 = 0   (both same   -> 0)
```

Draw these four points on paper:
  (0,0) -> label 0
  (0,1) -> label 1
  (1,0) -> label 1
  (1,1) -> label 0

Try to draw ONE straight line that separates the 0-labelled points
from the 1-labelled points. You cannot. That is the problem.

In 1969, Minsky and Papert proved mathematically that a single neuron
cannot solve XOR. This killed AI research funding for a decade.

The solution: add a hidden layer. Two lines can separate the points
even when one cannot. This is the Universal Approximation Theorem.

---

## Step 7 of 8 -- Run the XOR example

```powershell
cd examples\01-XOR-Network
. .\Run-Example-01.ps1
```

What you will see:
```
Training Neural Network...
Architecture : 2 -> 3 -> 1

Epoch     1 / 5000 (  0.0%) -- Error: 0.269
Epoch   500 / 5000 ( 10.0%) -- Error: 0.268
Epoch  1500 / 5000 ( 30.0%) -- Error: 0.082
Epoch  2000 / 5000 ( 40.0%) -- Error: 0.006
Epoch  5000 / 5000 (100.0%) -- Error: 0.000697

Accuracy   : 100.00%
Correct    : 4 / 4

SUCCESS! Network learned XOR!
```

What it means:
The network started with random weights and knew nothing.
After 5000 passes through 4 training examples, it learned XOR.
Error dropped from 0.269 to 0.0007 -- near perfect.

Watch the error curve:
  Epoch 1-1000:  barely moves (stuck in a plateau)
  Epoch 1500:    suddenly drops (escaped the plateau)
  Epoch 2000+:   smooth descent to near zero

This plateau-then-breakthrough is normal. The network was slowly
repositioning its weights until they crossed a threshold.

If something goes wrong:
If accuracy is below 75% -- run it again. Different random starting
weights sometimes get stuck. This is normal and expected.

---

## Step 8 of 8 -- Look inside what just happened

```powershell
# Create a network and inspect it
$nn = [NeuralNetwork]::new(@(2,3,1), 0.5)

# See the random starting weights of the first hidden neuron
$nn.Layers[0].Neurons[0].Weights
$nn.Layers[0].Neurons[0].Bias
```

What you will see:
Three random numbers between -0.5 and 0.5.
These are the starting weights -- completely random.

```powershell
# Train it
$data = @(
    @{ Input = @(0.0,0.0); Expected = @(0.0) }
    @{ Input = @(0.0,1.0); Expected = @(1.0) }
    @{ Input = @(1.0,0.0); Expected = @(1.0) }
    @{ Input = @(1.0,1.0); Expected = @(0.0) }
)
$result = $nn.Train($data, 5000)

# See the weights AFTER training
$nn.Layers[0].Neurons[0].Weights
$nn.Layers[0].Neurons[0].Bias
```

What it means:
The weights changed. Backpropagation moved them from random values
to values that encode the XOR pattern. This is learning.

---

## What to try before moving on

1. Run the XOR example 3 times -- does it always converge?
2. Change the architecture to [2, 2, 1] -- can 2 hidden neurons solve it?
3. Change learning rate to 0.1 -- slower but more stable
4. Change epochs to 500 -- does it converge fast enough?
5. Open VBAF.Core.AllClasses.ps1 and find the UpdateWeights method.
   Read the formula. Match it to what you read in the comments.

---

# CAMP 1 COMPLETE
**You have seen:** a neural network learn from random weights.
**You understand:** XOR, hidden layers, backpropagation, error curves.
**Next:** make an agent learn WITHOUT being told the correct answer.

---

---

# CAMP 2 -- LEARNING TO HUNT
## An agent discovers strategy through trial and error
### Goal: watch reward increase as the agent learns

---

## Step 9 of 10 -- Understand the difference

In Camp 1, we gave the network the CORRECT ANSWER for every input.
  Input: [0,1] -> Correct answer: 1
This is called SUPERVISED learning.

In Camp 2, we give the agent a REWARD for good outcomes.
  Action: choose castle type -> Reward: +2 if varied, -1 if repeated
The agent must figure out what "good" means by itself.
This is called REINFORCEMENT learning.

The difference:
  Supervised: "here is the right answer"
  Reinforcement: "here is how good that was"

---

## Step 10 of 10 -- Run the castle learning example

```powershell
cd ..\02-Castle-Learning
. .\Run-Example-02.ps1
```

What you will see:
```
Episode   1 | Reward:  12.45 | Epsilon: 1.000 | Q-Table:   0 entries
Episode  10 | Reward:  15.32 | Epsilon: 0.951 | Q-Table:  14 entries
Episode  50 | Reward:  18.67 | Epsilon: 0.779 | Q-Table:  38 entries
Episode 100 | Reward:  21.43 | Epsilon: 0.607 | Q-Table:  52 entries
```

What to watch:
  Epsilon:  starts at 1.0 (100% random), decays toward 0.01
  Q-Table:  grows as the agent visits new states
  Reward:   should trend upward as the agent learns

What it means:
  Episode 1:   agent picks randomly -- no knowledge
  Episode 10:  agent has seen some states -- Q-table forming
  Episode 100: agent exploiting learned knowledge -- reward rising

---

## Step 11 -- Train a DQN on CartPole

Now a neural network approximates Q-values instead of a table.
This works for problems too large for a table.

```powershell
cd "$env:USERPROFILE\OneDrive\WindowsPowerShell"
. .\VBAF.LoadAll.ps1

$agent = (Invoke-DQNTraining -Episodes 100 -PrintEvery 10)[-1]
```

What you will see:
```
Ep    10  Reward:    12  Best:    18  e: 0.951  Loss: 0.04521
Ep    20  Reward:    23  Best:    31  e: 0.905  Loss: 0.03891
Ep    50  Reward:    67  Best:    89  e: 0.779  Loss: 0.02341
Ep   100  Reward:   134  Best:   178  e: 0.607  Loss: 0.01123
```

What to watch:
  Reward: random agent gets 10-20. Trained agent gets 100-200.
  Epsilon: decays from 1.0 -- less exploration over time.
  Loss: should trend downward -- Q-values becoming accurate.

```powershell
# See the full stats
$agent.PrintStats()

# Get Q-values for a specific state
$state = @(0.1, 0.0, 0.05, 0.0)
$agent.GetQValues($state)
```

What it means:
GetQValues shows what the neural network thinks each action is worth.
Higher value = agent thinks this action leads to better outcomes.
After training, the values should make intuitive sense:
if the pole is tilting right, pushing right should have low value.

---

## What to try before moving on

1. Run DQN with FastMode and compare speed:
   $agent = (Invoke-DQNTraining -Episodes 50 -FastMode)[-1]

2. Run it twice -- does it always converge to the same reward?

3. Look at the Q-values before and after training:
   Create a new agent, get Q-values, train, get Q-values again.
   See how they changed.

4. Open VBAF.RL.DQN.ps1 and find the Replay() method.
   Read the Bellman equation comment. Trace through one update.

---

# CAMP 2 COMPLETE
**You have seen:** Q-learning and DQN in action.
**You understand:** rewards, Q-values, epsilon-greedy, experience replay.
**Next:** compare three different algorithms head to head.

---

---

# CAMP 3 -- THE ARENA
## Three algorithms compete -- you judge the winner
### Goal: benchmark DQN vs PPO vs A3C and explain the difference

---

## Step 12 of 10 -- Understand the three algorithms

**Q-Learning / DQN:**
  Learns: Q(state, action) = expected future reward
  Decides: take the action with the highest Q-value
  Memory: experience replay buffer (random batches)
  Key innovation: target network for stable training

**PPO (Proximal Policy Optimization):**
  Learns: pi(action|state) = probability of each action
  Decides: sample from the probability distribution
  Memory: rollout buffer (recent experiences, then discard)
  Key innovation: clipped update -- no catastrophic policy changes

**A3C (Advantage Actor-Critic):**
  Learns: policy AND value function in ONE shared network
  Decides: sample from policy head
  Memory: n-step rollout per worker (no buffer)
  Key innovation: parallel workers, shared global network

---

## Step 13 -- Train all three

```powershell
Write-Host "Training DQN..." -ForegroundColor Cyan
$dqn = (Invoke-DQNTraining -Episodes 100 -FastMode -Quiet)[-1]

Write-Host "Training PPO..." -ForegroundColor Cyan
$ppo = (Invoke-PPOTraining -Episodes 100 -FastMode -Quiet)[-1]

Write-Host "Training A3C..." -ForegroundColor Cyan
$a3c = (Invoke-A3CTraining -Episodes 100 -FastMode -Quiet)[-1]

Write-Host "All three trained!" -ForegroundColor Green
```

This takes 2-5 minutes. Watch the output -- each algorithm
prints different statistics because they work differently.

---

## Step 14 -- Benchmark them head to head

```powershell
$env = New-VBAFEnvironment -Name "CartPole" -MaxSteps 200

Invoke-VBAFBenchmark -Agent $null -Environment $env -Episodes 20 -Label "Random baseline"
Invoke-VBAFBenchmark -Agent $dqn  -Environment $env -Episodes 20 -Label "DQN"
Invoke-VBAFBenchmark -Agent $ppo  -Environment $env -Episodes 20 -Label "PPO"
Invoke-VBAFBenchmark -Agent $a3c  -Environment $env -Episodes 20 -Label "A3C"
```

What you will see:
```
  Random baseline
  Avg Reward :  14.3
  Max Reward :  28.0

  DQN
  Avg Reward : 143.7
  Max Reward : 200.0

  PPO
  Avg Reward : 167.2
  Max Reward : 200.0

  A3C
  Avg Reward : 112.4
  Max Reward : 200.0
```

What it means:
Random agent: 14 reward -- barely balances
Trained agents: 100-200 reward -- learned to balance

The winner varies each run because of random weight initialisation.
Run the benchmark 3 times. Which algorithm wins most often?

---

## Step 15 -- Watch four companies compete

```powershell
cd examples\03-Market-Simulation
. .\Run-Example-03.ps1
```

What you will see:
Four companies learning business strategy simultaneously.
After 10 simulated years, you see who won and WHY.

Watch for:
- Tacit collusion: companies avoid price wars without communicating
- Innovation races: R&D emerges as the dominant strategy
- Herfindahl index: measures market concentration

What it means:
Nobody programmed these behaviours.
They emerged from four Q-learning agents optimising their own rewards.
This is multi-agent reinforcement learning in action.

---

## What to try before moving on

1. Run the benchmark 3 times -- which algorithm wins most often?

2. Try GridWorld:
   $env = New-VBAFEnvironment -Name "GridWorld" -GridSize 5
   Invoke-VBAFBenchmark -Agent $dqn -Environment $env -Episodes 20 -Label "DQN on GridWorld"

3. Read the stats from each agent:
   $dqn.PrintStats()
   $ppo.PrintStats()
   $a3c.PrintStats()
   What is different? What does Entropy mean for PPO and A3C?

4. Open VBAF.RL.PPO.ps1 and find the ComputeGAE method.
   Read the comment about lambda. What happens when lambda = 1.0?

---

# CAMP 3 COMPLETE
**You have seen:** three RL algorithms, head-to-head benchmarking, multi-agent.
**You understand:** the difference between value-based, policy gradient, and actor-critic.
**Next:** build something yourself.

---

---

# CAMP 4 -- YOUR OWN FIRE
## Design your own environment and train your own agent
### Goal: an agent learns something YOU designed

---

## Step 16 -- Understand what an environment needs

Every VBAF environment needs three methods:

```powershell
Reset()         # start new episode, return initial state
Step($action)   # apply action, return @{NextState; Reward; Done}
GetState()      # return current state as double array
```

That is all. Any problem that fits this shape can be learned by
any VBAF agent -- DQN, PPO, A3C or Q-learning.

---

## Step 17 -- Study a simple example

```powershell
# RandomWalk is the simplest possible environment
$env = New-VBAFEnvironment -Name "RandomWalk"
$env.PrintInfo()

# Run one episode manually
$state = $env.Reset()
Write-Host "Start state: $state"

for ($step = 0; $step -lt 10; $step++) {
    $action = Get-Random -Minimum 0 -Maximum 2   # 0=left, 1=right
    $result = $env.Step($action)
    Write-Host "Action: $action  State: $($result.NextState)  Reward: $($result.Reward)  Done: $($result.Done)"
    if ($result.Done) { break }
}
```

What it means:
You are manually controlling the agent -- choosing random actions.
Watch how the state changes and reward is assigned.
A trained agent would learn to always move toward 0 (center).

---

## Step 18 -- Run the custom agent example

```powershell
cd examples\06-Custom-Agent
. .\Run-Example-06.ps1
```

This example shows how to build your own environment from scratch
and train a DQN agent on it. Read the code carefully.

---

## Step 19 -- Modify something

Pick ONE thing to change and observe the effect:

Option A -- Change the reward function in RandomWalk:
  Currently: +10 for reaching center, else -(distance * 0.1)
  Try: +1 for reaching center, else 0 (no distance penalty)
  Question: does the agent still learn? Is it faster or slower?

Option B -- Change DQN hyperparameters:
  Currently: Gamma=0.95, LearningRate=0.001, BatchSize=32
  Try: Gamma=0.50 (agent ignores future rewards)
  Question: does short-sighted learning work for CartPole?

Option C -- Change the architecture:
  Currently: [4, 64, 64, 2]
  Try: [4, 8, 2] (much smaller network)
  Question: can a tiny network still solve CartPole?

---

## What to try before moving on

1. Run your modified version 3 times. Is the result consistent?
2. Write down your hypothesis BEFORE running -- then check it.
3. Open VBAF.RL.Environment.ps1 and read the GridWorld class.
   Could you adapt it for a different grid-based problem?

---

# CAMP 4 COMPLETE
**You have done:** run manual episodes, modified a reward function, changed hyperparameters.
**You understand:** the environment interface, reward shaping, hyperparameter sensitivity.
**Next:** see where all this leads at enterprise scale.

---

---

# CAMP 5 -- THE SUMMIT
## From foundation to enterprise -- trace the learning ladder
### Goal: understand how Phase 1-9 becomes Phase 10-27

---

## Step 20 -- The learning ladder

VBAF has two layers:

**Foundation (Phases 1-9):**
Neural networks, Q-learning, DQN, PPO, A3C, multi-agent.
You have learned all of this in Camps 1-4.

**Enterprise (Phases 10-27):**
14 production-grade automation agents built on the SAME foundation.
These are not teaching examples -- they solve real IT problems.

The ladder:
```
Phase 1-9:  learn HOW agents learn
Phase 10-27: see WHAT agents can do when they learn well
```

---

## Step 21 -- Run one enterprise agent

```powershell
cd "$env:USERPROFILE\OneDrive\WindowsPowerShell"
. .\VBAF.LoadAll.ps1

# Self-Healing Infrastructure -- Phase 14
$result = Invoke-VBAFSelfHealingTraining -Episodes 50 -SimMode
```

What you will see:
A DQN agent learning to detect and fix system problems.
State: CPU load, memory, disk, error rate, response time.
Actions: Observe, Adjust, Restart, Rebuild.

What it means:
This is the same DQN you trained on CartPole in Camp 2.
Same algorithm. Same Bellman equation. Same experience replay.
Different environment. Different reward function.
The learning mechanism is identical.

---

## Step 22 -- Trace it back to the foundation

```powershell
# Open the enterprise file and find where NeuralNetwork is used
Select-String "NeuralNetwork" ".\VBAF.Enterprise.SelfHealing.ps1"

# Compare with DQN
Select-String "NeuralNetwork" ".\VBAF.RL.DQN.ps1"
```

What you will see:
Both files reference NeuralNetwork.
The enterprise agent uses the SAME class you built in Camp 1.

Trace the chain:
  VBAF.Core.AllClasses.ps1    -- defines NeuralNetwork
  VBAF.RL.DQN.ps1             -- uses NeuralNetwork for Q-learning
  VBAF.Enterprise.SelfHealing.ps1 -- uses DQN for IT automation

Three files. One chain. Same foundation.

---

## Step 23 -- Run the AutoPilot (the crown jewel)

```powershell
$result = Invoke-VBAFAutoPilotTraining -Episodes 50 -SimMode
```

What you will see:
AutoPilot orchestrates ALL 13 enterprise pillars simultaneously.
It is an agent that coordinates other agents.
Meta-learning -- an agent that decides which agents to activate.

This is Phase 27 -- the furthest point VBAF reaches.
But it is built entirely from the same concepts you learned in Camp 1.

---

## Step 24 -- Read one enterprise file properly

Choose any enterprise file that interests you:
- VBAF.Enterprise.AnomalyDetector.ps1 -- spots unusual patterns
- VBAF.Enterprise.EnergyOptimizer.ps1 -- reduces power consumption
- VBAF.Enterprise.PatchIntelligence.ps1 -- risk-aware patch scheduling

Open it and find:
1. What is the STATE? (what does the agent observe?)
2. What are the ACTIONS? (what can the agent do?)
3. What is the REWARD? (what is it optimising for?)

Answer those three questions for any environment and you understand
what the agent will learn to do.

---

# CAMP 5 COMPLETE
**You have seen:** the full learning ladder from XOR to enterprise AutoPilot.
**You understand:** how foundation concepts scale to production systems.
**You can:** read any VBAF file and understand what the agent is learning.

---

---

# THE VIEW FROM THE TOP

You started at Camp 0 with:
```powershell
Install-Module VBAF
```

You are now at Camp 5 with:
- Neural networks trained from scratch
- Three RL algorithms benchmarked
- Multi-agent competition observed
- Your own hyperparameters tested
- Enterprise agents running

**What you can do now:**

```powershell
# Train any algorithm
$agent = (Invoke-DQNTraining -Episodes 200)[-1]
$agent = (Invoke-PPOTraining -Episodes 200)[-1]
$agent = (Invoke-A3CTraining -Episodes 200)[-1]

# On any environment
$env = New-VBAFEnvironment -Name "CartPole"
$env = New-VBAFEnvironment -Name "GridWorld" -GridSize 8
$env = New-VBAFEnvironment -Name "RandomWalk"

# Benchmark anything
Invoke-VBAFBenchmark -Agent $agent -Environment $env -Episodes 50 -Label "My Agent"

# Run any enterprise pillar
Invoke-VBAFSelfHealingTraining -Episodes 100 -SimMode
Invoke-VBAFAutoPilotTraining   -Episodes 100 -SimMode
```

**Where to go from here:**

- Read the theory: docs/Theory.md
- Build your own environment: examples/06-Custom-Agent/
- Study the papers referenced in each file
- Contribute an example or a new environment

---

# QUICK REFERENCE

## The 5 most important commands

```powershell
# 1. Load everything (run once per session)
. .\VBAF.LoadAll.ps1

# 2. Run the learning path in order
& .\examples\01-XOR-Network\Run-Example-01.ps1
& .\examples\02-Castle-Learning\Run-Example-02.ps1
& .\examples\03-Market-Simulation\Run-Example-03.ps1

# 3. Train an agent
$agent = (Invoke-DQNTraining -Episodes 100 -PrintEvery 10)[-1]

# 4. Benchmark it
$env = New-VBAFEnvironment -Name "CartPole"
Invoke-VBAFBenchmark -Agent $agent -Environment $env -Episodes 20 -Label "My DQN"

# 5. See what it learned
$agent.PrintStats()
$agent.GetQValues(@(0.1, 0.0, 0.05, 0.0))
```

## If something breaks

```
"Unable to find type"     -> run . .\VBAF.LoadAll.ps1 first
"Cannot find path"        -> check you are in the right folder
"accuracy below 75%"      -> run XOR again (random init sometimes fails)
"reward not increasing"   -> train for more episodes
```

---

*VBAF -- Visual AI & Reinforcement Learning Framework*
*github.com/JupyterPS/VBAF*
*"The best way to understand AI is to build it yourself -- line by line."*