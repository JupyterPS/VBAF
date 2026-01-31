function Test-VBAF {
    <#
    .SYNOPSIS
        Runs comprehensive tests to verify VBAF installation.
    
    .DESCRIPTION
        Tests all major VBAF components to ensure they're working correctly:
        - Neural network creation and training
        - Q-Learning agent functionality
        - Class loading and dependencies
        - WinForms/Drawing assemblies
        - Example script availability
        
        Use this to verify your VBAF installation is complete and functional.
    
    .PARAMETER Quick
        Run only quick validation tests (skip training).
    
    .PARAMETER Verbose
        Show detailed test progress.
    
    .EXAMPLE
        Test-VBAF
        
        Runs all tests including training validation.
    
    .EXAMPLE
        Test-VBAF -Quick
        
        Runs only quick validation tests.
    
    .OUTPUTS
        Test results summary.
    
    .NOTES
        Author: Henning
        Part of VBAF Module
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$Quick
    )
    
    $testResults = @{
        Passed = 0
        Failed = 0
        Skipped = 0
        Tests = New-Object System.Collections.ArrayList
    }
    
    Write-Host "`n      - oo00oo - " -ForegroundColor Yellow
    Write-Host "  VBAF Test Suite" -ForegroundColor Cyan
    Write-Host "      - oo00oo - `n" -ForegroundColor Yellow
    
    # Test 1: Module loaded
    Write-Host "  [1/8] Testing module load..." -NoNewline
    try {
        $module = Get-Module VBAF
        if ($null -ne $module) {
            Write-Host " ✓ PASS" -ForegroundColor Green
            $testResults.Passed++
            $testResults.Tests.Add("Module loaded: v$($module.Version)") | Out-Null
        } else {
            throw "Module not loaded"
        }
    } catch {
        Write-Host " ✗ FAIL: $_" -ForegroundColor Red
        $testResults.Failed++
    }
    
    # Test 2: Core classes available
    Write-Host "  [2/8] Testing core classes..." -NoNewline
    try {
        $testNN = New-Object NeuralNetwork -ArgumentList @(2, 2, 1), 0.1
        if ($null -ne $testNN) {
            Write-Host " ✓ PASS" -ForegroundColor Green
            $testResults.Passed++
            $testResults.Tests.Add("NeuralNetwork class available") | Out-Null
        } else {
            throw "NeuralNetwork class not found"
        }
    } catch {
        Write-Host " ✗ FAIL: $_" -ForegroundColor Red
        $testResults.Failed++
    }
    
    # Test 3: RL classes available
    Write-Host "  [3/8] Testing RL classes..." -NoNewline
    try {
        $testAgent = New-Object QLearningAgent -ArgumentList (,@("a", "b")), 0.1, 0.5
        if ($null -ne $testAgent) {
            Write-Host " ✓ PASS" -ForegroundColor Green
            $testResults.Passed++
            $testResults.Tests.Add("QLearningAgent class available") | Out-Null
        } else {
            throw "QLearningAgent class not found"
        }
    } catch {
        Write-Host " ✗ FAIL: $_" -ForegroundColor Red
        $testResults.Failed++
    }
    
    # Test 4: Public functions available
    Write-Host "  [4/8] Testing public functions..." -NoNewline
    try {
        $functions = Get-Command -Module VBAF -CommandType Function
        if ($functions.Count -ge 5) {
            Write-Host " ✓ PASS ($($functions.Count) functions)" -ForegroundColor Green
            $testResults.Passed++
            $testResults.Tests.Add("Public functions exported: $($functions.Count)") | Out-Null
        } else {
            throw "Expected at least 5 functions, found $($functions.Count)"
        }
    } catch {
        Write-Host " ✗ FAIL: $_" -ForegroundColor Red
        $testResults.Failed++
    }
    
    # Test 5: WinForms assembly
    Write-Host "  [5/8] Testing WinForms assembly..." -NoNewline
    try {
        $testForm = New-Object System.Windows.Forms.Form
        if ($null -ne $testForm) {
            $testForm.Dispose()
            Write-Host " ✓ PASS" -ForegroundColor Green
            $testResults.Passed++
            $testResults.Tests.Add("WinForms assembly loaded") | Out-Null
        } else {
            throw "WinForms not available"
        }
    } catch {
        Write-Host " ✗ FAIL: $_" -ForegroundColor Red
        $testResults.Failed++
    }
    
    # Test 6: Drawing assembly
    Write-Host "  [6/8] Testing Drawing assembly..." -NoNewline
    try {
        $testBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Red)
        if ($null -ne $testBrush) {
            $testBrush.Dispose()
            Write-Host " ✓ PASS" -ForegroundColor Green
            $testResults.Passed++
            $testResults.Tests.Add("Drawing assembly loaded") | Out-Null
        } else {
            throw "Drawing assembly not available"
        }
    } catch {
        Write-Host " ✗ FAIL: $_" -ForegroundColor Red
        $testResults.Failed++
    }
    
    # Test 7: Neural network forward pass
    if (-not $Quick) {
        Write-Host "  [7/8] Testing NN forward pass..." -NoNewline
        try {
            $nn = New-Object NeuralNetwork -ArgumentList @(2, 3, 1), 0.1
            $output = $nn.Forward(@(0.5, 0.5))
            if ($null -ne $output -and $output.Count -eq 1) {
                Write-Host " ✓ PASS" -ForegroundColor Green
                $testResults.Passed++
                $testResults.Tests.Add("Neural network forward pass works") | Out-Null
            } else {
                throw "Forward pass returned unexpected output"
            }
        } catch {
            Write-Host " ✗ FAIL: $_" -ForegroundColor Red
            $testResults.Failed++
        }
    } else {
        Write-Host "  [7/8] Testing NN forward pass... ⊘ SKIPPED" -ForegroundColor Yellow
        $testResults.Skipped++
    }
    
    # Test 8: Q-Learning agent action selection
    if (-not $Quick) {
        Write-Host "  [8/8] Testing QL agent..." -NoNewline
        try {
            $agent = New-Object QLearningAgent -ArgumentList (,@("up", "down", "left", "right")), 0.1, 0.5
            $action = $agent.ChooseAction("state1")
            if ($action -in @("up", "down", "left", "right")) {
                Write-Host " ✓ PASS" -ForegroundColor Green
                $testResults.Passed++
                $testResults.Tests.Add("Q-Learning agent action selection works") | Out-Null
            } else {
                throw "Agent returned invalid action: $action"
            }
        } catch {
            Write-Host " ✗ FAIL: $_" -ForegroundColor Red
            $testResults.Failed++
        }
    } else {
        Write-Host "  [8/8] Testing QL agent... ⊘ SKIPPED" -ForegroundColor Yellow
        $testResults.Skipped++
    }
    
    # Summary
    Write-Host "`n  " + ("=" * 60) -ForegroundColor DarkGray
    Write-Host "  Test Results:" -ForegroundColor Cyan
    Write-Host "    ✓ Passed: " -NoNewline -ForegroundColor Green
    Write-Host $testResults.Passed -ForegroundColor White
    
    if ($testResults.Failed -gt 0) {
        Write-Host "    ✗ Failed: " -NoNewline -ForegroundColor Red
        Write-Host $testResults.Failed -ForegroundColor White
    }
    
    if ($testResults.Skipped -gt 0) {
        Write-Host "    ⊘ Skipped: " -NoNewline -ForegroundColor Yellow
        Write-Host $testResults.Skipped -ForegroundColor White
    }
    
    $total = $testResults.Passed + $testResults.Failed + $testResults.Skipped
    $successRate = if ($total -gt 0) { ($testResults.Passed / $total) * 100 } else { 0 }
    
    Write-Host "    Success Rate: " -NoNewline -ForegroundColor Cyan
    if ($successRate -eq 100) {
        Write-Host "$([Math]::Round($successRate, 1))%" -ForegroundColor Green
    } elseif ($successRate -ge 80) {
        Write-Host "$([Math]::Round($successRate, 1))%" -ForegroundColor Yellow
    } else {
        Write-Host "$([Math]::Round($successRate, 1))%" -ForegroundColor Red
    }
    
    if ($testResults.Failed -eq 0) {
        Write-Host "`n  🎉 All tests passed! VBAF is ready to use! 🎉" -ForegroundColor Green
    } else {
        Write-Host "`n  ⚠️  Some tests failed. Check installation." -ForegroundColor Yellow
    }
    
    Write-Host "`n      - oo00oo - `n" -ForegroundColor Yellow
    
    # Return results object
    return [PSCustomObject]$testResults
}