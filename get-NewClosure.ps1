$Adder = {
    param ([int] $x)
    return (
        {
          param ([string] $y)

          return ($x + $y)
        }.GetNewClosure()
    )
}
Set-Item -Path Function:Adder -Value $Adder
$add5 = Adder 5
$add10 = Adder 10

$add5.Invoke(2)
$add10.Invoke(2)
<#
This statement creates a function called Adder that takes an integer as a parameter.
It then returns a closure that takes a string as a parameter and adds the integer to the string. 
The Set-Item command creates a new function called Adder with the value of the $Adder variable.
The $add5 variable is then set to the result of calling the Adder function with the parameter 5.
Finally the Invoke method is called on the $add5 variable with the parameter 3, which adds 5 to 3 and returns 8.

This Powershell script creates a function called Adder which takes an integer as a parameter. 
The function returns a closure which takes a string as a parameter and returns the sum of the integer and the string. 
The function is then stored in the Function:Adder path. A variable called add5 is then created
which calls the Adder function with the parameter 5.
Finally the add5 variable is invoked with the parameter 3, which returns the sum of 5 and 3.

Powershell creates this script to add two numbers because it allows for the creation of a closure,
which is a function that can access variables from the scope in which it was created.

This allows the Adder function to store the value of $x and then use it when the $add5 function is invoked.
This allows for the reuse of the Adder function with different values of $x, making it more efficient
than having to create a new function for each value of $x. 
#>






