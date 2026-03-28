
# _______________________________________ => T H E  S C R I P T  I N I T I A L I Z A T I O N starts here <= _____________________________________

Using namespace System.Management.Automation.Host 

# Jump directly to one of the below topics. Activate (pf8) and press jump to that line

. "C:\Users\henni\OneDrive\WindowsPowerShell\GREP_Jump.ps1"  
$Num = 21
Jump-To-GUISectionISE -Num $Num 

# Determine the base path dynamically
$pathWin11 = "C:\Users\henni\OneDrive\WindowsPowerShell"
$pathWin10 = "C:\Users\Henning\OneDrive\WindowsPowerShell"

if (Test-Path $pathWin11) {
    $basePath = $pathWin11   
} else {
    $basePath = $pathWin10    
}

# _____________________________________ => The global settings starts here <= ___________________________________________

#Global attributes   
if (-not $script:Initialized) 
{
    # Perform initialization tasks here
    $script:Initialized = $true 

    Write-Host("The billingHash is now on")
    $billingHash = @{}         
    
    if (-not $script:Lastkey)
    {
        Write-Host("The Lastkey is now on")
        $script:Lastkey = @{}
    }                        

    $script:Counter = 1
    $script:Choice  = $null 
    $script:Table   = $null 
    $script:Passed  = $null        
    $script:Hashkey = $null
    $script:displayTable = $null 
    $script:displayWine  = $null

    $myWineGlass  = [WineGlass]::new($anyGlass, 0, 0, 0, 0)     
    $wineCompare0 = [Wine]::new(0, "PrimalSyrah", "SAPIEN Vineyards", 1990, $false, "Red", 1, "Delicious and fruity", 156)
    $wineCompare1 = [Wine]::new(1, "Duck", "Escalante Winery", 2003, $true, "White", 4, "Rich and Magnificient", 122)
    $wineCompare2 = [Wine]::new(2, "PSWine", "Chateau Snover", 2012, $false, "Red", "Dry", "Dark ruby", 220)  
}  

# _____________________________________ => T H E  S C R I P T  G U I starts here <= ___________________________________________

