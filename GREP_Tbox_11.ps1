                                                                                                                                                          <#
                                                   - oo00oo -  
                                              
                                                 F u n ct i o n s        
                                              
                                               M A C H I N E  R O O M  
                                               
                                               (Qualified staff only) 
                                                                                                                                                 #>



# 11. Functions


  # A reusable block of code that performs a specific task.
  # Defined using the function keyword.

       function Add-Numbers {
           param (
               [int]$a,
               [int]$b
           )
           return $a + $b
       }
       
       $sum = Add-Numbers -a 5 -b 10          
       Write-Host "The sum is: $sum"                                                                      # Outputs: 15


<###################################### >>> Additional referrals <<< ###############################

Start-Process "https:/books.goalkicker.com/PowerShellBook/PowerShellNotesForProfessionals.pdf"            Chapter12: PowerShell Functions 
Start-Process "https:/powershellbyexample.dev/"                                                           Functions      
Start-Process "https:/www.codecademy.com/resources/docs/powershell/functions"     
  
###################################################################################################>    

# Title: PowerShell Functions                                                             
# Author: Carly S. Germany
# Date: 06/07/2020


function Make-Student {
    param(
        [string]$firstname="",
        [string]$lastname="",
        [int]$score=3,
        [int]$day = 1,
        [int]$month = 1,
        [int]$year = 2003

    )
     [PSCustomObject] @{
    "FirstName"=$firstname;
    "LastName"=$lastname;
    "Score"=$score;
    "Birthday"=(get-date -Minute 0 -Second 0 -Millisecond 0 -Hour 0 -Year $year -Day $day -Month $month)
    }
}

$students = @()
$students += make-student -firstname "Bob"    -lastname "Sinclair" -score 3 -day 1 -month 3
$students += make-student -firstname "Alice"  -lastname "Cooper" -score 8 -day 14 -month 4
$students += make-student -firstname "Frank"  -lastname "Sinatra" -score 7 -day 12 -month 9
$students += make-student -firstname "Oscar"  -lastname "Wilde" -score 7 -day 22 -month 5
$students


$global:Pokemon_Name = "Undefined";
$global:Pokemon_Species = "Undefined";
$global:Pokemon_Gender = "Undefined";
$global:Pokemon_Health = 0;
$global:Pokemon_Defense = 0;
$global:Pokemon_Attack = 0;

$global:Opponent_Name = "Undefined";
$global:Opponent_Species = "Undefined";
$global:Opponent_Gender = "Undefined";
$global:Opponent_Health = 0;
$global:Opponent_Defense = 0;
$global:Opponent_Attack = 0;

###################################################################################################
# Pokemon Game (displaying functions)
###################################################################################################

function Main
{
         $Menu = "LOOP";

         Clear;
         Write("`nPokémon Tournament 1.0`n");

         while($Menu -EQ "LOOP")
         {
              Write("`n                Main Menu");
              Write("------------------------------------------");
              Write("|                                        |");
              Write("|         1 = Create Pokémon             |");
              Write("|         2 = Display Pokémon            |");
              Write("|         3 = Create Opponent            |");
              Write("|         4 = Display Opponent           |");
              Write("|         5 = Tournament                 |");
              Write("|         x = EXIT                       |");
              Write("|                                        |");
              Write("------------------------------------------`n");

              $CHOICE = Read-Host("CHOICE?");

              switch($CHOICE)
              {
                 1 { Create_Pokemon; }
                 2 { Display_Pokemon; }
                 3 { Create_Opponent; }
                 4 { Display_Opponent; }
                 5 { Pokemon_Tournament; }
                 'x' { Write("`n Exiting Pokémon Tournament ..."); $Menu = "EXIT"; }
                 default 
                 {  
                     Write("`nInvalid CHOICE. Choose again.");
                     Read-Host("Press ENTER to continue."); 
                     Clear;
                 }
              }
         }
}

<# --------------------------------------------------------------------------------- #>

