Write-Debug ("Starting " + $MyInvocation.MyCommand.Definition)

[string]$packageName="PowerShell.4.0"

<#
Exit Codes:
    3010: WSUSA executed the uninstall successfully.
    2359303: The update was not found.
#>

Start-ChocolateyProcessAsAdmin "/uninstall /KB:2819745 /quiet /norestart /log:`"$env:TEMP\PowerShell.v4.Uninstall.log`"" -exeToRun "WUSA.exe" -validExitCodes @(3010,2359303) 
Start-ChocolateyProcessAsAdmin "/uninstall /KB:2799888 /quiet /norestart /log:`"$env:TEMP\PowerShell.v4.Uninstall.log`"" -exeToRun "WUSA.exe" -validExitCodes @(3010,2359303)

Write-Warning "$packageName may require a reboot to complete the uninstallation."