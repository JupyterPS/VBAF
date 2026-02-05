#Requires -Version 5.1

<#
.SYNOPSIS
    Aesthetic reward calculator for castle generation
.DESCRIPTION
    Scores castles based on beauty, variety, harmony, and timing.
    Core reward function for multi-agent castle competition (Week 8).
.NOTES
    Part of VBAF - Art/Generative Module
    Used by castle agents to learn aesthetic preferences
.EXAMPLE
    
#>

class AestheticReward {
    # Reward weights (tunable)
    [double]$BeautyWeight = 3.0       # Individual castle beauty
    [double]$VarietyWeight = 2.0      # Different from recent castles
    [double]$HarmonyWeight = 1.5      # Complements other castles
    [double]$TimingWeight = 1.0       # Not overcrowded
    
    # Castle type preferences (for beauty scoring)
    [hashtable]$TypeBeauty = @{
        "Gothic" = 0.9
        "FairyTale" = 0.85
        "Fortress" = 0.7
        "Cathedral" = 0.95
        "Wizard" = 0.8
        "Palace" = 0.9
        "Oriental" = 0.85
        "Ruins" = 0.6
    }
    
    # Type compatibility matrix (for harmony scoring)
    [hashtable]$TypeHarmony = @{
        "Gothic|FairyTale" = 0.3      # Gothic + FairyTale = clash
        "Gothic|Cathedral" = 0.9      # Gothic + Cathedral = harmonious
        "Gothic|Fortress" = 0.7
        "Gothic|Wizard" = 0.5
        "Gothic|Palace" = 0.6
        "Gothic|Oriental" = 0.4
        "Gothic|Ruins" = 0.7
        
        "FairyTale|Cathedral" = 0.4
        "FairyTale|Fortress" = 0.3
        "FairyTale|Wizard" = 0.9      # FairyTale + Wizard = magical!
        "FairyTale|Palace" = 0.8
        "FairyTale|Oriental" = 0.6
        "FairyTale|Ruins" = 0.3
        
        "Cathedral|Fortress" = 0.5
        "Cathedral|Wizard" = 0.6
        "Cathedral|Palace" = 0.8
        "Cathedral|Oriental" = 0.5
        "Cathedral|Ruins" = 0.4
        
        "Fortress|Wizard" = 0.4
        "Fortress|Palace" = 0.6
        "Fortress|Oriental" = 0.7
        "Fortress|Ruins" = 0.8        # Fortress + Ruins = historic!
        
        "Wizard|Palace" = 0.7
        "Wizard|Oriental" = 0.6
        "Wizard|Ruins" = 0.5
        
        "Palace|Oriental" = 0.9       # Palace + Oriental = exotic!
        "Palace|Ruins" = 0.4
        
        "Oriental|Ruins" = 0.6
    }
    
    # History tracking
    [System.Collections.ArrayList]$CastleHistory
    [int]$MaxHistory = 10
    
    AestheticReward() {
        $this.CastleHistory = New-Object System.Collections.ArrayList
    }
    
    # Calculate total reward for a castle
    [hashtable] CalculateReward([string]$castleType, [hashtable]$context) {
        $beauty = $this.ScoreBeauty($castleType)
        $variety = $this.ScoreVariety($castleType)
        $harmony = $this.ScoreHarmony($castleType, $context)
        $timing = $this.ScoreTiming($context)
        
        # Weighted sum
        $totalReward = (
            ($beauty * $this.BeautyWeight) +
            ($variety * $this.VarietyWeight) +
            ($harmony * $this.HarmonyWeight) +
            ($timing * $this.TimingWeight)
        )
        
        # Normalize to 0-10 range
        $maxPossible = $this.BeautyWeight + $this.VarietyWeight + $this.HarmonyWeight + $this.TimingWeight
        $normalizedReward = ($totalReward / $maxPossible) * 10.0
        
        # Add to history
        $this.AddToHistory($castleType)
        
        # Return breakdown
        return @{
            TotalReward = $normalizedReward
            Beauty = $beauty
            Variety = $variety
            Harmony = $harmony
            Timing = $timing
            CastleType = $castleType
            WeightedBeauty = $beauty * $this.BeautyWeight
            WeightedVariety = $variety * $this.VarietyWeight
            WeightedHarmony = $harmony * $this.HarmonyWeight
            WeightedTiming = $timing * $this.TimingWeight
        }
    }
    