function Create_Pokemon
{
         $Min_Health = 75;
         $Max_health = 100;
         $Min_Defense = 5;
         $Max_Defense = 10;
         $Min_Attack = 2;
         $Max_Attack = 8;

         Write("`n-----------------------------------------");
         Write("Create your Pokémon!");

         $Menu = "LOOP";
         $CHOICE = "";

         while($Menu -EQ "LOOP")
         {
             Write("`nPick a species:");
             Write("`n   1. Pikachu`n   2. Mimikyu`n   3. Bulbasaur`n   4. Flareon`n   5. Charmander`n");

             $CHOICE = Read-Host("CHOICE?");

             switch($CHOICE)
             {
                 1 { $global:Pokemon_Species = "Pikachu"; $Menu = "EXIT"; }
                 2 { $global:Pokemon_Species = "Mimikyu"; $Menu = "EXIT"; }
                 3 { $global:Pokemon_Species = "Bulbasaur"; $Menu = "EXIT"; }
                 4 { $global:Pokemon_Species = "Flareon"; $Menu = "EXIT"; }
                 5 { $global:Pokemon_Species = "Charmander"; $Menu = "EXIT"; }
                 default 
                 {  
                     Write("`nInvalid CHOICE. Choose again.");
                     Read-Host("Press ENTER to continue."); 
                 }
              }
         }

         Write("`n");
         $global:Pokemon_Name = Read-Host("Name?");

         $Menu = "LOOP";

         while($Menu -EQ "LOOP")
         {
             Write("`nPick a gender:");
             Write("`n   (F)emale  or (M)ale?`n");

             $CHOICE = (Read-Host("CHOICE?")).ToLower();

             switch($CHOICE[0])
             {
                 'f' { $global:Pokemon_Gender = "Female"; $Menu = "EXIT"; }
                 'm' { $global:Pokemon_Gender = "Male"; $Menu = "EXIT"; }
                 default 
                 {  
                     Write("`nInvalid CHOICE. Choose again.");
                     Read-Host("Press ENTER to continue."); 
                 }
              }
         }

         Write("`nDetermining random stats ...");
         Write("Rolling dice ...`n");

         [Int] $global:Pokemon_Health = Get-Random -Minimum $Min_Health -Maximum ($Max_Health + 1);
         Write("Health = " + $global:Pokemon_Health);

         [Int] $global:Pokemon_Defense = Get-Random -Minimum $Min_Defense -Maximum ($Max_Defense + 1);
         Write("Defense = " + $global:Pokemon_Defense);

         [Int] $global:Pokemon_Attack = Get-Random -Minimum $Min_Attack -Maximum ($Max_Attack + 1);
         Write("Attack = " + $global:Pokemon_Attack);

         Write("`nA new Pokémon is born!")

         Write("`n-----------------------------------------");
}

<# --------------------------------------------------------------------------------- #>

function Display_Pokemon
{
         Write("`n----------Pokemon Stats----------");
         Write("Name: " + $global:Pokemon_Name);
         Write("Species: " + $global:Pokemon_Species);
         Write("Gender: " + $global:Pokemon_Gender);
         Write("Health: " + $global:Pokemon_Health);
         Write("Defense: " + $global:Pokemon_Defense);
         Write("Attack: " + $global:Pokemon_Attack);
         Write("-----------------------------------");
}

<# --------------------------------------------------------------------------------- #>

function Create_Opponent
{
         $Min_Health = 75;
         $Max_health = 100;
         $Min_Defense = 5;
         $Max_Defense = 10;
         $Min_Attack = 2;
         $Max_Attack = 8;

         Write("`nCreating opponent ...`n");

         [Int] $CHANCE = Get-Random -Minimum 1 -Maximum (5 + 1);

         switch($CHANCE)
         {
                 1 { $global:Opponent_Species = "Pikachu"; }
                 2 { $global:Opponent_Species = "Mimikyu"; }
                 3 { $global:Opponent_Species = "Bulbasaur"; }
                 4 { $global:Opponent_Species = "Flareon"; }
                 5 { $global:Opponent_Species = "Charmander"; }
         }

         Write("Species = " + $global:Opponent_Species);

         [Int] $CHANCE = Get-Random -Minimum 1 -Maximum (10 + 1);

         switch($CHANCE)
         {
                 1 { $global:Opponent_Name = "Daphne"; }
                 2 { $global:Opponent_Name = "Bubba"; }
                 3 { $global:Opponent_Name = "Ginger"; }
                 4 { $global:Opponent_Name = "Felix"; }
                 5 { $global:Opponent_Name = "Persiphone"; }
                 6 { $global:Opponent_Name = "Andromeda"; }
                 7 { $global:Opponent_Name = "Apollo"; }
                 8 { $global:Opponent_Name = "Elisa"; }
                 9 { $global:Opponent_Name = "Sparky"; }
                 10 { $global:Opponent_Name = "Kato"; }
         }

         Write("Name = " + $global:Opponent_Name);

         [Int] $CHANCE = Get-Random -Minimum 1 -Maximum (2 + 1);

         switch($CHANCE)
         {
            1 { $global:Opponent_Gender = "Female"; }
            2 { $global:Opponent_Gender = "Male"; }
         }

         Write("Gender = " + $global:Opponent_Gender);

         [Int] $global:Opponent_Health = Get-Random -Minimum $Min_Health -Maximum ($Max_Health + 1);
         Write("Health = " + $global:Opponent_Health);

         [Int] $global:Opponent_Defense = Get-Random -Minimum $Min_Defense -Maximum ($Max_Defense + 1);
         Write("Defense = " + $global:Opponent_Defense);

         [Int] $global:Opponent_Attack = Get-Random -Minimum $Min_Attack -Maximum ($Max_Attack + 1);
         Write("Attack = " + $global:Opponent_Attack);

         Write("`nA new Opponent is born!")
}

