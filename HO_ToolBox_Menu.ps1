CLS
#-----------------------------------------------------------------------------------------
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

# 1. Instantiate a Form Object (before adding the heading)
#-----------------------------------------------------------------------------------------
$Form_MAIN = New-Object system.Windows.Forms.Form
$Form_MAIN.ClientSize  = New-Object System.Drawing.Point(1300, 630)  # Increased height for space
$Form_MAIN.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen  # Center the form
$Form_MAIN.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#ffffff")
$Form_MAIN.Text = "P o w e r s h e l l  F u n d a m e n t a l s"
$Form_MAIN.TopMost = $false

# 1. Heading for the Form (Now we can add this after the form is instantiated)
#-----------------------------------------------------------------------------------------
$HeadingLabel = New-Object System.Windows.Forms.Label
$HeadingLabel.Text = "- oo00oo - `n`nC o n c e p t s`n`nM A C H I N E  R O O M"
$HeadingLabel.AutoSize = $true
$HeadingLabel.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 7, [System.Drawing.FontStyle]::Bold)  # Reduced font size even more

# Calculate the X position to center the heading label
$headingX = [math]::Floor(($Form_MAIN.ClientSize.Width - $HeadingLabel.Width) / 2)

# Set the location for the heading label to center it horizontally
$HeadingLabel.Location = New-Object System.Drawing.Point($headingX, 10)  # Position it at the top with a slight margin

$HeadingLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter

# Add the heading label to the form
$Form_MAIN.Controls.Add($HeadingLabel)

# 2. Adjust Panel Location (moving it 6 lines down)
#-----------------------------------------------------------------------------------------
$Panel = New-Object system.Windows.Forms.Panel
$Panel.Height = 420  # Increased height to fit all radio buttons comfortably
$Panel.Width = 1260   # Width remains the same
$Panel.Location = New-Object System.Drawing.Point(20, 100)  # Adjusted position to move it down

# Define the topics
$topics = @(
    "        1 Variables:                                 Used to store data that can be referenced and manipulated in scripts.",
    "        2 Loops:                                       Control structures that repeat a block of code multiple times (e.g., for, foreach).",
    "        3 Switches:                                  A control structure that allows for multi-way branching based on the value of a variable.",
    "        4 Conditional Logic:                     Structures like if and else that allow for decision-making in scripts.",
    "        5 Arrays:                                      Collections of items stored in a single variable, allowing for indexed access.",
    "        6 Hash Tables:                             Key-value pairs that allow for efficient data retrieval.",
    "        7 Strings:                                      Sequences of characters used to represent text.",
    "        8 Operators:                                Symbols that perform operations on variables and values (e.g., arithmetic, comparison).",
    "        9 Brackets:                                  Brackets are used for various purposes, including defining arrays, hash tables, and grouping expressions.",
    "      10 CmdletBinding:                         A keyword used in function definitions to enable advanced function features, such as parameter validation.",
    "      11 Functions:                                 Blocks of code that perform a specific task and can be reused.",
    "      12 Modules:                                   Packages of PowerShell functions and resources that can be imported into scripts.",
    "      13 Pipeline:                                   A method for passing the output of one command as input to another.",
    "      14 Regular Expressions:                Patterns used to match character combinations in strings.",
    "      15 User Interfaces (GUIs):            Graphical interfaces for user interaction.",
    "      16 Error Handling:                         Techniques for managing errors in scripts to ensure smooth execution.",
    "      17 Objects:                                     Everything in PowerShell is an object, that can represent things like variables, files, or system processes."
)

# Create radio buttons and add them to the panel
for ($i = 0; $i -lt $topics.Count; $i++) {
    $RadioButton = New-Object system.Windows.Forms.RadioButton
    $RadioButton.Text = $topics[$i]
    $RadioButton.AutoSize = $true
    $RadioButton.Location = New-Object System.Drawing.Point(10, [int]($i * 24))  # Adjusted Y spacing for better fit
    $RadioButton.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 10)  # Adjusted font size for better visibility

    # Add CheckedChanged event to the radio button
    $RadioButton.Add_CheckedChanged({
        if ($RadioButton.Checked) {
            # Call PSedit for the selected radio button
            $scriptIndex = $Panel.Controls.IndexOf($RadioButton) + 1
            $filename = "$BasePath\GREP_Tbox_$scriptIndex.ps1"
            if (Test-Path $filename) {
                PSedit $filename
                $Form_MAIN.Close()  # Close the form after loading the script
            } else {
                [System.Windows.Forms.MessageBox]::Show("The script '$filename' does not exist.")
            }
        }
    })

    # Add the radio button to the panel
    $Panel.Controls.Add($RadioButton)
}

# 3. Create a button to activate the selected radio button
$ActivateButton = New-Object System.Windows.Forms.Button
$ActivateButton.Text = "Activate Selected"
$ActivateButton.Size = New-Object System.Drawing.Size(200, 30)

# Calculate the X position to center the button
$buttonX = [math]::Floor(($Form_MAIN.ClientSize.Width - $ActivateButton.Width) / 2)

# Set the button's location to center it horizontally on the form, and move it 3 lines down
$ActivateButton.Location = New-Object System.Drawing.Point($buttonX, 552)  # Move the button 3 lines down

# Add event handler for the button
$ActivateButton.Add_Click({
    # Check which radio button is selected
    $selectedRadioButton = $Panel.Controls | Where-Object { $_ -is [System.Windows.Forms.RadioButton] -and $_.Checked }
    if ($selectedRadioButton) {
        # Get the index of the selected radio button
        $scriptIndex = $Panel.Controls.IndexOf($selectedRadioButton) + 1
        $filename = "$BasePath\GREP_Tbox_$scriptIndex.ps1"
        
        # Check if the script file exists and open it
        if (Test-Path $filename) {
            PSedit $filename
            $Form_MAIN.Close()  # Close the form after loading the script
        } else {
            [System.Windows.Forms.MessageBox]::Show("The script '$filename' does not exist.")
        }
    } else {
        [System.Windows.Forms.MessageBox]::Show("Please select a topic to activate.")
    }
})

# Add the panel and button to the form
$Form_MAIN.Controls.Add($Panel)
$Form_MAIN.Controls.Add($ActivateButton)

# Show the form
$Form_MAIN.Add_Shown({$Form_MAIN.Activate()})
[void]$Form_MAIN.ShowDialog()
 