    # Score individual castle beauty (0.0 - 1.0)
    [double] ScoreBeauty([string]$castleType) {
        if ($this.TypeBeauty.ContainsKey($castleType)) {
            return [double]$this.TypeBeauty[$castleType]
        } else {
            return 0.5  # Unknown type = neutral
        }
    }
    
    # Score variety (different from recent castles) (0.0 - 1.0)
    [double] ScoreVariety([string]$castleType) {
        if ($this.CastleHistory.Count -eq 0) {
            return 1.0  # First castle = full variety
        }
        
        # Count how many recent castles are the same type
        $recentCount = [Math]::Min(5, $this.CastleHistory.Count)
        $sameCount = 0
        
        for ($i = $this.CastleHistory.Count - 1; $i -ge $this.CastleHistory.Count - $recentCount; $i--) {
            if ($this.CastleHistory[$i] -eq $castleType) {
                $sameCount++
            }
        }
        
        # More same = less variety
        # 0 same = 1.0, 1 same = 0.7, 2 same = 0.4, 3+ same = 0.1
        if ($sameCount -eq 0) { return 1.0 }
        if ($sameCount -eq 1) { return 0.7 }
        if ($sameCount -eq 2) { return 0.4 }
        return 0.1
    }
    
    # Score harmony with nearby castles (0.0 - 1.0)
    [double] ScoreHarmony([string]$castleType, [hashtable]$context) {
        # Check if there are nearby castles (from context)
        if ($context.ContainsKey("NearbyCastles")) {
            $nearby = $context["NearbyCastles"]
            
            if ($nearby.Count -eq 0) {
                return 1.0  # No nearby castles = perfect harmony
            }
            
            # Average harmony with each nearby castle
            $totalHarmony = 0.0
            $count = 0
            
            foreach ($nearbyType in $nearby) {
                $harmonyScore = $this.GetTypeCompatibility($castleType, $nearbyType)
                $totalHarmony += $harmonyScore
                $count++
            }
            
            if ($count -gt 0) {
                return $totalHarmony / $count
            }
        }
        
        # Check recent history if no context provided
        if ($this.CastleHistory.Count -gt 0) {
            $lastCastle = $this.CastleHistory[$this.CastleHistory.Count - 1]
            return $this.GetTypeCompatibility($castleType, $lastCastle)
        }
        
        return 0.8  # Default good harmony
    }
    
    # Score timing (is screen crowded?) (0.0 - 1.0)
    [double] ScoreTiming([hashtable]$context) {
        # Check crowding from context
        if ($context.ContainsKey("CurrentCastleCount")) {
            $count = $context["CurrentCastleCount"]
            
            # Ideal: 3-5 castles on screen
            # Too few (0-2): 0.6
            # Just right (3-5): 1.0
            # Too many (6-8): 0.5
            # Overcrowded (9+): 0.2
            
            if ($count -le 2) { return 0.6 }
            if ($count -le 5) { return 1.0 }
            if ($count -le 8) { return 0.5 }
            return 0.2
        }
        
        return 0.8  # Default good timing
    }
    
    # Get compatibility between two castle types
    [double] GetTypeCompatibility([string]$type1, [string]$type2) {
        if ($type1 -eq $type2) {
            return 0.3  # Same type = low harmony (too repetitive)
        }
        
        # Try both orderings
        $key1 = "$type1|$type2"
        $key2 = "$type2|$type1"
        
        if ($this.TypeHarmony.ContainsKey($key1)) {
            return [double]$this.TypeHarmony[$key1]
        }
        
        if ($this.TypeHarmony.ContainsKey($key2)) {
            return [double]$this.TypeHarmony[$key2]
        }
        
        return 0.5  # Unknown combination = neutral
    }
    
