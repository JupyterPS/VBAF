# Make PowerShell Disappear
$windowcode = '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);'
$asyncwindow = Add-Type -MemberDefinition $windowcode -name Win32ShowWindowAsync -namespace Win32Functions -PassThru
$process = Get-Process -PID $pid
$null = $asyncwindow::ShowWindowAsync($process.MainWindowHandle, 0)

#Closing the application
$window.Add_Closed({
$null = $asyncwindow::ShowWindowAsync(($process).MainWindowHandle, 3)
$window.Add_Closing({[System.Windows.Forms.Application]::Exit()})
#[System.Windows.Forms.Application]::Exit();
})
$window.Add_Closing({[System.Windows.Forms.Application]::Exit()})






