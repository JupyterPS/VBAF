#Requires -Version 5.1

<#
.SYNOPSIS
    Experience Replay Memory Buffer
.DESCRIPTION
    Stores and samples past experiences for reinforcement learning.
    Breaks correlation in sequential experiences and improves data efficiency.
.NOTES
    Part of VBAF - Reinforcement Learning Module
    FIXED: Proper Add() method implementation
#>

class ExperienceReplay {
    # Properties
    [System.Collections.ArrayList]$Memory
    [int]$MaxSize
    
    # Constructor
    ExperienceReplay([int]$maxSize) {
        $this.Memory = New-Object System.Collections.ArrayList
        $this.MaxSize = $maxSize
    }
    
    # Add experience to memory
    [void] Add([hashtable]$experience) {
        # Add to memory
        $this.Memory.Add($experience) | Out-Null
        
        # If over capacity, remove oldest
        if ($this.Memory.Count -gt $this.MaxSize) {
            $this.Memory.RemoveAt(0)
        }
    }
    
    # Sample random batch
    [hashtable[]] Sample([int]$batchSize) {
        if ($this.Memory.Count -eq 0) {
            return @()
        }
        
        # Don't sample more than we have
        $actualSize = [Math]::Min($batchSize, $this.Memory.Count)
        
        $samples = New-Object System.Collections.ArrayList
        $usedIndices = @{}
        
        for ($i = 0; $i -lt $actualSize; $i++) {
            # Get random unique index
            $index = Get-Random -Minimum 0 -Maximum $this.Memory.Count
            
            # If already used, try again (simple collision handling)
            $attempts = 0
            while ($usedIndices.ContainsKey($index) -and $attempts -lt 10) {
                $index = Get-Random -Minimum 0 -Maximum $this.Memory.Count
                $attempts++
            }
            
            $usedIndices[$index] = $true
            $samples.Add($this.Memory[$index]) | Out-Null
        }
        
        return $samples.ToArray()
    }
    
    # Get memory size
    [int] Size() {
        return $this.Memory.Count
    }
    
    # Clear all memories
    [void] Clear() {
        $this.Memory.Clear()
    }
    
    # Check if memory is full
    [bool] IsFull() {
        return $this.Memory.Count -ge $this.MaxSize
    }
}