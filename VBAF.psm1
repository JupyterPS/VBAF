#Requires -Version 5.1

<#
.SYNOPSIS
    VBAF (Visual Business Automation Framework) Module Loader
.DESCRIPTION
    Loads all VBAF components using existing VBAF.LoadAll.ps1 and adds public API functions.
    
    This module provides a complete AI/RL framework built from scratch in PowerShell 5.1:
    - Neural networks with backpropagation
    - Q-Learning agents with experience replay
    - Multi-agent reinforcement learning
    - Real-time visualization dashboards
    - Business simulation environments
    - Generative art with aesthetic rewards
    
.NOTES
    Author: Henning
    Version: 1.0.0
    PowerShell: 5.1+
    
.EXAMPLE
    Import-Module VBAF
    $nn = New-VBAFNeuralNetwork -Architecture @(2,3,1) -LearningRate 0.1
    
.EXAMPLE
    Import-Module VBAF
    $agent = New-VBAFAgent -Type QLearning -Actions @("up","down","left","right")
#>

# Get module root path
$script:ModuleRoot = $PSScriptRoot

Write-Verbose "Loading VBAF Module from: $script:ModuleRoot"

# ==================== LOAD ASSEMBLIES ====================
Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
Add-Type -AssemblyName System.Drawing -ErrorAction SilentlyContinue

# ==================== LOAD ALL CLASSES USING EXISTING LOADER ====================
Write-Verbose "  Loading all VBAF classes via VBAF.LoadAll.ps1..."

# Use the existing, working VBAF.LoadAll.ps1
$loadAllPath = "C:\Users\henni\OneDrive\WindowsPowerShell\VBAF.LoadAll.ps1"

if (Test-Path $loadAllPath) {
    # Suppress the welcome messages from LoadAll
    $originalVerbose = $VerbosePreference
    $VerbosePreference = 'SilentlyContinue'
    
    # Load all classes
    . $loadAllPath
    
    $VerbosePreference = $originalVerbose
    Write-Verbose "  ✓ All classes loaded via VBAF.LoadAll.ps1"
} else {
    Write-Warning "VBAF.LoadAll.ps1 not found at: $loadAllPath"
    Write-Warning "Classes may not be available. Expected location: $loadAllPath"
}

# ==================== LOAD ART CLASSES (New ones not in LoadAll) ====================
Write-Verbose "  Loading new Art classes..."

# AestheticReward (created in this session)
if (Test-Path "$script:ModuleRoot\Art\VBAF.Art.AestheticReward.ps1") {
    . "$script:ModuleRoot\Art\VBAF.Art.AestheticReward.ps1"
    Write-Verbose "    ✓ Loaded: AestheticReward"
}

# CastleCompetition (created in this session)
if (Test-Path "$script:ModuleRoot\Art\VBAF.Art.CastleCompetition.ps1") {
    . "$script:ModuleRoot\Art\VBAF.Art.CastleCompetition.ps1"
    Write-Verbose "    ✓ Loaded: CastleCompetition"
}

Write-Verbose "  ✓ Art classes loaded"

# ==================== LOAD PUBLIC FUNCTIONS ====================
Write-Verbose "  Loading Public API functions..."

# Get all public function files
$PublicFunctions = @(Get-ChildItem -Path "$script:ModuleRoot\VBAF.Public.*.ps1" -ErrorAction SilentlyContinue)

# Dot source each function
foreach ($Function in $PublicFunctions) {
    try {
        . $Function.FullName
        Write-Verbose "    ✓ Loaded: $($Function.BaseName)"
    } catch {
        Write-Error "Failed to import function $($Function.FullName): $_"
    }
}

Write-Verbose "  ✓ Public API functions loaded ($($PublicFunctions.Count) functions)"

# ==================== MODULE INITIALIZATION ====================

# Module version
$script:VBAFVersion = '1.0.0'

# Module startup message
$script:ShowWelcomeMessage = $true

if ($script:ShowWelcomeMessage) {
    Write-Host ""
    Write-Host "      - oo00oo - " -ForegroundColor Yellow
    Write-Host "  VBAF v$script:VBAFVersion Loaded" -ForegroundColor Cyan
    Write-Host "  Visual Business Automation Framework" -ForegroundColor Cyan
    Write-Host "      - oo00oo - " -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Quick Start:" -ForegroundColor Green
    Write-Host "    Get-VBAFExamples    # View available examples" -ForegroundColor White
    Write-Host "    Get-VBAFVersion     # Show module info" -ForegroundColor White
    Write-Host "    Get-Command -Module VBAF  # List all commands" -ForegroundColor White
    Write-Host ""
}

# ==================== EXPORTED MEMBERS ====================

# Export functions (defined in manifest, but we can also export here for safety)
Export-ModuleMember -Function @(
    # Neural Network Functions
    'New-VBAFNeuralNetwork',
    'Train-VBAFNeuralNetwork',
    'Test-VBAFNeuralNetwork',
    'Export-VBAFNeuralNetwork',
    'Import-VBAFNeuralNetwork',
    
    # RL Agent Functions
    'New-VBAFAgent',
    'Train-VBAFAgent',
    'Get-VBAFAgentStats',
    'Export-VBAFAgent',
    'Import-VBAFAgent',
    
    # Market/Business Functions
    'New-VBAFMarket',
    'Start-VBAFMarketSimulation',
    'Get-VBAFMarketStats',
    
    # Visualization Functions
    'New-VBAFDashboard',
    'Show-VBAFLearningCurve',
    'Show-VBAFNetworkStructure',
    
    # Competition Functions
    'Start-VBAFCastleCompetition',
    'New-VBAFAestheticReward',
    
    # Utility Functions
    'Get-VBAFVersion',
    'Get-VBAFExamples',
    'Test-VBAF'
)

# Export module variables (if any)
Export-ModuleMember -Variable @(
    'ModuleRoot',
    'VBAFVersion'
)

# ==================== MODULE CLEANUP ====================

# Register cleanup on module removal
$ExecutionContext.SessionState.Module.OnRemove = {
    Write-Verbose "Unloading VBAF module..."
    # Cleanup code here if needed (e.g., close open dashboards, save state)
}

Write-Verbose "VBAF Module loaded successfully!"