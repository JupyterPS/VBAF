get-process | where-object {$_.Handles -gt 150} | sort-object -property id, name, cpu






