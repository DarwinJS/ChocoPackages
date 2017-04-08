$ErrorActionPreference = 'Stop';

$packageName = 'powershell-core'
$VersionMaj = '6.0.0'
$versionMinor = '18'
$Version = "$VersionMaj.$versionMinor"
$PFSubfolder = "$VersionMaj-alpha.$versionMinor"
$softwareName = 'powershell_6*'
$installerType = 'MSI'
$InstallFolder = "$env:ProgramFiles\PowerShell\$Version"

$silentArgs = '/qn /norestart'
$validExitCodes = @(0, 3010, 1605, 1614, 1641)

$uninstalled = $false
[array]$key = Get-UninstallRegistryKey -SoftwareName $softwareName

if ($key.Count -eq 1) {
  $key | % {
    $file = "$($_.UninstallString)"

    if ($installerType -eq 'MSI') {
      $silentArgs = "$($_.PSChildName) $silentArgs"
      $file = ''
    }

    Uninstall-ChocolateyPackage -PackageName $packageName `
                                -FileType $installerType `
                                -SilentArgs "$silentArgs" `
                                -ValidExitCodes $validExitCodes `
                                -File "$file"
  }
} elseif ($key.Count -eq 0) {
  Write-Warning "$packageName has already been uninstalled by other means."
} elseif ($key.Count -gt 1) {
  Write-Warning "$key.Count matches found!"
  Write-Warning "To prevent accidental data loss, no programs will be uninstalled."
  Write-Warning "Please alert package maintainer the following keys were matched:"
  $key | % {Write-Warning "- $_.DisplayName"}
}

$shortcutname = "PowerShell_$Version"
$shortcutpaths = @("$([Environment]::GetFolderPath('CommonDesktopDirectory'))", "$([Environment]::GetFolderPath('CommonStartMenu'))\Programs\PowerShell_$version")
Foreach ($SCPath in $shortcutpaths)
{
  If (Test-Path "$SCPath\$shortcutname") {Remove-Item "$SCPath\$shortcutname" -force}
  If ((Get-ChildItem "$SCPath").count -lt 1) {Remove-Item "$SCPath" -force}
}

If ((get-childitem $InstallFolder).count -lt 1)
{
  Remove-Item $InstallFolder -Force
}
