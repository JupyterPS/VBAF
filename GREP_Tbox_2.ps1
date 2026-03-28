                                                                                                                                                        <#
                                                     - oo00oo -  
                                                
                                                      L o o p s        
                                                
                                                 M A C H I N E  R O O M  
                                                 
                                                 (Qualified staff only) 

                                                                                                                                                           #>

# 2. Loops

# Jump directly to one of the below topics. Activate (run selected lines - pf8) at top left

. "C:\Users\henni\OneDrive\WindowsPowerShell\GREP_Jump.ps1"  
$Num = 2
Jump-To-GUISectionISE -Num $Num 


  # For Loop:
     for ($i = 0; $i -lt 5; $i++)
     {
         # code block
     }    
     
     # Foreach Loop:
     foreach ($i in 1..5) {
         Write-Host "Iteration $i"  # Outputs: Iteration 1, Iteration 2, ..., Iteration 5       
     } 

<###################################### >>> Additional referrals <<< ###############################

Start-Process "https:/books.goalkicker.com/PowerShellBook/PowerShellNotesForProfessionals.pdf"            Chapter7: Loops   
Start-Process "https:/powershellbyexample.dev/"                                                           For                                               
Start-Process "https:/powershellbyexample.dev/"                                                           Foreach 
Start-Process "https:/www.codecademy.com/resources/docs/powershell/loops"  
  
###################################################################################################>  

# Title: PowerShell Repetition Structures  
# A Basic FOR LOOP                                       
# B ForEach LOOP 
# C While LOOP  
# D Do While LOOP (will always execute at least ONCE) 
# E Do Until LOOP 


#Title: PowerShell - Module 04 - Repetition Structures                                                       
#Author: Carly S. Germany
#Date: 05/04/2020

# A. Basic FOR LOOP


     # For Loop:
     for ($i = 0; $i -lt 5; $i++)
     {
         # code block
     }    

     
     foreach ($i in 1..5) {
         Write-Host "Iteration $i"  # Outputs: Iteration 1, Iteration 2, ..., Iteration 5       
     } 
     

function Basic_For_Loop_1
{
         for($X = 0; $X -LT 5; $X++)
         {
             Write("Interation # " + ($X+1) + ".");
         }
}


function Basic_For_Loop_2
{
         Write("`n");
         $OUTPUT = "*";

         for($X = 0; $X -LT 5; $X++)
         {
             Write($OUTPUT);
             $OUTPUT = $OUTPUT + "*";
         }
}


function Basic_NESTED_For_Loop
{
         Write("`n");
         $ROWS = 5;
         $COLUMNS = 10;

         for($X = 0; $X -LT $ROWS; $X++)
         {
              for($Y = 0; $Y -LT $COLUMNS; $Y++)
              {
                  Write("Row = " + ($X+1) + ". Column = " + ($Y+1) + "");
              }

              Write("---------------------------------------");
         }
}

############################################################################
# B. ForEach LOOP
############################################################################

function Basic_ForEach_LOOP
{
         Write("`n");

         $MLP_Main_Characters = @("Twilight Sparkle",
                                  "Fluttershy",
                                  "Rainbow Dash",
                                  "Apple Jack",
                                  "Rarity",
                                  "Pinkie Pie");
         $PonyCounter = 0;

         ForEach($PONY in $MLP_Main_Characters)
         {
              $PonyCounter++;
              Write("Character " + $PonyCounter + " is " + $PONY);
         }
}


$array = "Brian", "Joe", "Steve", "Sue", "Mary"
Foreach ($item in $array)
{
write-Host "The current name is: $item."
}


Function show-colors( ) {
     $colors = [Enum]::GetValues( [ConsoleColor] )
     $max = ($Colors | foreach-object { "$_ ".Length } | Measure-object -Maximum).Maximum
     foreach($color in $colors ) {
          Write-host (" {0,2} {1,$max} " -f [int]$color,$color) -NoNewline
          Write-host "$color" -Foreground $color
     }
     }
show-colors 


$path = "$basePath\myfile.txt"
$lines = get-content -Path $path
    foreach($line in $lines) {
    if ($line -imatch "Hello there") {
        write-host $line
    }        
}  


$array = "Brian", "Joe", "Steve", "Sue", "Mary"
Foreach ($item in $array)
{

write-Host "The current name is: $item."

}

$c = 0  # Initialize $c outside the loop
Get-PSDrive | Where-Object {$_.free -gt 1} |
ForEach-Object {
    write-host "Only first." -backgroundcolor yellow
    $c = $c + 1
    write-host "Every time." $c -backgroundcolor green
    write-host "Only last." -backgroundcolor magenta "`nværdien er:" $c
}
 
Get-ChildItem | ForEach-Object { write-host("Fi1e name is: " + $_.FullName) }
$path = "$basePath\Myfile.txt"
(Get-Content $path) | ForEach-Object { $_ -replace '8', '2'} | Set-Content $path 


