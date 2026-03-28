Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

  $form          = New-Object System.Windows.Forms.Form
  $label_m3      = New-Object System.Windows.Forms.Label
  $button_ok     = New-Object System.Windows.Forms.Button
  $button_cancel = New-Object System.Windows.Forms.Button
  $StatusBar     = New-Object System.Windows.Forms.StatusBar

  $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
  $form.Topmost = $True
  $form.Text = "Vand indberetning"
  $form.Add_Shown({ $form.Activate() })
  $form.AutoScaleBaseSize = New-Object System.Drawing.Size (5,13)
  $form.ClientSize = New-Object System.Drawing.Size (400,262)

  $label_m3.Font = New-Object System.Drawing.Font ('Arial',10,[System.Drawing.FontStyle]::Bold,[System.Drawing.GraphicsUnit]::Point,0)
  $label_m3.Location = New-Object System.Drawing.Point (16,88)
  $label_m3.Size = New-Object System.Drawing.Size (168,24)
  $label_m3.Text = 'm3'
  $label_m3.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft

  $textBox_1 = New-Object System.Windows.Forms.TextBox
  $textBox_1.Location = New-Object System.Drawing.Point(192,88)
  $textBox_1.Size = New-Object System.Drawing.Size(184,21)
  $textBox_1.Font = New-Object System.Drawing.Font("Segoe UI", 12)  # Bigger, clean font  
  $form.Controls.Add($textBox_1)

  $button_ok.Font = New-Object System.Drawing.Font ('Arial',10,[System.Drawing.FontStyle]::Bold,[System.Drawing.GraphicsUnit]::Point,0)
  $button_ok.Location = New-Object System.Drawing.Point(312,16)
  $button_ok.Size = New-Object System.Drawing.Size(64,24)
  $button_ok.Text = 'OK'
  $button_ok.DialogResult = [System.Windows.Forms.DialogResult]::OK
  $form.AcceptButton = $button_ok

  $button_cancel.Font = New-Object System.Drawing.Font ('Arial',10,[System.Drawing.FontStyle]::Bold,[System.Drawing.GraphicsUnit]::Point,0)
  $button_cancel = New-Object System.Windows.Forms.Button
  $button_cancel.Location = New-Object System.Drawing.Point(312,48)
  $button_cancel.Size = New-Object System.Drawing.Size(64,24)
  $button_cancel.Text = 'Cancel'
  $button_cancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
  $form.CancelButton = $button_cancel

  $StatusBar.Name = "statusBar"
  $StatusBar.Text = "Godmorgen"

  $form.Controls.AddRange(@(
  $label_m3,
  $button_ok,
  $button_cancel,
  $StatusBar))

  $form.Topmost = $true
  $form.Add_Shown({ $form.Activate() })

  $form.Add_Shown({$textBox_1.Select()})

                 $result = $form.ShowDialog()

                 if ($result -eq [System.Windows.Forms.DialogResult]::OK)
                 {
                      $NYm3  = $textBox_1.Text
                 }

                 if ($result -eq [System.Windows.Forms.DialogResult]::Cancel)
                 {
                      exit
                 }

                 #Obtain date & filepath
                 $date = Get-Date
                 $dato = $date.ToString("dd-MM-yyyy")
                 $LogFile = "$basePath\FO_VandForbrug≈ret.txt"

                 #Prepare data to be logged
                 $NYm3 = ('{0:N3}' -f $Nym3)
   
                 #Create line to be logged
                 $LogLine = "Dato:=`"$dato`"  " +        
                            "m3:= `"$NYm3`" "                        

                 #Write line to the passed log file
                 Out-File -InputObject $LogLine -Append -NoClobber -Encoding Default -FilePath $LogFile -WhatIf:$False

                 #Kvittering til bruger
                 (Get-Content "$basePath\FO_Vandforbrug≈ret.txt")







