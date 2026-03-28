# HQ Enterprise Dashboard V3 - PURE GM
# 100% Game Machine Architecture
# Zero V1 Compatibility Code
# ========================================
Write-Host "`n"
Write-Host "             - oo00oo -                       " -ForegroundColor Cyan
Write-Host "=> _____ HQ Dashboard V3 (PURE GM) _________ <=`n" -ForegroundColor Cyan
Write-Host "             🎮 100% Game Machine            `n" -ForegroundColor Green

# ================================================
# Path Setup
# ================================================
if ($MyInvocation.MyCommand.Path) {
    $global:basePath = Split-Path -Parent $MyInvocation.MyCommand.Path
} else {
    $global:basePath = Get-Location
}

Write-Host "📁 Base path: $global:basePath`n" -ForegroundColor Gray

# ================================================
# Cleanup old instances
# ================================================
$global:floorshows = @{}

if ($global:mainForm) {
    try {
        $global:mainForm.Close()
        $global:mainForm.Dispose()
    } catch {}
    Remove-Variable mainForm -Scope Global -ErrorAction SilentlyContinue
}

$global:mainForm = $null

# ================================================
# Load Dependencies
# ================================================
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Windows.Forms.DataVisualization
Add-Type -AssemblyName System.Drawing

. "${basePath}\CompanyCustomerSupport.ps1"

# ================================================
# Load Domain Layer
# ================================================
Write-Host "🏢 Loading Domain Layer..." -ForegroundColor Cyan
. "${basePath}\CompanyBase.ps1"
#. "${basePath}\Company1.ps1"
#. "${basePath}\Company2.ps1"
#. "${basePath}\Company3.ps1"
#. "${basePath}\Company4.ps1"

# ================================================
# Load v3 Game Machine Core
# ================================================
Write-Host "🎮 Loading Game Machine Core..." -ForegroundColor Cyan
. "${basePath}\HQshowBase.ps1"

Write-Host ""

# ================================================
# Initialize Domain Models
# ================================================
Write-Host "🏭 Initializing Companies..." -ForegroundColor Yellow

$config = Import-PowerShellDataFile -Path "${basePath}\CompanyConfig.psd1"

$companyConfig = $config.Company1
$novoNordisk = [Company1]::new($companyConfig.Name, $companyConfig.Address, $companyConfig.ContactNumber)

$companyConfig = $config.Company2
$wineCompany = [Company2]::new($companyConfig.Name, $companyConfig.Address, $companyConfig.ContactNumber)

$companyConfig = $config.Company3
$commerceBank = [Company3]::new($companyConfig.Name, $companyConfig.Address, $companyConfig.ContactNumber, $companyConfig.CEO)

$companyConfig = $config.Company4
try {
    $machineLearning = [Company4]::new($companyConfig.Name, $companyConfig.Address, $companyConfig.ContactNumber)
} catch {
    $machineLearning = $novoNordisk  # Fallback
}

Write-Host "✅ Companies initialized`n" -ForegroundColor Green

# ================================================
# Initialize Game Machine
# ================================================
Write-Host "🎮 Initializing Game Machine..." -ForegroundColor Yellow

$Global:ShowManager = [ShowManager]::new()
$Global:ShowManager.RegisterCompany($novoNordisk)
$Global:ShowManager.RegisterCompany($wineCompany)
$Global:ShowManager.RegisterCompany($commerceBank)
$Global:ShowManager.RegisterCompany($machineLearning)

# Start Game Loop
Start-GameLoop -Manager $Global:ShowManager

Write-Host ""

# ================================================
# Company Data (For TreeView/Pie Chart)
# ================================================
$companies = @(
    @{Name="AI Company";    Dept="AI";         Revenue=800000000;  Employees=4000;  MarketCap=15000000000; Color=[System.Drawing.Color]::Orange},
    @{Name="Wine Company";  Dept="Database";   Revenue=3200000000; Employees=18000; MarketCap=60000000000; Color=[System.Drawing.Color]::MediumSeaGreen},
    @{Name="Commerce Bank"; Dept="Commerce";   Revenue=1500000000; Employees=9500;  MarketCap=21000000000; Color=[System.Drawing.Color]::Yellow},
    @{Name="Novo Nordisk";  Dept="Operations"; Revenue=5000000000; Employees=24000; MarketCap=82000000000; Color=[System.Drawing.Color]::Gold}
)

