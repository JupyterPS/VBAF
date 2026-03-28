get-help get-childitem -examples 

$files = Get-ChildItem -path $basePath 

Get-Childitem –Path C:\  -Include *_TXT.ps1 -File -Recurse -ErrorAction SilentlyContinue    # finder filer gemt hvor du ikke havde tænkt på

#Get-Childitem –Path C:\  -Include *.ps1 -File -Recurse -ErrorAction SilentlyContinue       # Se hvilke TXT filer der findes og om de skal hægtes på 







