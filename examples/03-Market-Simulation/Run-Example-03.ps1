 #Requires -Version 5.1
<#
.SYNOPSIS
    Launcher for Example 03 -- Market Simulation
.DESCRIPTION
    Loads the full VBAF framework and runs the four-company market simulation.

    WHAT THIS FILE DOES:
    ====================
    VBAF.Business.Test.CompanyMarket.ps1 depends on five classes:
      VBAF.RL.QLearningAgent.ps1
      VBAF.RL.ExperienceReplay.ps1
      VBAF.Business.CompanyState.ps1
      VBAF.Business.BusinessAction.ps1
      VBAF.Business.CompanyAgent.ps1
      VBAF.Business.MarketEnvironment.ps1

    Loading via VBAF.LoadAll.ps1 guarantees all six are available
    in the correct order before the simulation runs.

    HOW TO RUN:
    ===========
    cd "C:\Users\henni\OneDrive\WindowsPowerShell\examples\03-Market-Simulation"
    . .\Run-Example-03.ps1

.NOTES
    Part of VBAF (Visual AI & Reinforcement Learning Framework)
    Example 03 of 06 -- the most complex example so far.
    Run Examples 01 and 02 first.
#>

# Resolve the framework root (two levels up from this examples subfolder)
$frameworkRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")

# Step 1 -- Load the full VBAF framework
Write-Host ""
Write-Host "  Loading VBAF framework from: $frameworkRoot" -ForegroundColor DarkGray
. (Join-Path $frameworkRoot "VBAF.LoadAll.ps1")

# Step 2 -- Run the market simulation
Write-Host "  Starting Example 03: Market Simulation..." -ForegroundColor Cyan
Write-Host ""

& (Join-Path $frameworkRoot "VBAF.Business.Test.CompanyMarket.ps1")