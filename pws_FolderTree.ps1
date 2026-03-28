
# Get top-level folders
$topLevel = Get-ChildItem -Path "C:\Users\henni\OneDrive" -Directory

# Initialize an array to hold the result
$result = @()

# Loop through each top-level folder and get its subfolders up to one level deep
foreach ($folder in $topLevel) {
    $result += $folder.Name
    $subfolders = Get-ChildItem -Path $folder.FullName -Directory
    foreach ($subfolder in $subfolders) {
        $result += ("    " + $subfolder.Name)
    }
}

# Output the result to a file
$result | Out-File "$basePath\PWS_Treeview.txt"

$result

