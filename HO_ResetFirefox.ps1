<#

Start Firefox
Press ALT og venstre klik help og klik på more troubleshooting info og REFRESH Firefox   
 
Venstre klik på højre 3 streger i hjørne og klik på settings 
Indsæt https://images4.alphacoders.com/285/28544.jpg  Den smalle   
Delete 2 x felter i Privacy and security


Højreklik på samme 3 streger
Customize toolbar
fjern icon i venste øverste hjørne

Check at extensions er på plads Addblocker

#> 

# Define the path to the Firefox profile
$firefoxProfilePath = "$env:APPDATA\Mozilla\Firefox\Profiles"

# Get the profile directory (assuming there's only one profile)
$profileDir = Get-ChildItem -Path $firefoxProfilePath -Directory | Select-Object -First 1

# Define the path to prefs.js
$prefsFilePath = Join-Path -Path $profileDir.FullName -ChildPath "prefs.js"

# Check if prefs.js exists
if (Test-Path $prefsFilePath) {
    # Create a backup of prefs.js
    Copy-Item -Path $prefsFilePath -Destination "$prefsFilePath.bak"

    # Define the preferences to set
    $preferences = @(
        'user_pref("media.hardwaremediakeys.enabled", false);',
        'user_pref("browser.tabs.tabmanager.enabled", false);',
        'user_pref("unified", false);',
        'user_pref("extensions.unifiedExtensions.enabled", false);',
        'user_pref("network.protocol-handler.external.mailto", false);',
        'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);'
    )

    # Append the preferences to prefs.js
    Add-Content -Path $prefsFilePath -Value $preferences
    Write-Host "Preferences have been set successfully."
} else {
    Write-Host "prefs.js file not found."
}

#_________________________________________________________________________________________________
# Hvis ikke fundet så kør dette først

    # Define the preferences to set
    $preferences = @(
        'user_pref("media.hardwaremediakeys.enabled", false);',
        'user_pref("browser.tabs.tabmanager.enabled", false);',
        'user_pref("unified", false);',
        'user_pref("extensions.unifiedExtensions.enabled", false);',
        'user_pref("network.protocol-handler.external.mailto", false);',
        'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);'
    )

    # Append the preferences to prefs.js
    Add-Content -Path $prefsFilePath -Value $preferences