while ($true) { 

Add-Type -AssemblyName System.Windows.Forms
# Create a form
$form = New-Object Windows.Forms.Form
$form.Text = 'E N O T E K'  
$form.Size = New-Object System.Drawing.Size(410,510)
$form.StartPosition = 'CenterScreen'
$form.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Dpi

# Store initial sizes and locations
$initialFormSize = $form.Size
$initialRichTextBoxSize = New-Object System.Drawing.Size(360,360)
$initialRichTextBoxLocation = New-Object System.Drawing.Point(25,40)
$initialOkButtonLocation = New-Object System.Drawing.Point(150,420)
$initialCancelButtonLocation = New-Object System.Drawing.Point(250,420)
$initialLabelLocation = New-Object System.Drawing.Point(10,20)
$initialLabelSize = New-Object System.Drawing.Size(390,20)

# Create a RichTextBox
$richTextBox = New-Object Windows.Forms.RichTextBox
$richTextBox.Location = $initialRichTextBoxLocation
$richTextBox.Size = $initialRichTextBoxSize
$richTextBox.Font = New-Object System.Drawing.Font("Arial", 12)
$richTextBox.WordWrap = $false  # Disable word wrap

# OK Button
$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = $initialOkButtonLocation
$okButton.Size = New-Object System.Drawing.Size(75,23)
$okButton.Text = 'OK'
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $okButton
$form.Controls.Add($okButton)

# Cancel Button
$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Location = $initialCancelButtonLocation
$cancelButton.Size = New-Object System.Drawing.Size(75,23)
$cancelButton.Text = 'Cancel'
$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $cancelButton
$form.Controls.Add($cancelButton)

# Label
$label = New-Object System.Windows.Forms.Label
$label.Location = $initialLabelLocation
$label.Size = $initialLabelSize
$label.Text = '                    Wellcome'
$label.Font = New-Object System.Drawing.Font("Arial", 14)
$form.Controls.Add($label)

# Function to add colored text to RichTextBox
function add-ColoredText {
    param ([String]$text, [System.Drawing.Color]$color)
    $start = $richTextBox.Text.Length
    $richTextBox.AppendText($text)
    $end = $richTextBox.Text.Length
    $richTextBox.Select($start, $end - $start)
    $richTextBox.SelectionColor = $color 
}

# Set the cursor to an arrow
$richTextBox.Cursor = [System.Windows.Forms.Cursors]::Arrow

# MouseMove event handler
$richTextBox.Add_MouseMove({
    param($sender, $e)
    if (-not $richTextBox.ClientRectangle.Contains($e.Location)) {
        $richTextBox.Capture = $false
    } elseif (-not $richTextBox.Capture) {
        $richTextBox.Capture = $true
    }
})

# Add an event handler for MouseUp
$richTextBox.Add_MouseUp({
    $start = $richTextBox.GetFirstCharIndexOfCurrentLine()
    $length = $richTextBox.GetFirstCharIndexFromLine($richTextBox.GetLineFromCharIndex($start) + 1) - $start
    $richTextBox.Select($start, $length)
    $selectedText = $richTextBox.SelectedText.Trim()
# _____________________________________ =>  T H E  S C R I P T  dialog starts here <= ___________________________________________
    $script:Choice = $selectedText -replace '\D', ''                                              # The dialog starts here
})

# Add colored items to the RichTextBox
add-ColoredText "0 - Please order your table" ([System.Drawing.Color]::Red)
add-ColoredText "`n                            W I N E C A R D" ([System.Drawing.Color]::Black)
add-ColoredText "`n1 - PrimalSyrah SAPIEN Vineyards - Red" ([System.Drawing.Color]::Red)
add-ColoredText "`n2 - Great Duck Escalante Winery - Sparkling" ([System.Drawing.Color]::DarkBlue)
add-ColoredText "`n3 - PSWine Chateau Snover - Red" ([System.Drawing.Color]::DarkBlue)
add-ColoredText "`n4 - Compare two Wines" ([System.Drawing.Color]::DarkBlue)
add-ColoredText "`n5 - Refill (Eight cl)" ([System.Drawing.Color]::Red)
add-ColoredText "`n6 - Fill (Two cl)" ([System.Drawing.Color]::DarkMagenta)
add-ColoredText "`n7 - Sip (One cl)" ([System.Drawing.Color]::DarkMagenta)
add-ColoredText "`n8 - Drink (Two cl)" ([System.Drawing.Color]::Red)
add-ColoredText "`n9 - IsSparkling" ([System.Drawing.Color]::DarkRed)
add-ColoredText "`n10 - isAged" ([System.Drawing.Color]::DarkRed)
add-ColoredText "`n11 - IsTipsy" ([System.Drawing.Color]::DarkRed)
add-ColoredText "`n12 - Put it on the bill" ([System.Drawing.Color]::Red)
add-ColoredText "`n13 - Can I have the bill, please" ([System.Drawing.Color]::Red)
add-ColoredText "`n14 - Any vacant tables" ([System.Drawing.Color]::DarkGreen)
add-ColoredText "`n15 - What is status so far" ([System.Drawing.Color]::DarkGreen)
add-ColoredText "`n16 - Get a full view of the Enotek" ([System.Drawing.Color]::DarkGreen)
add-ColoredText "`n17 - Member new/old, register here please" ([System.Drawing.Color]::Black)
add-ColoredText "`n18 - Taken" ([System.Drawing.Color]::White)

$form.Controls.Add($richTextBox)

<# 
# Add resize event handler
$form.Add_Resize({
    $scaleFactorX = $form.Size.Width / $initialFormSize.Width
    $scaleFactorY = $form.Size.Height / $initialFormSize.Height

    $richTextBox.Size = [System.Drawing.Size]::new($initialRichTextBoxSize.Width * $scaleFactorX, $initialRichTextBoxSize.Height * $scaleFactorY)
    $richTextBox.Location = [System.Drawing.Point]::new($initialRichTextBoxLocation.X * $scaleFactorX, $initialRichTextBoxLocation.Y * $scaleFactorY)
    
    $okButton.Location = [System.Drawing.Point]::new($initialOkButtonLocation.X * $scaleFactorX, $initialOkButtonLocation.Y * $scaleFactorY)
    $cancelButton.Location = [System.Drawing.Point]::new($initialCancelButtonLocation.X * $scaleFactorX, $initialCancelButtonLocation.Y * $scaleFactorY)
    
    $label.Location = [System.Drawing.Point]::new($initialLabelLocation.X * $scaleFactorX, $initialLabelLocation.Y * $scaleFactorY)
    $label.Size = [System.Drawing.Size]::new($initialLabelSize.Width * $scaleFactorX, $initialLabelSize.Height * $scaleFactorY)

    # Ensure form size keeps everything visible
    $minWidth = $initialRichTextBoxSize.Width + $initialRichTextBoxLocation.X * 2
    $minHeight = $initialRichTextBoxSize.Height + $initialRichTextBoxLocation.Y + $okButton.Size.Height + 50  # Include space for buttons and padding

    if ($form.Width -lt $minWidth) { $form.Width = $minWidth }
    if ($form.Height -lt $minHeight) { $form.Height = $minHeight }
})
#>  

$form.Topmost = $true
$result = $form.ShowDialog()
  
                if ($result -eq [System.Windows.Forms.DialogResult]::OK)
                {} 
               
                if ($result -eq [System.Windows.Forms.DialogResult]::CANCEL)
                {
                    break
                }   
                  
# _____________________________________ => T H E  S C R I P T  C O N T R O L S starts here <= ___________________________________________
                
                # New member
                if (17 -contains $script:Choice)                                                 
                {   
                    choice17                                                                                                                       
                } 
                 
                if (0 -notcontains $script:Choice)            
                {
                    if (0,1,2 -notcontains $script:Table) 
                    {   
                        CLS  
                        Write-Host("                                        ")  
                        Write-Host("         - emocWelleWcome -             ") 
                        Write-Host("               oo00oo                   ")                                           
                        Write-Host("`n")                    
                        Write-Host("After beeing seated, I shall bring you:")  
                        Write-Host("                                        ")                                 
                        Write-Host("  Get a full view of the Enotek [16]   ")   
                        Write-Host("                and                    ") 
                        Write-Host("     The terms for membership   [17]   ")                 
                        Write-Host("`n")                                   
                        Write-Host("               oo00oo                   ")
                        Write-Host("         - emocWelleWcome -             ")   
                           
                        $script:Choice = 0                   
                    }                                       
                }

                if (0,17 -notcontains $script:Choice)
                {
                    showStatus
                }
                            
                # Reserve your table                          
                if (0,1,2 -notcontains $script:Table) 
                { 
                    Write-Host("`n")
                    Write-Host("*** 1 *** You can choose your table")                      
                    $script:Choice = 0                                                                                                                             
                } 

                # New table and bill                    
                if (0,1,2,3 -contains $script:Choice -and $script:Passed -eq 1)                                                            
                {                    
                    $myBilling.Accumulate($myWineGlass)
                    Write-Host("`n")

                    loadbillingHash                    
                }  

                # Reserve your wine                
                if (1,2,3 -contains $script:Choice)                                           
                {
                    $script:Passed = 1                                 
                }                                             
  
                # Put it on the bill 
                if (12 -contains $script:Choice -and $myWineGlass.Poured -lt 1 -and $myWineGlass.Consumed -lt 1)               
                {
                    # Check if any keys in $billingHash match the current table via regex 
                    $matchingKeys = $billingHash.Keys -match "^$script:Table-\d+"
                    if ($matchingKeys.Count -gt 0) 
                    {
                        Write-Host ("*** 2 *** No more to bill for table:") $script:displayTable
                        $script:Choice = 18                       
                    }         
                    else
                    { 
                        Write-Host("*** 3 *** No usage to bill for table:") $script:displayTable  
                        $script:Choice = 18                                                
                    }
                } 
 
                # Can I have the bill                
                if (13 -contains $script:Choice -and 0,1,2 -contains $script:Table)                                              
                {                
                    # Check if any keys in $billingHash match the current table via regex 
                    $matchingKeys = $billingHash.Keys -match "^$script:Table-\d+"
                    if ($matchingKeys.Count -lt 1 -and $myWineGlass.Poured -lt 1 -and $myWineGlass.Consumed -lt 1)            
                    { 
                        Write-Host("*** 4 *** Nothing to bill for table:") $script:displayTable  
                        $script:Choice = 18
                    }  
                    elseif ($myWineGlass.Poured -gt 0 -or $myWineGlass.Consumed -gt 0)
                    { 
                        Write-Host("`n")
                        Write-Host("*** 5 *** Put it on the bill table:") $script:displayTable  
                        $script:Choice = 18
                    }
                    elseif ($matchingKeys.Count -gt 0)
                    {
                        $script:Passed = 1                                                         # Green light for billing
                    } 
                }               
 
                # Vacant tables
                if (14 -contains $script:Choice)                                                 
                {  
                    CLS
                    showStatus 
                    freeTables                                                                                                                         
                }                      
                                      
                # Service situations                                                               'Rest of numbers' are checked here         
                if (0,1,2,3,14,15,16,18 -notcontains $script:Choice -and $script:Passed -ne 1 ) 
                {                             
                    Write-Host("*** 6 *** Order your Wine table:") $script:displayTable    
                    $script:Choice = 18                                      
                }       
                
                                    
                
<#                                                              - oo00oo -   
                                                        
                                                          M A C H I N E  R O O M        
                                                        
                                                        
                                                          (Qualified staff only)
#>                                                        
              

# ___________________________________________________ => Here starts section CLASS <= _________________________________________     
                   
     
switch ($script:Choice)
{
0 {                                                  
                 
enum WineSweetness
{  
	            VeryDry
	            Dry
	            Medium
	            Sweet
	            VerySweet
}

class Wine: iComparable
{
	            # Properties
                [Nullable[int]]$number 
                #[Int32]$number
	            [String]$name                
  	            [String]$winery
	            [Int32]$year
                [Boolean]$isSparkling = $false
	            [ValidateSet("Red", "White", "Rose")][String]$color
	            [WineSweetness]$sweetness
                [String]$description
	            [Double]$price

	            # Constructors
	            Wine() {Write-Host("`n");Write-Host("Instantiating a Wine object")  }

	            Wine ([String]$name)
	            {
		            $this.Name = $name
 	            }

	            # Wine ([Int32]$number,  
                Wine ([Nullable[int]]$number,       
                      [String]$name,
	                  [String]$winery,
	                  [Int32]$year,
                      [Boolean]$isSparkling,
                      [String]$color,
	                  [WineSweetness]$sweetness,
                      [String]$description,
	                  [Double]$price )
	            {

                Write-Host("`n")
                Write-Host("Instantiating a Wine object")
                    $this.Number      = $number 
	                $this.Name        = $name                    
		            $this.Winery      = $winery
		            $this.Year        = $year
                    $this.isSparkling = $isSparkling
		            $this.Color       = $color
		            $this.Sweetness   = $sweetness
                    $this.Description = $description
		            $this.Price       = $price
	            }

	            # Converts objects
	            Wine ([PSObject]$inputObject)
	            {
                    $this.Number      = $inputObject.Number 
		            $this.Name        = $inputObject.Name                    
                    $this.Number      = $inputObject.Name 
		            $this.Winery      = $inputObject.Winery
		            $this.Year        = $inputObject.Year
		            $this.Color       = $inputObject.Color
                    $this.isSparkling = $inputObject.isSparkling
		            $this.Sweetness   = $inputObject.Sweetness
                    $this.Description = $inputObject.Description
		            $this.Price       = $inputObject.Price
	            }

                # Member Method
                Display()
                {                      
                   Write-Host("`n")
                   Write-Host("W I N E")
                   #Write-Host("Number: "    + $this.Number)                                       # Out of order temporarily
                   Write-Host("Name: "       + $this.Name)                                         # Due to metric disorder :-) 
                   Write-Host("Winery: "     + $this.Winery)
                   Write-Host("Year: "       + $this.Year)
                   Write-Host("isSparkling: "+ $this.isSparkling)
                   Write-Host("Color: "      + $this.Color)
                   Write-Host("Sweetness: "  + $this.Sweetness)
                   Write-Host("Description: "+ $this.Description)
                   Write-Host("Price: "      + $this.Price)
                }                 
                        
	            static [Boolean] isAged ([Wine]$wine)
	            {
		           return (((get-Date).Year - $wine.Year) -ge 10)
	            }
               
	            # Compare (returns -1/0/1)
	            [int] CompareTo ([Object]$otherWine)
	            {
	                if (!($otherWine.Price)){ return [Int]::MaxValue }
		                return $this.Price.CompareTo($otherWine.Price)                     
	            }
}

class Glass
{
	            # Properties
	            [int32]$size
	            [int32]$filled

	            # Constructors
	            Glass() { }

	            Glass ($size, $filled)
	            {
                   Write-Host("Instantiating a Glass object")
            	       $this.Size   = $size
		               $this.Filled = $filled
	            }

                # Member Method
                Display()
                {
                   Write-Host("`n")
                   Write-Host("G L A S S")
                   Write-Host("Size: "   + $this.Size)
                   Write-Host("Filled: " + $this.Filled)
                } 

                # Glasset (myGlass) is filled
	            [Boolean] Fill ([int32]$volume)
	            {
		            if ($this.Filled + $volume -le $this.Size)
		            {
		                $this.Filled += $volume
		                return $true
		            }
		            else
		            {
                        if ($this.Size -gt 0)
		                {
                            Write-Warning "=> Sorry. The glass isn't big enough. You have room for $($this.Size - $this.Filled)."
                        }                                
		                return $false                           
		            }
	            }

                # Glasset (myGlass) is emptied
	            [Boolean] Drink ([int32]$amount)
	            {
		            if ($this.Filled  - $amount -ge 0)
		            {
		                $this.Filled -= $amount
                        return $true   
		            }
		            else
		            {
		                Write-Warning "=> Glass is empty. Time to refill"
		                return $false
		            }
	            }
}

class WineGlass: Glass
{
	            # Properties
	            [Wine]$wine

	            # Hidden properties
	            [Int]$consumed
	            [Int]$poured
              
	            # Constructors
	            WineGlass() { }

                WineGlass ([Wine]$wine,
                           [int]$size,                      
                           [int]$filled,
                           [int]$consumed,
                           [int]$poured)
                {

                Write-Host("Instantiating a WineGlass object") 
                   $this.Wine     = $wine                                             
	               $this.Size     = $size
	               $this.Filled   = $filled                                         
                   $this.Consumed = $consumed                                         
	               $this.Poured   = $poured            
                }

                # Member Method
                Display()
                {
                   Write-Host("`n")
                   Write-Host("W I N E G L A S S")                     
                   Write-Host("Wine: "     + $this.Wine.Name)                     
                   Write-Host("Size: "     + $this.Size)
                   Write-Host("Filled: "   + $this.Filled)
                   Write-Host("Consumed: " + $this.Consumed)
                   Write-Host("Poured: "   + $this.Poured)         
                }

                # Still sober
                [Boolean] IsTipsy()
                {
		           return ($this.Consumed -ge 20)
	            }

                [Boolean] Drink ([int32]$ounces)
                {
                   if (([Glass]$this).Drink($ounces))
                   {
                       $this.Consumed += $ounces
                       return $true
                   } 
                   else
                   {
                       return $false
                   }
                }               
     
                # Counts consumed and writes-down myWineGlass
	            Sip()
	            {
                    if ($this.Size -gt 0)
		            {
                        $this.Drink(1)
                    }
	            }
 
                # Counts Poured and the Glass (myWineGlass) is filled
	            [void] Fill ([int32]$volume)
	            {
		            if (([Glass]$this).Fill($volume))
		            {
		                 $this.Poured += $volume
		            }
	            }

                # Glass (myWineGlass) is refilled
                Refill()
	            {
		            $this.Fill($this.Size - $this.Filled)
	            }

                [String] toString()
	            { 
		            return "=> My $($this.Size)-oz. wine glass contains $($this.Filled) oz.`
of no. $($script:displayWine) $($this.Wine.Name) by $($this.Wine.Winery)." 
	            }
}

class BeerGlass: Glass 
{
	            [String]$beerName

                # Constructors
	            BeerGlass() {Write-Host("Instantiating a Beer object")  }
  
                # Member Method
                Display()
                {
                    Write-Host("`n")
                    Write-Host("Size: "   + $this.Size)
                    Write-Host("Filled: " + $this.Filled)
                }

	            Gulp()
	            {
 		            $this.Drink(3)
	            }

	            Spill()
	            {
		            $this.Filled = 0
		            Write-Warning "=> Oops! You've spilled your beer!"
	            }

	            Refill()  
	            {
 		            $this.Filled = $this.Size
	            }
}
 
class Billing
{
                # Properties
	            [Wine]$wine

                # Hidden properties
                    [Int]$tableNumber 
	                [Int]$accuConsumed
	                [Int]$accuPoured 
             
	            # Constructors
	            billing() {} 
 
	            billing ([Wine]$wine,
                         [Int]$tableNumber,
                         [Int]$accuConsumed,
                         [Int]$accuPoured)                       
                {

                Write-Host("Instantiating a billing object") 
                    $this.Wine         = $wine  
                    $this.TableNumber  = $tableNumber                   
                    $this.AccuConsumed = $accuConsumed
		            $this.AccuPoured   = $accuPoured                                  
	            } 

                # Member Method
                Display()
                {                      
                    Write-Host("`n") 
                    Write-Host("B I L L I N G (Accumulate the bill)") 
                    Write-Host("Price: "        + $this.Wine.Price) 
                    Write-Host("TableNumber: "  + $this.TableNumber)                                                       
                    Write-Host("AccuConsumed: " + $this.AccuConsumed)
                    Write-Host("AccuPoured: "   + $this.AccuPoured)                                                                                       
                }  
                
                # Accumulate Method
                Accumulate($wineGlass)
                {  		                          
                    $this.AccuConsumed += $wineGlass.Consumed
                    $this.AccuPoured   += $wineGlass.Poured                                                    
                }   
                
                SetTableNumber([Int]$tableNumber)
                {
                    $this.TableNumber = $tableNumber
                }                  
                                       
	            # Billing for (myWineGlass)
	            [String] GetCheck()
	            {
		            #return "{0:C}" -f ([Math]::Ceiling($this.AccuPoured * $this.Wine.Price / 25))
                    return "{0:N0}" -f ([Math]::Ceiling($this.AccuPoured * $this.Wine.Price / 25))                     
                }                                                                                    
}

# ________________________________________________ => Here ends section CLASS <= _________________________________________



# ______________________________________________ => F U N C T I O N S starts here <= ___________________________________

function loadbillingHash
{
                # Define the wine and table numbers
                $tableNumber = $myBilling.TableNumber
                $wineNumber  = $myWineGlass.Wine.Number                

                # Create the key based on wine and table numbers
                $key = "${tableNumber}-${wineNumber}"

                # Unload the existing data from the billingHash (if it exists)
                if ($billingHash.ContainsKey($key))
                {
                    $previousData  = $billingHash[$key]
                    $consumedValue = $previousData.Consumed
                    $pouredValue   = $previousData.Poured
                }
                else
                {
                    $consumedValue = $null
                    $pouredValue   = $null
                }
 
                $consumedValue       += $myWineGlass.Consumed             
                $pouredValue         += $myWineGlass.Poured         
                $myBilling.AccuPoured = $pouredValue

                if ($consumedValue -gt 0 -and $pouredValue -gt 0)
                {
                    # Update billingHash with new data
                    $billingHash[$key] = @{
                        "Consumed" = $consumedValue
                        "Poured"   = $pouredValue
                        "Billed"   = $myBilling.GetCheck()
                    }     
                }        
                    
                $myWineGlass.Filled     = $null 
		        $myWineGlass.Consumed   = $null
                $myWineGlass.Poured     = $null
                $myBilling.AccuConsumed = $null
                $myBilling.AccuPoured   = $null
		        
     
                Write-Host("`nB I L L I N G (LoadingHash)")                
                foreach ($property in 'Consumed', 'Poured', 'Billed')
                {
                    # Get the values for the current property, sort them, and join them into a string
                    $propertyName = "billingHash_${property}:".Substring(0,13)
                    $formattedValues = $billingHash.GetEnumerator() | Sort-Object Name |`
                    ForEach-Object { "$($_.Value.$property)" }                 
                    Write-Host("${propertyName} $($formattedValues -join ' ')")
                }
}

function billing
{
                # Function to handle blinking text
                function Write-BlinkingText([String[]]$text, [ConsoleColor[]]$color, $blinkCount = 3)
                {
                    for ($j = 1; $j -le $blinkCount; $j++)
                    {
                        for ($i = 0; $i -lt $text.Length; $i++)
                        {
                            Write-Host $text[$i] -ForegroundColor $color[$i] -NoNewline
                        }
                        Start-Sleep -Milliseconds 500                         # Adjust the sleep duration for the blink speed
                        Write-Host ""                                         # This clears the line by writing an empty line
                        Start-Sleep -Milliseconds 500                         # Adjust the sleep duration for the text disappearance
                    }
                }
                
                # Function to 'highlight' usage in kr.
                function Write-Color([String[]]$text, [ConsoleColor[]]$color)
                {
                    for ($i = 0; $i -lt $text.Length; $i++)
                    {
                        Write-Host $text[$i] -Foreground $color[$i] -NoNewLine
                    } 
                }
                
                CLS 
                Write-Host ""                  
                Write-BlinkingText -Text 'E N O T E K wine B A R ' -Color Cyan 
                
                # Initialize variables
                $totalBilledForTable = 0
                
                # Display information
                Write-Host("`nB I L L I N G") 
                
                # Display individual wine details
                for ($i = 0; $i -lt 3; $i++)
                {
                    $wineName = switch ($i)
                    {
                        0 { 'PrimalSyrah' }
                        1 { 'Great Duck'  }
                        2 { 'PSWine'      }
                    }
                
                    $wineKey = "${script:Table}-${i}"  
                
                    $wineBilled = $billingHash[$wineKey].Billed                  
                    $winePoured = $billingHash[$wineKey].Poured 
                    $winePrice = switch ($i)
                    {
                        0 { 156 }
                        1 { 122 }
                        2 { 220 }
                    }
                
                    Write-Host ""      
                    Write-Host "" 
                    Write-Color -Text "Table number: " , ($myBilling.TableNumber+1) -Color White,Magenta`n 
                    Write-Host "" 
                    Write-Color -Text "Wine no: " , $($i + 1) -Color White,Green`n  
                    Write-Host ""  
                    Write-Color -Text "Wine name: " , $wineName -Color White,Green`n                    
                    Write-Host ""  
                    Write-Color -Text "Poored: ", "$winePoured cl." -Color White,Cyan,White`n   
                    Write-Host("")
                    Write-Color -Text "Price per bottle: ", "$winePrice kr." -Color White,Cyan,White`n
                    Write-Host "" 
                    Write-Color -Text "Payment: " , "$wineBilled kr." -Color White,Yellow`n
                    Write-Host "" 
                    Write-Host ""   
                        
                    # Store the total billed for the current table in the array
                    $totalBilledForTable += $wineBilled
                }
                
                Write-Color -Text "==> Payment in all: " , "$totalBilledForTable kr." , " <==" -Color White,Yellow,White`n
                Write-Host("`n")                 
                    
                if ($billingHash.Values.Poured -gt 0 -and $myWineGlass.Poured -lt 1 )
                {     
                    $sortedbillingHash = $billingHash.GetEnumerator() | Sort-Object -Property @{
                    Expression = { $_.Key.Split('-')[0] -as [int] }
                    Ascending  = $true
                    }  
                }   

# ______________________________________________ => Send an email with the bill <= ___________________________________                                      

# Send an email with the bill
function Send-BillEmail([int]$tableNumber, [int]$totalBilledForTable) {
    $From = "Hennireckey@hotmail.com"
    $To   = "Hennireckey@hotmail.com"
    #$To = "xpernilleqr@gmail.com" 
    #$To = "xjrkp1991@gmail.com"
    $Subject    = "Enotek Wine Bar - Bill Requested"
    $SMTPServer = "smtp-mail.outlook.com"
    $SMTPPort  = "587"
    #$SMTPPort = "465"
    $Username  = "Hennireckey@hotmail.com"
    $Password  = "MuG6F9yRJFvDBN3"                                              # Replace with your actual password

# Create a PSCredential object for authentication
$Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $Username, (ConvertTo-SecureString -String $Password -AsPlainText -Force)

# Construct the email body
$Body = @"
Dear Customer,

Thank you for visiting Enotek Wine Bar. Below is your bill summary:

Table Number: $script:displayTable
-----------------------------------------
| Wine              | Poured (cl) | Price (kr) |
-----------------------------------------
| PrimalSyrah   | $($billingHash["$tableNumber-0"].Poured) | $($billingHash["$tableNumber-0"].Billed) |
| Great Duck    | $($billingHash["$tableNumber-1"].Poured) | $($billingHash["$tableNumber-1"].Billed) |
| PSWine          | $($billingHash["$tableNumber-2"].Poured) | $($billingHash["$tableNumber-2"].Billed) |
-----------------------------------------
Total Bill: $totalBilledForTable kr.
 
Please let us know if you have any questions or concerns. We look forward to serving you again soon!

Best regards,
Enotek Wine Bar
"@

# Send the email
Send-MailMessage -From $From -To $To -Subject $Subject -Body $Body -SmtpServer $SMTPServer -Port $SMTPPort -UseSsl -Credential $Credentials
}
                # Calculate total billed amount
                $totalBilledForTable = 0
                for ($i = 0; $i -lt 3; $i++) {
                    $totalBilledForTable += $billingHash["$tableNumber-$i"].Billed
                }

                # Send the bill email
                #Send-BillEmail -tableNumber $tableNumber -totalBilledForTable $totalBilledForTable

                # Data is deleted here after billing: 
                foreach ($item in $sortedbillingHash)
                {
                    $currentKey = $item.Key
                    $currentTableNumber = $currentKey.Split('-')[0]
                    if ($currentTableNumber -eq $script:Table) {
                        $currentWineNumber = $currentKey.Split('-')[1]
                
                        if ($currentWineNumber -eq 0) {
                            $billingHash.Remove($currentKey)
                            $script:displayTable = $null 
                            $script:displayWine  = $null
                        }
                        elseif ($currentWineNumber -eq 1) {
                                $billingHash.Remove($currentKey)
                                $script:displayTable = $null 
                                $script:displayWine  = $null
                        }
                        elseif ($currentWineNumber -eq 2) {
                                $billingHash.Remove($currentKey)
                                $script:displayTable = $null 
                                $script:displayWine  = $null 
                        }
                    }
                }

                freeTables
                $script:Passed = 0 
}

# Any free tables
Function freeTables
{    
                # Check if there are any keys left in the billingHash for each table
                $table0Taken = $billingHash.Keys -like "0-*" -and ($billingHash.Values | Where-Object { $_.Poured -gt 0 }).Count -gt 0
                $table1Taken = $billingHash.Keys -like "1-*" -and ($billingHash.Values | Where-Object { $_.Poured -gt 0 }).Count -gt 0
                $table2Taken = $billingHash.Keys -like "2-*" -and ($billingHash.Values | Where-Object { $_.Poured -gt 0 }).Count -gt 0
                
                # Create text and color variables based on the table status
                $text0  = if ($table0Taken) { "Taken" } else { "Vacant" }
                $color0 = if ($table0Taken) { "red"   } else { "yellow" }
            
                $text1  = if ($table1Taken) { "Taken" } else { "Vacant" }
                $color1 = if ($table1Taken) { "red"   } else { "yellow" }
            
                $text2  = if ($table2Taken) { "Taken" } else { "Vacant" }
                $color2 = if ($table2Taken) { "red"   } else { "yellow" }
            
                function Write-BlinkingText([String[]]$text, [ConsoleColor[]]$color, $blinkCount = 1)
                {
                    for ($j = 1; $j -le $blinkCount; $j++)
                    {
                        for ($i = 0; $i -lt $text.Length; $i++)
                        {
                            Write-Host $text[$i] -ForegroundColor $color[$i] -NoNewline
                        }
                        Start-Sleep -Milliseconds 500                       # Adjust the sleep duration for the blink speed
                        Write-Host ""                                       # This clears the line by writing an empty line
                        Start-Sleep -Milliseconds 500                       # Adjust the sleep duration for the text disappearance
                    }
                }
            
                # Function to 'highlight' usage in kr
                function Write-Color([String[]]$text, [ConsoleColor[]]$color)
                {   
                    for ($i = 0; $i -lt $text.Length; $i++)
                    { 
                        Write-Host $text[$i] -ForegroundColor $color[$i] -NoNewLine
                    }
                }
            
              # Display table information                  
                Write-Host("            - oo00oo -                      ")                                                
                Write-Host ""               
                Write-Host "      E N O T E K wine B A R "               
                Write-Host ""
                Write-Host "             T A B L E          " 
                Write-Host "              status           "  
                Write-Host "" 
                Write-BlinkingText -Text "Table 1       " , $text0 -Color White,$color0
                Write-Host ""
                Write-BlinkingText -Text "Table 2       " , $text1 -Color White,$color1
                Write-Host ""
                Write-BlinkingText -Text "Table 3       " , $text2 -Color White,$color2                                         
}
  
# All handling of [metric 1 start] of arrays/hashtables in creation of $script:METRIC display attribute for all needs in a script  
function metricChange
{
                $script:Passed = 0                                                       # Have to order new wine
  
                # Check if any keys in $billingHash match the current table via regex 
                $matchingKeys = $billingHash.Keys -match "^$script:Table-\d+"        

                if ($matchingKeys.Count -gt 0) 
                {                      
                    $currentTableNumber = [int]$script:Lastkey[$script:Table].Split('-')[0]
                    $currentWineNumber  = [int]$script:Lastkey[$script:Table].Split('-')[1]
                    
                    $script:displayTable = $currentTableNumber + 1
                    $script:displayWine  = $currentWineNumber  + 1

                    $wineOptions = @( $wineCompare0, $wineCompare1, $wineCompare2 )      # Show the last tasted wine at each table                     
                    $myWineGlass = $wineOptions[$currentWineNumber] 
                                     
                    $script:Choice = $script:displayWine                                 # This in order to activate methods
                    $script:Passed = 1
                    
                    # Display the information for the new table
                    Write-Host("`n")   
                    Write-Host("              - oo00oo -                      ")
                    Write-Host(">          Wine tasted recently             < ")                   
                    $myWineGlass.Display() 
                    Write-Host("`n")                                                       
                }   
}  

function loadLastkey
{
                # Check if the array contains the table index
                if (-not $script:Lastkey.ContainsKey($tableNumber))
                {
                    Write-Host "Adding new key to lastkey array: $($tableNumber + 1)"
                    $script:Lastkey.Add($tableNumber, $script:Hashkey)
                }
                else
                {
                    Write-Host "Updating existing key in lastkey array: $($tableNumber + 1)"
                    $script:Lastkey[$tableNumber] = $script:Hashkey
                }          
}

function showStatus
{
                showSeparator

                Write-Host("`1'st")              
                Write-Host("`Here => Choice:  ") $script:Choice   
                Write-Host("`Here => WineNumber:") $script:displayWine       
                Write-Host("`Here => TableNumber: ") $script:displayTable         
                Write-Host("`Here => Wine on Bills: ") $billingHash.count                         
                Write-Host("`Here => Poured not Paid: ") $myWineGlass.Poured    
                Write-Host("`Here => Ordered and Passed:") $script:Passed            
                Write-Host("`n")               
                Write-Host $("You are here:    ==> Table: $script:displayTable  => Wine:"; $script:displayWine) 
                Write-Host("`n") 
}

# Function to display separator and counter
function showSeparator
{ 
                Write-Host("`n")
                Write-Host "=> ___________________ $($script:Counter) ____________________ <= ___`n"    
                # Increment the counter for the next session
                $script:Counter++
}
  
# ______________________________________ => Finish run and a change of table <= _________________________________________ 
                               
                $result = [System.Windows.Forms.MessageBox]::Show("Choose table by pressing either Table1[Y] Table2[N] Table3[C]",`
                          "Order your table from these three Yes No Cancel", "YesNoCancel")                         
                                          
                switch ($result)`                                                        # Proposed by AI
                {
                    "Yes"    {$script:Table = 0;$script:displayTable = 1}
                    "No"     {$script:Table = 1;$script:displayTable = 2}
                    "Cancel" {$script:Table = 2;$script:displayTable = 3} 
                } 
                   
                CLS
                metricChange                                                                 
               
                showStatus
                Write-Host("`n")                 
                Write-Host("*** 7 *** Please order your Wine")   
                Write-Host("`n")                                   
  
If ($script:Choice -eq 0)
{ 
break
}                                                                                   
}                                                                    
}  

# ______________________________________________ => Here ends section functions <= _________________________________________



# _________________________________________________ => Here starts ENOTEK <= ______________________________________________ 

function Choice21
{       
    # Glass (ej Enotek)
    $myGlass = [Glass]::new(8, 0)

    $myGlass.Display()
    Write-Host("`n")

    # (Not Enotek)
    $myGlass.Drink(2)  # The glass is emptied myGlass 
    $myGlass.Fill(2)   # The glass is filled  myGlass  
    Write-Host("`n")
}

# _________________________________________ => Here starts ENOTEK function choice <= ______________________________________
        
function Choice04
{
    # CompareWines - Enotek - Questions  
    $selectedWine     = Get-WineByWineNumber
    $comparisonResult = $myWineGlass.Wine.CompareTo($selectedWine)

    switch ($comparisonResult)
    {
       -1 { 
            $priceDifference = $($selectedWine.Price - $myWineGlass.Wine.Price)
            Write-Host "$($myWineGlass.Wine.Name) is $($priceDifference) kr. cheaper than $($selectedWine.Name)" 
          }
        0 { Write-Host "$($myWineGlass.Wine.Name) and $($selectedWine.Name) have the same price" }
        1 { 
            $priceDifference = $($myWineGlass.Wine.Price - $selectedWine.Price)
            Write-Host "$($myWineGlass.Wine.Name) is $($priceDifference) kr. more expensive than $($selectedWine.Name)" 
          }
    }
} 

function Get-WineByWineNumber
{
    $wineOptions = @( $wineCompare0, $wineCompare1, $wineCompare2 )    

    $result = [System.Windows.Forms.MessageBox]::Show("Choose wine choice by pressing either Syrah[Y] Duck[N] PSW[C]",`
               "Your wine choice by pressing these three Yes No Cancel", "YesNoCancel") 

    switch ($result)
    {
        "Yes"    { return $wineOptions[0] }                  
        "No"     { return $wineOptions[1] }
        "Cancel" { return $wineOptions[2] }
        default  {}
    }
}

function Choice05
{
    # Refill - Tasting
    $myWineGlass.Refill()
    $myWineGlass.Display()
    Write-Host("`n")
    $myWineGlass.toString()     
}

function Choice06
{
    # Fill - Tasting
    $myWineGlass.Fill(2)
    $myWineGlass.Display()
    Write-Host("`n")
    $myWineGlass.toString()
}

function Choice07
{
    # Sip - Tasting
    $myWineGlass.Sip()
    $myWineGlass.Display()
    Write-Host("`n")
    $myWineGlass.toString()    
}

function Choice08
{ 
    # Drink - Smagning
    $myWineGlass.Drink(2)  
    $myWineGlass.Display()
    Write-Host("`n")
    $myWineGlass.toString()     
}

function Choice09
{
    # IsSparkling - Enotek - Questions 
    switch ($myWineGlass.Wine.Number)
    {
        0 { Write-Host "=> Is PrimalSyrah sparkling: $($PrimalSyrah.isSparkling)" }
        1 { Write-Host "=> Is Duck sparkling: $($Duck.isSparkling)" }
        2 { Write-Host "=> Is PSWine sparkling: $($PSWine.isSparkling)" }
    }
}

function Choice10
{
    # isAged - Enotek - Questions    
    switch ($myWineGlass.Wine.Number)
    {
        0 { Write-Host "=> Is PrimalSyrah aged: $(((get-Date).Year - $PrimalSyrah.Year) -ge 10), more than 10 years" }
        1 { Write-Host "=> Is Duck aged: $(((get-Date).Year - $Duck.Year) -ge 10), more than 10 years" }
        2 { Write-Host "=> Is PSWine aged: $(((get-Date).Year - $PSWine.Year) -ge 10), more than 10 years" }
    }
}
    
function Choice11
{
    # IsTipsy - Enotek - Questions
    if ($myWineGlass.IsTipsy())
    {
        Write-Host "=> Am I tipsy: You aught to stay home to morrow"
    }
    else 
    {
        Write-Host "=> Am I tipsy: Far from"
    }
}

function Choice12
{
    # Put it on the bill - Enotek 
    $myBilling.Accumulate($myWineGlass)
    Write-Host("`n");
     
    loadbillingHash

    Write-Host("`n")
    Write-Host("*B I L L I N G - H A S H T A B L E*")
    Write-Host("   P R E L I M I N A R Y  B I L L  ")
   
    foreach ($tableKey in ("0-0", "0-1", "0-2", "1-0", "1-1", "1-2", "2-0", "2-1", "2-2"))
    {
        $tableData = $billingHash.Item($tableKey)
        Write-Host($tableKey)

        # Check if $tableData is not null before iterating through it
        if ($null -ne $tableData) {
            Write-Host("{0,-30} {1,-15}" -f 'Name', 'Value')

            foreach ($entry in $tableData.GetEnumerator()) {
                $value = if ($null -eq $entry.Value) { 'N/A' } else { $entry.Value }
                Write-Host("{0,-30} {1,-15}" -f $entry.Key, $value)
            }
        }
        else
        {
            Write-Host("Empty")
        }        
    }
}

function Choice13
{
    # GetBill - Enotek 
    $myBilling.SetTableNumber($script:Table)
  
    billing  
}

function Choice15
{    
    switch ($script:displayWine)
    {
        1 { Write-Host("Wine tasted: 1. PrimalSyrah, SAPIEN Vineyards") }
        2 { Write-Host("Wine tasted: 2. Great Duck, Escalante Winery") }
        3 { Write-Host("Wine tasted: 3. PSWine, Chateau Snover") }        
    }
 
    # Status - Enotek      
    Write-Host("`n")
    Write-Host("*B I L L I N G - H A S H T A B L E*")
    Write-Host("   P R E L I M I N A R Y  B I L L  ")
    
    foreach ($tableKey in ("0-0", "0-1", "0-2", "1-0", "1-1", "1-2", "2-0", "2-1", "2-2"))
    {
        $tableData = $billingHash.Item($tableKey)
        Write-Host($tableKey)

        # Check if $tableData is not null before iterating through it
        if ($null -ne $tableData) {
            Write-Host("{0,-30} {1,-15}" -f 'Name', 'Value')

            foreach ($entry in $tableData.GetEnumerator()) {
                $value = if ($null -eq $entry.Value) { 'N/A' } else { $entry.Value }
                Write-Host("{0,-30} {1,-15}" -f $entry.Key, $value)
            }
        }
        else
        {
            Write-Host("Empty")
        }        
    }
}


# _________________________________________ => Here starts ENOTEK Explainer <= ______________________________________


function Choice16
{
    function Explainer
    {
      # FullView - Enoteket - Explainer 
      [CmdletBinding()]
      param(
          [Parameter(Mandatory)]
          [ValidateNotNullOrEmpty()]
          [string]$title,
    
          [Parameter(Mandatory)]
          [ValidateNotNullOrEmpty()]
          [string]$question
      )    
      $bot = [ChoiceDescription]::new('&out', '')     
      $options = [ChoiceDescription[]]( $bot )        
      $result = $host.ui.PromptForChoice($title, $question, $options, 0)   
        
      switch ($result) {       
          18 {$script:Choice  = 18 }                                                                                                                                                                  
      }
    }    
        Explainer -Title "                                                                                                                                      _ _______ M e n u _______ _" -Question {   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~                                                                    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~       

                                                                                                                                             E n o t e k        

                                                                                                                                       ~~   2022   ~~                      
                                          
                                         
                                         0:           Please, order your table   

                                         1:           Order wine:      PrimalSyrah,     SAPIEN Vineyards,     1990, Red, Delicious and fruity                                                                                                                                                                                                                                                    
                                         2:           Order wine:      Great Duck,      Escalante Winery,      2003, White Sparkling, Rich and Magnificient
                                         3:           Order wine:      PSWine,           Chateau Snover,         2012, Red Dry, Dark ruby  
                                         4:           Compare two Wines

                                         5:           Drink(2cl)                                 #Counts Glass filled and Consumed                                               
                                         6:           sip(1cl)                                     #Counts Glass filled and Consumed  
                                         7:           Fill(2)                                        #Tops and Counts filled and TotalPoured                         
                                         8:           Refill(8cl)                                  #Tops (size - filled) and Counts TotalPoured                                
                                           
                                         9:           IsSparkling                                
                                        10:          isAged 
                                        11:          IsTipsy                                    #Please, blow in here

                                       12:           Put it on the bill
                                       13:           Can I have the bill                  #billing = (TotalPoured / 25) * Price  
                                       14:           Any vacant tables                                                                                                            
                                       15:           What is status so far  
                                       17:           Membership terms
                                                                                                                                                                                                           
                                          }                                                                                     
}

function Choice17
{     

function Get-InputBox
{
    param(
        [string]$Prompt
    )

    # Create a .NET form
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Member input"
    #$form.Size = New-Object System.Drawing.Size(300, 220)  # Adjusted size
    $form.Size = New-Object System.Drawing.Size(400, 262)  # Adjusted size
    $form.StartPosition = "CenterScreen"

    # Add a label
    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10, 30)
    $label.Size = New-Object System.Drawing.Size(250, 70)
    $label.Text = $Prompt
    $form.Controls.Add($label)

    # Add a text box
    $textbox = New-Object System.Windows.Forms.TextBox
    $textbox.Location = New-Object System.Drawing.Point(50, 100)
    $form.Controls.Add($textbox)
    $textbox.Size = New-Object System.Drawing.Size(250, 20)

    # Add an OK button
    $button = New-Object System.Windows.Forms.Button
    $button.Location = New-Object System.Drawing.Point(100, 150)
    $button.Size = New-Object System.Drawing.Size(75, 23)
    $button.Text = "OK"
    $button.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.Controls.Add($button)

    # Show the form
    $form.AcceptButton = $button
    $result = $form.ShowDialog()

    # Return the text entered in the text box
    if ($result -eq [System.Windows.Forms.DialogResult]::OK)
    {
        $textbox.Text
    }
    else
    {
        $null
    }

    # Dispose of the form
    $form.Dispose()
} 
    
    # Get member number ***
    $csvFilePath = "$basePath\Mail.csv"  
    
    if (Test-Path $csvFilePath)
    {
        # Initialize variables
        $lastMemberNumber = 0
    
        # Read the CSV file
        Get-Content $csvFilePath | ForEach-Object{
            $values = $_ -split ','
    
            # Update the lastMemberNumber if the current memberNumber is greater
            if ([int]$values[0] -gt $lastMemberNumber)
            {
                $lastMemberNumber = [int]$values[0]
            }
        } 
           
        Write-Host " " 
        $nextMemberNumber = $lastMemberNumber + 1    
        #Write-Host "Next Member Number: $nextMemberNumber" 
        Write-Host "Next Member Number: $nextMemberNumber" -ForegroundColor Green
        Write-Host " " 
    }
    $member =  $nextMemberNumber  

    #___________________________________
    $email = Get-InputBox -Prompt "Welcome new/old member:`n         
           Please register your email or old`
           member number"
    #___________________________________  
    
    try {
           [int]$numericValue = $email
           Write-Host "Input is numeric."
           Write-Host " "  
           [int]$oldmember = $email  

            # Old member ***
            $found = $false
            Get-Content $csvFilePath | ForEach-Object{
                $values = $_ -split ','        
    
                if ($values[0] -eq $oldmember)
                {
                    $found = $true
                    $emailAddress = $values[2]
                }
            }
    
            if ($found)
            {
                $To = $emailAddress
                Write-Host "Email Address for Member $($oldmember):`n "****" $emailAddress "****" " -ForegroundColor Green 
                Write-Host " " 
                Write-Host " " 
            }
            else
            {
                Write-Host "Member $oldmember not found."
            }     
            $To =  $emailAddress
             
        }

    catch
        {
            Write-Host "Input is not numeric."

            $found = $false
            Get-Content $csvFilePath | ForEach-Object{
                $values = $_ -split ','        
                
                if ($values[2] -eq $email)
                { 
                    $found = $true                 
                    Write-Host "Your Emai address is already registered"                  
                } 
            }
                     
            if (-not $found) {
                Write-Host "Thank you for providing your email: $email"    
                $To = $email                
                $nextMemberNumber = $member + 1  
                $csvLine = "$member,$nextMemberNumber,$email"        
                $csvFilePath = "$basePath\Mail.csv"       
                # Append the CSV line to the file
                Add-Content -Path $csvFilePath -Value $csvLine           
            }  
        }          
}
 
# ____________________________________ => Here starts ENOTEK switch choice handling <= ______________________________________

 switch ($script:Choice)
 {
    1 {
        # 1.Choose your wine
        $PrimalSyrah = [Wine]::new(0, "PrimalSyrah", "SAPIEN Vineyards", 1990, $false, "Red", 1, "Delicious and fruity", 156)
        $myWineGlass = [WineGlass]::new($PrimalSyrah, 8, 0, 0, 0)
        $myBilling = [billing]::new($PrimalSyrah, $myBilling.TableNumber, $null, $null)
        $myBilling.SetTableNumber($script:Table)    
      
        [int]$tableNumber = $script:Table
        [int]$wineNumber  = 0      
        [string]$script:Hashkey = "${tableNumber}-${wineNumber}" 
          
        loadLastkey
        
        $script:displayWine = 1
        $PrimalSyrah.Display()
        $myWineGlass.Display()
        Write-Host("`n")
        $myWineGlass.toString()
        Write-Host("`n")

        showStatus

        break
      }
    
    2 {    
        # 2. Choose your wine
        # Using null constructor and hashtable
        $Duck = [Wine]@{
        Number = 1
        Name = "Great Duck"
        Winery = "Escalante Winery"
        Year = "2003"
        isSparkling = $true
        Color = "White"
        Sweetness = 4
        Description = "Rich and Magnificient"
        Price = 122
        }
        $myWineGlass = [WineGlass]::new($Duck, 8, 0, 0, 0)
        $myBilling = [billing]::new($Duck, $myBilling.TableNumber, $null, $null)
        $myBilling.SetTableNumber($script:Table)

        [int]$tableNumber = $script:Table
        [int]$wineNumber  = 1      
        [string]$script:Hashkey = "${tableNumber}-${wineNumber}"  

        loadLastkey
            
        $script:displayWine = 2
        $Duck.Display()
        $myWineGlass.Display()
        Write-Host("`n")
        $myWineGlass.toString()
        Write-Host("`n")   

        showStatus
 
        break
      }

    3 {
        # 3.Choose your wine 
        $PSWine = [Wine]::new(2,"PSWine", "Chateau Snover", 2012, $false, "Red", "Dry", "Dark ruby", 220)
        $myWineGlass = [WineGlass]::new($PSWine, 8, 0, 0, 0)             
        $myBilling   = [billing]::new($PSWine, $myBilling.TableNumber, $null, $null)    
        $myBilling.SetTableNumber($script:Table)   
        
        [int]$tableNumber = $script:Table
        [int]$wineNumber  = 2      
        [string]$script:Hashkey = "${tableNumber}-${wineNumber}"   

        loadLastkey

        $script:displayWine = 3
        $PSWine.Display()
        $myWineGlass.Display()         
        Write-Host("`n")
        $myWineGlass.toString()  
        Write-Host("`n")         
          
        showStatus         
        
        break    
      }
      
   18 {    
        break    
      }
       
      4 { Choice04 }
      5 { Choice05 }
      6 { Choice06 }
      7 { Choice07 }
      8 { Choice08 }
      9 { Choice09 }
     10 { Choice10 }
     11 { Choice11 }
     12 { Choice12 }
     13 { Choice13 }
     15 { Choice15 }
     16 { Choice16 }
     17 { Choice17 }
default {          }
} 
}    
        break       
        

