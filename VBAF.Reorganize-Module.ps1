# VBAF.Reorganize-Module.ps1
#Requires -Version 5.1

<#
.SYNOPSIS
    Reorganizes existing VBAF files into proper module structure.

.DESCRIPTION
    Creates the VBAF module folder structure and moves/copies existing files
    into their correct locations. Creates backups before moving files.
    
    This script prepares your VBAF files for module packaging.

.PARAMETER SourcePath
    Path containing your current VBAF files.
    Default: C:\Users\henni\OneDrive\WindowsPowerShell

.PARAMETER TargetPath
    Path where VBAF module should be created.
    Default: C:\Users\henni\OneDrive\WindowsPowerShell\VBAF

.PARAMETER Copy
    Copy files instead of moving them (keeps originals).

.PARAMETER CreateBackup
    Create backup of existing files before reorganizing.
    Default: $true

.EXAMPLE
    .\Reorganize-VBAFModule.ps1
    
    Reorganizes files with default paths.

.EXAMPLE
    .\Reorganize-VBAFModule.ps1 -Copy
    
    Copies files (keeps originals intact).

.NOTES
    Author: Henning
    Part of VBAF Module Setup
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$SourcePath = "C:\Users\henni\OneDrive\WindowsPowerShell",
    
    [Parameter(Mandatory = $false)]
    [string]$TargetPath = "C:\Users\henni\OneDrive\WindowsPowerShell\VBAF",
    
    [Parameter(Mandatory = $false)]
    [switch]$Copy,
    
    [Parameter(Mandatory = $false)]
    [bool]$CreateBackup = $true
)

Write-Host "`n      - oo00oo - " -ForegroundColor Yellow
Write-Host "  VBAF Module Reorganization Script" -ForegroundColor Cyan
Write-Host "      - oo00oo - `n" -ForegroundColor Yellow

Write-Host "  Source: $SourcePath" -ForegroundColor White
Write-Host "  Target: $TargetPath" -ForegroundColor White
Write-Host "  Mode: " -NoNewline -ForegroundColor White
if ($Copy) {
    Write-Host "COPY (originals preserved)" -ForegroundColor Green
} else {
    Write-Host "MOVE (originals will be moved)" -ForegroundColor Yellow
}
Write-Host ""

# Confirm before proceeding
$confirmation = Read-Host "  Proceed with reorganization? (Y/N)"
if ($confirmation -ne 'Y' -and $confirmation -ne 'y') {
    Write-Host "  Operation cancelled." -ForegroundColor Yellow
    return
}

# ==================== CREATE BACKUP ====================
if ($CreateBackup -and -not $Copy) {
    Write-Host "`n  [BACKUP] Creating backup..." -ForegroundColor Cyan
    
    $backupPath = "$SourcePath\VBAF_Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    
    try {
        New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
        
        # Backup all VBAF.* files
        $vbafFiles = Get-ChildItem -Path $SourcePath -Filter "VBAF.*.ps1"
        foreach ($file in $vbafFiles) {
            Copy-Item -Path $file.FullName -Destination $backupPath -Force
        }
        
        Write-Host "    ✓ Backup created: $backupPath" -ForegroundColor Green
        Write-Host "    ✓ Backed up $($vbafFiles.Count) files" -ForegroundColor Green
    } catch {
        Write-Warning "Failed to create backup: $_"
        $continueAnyway = Read-Host "  Continue without backup? (Y/N)"
        if ($continueAnyway -ne 'Y' -and $continueAnyway -ne 'y') {
            return
        }
    }
}

# ==================== CREATE FOLDER STRUCTURE ====================
Write-Host "`n  [STRUCTURE] Creating folder structure..." -ForegroundColor Cyan

$folders = @(
    "$TargetPath",
    "$TargetPath\Core",
    "$TargetPath\RL",
    "$TargetPath\Business",
    "$TargetPath\Art",
    "$TargetPath\Visualization",
    "$TargetPath\Public",
    "$TargetPath\Examples",
    "$TargetPath\Tests",
    "$TargetPath\Docs"
)

foreach ($folder in $folders) {
    try {
        if (-not (Test-Path $folder)) {
            New-Item -ItemType Directory -Path $folder -Force | Out-Null
            Write-Host "    ✓ Created: $folder" -ForegroundColor Green
        } else {
            Write-Host "    • Exists: $folder" -ForegroundColor Gray
        }
    } catch {
        Write-Error "Failed to create folder $folder : $_"
    }
}

# ==================== FILE MAPPING ====================
Write-Host "`n  [MAPPING] Organizing files by category..." -ForegroundColor Cyan

