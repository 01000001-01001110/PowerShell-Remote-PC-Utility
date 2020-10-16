
#Remote Computer Utility
#Credit where credit is due. The shell of this script was found here: https://no.qaru.tech/questions/49305892/powershell-doesnt-show-xaml-dialogbox I don't pretend to speak the language, but what I understand as the solution to whatever issue the OP was stating works very well as a shell for many other scripts as well. 
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
  #Changes: Modified the OS info button to  Invoke-Command -ComputerName $Computername -Credential  -ScriptBlock { Get-CimInstance -ClassName Win32_OperatingSystem | select-object CSName, Caption, CSDVersion, OSType, LastBootUpTime, ProductType }
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
#Version 0.2.0
  #Release Date: 
  #Complete Redesign of GUI
  #Added Tab Control for buttons. 
  #Added an "Online/Offline" visual indicator when you search for PC
  #Added Mouse over Search for PC changes background of button.
  #Added Mouse icon change when Hover Over Search for PC
  #Added and replaced all buttons with stylized buttons. 
  #Changed System information to manually build the array from three different queries. 
    #Still need to work on this with nested results. 
  #Changed button orientation.

    Add-Type -AssemblyName PresentationFramework
    [xml]$inputXML  = @"
    <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
            xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
            xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
            xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
            xmlns:local="clr-namespace:Remote_Computer_ToolKit"
            Title="Remote Computer ToolKit" Background="dimgray" Height="489.796" Width="800" FontFamily="Consolas" FontSize="10">
        <Window.Resources>
            <!-- ... -->
    
    
    
            <Style x:Key="ToggleButtonStyle" TargetType="ToggleButton">
                <Setter Property="Background" Value="DimGray" />
                <Setter Property="Foreground" Value="GhostWhite" />
                <Setter Property="Template">
                    <Setter.Value>
                        <ControlTemplate TargetType="ToggleButton">
                            <Border
                            CornerRadius="4"
                            Background="{TemplateBinding Background}"
                            BorderThickness="1"
                            Padding="2"
                            >
                                <ContentPresenter
                                HorizontalAlignment="Center"
                                VerticalAlignment="Center"
                                />
                            </Border>
                            <ControlTemplate.Triggers>
                                <Trigger Property="IsChecked" Value="True">
                                    <Setter
                                    Property="Background"
                                    Value="Blue"
                                    />
                                </Trigger>
                            </ControlTemplate.Triggers>
                        </ControlTemplate>
                    </Setter.Value>
                </Setter>
            </Style>
    
            <!-- ... -->
        </Window.Resources>
        <Grid Margin="0,0,0,21">
    
    
            <TabControl HorizontalAlignment="Left" Height="427" Margin="9,30,0,-19" VerticalAlignment="Top" Width="124" Grid.RowSpan="8">
                <TabItem Header="Remote Assist" Foreground="CornflowerBlue" FontWeight="Bold">
                    <Grid Background="#FFE5E5E5" Margin="0,0,0,-2" Height="405" VerticalAlignment="Top" HorizontalAlignment="Right" Width="118">
                        <ToggleButton x:Name="Ping_btn" Style="{StaticResource ToggleButtonStyle}" Content="Ping Computer" HorizontalAlignment="Left" Margin="10,5,0,0" VerticalAlignment="Top" Width="98" Height="20" />
                        <ToggleButton x:Name="login_btn" Style="{StaticResource ToggleButtonStyle}" Content="Signed In User" HorizontalAlignment="Left" Margin="10,30,0,0" VerticalAlignment="Top" Width="98" Height="20"/>
                        <ToggleButton x:Name="Drives_btn" Style="{StaticResource ToggleButtonStyle}" Content="Drive Information" HorizontalAlignment="Left" Margin="10,55,0,0" VerticalAlignment="Top" Width="98" Height="20" />
                        <ToggleButton x:Name="Hotfix_btn" Style="{StaticResource ToggleButtonStyle}" Content="Installed Updates" HorizontalAlignment="Left" Margin="10,80,0,0" VerticalAlignment="Top" Width="98" Height="20"/>
                        <ToggleButton x:Name="Time_btn" Style="{StaticResource ToggleButtonStyle}" Content="Installed Printers" HorizontalAlignment="Left" Margin="10,105,0,0" VerticalAlignment="Top" Width="98" Height="20" />
                        <ToggleButton x:Name="Stats_btn" Style="{StaticResource ToggleButtonStyle}" Content="PC Statistics" HorizontalAlignment="Left" Margin="10,130,0,0" VerticalAlignment="Top" Width="98" Height="20" />
                        <ToggleButton x:Name="BIOS_btn" Style="{StaticResource ToggleButtonStyle}" Content="System Info" HorizontalAlignment="Left" Margin="10,155,0,0" VerticalAlignment="Top" Width="98" Height="20"/>
                        <ToggleButton x:Name="NetworkInfo_btn" Style="{StaticResource ToggleButtonStyle}" Content="Network Info" HorizontalAlignment="Left" Margin="10,180,0,0" VerticalAlignment="Top" Width="98" Height="20"/>
                        <ToggleButton x:Name="Services_btn" Style="{StaticResource ToggleButtonStyle}" Content="Rmt Services" HorizontalAlignment="Left" Margin="10,205,0,0" VerticalAlignment="Top" Width="98" Height="20"/>
                        <ToggleButton x:Name="Processes_btn" Style="{StaticResource ToggleButtonStyle}" Content="Rmt Processes" HorizontalAlignment="Left" Margin="10,230,0,0" VerticalAlignment="Top" Width="98" Height="20" />
                        <ToggleButton x:Name="rmt_btn" Style="{StaticResource ToggleButtonStyle}" Content="Rmt Assist" HorizontalAlignment="Left" Margin="10,255,0,0" VerticalAlignment="Top" Width="98" Height="20" />
                        <ToggleButton x:Name="storage_btn" Style="{StaticResource ToggleButtonStyle}" Content="Rmt Profile Size" HorizontalAlignment="Left" Margin="10,280,0,0" VerticalAlignment="Top" Width="98" Height="20" />
                        <ToggleButton x:Name="Ladmin_btn" Style="{StaticResource ToggleButtonStyle}" Content="Local Admins" HorizontalAlignment="Left" Margin="10,305,0,0" VerticalAlignment="Top" Width="98" Height="20" />
                        <ToggleButton x:Name="FixUpdates_btn" Style="{StaticResource ToggleButtonStyle}" Content="Fix Update Srvs" HorizontalAlignment="Left" Margin="10,330,0,0" VerticalAlignment="Top" Width="98" Height="20"/>
                        <ToggleButton x:Name="Updates_btn" Style="{StaticResource ToggleButtonStyle}" Content="Force Win Updates" HorizontalAlignment="Left" Margin="10,355,0,0" VerticalAlignment="Top" Width="98" Height="20"/>
                        <ToggleButton x:Name="RestartPC_btn" Style="{StaticResource ToggleButtonStyle}" Content="Force Restart PC" HorizontalAlignment="Left" Margin="10,380,0,0" VerticalAlignment="Top" Width="98" Height="20" />
                    </Grid>
    
                </TabItem>
                <TabItem Header="Log" Foreground="CornflowerBlue" FontWeight="Bold">
                    <Grid Background="#FFE5E5E5"/>
                </TabItem>
            </TabControl>
            <DataGrid x:Name="Output_dtgrd" Margin="139,92,0,-20" Background="dimgray" Foreground="Black" />
    
            <Border CornerRadius="6" Padding="2" Width="88" RenderTransformOrigin="0.844,0.439"
                    VerticalAlignment="Top" HorizontalAlignment="Left" Margin="680,29,0,0" Height="25">
                <Border.Background>
                    <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                        <GradientStop Color="Black" Offset="0" />
                        <GradientStop Color="Black" Offset="0.75" />
                    </LinearGradientBrush>
                </Border.Background>
                <Button Cursor="Hand" x:Name="Connect_btn" BorderBrush="Transparent" Background="White" Foreground="CornflowerBlue" FontSize="10"
                        Content="Search For PC" FontWeight="Bold">
                    <Button.Resources>
                        <Style TargetType="{x:Type Border}">
                            <Setter Property="CornerRadius" Value="4"/>
                        </Style>
                    </Button.Resources>
                </Button>
            </Border>
    
    
            <Border CornerRadius="6" Padding="2" Width="354" RenderTransformOrigin="0.844,0.439"
                    VerticalAlignment="Top" HorizontalAlignment="Left" Margin="138,32,0,0" Height="25">
                <Border.Background>
                    <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                        <GradientStop Color="Black" Offset="0" />
                        <GradientStop Color="Black" Offset="0.75" />
                    </LinearGradientBrush>
                </Border.Background>
                <TextBox x:Name="InputBox_txtbx" Height="19" Margin="2,1,2,0" TextWrapping="Wrap" Text="Type in the remote computer name here" Foreground="CornflowerBlue" VerticalAlignment="Top" >
                    <TextBox.Resources>
                        <Style TargetType="{x:Type Border}">
                            <Setter Property="CornerRadius" Value="3"/>
                        </Style>
                    </TextBox.Resources>
                </TextBox>
            </Border>
            <Border BorderBrush="Black" BorderThickness="1" HorizontalAlignment="Left" Height="12" Margin="139,63,0,0" VerticalAlignment="Top" Width="643"/>
            <Label x:Name="Label2" Content="Remote Computer Output:" HorizontalAlignment="Left" Margin="134,75,0,0" VerticalAlignment="Top" Width="134" Foreground="GhostWhite" FontWeight="Bold" Height="22"/>
            <Label x:Name="Label1" Content="Connection Status" HorizontalAlignment="Left" Margin="504,32,0,0" VerticalAlignment="Top" Width="120" Foreground="GhostWhite" FontWeight="Bold" Height="22"/>
        </Grid>
    
    </Window>
