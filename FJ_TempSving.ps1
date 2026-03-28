                 Add-Type -AssemblyName System.Windows.Forms
                 Add-Type -AssemblyName System.Drawing
                 [System.Windows.Forms.Application]::EnableVisualStyles()

                 $array = @()
                 $x = 1
                 While ($x -lt 9)
                 {
                       $lastDataRow = (Get-Content "$basePath\FO_FjernvarmeForbrugÅret.txt")[-$x]
                       $array += ($lastDataRow.Substring(90,5))
                       $a = ($lastDataRow.Substring(15,2))
                 $x ++
                 }

                 $help = @()
                 $XArray = @()
                 $x=0
                 while ($x -lt $array.Count-1)
                 {
                       $XArray += ($array[$x+1] - $array[$x])
                       $help += [math]::Round($XArray[$x],3)
                 $x++
                 }

                 $date = (Get-Date).DayOfWeek
                 $day  = "$date"[0..2] -join ""

                 $engray = @("Sun","Sat","Fri","Thu","Wed","Tue","Mon","Sun","Sat","Fri","Thu","Wed","Tue","Mon")
                 $danray = @("Søn","Lør","Fre","Tor","Ons","Tir","Man","Søn","Lør","Fre","Tor","Ons","Tir","Man")

                 $x = 0
                 while ($day -ne $engray[$x])
                 {
                 $x ++
                 }

                 $y = $x
                 $day1=$danray[$y];$day2=$danray[$y+1];$day3=$danray[$y+2];$day4=$danray[$y+3];$day5=$danray[$y+4];$day6=$danray[$y+5];$day7=$danray[$y+6]

                 $Title = "               $day1??$a         ~~         $day2??$a           ~~          $day3??$a           ~~           $day4??$a         ~~           $day5??$a         ~~           $day6??$a            ~~         $day7??$a"

                      $options = $help
                      $DefaultChoice = 1
                      $script:result = ""
                      $form = New-Object System.Windows.Forms.Form
                      $form.FormBorderStyle = [Windows.Forms.FormBorderStyle]::FixedDialog
                      #$form.BackColor = [Drawing.Color]::'PeachPuff'
                      $form.BackColor = [Drawing.Color]::'Darkblue'
                      $form.ForeColor = "Black"
                      $form.TopMost = $True
                      $form.Text = $Title
                      $form.ControlBox = $False
                      $form.StartPosition = [Windows.Forms.FormStartPosition]::Manual
                      #$form.StartPosition = [Windows.Forms.FormStartPosition]::CenterScreen
                      #calculate width required based on longest option text and form title
                      $minFormWidth = 100
                      $formHeight = 44

                      $minButtonWidth = 110
                      $buttonHeight = 23
                      $buttonY = 12
                      $spacing = 10
                      $buttonWidth = [Windows.Forms.TextRenderer]::MeasureText((($Options | sort Length)[-1]),$form.Font).Width + 1
                      $buttonWidth = [Math]::Max($minButtonWidth, $buttonWidth)
                      $formWidth =  [Windows.Forms.TextRenderer]::MeasureText($Title,$form.Font).Width
                      $spaceWidth = ($options.Count+1) * $spacing
                      $formWidth = ($formWidth, $minFormWidth, ($buttonWidth * $Options.Count + $spaceWidth) | Measure-Object -Maximum).Maximum
                      $form.ClientSize = New-Object System.Drawing.Size($formWidth,$formHeight)

                      $index = 0
                      #create the buttons dynamically based on the options
                      foreach ($option in $Options)
                      {
                           Set-Variable "button$index" -Value (New-Object System.Windows.Forms.Button)
                           $temp = Get-Variable "button$index" -ValueOnly
                           $temp.Size = New-Object System.Drawing.Size($buttonWidth,$buttonHeight)
                           $temp.UseVisualStyleBackColor = $True
                           $temp.Text = $option
                           $buttonX = ($index + 1) * $spacing + $index * $buttonWidth
                           $temp.Add_Click({
                               $script:result = $this.Text; $form.Close()
                           })
                           $temp.Location = New-Object System.Drawing.Point($buttonX,$buttonY)
                           $form.Controls.Add($temp)
                      $index++
                      }
                      $shownString = '$this.Activate();'
                      if ($DefaultChoice -ne -1){
                           $shownString += '(Get-Variable "button$($DefaultChoice-1)" -ValueOnly).Focus()'
                      }
                      $shownSB = [ScriptBlock]::Create($shownString)
                      $form.Add_Shown($shownSB)

                      [void]$form.ShowDialog()