# Define file mappings (source filename -> target location)
$fileMap = @{
    # Core files
    'VBAF.Core.AllClasses.ps1' = 'Core'
    'VBAF.Core.Activation.ps1' = 'Core'
    'VBAF.Core.Neuron.ps1' = 'Core'
    'VBAF.Core.Layer.ps1' = 'Core'
    'VBAF.Core.NeuralNetwork.ps1' = 'Core'
    'VBAF.Core.LossFunction.ps1' = 'Core'
    
    # RL files
    'VBAF.RL.QTable.ps1' = 'RL'
    'VBAF.RL.ExperienceReplay.ps1' = 'RL'
    'VBAF.RL.QLearningAgent.ps1' = 'RL'
    'VBAF.RL.RewardShaping.ps1' = 'RL'
    
    # Business files
    'VBAF.Business.CompanyAgent.ps1' = 'Business'
    'VBAF.Business.CompanyState.ps1' = 'Business'
    'VBAF.Business.BusinessAction.ps1' = 'Business'
    'VBAF.Business.MarketEnvironment.ps1' = 'Business'
    'VBAF.Business.EconomicModel.ps1' = 'Business'
    
    # Art files
    'VBAF.Art.AestheticReward.ps1' = 'Art'
    'VBAF.Art.CastleCompetition.ps1' = 'Art'
    'VBAF.Art.Show20Agent.ps1' = 'Art'
    'VBAF.Art.Show20-QLearning.ps1' = 'Art'
    'VBAF.Art.CastleRenderer.ps1' = 'Art'
    
    # Visualization files
    'VBAF.Visualization.LearningDashboard.ps1' = 'Visualization'
    'VBAF.Visualization.GraphRenderer.ps1' = 'Visualization'
    'VBAF.Visualization.MetricsCollector.ps1' = 'Visualization'
    'VBAF.Visualization.MarketDashboard.ps1' = 'Visualization'
    
    # Example files (go to Examples folder)
    'VBAF.Core.Example-XOR.ps1' = 'Examples'
    'VBAF.Core.Test-ValidationDashboard.ps1' = 'Examples'
    'VBAF.RL.Example-CastleLearning.ps1' = 'Examples'
    'VBAF.RL.Example-GridWorld.ps1' = 'Examples'
    'VBAF.Company.TestLearning.ps1' = 'Examples'
    'VBAF.Business.Test.CompanyMarket.ps1' = 'Examples'
    'VBAF.Business.Dashboard-Demo.ps1' = 'Examples'
    'VBAF.Visualization.Example-Dashboard.ps1' = 'Examples'
    
    # Test files
    'VBAF.Core.Test-NeuralNetwork.ps1' = 'Tests'
    'VBAF.RL.Test-QLearning.ps1' = 'Tests'
    'VBAF.Business.Test-Market.ps1' = 'Tests'
}

# ==================== MOVE/COPY FILES ====================
Write-Host "`n  [TRANSFER] Moving files to new structure..." -ForegroundColor Cyan

$movedCount = 0
$copiedCount = 0
$notFoundCount = 0

foreach ($fileName in $fileMap.Keys) {
    $sourcePath = Join-Path $SourcePath $fileName
    $targetFolder = $fileMap[$fileName]
    $targetFilePath = Join-Path "$TargetPath\$targetFolder" $fileName
    
    if (Test-Path $sourcePath) {
        try {
            if ($Copy) {
                Copy-Item -Path $sourcePath -Destination $targetFilePath -Force
                Write-Host "    ✓ Copied: $fileName → $targetFolder\" -ForegroundColor Green
                $copiedCount++
            } else {
                Move-Item -Path $sourcePath -Destination $targetFilePath -Force
                Write-Host "    ✓ Moved: $fileName → $targetFolder\" -ForegroundColor Green
                $movedCount++
            }
        } catch {
            Write-Warning "Failed to process $fileName : $_"
        }
    } else {
        Write-Host "    ⊘ Not found: $fileName" -ForegroundColor DarkGray
        $notFoundCount++
    }
}

# ==================== HANDLE ALLCLASSES.PS1 ====================
Write-Host "`n  [SPECIAL] Processing AllClasses.ps1..." -ForegroundColor Cyan

$allClassesPath = Join-Path "$TargetPath\Core" "VBAF.Core.AllClasses.ps1"

if (Test-Path $allClassesPath) {
    Write-Host "    • AllClasses.ps1 found in Core/" -ForegroundColor Yellow
    Write-Host "    • This file may need to be split into individual class files" -ForegroundColor Yellow
    Write-Host "    • Or update module loader to source this file" -ForegroundColor Yellow
} else {
    Write-Host "    ⊘ AllClasses.ps1 not found - you may need to create individual class files" -ForegroundColor Gray
}

# ==================== CREATE PUBLIC FUNCTIONS NOTICE ====================
Write-Host "`n  [PUBLIC] Public API functions..." -ForegroundColor Cyan

$publicFunctions = @(
    'VBAF.Public.New-NeuralNetwork.ps1',
    'VBAF.Public.New-Agent.ps1',
    'VBAF.Public.Get-Version.ps1',
    'VBAF.Public.Get-Examples.ps1',
    'VBAF.Public.Start-CastleCompetition.ps1',
    'VBAF.Public.Test-Module.ps1'
)

