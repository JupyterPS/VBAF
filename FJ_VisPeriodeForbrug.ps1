CLS
# Define the Validate-Date function
function Validate-Date {
    param (
        [string]$dateString
    )
    try {
        $date = Get-Date $dateString -ErrorAction Stop
        return $true  # Date is valid
    } catch {
        return $false  # Date is invalid
    }
}

# Define the Validate-And-ParseDate function
function Validate-And-ParseDate {
    param ( 
        [string]$dateString,
        [string]$dateFormat = 'dd-MM-yyyy'
    )
    try {
        return [datetime]::ParseExact($dateString, $dateFormat, $null)
    } catch {
        throw "Invalid date format: $dateString. Expected format is $dateFormat."
    }
}

# Your existing script logic
$path1 = "$basePath\FJ_FjernvarmeUdtræk.txt"  # Udtræk

# Function to highlight consumption in kr/øre
function Write-Color {
    param (
        [String[]]$Text,
        [ConsoleColor[]]$Color
    )
    for ($i = 0; $i -lt $Text.Length; $i++) {
        Write-Host $Text[$i] -ForegroundColor $Color[$i] -NoNewLine
    }
}

$measure = Get-Content $path1 | Measure-Object
$lines = $measure.Count

if ($measure.Count -gt 0) {
    $lastDataRow = (Get-Content "$basePath\FJ_FjernvarmeUdtræk.txt")[0]
} else {
    $lastDataRow = (Get-Content "$basePath\FO_FjernvarmeForbrugåret.txt")[0]
}

$FraDato = $lastDataRow.Substring(7,10)
$GLKwH = $lastDataRow.Substring(25,7)
$GLm3 = $lastDataRow.Substring(40,7)
$GlT8 = $lastDataRow.Substring(126,10)
$GlT9 = $lastDataRow.Substring(148,10)

if ($measure.Count -gt 0) {
    $lastDataRow = (Get-Content "$basePath\FJ_FjernvarmeUdtræk.txt")[-1]
} else {
    $lastDataRow = (Get-Content "$basePath\FO_FjernvarmeForbrugåret.txt")[-1]
}

$TilDato = $lastDataRow.Substring(7,10)
$NyKwH = $lastDataRow.Substring(25,7)
$Nym3 = $lastDataRow.Substring(40,7)
$NyT8 = $lastDataRow.Substring(126,10)
$NyT9 = $lastDataRow.Substring(148,10)

$Forb_KwH = $NyKwH - $GLKwH
$Forb_m3 = $Nym3 - $GLm3
$Cooling = ($Forb_KwH / $Forb_m3) * 860
$Forb_T8 = $NyT8 - $GlT8
$Forb_T9 = $NyT9 - $GlT9
$TfGrad = $Forb_T8 / $Forb_m3
$TrGrad = $Forb_T9 / $Forb_m3

switch ($lastDataRow.Substring(16,1)) {
    0 { $FJV_pris = 451.56 }
    1 { $FJV_pris = 451.56 }
    2 { $FJV_pris = 477.50 }
    3 { $FJV_pris = 503.75 }
    4 { $FJV_pris = 626.25 }
    5 { $FJV_pris = 693.75 }
    6 { $FJV_pris = 704.09 }
    default { Write-Host("Tid til at få ny årspris") }
}
$Periode_pris = ($Forb_KwH * $FJV_pris)

[int]$Mdnr = ($lastDataRow.Substring(10,2))
switch ($Mdnr) {   
  01 {$Mdr = "Januar"}
  02 {$Mdr = "Februar"}
  03 {$Mdr = "Marts"}
  04 {$Mdr = "April"}
  05 {$Mdr = "Maj"}
  06 {$Mdr = "Juni"}
  07 {$Mdr = "Juli"}
  08 {$Mdr = "August"}
  09 {$Mdr = "September"} 
  10 {$Mdr = "Oktober"}
  11 {$Mdr = "November"}
  12 {$Mdr = "December"}
}

