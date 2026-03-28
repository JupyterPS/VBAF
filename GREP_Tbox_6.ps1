                                                                                                                                                         <#
                                                      - oo00oo -  
                                                 
                                                   H a s h  T a b l e s        
                                                 
                                                  M A C H I N E  R O O M  
                                                  
                                                  (Qualified staff only) 
                                                                                                                                                      #>


# 6. Hash Tables


  # Stores key-value pairs.
  # Used for associating one piece of data with another.

       # Example:
       $person = @{
           "Name" = "John"
           "Age" = 30
       }
       Write-Host $person["Name"]                                                                     # Output: John


<###################################### >>> Additional referrals <<< ###############################

Start-Process "https:/books.goalkicker.com/PowerShellBook/PowerShellNotesForProfessionals.pdf"        Chapter10: HashTables
Start-Process "https:/powershellbyexample.dev/"                                                       Hashtables   
Start-Process "https:/www.codecademy.com/resources/docs/powershell/objects"          
  
###################################################################################################>  

#[hashtable]$BillingHash = [ordered]@{TableNumber=0;WineNumber=0;AccuTotalPoured=0}                   # Not in use                 
                                                                              
  
$BillingHash.Add($Key,$MyBilling.AccuTotalPoured)                                                     # First time
$BillingHash.Set_Item($Key,$MyBilling.AccuTotalPoured)                                                # Change                                      
                                                                                                     
                                                                                                     
$BillingHash.Add("0-0",$MyBilling.AccuTotalPoured)                                                    # First time
$BillingHash.Add("0-1",$MyBilling.AccuTotalPoured)                                                   
$BillingHash.Add("0-2",$MyBilling.AccuTotalPoured)                                                   
                                                                                                     
$BillingHash.Set_Item("0-0",$MyBilling.AccuTotalPoured)                                               # Change
$BillingHash.Set_Item("0-1",$MyBilling.AccuTotalPoured)
$BillingHash.Set_Item("0-2",$MyBilling.AccuTotalPoured)  
 
foreach ($key in $BillingHash.Keys) {
    $MyBilling.AccuTotalPoured += ($BillingHash[$key]);
}

$BillingHash.Remove("0-0")
$BillingHash.Remove("0-1")
$BillingHash.Remove("0-2") 

$BillingHash = @{} 
$BillingHash.
$BillingHash.keys  
$BillingHash.Values 
$BillingHash.count 
$BillingHash.Item("0-1")     
#if ($BillingHash.Item("0-0")+$BillingHash.Item("0-1")+$BillingHash.Item("0-2") -gt 20)                            
$BillingHash.Values.Sum() #!!!!! oh no findes ikke

#If PrimalSyrah then...else if Values[1] osv.                                                         # Skal laves
$MyBilling.AccuTotalPoured += $BillingHash.Values[0]                                                  # 2
$MyBilling.AccuTotalPoured += $BillingHash.Values[1]
$MyBilling.AccuTotalPoured += $BillingHash.Values[2]

$BillingHash.Keys | ForEach-Object {
    "The value of '$_' is: $($BillingHash[$_])"
} | Sort-Object  

###################################################################################################
 
$HashValue= @{ ID = 13; Name = "Purnima"; Color = "fair"}
 
$HashValue.keys 
$HashValue.values
$HashValue.Add("Created","Now") 
$HashValue["ID"] 
$HashValue.Count 
$HashValue.Number
$HashValue.Remove("Item")
$HashValue["Updated"] = "Now" 
$HashValue.GetEnumerator() | Sort-Object -Property key

$hash = $null
$hash = @{}

$proc = get-process | Sort-Object -Property name -Unique
foreach ($p in $proc)
{
 $hash.add($p.ProcessName,$p.Id)
}

$x = @()
$x += [pscustomobject]@{Name="cname";  Display="Friendly Name"}
$x += [pscustomobject]@{Name="cname2"; Display="Friendly Name2"}
$x += [pscustomobject]@{Name="cname3"; Display="Friendly Name3"}

#_______________________________

# Define a hashtable with Active Directory cmdlets
$moduleFunctionPairs = @{
    'activedirectory' = @(
        'Get-ADUser',
        'Get-ADGroup',
        'Get-ADComputer',
        'Get-ADOrganizationalUnit',
        'Get-ADDomain',
        'Get-ADForest'
    ) 
}

# Initialize an empty hashtable for available cmdlets
$availableCmdlets = @{}

# Iterate over the module and its functions
foreach ($module in $moduleFunctionPairs.Keys) {
    $functions = $moduleFunctionPairs[$module]
    foreach ($function in $functions) {
        # Check if the cmdlet exists
        if (Get-Command $function -ErrorAction SilentlyContinue) {
            # Add the available cmdlet to the hashtable
            $availableCmdlets[$function] = $module
        }
    }
}

# Output the available cmdlets
Write-Host "Available cmdlets:"
$availableCmdlets.Keys

# Call the Menu again
invoke-expression -Command "$basePath\HO_ToolBox_Menu.ps1"