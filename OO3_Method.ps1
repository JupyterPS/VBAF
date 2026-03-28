                                                                                                                                                        <#
                                                     - oo00oo -  
                                               
                                                    M e t h o d s         
                                               
                                                M A C H I N E  R O O M  
                                                
                                                (Qualified staff only) 
                                                                                                                                                               #>


# 3. Methods 



# Jump directly to one of the below topics. Activate (pf8) and double click on below line

. "C:\Users\henni\OneDrive\WindowsPowerShell\GREP_Jump.ps1" 
$Num = 18
Jump-To-GUISectionISE -Num $Num 



####################### TABLE OF CONTENT ################################ 
* Methods          
* Method Chaining
* Overloaded Methods
* ToString        
######################################################################### 

cls
Class Dog
{               
                #Define properties
                [String]   $Name
                [int]      $Age
                [String]   $Breed
                [String]   $OwnerName
                [String]   $OwnerAddress
                [DateTime] $RegistrationDate
                [long]     $RegistrationNumber
                
                #Define static properties
                static [int] $NumberOfLegs = 4
                
                Dog() {}
                
                #Defines Constructor
                Dog([String]  $Name,
                    [int]     $Age,
                    [String]  $Breed,
                    [String]  $OwnerName,
                    [String]  $OwnerAddress,
                    [DateTime]$RegistrationDate,
                    [long]    $RegistrationNumber)
                {
                    Write-Host("Instantiating a Dog object")
                    $this.Name               = $Name
                    $this.Age                = $Age
                    $this.Breed              = $Breed
                    $this.OwnerName          = $OwnerName
                    $this.OwnerAddress       = $OwnerAddress
                    $this.RegistrationDate   = $RegistrationDate
                    $this.RegistrationNumber = $RegistrationNumber
                } 
     
                #Member Method
                Display()
                {                      
                    Write-Host("`n")
                    Write-Host("D O G")    
                    Write-Host("Name: "      + $this.Name)  
                    Write-Host("Age: "       + $this.Age)  
                    Write-Host("Breed: "     + $this.Breed)                     
                    Write-Host("OwnerName: " + $this.OwnerName)
                    Write-Host("OwnerAddress: "       + $this.OwnerAddress)
                    Write-Host("RegistrationDate: "   + $this.RegistrationDate) 
                    Write-Host("RegistrationNumber: " + $this.RegistrationNumber) 
                    Write-Host("`n")                         
                }  
                 
                #Defines Method Bark()
                [String] Bark()
                {
                    return "Woof! woof!"
                }
                
                #Defines Method Grow()
                Grow([int]$value)
                {
                    $this.Age = $this.Age + $value
                }
}               
############################ M E T H O D ################################ ==> Dog

#Using New-Object Parameters for ArgumentList are positional and required by the constructor.
$myDog = New-Object -TypeName Dog -ArgumentList "Lucy",6,"English Springer Spaniel","Cynthia G. Dumond","3105 Valley Lane, Austin, TX 78701","2017-12-12",2309         
$myDog.Display()   
           
$myDog.Bark()          # Method call     
$myDog.Grow(9)         # Method call 
$myDog.Age             # Result   

#########################################################################


# _________ Methods _________________

Methods

The term Method is a fancy way of describing a function defined inside of a class. In OOP, a method can take arguments the same as a function; 
however they must return a value.

    I f a method does not return a value, the return type is [Void].
    A data type should be type-hinted for each argument in the method header, e.g., [String] $Name.

A method should have an access modifier, name, arguments, and return type.

    The access modifier is considered public if left blank.
    I f static is not declared the property will be an instance type.


#########################################################################



class CyberNinja {
    # Public Properties
    [String] $Alias
    [Int32] $HitPoints

    # Static Properties
    static [String] $Clan = "Posh Shinobi"

    # Constructor
    CyberNinja([String] $alias, [Int32] $hitPoints) {
        $this.Alias = $alias
        $this.HitPoints = $hitPoints
    }

    # Instance Method
    [String] getAlias() {
        return $this.Alias
    }

    # Static Method
    static [String] getClan() {
        return [CyberNinja]::Clan
    }

    # Static Method
    static [String] Whisper([String] $Name) {
        return "Hello {0}!" -f $Name
    }
}

# Example of creating an instance of the class
$ninja = [CyberNinja]::new("Shadow", 100); $ninja

# Call instance method
$alias = $ninja.getAlias()
Write-Host "Ninja Alias: $alias"

# Call static methods
$clan = [CyberNinja]::getClan()
Write-Host "Ninja Clan: $clan"

$whisper = [CyberNinja]::Whisper("John")
Write-Host $whisper


#########################################################################



# _________ Method Chaining _________________


Method Chaining

Method chaining is a popular design pattern in languages such as JavaScript and PHP. 
Traditionally in functional languages, functions or constructors required large numbers of positional arguments. 
Method chaining gives us a way to create an object and set these values in a maintainable and readable fashion.

