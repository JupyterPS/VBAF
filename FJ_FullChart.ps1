[void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms.DataVisualization")

# create chart object
$Chart = New-object System.Windows.Forms.DataVisualization.Charting.Chart
$ChartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
$Chart.ChartAreas.Add($ChartArea)
$ChartArea.BackColor = [System.Drawing.Color]::DarkBlue
$Chartarea.AxisX.Minimum = 1
$Chartarea.AxisX.Maximum = 800
$Chartarea.AxisY.IsStartedFromZero = 0

                 $Array = Get-Content -Path $basePath\FO_FjernvarmeForbrug≈ret.txt
                 $Count = $Array.count

                 $array = @()
                 $x = 1
                 While ($x -lt $Count)
                 {
                      $lastDataRow = (Get-Content "$basePath\FO_FjernvarmeForbrug≈ret.txt")[-$x]
                      $array += ($lastDataRow.Substring(90,5))                                           
                 $x ++
                 }

                 [array]::Reverse($array)
 
                 #fyld x,y axen†
                 $Days = $null
                 $y=0
                 while ($y -lt $array.Count)
                      {$Days += @{$y=$Array[$y]}
                 $y++
                 }         
                 
                 #add title and axes labels
                 [void]$Chart.Series.Add("Data")†
                 $Chart.Series["Data"].Points.DataBindXY($Days.Keys, $Days.Values)                                  
                 [void]$Chart.Titles.Add("FJERNVARMECENTRALEN")
                 $ChartArea.AxisX.Title = "2021                                                                                                                          2022                                                                                                                      2023"
                 $ChartArea.AxisY.Title = "Varmeforbrug i KwH"
                                    

                 $Chart.Width = 1350
                 $Chart.Height = 300
                 $Chart.Left = 0
                 $Chart.Top = 10
                 
                 $form = New-Object System.Windows.Forms.Form
                 $form.Text = "Hele perioden 2??2?? til nu"
                 $form.Size = New-Object System.Drawing.Size(1350,385)
                 $form.StartPosition = 'CenterScreen'
                 $form.ForeColor = [System.Drawing.Color]::White              
                 $Form.controls.add($Chart)
                 $Form.Add_Shown({$Form.Activate()})

                 #legend
                 $legend = New-Object system.Windows.Forms.DataVisualization.Charting.Legend
                 $legend.name = "Legend1"
                 $Chart.Legends.Add($Legend)
                 $Legend.Docking = 'bottom'

                 #set chart type†
                 $Chart.Series["Data"].ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Line                              

                 $Form.ShowDialog()







