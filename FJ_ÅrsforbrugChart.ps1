CLS
#load the appropriate assemblies
[void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms.DataVisualization")

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.SendKeys]::SendWait('^{r}')

#create chart
$Chart = New-Object System.Windows.Forms.DataVisualization.Charting.Chart
$Chart.Width = 1400
$Chart.Height = 500
$Chart.Left = Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

#create a chartarea to draw on and add to chart
$ChartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
$Chart.ChartAreas.Add($ChartArea)

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Fjernvarme 2020 ==>'
$form.Size = New-Object System.Drawing.Size(300,280)
$form.StartPosition = 'CenterScreen'

#legend
$legend = New-Object system.Windows.Forms.DataVisualization.Charting.Legend
$legend.name = "Legend1"
$Chart.Legends.Add($Legend)
$Legend.Docking = 'bottom'

$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Point(75,190)
$okButton.Size = New-Object System.Drawing.Size(75,23)
$okButton.Text = 'OK'
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $okButton
$form.Controls.Add($okButton)

$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Location = New-Object System.Drawing.Point(150,190)
$cancelButton.Size = New-Object System.Drawing.Size(75,23)
$cancelButton.Text = 'Cancel'
$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $cancelButton
$form.Controls.Add($cancelButton)

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(280,20)
$label.Text = '                   Listen udviddes automatisk :-)'
$form.Controls.Add($label)

$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(10,40)
$listBox.Size = New-Object System.Drawing.Size(260,20)
$listBox.Height = 135

                 #opsæt fjernvarmeår i listbox
                 [void] $listBox.Items.Add('2020')
                 $count=1
                 $Xyear = @()
                 $antyear = (Get-Date).year - 2019
                 While ($count -lt $antyear)
                 {
                      $Xyear += (2020 + $count)
                      $count++
                 }

                 [void] $listBox.Items.AddRange($Xyear)
                 $form.Controls.Add($listBox)
                 $form.Topmost = $true
                 $result = $form.ShowDialog()

                 if ($result -eq [System.Windows.Forms.DialogResult]::OK)
                 {
                      $Year = $listBox.SelectedItem -1
                 }
                 if ($result -eq [System.Windows.Forms.DialogResult]::CANCEL)
                 {
                      break
                 }

                 #hent sidste dato i måneder
                 $myArray = @()
                 $array = 0..12 | % { (New-Object DateTime(($Year),12,31)).AddMonths($_).ToString("dd-MM-yyyy") }

                 #hent kwh i perioden
                 $x=0
                 while ($x -lt $array.Count)
                 {
                      $match = $array[$x]
                      foreach($line in Get-Content -Path "$basePath\FO_FjernvarmeForbrugÅret.txt")
                      {
                           if ($line.Substring(7,10) -match $match)
                           {
                                $myArray += ($Line.Substring(25,7))
                           }
                      }
                 $x++
                 }

                 #klargør til visning
                 $XArray = @()
                 $y=0
                 while ($y -lt $array.Count)
                 {
                      $XArray += ($myArray[$y+1] - $myArray[$y])  * 1000
                      If ($XArray[$y] -lt 0)
                      {
                           $XArray[$y] = 0
                      }
                      $Labels += (" ")
                 $y++
                 }

                 #add title and axes labels
                 $Labels = “Jan”, “Feb”, ”Mar”, “Apr”, "Maj", "Jun", "Jul", "Aug", "Sep", "Okt", "Nov", "Dec", " "
                 $Counter = $XArray

                 ############################################################################################
                 [void]$Chart.Series.Add("Data")
                 $Chart.Series[“Data”].Points.DataBindXY($Labels,$Counter)
                 ############################################################################################

                 #display the chart on a form
                 $Chart.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right -bor
                                 [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left

                 #add title and axes labels
                 [void]$Chart.Titles.Add("Årsforbrug målt i KWH * 1000")
                 $ChartArea.AxisX.Title = "Måned"
                 $ChartArea.AxisY.Title = "Forbrug"
                 $chartarea.AxisY.Interval = 100
                 $chartarea.AxisX.Interval = 1

                 #add a save button
                 $SaveButton = New-Object Windows.Forms.Button
                 $SaveButton.Text = "Tryk her"
                 $SaveButton.Top = 520
                 $SaveButton.Left = 1178
                 $SaveButton.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right

                 #########################################################################################################
                 invoke-expression -Command $basePath\FJ_ÅrsforbrugChart1.ps1
                 #########################################################################################################

                 #create form og visning
                 $Form = New-Object Windows.Forms.Form
                 $show = $year + 1
                 $Form.Text = "PowerShell Chart - Forbrug i $show"
                 $Form.Width = 1400
                 $Form.Height = 600
                 $Form.controls.add($Chart)
                 $Form.controls.add($SaveButton)

                 #################################################################
                 #set chart options - CYLINDER
                 $maxValue = $Chart.Series["Data"].Points.FindMaxByValue()
                 $maxValue.Color = [System.Drawing.Color]::Red
                 $minValue = $Chart.Series["Data"].Points.FindMinByValue()
                 $minValue.Color = [System.Drawing.Color]::Yellow
                 $Chart.Series["Data"]["DrawingStyle"] = "Cylinder"
                 #################################################################

                 $Form.Add_Shown({$Form.Activate()})
                 $Form.ShowDialog()

                 Write-Host $Year
                 Write-Host $myArray








