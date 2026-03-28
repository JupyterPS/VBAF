<#
GREB in .NET:

Yes, .NET provides several powerful libraries and tools that you can use to search through directories and files
to find specific content.
One of the most commonly used libraries for this purpose is the System.IO namespace, which includes classes for handling file
and directory operations.

Here’s a breakdown of how you can achieve a similar functionality using .NET:
1. Searching Directories for Files Containing a Specific Word

To search through directories and find files that contain a specific word, you can use the Directory and File classes
along with regular expressions or simple string search methods.

Here's an example of a PowerShell script that leverages .NET to search for a specific word in all files within a directory:
#>

param (
    [string]$searchWord,
    [string]$directoryPath
)

# Check if parameters are provided
if (-not $searchWord) {
    Write-Host "Error: Search word is required."
    exit
}

if (-not $directoryPath) {
    Write-Host "Error: Directory path is required."
    exit
}

# Validate directory path
if (-not (Test-Path -Path $directoryPath -PathType Container)) {
    Write-Host "Error: The specified directory path '$directoryPath' is not valid."
    exit
}

# Function to search for a word in a file
function Search-InFile {
    param (
        [string]$filePath,
        [string]$word
    )

    $fileContent = Get-Content -Path $filePath
    $linesWithWord = @()

    for ($i = 0; $i -lt $fileContent.Length; $i++) {
        if ($fileContent[$i] -match $word) {
            $linesWithWord += $i + 1  # Store line number as 1-based
        }
    }

    if ($linesWithWord.Count -gt 0) {
        return [PSCustomObject]@{
            FilePath = $filePath
            Lines    = $linesWithWord
        }
    } else {
        return $null
    }
}

# Function to search for a word in all files within a directory
function Search-InDirectory {
    param (
        [string]$directory,
        [string]$word
    )

    $results = @()
    $files = [System.IO.Directory]::GetFiles($directory, "*.*", [System.IO.SearchOption]::AllDirectories)

    foreach ($file in $files) {
        $result = Search-InFile -filePath $file -word $word
        if ($result -ne $null) {
            $results += $result
        }
    }

    return $results
}

# Perform the search
$searchResults = Search-InDirectory -directory $directoryPath -word $searchWord

# Output the results
if ($searchResults.Count -eq 0) {
    Write-Host "No matches found for '$searchWord' in directory '$directoryPath'."
} else {
    $searchResults | Format-Table -Property FilePath, Lines

    # Get and display the specific line for each result
    foreach ($result in $searchResults) {
        foreach ($lineNumber in $result.Lines) {
            $lineContent = Get-Line -path $result.FilePath -line $lineNumber
            Write-Host "File: $($result.FilePath)"
            Write-Host "Line: $lineNumber - $lineContent"
        }
    }
}

# Function to get a specific line from a file
function Get-Line {
    param (
        [string]$path,
        [int]$line
    )

    $content = Get-Content -Path $path
    return $content[$line - 1]  # Adjust for zero-based index
}

# Get and display the specific line
$lineContent = Get-Line -path $filePath -line $lineNumber
Write-Host "File: $filePath"
Write-Host "Line: $lineNumber $lineContent"
#____________________________________________________________________
# Define the search parameters
$searchWord = "Error"  # The word you want to search for
$directoryPath = "C:\Logs"  # The directory where you want to search

# Check if parameters are provided
if (-not $searchWord) {
    Write-Host "Error: Search word is required."
    exit
}

if (-not $directoryPath) {
    Write-Host "Error: Directory path is required."
    exit
}

# Validate directory path
if (-not (Test-Path -Path $directoryPath -PathType Container)) {
    Write-Host "Error: The specified directory path '$directoryPath' is not valid."
    exit
}

# Function to search for a word in a file
function Search-InFile {
    param (
        [string]$filePath,
        [string]$word
    )

    $fileContent = Get-Content -Path $filePath
    $linesWithWord = @()

    for ($i = 0; $i -lt $fileContent.Length; $i++) {
        if ($fileContent[$i] -match $word) {
            $linesWithWord += $i + 1  # Store line number as 1-based
        }
    }

    if ($linesWithWord.Count -gt 0) {
        return [PSCustomObject]@{
            FilePath = $filePath
            Lines    = $linesWithWord
        }
    } else {
        return $null
    }
}

# Function to get a specific line from a file
function Get-Line {
    param (
        [string]$path,
        [int]$line
    )
    return (Get-Content -Path $path)[$line - 1]  # Convert to 0-based index
}

# Function to search for a word in all files within a directory
function Search-InDirectory {
    param (
        [string]$directory,
        [string]$word
    )

    $results = @()
    $files = [System.IO.Directory]::GetFiles($directory, "*.*", [System.IO.SearchOption]::AllDirectories)

    foreach ($file in $files) {
        $result = Search-InFile -filePath $file -word $word
        if ($result -ne $null) {
            $results += $result
        }
    }

    return $results
}

# Perform the search
$searchResults = Search-InDirectory -directory $directoryPath -word $searchWord

# Output the results
if ($searchResults.Count -eq 0) {
    Write-Host "No matches found for '$searchWord' in directory '$directoryPath'."
} else {
    foreach ($result in $searchResults) {
        Write-Host "File: $($result.FilePath)"
        foreach ($lineNumber in $result.Lines) {
            $lineContent = Get-Line -path $result.FilePath -line $lineNumber
            Write-Host "Line: $lineNumber - $lineContent"
        }
        Write-Host "-----------------------------"
    }
}