# ================================================
# Form Setup
# ================================================
Write-Host "🖼️ Creating UI..." -ForegroundColor Yellow

$form = New-Object System.Windows.Forms.Form
$global:mainForm = $form

$form.Text = "Headquarters HQ - V3 (Pure GM)"
$form.Size = New-Object System.Drawing.Size(1000,600)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::White

# ================================================
# TreeView
# ================================================
$tree = New-Object System.Windows.Forms.TreeView
$tree.Location = New-Object System.Drawing.Point(20,20)
$tree.Size = New-Object System.Drawing.Size(250,200)
$tree.Font = New-Object System.Drawing.Font("Segoe UI",10)
$root = New-Object System.Windows.Forms.TreeNode("Company Headquarters")

$departments = @{}
foreach ($c in $companies) {
    if (-not $departments.ContainsKey($c.Dept)) {
        $deptNode = New-Object System.Windows.Forms.TreeNode($c.Dept)
        $departments[$c.Dept] = $deptNode
        $root.Nodes.Add($deptNode)
    }
    $child = New-Object System.Windows.Forms.TreeNode($c.Name)
    $child.BackColor = $c.Color
    $departments[$c.Dept].Nodes.Add($child)
}
$tree.Nodes.Add($root)
$tree.ExpandAll()
$form.Controls.Add($tree)

# ================================================
# Pie Chart
# ================================================
$pieChart = New-Object System.Windows.Forms.DataVisualization.Charting.Chart
$pieChart.Size = New-Object System.Drawing.Size(250,200)
$pieChart.Location = New-Object System.Drawing.Point(20,240)
$form.Controls.Add($pieChart)
$null = $pieChart.Handle

$pieChartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
$pieChartArea.Name = "PieArea"
$pieChartArea.BackColor = [System.Drawing.Color]::White
$pieChart.ChartAreas.Add($pieChartArea)

$pieMetricDropdown = New-Object System.Windows.Forms.ComboBox
$pieMetricDropdown.Location = New-Object System.Drawing.Point(20,450)
$pieMetricDropdown.Width = 250
$pieMetricDropdown.DropDownStyle = "DropDownList"
$pieMetricDropdown.Items.AddRange(@("Revenue","Employees","MarketCap"))
$pieMetricDropdown.SelectedIndex = 0
$form.Controls.Add($pieMetricDropdown)

function Update-PieChart {
    param($metric)
    $pieChart.Series.Clear()
    $pieSeries = New-Object System.Windows.Forms.DataVisualization.Charting.Series
    $pieSeries.ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Pie
    $pieSeries.ChartArea = "PieArea"
    $pieSeries.IsValueShownAsLabel = $true
    $pieSeries.Label = "#PERCENT{P0}"

    foreach ($c in $companies) {
        $val = $c[$metric]
        if ($metric -eq "Revenue" -or $metric -eq "MarketCap") {
            $val = [math]::Round($val / 1e9,2)
        }
        $pointIndex = $pieSeries.Points.AddXY($c['Name'], $val)
        $pieSeries.Points[$pointIndex].Color = $c['Color']
        $pieSeries.Points[$pointIndex].LegendText = $c['Name']
    }
$pieChart.Series.Add($pieSeries)
$pieChart.Titles.Clear()
$null = $pieChart.Titles.Add("Companies by $metric")
}

$pieMetricDropdown.Add_SelectedIndexChanged({ Update-PieChart $pieMetricDropdown.SelectedItem })
Update-PieChart "Revenue"