# _________________________________________________ => Here starts The Tool shop <= ______________________________________________         
            
        
#Tool shop
               {$PSWine.CompareTo($PrimalSyrah)}   #  1 kr. 220 against kr. 156  Vinene skal være bestilt for at kunne sammmenlignes       
               {$PSWine.CompareTo($Duck)}          #  1 kr. 220 against kr. 122
               {$Duck.CompareTo($PrimalSyrah)}     # -1 kr. 122 against kr. 156 
               {$Duck.CompareTo($PSWine)}          # -1 kr. 122 against kr. 220
               {$PrimalSyrah.CompareTo($Duck)}     #  1 kr. 156 against kr. 122
               {$PrimalSyrah.CompareTo($PSWine)}   # -1 kr. 156 against kr. 220

                $billingHash.keys 
                $billingHash.count   
                $billingHash.Values
                $billingHash.Values.Consumed 
                $billingHash.Values.Poured 
                $billingHash.Values.Billed                    
                                   
                $billingHash.Item("0-0")             
                $billingHash.Item("0-1")   
                $billingHash.Item("0-2")  
Write-Host("_______________________________________________________________`n")                
                $billingHash.Item("1-0")             
                $billingHash.Item("1-1")   
                $billingHash.Item("1-2")  
Write-Host("_______________________________________________________________`n")
                $billingHash.Item("2-0")             
                $billingHash.Item("2-1")   
                $billingHash.Item("2-2") 
