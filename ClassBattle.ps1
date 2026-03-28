cls
$global:Monster1
$global:Monster2
Class Monster
{
                 #Data Members
                 [String]$Name
                 [int]$Health
                 [int]$Attack
                 [int]$Defense

                 #Constructor
                 Monster()
                 {
                      Write-Host('Instantiating a Monster object.')
                      $this.Name =  'Generic Monster'
                      $this.Health = 100
                      $this.Attack = 7
                      $this.Defense = 12
                 }

                 #Member Methods
                 Display()
                 {
                      Write-Host("`n")
                      Write-Host('Name: ' + $this.Name)
                      Write-Host('Health: '+ $this.Health)
                      Write-Host('Attack: ' + $this.Attack)
                      Write-Host('Defense: ' + $this.Defense)
                 }
}

Class Godzilla : Monster
{
                 Godzilla()
                 {
                      Write-Host('Instantiating a Godzilla object.')
                      $this.Name =  'Godzilla'
                      $this.Health = 200
                      $this.Attack = 100
                      $this.Defense = 50
                 }


                 #Member Methods
                 Nuclear_Radiactive_Lightning()
                 {
                      Write-Host('Godzilla breathes Radiactive Lightning.')
                 }
}

Class Mothra : Monster
{
                 Mothra()
                 {
                      Write-Host('Instantiating a Mothra object.')
                      $this.Name =  'Mothra'
                      $this.Health = 125
                      $this.Attack = 85
                      $this.Defense = 65
                 }

                 Wing_Flap_Hurricane()
                 {
                      Write-Host("`nMothra flaps wings and makes HURRICANE attack!")
                 }
}

Function create_monsters
{
                 Clear

                 Write-Host("`n         Monster Combat 1.0`n")

                 $global:Monster1 = New-Object Godzilla
                 $global:Monster1.Display()

                 $global:Monster2 = New-Object Mothra
                 $global:Monster2.Display()

                 $Null = Read-Host("`n`nPress ENTER to continue.")
}

Function Monster_Combat
{
                 Clear

                 $MinDammage = 5
                 $MaxDammage = 30
                 $Monster1Turn = $false

                 Clear

                 Write("`nMonster Battle! `n")
                 Write( $global:Monster2.Name +  '  vs. ' +  $global:Monster1.Name + '1')

                 $global:Monster2.Display()
                 $global:Monster1.Display()

                 Write("`nRolling for who gets first attack . . .")

                 [Int] $Chance = Get-Random -Minimum 1 -Maximum (2 + 1)


                 Switch($CHANCE)
                 {
                      1 { $Monster1Turn = $true;  Write("`nMonster 1 gets 1st attack!");}
                      2 { $Monster1Turn = $false; Write("`nMonster 2 gets 1st attack!");}

                 }

                 While($global:Monster1.Health -GT 0 -AND $global:Monster2.Health -GT 0)
                 {
                      If($Monster1Turn)
                      {
                           If($global:Monster1.Health -GT 0 )
                           {
                                Write("`n" + $Global:Monster1.Name + ' attacks ' + $Global:Monster2.Name + '!')
                                $Dammage = Get-Random -Minimum $MinDammage -Maximum ($MaxDammage + 1)

                                Write($global:Monster1.Name + ' generates ' + $Dammage + ' dammage. ')
                                Write('Attack skills add ' + $Global:Monster1.Attack + ' dammage.')
                                $Dammage = $Dammage + $Global:Monster1.Attack

                                Write('Total dammage generated = ' + $Dammage)

                                Write($Global:Monster2.Name + ' defends subtracting ' +
                                      $Global:Monster2.Defense +  ' from dammage.')

                                $Dammage = $Dammage - $Global:Monster2.Defense

                                Write('After final attack ' + $Global:Monster1.Name + ' does ' +
                                              $Dammage + ' total dammage to ' + $Global:Monster2.name)

                                #Prevent negative dammage which would add health to opponent
                                If($Dammage -LT 0) { $Dammage = 0 }

                                $Global:Monster2.Health = $Global:Monster2.Health - $Dammage

                                $Monster1Turn = $False
                           }
                           else
                                {
                                     Write($Global:Monster1.Name + ' cannot attack on account of being DEAD.')
                                }
                      }
                      else
                      {

                           If ($Global:Monster2.Health -GT 0 )
                           {
                               Write("`n" + $Global:Monster2.Name + ' attacks ' + $Global:Monster1.Name + '!')
                                $Dammage = Get-Random -Minimum $MinDammage -Maximum ($MaxDammage + 1)

                                Write($global:Monster2.Name + ' generates ' + $Dammage + ' dammage. ')
                                Write('Attack skills add ' + $Global:Monster2.Attack + ' dammage.')
                                $Dammage = $Dammage + $Global:Monster2.Attack

                                Write('Total dammage generated = ' + $Dammage)

                                Write($Global:Monster1.Name + ' defends subtracting ' +
                                      $Global:Monster1.Defense +  ' from dammage.')

                                $Dammage = $Dammage - $Global:Monster1.Defense

                                Write('After final attack ' + $Global:Monster2.Name + ' does ' +
                                              $Dammage + ' total dammage to ' + $Global:Monster1.name)

                                #Prevent negative dammage which would add health to opponent
                                If($Dammage -LT 0) { $Dammage = 0 }

                                $Global:Monster1.Health = $Global:Monster1.Health - $Dammage

                                $Monster1Turn = $True
                           }
                           else
                                {
                                     Write($Global:Monster2.Name + ' was terminated with extreme prejudice.')
                                }
                      }

                      Write("`n$Global:Monster1.Name HEALTH = " + $Global:Monster1.Health)
                      Write("`n$Global:Monster2.Name HEALTH = " + $Global:Monster2.Health)

                      Start-Sleep -s 4
                 }

                 If ($Global:Monster1.Health -GT 0)
                 {
                      Write("`n" + $Global:Monster1.Name + ' wins the tournament!')
                 }
                 else
                 {
                      Write("`n" + $Global:Monster2.Name + ' wins the tournament!')
                 }
}
#--------- Invocations --------
create_monsters
monster_combat






