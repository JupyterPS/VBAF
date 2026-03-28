                                                                                                                                                          <#
                                                     - oo00oo -  
                                                
                                                  O p e r a t o r s        
                                                
                                                 M A C H I N E  R O O M  
                                                 
                                                 (Qualified staff only) 
                                                                                                                                                 #>



# 8. Operators



# Jump directly to one of the below topics. Activate (run selected lines - pf8) at top left

. "C:\Users\henni\OneDrive\WindowsPowerShell\GREP_Jump.ps1"  
$Num = 8
Jump-To-GUISectionISE -Num $Num 



  <# Perform operations on variables and values.
   # Common operators include:
       Arithmetic: +, -, *, /, %
       Comparison: -eq, -ne, -gt, -lt, -ge, -le
       Logical: -and, -or, -not              #>

       # Example:
       $result = 10 + 5
       $isGreaterThan = 20 -gt 10
       $logicalResult = $true -and $false                                                           # False because they are not both the same


<###################################### >>> Additional referrals <<< ###############################

Start-Process "https:/books.goalkicker.com/PowerShellBook/PowerShellNotesForProfessionals.pdf"      Chapter3,4 Operators                
Start-Process "https:/www.codecademy.com/resources/docs/powershell/operators"       
  
###################################################################################################>  

# Title: PowerShell Operators and Comparisons                                             
# Author: Carly S. Germany
# Date: 04/29/2020

# Note: Powershell has many operators and comparisons that can be used in expressions and logic evaluations.
# Some of the most basic and useful of these operators is:

<#
# ------------------- Comparison Operators -------------------

---___________ Operators that compare values and conditions --- 
-EQ = equal to (exact match)
-NE = NOT equal to (anything but the target)
-LT = less than the target
-GT = greater than the targt
-LE = less than or equal to
-GE = greater than or equal to 

# ------------------- Arithmetic Operators -------------------
.+ = addition
.- = subtraction
.* = multiplication
./ = division

# ------------------- Assignment Operators -------------------
. =   = assignment operator (takes whats on the left and stores it on the right)
. +=  = add AND assign operator (adds right op to left op and assigns result to left operand)
. -=  = subtract AND assign operator (subtracts right op from left op and assigns result to left operand)
. *=  = multiply AND assign operator (multiplies right op and left op and assigns result to left operand)
. /=  = divide AND assign operator (divides left op by right op and assigns result to left operand)
. %=  = modulus AND assign operator (divides left op by right op and assigns remainder to left operand) 

# ------------------- Logical Operators -------------------
. -and  = logical AND operator (true when BOTH statements are true)
. -or   = logical OR operator  (true when EITHER statement is true)
. -not  = logical NOT operator (reverses logic state)
. -xor  = logical EXCLUSIVE OR operator (true when only one statement is true) 
. !     = same as logical NOT operator

# ------ Like Operators (use regular expressions with wild cards) ------ 
. -LIKE = finds pattern in string WITH wild cards
. -NOTLIKE = negates the -LIKE operator

# -------------------- Match Operators  ------------------------------------- 
. -MATCH = uses regular expressions (regex) to find patters WITHOUT wild cards
. -NOTMATCH = negates the -MATCH operator

# ------ Replace Operator -----------------------------------------
. -REPLACE = replaces one set of charactes with another in a string

# ------------------- Split Operator -------------------
. -split = splits a string based on a delimiter, case sensitive.

# ------------------- Join Operator -------------------
. -join = concatenates/jions two separate strings 

# ---------------- Containment comparison -------------------------------------
. -in          = returns TRUE only when test value EXACT MATCH
. -notin       = negates -in operator
. -contains    = true when reference to 1 item in collection true
. -notcontains = tests for NON-existence of 1 item in a collection

# ------------------- Type comparison ------------------------------------------- 
. -is    = returns true if what is on left is of type of what is on right

# ------------------- Type Operators -------------------
. -is    = returns TRUE when input is instance of specified type
. -isnot = returns TRUE when input is NOT instance of specified type
. -as    = converts input to specified type 


<#  --------------------------------------------------------------- #>

