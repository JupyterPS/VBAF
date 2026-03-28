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

$pythonScriptPath = "$basePath\AI_OpenRouter.py"

# OpenRouter models
$models = @{
    "Mistral 7B Instruct (free)" = "mistralai/mistral-7b-instruct:free"
    "Claude 3 Haiku"            = "anthropic/claude-3-haiku"
    "GPT-3.5 Turbo"             = "openai/gpt-3.5-turbo"
    "GPT-4"                     = "openai/gpt-4"
    "Command R+"               = "cohere/command-r-plus"
    "Gemini-Pro"               = "google/gemini-pro"
    "Mixtral"                  = "mistralai/mixtral-8x7b-instruct"
}

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "AI_OpenRouter - OpenRouter Edition"
$form.Width = 520
$form.Height = 580
$form.StartPosition = "CenterScreen"

# Model Dropdown
$modelLabel = New-Object System.Windows.Forms.Label
$modelLabel.Text = "Choose Model:"
$modelLabel.Location = New-Object System.Drawing.Point(30, 20)
$form.Controls.Add($modelLabel)

$modelDropdown = New-Object System.Windows.Forms.ComboBox
$modelDropdown.Location = New-Object System.Drawing.Point(130, 15)
$modelDropdown.Width = 330
$modelDropdown.DropDownStyle = "DropDownList"
$modelDropdown.Items.AddRange($models.Keys)
$modelDropdown.SelectedIndex = 0
$modelDropdown.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$form.Controls.Add($modelDropdown)

# Input TextBox
$inputBox = New-Object System.Windows.Forms.TextBox
$inputBox.Multiline = $false
$inputBox.Width = 430
$inputBox.Location = New-Object System.Drawing.Point(30, 60)
$inputBox.Font = New-Object System.Drawing.Font("Segoe UI", 12)
$form.Controls.Add($inputBox)

# Output TextBox
$outputBox = New-Object System.Windows.Forms.TextBox
$outputBox.Multiline = $true
$outputBox.ScrollBars = "Vertical"
$outputBox.ReadOnly = $true
$outputBox.WordWrap = $true
$outputBox.Font = New-Object System.Drawing.Font("Consolas", 10)
$outputBox.Width = 440
$outputBox.Height = 300
$outputBox.Location = New-Object System.Drawing.Point(30, 140)
$form.Controls.Add($outputBox)

# Fallback toggle checkbox
$fallbackBox = New-Object System.Windows.Forms.CheckBox
$fallbackBox.Text = "Fallback"
$fallbackBox.Location = New-Object System.Drawing.Point(30, 100)
$form.Controls.Add($fallbackBox)

# Ask Button
$askButton = New-Object System.Windows.Forms.Button
$askButton.Text = "Ask"
$askButton.Location = New-Object System.Drawing.Point(400, 100)
$form.Controls.Add($askButton)

# Copy to Clipboard Button
$copyButton = New-Object System.Windows.Forms.Button
$copyButton.Text = "Copy to Clipboard"
$copyButton.Location = New-Object System.Drawing.Point(30, 460)
$copyButton.Width = 130
$form.Controls.Add($copyButton)

# Copy button click event
$copyButton.Add_Click({
    $textToCopy = $outputBox.Text
    if (![string]::IsNullOrWhiteSpace($textToCopy)) {
        [System.Windows.Forms.Clipboard]::SetText($textToCopy)
    } else {
        [System.Windows.Forms.MessageBox]::Show("Nothing to copy.", "Warning")
    }
})

# Ask button click event
$askButton.Add_Click({
    $question = $inputBox.Text
    $modelName = $models[$modelDropdown.SelectedItem]
    $modelsToTry = @($modelName)

    if ($fallbackBox.Checked) {
        $modelsToTry += $models.Values | Where-Object { $_ -ne $modelName }
    }

    $response = "No valid response."

    foreach ($model in $modelsToTry) {
        try {
            Write-Host "Trying model: $model"
            $result = & $pythonExePath $pythonScriptPath $question $model
            if ($result -notmatch "Request failed|timed out|Error") {
                $response = $result
                break
            }
        } catch {
            $response = "Unexpected error: $_"
        }
    }

    # Format response for readability
    $response = $response -replace "`r`n|`r|`n", "`r`n"  # Normalize line endings
    $response = [regex]::Replace($response, '([.!?])\s+', "`$1`r`n`r`n")  # Add spacing after sentences

    # Set formatted response to output box
    $outputBox.Text = $ExecutionContext.InvokeCommand.ExpandString($response)
})

# Show the form
$form.Add_Shown({ $form.Activate() })
[void]$form.ShowDialog()
