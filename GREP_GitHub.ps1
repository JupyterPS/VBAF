# Replace with your personal access token
$token = "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"

# Define the search term
$searchTerm = "DoWhile"

# GitHub API URL for code search
$url = "https://api.github.com/search/code?q=$searchTerm+in:file+language:PowerShell"

# Set headers with authorization token
$headers = @{
    "Authorization" = "token $token"
    "User-Agent" = "PowerShell-GitHub-Integration"
}

# Perform the API request
$response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get

# Display the results
$response.items | ForEach-Object {
    Write-Host "Repo: $($_.repository.full_name)"
    Write-Host "File: $($_.path)"
    Write-Host "Snippet: $($_.name)"
    Write-Host "URL: $($_.html_url)"
    Write-Host ""
}
