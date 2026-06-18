 #Requires -Version 5.1
<#
.SYNOPSIS
    Launcher for Example 05 -- Validation Dashboard
.DESCRIPTION
    Loads the full VBAF framework and runs the three-panel validation dashboard.

    WHAT THIS FILE DOES:
    ====================
    VBAF.Core.Test-ValidationDashboard.ps1 depends on four classes:
      VBAF.Core.AllClasses.ps1
      VBAF.RL.QTable.ps1
      VBAF.RL.ExperienceReplay.ps1
      VBAF.RL.QLearningAgent.ps1

    Loading via VBAF.LoadAll.ps1 guarantees all four are available
    before the dashboard starts.

    WHAT THE DASHBOARD SHOWS:
    =========================
    Panel 1 -- Neural network training on XOR (click Start to begin)
    Panel 2 -- Q-learning agent navigating a 10x10 grid (auto-starts)
    Panel 3 -- Experience replay buffer filling (auto-starts)

    IMPORTANT -- RUN FROM POWERSHELL CONSOLE, NOT ISE:
    ===================================================
    This dashboard opens a WinForms window.
    ISE locks when a WinForms window opens -- this is a known ISE limitation.

    Run from: Start -> Windows PowerShell (the blue console icon)
    Do NOT run from: PowerShell ISE (the editor with script pane)

    HOW TO RUN:
    ===========
    cd "C:\Users\henni\OneDrive\WindowsPowerShell\examples\05-Validation-Dashboard"
    . .\Run-Example-05.ps1

.NOTES
    Part of VBAF (Visual AI & Reinforcement Learning Framework)
    Example 05 of 06 -- run Examples 01-04 first.
#>

# Resolve the framework root (two levels up from this examples subfolder)
$frameworkRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")

# Step 1 -- Load the full VBAF framework
Write-Host ""
Write-Host "  Loading VBAF framework from: $frameworkRoot" -ForegroundColor DarkGray
. (Join-Path $frameworkRoot "VBAF.LoadAll.ps1")

# Step 2 -- Remind the user about ISE limitation before launching
Write-Host ""
Write-Host "  NOTE: WinForms window requires standalone PowerShell console." -ForegroundColor Yellow
Write-Host "  Q-learning and replay buffer start automatically." -ForegroundColor DarkGray
Write-Host "  Click 'Start NN Training' in the window to begin backpropagation." -ForegroundColor DarkGray
Write-Host ""

# Step 3 -- Run the validation dashboard
Write-Host "  Starting Example 05: Validation Dashboard..." -ForegroundColor Cyan
Write-Host ""

& (Join-Path $frameworkRoot "VBAF.Core.Test-ValidationDashboard.ps1")