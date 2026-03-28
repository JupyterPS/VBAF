                 [System.Windows.Forms.SendKeys]::SendWait("^{2}")
                 ##Define tabs and their content
                 $Tabs = [ordered]@{
                      "Tab One" = @(
                          "$basePath\OO1_Class.ps1"
                          "$basePath\OO2_Properties.ps1"
                          "$basePath\OO3_Method.ps1"
                          "$basePath\OO4_Enum.ps1"
                      )
                      "Tab Two" = @(
                          "$basePath\OO5_ClassConstructor.ps1"                          
                          "$basePath\OO6_ClassInheritance.ps1"
                          "$basePath\OO7_Call_Get+Set+.ps1"                              
                      )
                      "Tab Three" = @(                          
                          "$basePath\OO8_Polymorphism.ps1"                          
                          "$basePath\OO9_OOP_Definitions.ps1"                                               
                     )
                 }

                 foreach($tabDef in $Tabs.GetEnumerator()){ 

                     #Loop through the tab definitions until we reach one that hasn"t been configured yet
                      if(-not $psISE.PowerShellTabs.Where({$_.DisplayName -eq $tabDef.Name})){

                           #Set the name of the tab that was just created
                           $psISE.CurrentPowerShellTab.DisplayName = $tabDef.Name

                           #Open the corresponding files
                           foreach($file in Get-Item -Path $tabDef.Value){
                               $psISE.CurrentPowerShellTab.Files.Add($file.FullName)
                           }

                           if($psISE.PowerShellTabs.Count -lt $Tabs.Count){
                               #Still tabs to be opened
                               $newTab = $psISE.PowerShellTabs.Add()
                           }
                           cls

                           #Nothing more to be done - if we just opened a new tab it will take care of itself
                           #return
                      }
                 }









