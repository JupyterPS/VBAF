<#
.SYNOPSIS
    Creates complete VBAF documentation structure
.DESCRIPTION
    Adds docs/, examples/, tests/, benchmarks/ folders alongside existing code.
    Does NOT move or modify any existing .ps1 files.
#>

# Set base path (your current working directory)
$basePath = "C:\Users\henni\OneDrive\WindowsPowerShell"
cd $basePath

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  VBAF Documentation Structure Setup" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# ============================================================================
# ROOT LEVEL FILES
# ============================================================================

Write-Host "[1/6] Creating root-level files..." -ForegroundColor Yellow

# README.md (main entry point)
if (-not (Test-Path "README.md")) {
    New-Item -ItemType File -Path "README.md" -Force | Out-Null
    Write-Host "  ✓ README.md created" -ForegroundColor Green
} else {
    Write-Host "  ℹ README.md already exists (skipped)" -ForegroundColor Gray
}

# PAPER.md (research paper)
if (-not (Test-Path "PAPER.md")) {
    New-Item -ItemType File -Path "PAPER.md" -Force | Out-Null
    Write-Host "  ✓ PAPER.md created" -ForegroundColor Green
} else {
    Write-Host "  ℹ PAPER.md already exists (skipped)" -ForegroundColor Gray
}

# LICENSE
if (-not (Test-Path "LICENSE")) {
    New-Item -ItemType File -Path "LICENSE" -Force | Out-Null
    Write-Host "  ✓ LICENSE created" -ForegroundColor Green
} else {
    Write-Host "  ℹ LICENSE already exists (skipped)" -ForegroundColor Gray
}

# CHANGELOG.md
if (-not (Test-Path "CHANGELOG.md")) {
    New-Item -ItemType File -Path "CHANGELOG.md" -Force | Out-Null
    Write-Host "  ✓ CHANGELOG.md created" -ForegroundColor Green
} else {
    Write-Host "  ℹ CHANGELOG.md already exists (skipped)" -ForegroundColor Gray
}

# .gitignore
if (-not (Test-Path ".gitignore")) {
    New-Item -ItemType File -Path ".gitignore" -Force | Out-Null
    Write-Host "  ✓ .gitignore created" -ForegroundColor Green
} else {
    Write-Host "  ℹ .gitignore already exists (skipped)" -ForegroundColor Gray
}

# ============================================================================
# DOCS/ FOLDER (Main documentation)
# ============================================================================

Write-Host "`n[2/6] Creating docs/ structure..." -ForegroundColor Yellow

# Main docs folder
New-Item -ItemType Directory -Path "docs" -Force | Out-Null
Write-Host "  ✓ docs/" -ForegroundColor Green

# Core documentation files
$docFiles = @(
    "docs\README.md",
    "docs\GettingStarted.md",
    "docs\Architecture.md",
    "docs\Theory.md",
    "docs\API-Reference.md",
    "docs\FAQ.md"
)

foreach ($file in $docFiles) {
    if (-not (Test-Path $file)) {
        New-Item -ItemType File -Path $file -Force | Out-Null
        Write-Host "  ✓ $file" -ForegroundColor Green
    }
}

# docs/papers/ (Academic papers)
New-Item -ItemType Directory -Path "docs\papers" -Force | Out-Null
New-Item -ItemType Directory -Path "docs\papers\figures" -Force | Out-Null
Write-Host "  ✓ docs/papers/" -ForegroundColor Green
Write-Host "  ✓ docs/papers/figures/" -ForegroundColor Green

$paperFiles = @(
    "docs\papers\vbaf-main-paper.md",
    "docs\papers\multi-agent-study.md",
    "docs\papers\education-evaluation.md",
    "docs\papers\README.md"
)

foreach ($file in $paperFiles) {
    if (-not (Test-Path $file)) {
        New-Item -ItemType File -Path $file -Force | Out-Null
        Write-Host "  ✓ $file" -ForegroundColor Green
    }
}

# docs/tutorials/ (Step-by-step guides)
New-Item -ItemType Directory -Path "docs\tutorials" -Force | Out-Null
Write-Host "  ✓ docs/tutorials/" -ForegroundColor Green