# Find difference in daily consumption
# Den sidste dag i den indberettede periode, danner grundlag for i dag kr/kwh (selvom det er en måned siden)
if ($measure.Count -eq 0) {
    $NUlastDataRow = (Get-Content "$basePath\FO_FjernvarmeForbrugåret.txt")[-2] 
    $NUFraDato = $NUlastDataRow.Substring(7,10)
    $ToDate = Validate-And-ParseDate -dateString $TilDato
    $FromDate = Validate-And-ParseDate -dateString $NUFraDato
    $DaysDifference = ($ToDate - $FromDate).Days
    
    $Dag_KwH = $lastDataRow.Substring(90,5)
    $Dag_m3 = $lastDataRow.Substring(108,4)
    $Dag_pris = ([decimal]$Dag_KwH * $FJV_pris) / $DaysDifference
    $En_Dag = $Dag_KwH / $DaysDifference
    $Dag_Cool = $Dag_KwH / $Dag_m3 * 860
    $Cool = ('{0:N3}' -f $Dag_Cool)
} else {                                                                     
    $NUFraDato = $FraDato
    $ToDate = Validate-And-ParseDate -dateString $TilDato
    $FromDate = Validate-And-ParseDate -dateString $NUFraDato
    $DaysDifference = ($ToDate - $FromDate).Days
    
    $Dag_KwH = $Forb_KwH                                                                      
    $Dag_pris = ([decimal]$Dag_KwH * $FJV_pris) / $DaysDifference
    $En_Dag = $Dag_KwH / $DaysDifference
    $Dag_Cool = $Dag_KwH / $Dag_m3 * 860
    $Cool = ('{0:N3}' -f $Dag_Cool)
} 

try {
    $Date1 = Validate-And-ParseDate -dateString $FraDato
    $Date2 = Validate-And-ParseDate -dateString "01-10-2020"

    if ($Date1 -lt $Date2) {
        $FraDato = "01-10-2020"
        $Date1 = Validate-And-ParseDate -dateString $FraDato
    }

    # Continue with your script logic...

} catch {
    Write-Error $_.Exception.Message
}


#######################################################################   P r æ s e n t a t i o n   ##############################################################     
  
Write-Host 
if ($measure.Count -eq 0) {
   Write-Color -Text "Forbrug i perioden: ", $FraDato, " til ", $TilDato,"                                                            ", ('{0:N2}' -f $Forb_KwH), " KwH @ kr. ",  $FJV_pris,  " ===> kr. " ,('{0:N2}' -f $Periode_pris),"  ===>  gennemsnit $Mdr måned:  kr. ", ('{0:N2}' -f $Dag_pris),  "   KwH ", ('{0:N3}' -f $En_Dag) -Color White,White,White,White,White,White,White,White,White,White,Yellow,Yellow,Yellow,Cyan #$y
   Write-Color -Text "                                                                                                                                                                                                                                                                                                                 =======================       " ,  "                         Cooling ",   $Cool -Color White,Yellow,Yellow
} else {   
    Write-Color -Text "Forbrug i perioden: ", $FraDato, " til ", $TilDato,"                                                            ", ('{0:N2}' -f $Forb_KwH), " KwH @ kr. ",  $FJV_pris,  " ===> kr. " ,('{0:N2}' -f $Periode_pris),"  ===>  gennemsnit for perioden:  kr. ", ('{0:N2}' -f $Dag_pris),  "   KwH ", ('{0:N3}' -f $En_Dag)   -Color White,White,White,White,White,White,White,White,White,White,Yellow,Yellow,Yellow,Cyan #$y 
    Write-Color -Text "                                                                                                                                                                                                                                                                                                                 =====================       "  -Color White
}
#Write-Color -Text "                                                                                                                                                                                                                                                                                                                           ====="," ?? ","=====   " ,  "   Cooling ",   $Cool -Color White,Yellow,White,Yellow,Yellow
Write-Host ""
if ($Forb_KwH -gt 999.99)
            {Write-Host "KwH:                 "         ('{0:N2}' -f $Forb_KwH)   "                                                *       " "                                                                                               1"}
elseif ($Forb_KwH -gt 99.99)
            {Write-Host "KwH:             "          ('{0:N2}' -f $Forb_KwH)   "                                                *       " "                                                                                                 2"}
elseif ($Forb_KwH -gt 9.99)
            {Write-Host "KwH:              "          ('{0:N2}' -f $Forb_KwH)   "                                                *       " "                                                                                                 3"}
