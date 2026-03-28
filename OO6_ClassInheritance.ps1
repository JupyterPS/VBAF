                                                                                                                                                        <#
                                                     - oo00oo -  
                                               
                                                    Inheritance        
                                               
                                                M A C H I N E  R O O M  
                                                
                                                (Qualified staff only) 
                                                                                                                                                               #>


# 6. Inheritance


####################### TABLE OF CONTENT ################################ 
* Inheritance                  
######################################################################### 

cls
Class book
{               
                [String]$Category
                [String]$LastCheckedDate
                
                book(){}          
                
                #Member Method
                Display()
                {                      
                    Write-Host("`n")
                    Write-Host("B O O K")    
                    Write-Host("Category: "        + $this.Category)  
                    Write-Host("LastCheckedDate: " + $this.LastCheckedDate)         
                }   
                
                SetLastCheckedDate() 
                {                                                                                # Method
                    $this.LastCheckedDate = [DateTime]::Today
                }               
}
                
Class history : book
{                                                                                                # Family
                [String]$HistoryPeriod               
                
                history(){}

                #Member Method
                Display()
                {                      
                    Write-Host("`n")
                    Write-Host("H I S T O R Y")    
                    Write-Host("HistoryPeriod: "   + $this.HistoryPeriod)  
                    Write-Host("LastCheckedDate: " + $this.LastCheckedDate)
                    Write-Host("`n")         
                } 
                
                [String] GetLastCheckedDate()                                                    # Method
                {                                                                             
                    if($this.LastCheckedDate -lt $([DateTime]::Today))
                    {
                        return $this.LastCheckedDate
                    }
                    else 
                    {
                       return ([DateTime]::Today)
                    }
                }
                 
                SetLastCheckedDate([DateTime]$Date)                                              # Method
                {
                    $this.LastCheckedDate = $Date
                }
}               
############################ I N H E R I T A N C E ####################### ==> Book - History

$mybook = [Book]::new()
$mybook.Category = "history"
$mybook.SetLastCheckedDate()
$mybook.Display()

$myHistory = [History]::new()
$myHistory.HistoryPeriod = "MiddleAge"
$myHistory.SetLastCheckedDate([DateTime]::Today)
$myHistory.GetLastCheckedDate()
$myHistory.Display()

#########################################################################


# __________ Inheritance ________________ 


Inheritance

Inheritance allows for programmers to create classes from existing classes by extending them. 
In this way, we can reuse classes and extend the functionality without editing a closed class. *cough SOLID* 
When a class is extended, all of the members from the base or parent class are inherited (passed on) to the child class.

To extend a class, use the syntax Class Child : Parent.

#########################################################################
	

# Foo is the parent class
class Foo
{
    [string] $Message = "Hello!"

    [string] GetMessage()
    {
        return ("Message: {0}" -f $this.Message)
    }
}

# Bar extends Foo and inherits its members
class Bar : Foo
{

}

#########################################################################
The class Bar does not declare any properties or methods. If we create an instance of the Bar class, 
it will inherit all of the members of its parent class.
#########################################################################

$myBar = [Bar]::new()

$myBar.Message
Hello!

$myBar.GetMessage()
Message: Hello!




