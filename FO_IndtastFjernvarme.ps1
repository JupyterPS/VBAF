  Add-Type -AssemblyName System.Windows.Forms
  Add-Type -AssemblyName System.Drawing

  $form          = New-Object System.Windows.Forms.Form
  $label_KwH     = New-Object System.Windows.Forms.Label
  $label_m3      = New-Object System.Windows.Forms.Label
  $label_F       = New-Object System.Windows.Forms.Label
  $label_R       = New-Object System.Windows.Forms.Label
  $button_ok     = New-Object System.Windows.Forms.Button
  $button_cancel = New-Object System.Windows.Forms.Button
  $StatusBar     = New-Object System.Windows.Forms.StatusBar

  $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
  $form.Topmost = $True
  $form.Text = "Fjernvarme indberetning"
  $form.Add_Shown({ $form.Activate() })
  $form.AutoScaleBaseSize = New-Object System.Drawing.Size (5,13)
  $form.ClientSize = New-Object System.Drawing.Size (400,262)

  $label_KwH.Font = New-Object System.Drawing.Font ('Arial',10,[System.Drawing.FontStyle]::Bold,[System.Drawing.GraphicsUnit]::Point,0)
  $label_KwH.Location = New-Object System.Drawing.Point (16,88)
  $label_KwH.Size = New-Object System.Drawing.Size (168,24)
  $label_KwH.Text = 'KwH'
  $label_KwH.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft

  $label_m3.Font = New-Object System.Drawing.Font ('Arial',10,[System.Drawing.FontStyle]::Bold,[System.Drawing.GraphicsUnit]::Point,0)
  $label_m3.Location = New-Object System.Drawing.Point (16,112)
  $label_m3.Size = New-Object System.Drawing.Size (168,24)
  $label_m3.Text = 'm3'
  $label_m3.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft

  $label_F.Font = New-Object System.Drawing.Font ('Arial',10,[System.Drawing.FontStyle]::Bold,[System.Drawing.GraphicsUnit]::Point,0)
  $label_F.Location = New-Object System.Drawing.Point (16,136)
  $label_F.Size = New-Object System.Drawing.Size (168,24)
  $label_F.Text = 'Frem'
  $label_F.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft

  $label_R.Font = New-Object System.Drawing.Font ('Arial',10,[System.Drawing.FontStyle]::Bold,[System.Drawing.GraphicsUnit]::Point,0)
  $label_R.Location = New-Object System.Drawing.Point (16,160)
  $label_R.Size = New-Object System.Drawing.Size (168,24)
  $label_R.Text = 'Retur'
  $label_R.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft

  $textBox_1 = New-Object System.Windows.Forms.TextBox
  $textBox_1.Location = New-Object System.Drawing.Point(192,88)
  $textBox_1.Size = New-Object System.Drawing.Size(184,21)
  $textBox_1.Font = New-Object System.Drawing.Font("Segoe UI", 12)  # Bigger, clean font  
  $form.Controls.Add($textBox_1)

  $textBox_2 = New-Object System.Windows.Forms.TextBox
  $textBox_2.Location = New-Object System.Drawing.Point(192,112)
  $textBox_2.Size = New-Object System.Drawing.Size(184,21)
  $textBox_2.Font = New-Object System.Drawing.Font("Segoe UI", 12)  # Bigger, clean font
  $form.Controls.Add($textBox_2)

  $textBox_3 = New-Object System.Windows.Forms.TextBox
  $textBox_3.Location = New-Object System.Drawing.Point(192,136)
  $textBox_3.Size = New-Object System.Drawing.Size(184,21)
  $textBox_3.Font = New-Object System.Drawing.Font("Segoe UI", 12)  # Bigger, clean font
  $form.Controls.Add($textBox_3)

  $textBox_4 = New-Object System.Windows.Forms.TextBox
  $textBox_4.Location = New-Object System.Drawing.Point(192,160)
  $textBox_4.Size = New-Object System.Drawing.Size(184,21)
  $textBox_4.Font = New-Object System.Drawing.Font("Segoe UI", 12)  # Bigger, clean font
  $form.Controls.Add($textBox_4)

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
  $label_KwH,
  $label_m3,
  $label_F,
  $label_R,
  $button_ok,
  $button_cancel,
  $StatusBar))

  $form.Topmost = $true
  $form.Add_Shown({ $form.Activate() })

  $form.Add_Shown({$textBox_4.Select()})
  $form.Add_Shown({$textBox_3.Select()})
  $form.Add_Shown({$textBox_2.Select()})
  $form.Add_Shown({$textBox_1.Select()})

                 $result = $form.ShowDialog()

                 if ($result -eq [System.Windows.Forms.DialogResult]::OK)
                 {
                      $NYKwH = $textBox_1.Text
                      $NYm3  = $textBox_2.Text
                      $Frem  = $textBox_3.Text
                      $Retur = $textBox_4.Text
                 }

                 if ($result -eq [System.Windows.Forms.DialogResult]::Cancel)
                 {
                      exit
                 }

                 #Hent gamle coolingdata
                 $lastDataRow = (Get-Content "$basePath\FO_FjernvarmeForbrugÅret.txt")[-1]
                 $GLKwH = $lastDataRow.Substring(25,7)
                 $GLm3  = $lastDataRow.Substring(40,7)
                 $GlT8  = $lastDataRow.Substring(126,10)
                 $GlT9  = $lastDataRow.Substring(148,10)

                 #Beregn nye coolingdata
                 $Forb_KwH = $NYKwH - $GLKwH
                 $Forb_m3  = $NYm3  - $GLm3
                 #$Forb_m3 = "{0:00.00}" -f [double]$Forb_m3
                 $Cooling = ($Forb_KwH / $Forb_m3) * 860
                 $NyT8 = ($Forb_m3 * $Frem)
                 $NyT9 = ($Forb_m3 * $Retur)
                 $AccFT8 = $NyT8 + $GlT8
                 $AccRT9 = $NyT9 + $GlT9

                 $Pris = $Forb_KwH * 451.56
                 # 1..15 | % -begin {cls} -process {write-host "Pris for gårdsdagens fjernvarme: Kr."('{0:N2}' -f $Pris) -ForegroundColor Yellow;sleep 1;cls;sleep 1}

                 #Obtain date &   filepath
                 $date = Get-Date
                 $dato = $date.ToString("dd-MM-yyyy")
                 $LogFile = "$basePath\FO_FjernvarmeForbrugÅret.txt"

                 #Prepare data to be logged
                 $NYKwH =    ('{0:N3}' -f $NyKwH)
                 $NYm3 =     ('{0:N2}' -f $Nym3)
                 $Forb_KwH = ('{0:N3}' -f $Forb_KwH)
               # $Forb_m3 =  ('{0:N2}' -f $Forb_m3)
                 $Forb_m3 = '{0:000.00}' -f $Forb_m3                                                     # Indsætter foranstillede nuller                                                                                     # Indsætter foranstillede nuller
                 $Cooling =  ('{0:N3}' -f $Cooling)
                 $AccFT8 =   ('{0:N2}' -f $AccFT8)
                 $AccRT9 =   ('{0:N2}' -f $AccRT9)    

                 #Create line to   be logged
                 $LogLine = "Dato:=`"$dato`" " +`
                            "KwH:=`"$NYKwH`" " +`
                            "m3:= `"$NYm3`" " +`
                            "Cooling:= `"$Cooling`" " +`
                            "Periode - " +`
                            "Forb_KwH:= `"$Forb_KwH`" " +`
                            "Forb_m3:= `"$Forb_m3`" " +`
                            "AccFT8:= `"$AccFT8`" " +`
                            "AccRT9:= `"$AccRT9`" " +`
                            "F:= `"$Frem`" "  +`
                            "R:= `"$Retur`" "

                 #Write line to   the passed log file
                 Out-File -InputObject $LogLine -Append -NoClobber -Encoding Default -FilePath $LogFile -WhatIf:$False

                 #Kvittering til bruger
                 (Get-Content "$basePath\FO_FjernvarmeforbrugÅret.txt")








