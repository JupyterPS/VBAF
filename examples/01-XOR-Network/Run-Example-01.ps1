#Requires -Version 5.1
<#
.SYNOPSIS
    Launcher for Example 01 -- XOR Network
.DESCRIPTION
    Loads the full VBAF framework and runs the XOR example.

    WHAT THIS FILE DOES:
    ====================
    This launcher exists because VBAF.Core.Example-XOR.ps1 lives in
    the root folder and depends on other classes being loaded first.

    The correct way to run any VBAF example is always:
      1. Load everything via VBAF.LoadAll.ps1
      2. Then run the example

    Never dot-source an example file directly if it depends on classes
    defined in other files -- those classes will not exist yet.

    HOW TO RUN:
    ===========
    cd "C:\Users\henni\OneDrive\WindowsPowerShell\examples\01-XOR-Network"
    . .\Run-Example-01.ps1

.NOTES
    Part of VBAF (Visual AI & Reinforcement Learning Framework)
    Start here -- this is Example 01 of 06.
#>

# Resolve the framework root (two levels up from this examples subfolder)
$frameworkRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")

# Step 1 -- Load the full VBAF framework
# This makes NeuralNetwork, QLearningAgent, DQN and all other classes available
Write-Host ""
Write-Host "  Loading VBAF framework from: $frameworkRoot" -ForegroundColor DarkGray
. (Join-Path $frameworkRoot "VBAF.LoadAll.ps1")

# Step 2 -- Run the XOR example
# The example file lives in the framework root, not in this examples folder
$exampleFile = Join-Path $frameworkRoot "VBAF.Core.Example-XOR.ps1"

Write-Host "  Starting Example 01: XOR Network..." -ForegroundColor Cyan
Write-Host ""

& $exampleFile