Write-Host("_______________________________________________________________`n")
 
                # Accessing properties
                $count         = $billingHash.Count
                $isReadOnly    = $billingHash.IsReadOnly
                $keys          = $billingHash.Keys
                $values        = $billingHash.Values
                $enumerator    = $billingHash.GetEnumerator()
                $containsKey   = $billingHash.ContainsKey('Age') 
                $containsValue = $billingHash.ContainsValue('USA') 
                                 $billingHash.Add('NewKey', 'NewValue')
                                 $billingHash.Remove('Poured') 
                                                                           
                $billingHash.Values.Sum()                                                                #!!!!! oh no doesn't exist                   
                  
                $myWineGlass.Drink(2)
                $myWineGlass.Display()                                                 
                $myWineGlass.Refill()   
                $myWineGlass.Wine.name
                $myWineGlass.Wine.Number
                $myWineGlass.Consumed
                 
                $myBilling.Display()
                $myBilling.Wine.Price  
                
                                                  #=== Bierhalle ===#
# Choose a beer
                $myBeerGlass = [BeerGlass]@{BeerName = "Carlsberg Porter"; Size = 16; Filled = 16 }
                $myBeerGlass.BeerName
                $myBeerGlass.Size
                $myBeerGlass.Display()
                $myBeerGlass.Gulp()
                $myBeerGlass.Spill()
                $myBeerGlass.Refill()   
                                                  #=== Service area ===#
