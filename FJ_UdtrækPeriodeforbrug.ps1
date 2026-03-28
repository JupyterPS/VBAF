# Define paths for Win10 and Win11
$pathWin11 = "C:\Users\henni\OneDrive\WindowsPowerShell"
$pathWin10 = "C:\Users\Henning\OneDrive\WindowsPowerShell"

# Determine the base path dynamically
if (Test-Path $pathWin11) {
    $basePath = $pathWin11
} else {
    $basePath = $pathWin10
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form 
$form.Size = New-Object System.Drawing.Size(365,250)
$form.StartPosition = 'CenterScreen'

$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Point(75,120)
$okButton.Size = New-Object System.Drawing.Size(75,23)
$okButton.Text = 'OK'
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $okButton
$form.Controls.Add($okButton)

$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Location = New-Object System.Drawing.Point(150,120)
$cancelButton.Size = New-Object System.Drawing.Size(75,23)
$cancelButton.Text = 'Cancel'
$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $cancelButton
$form.Controls.Add($cancelButton)

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(280,20)
$label.Text = 'Indtast i formatet DG-MD-YYYY'
$form.Controls.Add($label)

$label_1 = New-Object System.Windows.Forms.Label
$label_1.Location = New-Object System.Drawing.Point(30,65)
$label_1.Size = New-Object System.Drawing.Size(80,10)
$label_1.Text = 'Dato fra:'
$form.Controls.Add($label_1)
$label_1.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft

$label_2 = New-Object System.Windows.Forms.Label
$label_2.Location = New-Object System.Drawing.Point(30,89)
$label_2.Size = New-Object System.Drawing.Size(80,10)
$label_2.Text = 'Dato til:'
$form.Controls.Add($label_2)
$label_2.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft

$textBox_1 = New-Object System.Windows.Forms.TextBox
$textBox_1.Location = New-Object System.Drawing.Point(120,60)
$textBox_1.Size = New-Object System.Drawing.Size(120,20)
$form.Controls.Add($textBox_1)

$textBox_2 = New-Object System.Windows.Forms.TextBox
$textBox_2.Location = New-Object System.Drawing.Point(120,84)
$textBox_2.Size = New-Object System.Drawing.Size(120,20)
$form.Controls.Add($textBox_2)

$form.Add_Shown({$textBox_2.Select()})
$form.Add_Shown({$textBox_1.Select()})
$form.Topmost = $true

function Validate-And-ParseDate {
    param (
        [string]$dateString,
        [string]$dateFormat = 'dd-MM-yyyy'
    )
    try {
        return [datetime]::ParseExact($dateString, $dateFormat, $null)
    } catch {
        throw "Invalid date format: $dateString. Expected format is $dateFormat."
    }
}

function Validate-Date {
    param (
        [string]$dateString,
        [string]$dateFormat = 'dd-MM-yyyy'
    )
    try {
        [datetime]::ParseExact($dateString, $dateFormat, $null) | Out-Null
        return $true
    } catch {
        return $false
    }
}

$form.Add_Shown({$textBox_2.Select()})
$form.Add_Shown({$textBox_1.Select()})
$form.Topmost = $true

$path1 = "$basePath\FO_FjernvarmeForbrugåret.txt"
$path2 = "$basePath\FJ_FjernvarmeUdtræk.txt"
#Clear-Content "$basePath\FJ_FjernvarmeUdtræk.txt"  #Gammelt udtræk

# hent fra/til datoer i input
$result = $form.ShowDialog()

if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
    # valider til og fra datoer
    $Valid = $false
    while (-not $Valid) {
        $IndFra_S = $textBox_1.Text
        $dateToValidate = $IndFra_S

        if (Validate-Date $dateToValidate) {
            #"Datoen er gyldig"
            $Valid = $true
        } else {
            Write-Warning "Datoen er ugyldig"
            $result = $form.ShowDialog()
        }
    }

    $Valid = $false
    while (-not $Valid) {
        $IndTil_S = $textBox_2.Text
        $dateToValidate = $IndTil_S

        if (Validate-Date $dateToValidate) {
            #"Datoen er gyldig"
            $Valid = $true
        } else {
            Write-Warning "Datoen er ugyldig"
            $result = $form.ShowDialog()
        }
    }
}

if ($result -eq [System.Windows.Forms.DialogResult]::Cancel) {
    exit
}

try {
    # Reset date range (due to asynchronous consumption registration)
    $Date1 = Validate-And-ParseDate -dateString $IndFra_S
    $Date2 = Validate-And-ParseDate -dateString $IndTil_S

    [int]$x = $Date1.Month
    [int]$y = $Date2.Month

    if (($x -In 1..12) -or ($y -In 1..12)) {
        if ($x -In 1..12) {
            $IndFra_S = (Get-Date -Year $Date1.Year -Month $Date1.Month -Day 1).ToString("dd-MM-yyyy")
        }

        if ($y -In 1..12) {
            $IndTil_S = (Get-Date -Year $Date2.Year -Month $Date2.Month -Day 1).ToString("dd-MM-yyyy")
        }

        $textBox_1.Text = $IndFra_S
        $textBox_2.Text = $IndTil_S
    }

    # Reset start date
    $Datemin = Validate-And-ParseDate -dateString "01-11-2020"
    $Date1 = Validate-And-ParseDate -dateString $IndFra_S

    if ($Date1 -lt $Datemin) {
        $IndFra_S = "01-11-2020"
        $Date1 = Validate-And-ParseDate -dateString $IndFra_S
        $textBox_1.Text = $IndFra_S
    }

    # Reset end date
    $Datemax = Get-Date
    $Date2 = Validate-And-ParseDate -dateString $IndTil_S

    if ($Date2 -gt $Datemax) {
        $IndTil_S = (Get-Date).ToString("dd-MM-yyyy")
        $Date2 = Validate-And-ParseDate -dateString $IndTil_S
        $IndTil_S = (Get-Date -Year $Date2.Year -Month $Date2.Month -Day 1).AddDays(-1).ToString("dd-MM-yyyy")
        $textBox_2.Text = $IndTil_S
    }

    $IndFra_S = (Get-Date -Year $Date1.Year -Month $Date1.Month -Day 1).AddDays(-1).ToString("dd-MM-yyyy")
    $IndTil_S = (Get-Date -Year $Date2.Year -Month $Date2.Month -Day 1).AddDays(-1).ToString("dd-MM-yyyy")

    $textBox_1.Text = $IndFra_S
    $textBox_2.Text = $IndTil_S
    $label.Text = '                   >>>  Datoerne er ændret  <<<        '
    Write-Warning "Grundet asynkron forbrugsregistrering, er datoerne ændret"
    $result = $form.ShowDialog()

} catch {
    Write-Error $_.Exception.Message
}

$Lines = get-content -Path $path1

# hent fra - til i hele talmaterialet
foreach($Line in $Lines) {
    if ($IndFra_S -eq $Line.Substring(7,10)) {
        Out-File -InputObject $Line -Append -NoClobber -Encoding Default -FilePath $Path2 -WhatIf:$False
    }

    if ($IndTil_S -eq $Line.Substring(7,10)) {
        Out-File -InputObject $Line -Append -NoClobber -Encoding Default -FilePath $Path2 -WhatIf:$False
    }
}
  # send tal til visning
  invoke-expression -Command $basePath\FJ_VisPeriodeForbrug.ps1