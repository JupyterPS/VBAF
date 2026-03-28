                                                                                                                                                        <#
                                                     - oo00oo -  
                                               
                                                     Properties        
                                               
                                                M A C H I N E  R O O M  
                                                
                                                (Qualified staff only) 
                                                                                                                                                               #>


# 2. Properties


####################### TABLE OF CONTENT ################################ 
* Properties              
######################################################################### 

cls
class Person 
{
                [string]$FirstName
                [string]$LastName

                Person() {}

                #Member Method
                Display()
                {                      
                    Write-Host("`n")
                    Write-Host("P E R S O N")    
                    Write-Host("FirstName: " + $this.FirstName)  
                    Write-Host("LastName: "  + $this.LastName)      
                }
     
                [string]GetName()                                         # Method 1
                {
                    return "$($this.FirstName) $($this.LastName)"         
                }
                
                [void]SetName([string]$Name)                              # Method 2
                {                                                         
                    $this.FirstName = ($Name -split " ")[0]
                    $this.LastName  = ($Name -split " ")[1]
                }
                
                [void]SetName([string]$FirstName,[string]$LastName)       # Method 3
                {    
                    $this.FirstName = $FirstName
                    $this.LastName  = $LastName
                }
}


#########################################################################
# Constructors have to be declared especially in child classes (no enheritance)
# You can call "things" in Base (to avoid duplicates), see for BaseCalls
# Has to be declared in every child class (otherwise an error will occur)                                                                               
########################################################################   

class Teacher : Person                                             
{                                                                  
                [int]hidden $EmployeeId                            
                                                                               
                Teacher() {}                                           
        
                #Member Method
                Display()
                {                      
                    Write-Host("`n")
                    Write-Host("T E A C H E R")
                    Write-Host("FirstName: "  + $this.FirstName)                  
                    Write-Host("LastName: "   + $this.LastName)      
                    Write-Host("EmployeeId: " + $this.EmployeeId)   
                    Write-Host("`n")    
                }                                    
}       
                                                                
class Student : Person 
{
                [int]$StudentId
                [string[]]$Classes = @()
                [int]static $MaxClassCount = 8
                
                Student() {}               
                 
                #Member Method
                Display()
                {                      
                    Write-Host("`n")
                    Write-Host("S T U D E N T")    
                    Write-Host("FirstName: " + $this.FirstName)                  
                    Write-Host("LastName: "  + $this.LastName)  
                    Write-Host("StudentId: " + $this.StudentId)  
                    Write-Host("Classes: ")   
                    foreach ($class in $this.Classes) {
                    Write-Host("   " + $class)
                    }                                     
                    Write-Host("`n")
                } 

                [void]AddClass([string]$Name) 
                {
                   if ($this.Classes.Count -lt [Student]::MaxClassCount) 
                   {
                       $this.Classes += $Name
                       Write-Host $this.Classes.Count
                   }
                }
} 
############################ S T U D E N T ################################ ==> Person - Teacher - Student

$myPerson = [person]::New()  
$myPerson.FirstName = "Jack"
$myPerson.LastName = "Freeman"
$myPerson.Display()
                                      
$myTeacher = [teacher]::New()  
$myTeacher.FirstName = "Debbie"
$myTeacher.LastName = "Moore"
$myTeacher.EmployeeId = 12345
$myTeacher.Display() 

$myStudent = [student]::new()                                    
$myStudent.FirstName = "Tyler"
$myStudent.LastName = "Muir"
$myStudent.StudentId = 4711
$myStudent.AddClass([string]"Singing")
"PE","English","Math","History","Computer Science","French","Wood Working","Cooking" | ForEach-Object {	$myStudent.AddClass($_) } 
$myStudent.Display()
   
$myStudent.Classes[1,2,3,4,5,6,7,8]
$myStudent.Classes.count
$myStudent.SetName("Jacob Newman")
$myStudent.SetName("Peter","Jason")
$myStudent.GetName()  
 
#########################################################################


#__________ Properties ________________  

Properties

Properties are a special type of class member which define a field (data variable) as well as hidden methods to get and set the value.
A Property is composed of a data type, name, default value, access modifier, and non-access modifier.

    DataType  A data type can be a built-in type like [String], [Int32], [Bool].
        Additionally this could also be a custom data type such as another PowerShell class: [Ninja].
    Name: The name of the property.
        The name follows a set of allowed rules such as alphanumeric, underscores, dashes, and, numbers.
    Default Value (Optional): Specifies the default value of a Property when creating an object.
        I f a value is not declared, the property will not always be null.
        The default value of the properties data type determines the value.
    Access Modifier (Optional): [public, hidden]. The default modifier is public; however we do not use the public keyword.
    Non-access Modifier (Optional): The static keyword controls if a property is an instance or class/static type.


#########################################################################


class Ninja {
    # Public Properties
    [String] $Alias
    [Int32] $HitPoints

    # Static Properties
    static [String] $Clan = "Posh Shinobi"

    # Hidden Properties (without the hidden attribute)
    [String] $RealName

    # Constructor
    Ninja([String] $alias, [Int32] $hitPoints, [String] $realName) {
        $this.Alias = $alias
        $this.HitPoints = $hitPoints
        $this.RealName = $realName
    }
 
     # Method to display information
    [void] DisplayInfo() {
        Write-Host "Alias: $($this.Alias)"
        Write-Host "Hit Points: $($this.HitPoints)"
        Write-Host "Clan: $([Ninja]::Clan)"  # Corrected static property access
        Write-Host "Real Name: $($this.RealName)"
    }
}
     $June = [Ninja]::new("JUNE", 28, "Miss Sofie")       
     $June.DisplayInfo()    
     $June.RealName
  