Write-Host "    The following public functions should be in Public/ folder:" -ForegroundColor White
foreach ($func in $publicFunctions) {
    $funcPath = Join-Path "$TargetPath\Public" $func
    if (Test-Path $funcPath) {
        Write-Host "    ✓ Found: $func" -ForegroundColor Green
    } else {
        Write-Host "    ⊘ Missing: $func (create this file)" -ForegroundColor Yellow
    }
}

# ==================== CREATE MODULE FILES NOTICE ====================
Write-Host "`n  [MODULE] Module definition files..." -ForegroundColor Cyan

$moduleFiles = @(
    'VBAF.psd1',
    'VBAF.psm1'
)

Write-Host "    The following files should be in VBAF\ root:" -ForegroundColor White
foreach ($file in $moduleFiles) {
    $filePath = Join-Path $TargetPath $file
    if (Test-Path $filePath) {
        Write-Host "    ✓ Found: $file" -ForegroundColor Green
    } else {
        Write-Host "    ⊘ Missing: $file (create this file)" -ForegroundColor Yellow
    }
}

# ==================== SUMMARY ====================
Write-Host "`n  " + ("=" * 70) -ForegroundColor DarkGray
Write-Host "  REORGANIZATION SUMMARY" -ForegroundColor Cyan
Write-Host "  " + ("=" * 70) -ForegroundColor DarkGray

if ($Copy) {
    Write-Host "    Files copied: $copiedCount" -ForegroundColor Green
} else {
    Write-Host "    Files moved: $movedCount" -ForegroundColor Green
}
Write-Host "    Files not found: $notFoundCount" -ForegroundColor Gray

Write-Host "`n  Folder Structure Created:" -ForegroundColor Cyan
Write-Host "    $TargetPath\" -ForegroundColor White
Write-Host "      ├── Core/           ($((Get-ChildItem "$TargetPath\Core" -ErrorAction SilentlyContinue).Count) files)" -ForegroundColor Gray
Write-Host "      ├── RL/             ($((Get-ChildItem "$TargetPath\RL" -ErrorAction SilentlyContinue).Count) files)" -ForegroundColor Gray
Write-Host "      ├── Business/       ($((Get-ChildItem "$TargetPath\Business" -ErrorAction SilentlyContinue).Count) files)" -ForegroundColor Gray
Write-Host "      ├── Art/            ($((Get-ChildItem "$TargetPath\Art" -ErrorAction SilentlyContinue).Count) files)" -ForegroundColor Gray
Write-Host "      ├── Visualization/  ($((Get-ChildItem "$TargetPath\Visualization" -ErrorAction SilentlyContinue).Count) files)" -ForegroundColor Gray
Write-Host "      ├── Public/         ($((Get-ChildItem "$TargetPath\Public" -ErrorAction SilentlyContinue).Count) files)" -ForegroundColor Gray
Write-Host "      ├── Examples/       ($((Get-ChildItem "$TargetPath\Examples" -ErrorAction SilentlyContinue).Count) files)" -ForegroundColor Gray
Write-Host "      ├── Tests/          ($((Get-ChildItem "$TargetPath\Tests" -ErrorAction SilentlyContinue).Count) files)" -ForegroundColor Gray
Write-Host "      └── Docs/           ($((Get-ChildItem "$TargetPath\Docs" -ErrorAction SilentlyContinue).Count) files)" -ForegroundColor Gray

Write-Host "`n  NEXT STEPS:" -ForegroundColor Yellow
Write-Host "    1. Save VBAF.psd1 to $TargetPath\" -ForegroundColor White
Write-Host "    2. Save VBAF.psm1 to $TargetPath\" -ForegroundColor White
Write-Host "    3. Save public functions to $TargetPath\Public\" -ForegroundColor White
Write-Host "    4. Update file paths in scripts (remove hardcoded base paths)" -ForegroundColor White
Write-Host "    5. Test the module: Import-Module $TargetPath\VBAF.psd1 -Verbose" -ForegroundColor White

if ($CreateBackup -and -not $Copy) {
    Write-Host "`n  ℹ️  Backup location: $backupPath" -ForegroundColor Cyan
}

Write-Host "`n      - oo00oo - " -ForegroundColor Yellow
Write-Host "  ✓ Reorganization Complete!" -ForegroundColor Green
Write-Host "      - oo00oo - `n" -ForegroundColor Yellow

# Return summary object
[PSCustomObject]@{
    SourcePath = $SourcePath
    TargetPath = $TargetPath
    FilesMoved = if ($Copy) { 0 } else { $movedCount }
    FilesCopied = if ($Copy) { $copiedCount } else { 0 }
    FilesNotFound = $notFoundCount
    BackupPath = if ($CreateBackup -and -not $Copy) { $backupPath } else { $null }
}