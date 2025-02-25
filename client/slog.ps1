<#
.SYNOPSIS
    Continuously tails a Star Citizen log file, detects events via regex,
    and sends them to a FastAPI server as JSON. In debug mode, it also prints
    the JSON payload to a GUI window.

    Configuration is still handled for server URL, log file path, etc.
    The current player is ONLY read from new "login" events in the log.
#>

param(
    [string]$ConfigFilePath = ".\client_config.json"
)

function Load-ClientConfig {
    if (Test-Path $ConfigFilePath) {
        Write-Host "Loading existing client_config.json..."
        $config = Get-Content $ConfigFilePath -Raw | ConvertFrom-Json
    }
    else {
        Write-Host "client_config.json not found. Creating default config..."
        $defaultConfig = @{
            server_url       = "http://127.0.0.1:8000/event"
            log_file_path    = "C:\StarCitizen\Game.log"
            group_passphrase = "defaultgroup"
            debug_mode       = $false
            send_events      = $true
        }
        $defaultConfig | ConvertTo-Json | Out-File $ConfigFilePath
        $config = $defaultConfig
    }

    # Ensure "send_events" property exists
    if (-not $config.PSObject.Properties.Name -contains "send_events") {
        $config | Add-Member -MemberType NoteProperty -Name send_events -Value $true
    }

    return $config
}