#[Wine].GetInterfaces()
#$PrimalSyrah, $PSWine, $Duck | Export-CSV -Path '$basePath\Mail.csv'
#$myCSVWines = Import-CSV -Path '$basePath\Mail.csv' | Foreach { [Wine]::new( $_ ) }

#$myCSVwines | ft name, Winery, year, color, Sweetness, price -AutoSize
#$myCSVwines | sort Price
#$myCSVwines | group color

#$PrimalSyrah, $PSWine, $Duck | Export-Clixml -Path '$basePath\Wine.xml'
#$myXMLWines = Import-Clixml -Path '$basePath\Wine.xml' | Foreach { [Wine]::new( $_ ) }

#$myXMLwines | ft name, Winery, year, color, Sweetness, price -AutoSize
#$myXMLwines | sort Price
#$myXMLwines | group color         
                                                     # THE END   

                                                  #=== Storage ===#       

<#     EVENT  
To connect the two scripts and allow them to interact with each other's events,ensure that they have a way to communicate.
Here are a few ways you can achieve this:
Dot-sourcing: If the wine script and the beer script are meant to be run together in the same session,
you can dot-source the wine script from the beer script. Dot-sourcing allows you to run the wine script within the context
of the beer script, meaning that all variables, functions, and classes defined will be available to the beer script.

