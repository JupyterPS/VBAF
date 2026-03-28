                                                                                                                                                        <#
                                                     - oo00oo -  
                                               
                                                    Enumerations        
                                               
                                                M A C H I N E  R O O M  
                                                
                                                (Qualified staff only) 
                                                                                                                                                               #>


# 4. Enumerations


####################### TABLE OF CONTENT ################################ 
* Enumerations                  
######################################################################### 

cls
Enum Family
{               
     Pinus_canariensis = 1
     Pinus_cembra      = 2
     Pinus_halepensis  = 3 
     Pinus_mugo        = 4
     Pinus_nigra       = 5 
     Pinus_pinaster    = 6
     Pinus_pinea       = 7
     Pinus_ponderosa   = 8
     Pinus_radiata     = 9 
     Pinus_sylvestris  = 10
     Pinus_strobus     = 11
     Pinus_thunbergii  = 12
}               
                
class Tree
{               
                [String]$Species
                [int32] $Height  
                
                Tree() {}                                                                        # Default Constuctor  
                
                Tree ([String]$Species,
                      [int32]$Height)                                                            # User Constuctor
                {
                    Write-Host("Instantiating a Tree object")
                    $this.Species = $Species
                    $this.Height  = $Height
                }
                
                #Member Method
                Display()
                {                      
                    Write-Host("`n")
                    Write-Host("T R E E")    
                    Write-Host("Species: " + $this.Species)  
                    Write-Host("Height: "  + $this.Height)  
                    Write-Host("`n")                                                    
                }
                
                [int32]Grow ([int32]$Amount)                                                     # Method
                {
                    $this.Height += $Amount
                    return $this.Height
                }
}               
                
Class Pine : Tree                                                                                # Child class 
{               
                [Family]$Family
                
                Pine() 
                {
                    Write-Host -Object "Child constructor called with no parameters" 
                } 
                 
                Pine([string]$Species,
                     [int32] $Height,
                     [Family]$Family)                                                            # Constuctor to call with params
                {
                    Write-Host("Instantiating a Pine object")
                    $this.Species = $Species;
                    $this.Height  = $Height;
                    $this.Family  = $Family 
                }

                #Member Method
                Display()
                {                      
                    Write-Host("`n")
                    Write-Host("P I N E")    
                    Write-Host("Species: " + $this.Species)  
                    Write-Host("Height: "  + $this.Height)                     
                    Write-Host("Family: "  + $this.Family)                                        
                }  
}               
################################# E N U M ############################### ==> Tree - Pine

$myTree = New-Object -TypeName Tree -ArgumentList "Pine", 10                                     # The good old PowerShell way  
$myTree.Species = "Pine"                                                                        
$myTree.Height = 10                                                                             
$myTree =[Tree]@{Species="Pine"; Height=10}                                                      # Hashtable 
$myTree.Grow(18)                                                                                
$myTree.Display()                                                                               
                                                                                                 # Call without params
$myPine = [Pine]::new()                                                                                                                                     
$myPine.Family = (10)                                                                            # Her får properties værdier
$myPine = [Pine]::new("Pine",40,10)                                                              # Instantiating
$myPine.Display() 

#########################################################################  


# _________ Enumerations _________________

Enumerations

An Enum is a special Type which defines a set of named constants. In PowerShell, we can use an Enum as an argument type for a method in a Class. 
The Enum type lets a method restrict the argument values it can accept.


#########################################################################



Enum Turtles
{
    Donatello = 1
    Leonardo = 2
    Michelangelo = 3
    Raphael = 4
}


#To get names from an enum
[System.Enum]::GetValues([Turtles])

#To get int values from an enum
[System.Enum]::GetValues([Turtles]) | foreach { [int] $_ }




