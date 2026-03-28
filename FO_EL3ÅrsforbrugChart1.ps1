#CLS
[void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms.DataVisualization")

#create chart
$Chart = New-object System.Windows.Forms.DataVisualization.Charting.Chart 
$Chart.Width = 500
$Chart.Height = 400
$Chart.Left = 40
$Chart.Top = 30

#create a chartarea to draw on and add to chart
$ChartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
$Chart.ChartAreas.Add($ChartArea)

#legend
$legend = New-Object system.Windows.Forms.DataVisualization.Charting.Legend
$legend.name = "Legend1"
$Chart.Legends.Add($Legend)
$Legend.Docking = 'bottom'
 
#add title and axes labels
[void]$Chart.Titles.Add("                                                            EL*CENTRALEN                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            .            .$yea1                                          .$yea2                                     .$yea3")
$ChartArea.AxisX.Title = "J F M A M J J A S O N D J F M A M J J A S O N D J F M A M J J A S O N D"
$ChartArea.AxisY.Title = "EL*Forbrug i KwH"

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

$Form = New-Object Windows.Forms.Form
$Form.Text = "PowerShell Chart"
$Form.Width = 600
$Form.Height = 550
$Form.controls.add($Chart)

                 #add colors
                 $Count = 1
                 $ThisYear = (Get-Date).Year
                 $chart.Series["Data"].points | ForEach-Object {
                      if ($Count -lt 13)
                      {                          
                           if ($yea1 -ge 2019 -and $year -le $ThisYear)
                           {  
                                $PSItem.Color = [System.Drawing.Color]::Red  
                           } 
                           else {$PSItem.Color = [System.Drawing.Color]::Yellow} 
                      }
                      elseif
                           ($Count -gt 12 -and $Count -lt 25)
                           {                                
                                if ($yea2 -ge 2020 -and $year -le $ThisYear)
                                {  
                                     $PSItem.Color = [System.Drawing.Color]::Yellow   
                                }        
                                else {$PSItem.Color = [System.Drawing.Color]::Green} 
                           }
                           else
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






