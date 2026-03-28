                                                                                                                                                        <#
                                                     - oo00oo -  
                                                
                                                     S w i t c h        
                                                
                                                 M A C H I N E  R O O M  
                                                 
                                                 (Qualified staff only) 
                                                                                                                                                     #>


# 3. SWITCH



# Jump directly to one of the below topics. Activate (run selected lines - pf8) at top left

. "C:\Users\henni\OneDrive\WindowsPowerShell\GREP_Jump.ps1"  
$Num = 3
Jump-To-GUISectionISE -Num $Num 



  # Switch Statement:       
     $day = "Monday"
     switch ($day) {
         "Monday" { Write-Host "Start of the week" }
         "Friday" { Write-Host "End of the work week" }
          default { Write-Host "Midweek" }
     }


<###################################### >>> Additional referrals <<< ###############################

Start-Process "https:/books.goalkicker.com/PowerShellBook/PowerShellNotesForProfessionals.pdf"            Chapter8: Switch statement             
Start-Process "https:/powershellbyexample.dev/"                                                           Switch      
Start-Process "https:/www.codecademy.com/resources/docs/powershell/conditionals"        
  
###################################################################################################>   

# A. Switch statements are more simplistic decision structures. They cannot handle the comparisons, evaluations
# and complexity of nested if/else structures. However, they can be a very effective way to handle simple 
# decisions in powershell. Such as if you want to create a menu in your program.


Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms
$msgBoxInput =  [System.Windows.MessageBox]::Show('Would you like to play a game?','Game  input','YesNoCancel','Error')
  switch  ($msgBoxInput) {
  'Yes' {
  ## Do something 
  }
  'No' {
  ## Do something
  }
  'Cancel' {
  ## Do something
  }
  }


Function HitMe{
foreach ($i in (1..10)){ 
     if ($i -eq 10)    { "last chance" } 
        ($i - 1)   
  $numberUserTyped = read-host "Find the right number from 0 to 9? (you have 10 tries)"
  switch ($numberUserTyped )
{
  0 {"You typed zero"}
  2 {"You typed two"}
  4 {"You typed four"}
  6 {"You typed six"}
  9 {"You typed nine"} 
  default {"You didn't type the correct thing"} 
}
if ($i -eq 10)    { "Good bye" } 
} 
}
hitme
 

function Simple_Switch
{
         Write("`nEmotions I understand are: happy,sad,angry")

         $Feelings = Read-Host("How do you feel today?");

         switch($Feelings)
         {
            "happy" { Write("Yay! I will rejoice with you."); }
            "sad"  { Write("I'm sorry. Need a hug?"); }
            "angry" { Write("Close your eyes. Breath deep. Count to 10."); }
            default { Write("Sorry. I do not understand that emotion."); }
         }
}


function Simple_Number_Game_Using_Switch
{
         $MyNumber = 3;

         $MyNumber = Read-Host("Guess my number?");

         switch($MyNumber)
         {
            1 { Write("My number is HIGHER."); }
            2 { Write("My number is HIGHER."); }
            3 { Write("YES! You guessed my number!"); }
            4 { Write("My number is LOWER."); }
            5 { Write("My number is LOWER."); }
            default { Write("INVALID guess. Guess between 1 and 5."); }
         }
}


function Menu_Main_Using_Switch
{
         Write("`n");
         Write("     -------- Main Menu --------");
         Write("     |                          |");
         Write("     |    (C)reate Pokemon      |");
         Write("     |    (D)isplay Pokemon     |");
         Write("     |    (S)ave Pokemon        |");
         Write("     |    (L)oad Pokemon        |");
         Write("     |    (B)uild Pokemon Test  |");
         Write("     |    (X) Exit              |");
         Write("     |                          |");
         Write("     ---------------------------");
         Write("");

            switch(Read-Host "Choose")
            { 
                c {   
                      Write-Host("`n  Create Pokemon Method.`n") -foregroundcolor "Red"; 
                      break;
                  };

                d {  
                     Write-Host("`n  Display Pokemon Method.`n") -foregroundcolor "Red"; 
                     break;
                  };

                s {   
                     Write-Host("`n  Save Pokemon Method.`n") -foregroundcolor "Red";
                     break;
                  };

                l {  
                     Write-Host("`n  Load Pokemon Method.`n") -foregroundcolor "Red";
                     break;
                  };

                b {  
                     Write-Host("`n  Build Pokemon Test.`n") -foregroundcolor "Red";
                     break;
                  };

                x {  Write-Host("`n  Exiting ...") -foregroundcolor "Red"; $LOOP = "STOP";
                     break;
                  };

                default {   
                           Write-Host("`n  Invalid entry");
                        };

           } #close switch 
}

###################################################################################################

# B. bit more complex swich statement using {} to evaluate an expression before switching on the result.
# We will combine a switch statement in with our if/else decision structure.

function Guess_My_Random_Number_Using_Switch
{
         $MyNumber = 0;
         $PlayersGuess = 0;
         $MAXnum = 5;
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
             switch($PlayersGuess)
             {
                {$PlayersGuess -LT $MyNumber} { Write("Guessed LESS than my number."); }
                {$PlayersGuess -GT $MyNumber} { Write("Guessed MORE than my number."); }
                {$PlayersGuess -EQ $MyNumber} { Write("Yes! You guessed my number!"); }
                default { Write("Invalid response."); }

             }   
         }

         Write("`nThe random number generated was: " + $MyNumber);

          
}

###################################################################################################

# C. Last note: Using "break". It is common to use break after a switch statement. This will become more important
# after we cover repetition structures in the near future. The key word "break" stops the flow of the program 
# from executing any evaluations or switch cases below the case that has been matched and exits the switch.

#Example:

function Simple_Number_Game_Using_Switch_Break
{
         $MyNumber = 3;

         $MyNumber = Read-Host("Guess my number?");

         switch($MyNumber)
         {
            1 { Write("My number is HIGHER."); 
                break;
              }
            2 { Write("My number is HIGHER.");  
                break;
              }
            3 { Write("YES! You guessed my number!");  
                break;
              }
            4 { Write("My number is LOWER.");  
                break;
              }
            5 { Write("My number is LOWER.");  
                break;
              }
            default { Write("INVALID guess. Guess between 1 and 5.");  
                      break;
                    }
         }
}
Guess_My_Number_1

# Call the Menu again
invoke-expression -Command "$basePath\HO_ToolBox_Menu.ps1"
  