elseif ($Forb_KwH -gt 0.00)
            {Write-Host "KwH:               "            ('{0:N2}' -f $Forb_KwH)   "                                                *       " "                                                                                                 4"}

if ($Forb_m3 -gt 999.99)
            {Write-Host "m3:            "  ('{0:N2}' -f $Forb_m3) "                                               / \" "                                                                                                       1"}
elseif ($Forb_m3 -gt 99.99)
            {Write-Host "m3:              "  ('{0:N2}' -f $Forb_m3) "                                               / \" "                                                                                                       2"}
elseif ($Forb_m3 -gt 9.99)
            {Write-Host "m3:               "  ('{0:N2}' -f $Forb_m3) "                                               / \" "                                                                                                       3"}
elseif ($Forb_m3 -gt 0.00)
            {Write-Host "m3:                "  ('{0:N2}' -f $Forb_m3) "                                               / \" "                                                                                                 4"}

if ($Forb_T8 -gt 99999.99)
            {Write-Host "m3xTf:       " ('{0:N2}' -f $Forb_T8) "            Gns. temp ==>:" ('{0:N2}' -f $TfGrad) "              _ _      " "                                                                                                 1"}
elseif ($Forb_T8 -gt 9999.99)
            {Write-Host "m3xTf:        "  ('{0:N2}' -f $Forb_T8) "            Gns. temp ==>:" ('{0:N2}' -f $TfGrad) "              _ _      " "                                                                                                 2"}
elseif ($Forb_T8 -gt 999.99)
            {Write-Host "m3xTf:         "  ('{0:N2}' -f $Forb_T8) "            Gns. temp ==>:" ('{0:N2}' -f $TfGrad) "              _ _      " "                                                                                                 3"}
elseif ($Forb_T8 -gt 0.99)
            {Write-Host "m3xTf:           "  ('{0:N2}' -f $Forb_T8) "            Gns. temp ==>:" ('{0:N2}' -f $TfGrad) "              _ _      " "                                                                                                 4"}

if ($Forb_T9 -gt 99999.99)
            {Write-Host "m3xTr:       " ('{0:N2}' -f $Forb_T9) "            Gns. temp <==:" ('{0:N2}' -f $TrGrad) "            C o o ling:"  ('{0:N3}' -f $Cooling) "                                                                                          1"}
elseif ($Forb_T9 -gt 9999.99)
            {Write-Host "m3xTr:        "  ('{0:N2}' -f $Forb_T9) "            Gns. temp <==:" ('{0:N2}' -f $TrGrad) "            C o o ling:"  ('{0:N3}' -f $Cooling) "                                                                                          2"}
elseif ($Forb_T9 -gt 999.99)
            {Write-Host "m3xTr:         "  ('{0:N2}' -f $Forb_T9) "            Gns. temp <==:" ('{0:N2}' -f $TrGrad) "            C o o ling:"  ('{0:N3}' -f $Cooling) "                                                                                          3"}
elseif ($Forb_T9 -gt 0.99)
            {Write-Host "m3xTr:           "  ('{0:N2}' -f $Forb_T9) "            Gns. temp <==:" ('{0:N2}' -f $TrGrad) "            C o o ling:"  ('{0:N3}' -f $Cooling) "                                                                                          4"}


Write-Host "                                                                         ,"; Write-Color -Text "Forbrug i perioden: ", $FraDato, " til ", $TilDato,"                                                            ", ('{0:N2}' -f $Forb_KwH), " MwH @ kr. ",  $FJV_pris,  " ===> kr. " ,('{0:N2}' -f $Periode_pris) -Color Yellow,Green,Red,Cyan,Magenta,Magenta,Yellow,Green,White,Cyan
#Write-Host "                                                                         ,";Start-Sleep -Seconds 3; Write-Color -Text "Forbrug i perioden: ", $FraDato, " til ", $TilDato,"                                                            ", ('{0:N2}' -f $Forb_KwH), " MwH @ kr. ",  $FJV_pris,  " ===> kr. " ,('{0:N2}' -f $Periode_pris) -Color Yellow,Green,Red,Cyan,Magenta,Magenta,Yellow,Green,White,Cyan

Clear-Content "$basePath\FJ_FjernvarmeUdtræk.txt"









