function Start-VBAFCastleCompetition {
    <#
    .SYNOPSIS
        Launches the multi-agent castle competition (Week 8 Grand Finale).
    
    .DESCRIPTION
        Starts a visual dashboard where three RL agents compete to generate
        aesthetically pleasing castle sequences. Watch emergent coordination
        behaviors as agents learn to cooperate!
        
        Agents:
        - Classic Agent (Brown) - Prefers Gothic, Cathedral, Fortress
        - Whimsical Agent (Pink) - Prefers FairyTale, Wizard, Palace
        - Modern Agent (Cyan) - Prefers Oriental, Ruins, minimalist
        
        The competition demonstrates:
        - Multi-agent reinforcement learning
        - Emergent coordination without communication
        - Aesthetic reward shaping
        - Real-time learning visualization
    
    .PARAMETER StepsPerEpisode
        Number of castle generations per episode.
        Default: 30
    
    .PARAMETER AutoStart
        Automatically start the competition when dashboard opens.
        Default: False (requires clicking Start button)
    
    .PARAMETER Speed
        Competition speed (milliseconds between steps).
        Range: 50 to 5000
        Default: 100 (10 steps/second)
        
        Lower = faster
        Higher = slower (easier to watch)
    
    .EXAMPLE
        Start-VBAFCastleCompetition
        
        Launches competition dashboard. Press "Start" to begin.
    
    .EXAMPLE
        Start-VBAFCastleCompetition -AutoStart -Speed 200
        
        Automatically starts competition at slower speed (5 steps/second).
    
    .EXAMPLE
        Start-VBAFCastleCompetition -StepsPerEpisode 50
        
        Longer episodes (50 castles per episode).
    
    .OUTPUTS
        None. Opens WinForms dashboard.
    
    .NOTES
        Author: Henning
        Part of VBAF Module
        Requires: WinForms, Drawing assemblies
        
        This is the Week 8 Grand Finale - brings together:
        - Neural networks (Week 1)
        - Q-Learning (Week 2)
        - Visualization (Week 3)
        - Multi-agent systems (Week 6)
        - Aesthetic rewards (Option 3)
    
    .LINK
        New-VBAFAgent
        New-VBAFAestheticReward
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateRange(10, 200)]
        [int]$StepsPerEpisode = 30,
        
        [Parameter(Mandatory = $false)]
        [switch]$AutoStart,
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(50, 5000)]
        [int]$Speed = 100
    )
    
    begin {
        Write-Host "`n      - oo00oo - " -ForegroundColor Yellow
        Write-Host "  🏰 CASTLE COMPETITION - WEEK 8 GRAND FINALE 🏰" -ForegroundColor Cyan
        Write-Host "      - oo00oo - `n" -ForegroundColor Yellow
        
        Write-Host "  Three agents compete for aesthetic space:" -ForegroundColor Green
        Write-Host "    • Classic Agent (Brown) - Gothic, Cathedral, Fortress" -ForegroundColor DarkYellow
        Write-Host "    • Whimsical Agent (Pink) - FairyTale, Wizard, Palace" -ForegroundColor Magenta
        Write-Host "    • Modern Agent (Cyan) - Oriental, Ruins, minimalist" -ForegroundColor Cyan
        Write-Host "`n  Configuration:" -ForegroundColor Green
        Write-Host "    Steps per episode: $StepsPerEpisode" -ForegroundColor White
        Write-Host "    Speed: $Speed ms ($([Math]::Round(1000/$Speed, 1)) steps/sec)" -ForegroundColor White
        Write-Host "    Auto-start: $AutoStart" -ForegroundColor White
        Write-Host "`n  Watch them learn to coordinate! 🚀`n" -ForegroundColor Yellow
    }
    
    process {
        try {
            # Check if competition script exists
            $competitionPath = Join-Path $script:ModuleRoot "Art\CastleCompetition.ps1"
            
            if (-not (Test-Path $competitionPath)) {
                Write-Warning "Castle competition script not found at: $competitionPath"
                Write-Host "`nYou can run it directly from your original location:" -ForegroundColor Yellow
                Write-Host '. $basePath\VBAF.Art.CastleCompetition.ps1' -ForegroundColor Cyan
                return
            }
            
            # Source the competition script
            . $competitionPath
            
            Write-Verbose "✓ Castle competition loaded"
            Write-Host "  Dashboard opening..." -ForegroundColor Green
            
        } catch {
            Write-Error "Failed to start castle competition: $_"
            throw
        }
    }
    
    end {
        Write-Verbose "Start-VBAFCastleCompetition completed"
    }
}