$tutorialFiles = @(
    "docs\tutorials\README.md",
    "docs\tutorials\01-Your-First-Neuron.md",
    "docs\tutorials\02-Building-XOR-Network.md",
    "docs\tutorials\03-Q-Learning-Agent.md",
    "docs\tutorials\04-Multi-Agent-Market.md",
    "docs\tutorials\05-Custom-Environments.md",
    "docs\tutorials\06-Using-Dashboards.md"
)

foreach ($file in $tutorialFiles) {
    if (-not (Test-Path $file)) {
        New-Item -ItemType File -Path $file -Force | Out-Null
        Write-Host "  ✓ $file" -ForegroundColor Green
    }
}

# docs/case-studies/ (Real-world applications)
New-Item -ItemType Directory -Path "docs\case-studies" -Force | Out-Null
Write-Host "  ✓ docs/case-studies/" -ForegroundColor Green

$caseStudyFiles = @(
    "docs\case-studies\README.md",
    "docs\case-studies\email-triage.md",
    "docs\case-studies\report-optimization.md",
    "docs\case-studies\resource-allocation.md",
    "docs\case-studies\castle-generation.md"
)

foreach ($file in $caseStudyFiles) {
    if (-not (Test-Path $file)) {
        New-Item -ItemType File -Path $file -Force | Out-Null
        Write-Host "  ✓ $file" -ForegroundColor Green
    }
}

# docs/teaching/ (Educational materials)
New-Item -ItemType Directory -Path "docs\teaching" -Force | Out-Null
New-Item -ItemType Directory -Path "docs\teaching\lecture-slides" -Force | Out-Null
New-Item -ItemType Directory -Path "docs\teaching\exercises" -Force | Out-Null
Write-Host "  ✓ docs/teaching/" -ForegroundColor Green

$teachingFiles = @(
    "docs\teaching\README.md",
    "docs\teaching\course-outline.md",
    "docs\teaching\semester-plan.md",
    "docs\teaching\exam-questions.md"
)

foreach ($file in $teachingFiles) {
    if (-not (Test-Path $file)) {
        New-Item -ItemType File -Path $file -Force | Out-Null
        Write-Host "  ✓ $file" -ForegroundColor Green
    }
}

# docs/dev/ (Developer documentation)
New-Item -ItemType Directory -Path "docs\dev" -Force | Out-Null
Write-Host "  ✓ docs/dev/" -ForegroundColor Green

$devFiles = @(
    "docs\dev\README.md",
    "docs\dev\contributing.md",
    "docs\dev\coding-standards.md",
    "docs\dev\testing-guide.md",
    "docs\dev\release-process.md"
)

foreach ($file in $devFiles) {
    if (-not (Test-Path $file)) {
        New-Item -ItemType File -Path $file -Force | Out-Null
        Write-Host "  ✓ $file" -ForegroundColor Green
    }
}

# ============================================================================
# EXAMPLES/ FOLDER (Working code examples)
# ============================================================================

Write-Host "`n[3/6] Creating examples/ structure..." -ForegroundColor Yellow

New-Item -ItemType Directory -Path "examples" -Force | Out-Null
Write-Host "  ✓ examples/" -ForegroundColor Green

$exampleFolders = @(
    "examples\01-XOR-Network",
    "examples\02-Castle-Learning",
    "examples\03-Market-Simulation",
    "examples\04-Learning-Dashboard",
    "examples\05-Validation-Dashboard",
    "examples\06-Custom-Agent"
)

foreach ($folder in $exampleFolders) {
    New-Item -ItemType Directory -Path $folder -Force | Out-Null
    New-Item -ItemType File -Path "$folder\README.md" -Force | Out-Null
    Write-Host "  ✓ $folder/" -ForegroundColor Green
}

# ============================================================================
# TESTS/ FOLDER (Test suite)
# ============================================================================

Write-Host "`n[4/6] Creating tests/ structure..." -ForegroundColor Yellow

New-Item -ItemType Directory -Path "tests" -Force | Out-Null
Write-Host "  ✓ tests/" -ForegroundColor Green

