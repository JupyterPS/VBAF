#Requires -Version 5.1
# VBAF.Business.Dashboard-Demo.ps1
# Dashboard 2
<#
.SYNOPSIS
    Market Dashboard Demo - 4 Company Simulation
.DESCRIPTION
    Real-time visualization of multi-agent market simulation.
    Shows market share, profit trends, economic indicators, and learning progress.
.NOTES
    Part of VBAF (Visual Business Automation Framework)
    Week 7 - Market Dashboard Visualization
#>

# Set base path
$basePath = $PSScriptRoot

Write-Host "=== VBAF Market Dashboard ===" -ForegroundColor Cyan

# Load dependencies in correct order
Write-Host "Loading dependencies..." -ForegroundColor Yellow

. "$basePath\VBAF.RL.QLearningAgent.ps1"
. "$basePath\VBAF.RL.ExperienceReplay.ps1"
. "$basePath\VBAF.Business.CompanyState.ps1"
. "$basePath\VBAF.Business.BusinessAction.ps1"
. "$basePath\VBAF.Business.CompanyAgent.ps1"
. "$basePath\VBAF.Business.MarketEnvironment.ps1"
. "$basePath\VBAF.Visualization.MarketDashboard.ps1"

Write-Host "All dependencies loaded successfully!" -ForegroundColor Green

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create market with 4 companies
Write-Host "`nInitializing market environment..." -ForegroundColor Yellow
$market = New-Object MarketEnvironment

# Initialize companies with starting capital ($100M each)
$startingCapital = 100000000  # $100M

Write-Host "Creating companies..." -ForegroundColor Yellow
$novo = New-Object CompanyAgent -ArgumentList "Novo Nordisk", "Pharma", $startingCapital
Write-Host "  ✓ Novo Nordisk created" -ForegroundColor Green

$wine = New-Object CompanyAgent -ArgumentList "Wine Co", "Wine", $startingCapital
Write-Host "  ✓ Wine Co created" -ForegroundColor Green

$bank = New-Object CompanyAgent -ArgumentList "Commerce Bank", "Banking", $startingCapital
Write-Host "  ✓ Commerce Bank created" -ForegroundColor Green

$ai = New-Object CompanyAgent -ArgumentList "AI Corp", "Technology", $startingCapital
Write-Host "  ✓ AI Corp created" -ForegroundColor Green

# Add companies to market
Write-Host "`nAdding companies to market..." -ForegroundColor Yellow
$market.AddCompany($novo)
$market.AddCompany($wine)
$market.AddCompany($bank)
$market.AddCompany($ai)

Write-Host "`nMarket initialized with 4 companies" -ForegroundColor Green
Write-Host "Starting capital: `$$($startingCapital / 1000000)M each" -ForegroundColor Cyan

Write-Host "`n=== Dashboard Controls ===" -ForegroundColor Yellow
Write-Host "  ▶  Play    - Auto-run simulation" -ForegroundColor Gray
Write-Host "  ⏭ Step    - Advance one quarter manually" -ForegroundColor Gray
Write-Host "  🔄 Reset   - Start over from beginning" -ForegroundColor Gray
Write-Host "  ━━━━━━━━━  Speed slider (1x-10x)" -ForegroundColor Gray
Write-Host "  💾 Export  - Save data to CSV" -ForegroundColor Gray

Write-Host "`nLaunching dashboard..." -ForegroundColor Cyan

# Create and show dashboard
$dashboard = New-Object MarketDashboard -ArgumentList $market
$dashboard.Show()

Write-Host "`nDashboard closed." -ForegroundColor Yellow
<#
      VBAF.Business.CompanyAgent.ps1          
      VBAF.Business.CompanyPanel.ps1          
      VBAF.Business.Dashboard-Demo.ps1 
      VBAF.Visualization.MarketDashboard.ps1
#>