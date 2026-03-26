# 06 — Using Dashboards

## What You Will Learn

- How to visualise training progress
- How to read the VBAF dashboard
- How to interpret learning curves

## Available Dashboards
```powershell
. .\VBAF.LoadAll.ps1

# Training visualisation dashboard
& ".\VBAF.Visualization.Example-Dashboard.ps1"

# Business metrics dashboard
& ".\VBAF.Business.Dashboard-Demo.ps1"

# Validation dashboard
& ".\VBAF.Core.Test-ValidationDashboard.ps1"

# Q-Learning animation
& ".\VBAF.Art.Show20-QLearning.ps1"

# Castle competition visualisation
& ".\VBAF.Art.CastleCompetition.ps1"
```

## Reading a Learning Curve

A healthy learning curve shows:
- Episodes 1-30: reward fluctuates, mostly random (high epsilon)
- Episodes 30-70: reward trend improves (agent starts exploiting)
- Episodes 70-100: reward stabilises near optimal (low epsilon)

If reward never improves, check:
- Is the environment returning meaningful rewards?
- Is the architecture large enough for the state space?
- Is epsilon decaying at the right rate?

## Dashboard Metrics

| Metric | What it means |
|--------|--------------|
| Avg reward | Mean reward over last N episodes |
| Epsilon | Current exploration rate (1=random, 0=exploit) |
| Loss | Neural network training loss |
| Action distribution | How often each action is chosen |
