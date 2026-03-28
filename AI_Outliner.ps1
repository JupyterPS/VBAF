Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Define paths
$pathWin11 = "C:\Users\henni\OneDrive\WindowsPowerShell"
$pathWin10 = "C:\Users\Henning\OneDrive\WindowsPowerShell"

$basePath = if (Test-Path $pathWin11) { $pathWin11 } else { $pathWin10 }
$pythonExePath = if (Test-Path $pathWin11) {
    "C:\Users\Henni\AppData\Local\Programs\Python\Python313\python.exe"
} else {
    "C:\Users\Henning\AppData\Local\Programs\Python\Python310\python.exe"
}

$pythonScriptPath = "$basePath\AI_Outliner.py"
$treeFilePath = "$basePath\Tree.md"

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "OutlinerAI - Tree Builder"
$form.Width = 550
$form.Height = 600
$form.StartPosition = "CenterScreen"

# Input TextBox
$inputBox = New-Object System.Windows.Forms.TextBox
$inputBox.Multiline = $false
$inputBox.Width = 460
$inputBox.Location = New-Object System.Drawing.Point(30, 60)
$inputBox.Font = New-Object System.Drawing.Font("Segoe UI", 12)
$form.Controls.Add($inputBox)

# Command Dropdown
$commandLabel = New-Object System.Windows.Forms.Label
$commandLabel.Text = "Command:"
$commandLabel.Location = New-Object System.Drawing.Point(30, 20)
$form.Controls.Add($commandLabel)

$commandDropdown = New-Object System.Windows.Forms.ComboBox
$commandDropdown.Location = New-Object System.Drawing.Point(100, 15)
$commandDropdown.Width = 200
$commandDropdown.DropDownStyle = "DropDownList"
$commandDropdown.Items.AddRange(@("G - Generate Tree", "D - Display Tree", "S - Save Tree", "B - Clarify Branch"))
$commandDropdown.SelectedIndex = 0
$form.Controls.Add($commandDropdown)

# Output TextBox
$outputBox = New-Object System.Windows.Forms.TextBox
$outputBox.Multiline = $true
$outputBox.ScrollBars = "Vertical"
$outputBox.ReadOnly = $true
$outputBox.WordWrap = $true
$outputBox.Font = New-Object System.Drawing.Font("Consolas", 10)
$outputBox.Width = 460
$outputBox.Height = 300
$outputBox.Location = New-Object System.Drawing.Point(30, 140)
$form.Controls.Add($outputBox)

# Run Button
$runButton = New-Object System.Windows.Forms.Button
$runButton.Text = "Run"
$runButton.Location = New-Object System.Drawing.Point(380, 15)
$runButton.Width = 80
$form.Controls.Add($runButton)

# Clipboard Button
$copyButton = New-Object System.Windows.Forms.Button
$copyButton.Text = "Copy Output"
$copyButton.Location = New-Object System.Drawing.Point(30, 460)
$copyButton.Width = 120
$form.Controls.Add($copyButton)

$copyButton.Add_Click({
    $textToCopy = $outputBox.Text
    if (![string]::IsNullOrWhiteSpace($textToCopy)) {
        [System.Windows.Forms.Clipboard]::SetText($textToCopy)
    } else {
        [System.Windows.Forms.MessageBox]::Show("Nothing to copy.", "Warning")
    }
})

# Run logic
$runButton.Add_Click({
    $input = $inputBox.Text
    $cmdCode = $commandDropdown.SelectedItem.Split(' ')[0]  # G, D, S, B

    switch ($cmdCode) {
        "G" {
            $args = @("G", $input)
            try {
                $result = & $pythonExePath $pythonScriptPath @args
                $outputBox.Text = $result
            } catch {
                $outputBox.Text = "Error running Python script: $_"
            }
        }
        "S" {
            try {
                Set-Content -Path $treeFilePath -Value $input -Encoding UTF8
                $outputBox.Text = "Tree.md updated successfully."
                Write-Host "`n[SAVE] Tree.md content written:" -ForegroundColor Green
                Write-Host $input
            } catch {
                $outputBox.Text = "Failed to save to Tree.md: $_"
            }
        }
        "D" {
            if (Test-Path $treeFilePath) {
                try {
                    $lines = Get-Content -Path $treeFilePath
                    $outputBox.Text = $lines -join "`r`n"

                    Write-Host "`n======= Tree.md =======`n" -ForegroundColor Cyan

                    foreach ($line in $lines) {
                        $cleanLine = $line.Trim()

                        if ($cleanLine -match '^[0-9IVXA-Z]+\.' -or $cleanLine -match '^[A-Z]+\s') {
                            Write-Host "$cleanLine" -ForegroundColor Yellow
                        } elseif ($cleanLine -match '^\s{2,}') {
                            Write-Host "    $cleanLine" -ForegroundColor Gray
                        } else {
                            Write-Host "$cleanLine"
                        }
                    }

                    Write-Host "`n======= End of Tree =======`n" -ForegroundColor Cyan
                } catch {
                    $outputBox.Text = "Failed to read Tree.md: $_"
                }
            } else {
                $outputBox.Text = "Tree.md not found."
            }
        }
        "B" {
            $args = @("B", $input)
            try {
                $result = & $pythonExePath $pythonScriptPath @args
                $outputBox.Text = $result
            } catch {
                $outputBox.Text = "Error running Python script: $_"
            }
        }
        default {
            $outputBox.Text = "Unknown command selected."
        }
    }
})

$form.Add_Shown({ $form.Activate() })
[void]$form.ShowDialog()

<#
Please convert the following system specification into a hierarchical tree with modules, submodules, and key functionalities.

System Overview:
- Purpose: Parse manuscript/system specification into a tree and generate code.
- Scope: Structure manuscripts/specs and generate/save code.
- Assumptions: Manual interaction; OpenRouter models; no automation.
- Vision: Refine specs, structure data, generate code.

Architecture:
- Hardware: CPU, Memory, Storage, GPU, I/O Devices
- Software: OS, Libraries, Middleware, Application Software, Drivers

Core Features:
- UI: GUI, CLI, Touch, Voice
- Processing: Algorithms, Data Structures, Encryption
- Networking: Connectivity, Protocols, Security
- Resource Mgmt: Scheduling, Memory, CPU, Power

Device Integration:
- Peripherals: Printers, Scanners, External Devices
- Smart Home: Lighting, Thermostat, Security
- Mobile: Remote, Sync, Share

Performance Metrics:
- CPU, Memory, Storage, Graphics, Network, Power, UX

Maintenance:
- Updates, Patches, Backup, Troubleshooting, Monitoring

Security:
- Auth, Privacy, Malware, Intrusion, Physical

Docs:
- Start, Operation, Troubleshoot, Customize, Security, Maintain

Testing:
- Unit, Integration, System, Acceptance, Performance, Compatibility, User

Lifecycle:
- Deploy, Retire, EOL, Upgrade, Feedback, Improve

#>