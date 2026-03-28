                                                                                                                                                              <#
                                                     - oo00oo -  
                                                
                                                     A r r a y s        
                                                
                                                 M A C H I N E  R O O M  
                                                 
                                                 (Qualified staff only)   
                                                                                                                                                                                                           #> 


# 5. ARRAYS    


  # Stores multiple values in a single variable.
  # Accessed using index numbers.

       # Example:
       $colors = "Red", "Green", "Blue"
       Write-Host $colors[0]  # Output: Red

 
<###################################### >>> Additional referrals <<< ###############################

Start-Process "https:/powershellbyexample.dev/"                                                           Arrays                                               
Start-Process "https:/powershellbyexample.dev/"                                                           Multidimensional Arrays   
Start-Process "https:/www.codecademy.com/resources/docs/powershell/arrays"          
  
###################################################################################################>  

#Title: PowerShell Arrays                                                                      
#Author: Carly S. Germany
#Date: 06/08/2020


$lines = @(1,"2",3,(get-date))
$path = "$basePath\Myfile.txt"
$lines | Out-File -FilePath $path

$data[0,2,3]
$data | ForEach-Object {"Item: [$PSItem]"}
     
$data = @(
       [pscustomobject]@{FirstName='Kevin';LastName='Marquette'}
       [pscustomobject]@{FirstName='John'; LastName='Doe'}
   )
$data[0].FirstName

$data = @(1,2,3,4)
$data -join '-'

$data -contains '2'

[int[]] $numbers = 1,2,3

$myarray = [System.Collections.ArrayList]::new()  # .net framework arraylist
[void]$myArray.Add('Value')

$bucket1 = [System.Collections.ArrayList]@(1,2,3,4,5)  

function One_Dimensional_Array_ForEach
{
         $MLP_Main_Characters = @("Twilight Sparkle",
                                  "Fluttershy"
                                  "Rainbow Dash",
                                  "Rarity",
                                  "Apple Jack",
                                  "Pinkie Pie");

         $PonyCounter = 0;
         Write-Host("`n`n");
         Write-Host("Number of ELEMENTS in array = " + $MLP_Main_Characters.Count + ".");
         Write-Host("");

         ForEach($PONY in $MLP_Main_Characters)
         {
             $PonyCounter++;
             Write-Host("Pony " + $PonyCounter + " is " + $PONY + ".");
         }
}

###################################################################################################

function One_Dimensional_Array_For
{
         $MLP_Main_Characters = @("Twilight Sparkle",
                                  "Fluttershy"
                                  "Rainbow Dash",
                                  "Rarity",
                                  "Apple Jack",
                                  "Pinkie Pie");

         Write-Host("`n`n");
         Write-Host("Number of ELEMENTS in array = " + $MLP_Main_Characters.Count + ".");
         Write-Host("");

         for($x = 0; $x -LT $MLP_Main_Characters.Count; $x++)
         {
             Write-Host("Pony " + ($x+1) + " is " + $MLP_Main_Characters[$x] + ".");
         }
}

###################################################################################################

