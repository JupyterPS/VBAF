<#   
                    
                                                  G R E P   

                        1.Indtast søgeord                           Der søges i nedenstående txt.filer + filer på discen    300

                        x.Eller indtast linienummeret der står nederst på siden >> Ln og Col
                         
                        2.L👀kupCmdLets                             SS64 og PDQ => detail beskriver cmdlets                 500

                        3.LookupFunc                                Microsofts functions i modules (halvfabrikata)        2.000

                        4.LookupSnips                               Tilsvarende ScriptSnippets i Github (halvfabrikata)   1.200

                                                                                                                          _____
 
                                                                                                                          4.000      
ChatGpt API
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
                                                                                                                           #>   
[void][System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') 
[System.Windows.Forms.SendKeys]::SendWait("^{r}")   
Add-Type -AssemblyName System.Drawing
cls
$form          = New-Object System.Windows.Forms.Form
$label_txt     = New-Object System.Windows.Forms.Label    
$button_ok     = New-Object System.Windows.Forms.Button
$StatusBar     = New-Object System.Windows.Forms.StatusStrip

$form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$form.Topmost = $True
$form.Text = "P o w e r  G R E P"
$form.Add_Shown({ $form.Activate() })
$form.ClientSize = New-Object System.Drawing.Size (450,192)

# Label settings
$label_txt.Font = New-Object System.Drawing.Font ('Arial',10,[System.Drawing.FontStyle]::Bold,[System.Drawing.GraphicsUnit]::Point,0)
$label_txt.Location = New-Object System.Drawing.Point (10,40)
$label_txt.Size = New-Object System.Drawing.Size (80,30)
$label_txt.Text = 'Søgeord'
$label_txt.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft 
$form.Controls.Add($label_txt)

# Updated TextBox with multiline, larger font, and better size
$textBox_1 = New-Object System.Windows.Forms.TextBox
$textBox_1.BorderStyle = [System.Windows.Forms.BorderStyle]::None
$textBox_1.Location = New-Object System.Drawing.Point(97, 40)
$textBox_1.Multiline = $true  # Allows vertical resizing
$textBox_1.Size = New-Object System.Drawing.Size(300, 25)
$textBox_1.Font = New-Object System.Drawing.Font("Segoe UI", 12)  # Bigger, clean font
$form.Controls.Add($textBox_1)

# OK Button
$button_ok.Font = New-Object System.Drawing.Font ('Arial',10,[System.Drawing.FontStyle]::Bold,[System.Drawing.GraphicsUnit]::Point,0)
$button_ok.Location = New-Object System.Drawing.Point(333,115)
$button_ok.Size = New-Object System.Drawing.Size(64,24)
$button_ok.Text = 'OK'
$button_ok.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $button_ok
$form.Controls.Add($button_ok)

# Create a label to go in the status strip
$statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
$statusLabel.Text = "Godmorgen"

# Add the label to the status strip
$StatusBar.Items.Add($statusLabel)

# Add the status strip to the form
$form.Controls.Add($StatusBar)

  $form.Controls.AddRange(@(
  $label_txt, 
  $button_ok,
  $StatusBar))

  $form.Topmost = $true
  $form.Add_Shown({ $form.Activate() }) 
  $form.Add_Shown({$textBox_1.Select})
  

                $result = $form.ShowDialog() 
                if ($result -eq [System.Windows.Forms.DialogResult]::OK)
                {
                     $txt = $textBox_1.Text  
                }

                # Nedenstående kode er kun beregnet til at indsætte tabs, for at kunne arbejde "DIREKTE" i sourcen, få ideer til søgeord osv.
                # Lukket ned ved alm. brug af GREP
                If ($txt -eq "Tabs_on") {               
                      #[System.Windows.Forms.SendKeys]::SendWait("^{2}")                       # Tabs can be displayed (just tabs show)
                      # Define tabs and their content
                      $Tabs = [ordered]@{
                      'Tab One' = @(                                     
                              "$basePath\GREP_LookUpCmdLets.ps1"      
                              "$basePath\GREP_LookUpFunc.ps1"
                              "$basePath\GREP_LookUpSnips.ps1"                       
                              "$basePath\GREP_PWSprof.ps1"                              
                              "$basePath\GREP.ps1"                                                   
                      )
                      }
                
                # Loop through the tab definitions until we reach one that hasn't been configured yet 
                foreach($tabDef in $Tabs.GetEnumerator()){                     
                
                     if(-not $psISE.PowerShellTabs.Where({$_.DisplayName -eq $tabDef.Name})){
                
                          # Set the name of the tab that was just created
                          $psISE.CurrentPowerShellTab.DisplayName = $tabDef.Name
                
                          # Open the corresponding files
                          foreach($file in Get-Item -Path $tabDef.Value){
                               $psISE.CurrentPowerShellTab.Files.Add($file.FullName)
                          }
                          cls
                          return
                     }
                }     
                } 

                if ($result -eq [System.Windows.Forms.DialogResult]::Cancel)
                {
                     exit
                } 

                if ([string]::IsNullOrWhiteSpace($txt))
                {
                    Write-Host "Feltet skal udfyldes"
                    exit
                } 
               
                if ($txt -match '^\d+$')                                                     # Numeric hit >>> second time around 
                {                    
                     if (-not $array) {
                         Write-Host "Der kan ikke søges på nummerisk kriterie"
                         exit
                     }
                                                                                                                                    # Hvis emnet(nummeret) på linien er udvalgt
                     [string]$pth = $($array[$txt - 5]) | Select-Object -Property Path       -ExpandProperty Path
                     [string]$lnr = $($array[$txt - 5]) | Select-Object -Property LineNumber -ExpandProperty LineNumber                       
                     [string]$lin = $($array[$txt - 5]) | Select-Object -Property Line       -ExpandProperty Line                  
                                  
                     $xpx = $pth[0..69] -join ""                                                                                         # Fast længde string på 68 char, ingen ' '
                     if ($xpx -eq "$basePath\GREP_PWSprof.ps1")                                  
                     {      
                          $arrayLNR = @()                                                                                                # Vis det valgte fra nettet 
                          $arrayLNR = Get-ChildItem -Path "$basePath\GREP_PWSprof.ps1" | `                 
                          Select-String -pattern "https:" | Select-Object -Property LineNumber -ExpandProperty LineNumber  
                          $arrayLNR += 10000
                     
                          $arrayURL = @()                                                                                                 # LN er nummeret på PROF Linket
                          $arrayURL = Get-ChildItem -Path "$basePath\GREP_PWSprof.ps1" | `                 
                          Select-String -pattern "https:" | Select-Object -Property Line -ExpandProperty Line         
                                                                                                                                     
                          $c = 0
                          $count = $arrayLNR.count
                          while ($c -le $arrayLNR.Count)
                          {                                                               
                               If ($lnr -In $arrayLNR[$c]..$arrayLNR[$c+1] -eq $True)                                                      # Hvis nummeret er i mellemrummet så  
                               {                                                                                                           # så er ovrskriftern URL'en fundet
                                   Start-Process $arrayURL[$c]
                                   break                                         
                               }                                 
                               else
                               {
                                   $c++
                               }
                          }  
                     }   
                     elseIf ($xpx -eq "$basePath\GREP_LookUpCmdLets.ps1") 
                     {
                       # Get the cmdlet                                        
                         $string = $lin                                          
                         $cmdletName = $string -replace "'", '' -replace ',', ''    
                                             
                         # Call the "cmdlookup" script and pass the cmdlet name                                             
                         powershell.exe -File "$basePath\GREP_LookUpCmdLets.ps1" $cmdletName
                     }    
                     elseif ($xpx -eq "$basePath\GREP_LookUpFunc.ps1") 
                     {
                         # Get the function                                        
                         $string  = $lin                         
                         $functionName = $string -replace "'", '' -replace ',', ''                                  
                         
                         # Call the "LookUpFunc" script and pass the function name                                             
                         powershell.exe -File "$basePath\GREP_LookUpFunc.ps1" $functionName
                     }             
                     elseif ($xpx -eq "$basePath\GREP_LookUpSnips.ps1") 
                     {
                         # Get the snippet                                        
                         $string  = $lin                         
                         $scriptName = $string -replace "'", '' -replace ',', ''                                  
                  
                         # Call the "LookUpSnips" script and pass the function name                                             
                         powershell.exe -File "$basePath\GREP_LookUpSnips.ps1" $scriptName
                     }        
                     else
                     {   
                         # Check if the path is valid
                         if (Test-Path $pth) {
                             psedit $pth.substring(0,$pth.length)
                         } else {
                             Write Host "The path '$pth' is not valid. Please check the path and try again."
                         }                            
                     }                                         
                }                                                                  
                else                                                                    
                {                                                           # Search engine >>> first time around                     
                     $array = @()
                     try {
                          $array = Get-ChildItem -Path "$basePath" -Filter "*.ps1" -Recurse | `
                          Select-String -SimpleMatch -CaseSensitive:$false -Pattern $txt -ErrorAction SilentlyContinue | `
                          Select-Object -Property Path, LineNumber, Line
                     } catch {
                         # Do nothing to suppress the error
                     }

                     $array                   
}





