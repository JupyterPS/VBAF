CLS
#load the appropriate assemblies
[void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms.DataVisualization")

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.SendKeys]::SendWait('^{r}')

#create chart
$Chart = New-object System.Windows.Forms.DataVisualization.Charting.Chart 
$Chart.Width = 500
$Chart.Height = 400
$Chart.Left = 40
$Chart.Top = 30

#create a chartarea to draw on and add to chart
$ChartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
$Chart.ChartAreas.Add($ChartArea)

#listbox form
$form = New-Object System.Windows.Forms.Form
$form.Text = 'VandChart 2019'
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
$label.Text = '                          Vælg 3 årig periode'
$form.Controls.Add($label)

#listbox
$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(10,40)
$listBox.Size = New-Object System.Drawing.Size(260,20)
$listBox.Height = 135

                 #opsæt fjernvarmeår i listbox
                 [void] $listBox.Items.Add('                                  ')
                 $y=2019
                 $x=2020
                 $z=2021
                 $count = 1
                 $Xyear = @()
                 $antyear = (Get-Date).year - 2019
                 While ($count -lt $antyear)
                 {
                      $Xyear += @("$y $x $z")
                      $y++
                      $x++
                      $z++
                      $count ++
                 }

                 [void]$listBox.Items.AddRange($Xyear)
                 $form.Controls.Add($listBox)
                 $form.Topmost = $true
                 $result = $form.ShowDialog()

                 if ($result -eq [System.Windows.Forms.DialogResult]::OK)
                 {
                      $Year = $listBox.SelectedItem.Substring(0,4) -1
                 }
                 if ($result -eq [System.Windows.Forms.DialogResult]::CANCEL)
                 {
                      break
                 }

                 #sæt de udvalgte årstal
                 $Hide = $Year
                 [int]$z = $Year
                 $Yea1 = $Year+1
                 $Yea2 = $Year+2
                 $Yea3 = $Year+3

                 #hent sidste dato i måneden
                 $count = 1
                 $array = @()
                 While ($count -lt $antyear)
                 {
                      $array += 0..12 | % { (New-Object DateTime(("$z"),12,31)).AddMonths($_).ToString("dd-MM-yyyy") }
                      $z++
                      $count++
                 }

                 #fjerner dubletter
                 $array = $array | Select-Object -Unique

                 #hent kwh for perioden
                 $x=0
                 $myArray = @()
                 while ($x -lt $array.Count)
                 {
                      $match = $array[$x]
                      foreach($line in Get-Content -Path "$basePath\FO_VandForbrugÅret.txt")
                      {
                           if ($line.Substring(7,10) -match $match)
                           {
                               $myArray += ($Line.Substring(26,7))
                           }
                      }
                 $x++
                 }

                 #klargør til visning
                 $Labels = @()
                 $XArray = @()
                 $y=0
                 while ($y -lt 36)
                 {
                      $XArray += ($myArray[$y+1] - $myArray[$y]) 
                      If ($XArray[$y] -lt 0)
                      {
                           $XArray[$y] = 0
                      }
                      $Labels += (" ")
                 $y++
                 }
                
                 #add title and axes labels
                 [void]$Chart.Titles.Add("                                   VANDVÆRKET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            .            .$yea1                                          .$yea2                                     .$yea3")
                 $ChartArea.AxisX.Title = "J F M A M J J A S O N D J F M A M J J A S O N D J F M A M J J A S O N D"
                 $ChartArea.AxisY.Title = "Vandforbrug i m3"

                 #DataBindXY dannes
                 $Counter = $XArray

                 ############################################################################################
                 [void]$Chart.Series.Add("Data")
                 $Chart.Series[“Data”].Points.DataBindXY($Labels,$Counter)
                 ############################################################################################

                 #display the chart on a form
                 $Chart.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right -bor
                                 [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left

                 #change chart area colour
                 $Chart.BackColor = [System.Drawing.Color]::Transparent

                 #make bars into 3d cylinders
                 $Chart.Series["Data"]["DrawingStyle"] = "Cylinder"

                 #create form
                 $Form = New-Object Windows.Forms.Form
                 $Form.Text = "PowerShell Chart - Forbrug over en 3 årig periode"
                 $Form.Width = 600
                 $Form.Height = 550
                 $Form.controls.add($Chart)
                 $Form.Add_Shown({$Form.Activate()})

                 #add a save button
                 $SaveButton = New-Object Windows.Forms.Button
                 $SaveButton.Text = "Save"
                 $SaveButton.Top = 500
                 $SaveButton.Left = 450
                 $SaveButton.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right

                 ##############################################################################################################
                 Invoke-expression -Command $basePath\FO_Vand3ÅrsforbrugChart1.ps1
                 ##############################################################################################################

                 #Resten kører efter kald til Chart1
                 #omfordel måneder rød,gul,grøn jan, febr, osv.
                 $Labels = (“.”,“.”,”.”,“.”,".",".",".",".",".",".",".",".",“.”,“.”,”.”,“.”,".",".",".",".",".",".",".",".",“.”,“.”,”.”,“.”,".",".",".",".",".",".",".",".")
                 $New_Counter = @()
                 $x = 0
                 $y = 12
                 $z = 24
                 while ($x -lt 12)
                 {
                      $New_Counter += $Counter[$x]
                      $New_Counter += $Counter[$y + $x]
                      $New_Counter += $Counter[$z + $x]
                 $x++
                 }

                 ############################################################################################
                 #[void]$Chart.Series.Add("Data")
                 $Chart.Series[“Data”].Points.DataBindXY($Labels,$New_Counter)
                 ############################################################################################

                 #saml måneder rød,gul,grøn jan, febr, osv.
                 $Count = 0
                 $ThisYear = (Get-Date).Year
                 $chart.Series["Data"].points | ForEach-Object {

                 $array = (0,3,6,9,12,15,18,21,24,27,30,33)
                      if ($Count -in $array)
                      {    
                           if ($yea1 -ge 2019 -and $year -le $ThisYear)                       
                           {  
                                $PSItem.Color = [System.Drawing.Color]::Red  
                           } 
                           else {$PSItem.Color = [System.Drawing.Color]::Yellow}                      
                      }

                 $array = (1,4,7,10,13,16,19,22,25,28,31,34)
                      if ($Count -in $array)
                      {                            
                           if ($yea2 -ge 2020 -and $year -le $ThisYear)                           
                           {  
                                $PSItem.Color = [System.Drawing.Color]::Yellow   
                           }        
                           else {$PSItem.Color = [System.Drawing.Color]::Green}                      
                      }

                 $array = (2,5,8,11,14,17,20,23,26,29,32,35)
                      if ($Count -in $array)
                      {                               
                           if ($yea3 -ge 2021 -and $year -le $ThisYear)                           
                           {  
                                $PSItem.Color = [System.Drawing.Color]::Green 
                           }                           
                      }
                 $Count++
                 }

                 #show form
                 $Form.Add_Shown({$Form.Activate()})
                 $Form.ShowDialog()
 








