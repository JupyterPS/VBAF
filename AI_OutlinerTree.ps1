# Define a function to show the menu
function Show-Menu {
    Write-Host "=== Cortex Tree Outliner ==="
    Write-Host "[G] Generate Tree from Manuscript (Paste)"
    Write-Host "[D] Display Tree (Outline View)"
    Write-Host "[S] Save Tree to File"
    Write-Host "[Q] Quit"
    Write-Host "============================="
}

# Function to generate the tree from the manuscript input
function Generate-Tree {
    $global:tree = ""

    Write-Host "Paste your manuscript (use indentation for structure)."
    Write-Host "Press Enter on a blank line to finish:"

    $inputLines = @()
    while ($true) {
        $line = Read-Host
        if ($line -eq "") { break }  # End input when user presses Enter on a blank line
        $inputLines += $line
    }

    # Convert input to a tree-like structure based on indentation
    $treeLines = @()
    $previousIndentLevel = 0
    $currentIndentLevel = 0

    foreach ($line in $inputLines) {
        # Count spaces at the start of the line to determine indentation level
        $currentIndentLevel = 0
        if ($line -match "^\s*") {
            $currentIndentLevel = $line.IndexOf($line.TrimStart())
        }
        
        if ($currentIndentLevel -gt $previousIndentLevel) {
            $treeLines += "  " * $currentIndentLevel + $line.Trim()
        } else {
            $treeLines += "  " * $currentIndentLevel + $line.Trim()
        }

        $previousIndentLevel = $currentIndentLevel
    }

    $global:tree = $treeLines -join "`n"
    Write-Host "Tree successfully created."
}

# Function to display the tree
function Display-Tree {
    if ($global:tree) {
        Write-Host "Displaying tree in outline view:"
        Write-Host $global:tree
    } else {
        Write-Host "No tree generated yet."
    }
}

# Function to save the tree to a file
function Save-Tree {
    if ($global:tree) {
        $filePath = Read-Host "Enter file path to save the tree"
        $global:tree | Out-File -FilePath $filePath
        Write-Host "Tree saved to $filePath"
    } else {
        Write-Host "No tree generated yet."
    }
}

# Main loop
while ($true) {
    Show-Menu
    $choice = Read-Host "Choose an option"

    switch ($choice.ToLower()) {
        'g' {
            Generate-Tree
        }
        'd' {
            Display-Tree
        }
        's' {
            Save-Tree
        }
        'q' {
            Write-Host "Goodbye!"
            break
        }
        default {
            Write-Host "Invalid option, please try again."
        }
    }
}