# ================================================
# Left Tabs
# ================================================
$tabs = New-Object System.Windows.Forms.TabControl
$tabs.Location = New-Object System.Drawing.Point(300,20)
$tabs.Size = New-Object System.Drawing.Size(650,30)
$tabs.Font = New-Object System.Drawing.Font("Segoe UI",9)

$overviewTab = New-Object System.Windows.Forms.TabPage
$overviewTab.Text = "Overview"
$analyticsTab = New-Object System.Windows.Forms.TabPage
$analyticsTab.Text = "Analytics"
$simulationTab = New-Object System.Windows.Forms.TabPage
$simulationTab.Text = "Simulation"

$tabs.TabPages.Add($overviewTab)
$tabs.TabPages.Add($analyticsTab)
$tabs.TabPages.Add($simulationTab)
$form.Controls.Add($tabs)

# ================================================
# Right Tabs
# ================================================
$rightTabs = New-Object System.Windows.Forms.TabControl
$rightTabs.Size = New-Object System.Drawing.Size(200, 30)
$rightTabs.Location = New-Object System.Drawing.Point(760, 20)
$rightTabs.Font = New-Object System.Drawing.Font("Segoe UI",9)

$tab1 = New-Object System.Windows.Forms.TabPage
$tab1.Text = "CleanUp"
$tab2 = New-Object System.Windows.Forms.TabPage
$tab2.Text = "Monitor"
$tab3 = New-Object System.Windows.Forms.TabPage
$tab3.Text = "EMERGENCY"

$rightTabs.TabPages.Add($tab1)
$rightTabs.TabPages.Add($tab2)
$rightTabs.TabPages.Add($tab3)

$form.Controls.Add($rightTabs)
$rightTabs.BringToFront()
$rightTabs.SelectedIndex = -1

# ================================================
# Floor Panel
# ================================================
$floorPanel = New-Object System.Windows.Forms.Panel
$floorPanel.Location = New-Object System.Drawing.Point(300,60)
$floorPanel.Size = New-Object System.Drawing.Size(650,410)
$floorPanel.BackColor = [System.Drawing.Color]::White
$form.Controls.Add($floorPanel)

# ================================================
# Create Show Panels
# ================================================
$namedShows = @("showA", "showB", "showC", "showD", "showE", "showF")
$numberedShows = 1..99 | ForEach-Object { "show$_" }
$allShows = $namedShows + $numberedShows

foreach ($showName in $allShows) {
    $panel = New-Object System.Windows.Forms.Panel
    $panel.Dock = "Fill"
    $panel.BackColor = [System.Drawing.Color]::White
    $panel.Visible = $false
    $floorPanel.Controls.Add($panel)
    $global:floorshows[$showName] = $panel
}

Write-Host "✅ Created $($allShows.Count) show panels" -ForegroundColor Green

# ================================================
# Load and Register v3 Shows ONLY
# ================================================
Write-Host "📺 Loading v3 Shows..." -ForegroundColor Yellow