function Empty_Array_Of_Fixed_Size
{
         $Number_of_Cylons = 5;
         $Final_Five = New-Object String[] $Number_of_Cylons;

         Write-Host("`n`n");
         Write-Host("Number of ELEMENTS in array Final_Five = " + $Final_Five.Count + ".");
         Write-Host("");

         #Populate Fixed Empty Array With CYLON Identities
         $Final_Five[0] = "Saul Tigh";
         $Final_Five[1] = "Ellen Tigh";
         $Final_Five[2] = "Samuel Anders";
         $Final_Five[3] = "Galen Tyrol";
         $Final_Five[4] = "Tory Foster";

         #REVEAL the Final Five Cylons
         for($y = 0; $y -LT $Final_Five.Count; $y++)
         {
             Write-Host("   Cylon " + ($y+1) + " is `"" + $Final_Five[$y] + "`".");
         }
}

###################################################################################################

function Dynamic_Empty_Array_Of_Undetermined_Size
{
         $Babylon5_Main_Chars = @();

         Write-Host("`n`n");
         Write-Host("BEFORE: Number of ELEMENTS in array Babylon5_Main_Chars = " + $Babylon5_Main_Chars.Count + ".");

         #Add Babylon5 Charactesr to Empty Array
         $Babylon5_Main_Chars += "Satai Delenn";
         $Babylon5_Main_Chars += "John Sheridan";
         $Babylon5_Main_Chars += "Vorlon Ambassador Kosh";
         $Babylon5_Main_Chars += "Vir Cotto";
         $Babylon5_Main_Chars += "Susan Ivanova";
         $Babylon5_Main_Chars += "Talia Winters";
         $Babylon5_Main_Chars += "Michael Garibaldi";
         $Babylon5_Main_Chars += "Lennier";
         $Babylon5_Main_Chars += "G'Kar";
         $Babylon5_Main_Chars += "Londo Mollari";

         Write-Host("AFTER: Number of ELEMENTS in array Babylon5_Main_Chars = " + $Babylon5_Main_Chars.Count + ".");
         Write-Host("");

         #REVEAL the Final Five Cylons
         for($x = 0; $x -LT $Babylon5_Main_Chars.Count; $x++)
         {
             Write-Host("   Babylon 5 character " + ($x+1) + " is `"" + $Babylon5_Main_Chars[$x] + "`".");
         }
}

###################################################################################################

function One_Dimensional_Parallel_Array
{
         $MLP_Char_Names = @("Twilight Sparkle",
                             "Fluttershy"
                             "Rainbow Dash",
                             "Rarity",
                             "Apple Jack",
                             "Pinkie Pie");

         $MLP_Char_Ages = @("15","17","12","14","19","16");

         Write-Host("`n`n");
         Write-Host("Number of ELEMENTS in array MLP_Char_Names = " + $MLP_Char_Names.Count + ".");
         Write-Host("Number of ELEMENTS in array MLP_Char_Ages = " + $MLP_Char_Ages.Count + ".");
         Write-Host("");

         for($x = 0; $x -LT $MLP_Char_Names.Count; $x++)
         {
             Write-Host("-----------------------------------------");
             Write-Host("Pony # " + ($x+1) + "");
             Write-Host("Name: " + $MLP_Char_Names[$x] + "");
             Write-Host("Age: " + $MLP_Char_Ages[$x] + "");
         }

         Write-Host("-----------------------------------------");
}

###################################################################################################

function Two_Dimensional_Array_1
{
         #2-D Array, 6 rows with 2 columns
         $MLP_Characters = @( ("Twilight Sparkle","15"),
                              ("Fluttershy","17"),
                              ("Rainbow Dash","12"),
                              ("Rarity","14"),
                              ("Apple Jack","19"),
                              ("Pinkie Pie","16")  );

         Write-Host("`n`n");
         Write-Host("Number of ELEMENTS in parallel array MLP_Characters = " + $MLP_Characters.Count + ".");
         Write-Host("Number of ROWs = " + $MLP_Characters.Count); #Note: Rows = same as # elements in this case
         Write-Host("Number of COLUMNS = " + $MLP_Characters[0].Count);
        
         Write-Host("");
         
         for($x = 0; $x -LT $MLP_Characters.Count; $x++)
         {
             Write-Host("-----------------------------------------");
             Write-Host("Pony # " + ($x+1) + "");
             Write-Host("Name: " + $MLP_Characters[$x][0] + "");
             Write-Host("Age: " + $MLP_Characters[$x][1] + "");
         }

         Write-Host("-----------------------------------------");
         
}

###################################################################################################

function Two_Dimensional_Array_2_New_Object
{
         # Note: When you create an array with "New-Object"?
         # It CHANGES the way you access the INDEX/subscript values of the array.
         # Also, you can use the method GetUpperBound() to get the last index value in 
         # a particular dimension of that array. So just add 1 to get # elements for that
         # dimension to offset the fencepost/off-by-one issue.

         #2-D array with 64 elements (8 rows by 8 columns)
         $ChessBoard = New-Object 'object[,]' 8,8; 
 
         Write-Host("`nTotal # elements in ChessBoard array = " + $ChessBoard.Count);
         Write-Host("Total X row elements in ChessBoard array = " + ($ChessBoard.GetUpperBound(0)+1));
         Write-Host("Total Y col elements in ChessBoard array = " + ($ChessBoard.GetUpperBound(1)+1));

              #Consume more memory
              for($x = 0; $x -LT ($ChessBoard.GetUpperBound(0)+1); $x++)
              {
                  for($y = 0; $y -LT ($ChessBoard.GetUpperBound(1)+1); $y++)
                  {
                      $ChessBoard[$x,$y] = "  `"" + ($x+1) + "," + ($y+1) + "`"";
                  }
              }

              Write("`n");
               
              # Create display output values to tax resources
              for($x = 0; $x -LT ($ChessBoard.GetUpperBound(0)+1); $x++)
              {
                  for($y = 0; $y -LT ($ChessBoard.GetUpperBound(1)+1); $y++)
                  {
                      Write-Host("$x,$y element value = " + $ChessBoard[$x,$y]);
                  }
              }
}

###################################################################################################


class UNICORN
{
      [String] $Name = "Anonymous Unicorn";
      [Int] $Age = 16;

      Unicorn() 
      { Write-Host("Instantiating a UNICORN object."); }
}

###################################################################################################

function An_Array_Of_Programmer_Defined_Objects_1
{
         Write-Host("`n`n"); 

         $HERD = @();

         $U1 = New-Object Unicorn;
         $U1.Name = "Twilight Sparkle";
         $HERD += $U1;

         $U2 = New-Object Unicorn;
         $U2.Name = "Rarity";
         $HERD += $U2;

         $U3 = New-Object Unicorn;
         $U3.Name = "Princess Celestia";
         $HERD += $U3;

         Write-Host("");

         for($x = 0; $x -LT $HERD.Count; $x++)
         {
             Write-Host("   Unicorn " + ($x+1) + " = " + $HERD[$x].Name);
         }
}

###################################################################################################

class Klingon_Bird_of_Prey
{
      [String] $FleetDesignation = "Anonymous Kahless";
      [Int] $Disruptors = 12;
      [Int] $QuantumTorpedos = 100;

      Klingon_Bird_of_Prey() 
      { Write-Host("Instantiating a Klingon_Bird_of_Prey object."); }      
}

###################################################################################################

function An_Array_Of_Programmer_Defined_Objects_2
{
         Write-Host("`n`n"); 
         
         $KlingongBattleFleet = @();

         $KBP1 = New-Object Klingon_Bird_of_Prey;
         $KBP1.FleetDesignation = "Kahless 1";
         $KlingongBattleFleet += $KBP1;

         $KBP2 = New-Object Klingon_Bird_of_Prey;
         $KBP2.FleetDesignation = "Kahless 2";
         $KlingongBattleFleet += $KBP2;

         $KBP3 = New-Object Klingon_Bird_of_Prey;
         $KBP3.FleetDesignation = "Kahless 3";
         $KlingongBattleFleet += $KBP3;

         Write-Host("");

         for($y = 0; $y -LT $KlingongBattleFleet.Count; $y++)
         {
             Write-Host("   Bird of Prey " + ($y+1) + " = " + $KlingongBattleFleet[$y].FleetDesignation);
         }
}

###################################################################################################

function Fixed_Array_Of_Programmer_Defined_Objects_1
{
         $HERD = New-Object UNICORN[] 3;

         Write-Host("`nNumber of elements in HERD = " + $HERD.Count);

         Write("`nBUILDING the UNICORN objects and POPULATING the Array.`n");

         for($z = 0; $z -LT $HERD.Count; $z++)
         {
              $HERD[$z] = New-Object UNICORN;
              $HERD[$z].Name = "Unicorn " + ($z+1) + "";
         }

         Write("`nRetrieving the UNICORN objects.`n");

         for($z = 0; $z -LT $HERD.Count; $z++)
         {
              Write-Host("   " + ($z+1) + " = " + $HERD[$z].Name + "");
         }
}

###################################################################################################

function Fixed_Array_Of_Programmer_Defined_Objects_2
{
         $KlingongBattleFleet = New-Object Klingon_Bird_of_Prey[] 3;

         Write-Host("`nNumber of elements in KlingongBattleFleet = " + $KlingongBattleFleet.Count);

         Write("`nBUILDING the Klingon_Bird_of_Prey objects and POPULATING the Array.`n");

         for($z = 0; $z -LT $KlingongBattleFleet.Count; $z++)
         {
              $KlingongBattleFleet[$z] = New-Object Klingon_Bird_of_Prey;
              $KlingongBattleFleet[$z].FleetDesignation = "Kahless " + ($z+1) + "";
         }

         Write("`nRetrieving the Klingon_Bird_of_Prey objects.`n");

         for($z = 0; $z -LT $KlingongBattleFleet.Count; $z++)
         {
              Write-Host("   " + ($z+1) + " = " + $KlingongBattleFleet[$z].FleetDesignation + "");
         }
}

<###################################################################################################
---------------Invocations---------------
One_Dimensional_Array_ForEach;
One_Dimensional_Array_For;
Empty_Array_Of_Fixed_Size;
Dynamic_Empty_Array_Of_Undetermined_Size;
One_Dimensional_Parallel_Array;
Two_Dimensional_Array_1;
Two_Dimensional_Array_2_New_Object;
An_Array_Of_Programmer_Defined_Objects_1;
An_Array_Of_Programmer_Defined_Objects_2;
Fixed_Array_Of_Programmer_Defined_Objects_1;
Fixed_Array_Of_Programmer_Defined_Objects_2;
##################################################################################################>

#Title: PowerShell  Arrays - Paralell Arrays
#Author: Carly S. Germany
#Date: 06/14/2020

#Globals
$global:The_Story;

###################################################################################################
# The_Story 
###################################################################################################

function MAIN
{
         Clear;
         Write("`n`nMADLIB 1.0 - Using Paralell Arrays`n`n");
         $null = Read-Host("Press ENTER to continue.");

         $choice = "";

         while($choice[0] -NE 'q')
         {
             Clear;

             Write("`nChoose an example to run:`n`n" +
                   "-----------------------`n" +
                   "|                     |`n" +
                   "|   (C)reate Story    |`n" +
                   "|   (R)ead Story      |`n" +
                   "|   (S)ave Story      |`n" +
                   "|   (L)oad Story      |`n" +
                   "|   (Q)uit            |`n" +
                   "|                     |`n" + 
                   "-----------------------" );

             $choice = (Read-Host("`nCHOICE?")).ToLower();

             switch($choice[0])
             {
                 'c' { Create_Story; }
                 'r' { Read_Story; }
                 's' { Save_Story; }
                 'l' { Load_Story; }
                 'q' { break; }
                 default { $null = Read-Host("`nInvalid choice. Press ENTER to continue."); }
             }           
         }         

        Write("`nExiting Array QUIZ 1.0 ...");
}

###################################################################################################

#Example of PARALLEL ARRAYS
function Create_Story
{
         $MESSAGE = "";

         $PlayerSays = @("***","***","***","***","***","***","***");

         $Criteria = @("Female person's name",
		    	       "An object",
			           "An infinitive verb",
    				   "An object or animal",
	    			   "An object",
		    		   "An object",
			    	   "Male person's name");

         $ComputerSays = @("One day, ", 
                           " was tip-toing through the tulips`nwhen she saw a ",
                           ".  This was because the folks`nat Microsoft were ",
                           " into the sky again and`nagain. Her ",
                           " jumped off of a cliff because`nthe ",
                           " could not pat its head and rub its`ntummy at the same time. The ",
                           " ran off`nholding hands with ");

         Clear;
         Write("`nLet's create the story.`n");
     
         #Get player's thoughts 
         for($x = 0; $x -LT $Criteria.Count; $x++)
         {
              $PlayerSays[$x] = Read-Host($Criteria[$x]);
         }

         #Concatenate everything together into a story String
         for($x = 0; $x -LT $ComputerSays.Count; $x++)
         {
             $MESSAGE = $MESSAGE + $ComputerSays[$x] + $PlayerSays[$x];        
         }

         $MESSAGE = $MESSAGE + ".`n`n`n            The End";

         #Store result in global to be accessed by other functions
         $global:The_Story = $MESSAGE;

         $null = Read-Host -Prompt "`nPress ENTER to continue.";
}

###################################################################################################

function Read_Story
{
         Clear;
         Write("`n`nThe story so far:`n`n");
         Write($global:The_Story);
         $null = Read-Host("`n`nPress ENTER to continue.");
}

###################################################################################################

function Save_Story
{
         Clear;
         Write("`nSAVE story to file.`n`n");

         $CurrentDIRLocation = Split-Path $script:MyInvocation.MyCommand.Path;
         $TextFileName = "\My_Story.txt";
         $TextOutput = $CurrentDIRLocation + $TextFileName;

         Write-Host("Saving story to: " + $TextOutput);
         $global:The_Story | Out-File $TextOutput;

         $null = Read-Host("`n`nPress ENTER to continue.");
}

###################################################################################################

function Load_Story
{
         Clear;
         Write("`nREAD story from file.`n`n");

         $CurrentDIRLocation = Split-Path $script:MyInvocation.MyCommand.Path;
         $TextFileName = "\My_Story.txt";
         $TextInput = $CurrentDIRLocation + $TextFileName;

         Write-Host("Loading story from: " + $TextInput);
         #$global:The_Story | Out-File $TextOutput;

         $global:The_Story = Get-Content $TextInput;

         $null = Read-Host("`n`nPress ENTER to continue.");
}

###################################################################################################


#------- Invocations -------
MAIN;

<####################################################################################################
One day, Jennifer was tip-toing through the tulips
when she saw a Freight Train.  This was because the folks
at Microsoft were eating into the sky again and
again. Her Cat jumped off of a cliff because
the Swimming Pool could not pat its head and rub its
tummy at the same time. The Toothbrush ran off
holding hands with George.
####################################################################################################> 

#Title: PowerShell Arrays - Tic Tac Toe
#Author: Carly S. Germany
#Date: 06/08/2020 

###################################################################################################

$global:EASY = $false;

function MAIN
{
         $GameBoard = @(' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ');
         $SQUARES = 9;
         $PlayerPiece = "";
         $ComputerPiece = "";
         $CurrentPlayer = "";

         #Start game and get player's choice to go first or last.
         $PlayerPiece = Introduction;

         #Whatever player chooses, 'X' or 'O'? The computer gets the other.    
         if($PlayerPiece -EQ "X")  
         { $ComputerPiece = "O"; }
         else 
         { $ComputerPiece = "X"; }
    
         $CurrentPlayer = "X";
         
         Display -BOARD $GameBoard;

         while((CheckForAWinner -BOARD $GameBoard -SQUARES $SQUARES) -EQ 'N')
         {
             Write("CurrentPlayer = " + $CurrentPlayer);

             if($CurrentPlayer -EQ $PlayerPiece)
             {
                 Write("Player's move.");
                 $CHOICE = PlayerPlays -BOARD $GameBoard -SQUARES $SQUARES -PlayerP $PlayerPiece;
                 $N = $CHOICE[1] -as [int]; #Note: Have to shave off xtra from Read-Host
                 $GameBoard[$N] = $PlayerPiece;
             }
             else
             {   
                 Write("Computer's move.");
                 $CHOICE = ComputerPlays -BOARD $GameBoard -SQUARES $SQUARES -PlayerP $PlayerPiece -ComputerP $ComputerPiece;
                 $N = $CHOICE -as [int];
                 $GameBoard[$N] = $ComputerPiece;
             }

             Display -BOARD $GameBoard;
        
             if($CurrentPlayer -EQ $PlayerPiece)
             { $CurrentPlayer = $ComputerPiece; }
             else
             { $CurrentPlayer = $PlayerPiece; }
               
         }  
         
         DisplayWinner -TheWinner (CheckForAWinner -BOARD $GameBoard -SQUARES $SQUARES) -ComputerP $ComputerPiece -PlayerP $PlayerPiece;

         Write("`n`nGame Over");
         Write("Exiting Tic Tac Toe 1.0`n`n");
         
}

###################################################################################################

function Introduction
{
         $FirstOrSecond = "";
         $intelligence = "";
         $PlayerPiece = "z";

         Clear;
         
         Write-Host("`n                   Welcome to Tic Tac Toe 1.0.`n");
         Write-Host("This game uses very simple A.I. in the form of several decision structures.");
         Write-Host("To play, enter a number, 0 - 8.  The number you enter will");
         Write-Host("indicate which of 9 positions you desire below:`n`n");
    
         Write-Host("                 0 | 1 | 2`n");
         Write-Host("                 ---------`n");
         Write-Host("                 3 | 4 | 5`n");
         Write-Host("                 ---------`n");
         Write-Host("                 6 | 7 | 8`n`n");

         Write-Host("The computer will play as your oponent in this game.`n"); 

         

         while($intelligence -NE "i" -AND $intelligence -NE "s")
         {
            Write-Host("`tDo you want your computer opponent to be (i)ntelligent or (s)imple?`n" +
                  "`tChoosing this option for your opponent sets the difficulty of the game.`n");

            $intelligence = (Read-Host("CHOICE")).ToLower();
    
            switch($intelligence)
            {
                "i" {
                       Write-Host("`nO.k., your computer opponent will be more dificult to beat.`n"); 
                       $global:EASY = $false;
                       break;
                    }
                        
                "s" { 
                       Write-Host("`nO.k., your computer opponent will be easier to beat.`n"); 
                       $global:EASY = $true;
                       break;
                    }

                default { Write-Host("That is an invalid response.`n`n"); break; }                     
            }

         }

         while($FirstOrSecond -NE "y" -AND $FirstOrSecond -NE "n")
         {
              Write-Host("Do you want to make the first move (y/n)?`n");
              $FirstOrSecond = (Read-Host("CHOICE")).ToLower();
    
              switch($FirstOrSecond)
              {
                 "y" {
                       Write-Host("`nOk, you take the first move.");
                       Write-Host("You are X. Computer is O.");
                       $PlayerPiece = "X";
                       break;
                     }

                 "n"{
                       Write-Host("`nO.k., the computer takes the first move."); 
                       Write-Host("You are O. Computer is X.");
                       $PlayerPiece = "O";
                       break;
                     }

                 default { Write-Host("That is an invalid response.`n`n"); break; }                     
              }
         }

         $null = Read-Host("`nPress ENTER to continue.");
         Clear;
       
         return $PlayerPiece;
}

###################################################################################################


#This function accepts an entire array as an argument
function Display([char[]] $BOARD)
{
         Write-Host("`n");
         Write-Host("`t" + $BOARD[0] + " | " + $BOARD[1] + " | " + $BOARD[2]);
         Write-Host("`t---------");
         Write-Host("`t" + $BOARD[3] + " | " + $BOARD[4] + " | " + $BOARD[5]);
         Write-Host("`t---------");
         Write-Host("`t" + $BOARD[6] + " | " + $BOARD[7] + " | " + $BOARD[8]);
         Write-Host("`n`n");      
}

###################################################################################################>

#This function accepts an entire array as an argument
function CheckForAWinner([char[]] $BOARD,$SQUARES)
{
         #Define all the wining combinations: horizontal + vertical + diagonal
         $WINNING_ROWS = @( (0, 1, 2),
                            (3, 4, 5),
                            (6, 7, 8),
                            (0, 3, 6),
                            (1, 4, 7),
                            (2, 5, 8),
                            (0, 4, 8),
                            (2, 4, 6) );  

         $TOTAL_ROWS = 8; 
    
         #If an row has three values that are the same? We have a winner.
         #We will either return 'X' or 'O' as the winner. Or a TIE and 
         #end the game. Or else we will return 'N' and keep playing the game.
    
         for($row = 0; $row -LT $TOTAL_ROWS; ++$row)
         {
             if ( ($BOARD[$WINNING_ROWS[$row][0]] -NE ' ') -AND 
                  ($BOARD[$WINNING_ROWS[$row][0]] -EQ $BOARD[$WINNING_ROWS[$row][1]]) -AND 
                  ($BOARD[$WINNING_ROWS[$row][1]] -EQ $BOARD[$WINNING_ROWS[$row][2]]) )
             {
                  return $GameBoard[$WINNING_ROWS[$row][0]];
             }
         }           

         #If we don't have a winner? Check for a possible TIE.
         $NoEmptySpaces = $true;
    
         for($x = 0; $x -LT $SQUARES; $x++)
         {
             if($BOARD[$x] -EQ ' ') 
             { $NoEmptySpaces = $false; }
         }

         if($NoEmptySpaces -EQ $true)
         {   return 'T'; }

         #If nobdy wins and it's not a tie return 'N' to keep playing.
         return 'N';
}

###################################################################################################

function LegalMove($Move,$BOARD)
{
         return ($BOARD[$Move] -EQ ' ');
}

###################################################################################################

function PlayerPlays([char[]] $BOARD,$SQUARES,$PlayerP)
{
         Write-Host("`nHuman choosing location: ");

         $PlayersMove;

         while($PlayersMove -GT $SQUARES -OR $PlayersMove -LT 0 -OR 
         ((LegalMove -Move $PlayersMove -BOARD $BOARD) -EQ $false))
         {
             Write-Host("`nChoose a location (0-8): ");
             $PlayersMove = Read-Host("Move");

             if($PlayersMove -GT $SQUARES -OR $PlayersMove -LT 0) 
             { 
                Write-Host("`nThat number is outside of the valid range of 1-8."); 
             }
             elseif((LegalMove -Move $PlayersMove -BOARD $BOARD) -EQ $false) 
             {
                Write-Host("`nYou cannot choose that location. It already has a(n) " +
                           $BOARD)[$PlayersMove] + " in it.`n"; 
             }
         } 

         return $PlayersMove; 
}

###################################################################################################

function ComputerPlays([char[]] $BOARD,$SQUARES,$PlayerP,$ComputerP)
{
         Write-Host -NoNewLine ("`nComputer choosing location: ");

         #1. If computer can win on next choice, then make that choice.
         for($x = 0; $x -LT $SQUARES; ++$x)
         {
             if(LegalMove -Move $x -BOARD $BOARD)
             {
                 $BOARD[$x] = $ComputerP;

                 if((CheckForAWinner -BOARD $BOARD -SQUARES $SQUARES) -EQ $ComputerP)
                 {
                     Write-Host -NoNewLine ("$x" + "`n");
                     return $x;
                 }
                 #Done checking this choice, undo it.
                 $BOARD[$x] = ' ';
             }
         } 

         #Note: Computer will not try to block player's winning move if EASY = true
         if($global:EASY -EQ $false)
         {   
             #2. If human can win on next choice, block that choice.

             for($y = 0; $y -LT $SQUARES; ++$y)
             {
                 if(LegalMove -Move $y -BOARD $BOARD)
                 {
                     $BOARD[$y] = $PlayerP;

                     if((CheckForAWinner -BOARD $BOARD -SQUARES $SQUARES) -EQ $PlayerP)
                     {
                         Write-Host -NoNewLine ("$y" + "`n");
                         return $y;
                     }

                     #done checking this choice, undo it
                     $BOARD[$y] = ' ';
                 } 
             }

             #3. If no one can win on next choice? Pick best open square.
             $PreferredChoices = @(4, 0, 2, 6, 8, 1, 3, 5, 7);

             for($i = 0; $i -LT $SQUARES; ++$i)
             {
                 $choice = $PreferredChoices[$i];

                 if(LegalMove -Move $choice -BOARD $BOARD)
                 {
                     Write-Host -NoNewLine ("$choice" + "`n");
                     return $choice;
                 }
             }
         }
}

###################################################################################################

function DisplayWinner($TheWinner,$ComputerP,$PlayerP)
{
       	if($TheWinner -EQ $ComputerP)
        {
            Write-Host("`n" + $TheWinner + " wins the game.");
            Write-Host("The computer wins this match.");
            Write-Host("Sorry, you loose.`n`n");
        }
	    elseif ($TheWinner -EQ $PlayerP)
        {
            Write-Host("`n" + $TheWinner + " wins the game.");
            Write-Host("Excellent. You win this match.");
            Write-Host("The computer looses.`n`n");
        }
	    else
        {
            Write-Host("`nThe game ends in a tie.");
            Write-Host("Neither you nor the computer wins.`n`n");
	    }         
}

###################################################################################################

#------- Function Invocations -------
MAIN;

# Call the Menu again
invoke-expression -Command "$basePath\HO_ToolBox_Menu.ps1"

 


                                                           