# In the beer script
. .\wine_script.ps1

With dot-sourcing, you can directly call functions or instantiate classes from the wine script in your beer script.
Shared variables or files: If the scripts are running in separate sessions or environments, you can use shared variables
or files to pass information between them. For example, you could write the output of the wine script (such as events or data)
to a file, and then have the beer script read from that file to determine when to trigger its own events.
Remote Procedure Call (RPC): If the scripts are running on different machines or environments, you can use RPC mechanisms
to call functions or methods in one script from the other. PowerShell supports various RPC mechanisms,
such as PowerShell Remoting or REST APIs, which allow scripts to communicate over a network.
Choose the method that best fits your use case and environment. In many cases, dot-sourcing may be the simplest solution
for connecting scripts running in the same session.
#>

<#   
#Min gamle loadbillingHash (Før Mr. AI lavede nyt forslag)
Function loadbillingHash
{
                 if (($myWineGlass.Wine.Number -eq 0) -And ($myBilling.TableNumber -eq 0)){ 
                 [int]$AC00 = $billingHash.Item("0-0").Consumed
                 [int]$AP00 = $billingHash.Item("0-0").Poured}
             ElseIf (($myWineGlass.Wine.Number -eq 0) -And ($myBilling.TableNumber -eq 0)){ 
                 [int]$AC01 = $billingHash.Item("0-1").Consumed
                 [int]$AP01 = $billingHash.Item("0-1").Poured}
             ElseIf (($myWineGlass.Wine.Number -eq 0) -And ($myBilling.TableNumber -eq 0)){ 
                 [int]$AC02 = $billingHash.Item("0-2").Consumed
                 [int]$AP02 = $billingHash.Item("0-2").Poured}
             ElseIf (($myWineGlass.Wine.Number -eq 0) -And ($myBilling.TableNumber -eq 0)){ 
                 [int]$AC  = $billingHash.Item("1-0").Consumed
                 [int]$AP10 = $billingHash.Item("1-0").Poured}
             ElseIf (($myWineGlass.Wine.Number -eq 0) -And ($myBilling.TableNumber -eq 0)){ 
                 [int]$AC11 = $billingHash.Item("1-1").Consumed
                 [int]$AP11 = $billingHash.Item("1-1").Poured}
             ElseIf (($myWineGlass.Wine.Number -eq 0) -And ($myBilling.TableNumber -eq 0)){ 
                 [int]$AC12 = $billingHash.Item("1-2").Consumed
                 [int]$AP12 = $billingHash.Item("1-2").Poured}
             ElseIf (($myWineGlass.Wine.Number -eq 0) -And ($myBilling.TableNumber -eq 0)){ 
                 [int]$AC20 = $billingHash.Item("2-0").Consumed
                 [int]$AP20 = $billingHash.Item("2-0").Poured}
             ElseIf (($myWineGlass.Wine.Number -eq 0) -And ($myBilling.TableNumber -eq 0)){ 
                 [int]$AC21 = $billingHash.Item("2-1").Consumed
                 [int]$AP21 = $billingHash.Item("2-1").Poured}
             ElseIf (($myWineGlass.Wine.Number -eq 0) -And ($myBilling.TableNumber -eq 0)){ 
                 [int]$AC22 = $billingHash.Item("2-2").Consumed
                 [int]$AP22 = $billingHash.Item("2-2").Poured}
                
                 if  (($myWineGlass.Wine.Number -eq 0) -And ($myBilling.TableNumber -eq 0)){$Key = "0-0";`
                       $billingHash[$Key] = @{"Consumed"=$myBilling.AccuConsumed + $AC00;"Poured"=$myBilling.AccuPoured + $AP00; 
                                              "Billed"=$($myBilling.GetCheck())}}                                                                 
             ElseIf  (($myWineGlass.Wine.Number -eq 1) -And ($myBilling.TableNumber -eq 0)){$Key = "0-1";`
                       $billingHash[$Key] = @{"Consumed"=$myBilling.AccuConsumed + $AC01;"Poured"=$myBilling.AccuPoured + $AP01;
                                              "Billed"=$($myBilling.GetCheck())}}                      
             ElseIf  (($myWineGlass.Wine.Number -eq 2) -And ($myBilling.TableNumber -eq 0)){$Key = "0-2";`
                       $billingHash[$Key] = @{"Consumed"=$myBilling.AccuConsumed + $AC02;"Poured"=$myBilling.AccuPoured + $AP02; 
                                              "Billed"=$($myBilling.GetCheck())}}
             ElseIf  (($myWineGlass.Wine.Number -eq 0) -And ($myBilling.TableNumber -eq 1)){$Key = "1-0";`
                       $billingHash[$Key] = @{"Consumed"=$myBilling.AccuConsumed + $AC10;"Poured"=$myBilling.AccuPoured + $AP10; 
                                              "Billed"=$($myBilling.GetCheck())}}
             ElseIf  (($myWineGlass.Wine.Number -eq 1) -And ($myBilling.TableNumber -eq 1)){$Key = "1-1";`
                       $billingHash[$Key] = @{"Consumed"=$myBilling.AccuConsumed + $AC11;"Poured"=$myBilling.AccuPoured + $AP11;
                                              "Billed"=$($myBilling.GetCheck())}}                      
             ElseIf  (($myWineGlass.Wine.Number -eq 2) -And ($myBilling.TableNumber -eq 1)){$Key = "1-2";`
                       $billingHash[$Key] = @{"Consumed"=$myBilling.AccuConsumed + $AC12;"Poured"=$myBilling.AccuPoured + $AP12; 
                                              "Billed"=$($myBilling.GetCheck())}}
             ElseIf  (($myWineGlass.Wine.Number -eq 0) -And ($myBilling.TableNumber -eq 2)){$Key = "2-0";`
                       $billingHash[$Key] = @{"Consumed"=$myBilling.AccuConsumed + $AC20;"Poured"=$myBilling.AccuPoured + $AP20; 
                                              "Billed"=$($myBilling.GetCheck())}}
             ElseIf  (($myWineGlass.Wine.Number -eq 1) -And ($myBilling.TableNumber -eq 2)){$Key = "2-1";`
                       $billingHash[$Key] = @{"Consumed"=$myBilling.AccuConsumed + $AC21;"Poured"=$myBilling.AccuPoured + $AP21;
                                              "Billed"=$($myBilling.GetCheck())}}                      
             ElseIf  (($myWineGlass.Wine.Number -eq 2) -And ($myBilling.TableNumber -eq 2)){$Key = "2-2";`
                       $billingHash[$Key] = @{"Consumed"=$myBilling.AccuConsumed + $AC22;"Poured"=$myBilling.AccuPoured + $AP22; 
                                              "Billed"=$($myBilling.GetCheck())}}    
                                                         
             $myWineGlass.Filled = 0 
		     $myWineGlass.Consumed = 0
		     $myWineGlass.Poured = 0
             $myBilling.AccuConsumed = 0
             $myBilling.AccuPoured = 0
                
             Write-Host("billingHash_C:") $billingHash.Values.Consumed
             Write-Host("billingHash_P:") $billingHash.Values.Poured  
             Write-Host("billingHash_B:") $billingHash.Values.Billed       
}             
             $sortedArray = $billingHash.keys          | Sort-Object
             $sortedArray = $billingHash.Values.Poured | Sort-Object 
             $sortedArray = $billingHash.Values.Billed | Sort-Object

_____________________________________________________________________________
Function billing                                                                    # Den gamle $billing (Nyd AI's version)
{    
                # Although you can't sort and add in a hashtable - This code manages                
                if ($billingHash.Values.Poured -gt 0 -and $myWineGlass.Poured -lt 1 )
                {          
                    $x = $y = $z = $null  # Initialize variables
                    $xx = $yy = $zz = $null   
                    $xxx = $yyy = $zzz = $total = $null                             

                    $sortedbillingHash = $billingHash.GetEnumerator() | Sort-Object -Property @{
                    Expression = { $_.Key.Split('-')[0] -as [int] }
                    Ascending  = $true
                    }

                    # Iterate through the sortedbillingHash to find a match based on wineNumber
                    foreach ($item in $sortedbillingHash)
                    {
                        $currentKey = $item.Key
                        $currentTableNumber = $currentKey.Split('-')[0]
                        if ($currentTableNumber -eq $script:Table)
                        {
                           $currentWineNumber = $currentKey.Split('-')[1] 
                           # Update the variables $x, $y, and $z with the sorted values
                           if ($currentWineNumber -eq 0)
                           {
                               $x = $item.Value.Consumed
                               $xx = $item.Value.Billed
                               $xxx = $item.Value.Poured
                           }
                           elseif ($currentWineNumber -eq 1)
                           {
                               $y = $item.Value.Consumed
                               $yy = $item.Value.Billed
                               $yyy = $item.Value.Poured
                           }
                           elseif ($currentWineNumber -eq 2)
                           {
                               $z = $item.Value.Consumed
                               $zz = $item.Value.Billed
                               $zzz = $item.Value.Poured
                           } 
                        }                                     
                    }             
                   
                    $count11 = $count12 = $count13 = $null   
                    if ($null -eq ($x, $y, $z, $xxx, $yyy, $zzz | Where-Object { $_ -ne $null })) 
                    {
                    # All variables are null
                    }
                    else
                    {
                       # At least one variable is not null    
                       if ($null -ne $xx  -and $xx -gt 0)
                       {   
                           $count11 = 0
                           Do {
                                $count11  ++                   
                              } until(($xx) -eq $count11)  
                       }
                       if ($null -ne $yy -and $yy -gt 0)
                       {         
                           $count12 = 0
                           Do {
                                $count12  ++
                              } until(($yy) -eq $count12)  
                       }
                       if ($null -ne $zz  -and $zz -gt 0)
                       {       
                           $count13 = 0
                           Do {
                                $count13  ++     
                              } until(($zz) -eq $count13)
                       } 
               
                       $total = $count11+$count12+$count13
                    }
}


# ____________________________________________ => Here starts AI Kommentarer til scriptet <= ______________________________________________ 

                                                          

You have provided a significant amount of PowerShell code, which appears to be an interactive script related to managing wine and billing.`
Here's an overview of your script and some comments on its structure and logic:

 1.   OOP Principles: Your script demonstrates object-oriented programming (OOP) principles by defining several classes for wines, glasses, and billing.`
      This is a good practice to encapsulate related data and functionality.

 2.   Class Design: You've designed classes for Wine, Glass, WineGlass, BeerGlass, and billing, which encapsulate their respective properties and behaviors.

 3.   Constructors: Your classes have constructors for different scenarios, such as default constructors, constructor overloads, and even constructors accepting PowerShell objects.`
      This provides flexibility for creating objects.

 4.   Display Methods: You've implemented Display methods in your classes for presenting object information, which is a good practice for debugging and user interaction.

 5.   Method Overloading: You've overloaded methods like Drink in the WineGlass class to provide different functionalities based on the number of arguments,`
      which is a good use of method overloading.

 6.   Hash Tables: You're using hash tables to accumulate billing data. It's a practical way to store and organize data.

 7.   User Interaction: You're using user input to make choices and decisions, which makes your script interactive and user-friendly.

 8.   Script Organization: You have structured your script using functions, classes, and multiple switch statements to handle different actions based on user input.

 9.   Comments: Your code includes comments for explaining the purpose and functionality of various code blocks, which is helpful for understanding the code.

10.   External Script Invocation: Your script invokes an external script using invoke-expression. Be cautious when invoking external scripts, as it could introduce security risks.

11.   Error Handling: Your script uses error handling with Write-Warning, which is a good practice to inform users about issues.

12.   Looping: You use loops for various purposes, such as counting and iterating through hash tables.

13.   Exit Statements: You're using exit statements to terminate the script based on certain conditions, like user choices.

14.   MessageBox: Your script shows message boxes using [System.Windows.Forms.MessageBox]. This provides a graphical way to interact with users but requires Windows Forms.

15.   Colorful Output: You use colorful output with different foreground colors, which can enhance user experience.

16.   String Formatting: You use string formatting to present data neatly, which is a good practice for user-friendly output.

To make your code more up-to-date and in line with best practices:
    Consider using try/catch blocks for more structured error handling.
    Check for PowerShell version compatibility and consider compatibility with PowerShell Core (6+) if you intend to support it. 
_______________________________________________________________

                                                 #=== Hash_handling_Serviceområde ===#

# Initialize billingHash with example data
$billingHash = @{
    "0-0" = @{ Consumed = 10; Poured = 5;  Billed = 15 }
    "0-1" = @{ Consumed = 8;  Poured = 0;  Billed = 10 }
    "0-2" = @{ Consumed = 12; Poured = 12; Billed = 18 }
    "1-0" = @{ Consumed = 7;  Poured = 7;  Billed = 14 }
    "1-1" = @{ Consumed = 9;  Poured = 0;  Billed = 11 }
    "1-2" = @{ Consumed = 11; Poured = 10; Billed = 20 }
    "2-0" = @{ Consumed = 6;  Poured = 0;  Billed = 8 }
    "2-1" = @{ Consumed = 10; Poured = 15; Billed = 25 }
    "2-2" = @{ Consumed = 14; Poured = 0;  Billed = 16 }
}
#__________
Write-Host("`Wines on the Bill:  ") $billingHash.count
#__________
Write-Host("`nB I L L I N G (LoadingHash)")                
               foreach ($property in 'Consumed', 'Poured', 'Billed')
               {
                    # Get the values for the current property, sort them, and join them into a string
                    $propertyName = "billingHash_${property}:".Substring(0,13)
                    $formattedValues = $billingHash.GetEnumerator() | Sort-Object Name |`
                    ForEach-Object { "$($_.Value.$property)" }                 
                   Write-Host("${propertyName} $($formattedValues -join ' ')")
               }
#__________
$sortedbillingHash = $billingHash.GetEnumerator() |`
                    Sort-Object @{Expression={ [int]$_.Key.Split('-')[0] }; Ascending=$true},`
                                @{Expression={ [int]$_.Key.Split('-')[1] }; Ascending=$true}
$sortedbillingHash
$script:Table=0;$currentWineNumber=0
                    # Iterate through the sortedbillingHash to find a match based on wineNumber
                    foreach ($item in $sortedbillingHash)
                    {
                        $currentKey = $item.Key
                        $currentTableNumber = $currentKey.Split('-')[0]
                        if ($currentTableNumber -eq $script:Table)
                        {
                            $currentWineNumber = $currentKey.Split('-')[1] 
                            # Update the variables $x, $y, and $z with the sorted values
                            if ($currentWineNumber -eq 0)
                            {
                                $x = $item.Value.Consumed
                                $xx = $item.Value.Billed
                                $xxx = $item.Value.Poured
                            }
                        }
                    }
$currentKey;$currentTableNumber;$currentWineNumber;$x;$xx;$xxx;
#__________
 $table0Poured = $billingHash.Keys | Where-Object { $_ -like "0-*" -and $billingHash[$_].Poured -eq 0 }
 $table0 = if ($table0Poured.Count -gt 0) { "1" } else { "0" }
 $array = @($table0)
 $script:out = $array[$script:Table]
 $script:out
 #__________
                    # Check if there are poured values in any of the tables
                    $table0Poured = $billingHash.Keys | Where-Object { $_ -like "0-*" -and $billingHash[$_].Poured -eq 0 }                   # Create text and color variables based on the table status
                    $text0  = if ($table0Poured.Count -gt 0) { "Taken" } else { "Vacant" }
                    $color0 = if ($table0Poured.Count -gt 0) { "red"   } else { "yellow" }
$table0Poured;$text0;$color0
#__________
     foreach ($tableKey in ("0-0"))
     {
        $tableData = $billingHash.Item($tableKey)                               # En række f.eks.  Consumed = 10; Poured = 5;  Billed = 15
       Write-Host($tableKey)

        # Check if $tableData is not null before iterating through it
        if ($null -ne $tableData)
        {
           Write-Host("{0,-30} {1,-15}" -f 'Name', 'Value')                    # Overskrift 'Name', 'Value'

            foreach ($entry in $tableData.GetEnumerator())
            {
                $value = if ($null -eq $entry.Value) { 'N/A' } else { $entry.Value }      # $value kan antage hvert object i rækken value
               Write-Host $value
                $value = if ($null -eq $entry.Name) { 'N/A' } else { $entry.Name }      # $value kan antage hvert object i rækken value
               Write-Host $value
            }
        }
     }
#__________

# Function to check if the table is vacant
function IsTableVacant {
    return $script:Table -in (0, 1, 2)
}
****This function checks if the table is vacant by using the -in operator to see if $script:Table is one of the values (0, 1, 2).
    If the table is vacant, it returns $true; otherwise, it returns $false.

# Function to check if wine is ordered and in sync
function IsWineOrderedAndSynced {
    return ($script:Passed     -eq 1) -and ($script:wines -eq $script:Table)
}
****This function checks if wine is ordered and in sync.
    It returns $true if $script:Passed     is equal to 1 and $script:wines is equal to $script:Table; otherwise, it returns $false.

# Function to handle ordering of tables
function OrderTable {
    if (IsTableVacant) {
       Write-Host "Please order your table"
        $script:Choice = 0
    }
}
****This function orders a table if it is vacant.
    It uses the IsTableVacant function to check if the table is vacant. If it is, it writes a message and sets $script:Choice to 0.

# Function to handle ordering of wine
function OrderWine {
    if (-not (IsWineOrderedAndSynced)) {
       Write-Host "Please order your wine"
        $script:Choice = 17
    }
}
****This function orders wine if it is not ordered and in sync.
    It uses the IsWineOrderedAndSynced function. If wine is not ordered and in sync, it writes a message and sets $script:Choice to 17.

# Service situations
if (0,1,2,3,13,14,15,16,17 -notcontains $script:Choice) {
    if (-not (IsTableVacant)) {
        if (-not (IsWineOrderedAndSynced))  {
            OrderWine
        }
    }
}
****This set of conditions checks service situations based on the value of $script:Choice.
    If $script:Choice is not in the specified values, and the table is not vacant, and wine is not ordered and in sync,
    it calls the OrderWine function.
#> 
<#
                                                  #=== Parameterområde ===#

# Initialize or declare a hashtable to store control values
$ControlValues = @{}

# Function to generate a unique key for the hashtable
function GetControlValuesKey {
    #return "$($script:Table)_$($uniqueCustomerIdentifier)"
    return "$($script:Table)"
}

# Function to store control values
function StoreControlValues {
    $key = GetControlValuesKey
    $ControlValues[$key] = @{
        'Choice' = $script:Choice
        'Table' = $script:Table
        'WineNumber' = $myWineGlass.Wine.Number
        'WinesOnBills' = $billingHash.Count
        'WinesTableLoadOK' = $script:wines
        'Passed' = $script:Passed    
        'WineglassNotOnBillYet' = $myWineGlass.Poured
    }   
    Write-Host "xxxxxxxxxxNOW STOREDxxxxxxxxxxxxxxxxxxxxxxxxe:"
}
 
# Function to retrieve control values
function RetrieveControlValues {
    $key = GetControlValuesKey
    $values = $ControlValues[$key]
    if ($values -ne $null) {
        $script:Choice = $values['Choice']
        $script:Table = $values['Table']
        $myWineGlass.Wine.Number = $values['WineNumber']
        $billingHash.Count = $values['WinesOnBills']
        $script:wines = $values['WinesTableLoadOK']
        $script:Passed     = $values['Passed']
        $myWineGlass.Poured = $values['WineglassNotOnBillYet']
    }    
}

           # Before changing tables, call StoreControlValues          
                    RetrieveControlValues 
                   Write-Host "zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz:"
                    yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy:"      
                    StoreControlValues 

                $ControlValues.keys
                $ControlValues.count 
                $ControlValues.Values
                $ControlValues.Item("0")
               Write-Host("`n")
                $ControlValues.Item("1")
               Write-Host("`n")
                $ControlValues.Item("2")

# _________________________________________*** AI comments on events ***________________________________________________________

 Snippet 1 (Bill and Email Request Event):

    Initializes event script blocks for bill and email requests.
    Defines methods to trigger both bill and email events.
    Registers event handlers for both bill and email requests.
    Triggers the email event.
    Triggers both bill and email events using a custom method.

Snippet 2 (Membership Request Event):

    Simply triggers the membership request event.

There's indeed a noticeable difference in the complexity and length of the code between these two snippets.
The first snippet involves setting up event handlers, defining methods to trigger events, and subscribing to events.
It's more elaborate because it handles both bill and email requests and requires more setup.

# ______________________________________*** BillAndEmail request event ***________________________________________________________ 
                
                [scriptblock]$BillRequestedEvent
                [scriptblock]$EmailRequestedEvent
                [string] $BillRequestedEvent)
                $global:BillRequestedEvent = [System.Management.Automation.PSEventArgs]::Empty 
                # Initialize event script blocks

                $this.BillRequestedEvent = {
                    param($TableNumber, $TotalBill)
                    Write-Host "Bill Requested for Table $TableNumber. Total Bill: $TotalBill"
                }

                $this.EmailRequestedEvent = {
                    param($TableNumber, $TotalBill)
                    Write-Host "Email Requested for Table $TableNumber. Total Bill: $TotalBill"
                } 

                # Member Method to trigger both bill and email events
                [void] RequestBillAndEmail()
                {
                    # Trigger the bill event
                    if ($this.BillRequestedEvent -ne $null) {
                        $this.BillRequestedEvent.Invoke($this.TableNumber, $this.GetCheck())
                    }
                
                    # Trigger the email event
                    if ($this.EmailRequestedEvent -ne $null) {
                        $this.EmailRequestedEvent.Invoke($this.TableNumber, $this.GetCheck())
                    }
                }

                # Member Method to trigger the event when the customer requests the bill
                [void] RequestBill()
                {
                    New-Event -SourceIdentifier $this.BillRequestedEvent -EventArguments @{
                        TableNumber = $this.TableNumber
                        TotalBill   = $this.GetCheck()
                    }
                } 

                # Function to handle the BillRequested event
                function Handle-BillRequestedEvent {
                    param($sender, $eventArgs)
                    Write-Host "Bill requested for table $($eventArgs.TableNumber)"
                    # Your code to handle the bill request event goes here
                }
                
                # Subscribe to the BillRequested event
                Register-EngineEvent -SourceIdentifier "BillRequested" -Action { Handle-BillRequestedEvent }
                
                # Function to handle the EmailRequested event
                function Handle-EmailRequestedEvent {
                    param($sender, $eventArgs)
                    Write-Host "Email requested for table $($eventArgs.TableNumber)"
                    # Your code to handle the email request event goes here
                }
                
                # Subscribe to the EmailRequested event
                Register-EngineEvent -SourceIdentifier "EmailRequested" -Action { Handle-EmailRequestedEvent }  
                 
                # Trigger the EmailRequestedEvent event
                if ($EmailRequestedEvent -ne $null) {
                    $EmailRequestedEvent.Invoke($tableNumber, $totalBilledForTable)
                }

                # Trigger the bill and email events
                $myBilling.RequestBillAndEmail()  

# _________________________________________*** membership request event ***________________________________________________________

                # Trigger the membership request event
                RequestMembership "New member: $email"



<#


#>  
