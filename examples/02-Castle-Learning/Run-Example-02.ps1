#Requires -Version 5.1
<#
.SYNOPSIS
    Launcher for Example 02 -- Castle Learning
.DESCRIPTION
    Loads the full VBAF framework and runs the Castle Learning example.

    WHAT THIS FILE DOES:
    ====================
    VBAF.RL.Example-CastleLearning.ps1 depends on three RL classes:
      VBAF.RL.QTable.ps1
      VBAF.RL.ExperienceReplay.ps1
      VBAF.RL.QLearningAgent.ps1

    Loading via VBAF.LoadAll.ps1 guarantees all three are available
    in the correct order before the example runs.

    HOW TO RUN:
    ===========
    cd "C:\Users\henni\OneDrive\WindowsPowerShell\examples\02-Castle-Learning"
    . .\Run-Example-02.ps1

.NOTES
    Part of VBAF (Visual AI & Reinforcement Learning Framework)
    Example 02 of 06 -- run Example 01 (XOR) first.
#>

# Resolve the framework root (two levels up from this examples subfolder)
$frameworkRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")

# Step 1 -- Load the full VBAF framework
Write-Host ""
Write-Host "  Loading VBAF framework from: $frameworkRoot" -ForegroundColor DarkGray
. (Join-Path $frameworkRoot "VBAF.LoadAll.ps1")

# Step 2 -- Run the Castle Learning example
Write-Host "  Starting Example 02: Castle Learning..." -ForegroundColor Cyan
Write-Host ""

& (Join-Path $frameworkRoot "VBAF.RL.Example-CastleLearning.ps1")