    # Add castle to history
    [void] AddToHistory([string]$castleType) {
        $this.CastleHistory.Add($castleType) | Out-Null
        
        # Keep only recent history
        if ($this.CastleHistory.Count -gt $this.MaxHistory) {
            $this.CastleHistory.RemoveAt(0)
        }
    }
    
    # Reset history
    [void] ResetHistory() {
        $this.CastleHistory.Clear()
    }
    
    # Set custom weights
    [void] SetWeights([double]$beauty, [double]$variety, [double]$harmony, [double]$timing) {
        $this.BeautyWeight = $beauty
        $this.VarietyWeight = $variety
        $this.HarmonyWeight = $harmony
        $this.TimingWeight = $timing
    }
    
    # Analyze a sequence of castles
    [hashtable] AnalyzeSequence([array]$castleSequence) {
        $this.ResetHistory()
        
        $rewards = New-Object System.Collections.ArrayList
        $totalReward = 0.0
        
        foreach ($castle in $castleSequence) {
            $context = @{
                NearbyCastles = @()
                CurrentCastleCount = 3  # Assume moderate crowding
            }
            
            $reward = $this.CalculateReward($castle, $context)
            $rewards.Add($reward) | Out-Null
            $totalReward += $reward.TotalReward
        }
        
        $avgReward = if ($castleSequence.Count -gt 0) {
            $totalReward / $castleSequence.Count
        } else {
            0.0
        }
        
        return @{
            Rewards = $rewards
            TotalReward = $totalReward
            AverageReward = $avgReward
            SequenceLength = $castleSequence.Count
        }
    }
    
    # Get statistics
    [hashtable] GetStats() {
        $typeDistribution = @{}
        
        foreach ($castle in $this.CastleHistory) {
            if ($typeDistribution.ContainsKey($castle)) {
                $typeDistribution[$castle]++
            } else {
                $typeDistribution[$castle] = 1
            }
        }
        
        return @{
            HistorySize = $this.CastleHistory.Count
            TypeDistribution = $typeDistribution
            Weights = @{
                Beauty = $this.BeautyWeight
                Variety = $this.VarietyWeight
                Harmony = $this.HarmonyWeight
                Timing = $this.TimingWeight
            }
        }
    }
}

# ==================== TESTING FUNCTIONS ====================