# Define show configuration
$v3ShowConfigs = @(
    @{Name="ShowA";  File="HQshowA.ps1";  Panel="showA";  Company=$null;            ClassName="ShowA"},
    @{Name="ShowB";  File="HQshowB.ps1";  Panel="showB";  Company=$null;            ClassName="ShowB"},
    @{Name="ShowC";  File="HQshowC.ps1";  Panel="showC";  Company=$null;            ClassName="ShowC"},
    @{Name="ShowD";  File="HQshowD.ps1";  Panel="showD";  Company=$null;            ClassName="ShowD"},
    @{Name="ShowE";  File="HQshowE.ps1";  Panel="showE";  Company=$null;            ClassName="ShowE"},
    @{Name="ShowF";  File="HQshowF.ps1";  Panel="showF";  Company=$null;            ClassName="ShowF"},

    @{Name="Show1";  File="HQshow1.ps1";  Panel="show1";  Company=$machineLearning; ClassName="Show1"},
    @{Name="Show2";  File="HQshow2.ps1";  Panel="show2";  Company=$machineLearning; ClassName="Show2"},
    @{Name="Show3";  File="HQshow3.ps1";  Panel="show3";  Company=$machineLearning; ClassName="Show3"},
    @{Name="Show4";  File="HQshow4.ps1";  Panel="show4";  Company=$machineLearning; ClassName="Show4"},
    @{Name="Show5";  File="HQshow5.ps1";  Panel="show5";  Company=$machineLearning; ClassName="Show5"},
    @{Name="Show6";  File="HQshow6.ps1";  Panel="show6";  Company=$machineLearning; ClassName="Show6"},
    @{Name="Show7";  File="HQshow7.ps1";  Panel="show7";  Company=$machineLearning; ClassName="Show7"},
    @{Name="Show8";  File="HQshow8.ps1";  Panel="show8";  Company=$machineLearning; ClassName="Show8"},
    @{Name="Show9";  File="HQshow9.ps1";  Panel="show9";  Company=$machineLearning; ClassName="Show9"},   
    @{Name="Show10"; File="HQshow10.ps1"; Panel="show10"; Company=$machineLearning; ClassName="Show10"},

    @{Name="Show11"; File="HQshow11.ps1"; Panel="show11"; Company=$wineCompany;     ClassName="Show11"},
    @{Name="Show12"; File="HQshow12.ps1"; Panel="show12"; Company=$wineCompany;     ClassName="Show12"},
    @{Name="Show13"; File="HQshow13.ps1"; Panel="show13"; Company=$wineCompany;     ClassName="Show13"},
    @{Name="Show14"; File="HQshow14.ps1"; Panel="show14"; Company=$wineCompany;     ClassName="Show14"},
    @{Name="Show15"; File="HQshow15.ps1"; Panel="show15"; Company=$wineCompany;     ClassName="Show15"},
    @{Name="Show16"; File="HQshow16.ps1"; Panel="show16"; Company=$wineCompany;     ClassName="Show16"},
    @{Name="Show17"; File="HQshow17.ps1"; Panel="show17"; Company=$wineCompany;     ClassName="Show17"},
    @{Name="Show18"; File="HQshow18.ps1"; Panel="show18"; Company=$wineCompany;     ClassName="Show18"},
    @{Name="Show19"; File="HQshow19.ps1"; Panel="show19"; Company=$wineCompany;     ClassName="Show19"},
    @{Name="Show20"; File="HQshow20.ps1"; Panel="show20"; Company=$wineCompany;     ClassName="Show20"},
    @{Name="Show71"; File="HQshow71.ps1"; Panel="show71"; Company=$wineCompany;     ClassName="Show71"},

    @{Name="Show21"; File="HQshow21.ps1"; Panel="show21"; Company=$commerceBank;    ClassName="Show21"},
    @{Name="Show22"; File="HQshow22.ps1"; Panel="show22"; Company=$commerceBank;    ClassName="Show22"},
    @{Name="Show23"; File="HQshow23.ps1"; Panel="show23"; Company=$commerceBank;    ClassName="Show23"},
    @{Name="Show24"; File="HQshow24.ps1"; Panel="show24"; Company=$commerceBank;    ClassName="Show24"},
    @{Name="Show25"; File="HQshow25.ps1"; Panel="show25"; Company=$commerceBank;    ClassName="Show25"},
    @{Name="Show26"; File="HQshow26.ps1"; Panel="show26"; Company=$commerceBank;    ClassName="Show26"},
    @{Name="Show27"; File="HQshow27.ps1"; Panel="show27"; Company=$commerceBank;    ClassName="Show27"},
    @{Name="Show28"; File="HQshow28.ps1"; Panel="show28"; Company=$commerceBank;    ClassName="Show28"},
    @{Name="Show29"; File="HQshow29.ps1"; Panel="show29"; Company=$commerceBank;    ClassName="Show29"},
    @{Name="Show30"; File="HQshow30.ps1"; Panel="show30"; Company=$commerceBank;    ClassName="Show30"},

    @{Name="Show31"; File="HQshow31.ps1"; Panel="show31"; Company=$novoNordisk;     ClassName="Show31"},
    @{Name="Show32"; File="HQshow32.ps1"; Panel="show32"; Company=$novoNordisk;     ClassName="Show32"},
    @{Name="Show33"; File="HQshow33.ps1"; Panel="show33"; Company=$novoNordisk;     ClassName="Show33"},
    @{Name="Show34"; File="HQshow34.ps1"; Panel="show34"; Company=$novoNordisk;     ClassName="Show34"},
    @{Name="Show35"; File="HQshow35.ps1"; Panel="show35"; Company=$novoNordisk;     ClassName="Show35"},
    @{Name="Show36"; File="HQshow36.ps1"; Panel="show36"; Company=$novoNordisk;     ClassName="Show36"},
    @{Name="Show37"; File="HQshow37.ps1"; Panel="show37"; Company=$novoNordisk;     ClassName="Show37"},
    @{Name="Show38"; File="HQshow38.ps1"; Panel="show38"; Company=$novoNordisk;     ClassName="Show38"},
    @{Name="Show39"; File="HQshow39.ps1"; Panel="show39"; Company=$novoNordisk;     ClassName="Show39"},
    @{Name="Show40"; File="HQshow40.ps1"; Panel="show40"; Company=$novoNordisk;     ClassName="Show40"},

    @{Name="Show50"; File="HQshow50.ps1"; Panel="show50"; Company=$machineLearning; ClassName="Show50"},
    @{Name="Show51"; File="HQshow51.ps1"; Panel="show51"; Company=$machineLearning; ClassName="Show51"},
    @{Name="Show52"; File="HQshow52.ps1"; Panel="show52"; Company=$machineLearning; ClassName="Show52"},
    @{Name="Show53"; File="HQshow53.ps1"; Panel="show53"; Company=$machineLearning; ClassName="Show53"},
    @{Name="Show54"; File="HQshow54.ps1"; Panel="show54"; Company=$machineLearning; ClassName="Show54"},
    @{Name="Show55"; File="HQshow55.ps1"; Panel="show55"; Company=$machineLearning; ClassName="Show55"},
    @{Name="Show56"; File="HQshow56.ps1"; Panel="show56"; Company=$machineLearning; ClassName="Show56"},
    @{Name="Show57"; File="HQshow57.ps1"; Panel="show57"; Company=$machineLearning; ClassName="Show57"},
    @{Name="Show58"; File="HQshow58.ps1"; Panel="show58"; Company=$machineLearning; ClassName="Show58"},
    @{Name="Show59"; File="HQshow59.ps1"; Panel="show59"; Company=$machineLearning; ClassName="Show59"},
    @{Name="Show60"; File="HQshow60.ps1"; Panel="show60"; Company=$machineLearning; ClassName="Show60"}

)

