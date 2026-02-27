[← Back to Tutorials](README.md) | [🏠 Home](../../README.md)

# Tutorial 06: Using the VBAF Dashboards

**Visualize your AI learning in real-time** 📊

> **Prerequisites:** Tutorial 01 and 03 completed
> **Time:** 10-15 minutes
> **Difficulty:** Beginner

---

## What You Will Learn

- How to launch the 3 VBAF dashboards
- What each dashboard shows and when to use it
- How to connect a training loop to live visualization

---

## Overview: The 3 Dashboards

VBAF includes three real-time WinForms dashboards:

| Dashboard | Script | Shows |
|-----------|--------|-------|
| Learning Dashboard | `VBAF.Visualization.Example-Dashboard.ps1` | Neural network training curves |
| Market Dashboard | `VBAF.Business.Dashboard-Demo.ps1` | 4 competing company agents |
| Validation Dashboard | `VBAF.Core.Test-ValidationDashboard.ps1` | XOR + Grid World side by side |

---

## Step 1: Load the Framework
```powershell
. .\VBAF.LoadAll.ps1
```

---

## Dashboard 1: Learning Dashboard

Shows your neural network error decreasing in real-time as it trains.
```powershell
. .\VBAF.Visualization.Example-Dashboard.ps1
```

**What you will see:**
- Error graph dropping toward zero
- Live statistics updating each epoch
- Network learning the XOR problem visually

**Best used for:** Understanding how backpropagation reduces error over time.

---

## Dashboard 2: Market Dashboard

Four company agents (Pharma, Wine, Banking, AI) compete across 20+ quarters.
```powershell
. .\VBAF.Business.Dashboard-Demo.ps1
```

**What you will see:**
- Market share shifting between companies
- Prices and profits evolving each quarter
- Emergent strategies forming without explicit programming
- Random economic events (recessions, breakthroughs) disrupting the market

**Best used for:** Understanding multi-agent reinforcement learning and emergent behavior.

---

## Dashboard 3: Validation Dashboard

Runs two algorithms side by side to validate the framework works correctly.
```powershell
. .\VBAF.Core.Test-ValidationDashboard.ps1
```

**What you will see:**
- Left panel: XOR neural network converging
- Right panel: Grid World Q-Learning agent improving
- Both training simultaneously in real-time

**Best used for:** Verifying your VBAF installation is working correctly.

---

## Connecting Your Own Training to a Dashboard

You can attach the Learning Dashboard to any training loop:
```powershell
# Load visualization
. .\VBAF.LoadAll.ps1

# Create dashboard
$dashboard = New-Object LearningDashboard -ArgumentList "My Training Monitor"
$dashboard.ShowNonBlocking()

# Create network
$nn = New-Object NeuralNetwork -ArgumentList @(2, 3, 1), 0.1

$xorData = @(
    @{Input=@(0,0); Expected=0},
    @{Input=@(0,1); Expected=1},
    @{Input=@(1,0); Expected=1},
    @{Input=@(1,1); Expected=0}
)

# Training loop with live updates
for ($epoch = 0; $epoch -lt 1000; $epoch++) {
    foreach ($sample in $xorData) {
        $output = $nn.Forward($sample.Input)
        $error = [Math]::Abs($sample.Expected - $output[0])
        $nn.Backward($sample.Expected)
        $dashboard.UpdateFromNeuralNetwork(@{Error=$error})
    }

    if ($epoch % 10 -eq 0) {
        $dashboard.Refresh()
    }
}

Write-Host "Training complete! Close dashboard window when done."
```

---

## Dashboard Tips

**Performance:**
- Dashboards run at 20-30 FPS on most Windows machines
- If slow, increase the refresh interval from 10 to 25 epochs

**Window behavior:**
- Dashboards are non-blocking — your script keeps running while they display
- Close the window when done or let the script finish naturally

**Troubleshooting crashes:**
- If a dashboard freezes, just close the window and rerun
- Core learning always works without visualization — dashboards are optional
- Make sure you ran `. .\VBAF.LoadAll.ps1` before launching any dashboard

---

## What You Learned

- VBAF has 3 dashboards covering neural networks, multi-agent markets, and validation
- Dashboards are non-blocking WinForms windows that update in real-time
- You can attach the Learning Dashboard to any custom training loop
- Visualization is optional — all learning works without it

---

## Next Steps

- **Examples/03-Market-Simulation:** Dig deeper into the market agent code
- **Examples/04-Learning-Dashboard:** See the full dashboard example script
- **docs/Architecture.md:** Understand how the visualization layer is built

---

*VBAF Version: 1.0.0 | PowerShell 5.1+ | Windows 10/11*


---
[← Back to Tutorials](README.md) | [← Back to Tutorial 05](05-Custom-Environment.md)