function Example_Comparison_OPS_GT_LT
{
         Write("Is 5 greater than 7?");
         if(5 -GT 7)
         { Write("TRUE. 5 is greater.");  }
         else
         { Write("FALSE. 5 is less."); }

         Write("`n");

         Write("Is 5 less than 7?");
         if(5 -LT 7)
         { Write("TRUE. 5 is less.");  }
         else
         { Write("FALSE. 5 is greater."); }
}

 

function Example_Comparison_OPS_EQ
{
         $a = 10;
         $b = 10;

         Write("Is a equal to b?");
         if($a -EQ $b)
         { Write("TRUE. a equals b.");  }
         else
         { Write("FALSE. a dows not equal b."); }
}

 

function Example_Comparison_OPS_NE
{

         $TESTRESULT = "midichlorians";

         if($TESTRESULT -NE "midichlorians")
         { Write("`nThis child will not become a Jedi."); }
         else
         { 
            Write("`nThe force is STRONG in this one."); 
            Write("Become a JEDI, this child will ..."); 
         } 

}

<#
# ------------------- Arithmetic Operators -------------------

+ = addition
- = subtraction
* = multiplication
/ = division
% = modulus (Divides left-hand operand by right-hand and returns remainder)

#>


function EXAMPLE_Arithmetic_OPS_1
{
         $x = 3 + 5 * 10;
         Write("`n(3 + 5 * 10) x = " + $x + ".");

         $x = 10 - 4 / 2;
         Write("`n(10 - 4 / 2) x = " + $x + ".");

         $x = 13 % 2;
         Write("`n(13 % 2) x = " + $x + ".");

         #Note the order of precedence: * and / before + and -
         #unless changed with ()
}

<#
# -------------------- Assignment Operators -------------------