This pattern is also known as the named parameter idiom. To create this pattern:

    Create a method to set a property.
    Set the return type of the method to the class type.
    Set an instance variable.
    Return $this.

    # The following example uses Enums to handle defaults easily.


#########################################################################



Enum Crust
{
    Thin
    HandTossed
    DeepDish
}

Enum Sauce
{
    Marinara
    GarlicParmesan
    Buffalo
}

Enum Toppings
{
    Pepperoni
    Sausage
    Chicken
}

class Pizza
{
    [Crust] $crust
    [Sauce] $sauce
    [Toppings] $toppings

    # Default, Parameterless Constructor
    Pizza()
    {

    }

    # Named Constructor
    static [Pizza] newOrder()
    {
        return [Pizza]::New()
    }


    [Pizza] chooseCrust([Crust] $crust)
    {
        $this.crust = $crust
        return $this
    }

    [Pizza] addSauce([Sauce] $sauce)
    {
        $this.sauce = $sauce
        return $this
    }

    [Pizza] addToppings([Toppings] $toppings)
    {
        $this.toppings = $toppings
        return $this
    }

    [Void] placeOrder()
    {
        Write-Host ("Pizza ordered. Details {0}" -f $this.toString())
    }

    [String] toString()
    {
        return "Crust: {0} Sauce: {1} Toppings: {2}" -f $this.crust, $this.sauce, $this.toppings
    }

}

#########################################################################


# separate steps
$myPizza = [Pizza]::new()
$myPizza.chooseCrust("DeepDish").addSauce("GarlicParmesan").addToppings("Sausage") | Out-Null
$myPizza.placeOrder()

# combined steps, using named constructor
[Pizza]::newOrder().chooseCrust("HandTossed").addSauce("Marinara").addToppings("Pepperoni").placeOrder()

# Using Normal Constructor: Parens not required in first example
([Pizza]::new()).placeOrder()

(New-Object -TypeName Pizza).placeOrder()

# Chaining Example Multiline. The "." on the right feels strange.

cls
[Pizza]::newOrder().
    chooseCrust("HandTossed").
    addSauce("Marinara").
    addToppings("Pepperoni").
    placeOrder()

# Chaining Example 2 Multiline
[Pizza]::newOrder() `
   | %{$_.chooseCrust("HandTossed")} `
   | %{$_.addSauce("Marinara")} `
   | %{$_.addToppings("Chicken")} `
   | %{$_.placeOrder()}


#########################################################################


# _________ Overloaded Methods _________________ 


Overloaded Methods

Method Overloading is a way to define multiple methods with the same name. 
Overloaded methods behave differently depending on the number of arguments or the data types of the arguments supplied. 
In the following code example, SayHello() and add() can be called different ways.


#########################################################################



class OverloadExample
{
    static [String] SayHello()
    {
        return "Hello There!"
    }

    static [String] SayHello ([String] $Name)
    {
        return "Hello {0}!" -f $Name
    }

    static [int] add([int] $a, [int] $b)
    {
        return $a + $b
    }

    static [double] add([double] $a, [double] $b)
    {
        return $a + $b
    }
}	

[OverloadExample]::SayHello()
Hello There!

[OverloadExample]::SayHello("Mike")
Hello Mike!

[OverloadExample]::add(1, 2)
3

[OverloadExample]::add(1.1, 2.3)
3.4

#########################################################################
Methods and Constructors are overloadable.
We could also refactor the above example to simplify SayHello(). In this next snippet, 
the parameterless SayHello() method is funneled through the single argument method.
#########################################################################	

class OverloadRefactor
{
    # Calls Overloaded Method
    static [String] SayHello ()
    {
        return [OverloadRefactor]::SayHello("There")
    }

    static [String] SayHello ([String] $Name)
    {
        return "Hello {0}!" -f $Name
    }
}


[OverloadRefactor]::SayHello()
Hello There!

[OverloadRefactor]::SayHello("Mike")
Hello Mike!

#########################################################################


# _________ ToString _________________

ToString

ToString is one of the convenient object methods seen in traditional OOP. If an object is passed to a function which accepts a string argument, 
ToString will automatically be called.

I f ToString is not added/overwritten in the class, the default ToString method returns the class name.
The default object behavior can be forced by casting the object to [System.Object].


#########################################################################



class myColor
{
    [String] $Color
    [String] $Hex

    myColor([String] $Color, [String] $Hex)
    {
        $this.Color = $Color
        $this.Hex = $Hex
    }

    [String] ToString()
    {
        return $this.Color + ":" + $this.Hex
    }
}

$red = [myColor]::new("Red", "#FF0000")

Write-Host $red
Red:#FF0000

Write-Host ([System.Object]$red).ToString()
myColor


