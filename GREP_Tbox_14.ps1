                                                                                                                                                          <#
                                                   - oo00oo -  
                                              
                                                    R e g E x        
                                              
                                               M A C H I N E  R O O M  
                                               
                                               (Qualified staff only) 
                                                                                                                                                 #>
 


# 14. Regular Expressions


  # Regular expressions (regex) are patterns used for matching strings and manipulating text based on specific criteria. 
  # They are useful for searching, validating, and extracting information from text.
  # Patterns used to match character combinations in strings. Regular expressions are useful for string manipulation, validation, and searching.
  # PowerShell supports regular expressions through the -match, -replace, and -split operators.

       $text = "Hello123"
       if ($text -match "\d") {
           Write-Host "The string contains a number."
       }

       $text = "The quick brown fox jumps over the lazy dog."
       if ($text -match "quick") {
           Write-Host "The text contains 'quick'."  # Outputs: The text contains 'quick'.
       }
       
       # Extracting words that start with 'b'
       $matches = [regex]::Matches($text, "\b\w*b\w*\b")
       foreach ($match in $matches) {
           Write-Host $match.Value  # Outputs: brown
       }


<###################################### >>> Additional referrals <<< ###############################

Start-Process "https:/books.goalkicker.com/PowerShellBook/PowerShellNotesForProfessionals.pdf"            Chapter32: Regular Expressions   
  
<###################################################################################################        

Regular Expression (Regex): A regular expression is a sequence of characters that forms a search pattern.
It can be used for pattern matching within strings.

Components of a Regex Pattern:

Literal Characters: Characters that match themselves. For example, the regex abc will match the string "abc" in any text.

   Metacharacters: Characters that have a special meaning and are not used as literal characters. Some common metacharacters include:
        . (dot): Matches any character except a newline.
        *: Matches 0 or more occurrences of the preceding character.
        +: Matches 1 or more occurrences of the preceding character.
        ?: Matches 0 or 1 occurrence of the preceding character.
        ^: Anchors the regex at the beginning of the line.
        $: Anchors the regex at the end of the line.
        []: Defines a character class; matches any single character within the brackets.
        |: Acts like a logical OR; matches either the pattern on its left or the pattern on its right.

    Quantifiers: Specify the number of occurrences of a character or group.
        {n}: Matches exactly n occurrences.
        {n,}: Matches n or more occurrences.
        {n,m}: Matches between n and m occurrences.
 
Regex Examples:

Match Email Addresses: 
^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]\$

Match Dates (MM/DD/YYYY format):
^(0[1-9]|1[0-2])/(0[1-9]|[12][0-9]|3[01])/(19|20)\d{2}$

Match IP Addresses:
^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$

Match Words Starting with "Hello":
^Hello\w*

Match a Hexadecimal Color Code:
^#(?:[0-9a-fA-F]{3}){1,2}$

#"^$script:Table-\d+" ===>> table-0,1 eller 2
###################################################################################################>

# Call the Menu again
invoke-expression -Command "$basePath\HO_ToolBox_Menu.ps1"