# CompanyEmail.ps1

Write-Host "=> _____ CompanyEmail _____________________ <=`n"

# Simple email sending function
function Send-Email {
    param (
        [string]$to,
        [string]$subject,
        [string]$body
    )
    Write-Host "Sending email to $to with subject '$subject' and body '$body'"
}