############################################################################
# C. While LOOP
############################################################################

function Basic_While_LOOP
{
         $LuckyNumber = 448;
         $Counter = 444;

         while($Counter -LT $LuckyNumber)
         {
            $Counter++;
            Write("LuckyNumber = " + $Counter + ".");
         }

}

############################################################################
# D. Do While LOOP (will always execute at least ONCE)
############################################################################

function Basic_Do_While_LOOP
{
         $LuckyNumber = 444;
         $Counter = 0;

         do
         {
            $Counter++;
            Write("LuckyNumber = " + $Counter + ".");
         }
         while($Counter -LT $LuckyNumber)
}

$Count = 0
While ($Count -lt 5) {
    Write-host $Count 
    $Count ++
}
 

$count = 0
 Do {
      $count  ++
      write-host $count 
} while($count -ne 10)

$Count = 0  
Do {
    $Count ++ 
    write-host $Count 
    If ($Count -eq 8)  
   {
    "Interupting Loop"
        Break
}
} while($Count -ne 10)

$Count = 0  
Do {
    $Count ++ 
    write-host $Count 
    If ($Count -eq 8)  
   {
    "Interupting Loop"
        Break
}
} while($Count -ne 10)

############################################################################
# E. Do Until LOOP
############################################################################

function BASIC_DO_Until_LOOP
{
         $LuckyNumber = 444;
         $Counter = 0;

         do
         {
            $Counter++;
            Write("LuckyNumber = " + $Counter + ".");
         }
         until($Counter -EQ $LuckyNumber)
}

$count = 0
 Do {
      $count  ++
      write-host $count 
} until($count -eq 5)
 
$count = 0
 Do {
      $count  ++
      write-host $count 
} until($count -eq 5)


############################################################################
# F. Guessing Games
############################################################################

#Title: PowerShell Number Guessing Game
#Author: Carly S. Germany
#Date: 05/04/2020

function NumberGame_1
{
         $Min = 1;
         $Max = 5;
         $GUESS = 0;
         $Score = 0;
         $The_Number = Get-Random -Minimum $Min -Maximum ($Max + 1);

         Clear;
         Write("`nNumber Guessing Game 1.0`n");
         Write("`nGuess my number between " + $Min + " and " + $Max + ".");
         Write("You get 3 guesses.");

         for($z = 0; $z -LT 3; $z++)
         {
             [Int]$GUESS = Read-Host("`nAttempt # " + ($z+1) + "?");
             
             if($GUESS -LT $Min)
             {
                  Write("Invalid guess. Less than minimum.");
             }
             elseif($GUESS -GT $Max)
             {
                  Write("Invalid guess. Greater than maximum.");
             }
             else
             {
                  Write("Guess is valid - within range.");

                  if($GUESS -EQ $The_Number)
                  {
                      Write("You did it! You guessed my number.");
                      $Score++;
                      $z = 3;
                  }
                  elseif($GUESS -GT $The_Number)
                  {
                      Write("My number was smaller.");
                  }
                  else
                  {
                      Write("My number was bigger.");
                  }

             } 
         }

         Write("`nMy number was: " + $The_Number + "");
         Write("Score: " + $Score + "");

}

############################################################################

function NumberGame_2
{
         $Menu = "LOOP";
         $CHOICE = "";
         $The_Number = 0;
         $Min = 0;
         $Max = 0;

         while($Menu -EQ "LOOP")
         {
              Clear;
              Write("`nNumber Guessing Game 2.0`n");
              Write("------------------------------------------");
              Write("|      Choose a level of difficulty:     |");
              Write("|                                        |");
              Write("|      1 = EASY (1-5)                    |");
              Write("|      2 = NORMAL (1-10)                 |");
              Write("|      3 = HARD (1-100)                  |");
              Write("|                                        |");
              Write("------------------------------------------`n");

              $CHOICE = Read-Host("CHOICE?");

              if($CHOICE -EQ "1")
              { 
                 $Min = 1;
                 $Max = 5;
                 $Menu = "EXIT";
                 $The_Number = Get-Random -Minimum $Min -Maximum ($Max + 1);
              }
              elseif($CHOICE -EQ "2")
              {
                 $Min = 1;
                 $Max = 10;
                 $Menu = "EXIT";
                 $The_Number = Get-Random -Minimum $Min -Maximum ($Max + 1);                 
              }
              elseif($CHOICE -EQ "3")
              {
                 $Min = 1;
                 $Max = 100;
                 $Menu = "EXIT";
                 $The_Number = Get-Random -Minimum $Min -Maximum ($Max + 1);                 
              }
              else 
              { 
                  Write("`nInvalid CHOICE. Choose again.");
                  Read-Host("Press ENTER to continue."); 
              }

         }
}

############################################################################