function Test-AestheticReward {
    Write-Host "`n      - oo00oo - " -ForegroundColor Yellow
    Write-Host "Testing Aesthetic Reward System" -ForegroundColor Cyan
    Write-Host "      - oo00oo - `n" -ForegroundColor Yellow
    
    $reward = New-Object AestheticReward
    
    # Test 1: Single castle scoring
    Write-Host "Test 1: Individual Castle Scores" -ForegroundColor Green
    Write-Host "=" * 50
    
    $castleTypes = @("Gothic", "FairyTale", "Cathedral", "Wizard", "Palace", "Oriental", "Fortress", "Ruins")
    
    foreach ($type in $castleTypes) {
        $context = @{ CurrentCastleCount = 4 }
        $score = $reward.CalculateReward($type, $context)
        
        Write-Host ("{0,-12} | Total: {1:F2} | Beauty: {2:F2} | Variety: {3:F2} | Harmony: {4:F2} | Timing: {5:F2}" -f `
            $type, $score.TotalReward, $score.Beauty, $score.Variety, $score.Harmony, $score.Timing) -ForegroundColor Cyan
    }
    
    # Test 2: Variety testing (repetition)
    Write-Host "`nTest 2: Variety Penalty (Repeating Gothic)" -ForegroundColor Green
    Write-Host "=" * 50
    
    $reward.ResetHistory()
    
    for ($i = 1; $i -le 5; $i++) {
        $context = @{ CurrentCastleCount = 4 }
        $score = $reward.CalculateReward("Gothic", $context)
        Write-Host ("Gothic #{0} | Total: {1:F2} | Variety: {2:F2} (should decrease)" -f `
            $i, $score.TotalReward, $score.Variety) -ForegroundColor Yellow
    }
    
    # Test 3: Harmony testing
    Write-Host "`nTest 3: Harmony Between Castle Types" -ForegroundColor Green
    Write-Host "=" * 50
    
    $reward.ResetHistory()
    
    # Good combination: Gothic → Cathedral
    $context1 = @{ CurrentCastleCount = 4 }
    $score1 = $reward.CalculateReward("Gothic", $context1)
    Write-Host ("Gothic first    | Total: {0:F2}" -f $score1.TotalReward) -ForegroundColor Cyan
    
    $context2 = @{ NearbyCastles = @("Gothic"); CurrentCastleCount = 4 }
    $score2 = $reward.CalculateReward("Cathedral", $context2)
    Write-Host ("Cathedral after | Total: {0:F2} | Harmony: {1:F2} (high - Gothic+Cathedral harmonize!)" -f `
        $score2.TotalReward, $score2.Harmony) -ForegroundColor Green
    
    # Bad combination: Gothic → FairyTale
    $reward.ResetHistory()
    $score3 = $reward.CalculateReward("Gothic", $context1)
    Write-Host ("`nGothic first    | Total: {0:F2}" -f $score3.TotalReward) -ForegroundColor Cyan
    
    $context3 = @{ NearbyCastles = @("Gothic"); CurrentCastleCount = 4 }
    $score4 = $reward.CalculateReward("FairyTale", $context3)
    Write-Host ("FairyTale after | Total: {0:F2} | Harmony: {1:F2} (low - Gothic+FairyTale clash!)" -f `
        $score4.TotalReward, $score4.Harmony) -ForegroundColor Red
    
    # Test 4: Timing (crowding)
    Write-Host "`nTest 4: Timing Penalty (Crowding)" -ForegroundColor Green
    Write-Host "=" * 50
    
    $reward.ResetHistory()
    
    $crowdingLevels = @(1, 3, 5, 7, 10)
    foreach ($count in $crowdingLevels) {
        $context = @{ CurrentCastleCount = $count }
        $score = $reward.CalculateReward("Palace", $context)
        Write-Host ("{0} castles on screen | Total: {1:F2} | Timing: {2:F2}" -f `
            $count, $score.TotalReward, $score.Timing) -ForegroundColor Cyan
    }
    
    # Test 5: Sequence analysis
    Write-Host "`nTest 5: Analyze Good vs Bad Sequences" -ForegroundColor Green
    Write-Host "=" * 50
    
    # Good sequence: varied, harmonious
    $goodSequence = @("Cathedral", "Palace", "Oriental", "Wizard", "Gothic", "Fortress")
    $goodAnalysis = $reward.AnalyzeSequence($goodSequence)
    Write-Host ("Good Sequence: {0}" -f ($goodSequence -join " → ")) -ForegroundColor Green
    Write-Host ("  Average Reward: {0:F2}" -f $goodAnalysis.AverageReward) -ForegroundColor Green
    
    # Bad sequence: repetitive, clashing
    $badSequence = @("Gothic", "Gothic", "FairyTale", "Gothic", "FairyTale", "Gothic")
    $badAnalysis = $reward.AnalyzeSequence($badSequence)
    Write-Host ("`nBad Sequence: {0}" -f ($badSequence -join " → ")) -ForegroundColor Red
    Write-Host ("  Average Reward: {0:F2}" -f $badAnalysis.AverageReward) -ForegroundColor Red
    
    Write-Host "`n" ("=" * 50)
    Write-Host "✓ All tests complete!" -ForegroundColor Green
    Write-Host "      - oo00oo - `n" -ForegroundColor Yellow
}

# Run tests if executed directly
if ($MyInvocation.InvocationName -ne '.') {
    Test-AestheticReward
}