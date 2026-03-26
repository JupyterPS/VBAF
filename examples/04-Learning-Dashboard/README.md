# Example 04: Learning Dashboard

Real-time visualisation of agent training progress.
Watch epsilon decay, reward improvement and action distribution
update live as the agent trains.

## What It Does

- Displays training metrics in a terminal dashboard
- Updates every N episodes during training
- Shows learning curves, action counts and final policy

## Run It
```powershell
. .\VBAF.LoadAll.ps1
& ".\VBAF.Visualization.Example-Dashboard.ps1"
```

## Dashboard Panels

- Top: episode reward history (last 20 episodes)
- Middle: epsilon decay curve
- Bottom: action distribution bar chart
- Right: current policy summary

## Key Concepts

- Live training visualisation in PowerShell console
- Reading learning curves to diagnose training issues
- Action distribution as a policy health indicator

## Files

- `VBAF.Visualization.Example-Dashboard.ps1` — main dashboard
- See [docs/tutorials/06-Using-Dashboards.md](../../docs/tutorials/06-Using-Dashboards.md)
