function Show-ConfigurationGUI {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $config = Load-ClientConfig

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Update Log Parser Configuration"
    $form.Size = New-Object System.Drawing.Size(500,400)
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
    
    # Log File Path
    $lblLogFile = New-Object System.Windows.Forms.Label
    $lblLogFile.Location = New-Object System.Drawing.Point(10,80)
    $lblLogFile.Size = New-Object System.Drawing.Size(100,20)
    $lblLogFile.Text = "Log File Path:"
    $form.Controls.Add($lblLogFile)
    
    $txtLogFilePath = New-Object System.Windows.Forms.TextBox
    $txtLogFilePath.Location = New-Object System.Drawing.Point(120,80)
    $txtLogFilePath.Size = New-Object System.Drawing.Size(300,20)
    $txtLogFilePath.Text = $config.log_file_path
    $form.Controls.Add($txtLogFilePath)
    
    $btnBrowse = New-Object System.Windows.Forms.Button
    $btnBrowse.Location = New-Object System.Drawing.Point(430,80)
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
    
    # Group Passphrase
    $lblPassphrase = New-Object System.Windows.Forms.Label
    $lblPassphrase.Location = New-Object System.Drawing.Point(10,120)
    $lblPassphrase.Size = New-Object System.Drawing.Size(100,20)
    $lblPassphrase.Text = "Group Passphrase:"
    $form.Controls.Add($lblPassphrase)
    
    $txtPassphrase = New-Object System.Windows.Forms.TextBox
    $txtPassphrase.Location = New-Object System.Drawing.Point(120,120)
    $txtPassphrase.Size = New-Object System.Drawing.Size(350,20)
    $txtPassphrase.Text = $config.group_passphrase
    $form.Controls.Add($txtPassphrase)
    
    # Debug Mode checkbox
    $chkDebugMode = New-Object System.Windows.Forms.CheckBox
    $chkDebugMode.Location = New-Object System.Drawing.Point(120,160)
    $chkDebugMode.Size = New-Object System.Drawing.Size(150,20)
    $chkDebugMode.Text = "Enable Debug Mode"
    $chkDebugMode.Checked = $config.debug_mode
    $form.Controls.Add($chkDebugMode)
    
    # Function to save updated config
    $SaveConfig = {
        $config.server_url       = $txtServerUrl.Text
        $config.log_file_path    = $txtLogFilePath.Text
        $config.group_passphrase = $txtPassphrase.Text
        $config.debug_mode       = $chkDebugMode.Checked
        $config | ConvertTo-Json | Out-File $ConfigFilePath
    }

    # Auto-save on change for all controls
    $txtServerUrl.Add_TextChanged({ & $SaveConfig })
    $txtLogFilePath.Add_TextChanged({
        & $SaveConfig
        if (-not (Test-Path $txtLogFilePath.Text)) {
            $lblError.Text = "Log file not found. Please enter a valid path."
        }
        else {
            $lblError.Text = ""
        }
    })
    $txtPassphrase.Add_TextChanged({ & $SaveConfig })
    $chkDebugMode.Add_CheckedChanged({ & $SaveConfig })

    # Check on load if the log file path is valid
    if (-not (Test-Path $txtLogFilePath.Text)) {
        $lblError.Text = "Log file not found. Please enter a valid path."
    }
    
    # Close button to exit GUI
    $btnClose = New-Object System.Windows.Forms.Button
    $btnClose.Location = New-Object System.Drawing.Point(200,210)
    $btnClose.Size = New-Object System.Drawing.Size(100,30)
    $btnClose.Text = "Close"
    $btnClose.Add_Click({ $form.Close() })
    $form.Controls.Add($btnClose)
    
    [void]$form.ShowDialog()
}
