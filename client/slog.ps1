<#
.SYNOPSIS
    Continuously tails a Star Citizen log file, detects events via regex,
    and sends them to a FastAPI server as JSON. In debug mode, it also prints
    the JSON payload to a GUI window.
    
    The configuration GUI is always shown to update the configuration.
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
    if (-not $config.PSObject.Properties.Name -contains "send_events") {
        $config | Add-Member -MemberType NoteProperty -Name send_events -Value $true
    }
    return $config
}

function Show-ConfigurationGUI {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $config = Load-ClientConfig

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Update Log Parser Configuration"
    $form.Size = New-Object System.Drawing.Size(500,450)
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
    
    # Debug Mode checkbox
    $chkDebugMode = New-Object System.Windows.Forms.CheckBox
    $chkDebugMode.Location = New-Object System.Drawing.Point(120,200)
    $chkDebugMode.Size = New-Object System.Drawing.Size(150,20)
    $chkDebugMode.Text = "Enable Debug Mode"
    $chkDebugMode.Checked = $config.debug_mode
    $form.Controls.Add($chkDebugMode)

    # Send events to server checkbox
    $chkSendEvents = New-Object System.Windows.Forms.CheckBox
    $chkSendEvents.Location = New-Object System.Drawing.Point(300,200)
    $chkSendEvents.Size = New-Object System.Drawing.Size(150,40)
    $chkSendEvents.Text = "Send events to server (online mode)"
    $chkSendEvents.Checked = $config.send_events
    $chkSendEvents.Checked = $true   # Always checked by default
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
    $btnClose.Location = New-Object System.Drawing.Point(200,280)
    $btnClose.Size = New-Object System.Drawing.Size(100,30)
    $btnClose.Text = "Exit"
    $btnClose.Add_Click({
        $form.Close()
        $host.SetShouldExit(0)
    })       
    $form.Controls.Add($btnClose)
    
    [void]$form.ShowDialog()
}

# Always display the configuration GUI
Show-ConfigurationGUI

# Reload configuration after GUI is closed.
$config = Load-ClientConfig
$serverUrl       = $config.server_url
$logFilePath     = $config.log_file_path
$groupPassphrase = $config.group_passphrase
$debugMode       = $config.debug_mode

Write-Host "Using server URL: $serverUrl"
Write-Host "Log file path: $logFilePath"
Write-Host "Group passphrase: $groupPassphrase"
Write-Host "Debug mode: $debugMode"

# Proceed with the rest of the script regardless of the log file's existence.
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

# Example regex patterns (adjust as needed):
$RegexLogin              = "Player\s+(?<player>\w+)\s+logged in"
$RegexLoadingScreen      = "Loading\s+screen\s+start"
$RegexKill               = "Player\s+(?<killer>\w+)\s+killed\s+player\s+(?<victim>\w+)"
$RegexVehicleDestruction = "Vehicle\s+(?<vehicle>\S+)\s+destroyed\s+by\s+(?<player>\w+)"
$RegexZoneChange         = "Player\s+(?<player>\w+)\s+entered\s+zone\s+(?<zone>\w+)"

function Send-EventToServer($eventObject) {
    if (-not $config.send_events) {
        Write-Host "Send events disabled in configuration."
        return
    }
    $jsonBody = $eventObject | ConvertTo-Json -Depth 10

    if ($debugMode -and $txtDebug) {
        $txtDebug.AppendText("DEBUG: $jsonBody`r`n")
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

Get-Content $logFilePath -Tail 1 -Wait | ForEach-Object {
    $line = $_

    if ($line -match $RegexLogin) {
        $player = $Matches["player"]
        $eventObject = @{
            event_type = "login"
            timestamp  = (Get-Date).ToString("o")
            player     = $player
            group      = $groupPassphrase
        }
        Send-EventToServer $eventObject
    }
    elseif ($line -match $RegexLoadingScreen) {
        $eventObject = @{
            event_type = "loading_screen"
            timestamp  = (Get-Date).ToString("o")
            group      = $groupPassphrase
        }
        Send-EventToServer $eventObject
    }
    elseif ($line -match $RegexKill) {
        $killer = $Matches["killer"]
        $victim = $Matches["victim"]
        $eventObject = @{
            event_type = "kill"
            timestamp  = (Get-Date).ToString("o")
            killer     = $killer
            victim     = $victim
            group      = $groupPassphrase
        }
        Send-EventToServer $eventObject
    }
    elseif ($line -match $RegexVehicleDestruction) {
        $vehicle = $Matches["vehicle"]
        $player  = $Matches["player"]
        $eventObject = @{
            event_type = "vehicle_destruction"
            timestamp  = (Get-Date).ToString("o")
            vehicle    = $vehicle
            player     = $player
            group      = $groupPassphrase
        }
        Send-EventToServer $eventObject
    }
    elseif ($line -match $RegexZoneChange) {
        $player = $Matches["player"]
        $zone   = $Matches["zone"]
        $eventObject = @{
            event_type = "zone_change"
            timestamp  = (Get-Date).ToString("o")
            player     = $player
            zone       = $zone
            group      = $groupPassphrase
        }
        Send-EventToServer $eventObject
    }
}
