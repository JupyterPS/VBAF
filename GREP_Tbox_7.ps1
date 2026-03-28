                                                                                                                                                          <#
                                                    - oo00oo -  
                                               
                                                   S t r i n g s        
                                               
                                                M A C H I N E  R O O M  
                                                
                                                (Qualified staff only) 
                                                                                                                                                  #>
 


# 7. Strings


  # Sequences of characters used to represent text.
  # Strings can be defined using single quotes (') for literal strings or double quotes (") for expandable strings.
  # String manipulation methods and operators can be used to work with strings.

       $greeting = "Hello, World!"
       $name = 'John'
       $message = "$greeting My name is $name."  # Expands $name
       Write-Host $message                                                                                # Output: Hello, World! My name is John.

<###################################### >>> Additional referrals <<< ###############################

Start-Process "https:/books.goalkicker.com/PowerShellBook/PowerShellNotesForProfessionals.pdf"            Chapter9: Strings
Start-Process "https:/powershellbyexample.dev/"     
  
###################################################################################################>  

# Explicitly typing/casting a PowerShell Variable


# Note: Powershell tries to simplify variable declaration and usage by not forcing strong data typing. 
# To achieve this? It treats most data as string data by default. String data is a collection of chars.
# Unfortunately, this can create unexpected outcomes and create errors in calculations. For example:

# A. This calculates correctly, PowerShell auto-chooses the correct data types
$ANumber = 222;
$MyNumber = $ANumber * 2;
Write("MyNumber is now: " + $MyNumber);  

# Above, everything calculates correctly and MyNumber displays as 444.

# B. This calculates incorrectly, PowerShell chooses wrong data type since input is a string
$MyNumber = Read-Host("Please enter a number");
$MyNumber = $MyNumber * $MyNumber;
Write("MyNumber squared is: " + $MyNumber);

# If I enter "4"? I should get the square of 4. But because Powershell treats it as a string data type instead
# of an integer data type? It displays the incorrect value of "4444" instead of "16". Powershell is treating
# the data type as string, so it displays the char "4" 4 times. It's not treating it as integer data.
  
# C. We can help powershell as programmers by explicitly declaring the data type of the input variable. The syntax
# for this is very simliar to type-casting in C++ and Java, where you convert one data type to another. In 
# Powershell, to explicitly declare the data type of a variable use [] and insert the explicit data type in between.

[Int]$MyNumber = Read-Host("Please enter a number");
$MyNumber = $MyNumber * $MyNumber;
Write("MyNumber squared is: " + $MyNumber);
 
#Notice when I enter the exact same value "4" above? It now calcualtes the square correctly as "16".

# Another example:
[DateTime]$FooledMe = "April 1, 2020"; 
$CurrentDate = Get-Date; 
$Days = ($CurrentDate - $FooledMe).Days; 
Write-Host "Worst prank ever $Days day(s) ago.";

# Example above explicitly forces the string data "April 1, 2020" into a [DataTime] class oject in PowerShell.
# Now that it is the right data type? It can be used for calculations.

<#
    Here are some values you can EXPLICITLY convert/cast to in PowerShell:

    [Int] = 32-bit integers
    [Int32] = 32-bit integers
    [Float] = floating point, for large numbers or extra decimal precision
    [Single] = floating point, for large numbers or extra decimal precision
    [Bool] = boolean values, either $true or $false
    [String] = a string of text
    [Array]	= an array, a collection of variable objects
    [DateTime] = date and time object
    [TimeSpan]= a time interval
    [Guid] = GUID 32-byte identifier
    [HashTable]	= hash table with key-value pairs
    [ScriptBlock] = powerShell script block
    [PsObject] = a powerShell object
    [XmlDocument] = an XML document
    [Regex]	= a regular expression
#>

#Note: You can use the methods "GetType()" to get a variable's data type if you aren't sure. 	
$b = 444;
$b.GetType().Name

###################################################################################################

# More Examples:

#----Example 1: Reading string data and storing it in variables--------

function Pony_Database
{
         $UserName = Read-Host("Please enter your NAME");
         $UserAge = Read-Host("Please enter your AGE");
         $UserSpecies = Read-Host("Please enter your SPECIES");
         $UserGender = Read-Host("Please enter your GENDER");

         Write("`nStats:`n");
         Write("Name: " + $UserName);
         Write("Age: " + $UserAge);
         Write("Species: " + $UserSpecies);
         Write("Gender: " + $UserGender);
}


###################################################################################################


#----Example 2: Reading a string data and storing it in a variable--------

function Guess_My_Number
{
         $MyNumber = 444;

         $BestGuess = Read-Host("What is MyNumber?");

         if($BestGuess -EQ $MyNumber)
         { Write("What luck! You guessed my number!"); }
         else
         { Write("Sorry. That was NOT my number."); }

}
  
# Call the Menu again
invoke-expression -Command "$basePath\HO_ToolBox_Menu.ps1"