# Step 1: Load all show scripts first
Write-Host "  📂 Loading show scripts..." -ForegroundColor DarkCyan
foreach ($config in $v3ShowConfigs) {
    $scriptPath = Join-Path $global:basePath $config.File
    
    if (Test-Path $scriptPath) {
        try {
            . $scriptPath
            Write-Host "    ✓ Loaded $($config.File)" -ForegroundColor DarkGreen
        } catch {
            Write-Host "    ✗ Failed to load $($config.File): $_" -ForegroundColor Red
        }
    } else {
        Write-Host "    ⚠ File not found: $($config.File)" -ForegroundColor Yellow
    }
}

Write-Host ""

# Step 2: Register shows with ShowManager
Write-Host "  🎮 Registering shows with Game Machine..." -ForegroundColor DarkCyan

foreach ($config in $v3ShowConfigs) {
    if ($global:floorshows.ContainsKey($config.Panel)) {
        try {
            # Create show instance using class name
            $show = New-Object $config.ClassName ($global:floorshows[$config.Panel])
            
            # Set company if specified
            if ($config.Company) {
                $show.SetCompany($config.Company)
            }
            
            # Register with ShowManager
            $Global:ShowManager.RegisterShow($show)
            Write-Host "    ✅ $($config.Name) registered" -ForegroundColor Green
        } catch {
            Write-Host "    ❌ Failed to register $($config.Name): $_" -ForegroundColor Red
        }
    } else {
        Write-Host "    ⚠ Panel not found: $($config.Panel)" -ForegroundColor Yellow
    }
}

