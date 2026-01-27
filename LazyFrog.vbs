' LazyFrog Developer Tools Launcher
' This VBScript launches the application in PowerShell 7

Set WshShell = CreateObject("WScript.Shell")
Set FSO = CreateObject("Scripting.FileSystemObject")

' Get the script directory
ScriptDir = FSO.GetParentFolderName(WScript.ScriptFullName)

' PowerShell 7 path
PwshPath = "C:\Program Files\PowerShell\7\pwsh.exe"

' Main script path
MainScript = ScriptDir & "\src\main.ps1"

' Check if PowerShell 7 exists
If Not FSO.FileExists(PwshPath) Then
    MsgBox "PowerShell 7 is required but not found." & vbCrLf & vbCrLf & _
           "Please install from:" & vbCrLf & _
           "https://github.com/PowerShell/PowerShell/releases", _
           vbCritical, "LazyFrog - Error"
    WScript.Quit 1
End If

' Check if main script exists
If Not FSO.FileExists(MainScript) Then
    MsgBox "Cannot find main.ps1" & vbCrLf & vbCrLf & _
           "Expected: " & MainScript, _
           vbCritical, "LazyFrog - Error"
    WScript.Quit 1
End If

' Launch PowerShell 7 with the main script
Command = """" & PwshPath & """ -NoProfile -ExecutionPolicy Bypass -NoLogo -File """ & MainScript & """"
WshShell.Run Command, 1, True
