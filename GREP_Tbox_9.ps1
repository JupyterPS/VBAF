                                                                                                                                                            <#
                                                    - oo00oo -  
                                               
                                                   B r a c k e t s        
                                               
                                                M A C H I N E  R O O M  
                                                
                                                (Qualified staff only) 

                                                                                                                                                             #>



# 9. Brackets


  # Brackets are used in PowerShell for various purposes, including defining arrays, hash tables, and grouping expressions.
  # Square brackets ([]) are used for type casting and defining arrays, while curly braces ({}) are used for script blocks and functions.

       # Array
       $array = @(1, 2, 3)
       Write-Host $array[0]
       
       # Hash Table
       $hashTable = @{
           "Key1" = "Value1"
           "Key2" = "Value2"
       }
       
 
###################################################################################################


<#  ------------------- 3 Kinds of brackets -------------------

1. Parenthesis brackets- ()
2. Curly brackets-       {}
3. Square brackets-      []     

1. Parenthesis brackets:
Close multiple statements used in loop, Pass parameter, Assign array value

2. Curly brackets: 
Execute a block of statements, enclose the code

3. Square brackets:
Represent each array item
#>
 

# $Array=@(1,2,3,4)
# $Array[1] = 2 

$arrayItem = @("Laptop", "Mobile", "Tablet")
for($i = 0; $i -lt $arrayItem.length; $i++)
{
$arrayItem[$i]
}

# Call the Menu again
invoke-expression -Command "$basePath\HO_ToolBox_Menu.ps1"