"@
    <##>
    $reader=(New-Object System.Xml.XmlNodeReader $inputXML)
    
    $Window=[Windows.Markup.XamlReader]::Load( $reader )
    
    
    #Connect to Controls
    
    $inputXML.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]")  | ForEach-Object {
    
    New-Variable -Name $_.Name -Value $Window.FindName($_.Name) -Force
    Write-Host $_.Name
    }
    
    #-------------------------------------------------------------#
    #----Control Event Handlers-----------------------------------#
    #-------------------------------------------------------------#
    
    
    
    
    function ConvertTo-DataTable
    {
        <#
        .Synopsis
            Creates a DataTable from an object
        .Description
            Creates a DataTable from an object, containing all properties (except built-in properties from a database)
        .Example
            Get-ChildItem| Select Name, LastWriteTime | ConvertTo-DataTable
        .Link
            Select-DataTable
        .Link
            Import-DataTable
        .Link
            Export-Datatable
        #>
        [OutputType([Data.DataTable])]
        param(
        # The input objects
        [Parameter(Position=0, Mandatory=$true, ValueFromPipeline = $true)]
        [PSObject[]]
        $InputObject
        )
    
        begin {
    
            $outputDataTable = new-object Data.datatable
    
            $knownColumns = @{}
    
    
        }
    
        process {
    
            foreach ($In in $InputObject) {
                $DataRow = $outputDataTable.NewRow()
                $isDataRow = $in.psobject.TypeNames -like "*.DataRow*" -as [bool]
    
                $simpleTypes = ('System.Boolean', 'System.Byte[]', 'System.Byte', 'System.Char', 'System.Datetime', 'System.Decimal', 'System.Double', 'System.Guid', 'System.Int16', 'System.Int32', 'System.Int64', 'System.Single', 'System.UInt16', 'System.UInt32', 'System.UInt64')
    
                $SimpletypeLookup = @{}
                foreach ($s in $simpleTypes) {
                    $SimpletypeLookup[$s] = $s
                }
    
    
                foreach($property in $In.PsObject.properties) {
                    if ($isDataRow -and
                        'RowError', 'RowState', 'Table', 'ItemArray', 'HasErrors' -contains $property.Name) {
                        continue
                    }
                    $propName = $property.Name
                    $propValue = $property.Value
                    $IsSimpleType = $SimpletypeLookup.ContainsKey($property.TypeNameOfValue)
    
                    if (-not $outputDataTable.Columns.Contains($propName)) {
                        $outputDataTable.Columns.Add((
                            New-Object Data.DataColumn -Property @{
                                ColumnName = $propName
                                DataType = if ($issimpleType) {
                                    $property.TypeNameOfValue
                                } else {
                                    'System.Object'
                                }
                            }
                        ))
                    }
    
                    $DataRow.Item($propName) = if ($isSimpleType -and $propValue) {
                        $propValue
                    } elseif ($propValue) {
                        [PSObject]$propValue
                    } else {
                        [DBNull]::Value
                    }
    
                }
                $outputDataTable.Rows.Add($DataRow)
            }
    
        }
    
        end
        {
            ,$outputDataTable
    
        }
    
    }
    
    
    $remoteOS_btn.Add_Click({
    
        If (-NOT ([string]::IsNullOrEmpty($InputBox_txtbx.Text)))  {
        $Computername  = $InputBox_txtbx.Text
        Write-Verbose  "Gathering remote OS information from $Computername"  -Verbose
              Try  {
                
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
                        if (Test-Connection -ComputerName $Computername -Quiet -Count 1) 
                        {
                            $label1.Foreground = "Green"
                            $label1.Background = "Black"
                            $label1.Content = ("$Computername Online")
                        }
                        else {
                            $label1.Foreground = "Red"
                            $label1.Background = "Black"
                            $label1.Content = ("$Computername Offline")
                        }
                        $testcon  = Test-Connection -ComputerName $Computername -Count 4 -Delay 2 -TTL 255 -BufferSize 256 -ThrottleLimit 32
                            $Output_dtgrd.ItemsSource = $testcon
                       
                    }
                    Catch  {
                        Write-Warning  $_
                    }
            }
        })
    
        $Connect_btn.Add_Click({
            If (-NOT ([string]::IsNullOrEmpty($InputBox_txtbx.Text)))  {
                $Computername  = $InputBox_txtbx.Text
                Write-Verbose  "Attempting to connect to $Computername Please be patient"  -Verbose
                    Try  {
                        if (Test-Connection -ComputerName $Computername -Quiet -Count 1) 
                        {
                            $label1.Foreground = "Green"
                            $label1.Background = "Black"
                            $label1.Content = ("$Computername Online")
                        }
                        else {
                            $label1.Foreground = "Red"
                            $label1.Background = "Black"
                            $label1.Content = ("$Computername Offline")
                        }
                        
                       
                    }
                    Catch  {
                        Write-Warning  $_
                    }
            }
        })
    
    
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
    
    
                    $Stats_btn.Add_Click({
                        If (-NOT ([string]::IsNullOrEmpty($InputBox_txtbx.Text)))  {
                          $Computername  = $InputBox_txtbx.Text
                          Write-Verbose  "Gathering Statistics from $Computername"  -Verbose
                              Try  {
                                  $Stats = Invoke-Command -ComputerName $Computername -ScriptBlock { Get-ComputerInfo }
                                  $Stats = $Stats | Out-GridView
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
                                    $Printer = Get-Printer -ComputerName $computername | Select-Object Name, PrinterStatus, ComputerName, DriverName, JobCount, PortName
                                    $Output_dtgrd.ItemsSource = $Printer
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
                                $option = New-CimSessionOption -Protocol Dcom
                                    $session = New-CimSession -ComputerName $computername -SessionOption $option
    
                                    $bootTime = Get-CimInstance -ClassName Win32_OperatingSystem -CimSession $session | Select-Object -ExpandProperty LastBootupTime
                                    $upTime = New-TimeSpan -Start $bootTime
    
                                    $min = [int]$upTime.TotalMinutes
    
                                $user = Get-CimInstance -ComputerName $computername -ClassName Win32_ComputerSystem | Select-Object UserName
                                  $user = $user -replace "^.*?\\"
                                  $user = $user.Substring(0,$user.Length-1)
                                  $user
                                  $storage = "{0} MB" -f ((Get-ChildItem \\$computername\c$\users\$user -Recurse | Measure-Object -Property Length -Sum -ErrorAction Stop).Sum / 1GB)
    
    
    
                                  $Stats = Invoke-Command -ComputerName $Computername -ScriptBlock { Get-ComputerInfo }
    
    
    
                                  #$BIOS  = Get-CimInstance -ClassName Win32_BIOS -ComputerName $Computername
                                  $my_inventory = @{}
                                    $my_inventory.add("Computer Name",$(Get-CimInstance win32_operatingsystem -ComputerName $Computername).csname)
                                    $my_inventory.add("Operating System",$(Get-CimInstance win32_operatingsystem -ComputerName $Computername).caption)
                                    $my_inventory.add("Operating System Version",$(Get-CimInstance win32_operatingsystem -ComputerName $Computername).version)
                                    $my_inventory.add("Make",$(Get-CimInstance win32_computersystem -ComputerName $Computername).model)
                                    $my_inventory.add("Manufacturer",$(Get-CimInstance win32_computersystem -ComputerName $Computername).manufacturer)
                                    $my_inventory.add("Memory/GB",$(Get-CimInstance win32_computersystem -ComputerName $Computername).TotalPhysicalMemory/1GB -as [int])
                                    $my_inventory.add("Current Running Processes",(Get-CimInstance -ClassName Win32_Process -ComputerName $Computername).Count)
                                    $my_inventory.add("BIOS Version",(Get-CimInstance -ClassName Win32_BIOS -ComputerName $Computername).SMBIOSBIOSVersion)
                                    $my_inventory.add("BIOS Manufacturer",(Get-CimInstance -ClassName Win32_BIOS -ComputerName $Computername).Manufacturer)
                                    $my_inventory.add("BIOS Date",(Get-CimInstance -ClassName Win32_BIOS -ComputerName $Computername).Name)
                                    $my_inventory.add("DELL",(Get-CimInstance -ClassName Win32_BIOS -ComputerName $Computername).Version)
                                    $my_inventory.add("Remote Computer Name",(Get-CimInstance -ClassName Win32_BIOS -ComputerName $Computername).PSComputerName)
                                    $my_inventory.add("Logged On User",(Get-CimInstance -ComputerName $computername -ClassName Win32_ComputerSystem).UserName)
                                    $my_inventory.add("Product",($Stats).WindowsProductName)
                                    $my_inventory.add("Windows CurrentVersion",($Stats).WindowsCurrentVersion)
                                    $my_inventory.add("Windows Edition",($Stats).WindowsEditionId)
                                    $my_inventory.add("Client / Server",($Stats).WindowsInstallationType)
                                    $my_inventory.add("Installation Date",($Stats).WindowsInstallDateFromRegistry)
                                    $my_inventory.add("Firmware Type",($Stats).BiosFirmwareType)
                                    $my_inventory.add("BIOS Release Date",($Stats).BiosReleaseDate)
                                    $my_inventory.add("Serial Number",($Stats).BiosSeralNumber)
                                    $my_inventory.add("Registered Domain",($Stats).CsDomain)
                                    $my_inventory.add("Last Boot State",($Stats).CsBootupState)
                                    $my_inventory.add("Current Time",($Stats).OsLocalDateTime)
                                    $my_inventory.add("Last Boot Time",($Stats).OsLastBootUpTime)
                                    $my_inventory.add("Uptime",($Stats).OsUptime)
                                    $my_inventory.add("Number of Updates Installed",($Stats).OsHotFixes.Length)
                                    $my_inventory.add("Profile Size",$storage)
                                  $Output_dtgrd.ItemsSource = $my_inventory
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
                            $Networks = Get-CimInstance Win32_NetworkAdapterConfiguration -ComputerName $Computer | ? {$_.IPEnabled}
                                $my_network = @{}
                                $my_network.add("AdapterDesc",($Networks).Description)
                                $my_network.add("IP Address",($Networks).IPAddress)
                                $my_network.add("Subnet Mask",($Networks).IPSubnet)
                                $my_network.add("GateWay",($Networks).DefaultIPGateway)
                                $my_network.add("DNS Servers",($Networks).DNSServerSearchOrder)
                                $my_network.add("DNS Domain",($Networks).DNSDomain)
                                $my_network.add("DNS Suffix",($Networks).DNSDomainSuffixSearchOrder)
                                $my_network.add("FullDNSReg",($Networks).FullDNSRegistrationEnabled)
                                $my_network.add("WINSLMHOST",($Networks).WINSEnableLMHostsLookup)
                                $my_network.add("WINSPRI",($Networks).WINSPrimaryServer)
                                $my_network.add("WINSSEC",($Networks).WINSSecondaryServer)
                                $my_network.add("Domain DNS Reg",($Networks).DomainDNSRegistrationEnabled)
                                $my_network.add("DNS WINS Enable",($Networks).DNSEnabledForWINSResolution)
                                $my_network.add("TCPIP NETBIOS",($Networks).TcpipNetbiosOptions)
                                $my_network.add("Adapter Name",($Networks).name)
                                $my_network.add("Status",($Networks).status)
                                $my_network.add("Link Speed",($Networks).linkspeed)
                                $my_network.add("Drivers",($Networks).driverinformation)
                                $my_network.add("MAC Address",($Networks).MACAddress)
                                $my_network.add("DHCP Enabled",($Networks).DHCPEnabled)
                                $Output_dtgrd.ItemsSource = $my_network
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
                              $Restart  = Restart-Computer -ComputerName $Computername -Force
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
    
    #endregion
    
    #-------------------------------------------------------------#
    #----Script Execution-----------------------------------------#
    #-------------------------------------------------------------#
    
    $Window = [Windows.Markup.XamlReader]::Parse($Xaml)
    
    [xml]$xml = $Xaml
    
    $xml.SelectNodes("//*[@Name]") | ForEach-Object { Set-Variable -Name $_.Name -Value $Window.FindName($_.Name) }
    
    
    
    
    $Window.ShowDialog()