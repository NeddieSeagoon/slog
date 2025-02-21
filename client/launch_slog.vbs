Set objShell = CreateObject("Wscript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")
' Get the folder containing this VBScript
strFolder = objFSO.GetParentFolderName(WScript.ScriptFullName)
' Build the full path to your PowerShell script
strScriptPath = objFSO.BuildPath(strFolder, "slog.ps1")
' Run the PowerShell script with a hidden window
objShell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -File """ & strScriptPath & """", 1, True
' objShell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & strScriptPath & """", 1, True
