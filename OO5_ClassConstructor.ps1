                                                                                                                                                        <#
                                                     - oo00oo -  
                                               
                                                     Constructor       
                                               
                                                M A C H I N E  R O O M  
                                                
                                                (Qualified staff only) 
                                                                                                                                                               #>


# 5. Constructor



# Jump directly to one of the below topics. Activate (pf8) and double click on below line

. "C:\Users\henni\OneDrive\WindowsPowerShell\GREP_Jump.ps1"  
$Num = 19
Jump-To-GUISectionISE -Num $Num 



####################### TABLE OF CONTENT ################################ 
* Constructor          
* Base Constructor
* Constructor Overloads
* $this        
######################################################################### 

cls
Class Vehicle
{                                                                                                # Parent/Base class
                [string]  $Name    = "Mercedes"                   
                [string]  $Make    = "Daimler/Benz"
                [string]  $Model   = "W124 - 260"
                [int]     $Year    = 1989 
                [string]  $Color   = "Silver"  
                [decimal] $Lenghth = 4.6	
                [decimal] $Width   = 2.3
                [decimal] $Height  = 1.6
                [int]     $numberOfDoors = 4
                
                Vehicle() 
                {
                    Write-Host("`n")
                    Write-Host -Object "Base constructor called with no parameters"              # Default constructor
                } 
                
                Vehicle ([string]  $Name,                  
                         [string]  $Make,   
                         [string]  $Model,    
                         [int]     $Year,     
                         [string]  $Color,   
                         [decimal] $Lenghth,  
                         [decimal] $Width,    
                         [decimal] $Height,  
                         [int]     $numberOfDoors) 
                {
                 Write-Host("`n")
                 Write-Host("Instantiating a Vehicle object")                  
	                $this.Name   = $Name  
                    $this.Make   = $Make
                    $this.Model  = $Model
                    $this.Year   = $Year  
                    $this.Color  = $Color
		            $this.Lenghth= $Lenghth
		            $this.Width  = $Width
                    $this.Height = $Height            
                    $this.NumberOfDoors = $NumberOfDoors                         
                }   
                      
                #Member Method
                Display()
                {                      
                    Write-Host("`n")
                    Write-Host("V E H I C L E")               
                    Write-Host("Name: "    + $this.Name)
                    Write-Host("Make: "    + $this.Make)
                    Write-Host("Model: "   + $this.Model)  
                    Write-Host("Year: "    + $this.Year) 
                    Write-Host("Color: "   + $this.Color)                    
                    Write-Host("Lenghth: " + $this.Lenghth)
                    Write-Host("Width: "   + $this.Width)
                    Write-Host("Height: "  + $this.Height)      
                    Write-Host("NumberOfDoors:  " + $this.NumberOfDoors)                             
                }                       
}               
                
class Car : Vehicle 
{               
                [string] $Vin 
                [int]    $Milage = 50 
                
                Car ([string] $Vin,                                                               
                     [int]    $Milage)                     
                {
                 Write-Host("`n")
                 Write-Host("Instantiating a Car object")
                    $this.Vin   =  $Vin 	        
                    $this.Milage = $Milage                
                }    		           
 
                Car() 
                {
                    Write-Host -Object "Child constructor called with no parameters"  
                }      
                
                #Member Method
                Display()
                {                      
                    Write-Host("`n")
                    Write-Host("C A R")               
                    Write-Host("Vin: "    + $this.Vin)
                    Write-Host("Milage: " + $this.Milage) 
                }    
  
                [void] Drive([int] $Milage)                                                      # Method uden at returnere noget
                {                                                                
                    $this.Milage += $Milage
                }                             
}                 
############################### C L A S S ############################# ==> Vehicle - Car

#En Class skal bruges til at oprette et object -                                           
$MyVehicle = New-Object -TypeName Vehicle  
$MyVehicle.Display()

$Mycar = New-Object -TypeName Car  
$Mycar.Drive(10)                                                         
$Mycar.Milage  
$Mycar.Vin = "1A2B3C4D5E6F"                                                                               
$Mycar.Display()   
       
#########################################################################


# __________ Constructor ________________


Constructor

A Constructor is a type of method that is called only when an object is created. A constructor must use the same name as the class.

Let’s say we create a class called CyberNinja with properties for the ninja’s Alias and HitPoints. 
By design, we would not want to allow someone to create a ninja object without filling in the required properties. 
To force any required arguments, we need a constructor.

Constructors are similar to the Begin block in Functions.


#########################################################################


class CyberNinja
{
    # Constructor
    CyberNinja ([String] $Alias, [int32] $HitPoints)
    {
        $this.Alias = $Alias
        $this.HitPoints = $HitPoints
    }
}

#########################################################################


# __________ Base Constructor ________________


Base Constructor

A child class can call the constructor of its parent by using the : base() command on its constructor


#########################################################################

	

class ZeroWing
{
    [String] $User
    [String] $Message

    ZeroWing([String] $User, [String] $Message)
    {
        $this.User = $User
        $this.Message = $Message
    }

    [String] TurnOn()
    {
        return ("{0} : {1}" -f $this.User, $this.Message)
    }
}

class MainScreen : ZeroWing
{
    MainScreen([String] $User, [String] $Message) : base($User, $Message)
    {

    }
}

# The constructor for MainScreen maps parameters to the base constructor.


$mainScreen = [MainScreen]::new("CATS", "All your base are belong to us.")

$mainScreen.User
CATS

$mainScreen.TurnOn()
CATS : All your base are belong to us.
   
#########################################################################


# __________ Class Constructor Overloads ________________


Class Carr
{
        [String]$vint    
        [int]$numberOfDoors
        [int]$year
        [String]$model 
        static [int]$numberOfWheels = 4

        Carr() {}                                                                                              

        Carr ([string]$vint)                                                                      # Overload Constructors 
             {
                $this.vint = $vint
             }

        Carr ([string]$vint, [string]$model)
             {
                $this.vint = $vint
                $this.model = $model
             }

        Carr ([string]$vint, [string]$model, [int]$year)
             {
                $this.vint = $vint
                $this.model = $model
                $this.year = $year
             }

        Carr ([string]$vint, [string]$model, [int]$year, [int]$numberOfDoors)
             {
                $this.vint = $vint
                $this.model = $model
                $this.year = $year
                $this.numberOfDoors = $numberOfDoors
             }
}
######################################################################### 

[car]
[car]::new
[car]::new() 
[Car]::new(12345)                                                                                # Kald af overload constructors
[Car]::new(12345,"chevy")
[Car]::new(12345,"chevy", 1989)
[Car]::new(12345,"chevy", 1989, 4)

#########################################################################


# _________ $this _________________


$this

The $this variable describes the current instance of the object. It is thought of like $_ for classes.

I f a property is not static, the syntax $this.PropertyName is used to reference the instance property.
To refer to methods simply use the method name or $this.MethodName().


