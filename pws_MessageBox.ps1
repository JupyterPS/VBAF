[System.Windows.MessageBox] | Get-Member  -static      #lister methods (uden static kan man ikke se SHOW)

[System.Windows.MessageBox]::Show('Would you like to play a game?','Game input','YesNoCancel')
for ($i = 0; $i -le 100; $i+=20)
{
    Write-Progress -Activity "Search in Progress" -Status "$i% Complete:" -PercentComplete $i;
    Start-sleep 1
}
[System.Windows.MessageBox]::Show('I cannot find your computer!','Katastrofe','YesNoCancel','Error')