function Show-ConfigurationGUI {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    
    $global:currentPlayerName = ""
    $config = Load-ClientConfig

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Update Log Parser Configuration"
    $form.Size = New-Object System.Drawing.Size(500,500)
    $form.StartPosition = "CenterScreen"

    # Error message label (in red)
    $lblError = New-Object System.Windows.Forms.Label
    $lblError.Location = New-Object System.Drawing.Point(10,5)
    $lblError.Size = New-Object System.Drawing.Size(480,20)
    $lblError.ForeColor = [System.Drawing.Color]::Red
    $lblError.Text = ""
    $form.Controls.Add($lblError)

    # Server URL
    $lblServerUrl = New-Object System.Windows.Forms.Label
    $lblServerUrl.Location = New-Object System.Drawing.Point(10,40)
    $lblServerUrl.Size = New-Object System.Drawing.Size(100,20)
    $lblServerUrl.Text = "Server URL:"
    $form.Controls.Add($lblServerUrl)
    
    $txtServerUrl = New-Object System.Windows.Forms.TextBox
    $txtServerUrl.Location = New-Object System.Drawing.Point(120,40)
    $txtServerUrl.Size = New-Object System.Drawing.Size(350,20)
    $txtServerUrl.Text = $config.server_url
    $form.Controls.Add($txtServerUrl)

    # Server URL status indicator (circle) and label
    $panelServerIndicator = New-Object System.Windows.Forms.Panel
    $panelServerIndicator.Location = New-Object System.Drawing.Point(120,65)
    $panelServerIndicator.Size = New-Object System.Drawing.Size(15,15)
    $gp = New-Object System.Drawing.Drawing2D.GraphicsPath
    $gp.AddEllipse(0,0,15,15)
    $panelServerIndicator.Region = New-Object System.Drawing.Region($gp)
    $panelServerIndicator.BackColor = [System.Drawing.Color]::Gray  # default color
    # black outline
    $panelServerIndicator.Add_Paint({
        param($sender, $e)
        $e.Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $e.Graphics.DrawEllipse([System.Drawing.Pens]::Black, 0, 0, $sender.Width - 1, $sender.Height - 1)
    })
    $form.Controls.Add($panelServerIndicator)

    $lblServerStatus = New-Object System.Windows.Forms.Label
    $lblServerStatus.Location = New-Object System.Drawing.Point(140,65)
    $lblServerStatus.Size = New-Object System.Drawing.Size(150,15)
    $lblServerStatus.Text = ""
    $form.Controls.Add($lblServerStatus)

    # Log File Path
    $lblLogFile = New-Object System.Windows.Forms.Label
    $lblLogFile.Location = New-Object System.Drawing.Point(10,100)
    $lblLogFile.Size = New-Object System.Drawing.Size(100,20)
    $lblLogFile.Text = "Log File Path:"
    $form.Controls.Add($lblLogFile)
    
    $txtLogFilePath = New-Object System.Windows.Forms.TextBox
    $txtLogFilePath.Location = New-Object System.Drawing.Point(120,100)
    $txtLogFilePath.Size = New-Object System.Drawing.Size(300,20)
    $txtLogFilePath.Text = $config.log_file_path
    $form.Controls.Add($txtLogFilePath)
    
    $btnBrowse = New-Object System.Windows.Forms.Button
    $btnBrowse.Location = New-Object System.Drawing.Point(430,100)
    $btnBrowse.Size = New-Object System.Drawing.Size(40,20)
    $btnBrowse.Text = "..."
    $btnBrowse.Add_Click({
        $ofd = New-Object System.Windows.Forms.OpenFileDialog
        $ofd.Filter = "Log Files (*.log)|*.log|All Files (*.*)|*.*"
        if ($ofd.ShowDialog() -eq "OK") {
            $txtLogFilePath.Text = $ofd.FileName
        }
    })
    $form.Controls.Add($btnBrowse)

    # Log File status indicator (circle) and label
    $panelLogIndicator = New-Object System.Windows.Forms.Panel
    $panelLogIndicator.Location = New-Object System.Drawing.Point(120,125)
    $panelLogIndicator.Size = New-Object System.Drawing.Size(15,15)
    $gp2 = New-Object System.Drawing.Drawing2D.GraphicsPath
    $gp2.AddEllipse(0,0,15,15)
    $panelLogIndicator.Region = New-Object System.Drawing.Region($gp2)
    $panelLogIndicator.BackColor = [System.Drawing.Color]::Gray  # default color
    # black outline
    $panelLogIndicator.Add_Paint({
        param($sender, $e)
        $e.Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $e.Graphics.DrawEllipse([System.Drawing.Pens]::Black, 0, 0, $sender.Width - 1, $sender.Height - 1)
    })
    $form.Controls.Add($panelLogIndicator)

    $lblLogStatus = New-Object System.Windows.Forms.Label
    $lblLogStatus.Location = New-Object System.Drawing.Point(140,125)
    $lblLogStatus.Size = New-Object System.Drawing.Size(150,15)
    $lblLogStatus.Text = ""
    $form.Controls.Add($lblLogStatus)

    # Group Passphrase
    $lblPassphrase = New-Object System.Windows.Forms.Label
    $lblPassphrase.Location = New-Object System.Drawing.Point(10,160)
    $lblPassphrase.Size = New-Object System.Drawing.Size(100,40)
    $lblPassphrase.Text = "Group Password:"
    $form.Controls.Add($lblPassphrase)
    
    $txtPassphrase = New-Object System.Windows.Forms.TextBox
    $txtPassphrase.Location = New-Object System.Drawing.Point(120,160)
    $txtPassphrase.Size = New-Object System.Drawing.Size(350,20)
    $txtPassphrase.Text = $config.group_passphrase
    $form.Controls.Add($txtPassphrase)

    # Player Status Label
    $lblPlayerStatus = New-Object System.Windows.Forms.Label
    $lblPlayerStatus.Location = New-Object System.Drawing.Point(10,200)
    $lblPlayerStatus.Size = New-Object System.Drawing.Size(100,20)
    $lblPlayerStatus.Text = "Player Status:"
    $form.Controls.Add($lblPlayerStatus)
    
    # Player Status indicator (circle) and label
    $panelPlayerIndicator = New-Object System.Windows.Forms.Panel
    $panelPlayerIndicator.Location = New-Object System.Drawing.Point(120,200)
    $panelPlayerIndicator.Size = New-Object System.Drawing.Size(15,15)
    $gp3 = New-Object System.Drawing.Drawing2D.GraphicsPath
    $gp3.AddEllipse(0,0,15,15)
    $panelPlayerIndicator.Region = New-Object System.Drawing.Region($gp3)
    $panelPlayerIndicator.BackColor = [System.Drawing.Color]::Red  # Default to red (no player detected)
    # black outline
    $panelPlayerIndicator.Add_Paint({
        param($sender, $e)
        $e.Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $e.Graphics.DrawEllipse([System.Drawing.Pens]::Black, 0, 0, $sender.Width - 1, $sender.Height - 1)
    })
    $form.Controls.Add($panelPlayerIndicator)

    $lblPlayerName = New-Object System.Windows.Forms.Label
    $lblPlayerName.Location = New-Object System.Drawing.Point(140,200)
    $lblPlayerName.Size = New-Object System.Drawing.Size(350,15)
    $lblPlayerName.Text = "No player detected"
    $form.Controls.Add($lblPlayerName)

    # Debug Mode checkbox
    $chkDebugMode = New-Object System.Windows.Forms.CheckBox
    $chkDebugMode.Location = New-Object System.Drawing.Point(120,240)
    $chkDebugMode.Size = New-Object System.Drawing.Size(150,20)
    $chkDebugMode.Text = "Enable Debug Mode"
    $chkDebugMode.Checked = $config.debug_mode
    $form.Controls.Add($chkDebugMode)

    # Send events to server checkbox
    $chkSendEvents = New-Object System.Windows.Forms.CheckBox
    $chkSendEvents.Location = New-Object System.Drawing.Point(300,240)
    $chkSendEvents.Size = New-Object System.Drawing.Size(170,40)
    $chkSendEvents.Text = "Send events to server (online mode)"
    $chkSendEvents.Checked = $config.send_events
    $form.Controls.Add($chkSendEvents)

    # Function to save updated config
    $SaveConfig = {
        $config.server_url       = $txtServerUrl.Text
        $config.log_file_path    = $txtLogFilePath.Text
        $config.group_passphrase = $txtPassphrase.Text
        $config.debug_mode       = $chkDebugMode.Checked
        $config.send_events      = $chkSendEvents.Checked

        $config | ConvertTo-Json | Out-File $ConfigFilePath
    }

    # Functions to update status indicators
    function Update-ServerStatusIndicator {
        $url = $txtServerUrl.Text
        try {
            $response = Invoke-WebRequest -Uri $url -Method Head -TimeoutSec 3 -ErrorAction Stop
            if ($response.StatusCode -eq 200) {
                $panelServerIndicator.BackColor = [System.Drawing.Color]::Green
                $lblServerStatus.Text = "server online"
            }
            else {
                $panelServerIndicator.BackColor = [System.Drawing.Color]::Red
                $lblServerStatus.Text = "incorrect server address"
            }
        }
        catch {
            if ($_.Exception.Message -match "timed out") {
                $panelServerIndicator.BackColor = [System.Drawing.Color]::Yellow
                $lblServerStatus.Text = "server offline"
            }
            else {
                $panelServerIndicator.BackColor = [System.Drawing.Color]::Red
                $lblServerStatus.Text = "incorrect server address"
            }
        }
    }

    function Update-LogFileStatusIndicator {
        $path = $txtLogFilePath.Text
        if (Test-Path $path) {
            $fileInfo = Get-Item $path
            # If log was written within last 60s, consider it "active"
            if ((Get-Date) - $fileInfo.LastWriteTime -lt (New-TimeSpan -Seconds 60)) {
                $panelLogIndicator.BackColor = [System.Drawing.Color]::Green
                $lblLogStatus.Text = "log active"
            }
            else {
                $panelLogIndicator.BackColor = [System.Drawing.Color]::Yellow
                $lblLogStatus.Text = "log inactive"
            }
        }
        else {
            $panelLogIndicator.BackColor = [System.Drawing.Color]::Red
            $lblLogStatus.Text = "incorrect path"
        }
    }

    # Function to update player status (called from the tail when a login is detected)
    $global:UpdatePlayerStatusFunction = {
        param($playerName)
        
        if ($playerName -and $playerName -ne "") {
            $global:currentPlayerName = $playerName
            $panelPlayerIndicator.BackColor = [System.Drawing.Color]::Green
            $lblPlayerName.Text = "Player detected: $playerName"
        }
    }

    # Auto-save on change for all controls and update status indicators
    $txtServerUrl.Add_TextChanged({
        & $SaveConfig
        Update-ServerStatusIndicator
    })
    $txtLogFilePath.Add_TextChanged({
        & $SaveConfig
        Update-LogFileStatusIndicator
    })
    $txtPassphrase.Add_TextChanged({ & $SaveConfig })
    $chkDebugMode.Add_CheckedChanged({ & $SaveConfig })
    $chkSendEvents.Add_CheckedChanged({ & $SaveConfig })

    # Initial status update on load
    Update-ServerStatusIndicator
    Update-LogFileStatusIndicator

    # Close button to exit GUI
    $btnClose = New-Object System.Windows.Forms.Button
    $btnClose.Location = New-Object System.Drawing.Point(200,320)
    $btnClose.Size = New-Object System.Drawing.Size(100,30)
    $btnClose.Text = "Exit"
    $btnClose.Add_Click({
        $form.Close()
        $host.SetShouldExit(0)
    })       
    $form.Controls.Add($btnClose)
    
    # Make form modeless so it can stay open during log processing
    $form.Show()
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $form.MaximizeBox = $false
    $form.MinimizeBox = $true
    
    return $form
}

