#CIM is an extensible, object-oriented data model that contains information about different parts of an enterprise, maintained by the Distributed Management Task Force (DMTF)
get-CimInstance win32_service | where-object {$_.Name -eq 'Schedule'} | format-list Name, Description                  #get-CimInstance er til serveropslag 






