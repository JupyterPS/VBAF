                                ################ Arbejder i registrede data ########################
                 $YearFrom = 2019                                                                                      #Fjernvarme opstart
                 Clear-Content "$basePath\FJ_FjernvarmeUdtr�k.txt"    #Gammelt udtr�k
                 $path = "$basePath\FJ_FjernvarmeUdtr�k.txt"

                 $YearTo = get-date -Format yyyy
                 $YearCount = $YearTo - $YearFrom + 1
                 $z = ($YearCount - 1) * 12

                 $y=0
                 while ($y -lt $YearCount)
                 {
                      $array = @()
                      $array = 0..$z | % { (New-Object DateTime(($YearFrom)),12,31).AddMonths($_).ToString("dd-MM-yyyy") }
                      $y ++
                 }

                 $x=0
                 while ($x -lt $array.Count)
                 {
                      $match = $array[$x]

                      foreach($line in Get-Content -Path "$basePath\FO_FjernvarmeForbrug�ret.txt")
                      {
                           if ($line.Substring(7,10) -match $match)
                           {
                                Out-File -InputObject $Line -Append -NoClobber -Encoding Default -FilePath $Path -WhatIf:$False
                           }
                      }
                 $x++
                 }
                 (Get-Content "$basePath\FJ_FjernvarmeUdtr�k.txt")
                 Clear-Content "$basePath\FJ_FjernvarmeUdtr�k.txt"    #Gammelt udtr�k








