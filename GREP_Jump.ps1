function Jump-To-GUISectionISE {
    param (
        [int]$Num  
    )    

    switch ($Num) {
        1 {
            $ScriptPath = "C:\Users\henni\OneDrive\WindowsPowerShell\GREP_Tbox_1.ps1"
            $regex = '^\s*#\s*[A-Z]\.\s+'
        }
        2 {
            $ScriptPath = "C:\Users\henni\OneDrive\WindowsPowerShell\GREP_Tbox_2.ps1"
            $regex = '^\s*#\s*[A-Z]\.\s+'
        }
        3 {
            $ScriptPath = "C:\Users\henni\OneDrive\WindowsPowerShell\GREP_Tbox_3.ps1"
            $regex = '^\s*#\s*[A-Z]\.\s+'
        }
        8 {
            $ScriptPath = "C:\Users\henni\OneDrive\WindowsPowerShell\GREP_Tbox_8.ps1"
            $regex = '^\s*#\s*-'
        }
        15 {
            $ScriptPath = "C:\Users\henni\OneDrive\WindowsPowerShell\GREP_Tbox_15.ps1"
            $regex = '^\s*#\s*Powershell GUI Forms and Components\s*-\s*\d{2}\s+.*$'
        }
        18 {
            $ScriptPath = "C:\Users\henni\OneDrive\WindowsPowerShell\OO3_Method.ps1"
            $regex = '^\s*#\s*_'
        }
        19 {
            $ScriptPath = "C:\Users\henni\OneDrive\WindowsPowerShell\OO5_ClassConstructor.ps1"
            $regex = '^\s*#\s*_'
        }
        20 {
            $ScriptPath = "C:\Users\henni\OneDrive\WindowsPowerShell\OO9_OOP_Definitions.ps1"
            $regex = '^\s\*\s{2}'
        }
        21 {
            $ScriptPath = "C:\Users\henni\OneDrive\WindowsPowerShell\Enotek.ps1"
            $regex = '^# _'
        }
        22 {
            $ScriptPath = "C:\Users\henni\OneDrive\WindowsPowerShell\Company4.ps1"
            $regex = '^# _'
        }
        23 {
            $ScriptPath = "C:\Users\henni\OneDrive\WindowsPowerShell\CompanyOperations.ps1"
            $regex = '^# _'
        }
        default {
            Write-Warning "Unknown selection number: $Num"
            return
        }
    }   
    
    if (-not (Test-Path $ScriptPath)) {
        [System.Windows.Forms.MessageBox]::Show("File not found:`n$ScriptPath", "Error", 'OK', 'Error')
        return
    }

    Add-Type -AssemblyName PresentationFramework

    $XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Jump to Section" Height="630" Width="900"
        WindowStartupLocation="CenterScreen">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <TextBlock Text="Jump to GUI Section" FontSize="18" FontWeight="Bold" 
                   HorizontalAlignment="Center" Grid.Row="0" Margin="0,0,0,10"/>

        <ListBox Name="SectionList" Grid.Row="1" FontSize="14" Margin="0,0,0,10" />

        <Button Content="Jump" Name="JumpBtn" Width="80" Height="30" Grid.Row="2" HorizontalAlignment="Center"/>
    </Grid>
</Window>
"@

    $xmlReader = [System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($XAML)))
    $window = [Windows.Markup.XamlReader]::Load($xmlReader)

    # Read file and match lines
    $lines = Get-Content $ScriptPath 
    $sections = @()

    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match $regex) {
            $sections += [PSCustomObject]@{
                No         = $lines[$i].Trim()
                LineNumber = $i + 1
            }
        }
    }

    $listBox  = $window.FindName("SectionList")
    $jumpBtn  = $window.FindName("JumpBtn")

    $listBox.ItemsSource = $sections

    # Jump function (shared for button & double-click)
    $jumpAction = {
        $selection = $listBox.SelectedItem
        if ($selection) {
            if ($psISE) {
                $openFile = $psISE.CurrentPowerShellTab.Files | Where-Object { $_.FullPath -eq $ScriptPath }
                if (-not $openFile) {
                    $openFile = $psISE.CurrentPowerShellTab.Files.Add($ScriptPath)
                }

                if ($openFile) {
                    # Dynamically get line length to prevent out-of-range exception
                    $lineText = $lines[$selection.LineNumber - 1]
                    $lineLength = $lineText.Length

                    $openFile.Editor.SetCaretPosition($selection.LineNumber, 1)
                    $openFile.Editor.Select($selection.LineNumber, 1, $selection.LineNumber, $lineLength + 1)
                }
            }
            $window.Close()  # Close after jump
        }
    }

    # Button click triggers jump
    $jumpBtn.Add_Click($jumpAction)

    # Double-click triggers jump
    $listBox.Add_MouseDoubleClick($jumpAction)

    $window.ShowDialog() | Out-Null
}
