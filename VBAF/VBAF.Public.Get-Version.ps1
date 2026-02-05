function Get-VBAFVersion {
    <#
    .SYNOPSIS
        Displays VBAF module version and information.
    
    .DESCRIPTION
        Shows detailed information about the VBAF module including:
        - Version number
        - Installation path
        - Loaded components
        - Available functions
        - System requirements
    
    .PARAMETER Detailed
        Show detailed component information.
    
    .EXAMPLE
        Get-VBAFVersion
        
        Displays basic version information.
    
    .EXAMPLE
        Get-VBAFVersion -Detailed
        
        Shows detailed component listing.
    
    .OUTPUTS
        PSCustomObject with version information.
    
    .NOTES
        Author: Henning
        Part of VBAF Module
    #>
    
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$Detailed
    )
    
    Write-Host "`n      - oo00oo - " -ForegroundColor Yellow
    Write-Host "  VBAF - Visual Business Automation Framework" -ForegroundColor Cyan
    Write-Host "      - oo00oo - `n" -ForegroundColor Yellow
    
    # Get module info
    $module = Get-Module VBAF
    
    if ($null -eq $module) {
        Write-Warning "VBAF module is not currently loaded"
        return
    }
    
    Write-Host "  Version: " -NoNewline -ForegroundColor Green
    Write-Host $module.Version -ForegroundColor White
    
    Write-Host "  Author: " -NoNewline -ForegroundColor Green
    Write-Host $module.Author -ForegroundColor White
    
    Write-Host "  Path: " -NoNewline -ForegroundColor Green
    Write-Host $module.ModuleBase -ForegroundColor White
    
    Write-Host "  PowerShell: " -NoNewline -ForegroundColor Green
    Write-Host "$($PSVersionTable.PSVersion) ($($PSVersionTable.PSEdition))" -ForegroundColor White
    
    # Count exported functions
    $exportedFunctions = Get-Command -Module VBAF -CommandType Function
    Write-Host "  Exported Functions: " -NoNewline -ForegroundColor Green
    Write-Host $exportedFunctions.Count -ForegroundColor White
    
    if ($Detailed) {
        Write-Host "`n  Components:" -ForegroundColor Cyan
        Write-Host "    • Core: Neural Networks, Activation Functions" -ForegroundColor White
        Write-Host "    • RL: Q-Learning, Experience Replay, Agents" -ForegroundColor White
        Write-Host "    • Business: Market Simulation, Company Agents" -ForegroundColor White
        Write-Host "    • Art: Castle Competition, Aesthetic Rewards" -ForegroundColor White
        Write-Host "    • Visualization: Dashboards, Learning Curves" -ForegroundColor White
        
        Write-Host "`n  Available Commands:" -ForegroundColor Cyan
        foreach ($func in ($exportedFunctions | Sort-Object Name)) {
            Write-Host "    • $($func.Name)" -ForegroundColor Gray
        }
    }
    
    Write-Host "`n  Quick Start:" -ForegroundColor Green
    Write-Host "    Get-VBAFExamples           # View examples" -ForegroundColor White
    Write-Host "    Get-Help New-VBAFNeuralNetwork -Examples" -ForegroundColor White
    Write-Host "    Get-Command -Module VBAF   # List all commands" -ForegroundColor White
    
    Write-Host "`n      - oo00oo - `n" -ForegroundColor Yellow
    
    # Return object for pipeline use
    [PSCustomObject]@{
        Name = $module.Name
        Version = $module.Version
        Author = $module.Author
        Path = $module.ModuleBase
        ExportedFunctions = $exportedFunctions.Count
        PowerShellVersion = $PSVersionTable.PSVersion
        PowerShellEdition = $PSVersionTable.PSEdition
    }
}