# Always display the configuration GUI
$configForm = Show-ConfigurationGUI
[System.Windows.Forms.Application]::DoEvents()

# Reload configuration after GUI is opened
$config = Load-ClientConfig
$serverUrl       = $config.server_url
$logFilePath     = $config.log_file_path
$groupPassphrase = $config.group_passphrase
$debugMode       = $config.debug_mode

Write-Host "Using server URL: $serverUrl"
Write-Host "Log file path: $logFilePath"
Write-Host "Group passphrase: $groupPassphrase"
Write-Host "Debug mode: $debugMode"
if ($global:currentPlayerName -ne "") {
    Write-Host "Detected player: $global:currentPlayerName"
} else {
    Write-Host "No player detected yet. Waiting for login events..."
}

# Warn if log file doesn't exist, but keep going
if (-not (Test-Path $logFilePath)) {
    Write-Host "Warning: Log file not found. Continuing..."
}

# If debug mode is enabled, create a debug output window.
if ($debugMode) {
    Add-Type -AssemblyName System.Windows.Forms
    $debugForm = New-Object System.Windows.Forms.Form
    $debugForm.Text = "Debug Output"
    $debugForm.Size = New-Object System.Drawing.Size(600,400)
    $txtDebug = New-Object System.Windows.Forms.TextBox
    $txtDebug.Multiline = $true
    $txtDebug.ScrollBars = "Vertical"
    $txtDebug.Dock = "Fill"
    $debugForm.Controls.Add($txtDebug)
    $debugForm.Show()
}

