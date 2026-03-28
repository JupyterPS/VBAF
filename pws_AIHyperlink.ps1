Add-Type -AssemblyName System.Windows.Forms

# Create a form
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Hyperlink Example'
$form.Size = New-Object System.Drawing.Size(300, 200)
$form.StartPosition = 'CenterScreen'

# Create a link label
$linkLabel = New-Object System.Windows.Forms.LinkLabel
$linkLabel.Text = 'Click here to visit OpenAI website'
$linkLabel.AutoSize = $true
$linkLabel.Location = New-Object System.Drawing.Point(50, 50)

# Add an event handler for the link clicked event
$linkLabel.Add_Click({
    # Open the URL in the default web browser
    Start-Process 'https://openai.com'
})

# Add the link label to the form
$form.Controls.Add($linkLabel)

# Show the form
$form.ShowDialog() | Out-Null

# Dispose of the form
$form.Dispose()






