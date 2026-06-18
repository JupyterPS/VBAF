 #Requires -Version 5.1
<#
.SYNOPSIS
    Launcher for Example 04 -- Learning Dashboard
.DESCRIPTION
    Loads the full VBAF framework and runs the learning dashboard demo.

    WHAT THIS FILE DOES:
    ====================
    VBAF.Visualization.Example-Dashboard.ps1 depends on three classes:
      VBAF.Visualization.MetricsCollector.ps1
      VBAF.Visualization.GraphRenderer.ps1
      VBAF.Visualization.LearningDashboard.ps1

    Loading via VBAF.LoadAll.ps1 guarantees all three are available
    before the dashboard starts.

    IMPORTANT -- RUN FROM POWERSHELL CONSOLE, NOT ISE:
    ===================================================
    This dashboard opens a WinForms window.
    ISE locks when a WinForms window opens -- this is a known ISE limitation.

    Run from: Start -> Windows PowerShell (the blue console icon)
    Do NOT run from: PowerShell ISE (the editor with script pane)

    The console output (epochs 50-500) works in both.
    The WinForms chart window only works in standalone console.

    HOW TO RUN:
    ===========
    cd "C:\Users\henni\OneDrive\WindowsPowerShell\examples\04-Learning-Dashboard"
    . .\Run-Example-04.ps1

.NOTES
    Part of VBAF (Visual AI & Reinforcement Learning Framework)
    Example 04 of 06 -- run Examples 01-03 first.
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
Write-Host "  Console output (learning curves) works in both ISE and console." -ForegroundColor DarkGray
Write-Host ""

# Step 3 -- Run the learning dashboard
Write-Host "  Starting Example 04: Learning Dashboard..." -ForegroundColor Cyan
Write-Host ""

& (Join-Path $frameworkRoot "VBAF.Visualization.Example-Dashboard.ps1")