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

$pythonScriptPath = "$basePath\AI_HuggingFace.py"

# Hugging Face models
$models = @{
    "Mistral-Nemo-Instruct-240" = "mistralai/Mistral-Nemo-Instruct-2407" 
    "LLaMA 3.1 8B Instruct" = "meta-llama/Meta-Llama-3-8B-Instruct"
    "LLaMA 3.1 70B Instruct" = "meta-llama/Meta-Llama-3.1-70B-Instruct"
    "Mixtral 8x7B Instruct" = "mistralai/Mixtral-8x7B-Instruct-v0.1"
    "Mistral 7B Instruct" = "mistralai/Mistral-7B-Instruct-v0.1"
    "LLaMA 2 7B Chat" = "meta-llama/Llama-2-7b-chat-hf"
    "Phi-3-mini" = "microsoft/Phi-3-mini-4k-instruct"
    "Phi-2" = "microsoft/phi-2"
    "bert-base-uncased" = "bert-base-uncased"                                                    # Busy/Waiting
    "distilbert-base-uncased" = "distilbert-base-uncased"                                        # Mask missing
    "roberta-base" = "roberta-base"                                                              # Mask missing
    "gpt2" = "gpt2"                                                                              # OK        
    "distilgpt2" = "distilgpt2"                                                                  # OK
    "facebook/bart-large-cn" = "facebook/bart-large-cnn"                                         # OK
    "meta-llama/Meta-Llama-3.1-70B-Instruct" = "meta-llama/Meta-Llama-3.1-70B-Instruct"          # HF token missing  
    "CohereForAI/c4ai-command-r-plus-08-2024" = "CohereForAI/c4ai-command-r-plus-08-2024"        # HF token missing
    "Qwen/Qwen2.5-72B-Instruc" = "Qwen/Qwen2.5-72B-Instruct"                                     # FANTASTIC   12
    "nvidia/Llama-3.1-Nemotron-70B-Instruct-HF" = "nvidia/Llama-3.1-Nemotron-70B-Instruct-HF"    # HF token missing  
    "meta-llama/Llama-3.2-11B-Vision-Instruct" = "meta-llama/Llama-3.2-11B-Vision-Instruct"      # FANTASTIC    5 
    "NousResearch/Hermes-3-Llama-3.1-8B" = "NousResearch/Hermes-3-Llama-3.1-8B"                  # FANTASTIC   12 MOSTLY BUSY
    "mistralai/Mistral-Nemo-Instruct-2407" = "mistralai/Mistral-Nemo-Instruct-2407"              # FANTASTIC    5
    "microsoft/Phi-3.5-mini-instruct" = "microsoft/Phi-3.5-mini-instruct"                        # OK
    "Phi-3.5-mini-instruct" = "Phi-3.5-mini-instruct"                                            # Heavy error  
}

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "AI_HuggingFace - Hugging Face"
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

# Output TextBox (NEW - for formatted responses)
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
            #Write-Host $result
            if ($result -notmatch "Request failed|timed out|Error") {
                $response = $result
                break
            }
        } catch {
            $response = "Unexpected error: $_"
        }
    }

    # Format response for readability
    $response = $response -replace "`r`n|`r|`n", "`r`n"  # Normalize all to Windows-style
    $response = [regex]::Replace($response, '([.!?])\s+', "`$1`r`n`r`n")  # Add spacing after sentences

    # Set formatted response to output box
    $outputBox.Text = $ExecutionContext.InvokeCommand.ExpandString($response)
})

$form.Add_Shown({ $form.Activate() })
[void]$form.ShowDialog()