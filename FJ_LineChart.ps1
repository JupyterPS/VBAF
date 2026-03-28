[void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms.DataVisualization")

# create chart object
$Chart = New-object System.Windows.Forms.DataVisualization.Charting.Chart
$ChartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
$Chart.ChartAreas.Add($ChartArea)
$ChartArea.BackColor = [System.Drawing.Color]::DarkBlue

                                     Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.SendKeys]::SendWait('^{r}')

                 $array = @()
                 $x = 1
                 While ($x -lt 10)
                 {
                      $lastDataRow = (Get-Content "$basePath\FO_FjernvarmeForbrug≈ret.txt")[-$x]
                      $array += ($lastDataRow.Substring(90,5))
                      $a = ($lastDataRow.Substring(16,1))
                 $x ++
                 }

                 $XArray = @()
                 $y=0
                 while ($y -lt $array.Count - 1)
                 {
                      $XArray += ($array[$y+1] - $array[$y])
                 $y++
                 }

                 #add title and axes labels†
                 $Days = $null
                 $y=0
                 while ($y -lt $array.Count)
                      {$Days += @{$y=$XArray[$y]}
                 $y++
                 }

                 [void]$Chart.Series.Add("Data")†
                 $Chart.Series["Data"].Points.DataBindXY($Days.Keys, $Days.Values)

                 $form = New-Object System.Windows.Forms.Form
                 $form.Text = "I dag og 7 dage bagud 2??$a"
                 $form.Size = New-Object System.Drawing.Size(330,360)
                 $form.StartPosition = 'CenterScreen'
                 $form.ForeColor = [System.Drawing.Color]::White
                 #$form.BackColor = "Grey"
                 $Form.controls.add($Chart)
                 $Form.Add_Shown({$Form.Activate()})

                 #legend
                 $legend = New-Object system.Windows.Forms.DataVisualization.Charting.Legend
                 $legend.name = "Legend1"
                 $Chart.Legends.Add($Legend)
                 $Legend.Docking = 'bottom'

                 # set chart type†
                 $Chart.Series["Data"].ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::SpLine
                 #$Chart.Series["Data"].ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::fastPoint

                 ############################################################################################
                 invoke-expression -Command $basePath\FJ_TempSving.ps1
                 ############################################################################################
 
                 $Form.ShowDialog()
 







