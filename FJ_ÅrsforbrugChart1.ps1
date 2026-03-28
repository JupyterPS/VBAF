CLS
#load the appropriate assemblies 
[void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms.DataVisualization")
 
#create chart
$Chart = New-Object System.Windows.Forms.DataVisualization.Charting.Chart
$Chart.Width = 1400
$Chart.Height = 500
$Chart.Left = Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

#create a chartarea to draw on and add to chart
$ChartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
$Chart.ChartAreas.Add($ChartArea)

#legend  
$legend = New-Object system.Windows.Forms.DataVisualization.Charting.Legend
$legend.name = "Legend1" 
$Chart.Legends.Add($Legend) 
$Legend.Docking = 'bottom'

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

#create form
$Form = New-Object Windows.Forms.Form
$show = $year + 1
$Form.Text = "PowerShell Chart - Forbrug i $show"
$Form.Width = 1400
$Form.Height = 600
$Form.controls.add($Chart)
$Form.controls.add($SaveButton)

#################################################################
#set chart options - PIE
$Chart.Series["Data"]["PieLabelStyle"] = "Outside"
$Chart.Series["Data"]["PieLineColor"] = "Black"
$Chart.Series["Data"]["PieDrawingStyle"] = "Concave"
($Chart.Series["Data"].Points.FindMaxByValue())["Exploded"] = $true

#set chart type
$Chart.Series["Data"].ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Pie 
#################################################################  
 
$Form.Add_Shown({$Form.Activate()})
$Form.ShowDialog()

Write-Host $Year
Write-Host $myArray

 






