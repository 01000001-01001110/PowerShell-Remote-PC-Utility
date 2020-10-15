
#Remote Computer Utility
#By: Alan Newingham
#Date: 10/13/2020
#Multiple remote computer commands in an easy to use tool.
        #Services: Remote PC Services and whether running or stopped
        #Processes: Remote PC processes
        #Drives: Drive information for remote PC
        #OS_Info: Information including the last reboot from remote PC
        #Signed_In: Get currently signed-in user on remote PC
        #Hotfix_Info: Get the list of current Hotfixes installed by KB#
        #Time: Get current time on remote PC
        #Ping: Ping remote PC
        #Stats: Get System Statistics from remote PC
        #BIOS_Info: Gets bios information from remote PC
        #Rmt_Asst: opens remote assist tool with PC name already applied.
        #User_Profile: Get the remote PC, and logged on user, then counts the drive space used by logged on user profile
        #RestartPC: Restarts the remote PC
#Version 0.0.1 
  #Release Date: 10/13/2020
  #updated script with try/catch to remove "garble" from the output.
  #remote assist is still flaky
  #User profile needs tweaking right now it grabs the current logged on user, and runs a get content on their profile directory to get the size, then "does math" to get the drive space used in MB. 
  #During development my system updated and I had to add Add-Type -AssemblyName PresentationFramework for everything to stop failing. Not sure what happened there.
  #Fairly simple I replicated what worked once throughout every button in this script. Worked well. 
#Version 0.0.2
  #Release Date: 10/14/2020
  #Changes: Modified the OS info button to  Invoke-Command -ComputerName $Computername -Credential sfbosaa\anewingham -ScriptBlock { Get-CimInstance -ClassName Win32_OperatingSystem | select-object CSName, Caption, CSDVersion, OSType, LastBootUpTime, ProductType }
    #Invoke command works much better with no error, and I changed the WMI query to CIM as WMI shouldn't be used anymore. 
  #Changed the orientation of buttons to get ready to increase window size and re-orient.
  #Changed the OS Info button to output this data to a popup window as the formatting of the data was not conducive to migrating to output datagrid.
  #Replaced the text view with datagrid
    #This was a lot bigger of a task than I initially anticipated. 
  #Increasing size of tool to 450x700 to accomodate new tools being added. 
  #Initiated a few button configs to run Invoke-Command
  #Initiated a few queries to make use of pssession 
  #Added both the computer search bar and output windows to anchor to the left of the window
    #This was done to expand the gridview window in case there is data that expands past the 700px I have the window set for. 
  #Moved first buttons down a bit from the top of the group box
    #My opinion it does not feel so crowded at the top of the application now.
  #Added a Fix updates button. This creates a new PSSession to the computer and runs the commands to reset the Windows Update Components. 
  #Issues: 
    #Having an issue with the GridView component.
    #Using it where I can, until I can find out why the errors like this happen, and how to fix them WARNING: Exception setting "ItemsSource": "Cannot convert value "10/14/2020 1:25:27 PM" to type "System.Collections.IEnumerable". Error: "Invalid cast from 'System.DateTime' to 'System.Collections.IEnumerable'.""
  
  Add-Type -AssemblyName PresentationFramework
  [xml]$XAML  = @"
  <Window  xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
  xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
  xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
  xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
  xmlns:local="clr-namespace:MyFirstWPF"
  Title="PowerShell Remote Computer Utility" Height="450"  Width="700">
  <Grid>
  <GroupBox  x:Name="Actions" Header="Actions"  HorizontalAlignment="Left" Height="400"  VerticalAlignment="Top" Width="90" Margin="0,11,0,0">
  <StackPanel>
                  <Label  />
                  <Button  x:Name="remoteOS_btn" Content="OS Info"/>
                  <Button  x:Name="login_btn" Content="Signed In"/>
                  <Button  x:Name="Drives_btn" Content="Drives"/>
                  <Button  x:Name="Hotfix_btn" Content="Hotfix Info"/>
                  <Button  x:Name="Time_btn" Content="Time"/>
                  <Button  x:Name="Ping_btn" Content="Ping"/>
                  <Button  x:Name="Stats_btn" Content="Stats"/>
                  <Button  x:Name="BIOS_btn" Content="BIOS Info"/>
                  <Button  x:Name="NetworkInfo_btn" Content="Network Info"/>
                  <Button  x:Name="Services_btn" Content="Services"/>
                  <Button  x:Name="rmt_btn" Content="Rmt Asst"/>
                  <Button  x:Name="Processes_btn" Content="Processes"/>
                  <Button  x:Name="storage_btn" Content="User Profile"/>
                  <Button  x:Name="Updates_btn" Content="Force Updates"/>
                  <Button  x:Name="FixUpdates_btn" Content="Fix Updates"/>
                  <Button  x:Name="Ladmin_btn" Content="Local Admins"/>
                  <Label  />
                  <Label  />
                  <Label  />
                  <Label  />
                  <Label  />
                  <Label  />
                  <Label  />
                  <Button  x:Name="RestartPC_btn" Content="RestartPC"/>
      </StackPanel>
  </GroupBox>
  <GroupBox  x:Name="Computername" Header="Computername"  HorizontalAlignment="Stretch" Margin="92,11,0,0"  VerticalAlignment="Top" Height="45"  Width="auto">
  <TextBox  x:Name="InputBox_txtbx" TextWrapping="Wrap"/>            
  </GroupBox>
  <GroupBox  x:Name="Results" Header="Results"  HorizontalAlignment="Stretch" Margin="92,61,0,0"  VerticalAlignment="Top" Height="348"  Width="auto">
  <DataGrid  x:Name="Output_dtgrd" AlternatingRowBackground = 'LightBlue'  AlternationCount='2' CanUserAddRows='False'/>
  </GroupBox>
    </Grid>
  </Window>