################################################################################
# NEW REGEX PATTERNS WITH NAMED CAPTURES
################################################################################

# 1) Kill pattern
$RegexKill = "<(?<timestamp>[^>]+)> \[Notice\] <Actor Death> CActor::Kill: '(?<EnemyPilot>[^']+)' \[(?<EnemyPilot_ID>\d+)\] in zone '(?<EnemyShip>[^']+)' killed by '(?<Player>[^']+)' \[(?<Player_ID>\d+)\] using '(?<Weapon>[^']+)' \[Class (?<Class>[^]]+)\] with damage type '(?<DamageType>[^']+)' from direction x: (?<dir_x>[-\d\.]+), y: (?<dir_y>[-\d\.]+), z: (?<dir_z>[-\d\.]+)"

# 2) Vehicle Destruction pattern
$RegexVehicleDestruction = "<(?<timestamp>[^>]+)> \[Notice\] <Vehicle Destruction> CVehicle::OnAdvanceDestroyLevel: Vehicle '(?<vehicle>[^']+)' \[(?<vehicle_id>\d+)\] in zone '(?<vehicle_zone>[^']+)' \[pos x: (?<x>[-\d\.]+), y: (?<y>[-\d\.]+), z: (?<z>[-\d\.]+) vel x: (?<vel_x>[-\d\.]+), y: (?<vel_y>[-\d\.]+), z: (?<vel_z>[-\d\.]+)\] driven by '(?<driver>[^']+)' \[(?<driver_id>\d+)\] advanced from destroy level (?<destroy_level_start>\d+) to (?<destroy_level_end>\d+) caused by '(?<destroyed_by>[^']+)' \[(?<destroyed_by_id>\d+)\] with '(?<cause>[^']+)'"

