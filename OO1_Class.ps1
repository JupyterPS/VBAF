                                                                                                                                                        <#
                                                     - oo00oo -  
                                               
                                                    C l a s s e s        
                                               
                                                M A C H I N E  R O O M  
                                                
                                                (Qualified staff only) 
                                                                                                                                                               #>


# 1. Classes


####################### TABLE OF CONTENT ################################ 
* Classes
* class CyberNinja  
#########################################################################

We can think of Classes as models or blueprints. To use a Class, we create a special Type of variable known as an Object;
an Object is an instance of a Class.

Think of a class as a way to create a specification of variables, functions, and other properties (e.g. a template). 
Now to use this model, we must create an instance of the specification (object). 
Similarly this is the same idea where a contractor can use a blueprint to build multiple houses. 
Once created, an object has access to properties and methods defined by its class. 

#########################################################################

cls
class car 
{  
        [string]   $Color = "Silver"                                                # Lidt "gammeldags" måde at initiere properties på
        [string]   $Name  = "Mercedes"                                             
        [decimal]  $Lenghth = 4.6	                                               
        [decimal]  $Width   = 2.3                                                  
        [decimal]  $Height  = 1.6                                                  
        [string]   $Manufacturer = "Daimler/Benz"                                  
        [string]   $Model   = "W124 - 260"                                         
        [int]      $Milage  = 10                                                   
                                                                                   
        [void] Drive([int] $Milage)                                                 # Method uden at returnere noget
        {                                                                           
               $this.Milage += $Milage                                             
        }                                                                          
}                                                                                  
########################################################################   
          
#En Class skal bruges til at oprette et object - her de 2 måder                     # Called Instatiation  
$Mycar = [car]::new(); $Mycar                                                             
$Mycar = New-Object -TypeName Car; $Mycar                                                  
                                                                                   
$Mycar.Drive(50)                                                                    
$Mycar.Milage                                                                       # Kald method
                                                                                  
$members = Get-Member -InputObject $Mycar; $members                                 # Vis alle elementer 
$members = Get-Member -MemberType  Property -InputObject $Mycar; $members            
$members = Get-Member -MemberType  Method   -InputObject $Mycar; $members      

#########################################################################


#_________ class CyberNinja _________________

#Base Class
class CyberNinja
{
                 #Properties
                 [String] $Alias
                 [int32] $HitPoints

                 #Static Properties
                 static [String] $Clan = "DevOps Library"

                 #Hidden Properties
                 hidden [String] $RealName

                 #Parameterless Constructor
                 CyberNinja ()
                 {
                 }

                 #Constructor
                 CyberNinja ([String] $Alias, [int32] $HitPoints, [String] $RealName)
                 {
                      Write-Host("Instantiating a CyberNinja object")
                      $this.Alias = $Alias
                      $this.HitPoints = $HitPoints
                      $this.RealName = $RealName
                 }

                 #Member Methods
                 Display()
                 {
                      Write-Host("`n")
                      Write-Host("Alias: " + $this.Alias)
                      Write-Host("HitPoints: "+ $this.HitPoints)
                      Write-Host("RealName: "+ $this.RealName)
                 }

                 #Method
                 [String] getAlias()
                 {
                      return $this.Alias
                 }

                 #Static Method
                 static [String] getClan()
                 {
                      return [CyberNinja]::Clan
                 }

                 #ToString Method
                 [String] ToString()
                 {
                      return $this.Alias + ":" + $this.HitPoints
                 }
}

#inherits
class LittleNinja : CyberNinja
{
                 LittleNinja()
                 {
                      Write-Host("Instantiating a LittleNinja object")
                 }
}

Function validate_Ninja
{

                 [AllowNull()]
                 [AllowEmptyCollection()]
                 [AllowEmptyString()]
                 [ValidateCount(1,3)][string[]]$ComputerName
                 [ValidateLength(1,200)][string]$Text
                 [ValidateRange(-10,10)][int]$Speed = 0
                 [ValidateNotNullOrEmpty()][string]$Path = 'c:\somefolder'
                 [ValidateDrive('c','d','env')][string]$Path = 'c:\windows'
                 [ValidateLength(8,12)][string]$computername ='Server2018'
                 [ValidatePattern('^Server\d{2,4}$')][string]$ComputerName = 'Server12'
                 [ValidateSet('NewYork','London','Berlin')][string]$City = 'Berlin'

                 # In total, there are several validation attributes available in PowerShell 
                 and the exact number can vary based on the version of PowerShell you are using

}

Function create_Ninjas
{
                 #When considering code design, it is common to declare the object type explicitly.
                 #Using Static "new" method
                 $Ken = [CyberNinja]::new("Ken", 28, "JOE")
                 $Ken.Display()
                 $Ken.ToString()
                 $Ken.getAlias()
                 $Ken.RealName
                 $Ken::getClan()

                 #Using New-Object. Parameters for Argument list are positional and required by the constructor.
                 $Hodge = New-Object CyberNinja -ArgumentList "Hodge", 31, " "
                 $Hodge.Display()

                 #Using a HashTable. Note: requires default or parameterless constructor.
                 $June = [CyberNinja]@{
                      Alias = "June"
                      HitPoints = 40
                      RealName = " "
                 }
                 $June.Display()

                 #Dynamic Object Type using a variable name.
                 $Type = "CyberNinja"
                 $Steven = New-Object -TypeName $Type -ArgumentList "Steve", 44, "Major"
                 $Steven.Display()
                 $Steven.RealName

                 $myNinja = [LittleNinja]::new()
                 $myNinja.Display()

                 #Call a Static Method
                 $Ken::getClan()
                 [CyberNinja]::getClan()

                 #Fetch Static Prop Value
                 $Ken::Clan
                 [CyberNinja]::Clan

                 #Set Static Prop Value
                 $Ken::Clan = "DevOps Library"
                 [CyberNinja]::Clan = "DevOps Library"

                 #Call an Instance Method
                 $Ken.getAlias()

                 #Fetch Instance Prop Value
                 $Ken.HitPoints

                 #Set Instance Prop Value
                 $Ken.Alias = "Mekuto"
}
#--------- Invocations --------
 create_Ninjas

#########################################################################

Creating instances of a class

To use a class, we must instantiate an object unless using static properties or methods.
Most commonly, this is done using the new() static method or the New-Object Command. 
In some cases, such as creating classes dynamically by type, the New-Object command is necessary.

#########################################################################


# Using Static "new" method.
$Ken = [CyberNinja]::new("Ken", 28, "Joe")

# Using New-Object. Parameters for Argument list are positional and required by the constructor.
$Hodge = New-Object CyberNinja -ArgumentList "Hodge", 31, "Joe"

# Using a HashTable. Note: requires default or parameterless constructor.
$June = [CyberNinja]@{
    Alias = "June";
    HitPoints = 40;
}

# Dynamic Object Type using a variable name.
$Type = "CyberNinja"
$Steven = New-Object -TypeName $Type; $Steven

# When considering code design, it is common to declare the object type explicitly.	 




 

 












                          