<# --------------------------------------------------------------------------------- #>

function Display_Opponent
{
         Write("`n---------Opponent Stats----------");
         Write("Name: " + $global:Opponent_Name);
         Write("Species: " + $global:Opponent_Species);
         Write("Gender: " + $global:Opponent_Gender);
         Write("Health: " + $global:Opponent_Health);
         Write("Defense: " + $global:Opponent_Defense);
         Write("Attack: " + $global:Opponent_Attack);
         Write("------------------------------------");
}

<# --------------------------------------------------------------------------------- #>

function Pokemon_Tournament
{
         Clear;

         $MinDammage = 5;
         $MaxDammage = 30;
         $PlayersTurn = $false;
         Write("`nInitiating Pokémon Tournament ...`n");

         Write($global:Pokemon_Name + " vs. " + $global:Opponent_Name + "!");
        
         Display_Pokemon;
         Display_Opponent;

         #Fight until pokmon or opponent loses

         Write("`nRolling for who gets first attack ...");

         [Int] $CHANCE = Get-Random -Minimum 1 -Maximum (2 + 1);

         switch($CHANCE)
         {
            1 { $PlayersTurn = $true; Write("`nPlayer gets 1st attack!");}
            2 { $PlayersTurn = $false; Write("`nOpponent gets 1st attack!"); }
         }

         while($global:Pokemon_Health -GT 0 -AND $global:Opponent_Health -GT 0)
         {
             if($PlayersTurn)
             {
                 if($global:Pokemon_Health -GT 0)
                 {
                     Write("`n" + $global:Pokemon_Name + " attacks " + $global:Opponent_Name + "!");

                     $Dammage = Get-Random -Minimum $MinDammage -Maximum ($MaxDammage + 1);

                     Write($global:Pokemon_Name + " generates " + $Dammage + " dammage.");
                     Write("Attack skills add " + $global:Pokemon_Attack + " dammage.");
                     $Dammage = $Dammage + $global:Pokemon_Attack;

                     Write("Total dammage generated = " + $Dammage);

                     Write($global:Opponent_Name + " defends subtracting " + 
                           $global:Opponent_Defense + " from dammage.");

                     $Dammage = $Dammage - $global:Opponent_Defense;

                     Write("After attack " + $global:Pokemon_Name + " does " + 
                            $Dammage + " total dammage to " + $global:Opponent_Name);

                     if($global:Opponent_Health - $Dammage -GE 0)
                     {
                        $global:Opponent_Health = $global:Opponent_Health - $Dammage;
                     }
                     else
                     {
                         $global:Opponent_Health = 0;
                     }
                     

                     $PlayersTurn = $false;
                 }
                 else
                 {
                     Write($global:Pokemon_Name + " cannot attack on account of being DEAD.");
                 }
             }
             else
             {
                 if($global:Opponent_Health -GT 0)
                 {
                     Write("`n" + $global:Opponent_Name + " attacks " + $global:Pokemon_Name + "!");

                     $Dammage = Get-Random -Minimum $MinDammage -Maximum ($MaxDammage + 1);

                     Write($global:Opponent_Name + " generates " + $Dammage + " dammage.");
                     Write("Attack skills add " + $global:Opponent_Attack + " dammage.");
                     $Dammage = $Dammage + $global:Opponent_Attack;

                     Write("Total dammage generated = " + $Dammage);

                     Write($global:Pokemon_Name + " defends subtracting " + 
                           $global:Pokemon_Defense + " from dammage.");

                     $Dammage = $Dammage - $global:Pokemon_Defense;

                     Write("After attack " + $global:Opponent_Name + " does " + 
                            $Dammage + " total dammage to " + $global:Pokemon_Name);

                     if($global:Pokemon_Health - $Dammage -GE 0)
                     {
                        $global:Pokemon_Health = $global:Pokemon_Health - $Dammage;
                     }
                     else
                     {
                        $global:Pokemon_Health = 0;
                     }

                     $PlayersTurn = $true;
                 }
                 else
                 {
                   Write($global:Opponent_Name + " was terminated with extreme prejudice.");
                 }
             }

             Write("`n$global:Pokemon_Name HEALTH = " + $global:Pokemon_Health);
             Write("$global:Opponent_Name HEALTH = " + $global:Opponent_Health);

             Start-Sleep -s 4;
         }

         if($global:Pokemon_Health -GT 0)
         {
             Write("`n" + $global:Pokemon_Name + " wins the tournament!");
         }
         else
         {
             Write("`n" + $global:Opponent_Name + " wins the tournament.");
         }
}

#------- INVOCATIONS -----------
Main;

# Call the Menu again
invoke-expression -Command "$basePath\HO_ToolBox_Menu.ps1"

 