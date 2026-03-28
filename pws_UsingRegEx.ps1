# Define the path to your input text file and output text file
$inputFile = "$basePath\A_X.txt"
$outputFile = "$basePath\A_X.txt"

# Read the input file line by line, update the field, and write to the output file
(Get-Content $inputFile) | ForEach-Object {
    # Use regular expressions to find and modify the "Forb_m3" field
    $_ -replace "kwh:= "  , " m3:= " 
} | Set-Content -Force $outputFile

Write-Host "Field updated and saved to $outputFile"
 
<#__________________________________________________________________________________________________
#    $_ represents the current line being processed.

    -replace is a PowerShell operator used for string replacement.

#    'Forb_m3:= "(\d+\.\d+)"' is the regular expression pattern we're searching for within each line. Let's break it down:
        Forb_m3:= " matches the literal string "Forb_m3:= " in the line.
        (\d+\.\d+) is a capturing group that matches one or more digits (\d+) followed by a decimal point (\.),
        and then one or more digits again.`
        This part captures the numeric value in the "Forb_m3" field.

    'Forb_m3:= "0$1"' is the replacement string:
        Forb_m3:= " is the literal string "Forb_m3:= " that we want to keep in the output.
#        0 is the additional zero we want to add.
#        $1 is a backreference to the value captured by the capturing group (\d+\.\d+).
    This ensures that we keep the original numeric value intact in the output.

So the regular expression essentially looks for lines containing "Forb_m3:= " followed by a numeric value, captures that numeric value,`
and replaces it with "Forb_m3:= " followed by the numeric value with an additional leading zero. 
#>

#>  







