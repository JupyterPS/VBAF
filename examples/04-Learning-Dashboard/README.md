# Example 04: Learning Dashboard

Real-time visualisation of agent training progress.
Watch error decrease, rewards increase and epsilon decay
as 500 training epochs run automatically.

## Important -- Run From PowerShell Console, Not ISE

This dashboard opens a WinForms window.
ISE locks up when a WinForms window opens -- this is a known ISE limitation.

Always run this example from a standalone PowerShell console:
  Start -> Windows PowerShell (not ISE)

## What The Dashboard Shows

The console output shows training metrics every 50 epochs:
  Error   -- neural network loss, starts ~0.5, drops toward 0.001
  Reward  -- RL agent score, starts ~5, climbs toward 15+
  Epsilon -- exploration rate, starts 1.0, decays toward 0.01

After the console output, a WinForms window opens with live charts.

## What To Watch

Error curve:
  Starts high (random weights), drops exponentially.
  Flattening early = learning rate too low or network too small.
  Oscillating = learning rate too high.

Reward curve:
  Starts low, climbs as agent learns better actions.
  Plateaus = agent has converged (or is stuck in local optimum).

Epsilon curve:
  Starts at 1.0 (pure random), decays each episode.
  Reaches 0.01 = agent mostly exploiting learned policy.
  This is the exploration-exploitation tradeoff made visible.

## Reading Learning Curves

A healthy training run looks like this:
  Epoch  50: Error=0.33  Reward= 5.1  Epsilon=0.778
  Epoch 100: Error=0.21  Reward= 7.2  Epsilon=0.606
  Epoch 200: Error=0.10  Reward= 9.3  Epsilon=0.367
  Epoch 300: Error=0.04  Reward=11.9  Epsilon=0.222
  Epoch 500: Error=0.01  Reward=14.5  Epsilon=0.082

Error goes down. Reward goes up. Epsilon decays. All three together
confirm that learning is working correctly.

If error goes down but reward does not go up -- the network is
learning the wrong thing (reward function may need redesign).

If epsilon reaches 0.01 but reward is still low -- the agent
converged on a bad policy. Try more episodes or different hyperparameters.

## Run It

```powershell
cd "C:\Users\henni\OneDrive\WindowsPowerShell\examples\04-Learning-Dashboard"
. .\Run-Example-04.ps1
```

## Expected Output
+----------------------------------------------+

|     LEARNING DASHBOARD - DEMO               |

+----------------------------------------------+
Epoch  50: Error=0.3319, Reward= 5.09, Epsilon=0.778

Epoch 100: Error=0.2116, Reward= 7.15, Epsilon=0.606

Epoch 150: Error=0.1549, Reward= 9.03, Epsilon=0.471

Epoch 200: Error=0.0998, Reward= 9.34, Epsilon=0.367

Epoch 250: Error=0.0751, Reward=10.94, Epsilon=0.286

Epoch 300: Error=0.0394, Reward=11.88, Epsilon=0.222

Epoch 350: Error=0.0527, Reward=13.76, Epsilon=0.173

Epoch 400: Error=0.0547, Reward=13.09, Epsilon=0.135

Epoch 450: Error=0.0210, Reward=14.56, Epsilon=0.105

Epoch 500: Error=0.0066, Reward=13.26, Epsilon=0.082
Training simulation complete (500 epochs)

## What To Try Next

1. Open the WinForms window from a standalone console -- see the live charts
2. Change dataTimer.Interval to 50 -- twice as fast
3. Change startError to 0.9 -- steeper learning curve
4. Move on to examples\05-Validation-Dashboard\ -- evaluating model quality

## Key Concepts

- Learning curves -- the primary diagnostic tool for training
- Exponential error decay -- what healthy neural network training looks like
- Epsilon decay schedule -- visualising exploration vs exploitation
- WinForms timer-driven data updates in PowerShell

## Files

- `Run-Example-04.ps1` -- run this to start the example
- `VBAF.Visualization.Example-Dashboard.ps1` -- full dashboard with WinForms window
- Source: `..\..\VBAF.Visualization.MetricsCollector.ps1` -- metrics tracking
- Source: `..\..\VBAF.Visualization.LearningDashboard.ps1` -- dashboard class
