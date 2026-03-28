                                                                                                                                                           <#
                                                     - oo00oo -  
                                             
                                                   Conditional Logic        
                                                
                                                 M A C H I N E  R O O M  
                                                 
                                                 (Qualified staff only) 
                                                                                                                                                   #>

# 4. Conditional Logic


  # Controls the flow of execution in a script.
  # Loops are control structures that allow you to execute a block of code multiple times. 
  # Common types include for, foreach, and while.
   
     $temperature = 75
     if ($temperature -gt 80) {
         Write-Host "It's hot outside."
     } elseif ($temperature -lt 60) {
         Write-Host "It's cold outside."
     } else {
         Write-Host "The weather is pleasant."
     }


<###################################### >>> Additional referrals <<< ###############################

Start-Process "https:/books.goalkicker.com/PowerShellBook/PowerShellNotesForProfessionals.pdf"            Chapter6: Conditional logic
Start-Process "https:/powershellbyexample.dev/"                                                           If/Else  
Start-Process "https:/www.codecademy.com/resources/docs/powershell/conditionals"       
  
###################################################################################################>                  

#Title: PowerShell - Conditional Logic
#Author: Carly S. Germany
#Date: 04/24/2020


# Note: One of the most useful things to learn in Powershell or any programming language after variables and data
# types is DECISION STRUCTURES. These will allow you to do things with the values stored in your variables and
# code logic and behavior that will flow in different ways based on those values. There are two basic decision
# structures in most programming languages. Powershell is no exception.



# Title: PowerShell - Conditional Logic
# 1. The IF/ELSE decision structure 

$Number = 2020 
$SrvName = "Server5"
if ($Number -gt 2020) {$SrvName + " is not installed on this computer."}
ElseIf ($Number -lt 2020) {$SrvName + " is working." }
ElseIf ($Number -eq 2020) {$SrvName + " is not working." }
Else {}

$value = 5
if ($value -gt 10) {
    Write-Host "value is greater than 10"
}
else {
    Write-Host "value is $value"
}

if ($value -gt 10) {
    Write-Host "value is greater than 10"
}
elseif ($value -lt 10) {
    Write-Host "value is less than 10"
}
else {
    Write-Host "value is 10"
}

################################################################################################### 

# 1. The IF/ELSE decision structure

#-----Example 1 - Guess My Number---------------

function Guess_My_Number_1
{
         $MyNumber = 444;
         $PlayersGuess = 0;

         Write("`nGreetings, player one.");
         Write-Host("Can you guess my number? ") -NoNewLine;

         $PlayersGuess = $Host.UI.ReadLine();

         if($PlayersGuess -EQ "444")
         { Write("Yes! That's it! You guessed my number!"); }
         else
         { Write("Sorry, that was wrong. You did NOT guess my number."); }
}

################################################################################################### 

function Guess_My_Number_2
{
         $MyNumber = 444;
         $PlayersGuess = 0;

         Write("`nGreetings, player one.");

         $PlayersGuess = Read-Host("Can you guess my number?");

         if($PlayersGuess -EQ "444")
         { Write("Yes! That's it! You guessed my number!"); }
         else
         { Write("Sorry, that was wrong. You did NOT guess my number."); }

}

################################################################################################### 

function Guess_My_Random_Number_1
{
         $MyNumber = 0;
         $PlayersGuess = 0;

         Write("`nGreetings, player one.");
         Write("Generating a random number between 1 and 10.");

         #Generates random #. Max must be +1 for offset
         $MyNumber = Get-Random -Minimum 1 -Maximum 11; 

         $PlayersGuess = Read-Host("Can you guess my number?");

         if($PlayersGuess -EQ $MyNumber)
         { Write("Wow! You guessed my number!"); }
         else
         { Write("Sorry. You did NOT guess my number."); }

         Write("`nThe random number generated was: " + $MyNumber);

}

################################################################################################### -

function Guess_My_Random_Number_2
{
         $MyNumber = 0;
         $PlayersGuess = 0;
         $MAXnum = 10;
         $MINnum = 1;

         Write("`nGreetings, player one.");
         Write("Generating a random number between " + $MINnum + " and " + $MAXnum + ".");

         #Remember: Max must be +1 for offset
         $MyNumber = Get-Random -Minimum $MINnum -Maximum ($MAXnum + 1);

         #Note: Still not what we expect cause processed as STRING, not INT.
         #So if we enter a negative number it won't process logic properly
         $PlayersGuess = Read-Host("Can you guess my number?");

         if($PlayersGuess -LT $MINnum)
         {
             Write("INVALID. Too low. Your guess is BELOW the minimum range.");
         }
         elseif($PlayersGuess -GT $MAXnum)
         { 
             Write("INVALID. Too high. Your guess is ABOVE the maximum range."); 
         }
         else
         {
             Write("You entered valid number between " + $MINnum + " and " + $MAXnum + ".");
             
             if($PlayersGuess -EQ $MyNumber)
             { 
                 Write("Wow! You guessed my number!"); 
             }
             else
             { 
                 Write("Sorry. You did NOT guess my number."); 
             }        
         }

         Write("`nThe random number generated was: " + $MyNumber);
}

################################################################################################### 

function Guess_My_Random_Number_3
{
         $MyNumber = 0;
         $PlayersGuess = 0;
         $MAXnum = 10;
         $MINnum = 1;

         Write("`nGreetings, player one.");
         Write("Generating a random number between " + $MINnum + " and " + $MAXnum + ".");

         #Remember: Max must be +1 for offset
         $MyNumber = Get-Random -Minimum $MINnum -Maximum ($MAXnum + 1);

         #Note: Here we take STRING data type and cast/convert to Int.
         #Now the logic will work properly
         [Int]$PlayersGuess = Read-Host("Can you guess my number?");

         if($PlayersGuess -LT $MINnum)
         {
             Write("INVALID. Too low. Your guess is BELOW the minimum range.");
         }
         elseif($PlayersGuess -GT $MAXnum)
         { 
             Write("INVALID. Too high. Your guess is ABOVE the maximum range."); 
         }
         else
         {
             Write("You entered valid number between " + $MINnum + " and " + $MAXnum + ".");
             
             if($PlayersGuess -EQ $MyNumber)
             { 
                 Write("Wow! You guessed my number!"); 
             }
             else
             { 
                 Write("Sorry. You did NOT guess my number."); 
             }        
         }

         Write("`nThe random number generated was: " + $MyNumber);
} 

<################################################################################################### 

A. Hard Coding: Notice above that because we are no longer HARD CODING values into our logic?
The program is MUCH easier to modify, adapt, evolve and change.
By declaring our constants as variables at the top? We can change them only once
and not have to change those values dozens or hundreds of times throughout the code
when we are tweaking and modifying things or extending the program's funciotnality.
Writing code that is easy to maintain, modify and read is good practice. Avoid hard coding values.

B. Nesting: Notice above how we are NESTING one block of if/else decision structure inside another?
This is a way to write code that can make more complex logic decisions based on the data fed to it.
Complex logic in code can involve dozens or even hundreds of layers of decision structires nested
inside each other that allows the logic to branch off into multiplt contingencies.

###################################################################################################>  

# Call the Menu again
invoke-expression -Command "$basePath\HO_ToolBox_Menu.ps1"

