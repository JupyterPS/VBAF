# Progress bar
Add-Type -AssemblyName PresentationFramework
[System.Windows.Forms.MessageBox]::Show('Would you like to play a game on your computer?','Game input','YesNoCancel')
for ($i = 0; $i -le 100; $i+=20)
{
    Write-Progress -Activity "Search in Progress" -Status "$i% Complete:" -PercentComplete $i;
    Start-sleep 1
}
[System.Windows.MessageBox]::Show('Sorry, I cannot find it','Game input','YesNoCancel','Error')






