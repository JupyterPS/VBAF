# Release Process

How VBAF versions are prepared, tested and published to PowerShell Gallery.

## Version Numbering

VBAF uses semantic versioning: MAJOR.MINOR.PATCH

- MAJOR: breaking API changes
- MINOR: new enterprise pillars or significant features
- PATCH: bug fixes

Current: v4.0.0

## Release Checklist

Before publishing a new version:

1. Update version in VBAF.psd1
```powershell
ModuleVersion = '4.1.0'
```

2. Update version references in README.md

3. Run all tests
```powershell
. .\VBAF.LoadAll.ps1
```

4. Test install from clean session
```powershell
Remove-Module VBAF -ErrorAction SilentlyContinue
Import-Module VBAF
. .\VBAF.LoadAll.ps1
```

5. Commit and tag
```powershell
git add .
git commit -m "Release v4.1.0 — Phase 28 NetworkTrafficManager"
git tag v4.1.0
git push origin master --tags
```

6. Publish to PSGallery
```powershell
Copy-Item VBAF.psd1 VBAF\VBAF.psd1 -Force
Publish-Module -Path ".\VBAF" -NuGetApiKey "YOUR_KEY" -Verbose
```

7. Verify on PSGallery
```powershell
Find-Module VBAF
```

## Hotfix Process

For urgent bug fixes:
1. Fix on master branch
2. Increment PATCH version
3. Follow release checklist from step 3