Write-Host "  📊 V3 Shows registered: $($Global:ShowManager.Shows.Count)/9" -ForegroundColor Cyan
Write-Host ""

# ================================================
# Tab Event Handlers - PURE GM
# ================================================
$tabs.Add_SelectedIndexChanged({
    switch ($tabs.SelectedTab.Text) {
        "Overview" {
            if ($Global:ShowManager.Shows.ContainsKey("showA")) {
                $Global:ShowManager.LoadShow("showA")
            } else {
                [System.Windows.Forms.MessageBox]::Show("ShowA not yet converted to V3", "Coming Soon", "OK", "Information")
            }
        }
        "Analytics" {
            if ($Global:ShowManager.Shows.ContainsKey("showB")) {
                $Global:ShowManager.LoadShow("showB")
            } else {
                [System.Windows.Forms.MessageBox]::Show("ShowB not yet converted to V3", "Coming Soon", "OK", "Information")
            }
        }
        "Simulation" {
            if ($Global:ShowManager.Shows.ContainsKey("showC")) {
                $Global:ShowManager.LoadShow("showC")
            } else {
                [System.Windows.Forms.MessageBox]::Show("ShowC not yet converted to V3", "Coming Soon", "OK", "Information")
            }
        }
        default {
            # Hide all panels
            foreach ($key in $global:floorshows.Keys) {
                $global:floorshows[$key].Visible = $false
            }
        }
    }
})

$rightTabs.Add_SelectedIndexChanged({
    switch ($rightTabs.SelectedTab.Text) {
        "CleanUp" {
            if ($Global:ShowManager.Shows.ContainsKey("showD")) {
                $Global:ShowManager.LoadShow("showD")
            } else {
                [System.Windows.Forms.MessageBox]::Show("ShowD not yet converted to V3", "Coming Soon", "OK", "Information")
            }
        }
        "Monitor" {
            if ($Global:ShowManager.Shows.ContainsKey("showE")) {
                $Global:ShowManager.LoadShow("showE")
            } else {
                [System.Windows.Forms.MessageBox]::Show("ShowE not yet converted to V3", "Coming Soon", "OK", "Information")
            }
        }
        "EMERGENCY" {
            if ($Global:ShowManager.Shows.ContainsKey("showF")) {
                $Global:ShowManager.LoadShow("showF")
            } else {
                [System.Windows.Forms.MessageBox]::Show("ShowF not yet converted to V3", "Coming Soon", "OK", "Information")
            }
        }
        default {
            # Hide all panels
            foreach ($key in $global:floorshows.Keys) {
                $global:floorshows[$key].Visible = $false
            }
        }
    }
})

# ================================================
# News Ticker
# ================================================
$tickerPanel = New-Object System.Windows.Forms.Panel
$tickerPanel.Dock = "Bottom"
$tickerPanel.Height = 25
$tickerPanel.BackColor = [System.Drawing.Color]::DarkBlue
$form.Controls.Add($tickerPanel)

$tickerLabel = New-Object System.Windows.Forms.Label
$tickerLabel.ForeColor = [System.Drawing.Color]::White
$tickerLabel.Font = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
$tickerLabel.AutoSize = $true
$tickerPanel.Controls.Add($tickerLabel)

$global:messages = @("Welcome to HQ Dashboard V3 - 100% Pure Game Machine!", "🎮 All shows now use GM architecture")
$global:liveNewsMessages = @()

