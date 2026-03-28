                                                                                                                                                        <#
                                                     - oo00oo -  
                                               
                                                     Get_Setters        
                                               
                                                M A C H I N E  R O O M  
                                                
                                                (Qualified staff only) 
                                                                                                                                                               #>


# 7. Get_Setters


cls
class student 
{
        [string]$FirstName
        [string]$LastName
 
        student() {}   #Default constructor (forsvinder når du laver nye overload constr.; men kan tages tilbage ved at sætte den ind

        student([string]$Name)
        {                                                                                        # User constructor
            $this.SetName($Name)                                                                 
        }                                                                                        
                                                                                                 
        [string]GetName()                                                                        # Method 1
        {                                                                                        
            return "$($this.FirstName) $($this.LastName)"                                        
        }                                                                                        
                                                                                                 
        [void]SetName([string]$Name)                                                             # Method 2  
        {                                                                                        
            $this.FirstName = ($Name -split " ")[0]                                              
            $this.LastName = ($Name -split " ")[1]                                               
        }                                                                                        
                                                                                                 
        [void]SetName([string]$FirstName,[string]$LastName)                                      # Method 3
        {    
            $this.FirstName = $FirstName
            $this.LastName = $LastName
        }
}
#########################################################################

$student1 = [student]::new()                                                                     # Method 1  
$student1.FirstName = "Tyler"                                                                    
$student1.LastName = "Muir"                                                                      
$student1.GetName()                                                                              
                                                                                                 
$student1 = [student]::new()                                                                     # Method 2
$student1.SetName("Tyler Muir")                                                                  
$student1                                                                                        
                                                                                                 
$student2 = [student]::new()                                                                     # Method 3
$student2.SetName("Tyler"," Muir")                                                               
$student2                                                                                        
                                                                                                 
[student]::New                                                                                   # Show constructors
$student1 = [student]::new("Tyler Muir")                                                         # Call user constructor, split does it
$student1                                                                                        
                                                                                                 
[student]::New                                                                                   # pga af den specielle user_constructor (øverst)
                                                                                                 # har det sidste kald gjort at "STUDENT NEW (NAME)"
########################################################################






