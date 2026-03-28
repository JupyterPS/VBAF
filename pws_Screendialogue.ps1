function show { 
      
    param ( $str )                                                             
  
    Write-Host "Hello $str"     
} 
   
$str = Read-Host -Prompt 'Enter a String'
  
show ( $str )
Write-Host "Hello string1 $str"    






