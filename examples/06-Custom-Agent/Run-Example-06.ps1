 #Requires -Version 5.1
<#
.SYNOPSIS
    Launcher for Example 06 -- Custom Agent
.DESCRIPTION
    Loads the full VBAF framework and runs the custom enterprise pillar tutorial.

    WHAT THIS FILE DOES:
    ====================
    tutorials\13_Enterprise_CustomPillar.ps1 builds a complete Phase 28
    enterprise pillar from scratch -- Network Traffic Manager.

    It depends on:
      VBAF.Core.AllClasses.ps1   -- NeuralNetwork class
      VBAF.RL.DQN.ps1            -- DQNConfig, DQNAgent classes
      VBAF.RL.ExperienceReplay.ps1 -- replay buffer

    Loading via VBAF.LoadAll.ps1 guarantees all three are available
    before the tutorial runs.

    WHAT YOU WILL SEE:
    ==================
    Phase 1 -- Baseline: random agent, negative average reward
    Phase 2 -- Training: DQN agent improves over 30 episodes
    Phase 3 -- Evaluation: trained agent beats baseline by 100%+

    The NetworkTrafficEnvironment class in the tutorial is the
    template for any new VBAF enterprise pillar you want to build.

    HOW TO RUN:
    ===========
    cd "C:\Users\henni\OneDrive\WindowsPowerShell\examples\06-Custom-Agent"
    . .\Run-Example-06.ps1

.NOTES
    Part of VBAF (Visual AI & Reinforcement Learning Framework)
    Example 06 of 06 -- the final example and the starting point for Phase 28+.
    Run Examples 01-05 first for the full learning path.
#>

# Resolve the framework root (two levels up from this examples subfolder)
$frameworkRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")

# Step 1 -- Load the full VBAF framework
Write-Host ""
Write-Host "  Loading VBAF framework from: $frameworkRoot" -ForegroundColor DarkGray
. (Join-Path $frameworkRoot "VBAF.LoadAll.ps1")

# Step 2 -- Run the custom agent tutorial
Write-Host "  Starting Example 06: Custom Agent..." -ForegroundColor Cyan
Write-Host ""

& (Join-Path $frameworkRoot "tutorials\13_Enterprise_CustomPillar.ps1")