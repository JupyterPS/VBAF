function Get-VBAFExamples {
    <#
    .SYNOPSIS
        Lists available VBAF examples and how to run them.
    
    .DESCRIPTION
        Displays all available example scripts with descriptions and usage instructions.
        Examples demonstrate neural networks, Q-learning, multi-agent systems, and more.
    
    .PARAMETER Category
        Filter examples by category.
        Valid values: 'Core', 'RL', 'Business', 'Art', 'Visualization', 'All'
        Default: 'All'
    
    .PARAMETER ShowPath
        Display full file paths to examples.
    
    .EXAMPLE
        Get-VBAFExamples
        
        Lists all available examples.
    
    .EXAMPLE
        Get-VBAFExamples -Category RL
        
        Shows only reinforcement learning examples.
    
    .EXAMPLE
        Get-VBAFExamples -ShowPath
        
        Displays file paths to examples.
    
    .OUTPUTS
        List of available examples with descriptions.
    
    .NOTES
        Author: Henning
        Part of VBAF Module
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet('Core', 'RL', 'Business', 'Art', 'Visualization', 'All')]
        [string]$Category = 'All',
        
        [Parameter(Mandatory = $false)]
        [switch]$ShowPath
    )
    
    Write-Host "`n      - oo00oo - " -ForegroundColor Yellow
    Write-Host "  VBAF Examples" -ForegroundColor Cyan
    Write-Host "      - oo00oo - `n" -ForegroundColor Yellow
    
    # Define all examples
    $examples = @(
        [PSCustomObject]@{
            Category = 'Core'
            Name = 'XOR Neural Network'
            File = 'VBAF.Core.Example-XOR.ps1'
            Description = 'Train a neural network to solve the XOR problem'
            Command = '. $basePath\VBAF.Core.Example-XOR.ps1'
        },
        [PSCustomObject]@{
            Category = 'Core'
            Name = 'Validation Dashboard'
            File = 'VBAF.Core.Test-ValidationDashboard.ps1'
            Description = 'Visual proof that neural networks and Q-learning work'
            Command = '. $basePath\VBAF.Core.Test-ValidationDashboard.ps1'
        },
        [PSCustomObject]@{
            Category = 'RL'
            Name = 'Castle Q-Learning'
            File = 'VBAF.RL.Example-CastleLearning.ps1'
            Description = 'RL agent learns to generate aesthetic castle sequences'
            Command = '. $basePath\VBAF.RL.Example-CastleLearning.ps1'
        },
        [PSCustomObject]@{
            Category = 'RL'
            Name = 'Q-Learning Grid World'
            File = 'VBAF.RL.Example-GridWorld.ps1'
            Description = 'Simple Q-learning in 10x10 grid environment'
            Command = '. $basePath\VBAF.RL.Example-GridWorld.ps1'
        },
        [PSCustomObject]@{
            Category = 'Business'
            Name = 'Company Learning Test'
            File = 'VBAF.Company.TestLearning.ps1'
            Description = 'Single company agent learns optimal strategy'
            Command = '. $basePath\VBAF.Company.TestLearning.ps1'
        },
        [PSCustomObject]@{
            Category = 'Business'
            Name = 'Multi-Company Market'
            File = 'VBAF.Business.Test.CompanyMarket.ps1'
            Description = '4 companies compete in simulated market'
            Command = '. $basePath\VBAF.Business.Test.CompanyMarket.ps1'
        },
        [PSCustomObject]@{
            Category = 'Business'
            Name = 'Market Dashboard Demo'
            File = 'VBAF.Business.Dashboard-Demo.ps1'
            Description = 'Real-time visualization of market simulation'
            Command = '. $basePath\VBAF.Business.Dashboard-Demo.ps1'
        },
        [PSCustomObject]@{
            Category = 'Art'
            Name = 'Castle Competition'
            File = 'VBAF.Art.CastleCompetition.ps1'
            Description = '3 agents compete for aesthetic space - GRAND FINALE!'
            Command = '. $basePath\VBAF.Art.CastleCompetition.ps1'
        },
        [PSCustomObject]@{
            Category = 'Art'
            Name = 'Show20 Q-Learning Agent'
            File = 'VBAF.Art.Show20-QLearning.ps1'
            Description = 'Original castle generation with Q-learning'
            Command = '. $basePath\VBAF.Art.Show20-QLearning.ps1'
        },
        [PSCustomObject]@{
            Category = 'Visualization'
            Name = 'Learning Dashboard'
            File = 'VBAF.Visualization.Example-Dashboard.ps1'
            Description = 'Real-time learning curve visualization'
            Command = '. $basePath\VBAF.Visualization.Example-Dashboard.ps1'
        }
    )
    
    # Filter by category
    if ($Category -ne 'All') {
        $examples = $examples | Where-Object { $_.Category -eq $Category }
    }
    
    # Group by category
    $grouped = $examples | Group-Object Category
    
    foreach ($group in $grouped) {
        Write-Host "  [$($group.Name)]" -ForegroundColor Green
        Write-Host "  " + ("=" * 70) -ForegroundColor DarkGray
        
        foreach ($example in $group.Group) {
            Write-Host "  • " -NoNewline -ForegroundColor Cyan
            Write-Host $example.Name -ForegroundColor White
            Write-Host "    $($example.Description)" -ForegroundColor Gray
            
            if ($ShowPath) {
                Write-Host "    File: $($example.File)" -ForegroundColor DarkGray
            }
            
            Write-Host "    Run: " -NoNewline -ForegroundColor Yellow
            Write-Host $example.Command -ForegroundColor White
            Write-Host ""
        }
    }
    
    Write-Host "  Total Examples: $($examples.Count)" -ForegroundColor Cyan
    Write-Host "`n      - oo00oo - `n" -ForegroundColor Yellow
    
    # Return examples for pipeline use
    return $examples
}