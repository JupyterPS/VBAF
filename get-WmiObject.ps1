

#WMI is Microsoft's version of CIM. Microsoft added DCOM and RPC to the CIM management framework along with other small changes and called it the Windows Management Interface WMI
#WMI organizes its classes in a hierarchical namespace. To find useful information, you need to know a Class Name plus the Namespace where it lives
get-WmiObject -List                                                                                                    #get-WmiObject er til lokalopslaglag   
get-WmiObject -Class Win32_SystemDriver| Where-Object -FilterScript {$_.State -eq "Running"}                             
get-WmiObject -Class Win32_LogicalDisk | ForEach-Object -Process {($_.FreeSpace)/1024.0/1024.0}
get-WmiObject -Class Win32_LogicalDisk | Select-Object -Property Name,FreeSpace| get-Member                            #Her er nu PSObject
get-WmiObject -Class Win32_Product -ComputerName . | Format-List -Property Name,InstallDate                            #Formateret liste                                                                                                 #(Lister alle WMI classes) (SKAL køre Powershell 5.1)
get-WmiObject -ClassName Win32_OperatingSystem | Select-Object -Property *   