function NumberGame_3
{
         $Min = 1;
         $Max = 10;
         $NumbersToGuess = 3;
         $NumberGuessesPerNumber = 3;
         $GUESS = 0;
         $Score = 0;
         $The_Number = Get-Random -Minimum $Min -Maximum ($Max + 1);

         Clear;
         Write("`nNumber Guessing Game 3.0`n");
         Write("`nYou have the opportunity to guess " + $NumbersToGuess + " different numbers.")

         for($x = 0; $x -LT $NumbersToGuess; $x++)
         {
               Write("`n-----------------------------------------");
               Write("Guessing for Number: " + ($x+1) + "");

               Write("`nNumber " + ($x+1) + " is between " + $Min + " and " + $Max + ".");
               Write("You get " + $NumberGuessesPerNumber + " guesses for this number.");

               for($z = 0; $z -LT $NumberGuessesPerNumber; $z++)
               {
                   [Int]$GUESS = Read-Host("`nAttempt # " + ($z+1) + "?");
             
                   if($GUESS -LT $Min)
                   {
                        Write("Invalid guess. Less than minimum.");
                   }
                   elseif($GUESS -GT $Max)
                   {
                        Write("Invalid guess. Greater than maximum.");
                   }
                   else
                   {
                        Write("Guess is valid - within range.");

                        if($GUESS -EQ $The_Number)
                        {
                            Write("You did it! You guessed my number.");
                            $Score++;
                            $z = 3;
                        }
                        elseif($GUESS -GT $The_Number)
                        {
                            Write("My number was smaller.");
                        }
                        else
                        {
                            Write("My number was bigger.");
                        }

                   } 
               }

               Write("`nMy number was: " + $The_Number + "");
               Write("Score: " + $Score + "");
         }
}

############################################################################

function NumberGame_4
{
         $Menu = "LOOP";
         $Min = 1;
         $Max = 10;
         $NumbersToGuess = 3;
         $NumberGuessesPerNumber = 3;
         $GUESS = 0;
         $Score = 0;
         $The_Number = Get-Random -Minimum $Min -Maximum ($Max + 1);

         Clear;
         Write("`nNumber Guessing Game 4.0`n");
         Write("`nYou have the opportunity to guess " + $NumbersToGuess + " different numbers.")

         while($Menu -EQ "LOOP")
         {
              Write("------------------------------------------");
              Write("|      Choose a level of difficulty:     |");
              Write("|                                        |");
              Write("|      1 = EASY (1-5)                    |");
              Write("|      2 = NORMAL (1-10)                 |");
              Write("|      3 = HARD (1-100)                  |");
              Write("|                                        |");
              Write("------------------------------------------`n");

              $CHOICE = Read-Host("CHOICE?");

              switch($CHOICE)
              {
                 1 
                 {  
                     $Min = 1;
                     $Max = 5;
                     $Menu = "EXIT";
                 }
                 2 
                 {  
                     $Min = 1;
                     $Max = 10;
                     $Menu = "EXIT";
                 }
                 3 
                 {  
                     $Min = 1;
                     $Max = 100;
                     $Menu = "EXIT";
                 }
                 default 
                 {  
                     Write("`nInvalid CHOICE. Choose again.");
                     Read-Host("Press ENTER to continue."); 
                 }
              }
         }

         for($x = 0; $x -LT $NumbersToGuess; $x++)
         {
               $The_Number = Get-Random -Minimum $Min -Maximum ($Max + 1);

               Write("`n-----------------------------------------");
               Write("Guessing for Number: " + ($x+1) + "");

               Write("`nNumber " + ($x+1) + " is between " + $Min + " and " + $Max + ".");
               Write("You get " + $NumberGuessesPerNumber + " guesses for this number.");

               for($z = 0; $z -LT $NumberGuessesPerNumber; $z++)
               {
                   [Int]$GUESS = Read-Host("`nAttempt # " + ($z+1) + "?");
             
                   if($GUESS -LT $Min)
                   {
                        Write("Invalid guess. Less than minimum.");
                   }
                   elseif($GUESS -GT $Max)
                   {
                        Write("Invalid guess. Greater than maximum.");
                   }
                   else
                   {
                        Write("Guess is valid - within range.");

                        if($GUESS -EQ $The_Number)
                        {
                            Write("You did it! You guessed my number.");
                            $Score++;
                            $z = 3;
                        }
                        elseif($GUESS -GT $The_Number)
                        {
                            Write("My number was smaller.");
                        }
                        else
                        {
                            Write("My number was bigger.");
                        }

                   } 
               }

               Write("`nMy number was: " + $The_Number + "");
               Write("Score: " + $Score + "");
         }

         Write("Final score for all " + $NumbersToGuess + " numbers is: " + $Score + "");
}

############################################################################

#Invocations
NumberGame_1
NumberGame_2
NumberGame_3
NumberGame_4
Basic_For_Loop_1

############################################################################ 

# Call the Menu again
invoke-expression -Command "$basePath\HO_ToolBox_Menu.ps1"