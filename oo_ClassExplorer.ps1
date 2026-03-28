#1. use the static currentdomain property from the system.appdomain .NET Framework class
#- one is used by the Windows PowerShell console
#-  the other is Windows PowerShell ISE 
[appdomain]::CurrentDomain
[appdomain]::CurrentDomain | get-member 

#- use the getassemblies method
[appdomain]::currentdomain.GetAssemblies()

#2. RETURNS: System.Reflection.Assembly .NET Framework class.
[appdomain]::currentdomain.GetAssemblies() | Get-Member
_____________________________________________________________________________________    

[appdomain]::CurrentDomain
 
[appdomain]::currentdomain.GetAssemblies()
[appdomain]::currentdomain.GetAssemblies() | % {$_.gettypes()} | sort basetype 
Install-Module ClassExplorer
Get-Assembly
#_____________________________________________________________________________________

Find-Type RunspaceConnectionInfo    
 
Find-Type -InheritsType System.Management.Automation.Runspaces.RunspaceConnectionInfo  

Find-Type -InheritsType System.Management.Automation.Runspaces.RunspaceConnectionInfo |  Find-Type { $_ | Find-Member -MemberType Constructor }
[Management.Automation.Runspaces.NamedPipeConnectionInfo] |    Find-Member -MemberType Constructor |    Get-Parameter

# Or, alternatively this will return all constructors, properties, methods, etc that return any
# implementation of RunspaceConnectionInfo.
Find-Member -ReturnType System.Management.Automation.Runspaces.RunspaceConnectionInfo


# using namespace System.Management.Automation.Runspaces  

Find-Member -ReturnType { [ReadOnlySpan[byte]] } -ParameterType { [ReadOnlySpan[any]] }

Find-Member -MemberType Method -Instance -ParameterType string -ReturnType bool -ParameterCount 4.. |
Find-Member -ParameterType { [anyref] [any] } | Find-Member -Not -RegularExpression 'Should(Continue|Process)'

#_____________________________________________________________________________________

# Get the current application domain
$currentDomain = [AppDomain]::CurrentDomain

# Get all loaded assemblies
$assemblies = $currentDomain.GetAssemblies()

# List all types in the loaded assemblies
$types = $assemblies | ForEach-Object { $_.GetTypes() }

# Display the types
$types | Sort-Object FullName | Format-Table FullName

# Find a specific type and its members
$runspaceTypes = Find-Type -InheritsType System.Management.Automation.Runspaces.RunspaceConnectionInfo
$runspaceTypes | ForEach-Object { $_ | Find-Member }