# 3) Login pattern
$RegexLogin = "<(?<timestamp>[^>]+)> \[Notice\] <Legacy login response> \[CIG-net\] User Login Success - Handle\\[(?<Player>[A-Za-z0-9_-]+)\\]"

# 4) Loading Screen pattern
$RegexLoadingScreen = "<(?<timestamp>[^>]+)> Loading screen for (?<mode>[^\\s]+) : (?<screen>[^ ]+) closed after (?<duration>[\\d\\.]+) seconds"

# 5) Enter Zone pattern
$RegexEnterZone = "<(?<timestamp>[^>]+)> \[Notice\] <CEntityComponentInstancedInterior::OnEntityEnterZone> \[InstancedInterior\] OnEntityEnterZone - InstancedInterior \\[(?<InstancedInterior>[^\\]]+)\\] \\[\\d+\\] -> Entity \\[(?<Entity>[^\\]]+)\\] \\[\\d+\\] -- m_openDoors\\[\\d+\\], m_managerGEID\\[(?<ManagerGEID>\\d+)\\], m_ownerGEID\\[(?<OwnerName>[^\\]]+)\\]\\[(?<OwnerGEID>\\d+)\\], m_isPersistent\\[(?<IsPersistent>\\d+)\\]"

# 6) Leave Zone pattern
$RegexLeaveZone = "<(?<timestamp>[^>]+)> \[Notice\] <CEntityComponentInstancedInterior::OnEntityLeaveZone> \[InstancedInterior\] OnEntityLeaveZone - InstancedInterior \\[(?<InstancedInterior>[^\\]]+)\\] \\[\\d+\\] -> Entity \\[(?<Entity>[^\\]]+)\\] \\[\\d+\\] -- m_openDoors\\[\\d+\\], m_managerGEID\\[(?<ManagerGEID>\\d+)\\], m_ownerGEID\\[(?<OwnerName>[^\\]]+)\\]\\[(?<OwnerGEID>\\d+)\\], m_isPersistent\\[(?<IsPersistent>\\d+)\\]"

# 7) Ship prefix pattern
$shipPrefixes = "ORIG|CRUS|RSI|AEGS|VNCL|DRAK|ANVL|BANU|MISC|CNOU|XIAN|GAMA|TMBL|ESPR|KRIG|GRIN|XNAA|MRAI"
$RegexShipPrefix = "^((?<ship_prefix>$shipPrefixes).*)"

# 8) Version pattern
$RegexVersion = "--system-trace-env-id='pub-sc-alpha-(?<gameversion>\\d{3,4}-\\d{7})'"

################################################################################
# Helper function to send event
################################################################################
function Send-EventToServer($eventObject) {
    # Don't send events if we don't have a player name yet
    if ($global:currentPlayerName -eq "") {
        if ($debugMode -and $txtDebug) {
            $txtDebug.AppendText("DEBUG: Skipping event - no player detected yetrn")
            [System.Windows.Forms.Application]::DoEvents()
        }
        return
    }
    
    if (-not $config.send_events) {
        Write-Host "Send events disabled in configuration."
        return
    }
    
    # Attach the current player name at send-time
    $eventObject["user_id"] = $global:currentPlayerName

    $jsonBody = $eventObject | ConvertTo-Json -Depth 10

    if ($debugMode -and $txtDebug) {
        $txtDebug.AppendText("DEBUG: $jsonBodyrn")
        [System.Windows.Forms.Application]::DoEvents()
    }
    
    try {
        Invoke-RestMethod -Uri $serverUrl -Method Post -Body $jsonBody -ContentType "application/json"
    }
    catch {
        Write-Host "Error sending event to server: $($_.Exception.Message)"
    }
}

Write-Host "Starting log tail..."

