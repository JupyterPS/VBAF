# Define paths for Win10 and Win11
$pathWin11 = "C:\Users\henni\OneDrive\WindowsPowerShell"
$pathWin10 = "C:\Users\Henning\OneDrive\WindowsPowerShell"

# Determine the base path dynamically
if (Test-Path $pathWin11) {
    $basePath = $pathWin11
} else {
    $basePath = $pathWin10
}

# Script header
Write-Host("`n")
Write-Host("             - oo00oo -                       ")
Write-Host "=> _____ CompanyHeadQuarters ______________ <=n"

# Add-Type and SendKeys initialization
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.SendKeys]::SendWait('^{r}')

# Load the CompanyCustomerSupport module if necessary
if (-not (Get-Module -Name CompanyCustomerSupport -ErrorAction SilentlyContinue)) {
    Import-Module "${basePath}\CompanyCustomerSupport.ps1"
}

# Load other dependencies dynamically using $basePath
. "${basePath}\CompanyPSSQLopen.ps1"
. "${basePath}\CompanyBase.ps1"
. "${basePath}\Company1.ps1"
. "${basePath}\Company2.ps1"
. "${basePath}\Company3.ps1"
. "${basePath}\Company4.ps1"
. "${basePath}\CompanyEvent.ps1"
. "${basePath}\CompanyEmail.ps1"
. "${basePath}\CompanyFileSysMon.ps1"
. "${basePath}\CompanyOperations.ps1"

# Load the configuration data
$config = Import-PowerShellDataFile -Path "${basePath}\CompanyConfig.psd1"

# Example of fetching data from the database instead of The Config
$companyData = Invoke-SqliteQuery -Connection $db -Query "SELECT * FROM Companies WHERE Name = 'Novo Nordisk'"
$novoNordisk = [Company1]::new($companyData.Name, $companyData.Address, $companyData.ContactNumber)

# Extract the specific company configuration
$companyConfig = $config.Company1
$novoNordisk = [Company1]::new($companyConfig.Name, $companyConfig.Address, $companyConfig.ContactNumber) 

$companyConfig = $config.Company2
$wineCompany = [Company2]::new($companyConfig.Name, $companyConfig.Address, $companyConfig.ContactNumber)

$companyConfig = $config.Company3
$commerceBank = [Company3]::new($companyConfig.Name, $companyConfig.Address, $companyConfig.ContactNumber, $companyConfig.CEO)

$companyConfig = $config.Company4
# Instantiate Company4 with 7 arguments (Name, Address, Contact, + 4 Strategies)
$machineLearning = [Company4]::new($companyConfig.Name, $companyConfig.Address, $companyConfig.ContactNumber,` 
                                   $researchStrategy, $developmentStrategy, $collaborationStrategy, $evaluationStrategy)
# Demonstrate usage
Write-Host("`n")
$novoNordisk.AddEmployee("Poul Clark", "Developer")
$novoNordisk.ListEmployees()

# Add employees  
Write-Host "n"
$wineCompany.AddEmployee("John Smith", "Winemaker")
$wineCompany.AddCustomer("Liam Brown", "liam@example.com")

Write-Host("`n")
$commerceBank.AddEmployee("Bob", "Accountant")
$commerceBank.AddCustomer("Jane Doe", "jane.doe@example.com")

Write-Host("`n")
# Run operations for all companies
$companies = @($novoNordisk, $wineCompany, $commerceBank, $machineLearning)
foreach ($company in $companies) {
    Write-Host("`n")
    Run-CompanyOperations -company $company
} 

Write-Host("`n")
# Invoke specific operations
$novoNordisk.SpecificOperation()
$wineCompany.SpecificOperation()
$commerceBank.SpecificOperation()
$machineLearning.SpecificOperation()

. "${basePath}\CompanyPSSQLclose.ps1"
. "${basePath}\CompanyPresent.ps1"
. "${basePath}\CompanyShow.ps1"
 