function Update-Ticker {
    $combined = @()
    if ($global:messages) { $combined += $global:messages }
    if ($global:liveNewsMessages.Count -gt 0) {
        $combined += ""
        foreach ($headline in $global:liveNewsMessages) {
            $combined += ("📰 " + $headline)
        }
    }
    if ($combined.Count -eq 0) { $combined = @("⏳ Waiting for news...") }
    $scrollText = (($combined -join "     ") + "     ") * 2
    $tickerLabel.Text = $scrollText
    $tickerLabel.Left = $tickerPanel.Width
}

$tickerTimer = New-Object System.Windows.Forms.Timer
$tickerTimer.Interval = 50
$tickerTimer.Add_Tick({
    $tickerLabel.Left -= 2
    if (($tickerLabel.Left + $tickerLabel.Width) -lt 0) {
        $tickerLabel.Left = $tickerPanel.Width
    }
})
$tickerTimer.Start()

$NewsApiKey = "94d76d7d76b54db79dd4ab5810b9c371"
$NewsApiEndpoint = "https://newsapi.org/v2/top-headlines?country=us&category=business&apiKey=$NewsApiKey"

function Fetch-LiveNews {
    try {
        $resp = Invoke-RestMethod -Uri $NewsApiEndpoint -Method Get -TimeoutSec 10
        if ($resp.articles) {
            $global:liveNewsMessages = $resp.articles | Select-Object -First 5 | ForEach-Object { $_.title }
        } else {
            $global:liveNewsMessages = @("No headlines available.")
        }
    } catch {
        $global:liveNewsMessages = @("⚠ Error fetching news")
    }
    Update-Ticker
}

Fetch-LiveNews

$newsTimer = New-Object System.Windows.Forms.Timer
$newsTimer.Interval = 60000
$newsTimer.Add_Tick({ Fetch-LiveNews })
$newsTimer.Start()

# ================================================
# TreeView Click Handler - PURE GM
# ================================================
$tree.Add_NodeMouseClick({
    param($sender, $e)
    $node = $e.Node
    $clickedName = $node.Text
    $company = $companies | Where-Object { $_.Name -eq $clickedName }
    if ($company) {
        Show-CompanyDropdown-V3 -companyName $company.Name
    }
})

function Show-CompanyDropdown-V3 {
    param([string]$companyName)

    $companyShows = @{
        "AI Company"     = @("show1" ,"show2" ,"show3" ,"show4" ,"show5" ,"show6" ,"show7" ,"show8" ,"show9" ,"show10",`
                             "show50","show51","show52","show53","show54","show55","show56","show57","show58","show59","show60")
        "Wine Company"   = @("show11","show12","show13","show14","show15","show16","show17","show18","show19","show20","show71")
        "Commerce Bank"  = @("show21","show22","show23","show24","show25","show26","show27","show28","show29","show30")
        "Novo Nordisk"   = @("show31","show32","show33","show34","show35","show36","show37","show38","show39","show40")
    }

    $shows = $companyShows[$companyName]
    if (-not $shows) {
        [System.Windows.Forms.MessageBox]::Show("No shows configured for $companyName", "Info", "OK", "Information")
        return
    }

    # Filter to only GM-registered shows
    $availableShows = $shows | Where-Object {
        $Global:ShowManager.Shows.ContainsKey($_)
    }

    if ($availableShows.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show(
            "No V3 shows available yet for $companyName.`n`nShows are being converted to Game Machine architecture.`n`nCurrently available V3 shows:`n- Show1, Show15, Show31`n- ShowA, ShowB, ShowC`n- ShowD, ShowE, ShowF",
            "Coming Soon",
            "OK",
            "Information"
        )
        return
    }

    $dropdownForm = New-Object System.Windows.Forms.Form
    $dropdownForm.Text = "$companyName Shows (V3)"
    $dropdownForm.Size = New-Object System.Drawing.Size(300, 150)
    $dropdownForm.StartPosition = "CenterScreen"
    $dropdownForm.FormBorderStyle = "FixedDialog"
    $dropdownForm.MaximizeBox = $false
    $dropdownForm.MinimizeBox = $false
    $dropdownForm.TopMost = $true

    $Global:CompanyDropdownForm = $dropdownForm

    $comboBox = New-Object System.Windows.Forms.ComboBox
    $comboBox.Location = New-Object System.Drawing.Point(20, 20)
    $comboBox.Size = New-Object System.Drawing.Size(240, 25)
    $comboBox.DropDownStyle = "DropDownList"
    $comboBox.Items.AddRange($availableShows)
    $comboBox.SelectedIndex = 0
    $dropdownForm.Controls.Add($comboBox)

    $comboBox.Add_SelectedIndexChanged({
        $selectedShow = $comboBox.SelectedItem
        if ($selectedShow -and $Global:ShowManager.Shows.ContainsKey($selectedShow)) {
            $Global:ShowManager.LoadShow($selectedShow)
        }
        $dropdownForm.Close()
    })

    [void]$dropdownForm.ShowDialog($form)
}