################################################################################
# Tail the log and match each pattern in turn
################################################################################
Get-Content $logFilePath -Tail 1 -Wait | ForEach-Object {
    $line = $_

    # Keep UI responsive
    [System.Windows.Forms.Application]::DoEvents()

    # 1) LOGIN EVENT - sets the global player name
    if ($line -match $RegexLogin) {
        $playerName = $Matches["Player"]
        Write-Host "Login detected: $playerName"
        
        # Update the global player name
        $global:currentPlayerName = $playerName
        
        # Update the UI if available
        if ($global:UpdatePlayerStatusFunction) {
            Invoke-Command -ScriptBlock $global:UpdatePlayerStatusFunction -ArgumentList $playerName
            [System.Windows.Forms.Application]::DoEvents()
        }
        
        # Create and send the login event
        $eventObject = [ordered]@{
            event_type      = "login"
            local_timestamp = (Get-Date).ToString("o")
            group           = $groupPassphrase
        }
        foreach ($k in $Matches.Keys) {
            if ($k -ne '0') { $eventObject[$k] = $Matches[$k] }
        }
        Send-EventToServer $eventObject
    }
    # If we have a player name, handle other events:
    elseif ($global:currentPlayerName -ne "") {
        # 2) KILL
        if ($line -match $RegexKill) {
            $eventObject = [ordered]@{
                event_type      = "kill"
                local_timestamp = (Get-Date).ToString("o")
                group           = $groupPassphrase
            }
            foreach ($k in $Matches.Keys) {
                if ($k -ne '0') { $eventObject[$k] = $Matches[$k] }
            }
            Send-EventToServer $eventObject
        }
        # 3) VEHICLE DESTRUCTION
        elseif ($line -match $RegexVehicleDestruction) {
            $eventObject = [ordered]@{
                event_type      = "vehicle_destruction"
                local_timestamp = (Get-Date).ToString("o")
                group           = $groupPassphrase
            }
            foreach ($k in $Matches.Keys) {
                if ($k -ne '0') { $eventObject[$k] = $Matches[$k] }
            }
            Send-EventToServer $eventObject
        }
        # 4) LOADING SCREEN
        elseif ($line -match $RegexLoadingScreen) {
            $eventObject = [ordered]@{
                event_type      = "loading_screen"
                local_timestamp = (Get-Date).ToString("o")
                group           = $groupPassphrase
            }
            foreach ($k in $Matches.Keys) {
                if ($k -ne '0') { $eventObject[$k] = $Matches[$k] }
            }
            Send-EventToServer $eventObject
        }
        # 5) ENTER ZONE
        elseif ($line -match $RegexEnterZone) {
            $eventObject = [ordered]@{
                event_type      = "enter_zone"
                local_timestamp = (Get-Date).ToString("o")
                group           = $groupPassphrase
            }
            foreach ($k in $Matches.Keys) {
                if ($k -ne '0') { $eventObject[$k] = $Matches[$k] }
            }
            Send-EventToServer $eventObject
        }
        # 6) LEAVE ZONE
        elseif ($line -match $RegexLeaveZone) {
            $eventObject = [ordered]@{
                event_type      = "leave_zone"
                local_timestamp = (Get-Date).ToString("o")
                group           = $groupPassphrase
            }
            foreach ($k in $Matches.Keys) {
                if ($k -ne '0') { $eventObject[$k] = $Matches[$k] }
            }
            Send-EventToServer $eventObject
        }
        # 7) DETECT SHIP PREFIX
        elseif ($line -match $RegexShipPrefix) {
            $eventObject = [ordered]@{
                event_type      = "ship_prefix_detected"
                local_timestamp = (Get-Date).ToString("o")
                group           = $groupPassphrase
            }
            foreach ($k in $Matches.Keys) {
                if ($k -ne '0') { $eventObject[$k] = $Matches[$k] }
            }
            Send-EventToServer $eventObject
        }
        # 8) DETECT VERSION
        elseif ($line -match $RegexVersion) {
            $eventObject = [ordered]@{
                event_type      = "version_detected"
                local_timestamp = (Get-Date).ToString("o")
                group           = $groupPassphrase
            }
            foreach ($k in $Matches.Keys) {
                if ($k -ne '0') { $eventObject[$k] = $Matches[$k] }
            }
            Send-EventToServer $eventObject
        }
    }
}