"@


  $reader=(New-Object System.Xml.XmlNodeReader  $xaml)

    $Window=[Windows.Markup.XamlReader]::Load(  $reader )


  #Connect to Controls 

    $xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]")  | ForEach {

    New-Variable  -Name $_.Name -Value $Window.FindName($_.Name) -Force

    }


  #region Events 

    $Processes_btn.Add_Click({
        If (-NOT ([string]::IsNullOrEmpty($InputBox_txtbx.Text)))  {
          $Computername  = $InputBox_txtbx.Text
          Write-Verbose  "Gathering processes from $Computername"  -Verbose
              Try  {
                  $Processes  = Get-CimInstance Win32_Process -ComputerName  $Computername
                  $Output_dtgrd.ItemsSource = $Processes
              }
              Catch  {
                  Write-Warning  $_
                  }
          }
    })


  $Drives_btn.Add_Click({

    If (-NOT ([string]::IsNullOrEmpty($InputBox_txtbx.Text)))  {
      $Computername  = $InputBox_txtbx.Text
      Write-Verbose  "Gathering drives from $Computername"  -Verbose
      Try  {
          $Drives  = Get-CimInstance -ComputerName $Computername -ClassName Win32_LogicalDisk -Filter "DriveType=3" 
          $Output_dtgrd.ItemsSource = $Drives
      }
      Catch  {
          Write-Warning  $_
      }
    }
    })


  $Services_btn.Add_Click({
    If (-NOT ([string]::IsNullOrEmpty($InputBox_txtbx.Text)))  {
      $Computername  = $InputBox_txtbx.Text
      Write-Verbose  "Gathering services Information from $Computername"  -Verbose
      Try  {
          $Services  = Invoke-Command -ComputerName $Computername -ScriptBlock { Get-Service }
          $Output_dtgrd.ItemsSource = $Services
      }
      Catch  {
          Write-Warning  $_
      }
    }
    })
    

  $remoteOS_btn.Add_Click({
    
    If (-NOT ([string]::IsNullOrEmpty($InputBox_txtbx.Text)))  {
    $Computername  = $InputBox_txtbx.Text
    Write-Verbose  "Gathering remote OS information from $Computername"  -Verbose
          Try  {
      $Command = Invoke-Command -ComputerName $Computername -ScriptBlock { Get-CimInstance -ClassName Win32_OperatingSystem | Format-List <#| select-object CSName, Caption, CSDVersion, OSType, LastBootUpTime, ProductType#> }
      $Command = $Command | Format-Table
      $Command = $Command | Out-String
      [System.Windows.MessageBox]::Show($Command)
      #$Output_dtgrd.ItemsSource = $Command
      }
      Catch  {
          Write-Warning  $_
      }
    }
    })


  $login_btn.Add_Click({
    If (-NOT ([string]::IsNullOrEmpty($InputBox_txtbx.Text)))  {
      $Computername  = $InputBox_txtbx.Text
      Write-Verbose  "Getting currently logged in user on $Computername"  -Verbose
          Try  {
            $currentLogin = New-Object -TypeName "System.Collections.Generic.List[System.String]"
              $currentLogin  = Get-CimInstance -ComputerName $Computername -ClassName Win32_ComputerSystem | Select-Object UserName 
              $currentLogin = $currentLogin | Out-String
              [System.Windows.MessageBox]::Show($currentLogin)
          }
          Catch  {
              Write-Warning  $_
          }
    }
    })


  $Hotfix_btn.Add_Click({
      If (-NOT ([string]::IsNullOrEmpty($InputBox_txtbx.Text)))  {
          $Computername  = $InputBox_txtbx.Text
          Write-Verbose  "Getting Hotfix Information for $Computername"  -Verbose
          Try  {
              $UGP  = Get-CimInstance -ComputerName $Computername -ClassName Win32_QuickFixEngineering
              $Output_dtgrd.ItemsSource = $UGP
          }
          Catch  {
              Write-Warning  $_
          }
      }
    })


    $Ping_btn.Add_Click({
      If (-NOT ([string]::IsNullOrEmpty($InputBox_txtbx.Text)))  {
          $Computername  = $InputBox_txtbx.Text       
          Write-Verbose  "Pinging $Computername"  -Verbose
              Try  {
                  $testcon  = Test-Connection -ComputerName $Computername -Count 4 -Delay 2 -TTL 255 -BufferSize 256 -ThrottleLimit 32 
                  $Output_dtgrd.ItemsSource = $testcon
              }
              Catch  {
                  Write-Warning  $_
              }
      }
  })


    $Stats_btn.Add_Click({
        If (-NOT ([string]::IsNullOrEmpty($InputBox_txtbx.Text)))  {
          $Computername  = $InputBox_txtbx.Text
          Write-Verbose  "Gathering Statistics from $Computername"  -Verbose
              Try  {
                  $Stats1  = Get-CimInstance -ClassName Win32_ComputerSystem -ComputerName $Computername
                  [System.Windows.MessageBox]::Show($Stats1)
              }
              Catch  {
                  Write-Warning  $_
                  }
          }
    })


    $Time_btn.Add_Click({
        If (-NOT ([string]::IsNullOrEmpty($InputBox_txtbx.Text)))  {
          $Computername  = $InputBox_txtbx.Text
          Write-Verbose  "Getting Time Information from $Computername"  -Verbose
              Try  {
                  $Time  = invoke-command -ComputerName $Computername -ScriptBlock {get-date} 
                  $Time = $Time | Out-String
                  [System.Windows.MessageBox]::Show($Time)
              }
              Catch  {
                  Write-Warning  $_
                  }
          }
    })


    $storage_btn.Add_Click({
        If (-NOT ([string]::IsNullOrEmpty($InputBox_txtbx.Text)))  {
          $Computername  = $InputBox_txtbx.Text
          Write-Verbose  "Getting Profile Storage Information from $Computername"  -Verbose
              Try  {
                  $user = Get-CimInstance -ComputerName $computername -ClassName Win32_ComputerSystem | Select-Object UserName
                  $user = $user -replace "^.*?\\"
                  $user = $user.Substring(0,$user.Length-1)
                  $user
                  $storage = "{0} MB" -f ((Get-ChildItem \\$computername\c$\users\$user -Recurse | Measure-Object -Property Length -Sum -ErrorAction Stop).Sum / 1MB)
                  $Output_dtgrd.ItemsSource = ("The user profile: " + $user + "`n`t is using this much disk space: " + $storage |  Out-String)
              }
              Catch  {
                  Write-Warning  $_
                  }
          }
    })

    $rmt_btn.Add_Click({
      If (-NOT ([string]::IsNullOrEmpty($InputBox_txtbx.Text)))  {
          $Computername  = $InputBox_txtbx.Text
          $WinRemAss = "$env:systemroot/system32/msra.exe"
          Start-Process $WinRemAss -ArgumentList "/OfferRA $ComputerName" -Wait -NoNewWindow -RunAsAdministrator
          <#
            The following three statements are equivalent and should produce the same results:
            -Start-Process $WinRemAss -ArgumentList "/OfferRA $Computer" -Wait -NoNewWindow
            -& $WinRemAss /OfferRA $Computer
            -cmd /c $WinRemAss /OfferRA $Computer
          #>
          }
    })


    $BIOS_btn.Add_Click({
        If (-NOT ([string]::IsNullOrEmpty($InputBox_txtbx.Text)))  {
          $Computername  = $InputBox_txtbx.Text
          Write-Verbose  "Getting BIOS Information from $Computername"  -Verbose
              Try  {
                  $BIOS  = Get-CimInstance -ClassName Win32_BIOS -ComputerName $Computername
                  [System.Windows.MessageBox]::Show($BIOS)
              }
              Catch  {
                  Write-Warning  $_
                  }
          }
    })

    $NetworkInfo_btn.Add_Click({
      If (-NOT ([string]::IsNullOrEmpty($InputBox_txtbx.Text)))  {
          $Computername  = $InputBox_txtbx.Text
          Write-Verbose  "Querying Network Info for $Computername"  -Verbose
          Try  {
            $session = New-PSSession -ComputerName $Computername
              
            Invoke-Command -Session $session -ScriptBlock { $Network = Get-WmiObject Win32_NetworkAdapterConfiguration -Filter IPEnabled=TRUE | Select-Object Description, DHCPServer, @{Name='IpAddress';Expression={$_.IpAddress -join '; '}}, @{Name='IpSubnet';Expression={$_.IpSubnet -join '; '}}, @{Name='DefaultIPgateway';Expression={$_.DefaultIPgateway -join '; '}}, @{Name='DNSDomain';Expression={$_.DNSDomain -join '; '}}, WinsPrimaryServer, WINSSecindaryServer }
              # This shouldn't print anything.
              # Print the result on remote computer an assing its output to localC variable
              $Network | Format-Table
              $locally = Invoke-Command -Session $session  -ScriptBlock { $Network }
              # Print the local variable, it should contain $remoteComputer data.
              #$locally = $locally | Select-Object Description, DHCPServer, IpAddress, DefaultIPgateway, DNSDomain, WinsPrimaryServer, WINSSecindaryServer,PSComputerName,RunspaceId
              $locally = $locally | Out-String
              #$Output_dtgrd.ItemsSource = $locally
              [System.Windows.MessageBox]::Show($locally)
              Remove-PSSession $session
          }
          Catch  {
              Write-Warning  $_
          }
      }
    })

    $Ladmin_btn.Add_Click({
      If (-NOT ([string]::IsNullOrEmpty($InputBox_txtbx.Text)))  {
          $Computername  = $InputBox_txtbx.Text
          Write-Verbose  "Query Local Admin on $Computername"  -Verbose
          Try  {
            $session = New-PSSession -ComputerName $Computername
              
            Invoke-Command -Session $session -ScriptBlock { $remoteComputer = Get-LocalGroupMember -Group "Administrators" }
              # This shouldn't print anything.
              # Print the result on remote computer an assing its output to localC variable
              $locally = Invoke-Command -Session $session  -ScriptBlock { $remoteComputer }
              # Print the local variable, it should contain $remoteComputer data.
              $locally = $locally | Format-Table
              $Output_dtgrd.ItemsSource = $locally
              Remove-PSSession $session
          }
          
          Catch  {
              Write-Warning  $_
          }
      }
    })

    $RestartPC_btn.Add_Click({
      If (-NOT ([string]::IsNullOrEmpty($InputBox_txtbx.Text)))  {
          $Computername  = $InputBox_txtbx.Text
          Write-Verbose  "Restarting $Computername"  -Verbose
          Try  {
              $Restart  = Restart-Computer -ComputerName $Computername
              $Output_dtgrd.ItemsSource = $Restart
          }
          Catch  {
              Write-Warning  $_
          }
      }
    })

    $Updates_btn.Add_Click({
      If (-NOT ([string]::IsNullOrEmpty($InputBox_txtbx.Text)))  {
          $Computername = $InputBox_txtbx.Text
          Write-Verbose "Attempting to force windows update on $Computername"  -Verbose
          Try  {
              $Computername = $InputBox_txtbx.Text
              $session = New-PSSession -ComputerName $Computername
              
              Invoke-Command -Session $session -ScriptBlock {
                  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Unrestricted -Force
                  start-sleep 2
                  Add-WUServiceManager -MicrosoftUpdate
                  Install-Module PSWindowsUpdate
                  Start-Sleep 30
                  Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -AutoReboot | Out-File "\\UpdateLogs\$Computername-$(Get-Date -f yyyy-MM-dd)-MSUpdates.log" -Force 
               }

               Remove-PSSession
          }
          Catch  {
              Write-Warning  $_
          }
          
      }
    })

    $FixUpdates_btn.Add_Click({
      If (-NOT ([string]::IsNullOrEmpty($InputBox_txtbx.Text)))  {
          $Computername  = $InputBox_txtbx.Text
          Write-Verbose  "Attempting to fix Windows Updates on $Computername"  -Verbose
          Try  {
            $session = New-PSSession -ComputerName $Computername
              
            Invoke-Command -Session $session -ScriptBlock {
              #Stop BITS, Cryptographic, MSI Installer and Windows Update Services.
              Net stop wuauserv
              Net stop cryptSvc 
              Net stop bits  
              Net stop msiserver 
     
              #Rename SoftwareDistribution and Catroot2 folder.
              Rename-Item C:\Windows\SoftwareDistribution C:\Windows\SoftwareDistribution.old  
              Rename-Item C:\Windows\System32\catroot2 C:\Windows\System32\Catroot2.old  
    
              #Restart BITS, Cryptographic, MSI Installer and Windows Update Services. 
              Net start wuauserv  
              Net start cryptSvc 
              Net start bits  
              Net start msiserver
            }
Remove-PSSession $session
          }
          Catch  {
              Write-Warning  $_
          }
      }
    })

  #endregion Events 


  $Null = $Window.ShowDialog()