=   = assignment operator (takes what's on the left and stores it on the right)
+=  = add AND assign operator (adds right op to left op and assigns result to left operand)
-=  = subtract AND assign operator (subtracts right op from left op and assigns result to left operand)
*=  = multiply AND assign operator (multiplies right op and left op and assigns result to left operand)
/=  = divide AND assign operator (divides left op by right op and assigns result to left operand)
%=  = modulus AND assign operator (divides left op by right op and assigns remainder to left operand)

#>


function EXAMPLE_Assignment_OPs_1
{
         Write("`n");

         $PonyAge = 5;

         Write("`nCurrent value of PonyAge is: "+ $PonyAge);
         Write("(OP: =) PonyAge is " + $PonyAge + "."); 
         
         Write("`nCurrent value of PonyAge is: "+ $PonyAge);
         $PonyAge += 5;
         Write("(OP: += 5) PonyAge is now " + $PonyAge + "."); 

         Write("`nCurrent value of PonyAge is: "+ $PonyAge);
         $PonyAge -= 5;
         Write("(OP: -= 5) PonyAge is now " + $PonyAge + "."); 

         Write("`nCurrent value of PonyAge is: "+ $PonyAge);
         $PonyAge *= 5;
         Write("(OP: *= 5) PonyAge is now " + $PonyAge + "."); 

         Write("`nCurrent value of PonyAge is: "+ $PonyAge);
         $PonyAge /= 5;
         Write("(OP: /= 5) PonyAge is now " + $PonyAge + "."); 

         $PonyAge = 13;

         Write("`nCurrent value of PonyAge is: "+ $PonyAge);
         Write("(OP: =) PonyAge is " + $PonyAge + ".");

         Write("`nCurrent value of PonyAge is: "+ $PonyAge);
         $PonyAge %= 5;
         Write("(OP: %= 5) PonyAge is now " + $PonyAge + ".");    
}

<#
# -------------------- Logical Operators -------------------

-and  = logical AND operator (true when BOTH statements are true)
-or   = logical OR operator  (true when EITHER statement is true)
-not  = logical NOT operator (reverses logic state)
-xor  = logical EXCLUSIVE OR operator (true when only one statement is true) 
!     = same as logical NOT operator

#>


function EXAMPLE_Logical_OPS_EQ
{
         #HALO Alpha OPs

         $GroundForce_Covenant = "NOT Present";
         $GroundForce_Banished = "Present";
         $GroundForce_UnitedNationsSpaceCommand = "Present";

         if($GroundForce_Covenant -EQ "Present")
         { Write("Covenant are present in this location."); }
         else
         { Write("Covenant are NOT present in this location.");  }

         if($GroundForce_UnitedNationsSpaceCommand -EQ "Present")
         { Write("UNSC are present in this location."); }
         else
         { Write("UNSC are NOT present in this location.");  }

         if($GroundForce_Banished -NE "Absent")
         { Write("Banished are present in this location."); }
         else
         { Write("Banished are NOT present in this location.");  }         
}


function EXAMPLE_Logical_OPS_AND
{
         #OP is -EQ + -AND, so multiple expressions compared, BOTH have to be true
         #AND-ing things together

         $GroundForce_Covenant = "NOT Present";
         $GroundForce_Banished = "Present";
         $GroundForce_UNSC = "Present";

         if($GroundForce_UNSC -EQ "Present" -AND $GroundForce_Banished -EQ "Present")
         { Write("The FLOOD are defeated."); }
         else
         { Write("The FLOOD escape and eradicate the universe.");  }
         
}


function EXAMPLE_Logical_OPS_OR
{
         #OP is -EQ + -OR, so multiple expressions compared, ONLY ONE has to be true
         #OR-ing things together

         $GroundForce_Covenant = "NOT Present";
         $GroundForce_Banished = "Present";
         $GroundForce_UNSC = "Present";

         if($GroundForce_Covenant -EQ "Present" -OR $GroundForce_Banished -EQ "Present")
         { Write("Covenant race forces have arrived."); }
         else
         { Write("No Covenant race forces are present, banished or otherwise.");  }
         
}


function EXAMPLE_Logical_OPS_NOT
{
         $TESTRESULT = $null;

         if(-NOT $TESTRESULT)
         { Write("`nThis child was not tested."); }
         else
         { Write("`nThis child has been tested."); } 

         $TESTRESULT = "Tested";

         if(-NOT $TESTRESULT)
         { Write("`nThis child was not tested."); }
         else
         { Write("`nThis child has already been tested."); } 


         $TESTRESULT = $null;

         if(! $TESTRESULT)
         { Write("`nThis child was not tested."); }
         else
         { Write("`nThis child has already been tested."); } 
}

<#
# ------- Like Operators (use regular expressions with wild cards) ------

-LIKE = finds pattern in string WITH wild cards
-NOTLIKE = negates the -LIKE operator

#>

  
function EXAMPLE_LIKE
{
         $TARGET = "Are Cylons alive? Ask the final five.";

         if($TARGET -LIKE "*five*")
         { Write("`nFound the final five. Cylons are alive!"); }
         else
         { Write("`nYou or your mother might be a frackin' TOASTER."); }
}

<#
# ------- Match Operators  ------------------------------------- 

-MATCH = uses regular expressions (regex) to find patters WITHOUT wild cards
-NOTMATCH = negates the -MATCH operator

#>


function EXAMPLE_MATCH
{
         $TARGET = "Kakashi sensei bought Naruto Ramen Ichiraku";

         if($TARGET -MATCH "Ichi")
         { Write("`nKakashi Hatake really DID buy Naruto ramen at Ichiraku's."); }
         else
         { Write("`nNaruto was a BAD shinobi. He gets no ramen."); }
}

<#
# ------- Replace Operator -----------------------------------------

-REPLACE = replaces one set of charactes with another in a string

#>


function EXAMPLE_REPLACE_1
{
         $TARGET = "Naruto and the Nine Tailed Fox will become shinobi someday.";
         Write("`nBEFORE calling -replace: " + $TARGET);
         $TARGET = $TARGET -replace("shinobi","Hokage");
         Write("`nAFTER calling -replace: " + $TARGET);
}


function EXAMPLE_REPLACE_2
{
         $TARGET = "I will take the RED PILL or I will take the BLUE PILL.";
         Write("`nBEFORE calling -replace: " + $TARGET);
         $TARGET = $TARGET -replace(" or I will take the BLUE PILL.",". ");
         Write("`nAFTER calling -replace: " + $TARGET);
}


<#
# -------------------- Split Operator -------------------

-split = splits a string based on a delimiter, case sensitive.

#>

<#  --------------------------------------------------------------- #>


function EXAMPLE_SPLIT_DELIMITER_OMITTED_1
{
         $RESULT = "PonyName = Fluttershy:PonyType = Pegasus:PonyLocation = Equestria";
         $RESULT = $RESULT -split ":";
         Write($RESULT);
}


function EXAMPLE_SPLIT_DELIMITER_INCLUDED_2
{
         $RESULT = "PonyName = Fluttershy:PonyType = Pegasus:PonyLocation = Equestria";
         $RESULT = $RESULT  -split "(:)";
         Write($RESULT);  
}


function EXAMPLE_SPLIT_SPECIFY_NUM_STRINGS_3
{
         $RESULT = "Pony-Pegasus-Unicorn-Alicorn-Pegasus-Unicorn";
         $RESULT = $RESULT -split '(-)',4;
         Write($RESULT);
}


function EXAMPLE_SPLIT_ARRAY_ELEMENTS
{
         $RESULT = "PonyName = Fluttershy:PonyType = Pegasus:PonyLocation = Equestria";
         $RESULT = $RESULT -split ":";
         Write($RESULT);

         Write("`nNumber of elements in RESULT: " + $RESULT.Count);

         for($x = 0; $x -LT $RESULT.Count; $x++)
         {
             Write("String " + ($x+1) + " = " + $RESULT[$x] + "");
         }
}

#Note: If you submit an array of strings, the max-substring limit is applied to each string separately.

<#
# -------------------- Join Operator -------------------

-join = concatenates/jions two separate strings

#>


function EXAMPLE_JOIN_STRINGS
{
         $RESULT = -join ("Fluttershy:","TwilightSparkle:","RainbowDash:","Rarity:","AppleJack:","PinkiePie");
         Write  $RESULT 
}


function EXAMPLE_JOIN_STRINGS_WITH_DELIMITER
{
         $RESULT = "Fluttershy", "TwilightSparkle", "RainbowDash", "Rarity", "AppleJack", "PinkiePie" -join " ";
         Write("`n" + $RESULT);
}

<#
# ------- Containment comparison -------------------------------------

-in          = returns TRUE only when test value EXACT MATCH
-notin       = negates -in operator
-contains    = true when reference to 1 item in collection true
-notcontains = tests for NON-existence of 1 item in a collection

#>


function EXAMPLE_IN
{
         Write("`nIs Kuill in The Mandalorian?");

         if("Kuiil" -IN "Kuiil", "The Mandalorian")
         { Write("Yes he was! EXACT match."); }
         else
         { Write("No he wasn't. Not EXACT match."); }

         Write("`nIs Kuill in The Mandalorian?");

         if("Kuiil" -IN "Kuiil is a father figure", "The Mandalorian")
         { Write("Yes he was! EXACT match."); }
         else
         { Write("No he wasn't. Not EXACT match."); }
}


function EXAMPLE_CONTAINS
{
         Write("`nIs Cara Dune now a member of Greef Karga's Bounty Hunters' Guild?");

         if("Cara Dune", " is a member of Greef's Hunters" -CONTAINS "Cara Dune")
         { Write("Yes she was! EXACT match."); }
         else
         { Write("No she wasn't. Not EXACT match."); }

         Write("`nIs Cara Dune now a member of Greef Karga's Bounty Hunters' Guild?");

         if("Cara Dune is a member of Greef's Hunters" -CONTAINS "Cara Dune")
         { Write("Yes she was! EXACT match."); }
         else
         { Write("No she wasn't. Not EXACT match."); }
}


<#
# ------- Type comparison ------------------------------------------- 

-is    = returns true if what is on left is of type of what is on right
-isnot = returns false if what is on left is not of type of what is on right

#>

<#  --------------------------------------------------------------- #>

function EXAMPLE_COMPARISON_IS
{
         $a = 444;
         $b = 3.145678;
         $c = "Carly";

         $a.GetType();
         $b.GetType();
         $c.GetType();

         $TESTER = 444;
         Write("`n------------------------------------------------");
         Write("Setting value of TESTER to: `"" + $TESTER + "`".")
         Write("------------------------------------------------");

         if($TESTER -is [int])
         { Write("`nYes, TESTER is data type INT."); }
         else
         { Write("`nNo, TESTER is not an integer."); }

         if($TESTER -is [double])
         { Write("`nYes, TESTER is data type DOUBLE."); }
         else
         { Write("`nNo, TESTER is not a double."); }

         if($TESTER -is [string])
         { Write("`nYes, TESTER is data type STRING."); }
         else
         { Write("`nNo, TESTER is not a string."); }

         $TESTER = 3.145678;
         Write("`n------------------------------------------------");
         Write("Setting value of TESTER to: `"" + $TESTER + "`".")
         Write("------------------------------------------------");

         if($TESTER -is [int])
         { Write("`nYes, TESTER is data type INT."); }
         else
         { Write("`nNo, TESTER is not an integer."); }

         if($TESTER -is [double])
         { Write("`nYes, TESTER is data type DOUBLE."); }
         else
         { Write("`nNo, TESTER is not a double."); }

         if($TESTER -is [string])
         { Write("`nYes, TESTER is data type STRING."); }
         else
         { Write("`nNo, TESTER is not a string."); }

         $TESTER = "Carly";
         Write("`n------------------------------------------------");
         Write("Setting value of TESTER to: `"" + $TESTER + "`".")
         Write("------------------------------------------------");

         if($TESTER -is [int])
         { Write("`nYes, TESTER is data type INT."); }
         else
         { Write("`nNo, TESTER is not an integer."); }

         if($TESTER -is [double])
         { Write("`nYes, TESTER is data type DOUBLE."); }
         else
         { Write("`nNo, TESTER is not a double."); }

         if($TESTER -is [string])
         { Write("`nYes, TESTER is data type STRING."); }
         else
         { Write("`nNo, TESTER is not a string."); }
}

<#
# -------------------- Redirection Operators -------------------

>    = redirects data stream to a file
>>   = appends data stream to a file
2>&1 = redirects error stream (2) to success stream (1)
3>&1 2>&1 = redirects both warning stream (3) and error stream (2) to success stream (1)

#>


function EXAMPLE_REDIRECT_1
{
         $Data = "Supercalafrajalisticexpealadocious";
         $Data > "C:\DATA\data.txt";
}

function EXAMPLE_REDIRECT_2
{
         &{
             Write-Warning "Curly: Hello!"
             Write-Error "Larry: Hello!"
             Write-Output "Moe: Hello!"
          } 3>&1 2>&1 > C:\DATA\The_Three_Stooges.log 
}


function EXAMPLE_REDIRECT_3
{
         #redirect ALL streams to a file using wildcard
         .\script.ps1 *> script.log
}


function EXAMPLE_REDIRECT_4
{
         # Unexpected logic error
         if (36 > 42) 
         { "true" } 
         else 
         { "false" }

         # Won't evalutate to true or false.
         # Takes the value "36" and redirects it to file called "42".
}

<#
# -------------------- Type Operators -------------------

-is    = returns TRUE when input is instance of specified type
-isnot = returns TRUE when input is NOT instance of specified type
-as    = converts input to specified type

#>


function EXAMPLE_TYPE_OP_IS_1
{
         $AnArray = @("Galactica","Pegasus","Cylon BaseStar"); 
         # $AnArray = 3;

         if($AnArray -is [System.Collections.IList])
         { Write("Yes. An array is part of System.Collections.IList."); }
         else 
         { Write("Nope. Not a system collecions ilist object."); }
}


function EXAMPLE_TYPE_OP_IS_2
{
         Write("`nIs 32 a float?");
         32 -is [Float];
         Write("`nIs 32 an int?");
         32 -is "int";
         Write("`nIs `"12/31/2007`" a [DateTime]?");
         "12/31/2007" -is [DateTime];
         Write("`nIs `"12/31/2007`" a string?");
         "12/31/2007" -is [String];
}


function EXAMPLE_TYPE_OP_AS_1
{
         Write("`nRemember, remember ...")
         "11/05/20" -as [datetime];

         # Converts string to DateTime object
}


function EXAMPLE_TYPE_OP_AS_2
{
         1032 -as [System.Globalization.CultureInfo]
         1031 -as [System.Globalization.CultureInfo]
         1030 -as [System.Globalization.CultureInfo]
         1029 -as [System.Globalization.CultureInfo]
         1028 -as [System.Globalization.CultureInfo]
         1027 -as [System.Globalization.CultureInfo]
         1026 -as [System.Globalization.CultureInfo]
         1025 -as [System.Globalization.CultureInfo]
         1024 -as [System.Globalization.CultureInfo]
         1023 -as [System.Globalization.CultureInfo]
         1022 -as [System.Globalization.CultureInfo]
         1021 -as [System.Globalization.CultureInfo]
         1020 -as [System.Globalization.CultureInfo]
}

<#
# -------------------- Unary Operators -------------------

++ = increment (add 1 to veriable)
-- = decrement (subtract 1 from variable)

Note: These can be either postfix or prefix

#>

<#  --------------------------------------------------------------- #>
function EXAMPLE_Unary
{
         $a = 10;
         $a++;
         Write("`nThe value of a is now " + $a + ".");
}

<#
# -------------------- Special Operators -------------------

() = modify precedence. Whenever placed around part of expression, causes part inside () to be evaluate 1st.
() Can also be used to embed the result of one function within another.
#>


function EXAMPLE_Special_1
{
         (800 + 88) / 2
}


function EXAMPLE_Special_2
{
         Write("Today is " + (Get-Date) );
}

<#
# -------------------- SubExpression Operator -------------------

$() = takes result from method and presents it as a variable

#>


function EXAMPLE_SubExpression_1
{
         Write("Today is $(Get-Date)");
}


function EXAMPLE_SubExpression_2
{
         Write("C: Folders are:`n`n" + $((dir c:\ -dir).Name -join " `n" ));
}

<#
# -------------------- Call Operator -------------------

call operatpr & = call operator, executes command, script block or script

#>


function EXAMPLE_CALL_1
{
         $a = "DIR";
         $b = "Get-ExecutionPolicy"; 
         $c = "Get-Acl"; 
         $d = "Get-NetAdapter";

         & $a;
         & $b;
         & $c;
         & $d;
}


function EXAMPLE_CALL_2
{
         Get-ChildItem
         CD C:\DATA
         & ".\Test.ps1"
}

<#
# -------------------- Background Operator -------------------

background operator & =  runs command asynchronously in subshell as job.
                         placing "&" after a command statement runs it in background

Get-Process -Name pwsh &
Update-Help -Force -Verbose &
Get-ChildItem -Path c:\ -Recurse &

# Equivalent
the-long-running-script.sh &
Start-Process -NoNewWindow the-long-running-script.bat


#>

<#
# ------Job Commandlets----------------------------------------------

Get-Job = gets background jobs running in current session
Receive-Job = gets results of background jobs in current session
Remove-Job = deletes background job
Start-Job = starts background job
Stop-Job = stops background job
Wait-Job = suppresses command prompt until one or all background jobs running in session complete

function bg() 
{Start-Process -NoNewWindow @args}

bg ping google.com

#>

<#
# -------------------- Array SubExpression Operator ------------

@( ) = returns array or 1 or more elements in array

#>

<#
# -------------------- Cast Operator -------------------

[] = cast one data type to another

#>

function EXAMPLE_CAST
{
         Write("`nRead-Host takes input as string. Without a cast? Calculation is wrong.");
         $MyNumber = Read-Host("Please enter a number");
         $MyNumber = $MyNumber * $MyNumber;
         Write("MyNumber squared is: " + $MyNumber);

         Write("`nIf we cast the sting to an int? Calculation is now right.");
         [Int]$MyNumber = Read-Host("Please enter a number");
         $MyNumber = $MyNumber * $MyNumber;
         Write("MyNumber squared is: " + $MyNumber);
}
Example_Comparison_OPS_GT_LT

# Call the Menu again
invoke-expression -Command "$basePath\HO_ToolBox_Menu.ps1"
 