<#
Remote Computer Utility
By: Alan Newingham
Date: 10/13/2020

Multiple remote computer commands in an easy to use tool.
        Services: Remote PC Services and whether running or stopped
        Processes: Remote PC processes
        Drives: Drive information for remote PC
        OS_Info: Information including the last reboot from remote PC
        Signed_In: Get currently signed-in user on remote PC
        Hotfix_Info: Get the list of current Hotfixes installed by KB#
        Time: Get current time on remote PC
        Ping: Ping remote PC
        Stats: Get System Statistics from remote PC
        BIOS_Info: Gets bios information from remote PC
        Rmt_Asst: opens remote assist tool with PC name already applied.
        User_Profile: Get the remote PC, and logged on user, then counts the drive space used by logged on user profile
        RestartPC: Restarts the remote PC

Version 0.0.1 
  Release Date 10/13/2020
  updated script with try/catch to remove "garble" from the output.
  remote assist is still flaky
  User profile needs tweaking right now it grabs the current logged on user, and runs a get content on their profile directory to get the size, then "does math" to get the drive space used in MB. 
  During development my system updated and I had to add Add-Type -AssemblyName PresentationFramework for everything to stop failing. Not sure what happened there.
  Fairly simple I replicated what worked once throughout every button in this script. Worked well. 
#>
function RemoteUtility {
  Add-Type -AssemblyName PresentationFramework
  [xml]$XAML  = @"
    <Window  xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
    xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
    xmlns:local="clr-namespace:MyFirstWPF"
    Title="PowerShell Remote Computer Utility" Height="350"  Width="655">
    <Grid>
  <GroupBox  x:Name="Actions" Header="Activities"  HorizontalAlignment="Left" Height="299"  VerticalAlignment="Top" Width="80"  Margin="0,11,0,0">
      <StackPanel>
                  <Button  x:Name="Services_btn" Content="Services"/>
                  <Button  x:Name="Processes_btn" Content="Processes"/>
                  <Button  x:Name="Drives_btn" Content="Drives"/>
                  <Button  x:Name="remoteOS_btn" Content="OS Info"/>
                  <Button  x:Name="login_btn" Content="Signed In"/>
                  <Button  x:Name="Hotfix_btn" Content="Hotfix Info"/>
                  <Button  x:Name="Time_btn" Content="Time"/>
                  <Button  x:Name="Ping_btn" Content="Ping"/>
                  <Button  x:Name="Stats_btn" Content="Stats"/>
                  <Button  x:Name="BIOS_btn" Content="BIOS Info"/>
                  <Button  x:Name="rmt_btn" Content="Rmt Asst"/>
                  <Button  x:Name="storage_btn" Content="User Profile"/>
                  <Button  x:Name="RestartPC_btn" Content="RestartPC"/>
      </StackPanel>
  </GroupBox>
    <GroupBox  x:Name="Computername" Header="Computername"  HorizontalAlignment="Left" Margin="92,11,0,0" VerticalAlignment="Top"  Height="45" Width="535">
    <TextBox  x:Name="InputBox_txtbx" TextWrapping="Wrap"/>            
    </GroupBox>
    <GroupBox  x:Name="Results" Header="Results"  HorizontalAlignment="Left" Margin="92,61,0,0"  VerticalAlignment="Top" Height="248"  Width="535">
    <TextBox  x:Name="Output_txtbx" IsReadOnly="True"  HorizontalScrollBarVisibility="Auto"  VerticalScrollBarVisibility="Auto" />
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
                  $Output_txtbx.Text = ($Processes |  Out-String)
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
          $Output_txtbx.Text = ($Drives | Out-String)
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
          $Services  = Get-Service -ComputerName $Computername
          $Output_txtbx.Text = ($Services | Out-String)
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
      $remoteOS1  = Get-WMIObject Win32_OperatingSystem -ComputerName $Computername |
              select-object CSName, Caption, CSDVersion, OSType, LastBootUpTime, ProductType
      $Output_txtbx.Text = ($remoteOS1 | Out-String)
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
              $currentLogin  = Get-CimInstance -ComputerName $Computername -ClassName Win32_ComputerSystem | Select-Object UserName 
              $Output_txtbx.Text = ($currentLogin | Out-String)
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
              $Output_txtbx.Text = ($UGP | Out-String)
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
                  $testcon  = Test-Connection -ComputerName $Computername -Count 3 -Delay 2 -TTL 255 -BufferSize 256 -ThrottleLimit 32 
                  $Output_txtbx.Text = ($testcon | Out-String)
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
                  $Output_txtbx.Text = ($Stats1 |  Out-String)
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
                  $Output_txtbx.Text = ($Time |  Out-String)
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
                  $Output_txtbx.Text = ($storage |  Out-String)
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
          Start-Process $WinRemAss -ArgumentList "/OfferRA $ComputerName" -Wait -NoNewWindow
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
                  $Output_txtbx.Text = ($BIOS |  Out-String)
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
              $Output_txtbx.Text = ($Restart | Out-String)
          }
          Catch  {
              Write-Warning  $_
          }
      }
    })

  #endregion Events 


  $Null = $Window.ShowDialog()
}


RemoteUtility