$testFiles = @(
    "tests\README.md",
    "tests\Core.Tests.ps1",
    "tests\RL.Tests.ps1",
    "tests\Business.Tests.ps1",
    "tests\Visualization.Tests.ps1",
    "tests\Integration.Tests.ps1"
)

foreach ($file in $testFiles) {
    if (-not (Test-Path $file)) {
        New-Item -ItemType File -Path $file -Force | Out-Null
        Write-Host "  ✓ $file" -ForegroundColor Green
    }
}

# ============================================================================
# BENCHMARKS/ FOLDER (Performance data)
# ============================================================================

Write-Host "`n[5/6] Creating benchmarks/ structure..." -ForegroundColor Yellow

New-Item -ItemType Directory -Path "benchmarks" -Force | Out-Null
New-Item -ItemType Directory -Path "benchmarks\data" -Force | Out-Null
Write-Host "  ✓ benchmarks/" -ForegroundColor Green
Write-Host "  ✓ benchmarks/data/" -ForegroundColor Green

$benchmarkFiles = @(
    "benchmarks\README.md",
    "benchmarks\xor-convergence.md",
    "benchmarks\agent-learning-curves.md",
    "benchmarks\performance-comparison.md"
)

foreach ($file in $benchmarkFiles) {
    if (-not (Test-Path $file)) {
        New-Item -ItemType File -Path $file -Force | Out-Null
        Write-Host "  ✓ $file" -ForegroundColor Green
    }
}

# ============================================================================
# ASSETS/ FOLDER (Images, diagrams, media)
# ============================================================================

Write-Host "`n[6/6] Creating assets/ structure..." -ForegroundColor Yellow

New-Item -ItemType Directory -Path "assets" -Force | Out-Null
New-Item -ItemType Directory -Path "assets\images" -Force | Out-Null
New-Item -ItemType Directory -Path "assets\diagrams" -Force | Out-Null
New-Item -ItemType Directory -Path "assets\screenshots" -Force | Out-Null
Write-Host "  ✓ assets/" -ForegroundColor Green
Write-Host "  ✓ assets/images/" -ForegroundColor Green
Write-Host "  ✓ assets/diagrams/" -ForegroundColor Green
Write-Host "  ✓ assets/screenshots/" -ForegroundColor Green

# ============================================================================
# VERIFICATION
# ============================================================================

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Verification" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Count created items
$totalFolders = (Get-ChildItem -Path $basePath -Directory -Recurse | Where-Object { $_.FullName -like "*docs*" -or $_.FullName -like "*examples*" -or $_.FullName -like "*tests*" -or $_.FullName -like "*benchmarks*" -or $_.FullName -like "*assets*" }).Count
$totalFiles = (Get-ChildItem -Path $basePath -File -Recurse | Where-Object { $_.FullName -like "*docs*" -or $_.FullName -like "*examples*" -or $_.FullName -like "*tests*" -or $_.FullName -like "*benchmarks*" -or $_.FullName -like "*.md" -or $_.FullName -like "*LICENSE*" -or $_.FullName -like "*.gitignore" }).Count

Write-Host "✓ Structure created successfully!" -ForegroundColor Green
Write-Host "  Folders created: $totalFolders" -ForegroundColor Cyan
Write-Host "  Files created: $totalFiles" -ForegroundColor Cyan

# Verify key folders exist
Write-Host "`nKey folders:" -ForegroundColor Yellow
$keyFolders = @("docs", "docs\papers", "docs\tutorials", "docs\case-studies", "docs\teaching", "examples", "tests", "benchmarks", "assets")
foreach ($folder in $keyFolders) {
    if (Test-Path $folder) {
        Write-Host "  ✓ $folder" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $folder (MISSING!)" -ForegroundColor Red
    }
}

# Check that code files were NOT moved
Write-Host "`nVerifying existing code (should be unchanged):" -ForegroundColor Yellow
$codeFiles = @("VBAF.LoadAll.ps1", "VBAF.psd1", "VBAF.Core.AllClasses.ps1", "VBAF.RL.QTable.ps1")
foreach ($file in $codeFiles) {
    if (Test-Path $file) {
        Write-Host "  ✓ $file (still in place)" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $file (MOVED OR MISSING!)" -ForegroundColor Red
    }
}

