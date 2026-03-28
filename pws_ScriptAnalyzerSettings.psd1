Invoke-ScriptAnalyzer -Path "$basePath\Enotek.ps1" -Settings "$basePath\pwsScriptAnalyzerSettings.psd1"

@{
   Severity=@('Error','Warning')
   ExcludeRules=@('PSAvoidUsingCmdletAliases')
  }

