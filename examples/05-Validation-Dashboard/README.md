# Example 05: Validation Dashboard

A three-panel live dashboard that proves the VBAF foundation works.
Watch neural network training, Q-learning grid navigation and experience
replay filling simultaneously in real time.

## Important -- Run From PowerShell Console, Not ISE

This dashboard opens a WinForms window.
Run from: Start -> Windows PowerShell (the blue console icon)
Do NOT run from: PowerShell ISE

## The Three Panels

Panel 1 -- Neural Network (XOR Training):
  A 2-4-1 network trains on the XOR problem.
  Watch the error curve drop from 1.0 toward 0.0 as backpropagation
  finds the right weights. Green line = learning curve.

Panel 2 -- Q-Learning (Grid World):
  An agent navigates a 10x10 grid from top-left (0,0) to bottom-right (9,9).
  Yellow square = agent position. Green square = goal.
  Each step costs -0.1. Reaching the goal earns +10.
  Watch the agent find shorter paths as episodes accumulate.

Panel 3 -- Experience Replay Buffer:
  Shows the replay buffer filling up to capacity (100 experiences).
  Magenta bar = current fill level.
  Magenta line = fill history over time.
  A full buffer means the agent has enough experience to learn from.

## What To Watch

Neural network panel:
  Error starts near 1.0 and drops exponentially.
  Flattens near 0.0 when XOR is solved.
  Click Start NN Training to begin -- it does not start automatically.

Q-learning panel:
  Early episodes: agent wanders randomly (high step count, low reward).
  Later episodes: agent finds direct paths (fewer steps, better reward).
  Episode count in status bar confirms learning is running.

Experience replay panel:
  Buffer fills quickly (100 capacity).
  Once full, old experiences are replaced by new ones.
  This is the circular buffer pattern used in DQN (Mnih 2013).

## Controls

  Start NN Training -- begins neural network backpropagation
  Pause NN          -- freezes NN training (Q-learning continues)
  Stop All          -- halts everything

Q-learning and experience replay run automatically from startup.
Neural network requires clicking Start.

## Run It

```powershell
cd "C:\Users\henni\OneDrive\WindowsPowerShell\examples\05-Validation-Dashboard"
. .\Run-Example-05.ps1
```

## Expected Console Output
VBAF Validation Dashboard

Initializing Neural Network for XOR...

Neural Network created (2-4-1 architecture)

Initializing Q-Learning Grid World...

Q-Learning agent created (10x10 grid)

Dashboard ready!

## What To Try Next

1. Watch error curve flatten -- that is XOR solved
2. Count how many episodes before Q-agent finds consistent short paths
3. Compare replay buffer fill rate with the step count in panel 2
4. Move on to examples\06-Custom-Agent\ -- build your own RL environment

## Key Concepts

- Simultaneous visualisation of three learning algorithms
- Experience replay buffer (Lin 1992) -- why DQN needs a memory
- Grid world -- the simplest RL environment (discrete state and action space)
- Circular buffer -- old experiences replaced when capacity is reached

## Files

- `Run-Example-05.ps1` -- run this to start the dashboard
- `VBAF.Core.Test-ValidationDashboard.ps1` -- full three-panel dashboard
- Source: `..\..\VBAF.Core.AllClasses.ps1` -- NeuralNetwork class
- Source: `..\..\VBAF.RL.QLearningAgent.ps1` -- Q-learning agent
- Source: `..\..\VBAF.RL.ExperienceReplay.ps1` -- replay buffer