# ============================================================================
# FINAL STRUCTURE DISPLAY
# ============================================================================

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Final Directory Structure" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "VBAF/" -ForegroundColor White
Write-Host "├── README.md                  (Main entry point)" -ForegroundColor Gray
Write-Host "├── PAPER.md                   (Research paper)" -ForegroundColor Gray
Write-Host "├── LICENSE" -ForegroundColor Gray
Write-Host "├── CHANGELOG.md" -ForegroundColor Gray
Write-Host "├── .gitignore" -ForegroundColor Gray
Write-Host "│" -ForegroundColor Gray
Write-Host "├── VBAF.LoadAll.ps1           (Your existing code - UNCHANGED)" -ForegroundColor Green
Write-Host "├── VBAF.psd1                  (Module manifest - UNCHANGED)" -ForegroundColor Green
Write-Host "├── VBAF.*.ps1                 (All your .ps1 files - UNCHANGED)" -ForegroundColor Green
Write-Host "│" -ForegroundColor Gray
Write-Host "├── docs/                      (Documentation)" -ForegroundColor Yellow
Write-Host "│   ├── README.md" -ForegroundColor Gray
Write-Host "│   ├── GettingStarted.md" -ForegroundColor Gray
Write-Host "│   ├── Architecture.md" -ForegroundColor Gray
Write-Host "│   ├── Theory.md" -ForegroundColor Gray
Write-Host "│   ├── API-Reference.md" -ForegroundColor Gray
Write-Host "│   ├── papers/                (Research papers)" -ForegroundColor Yellow
Write-Host "│   ├── tutorials/             (Step-by-step guides)" -ForegroundColor Yellow
Write-Host "│   ├── case-studies/          (Real-world examples)" -ForegroundColor Yellow
Write-Host "│   ├── teaching/              (Educational materials)" -ForegroundColor Yellow
Write-Host "│   └── dev/                   (Developer docs)" -ForegroundColor Yellow
Write-Host "│" -ForegroundColor Gray
Write-Host "├── examples/                  (Working code examples)" -ForegroundColor Yellow
Write-Host "│   ├── 01-XOR-Network/" -ForegroundColor Gray
Write-Host "│   ├── 02-Castle-Learning/" -ForegroundColor Gray
Write-Host "│   └── ..." -ForegroundColor Gray
Write-Host "│" -ForegroundColor Gray
Write-Host "├── tests/                     (Test suite)" -ForegroundColor Yellow
Write-Host "│   ├── Core.Tests.ps1" -ForegroundColor Gray
Write-Host "│   └── ..." -ForegroundColor Gray
Write-Host "│" -ForegroundColor Gray
Write-Host "├── benchmarks/                (Performance data)" -ForegroundColor Yellow
Write-Host "│   └── data/" -ForegroundColor Gray
Write-Host "│" -ForegroundColor Gray
Write-Host "└── assets/                    (Images, diagrams)" -ForegroundColor Yellow
Write-Host "    ├── images/" -ForegroundColor Gray
Write-Host "    ├── diagrams/" -ForegroundColor Gray
Write-Host "    └── screenshots/" -ForegroundColor Gray

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Next Steps" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "1. Test that your code still works:" -ForegroundColor Yellow
Write-Host "   . .\VBAF.LoadAll.ps1" -ForegroundColor White
Write-Host ""
Write-Host "2. Fill in key documentation files:" -ForegroundColor Yellow
Write-Host "   • README.md (main project description)" -ForegroundColor White
Write-Host "   • docs/README.md (documentation hub)" -ForegroundColor White
Write-Host "   • docs/papers/vbaf-main-paper.md (research paper)" -ForegroundColor White
Write-Host ""
Write-Host "3. Add content to LICENSE:" -ForegroundColor Yellow
Write-Host "   • MIT License recommended for academic projects" -ForegroundColor White
Write-Host ""

Write-Host "✨ VBAF documentation structure is ready!" -ForegroundColor Green
Write-Host ""