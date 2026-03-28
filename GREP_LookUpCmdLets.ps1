Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$SendKeys = [System.Windows.Forms.SendKeys]

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Commandshell'
#$form.Size = New-Object System.Drawing.Size(300,280)
$form.Size = New-Object System.Drawing.Size(300,480)
$form.StartPosition = 'CenterScreen'

$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Point(75,404)
$okButton.Size = New-Object System.Drawing.Size(75,23)
$okButton.Text = 'OK'
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $okButton
$form.Controls.Add($okButton)

#$cancelButton = New-Object System.Windows.Forms.Button
#$cancelButton.Location = New-Object System.Drawing.Point(150,404)
#$cancelButton.Size = New-Object System.Drawing.Size(75,23)
#$cancelButton.Text = 'Cancel'
#$cancelButton.Text = 'Sort'
#$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
#$form.CancelButton = $cancelButton
#$form.Controls.Add($cancelButton)

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(280,20)
$label.Text = 'Hvad du ønsker skal du få, bare klø på:'
$form.Controls.Add($label)

$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(10,40)
$listBox.Size = New-Object System.Drawing.Size(260,20)
#$listBox.Height = 135 
$listBox.Height = 360 

################################################### Uden sort #################################################
#                                             (SS64 = 1) og (PDQ  = 2) 
$A = @(  
'add-appxpackage',
'1add-bitlockerkeyprotector',
'add-computer',
'add-content',
'1add-history',
'2add-kdsrootkey',
'2add-localgroupmember',
'add-member',
'add-mppreference',
'2add-odbcdsn',
'2add-printer',
'2add-printerdriver',
'2add-printerport',
'add-pssnapin',
'add-type',
'2add-vpnconnection',
'add-vpnconnectionroute',
'add-windowscapability',
'1add-windowsfeature',
'1add-windowspackage',
'1backup-gpo',
'1begin',
'1bits',
'1break',
'1catch',
'1checkpoint-computer',
'checkpoint-webapplicationmonitoring',
'clear-content',
'1clear-disk',
'1clear-dnsclientcache',
'1clear-eventlog',
'1clear-history',
'clear-host',
'1clear-item',
'1clear-itemproperty',
'clear-variable',
'compare-object',
'1complete-transaction',
'compress-archive',
'2confirm-securebootuefi',
'1connect-pssession',
'1connect-wsman',
'1continue',
'convertfrom-csv',
'convertfrom-json',
'convertfrom-securestring',
'2convertfrom-string',
'2convertfrom-stringdata',
'convert-path',
'convertto-csv',
'convertto-html',
'convertto-json',
'convertto-securestring',
'convertto-xml',
'copy-item',
'1copy-itemproperty', 
'1disable-bitlocker',
'1disable-computerrestore',
'2disable-netadapterbinding',
'2disable-windowsoptionalfeature',
'1disable-psbreakpoint',
'1disable-psremoting',
'1disable-pssessionconfiguration',
'1disable-windowsoptionalfeature',
'1disable-wsmancredssp',
'1disconnect-pssession',
'1disconnect-wsman',
'1do',
'enable-bitlocker',
'1enable-bitlockerautounlock',
'2enable-netfirewallrule',
'1enable-psbreakpoint',
'enable-psremoting',
'1enable-pssessionconfiguration',
'enable-windowsoptionalfeature',
'enable-wsmancredssp',
'1end',
'enter-pssession',
'1exit',
'exit-pssession',
'expand-archive',
'1export-alias',
'2export-certificate',
'export-clixml',
'1export-console',
'1export-counter',
'export-csv',
'export-formatdata',
'export-modulemember',
'2export-pfxcertificate',
'1export-pssession',
'2export-startlayout',
'2export-windowsdriver',
'2find-module',
'2find-package',
'1for',
'1foreach',
'foreach-object',
'format-custom',
'1format-hex',
'format-list',
'format-table',
'2format-volume',
'format-wide',
'get-acl',
'get-alias',
'2get-appvclientpackage',
'2get-appxpackage',
'get-appxprovisionedpackage',
'get-authenticodesignature',
'get-bitlockervolume',
'get-bitstransfer',
'get-certificate',
'get-childitem',
'1get-cimassociatedinstance',
'1get-cimclass',
'get-ciminstance',
'1get-cimsession',
'get-clipboard',
'get-command',
'get-computerinfo',
'get-computerrestorepoint',
'get-content',
'get-counter',
'get-credential',
'get-culture',
'get-date',
'2get-disk',
'1get-dnsclientcache',
'1get-dnsclientserveraddress',
'1get-dscconfiguration',
'1get-dsclocalconfigurationmanager',
'1get-dscresource',
'get-event',
'get-eventlog',
'1get-eventsubscriber',
'get-executionpolicy',
'get-filehash',
'1get-formatdata',
'get-help',
'get-history',
'get-host',
'get-hotfix',
'2get-installedmodule',
'get-item',
'get-itemproperty',
'get-job',
'get-localgroup',
'2get-localgroupmember',
'get-localuser',
'get-location',
'get-member',
'get-module',
'get-netadapter',
'2get-netadaptervmq',
'2get-netconnectionprofile',
'2get-netfirewallrule',
'get-netipaddress',
'get-netipconfiguration',
'2get-netipinterface',
'get-nettcpconnection',
'2get-package',
'2get-partition',
'get-pfxcertificate',
'2get-physicaldisk',
'2get-pnpdevice',
'get-printer',
'1get-printjob',
'get-process',
'1get-psbreakpoint',
'1get-pscallstack',
'get-psdrive',
'1get-psprovider',
'2get-psrepository',
'get-pssession',
'1get-pssessionconfiguration',
'get-pssnapin',
'get-random',
'get-scheduledjob',
'get-scheduledtask',
'get-scheduledtaskinfo',
'get-service',
'get-smbconnection',
'1get-smbmapping',
'2get-smbopenfile',
'2get-smbserverconfiguration',
'2get-smbsession',
'get-smbshare',
'2get-smbshareaccess',
'get-startapps',
'2get-storagejob',
'get-timezone',
'2get-tlsciphersuite',
'2get-tpm',
'1get-tracesource',
'1get-transaction',
'1get-uiculture',
'get-unique',
'get-variable',
'2get-virtualdisk',
'2get-volume',
'2get-vpnconnection',
'1get-webapplicationmonitoringstatus',
'get-windowscapability',
'1get-windowsfeature',
'get-windowsoptionalfeature',
'1get-windowspackage',
'2get-windowsupdatelog',
'get-winevent',
'get-wmiobject',
'1get-wsmancredssp',
'1get-wsmaninstance',
'grant-smbshareaccess',
'group-object',
'1if',
'1import-alias',
'2import-certificate',
'import-clixml',
'1import-counter',
'import-csv',
'1import-gpo',
'import-module',
'2import-pfxcertificate',
'import-pssession',
'2import-startlayout',
'2initialize-disk',
'2install-module',
'2install-package',
'2install-packageprovider',
'1install-windowsfeature',
'invoke-cimmethod',
'invoke-command',
'invoke-expression',
'1invoke-history',
'invoke-item',
'2invoke-pester',
'invoke-restmethod',
'invoke-webrequest',
'invoke-wmimethod',
'invoke-wsmanaction',
'1join-path',
'1limit-eventlog',
'measure-command',
'measure-object',
'1messagebox',
'2mount-diskimage',
'2mount-windowsimage',
'move-item',
'1move-itemproperty',
'new-alias',
'1new-ciminstance',
'new-cimsession',
'1new-cimsessionoption',
'1new-dscchecksum',
'1new-event',
'new-eventlog',
'new-guid',
'new-item',
'new-itemproperty',
'new-jobtrigger',
'1new-localgroup',
'new-localuser',
'1new-module',
'2new-netfirewallrule',
'2new-netipaddress',
'2new-netlbfoteam',
'2new-netnat',
'2new-netroute',
'new-object',
'2new-partition',
'new-psdrive',
'new-pssession',
'new-pssessionoption',
'new-scheduledtask',
'new-scheduledtaskaction',
'new-scheduledtaskprincipal',
'new-scheduledtasksettingsset',
'new-scheduledtasktrigger',
'2new-selfsignedcertificate',
'new-service',
'new-smbmapping',
'new-smbshare',
'2new-storagepool',
'new-timespan',
'new-variable',
'2new-virtualdisk',
'2new-volume',
'new-webserviceproxy',
'1new-wsmaninstance',
'1new-wsmansessionoption',
'2optimize-volume',
'out-default',
'out-file',
'out-gridview',
'out-host',
'out-null',
'out-printer',
'out-string',
'1param',
'1pause',
'1pop-location',
'1powershell',
'1process',
'push-location',
'read-host',
'receive-job',
'1register-cimindicationevent',
'1register-engineevent',
'register-objectevent',
'2register-psrepository',
'1register-pssessionconfiguration',
'register-scheduledjob',
'register-scheduledtask',
'1register-wmievent',
'remove-appxpackage',
'remove-appxprovisionedpackage',
'1remove-ciminstance',
'1remove-cimsession',
'remove-computer',
'1remove-event',
'1remove-eventlog',
'remove-item',
'remove-itemproperty',
'1remove-job',
'remove-module',
'2remove-netipaddress',
'2remove-physicaldisk',
'2remove-printer',
'1remove-psbreakpoint',
'remove-psdrive',
'remove-pssession',
'1remove-pssnapin',
'1remove-smbmapping', 
'remove-variable',
'1remove-windowscapability',
'1remove-windowspackage',
'remove-wmiobject',
'1remove-wsmaninstance',
'rename-computer',
'1rename-item',
'1rename-itemproperty', 
'2repair-volume',
'2repair-windowsimage',
'reset-computermachinepassword',
'2resize-partition',
'1resolve-dns',
'2resolve-dnsname',
'resolve-path',
'restart-computer',
'restart-service',
'restore-computer',
'1restore-gpo',
'1resume-bitlocker',
'1resume-service',
'1return',
'1run/call',
'2save-module',
'1scheduler',
'select-object',
'select-string',
'select-xml',
'send-mailmessage',
'set-acl',
'set-alias',
'set-authenticodesignature',
'set-clipboard',
'set-content',
'2set-culture',
'set-date',
'2set-disk',
'2set-dnsclientserveraddress',
'set-dsclocalconfigurationmanager',
'set-executionpolicy',
'set-item',
'set-itemproperty',
'1set-localgroup',
'set-localuser',
'set-location',
'set-mppreference',
'2set-netadapter',
'2set-netadaptervmq',
'2set-netconnectionprofile',
'2set-netfirewallprofile',
'2set-netfirewallrule',
'2set-netipaddress',
'2set-netipinterface',
'set-nettcpsetting',
'2set-partition',
'2set-physicaldisk',
'2set-printer',
'1set-psbreakpoint',
'set-psdebug',
'2set-psrepository',
'set-pssessionconfiguration',
'set-scheduledtask',
'set-service',
'2set-smbclientconfiguration',
'2set-smbserverconfiguration',
'set-smbshare',
'set-strictmode',
'set-timezone',
'1set-tracesource',
'set-variable',
'2set-vpnconnection',
'2set-winsystemlocale',
'2set-winuserlanguagelist',
'set-wmiinstance',
'1set-wsmaninstance',
'set-wsmanquickconfig',
'1show-command',
'1show-eventlog',
'1sort-object',
'split-path',
'start-bitstransfer',
'start-dscconfiguration',
'start-job',
'start-process',
'start-scheduledtask',
'start-service',
'start-sleep',
'1start-transaction',
'start-transcript',
'stop-computer',
'1stop-job',
'stop-process',
'stop-service',
'stop-transcript',
'suspend-bitlocker',
'suspend-service',
'1switch',
'tee-object',
'test-computersecurechannel',
'test-connection',
'test-netconnection',
'test-path',
'test-wsman',
'1trace-command',
'1trap',
'1try',
'unblock-file',
'1undo-transaction',
'2uninstall-module',
'2uninstall-package',
'1uninstall-windowsfeature',
'1unregister-event',
'1unregister-pssessionconfiguration',
'unregister-scheduledtask',
'1update-formatdat',
'update-help',
'1update-list',
'update-module',
'update-script',
'1update-typedata',
'1use-transaction',
'1wait-event',
'wait-job',
'wait-process',
'where method',
'where-object',
'1while',
'write-debug',
'write-error',
'write-eventlog',
'write-host',
'2write-information',
'write-object',
'write-output',
'1write-progress',
'1write-verbose',
'1write-warning',
'1zip')

             # If $functionName is provided as an argument, skip listbox and directly set it
             if ($args[0])
             {
                 $cmdletName = $args[0] 
                 if ($cmdletName.Substring(0,1) -eq " ")                        
                 {
                     Write-Host "Cmdlet '$cmdletName' not found."  
                     exit             
                 }                
             }
             else
             {
             
             [void] $listBox.Items.AddRange($A)
             $form.Controls.Add($listBox)
             $form.Topmost = $true
             $result = $form.ShowDialog()

<######################################################  Med sort #################################################
 
                 if ($result -eq [System.Windows.Forms.DialogResult]::CANCEL)
                 {    
                     Add-Type -AssemblyName System.Windows.Forms
                     Add-Type -AssemblyName System.Drawing
                     
                     $form = New-Object System.Windows.Forms.Form
                     $form.Text = 'Commandshell'
                     #$form.Size = New-Object System.Drawing.Size(300,280)
                     $form.Size = New-Object System.Drawing.Size(300,475)
                     $form.StartPosition = 'CenterScreen'
                      
                     $okButton = New-Object System.Windows.Forms.Button
                     #$okButton.Location = New-Object System.Drawing.Point(75,190)
                     $okButton.Location = New-Object System.Drawing.Point(75,404)
                     $okButton.Size = New-Object System.Drawing.Size(75,23)
                     $okButton.Text = 'OK'
                     $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
                     $form.AcceptButton = $okButton
                     $form.Controls.Add($okButton)
                     
                     $cancelButton = New-Object System.Windows.Forms.Button
                     $cancelButton.Location = New-Object System.Drawing.Point(150,404)
                     $cancelButton.Size = New-Object System.Drawing.Size(75,23)
                     #$cancelButton.Text = 'Cancel'
                     $cancelButton.Text = 'Sort'
                     $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
                     $form.CancelButton = $cancelButton
                     $form.Controls.Add($cancelButton)
                     
                     $label = New-Object System.Windows.Forms.Label
                     $label.Location = New-Object System.Drawing.Point(10,20)
                     $label.Size = New-Object System.Drawing.Size(280,20)
                     $label.Text = 'Hvad du ønsker skal du få, bare klø på:'
                     $form.Controls.Add($label)
                     
                     $listBox = New-Object System.Windows.Forms.ListBox
                     $listBox.Location = New-Object System.Drawing.Point(10,40)
                     $listBox.Size = New-Object System.Drawing.Size(260,20)
                     #$listBox.Height = 135 
                     $listBox.Height = 360 
                 
                     $B = $A | Sort-Object -Unique  
                     
                     [void] $listBox.Items.AddRange($B)
                     $form.Controls.Add($listBox)
                     $form.Topmost = $true
                     $result = $form.ShowDialog()
                 }    
#>
             }

             if ($result -eq [System.Windows.Forms.DialogResult]::OK -or ($args[0]))
             {          
                 if ($args[0])
                 {                        
                     $SelectedItem = $cmdletName
                 }
                 else
                 {
                     $SelectedItem = $listBox.SelectedItem 
                 }
             
                 if ($SelectedItem.Substring(0,1) -notin 1,2)                        # begge markereringer, både PDQ og SS64
                 {
                     Start-Process https://www.pdq.com/powershell/$SelectedItem/ 
             
                     $domain = 'html'
                     $x = $SelectedItem + ".$domain"                      
                     Start-Process https://ss64.com/ps/$x  
                 }
                 else
                 {
                     Start-Process https://www.pdq.com/powershell/$SelectedItem/                   
                     Start-Sleep -Seconds 1 
                      
                     if ($SelectedItem.Substring(0,1) -in 1)                         # 1 markerering = minus PDQ
                     {       
                         $SendKeys::SendWait("^w")                                   # Fjerne 404 siden
                         Start-Sleep -Seconds 1   
                                                 
                         $SelectedItem = $SelectedItem -replace '^.', ''  
                         $domain = 'html'
                         $x = $SelectedItem + ".$domain"                 
                         
                         Start-Process https://ss64.com/ps/$x    
                     }
#_ SS64 = 1              
#  PDQ  = 2  
                     else                                                           # 2 markerering = minus SS64
                     {                        
                         $SendKeys::SendWait("^w") 
                         Start-Sleep -Seconds 1    
                                             
                         $SelectedItem = $SelectedItem -replace '^.', '' 
                         Start-Process https://www.pdq.com/powershell/$SelectedItem/ 
                     }
                 }
             
             }
 
             # Close the form
             $form.Dispose()