# ================================================
# Chat Button
# ================================================
$chatButton = New-Object System.Windows.Forms.Button
$chatButton.Text = "✨ Let's chat"
$chatButton.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$chatButton.Size = New-Object System.Drawing.Size(130, 35)
$chatButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#e0f0ff")
$chatButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#003366")
$chatButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$chatButton.FlatAppearance.BorderSize = 0

$radius = 10
$graphicsPath = New-Object System.Drawing.Drawing2D.GraphicsPath
$graphicsPath.AddArc(0, 0, $radius, $radius, 180, 90)
$graphicsPath.AddArc($chatButton.Width - $radius, 0, $radius, $radius, 270, 90)
$graphicsPath.AddArc($chatButton.Width - $radius, $chatButton.Height - $radius, $radius, $radius, 0, 90)
$graphicsPath.AddArc(0, $chatButton.Height - $radius, $radius, $radius, 90, 90)
$graphicsPath.CloseFigure()
$chatButton.Region = New-Object System.Drawing.Region($graphicsPath)

$chatButton.Add_MouseEnter({ $chatButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#cce4ff") })
$chatButton.Add_MouseLeave({ $chatButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#e0f0ff") })

$chatButton.Location = New-Object System.Drawing.Point(($form.ClientSize.Width - $chatButton.Width - 20), ($form.ClientSize.Height - $chatButton.Height - 37))
$chatButton.Anchor = "Bottom,Right"

$chatButton.Add_Click({
    $form.Topmost = $false
    Invoke-Expression -Command "$basePath\AI_OpenRouter.ps1"
    $form.Topmost = $true
})

$form.Controls.Add($chatButton)

# ================================================
# Form Events
# ================================================
$form.Add_Shown({
    $form.Activate()
    $form.Topmost = $true
    $form.Topmost = $false

    # Load default show on startup
    if ($Global:ShowManager.Shows.ContainsKey("showA")) {
        $Global:ShowManager.LoadShow("showA")
    }
})

$form.Add_FormClosing({
    Write-Host "`n🛑 Shutting down V3..." -ForegroundColor Yellow
    Stop-GameLoop
    $Global:ShowManager.StopAll()
    Write-Host "✅ Cleanup complete" -ForegroundColor Green
})

# ================================================
# Launch Dashboard V3
# ================================================
Write-Host "`n🚀 Launching Dashboard V3 (Pure GM)...`n" -ForegroundColor Magenta
Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  ✅ 9 V3 Shows Ready:" -ForegroundColor Green
Write-Host "     • Show1, Show15, Show31" -ForegroundColor White
Write-Host "     • ShowA, ShowB, ShowC" -ForegroundColor White
Write-Host "     • ShowD, ShowE, ShowF" -ForegroundColor White
Write-Host "  🎮 100% Game Machine Architecture" -ForegroundColor Green
Write-Host "  🚫 Zero V1 Compatibility Code" -ForegroundColor Green
Write-Host "════════════════════════════════════════`n" -ForegroundColor Cyan

[void]$form.ShowDialog()
