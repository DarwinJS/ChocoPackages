
$ErrorActionPreference = 'Stop';

$packageName= 'powershell-core'
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$VersionMaj = '6.0.0'
$versionMinor = '7'
$Version = "$VersionMaj.$versionMinor"
$PFSubfolder = "$VersionMaj-beta.$versionMinor"
$InstallFolder = "$env:ProgramFiles\PowerShell\$PFSubfolder"

If (Test-Path "$InstallFolder\powershell.exe")
{
  Write-output "$packagename version $PFSubfolder is already installed by another means."
  Exit 0
}

$packageArgs = @{
  packageName   = $packageName
  unzipLocation = $toolsDir
  fileType      = 'MSI'
  url           = 'https://github.com/PowerShell/PowerShell/releases/download/v6.0.0-beta.7/PowerShell-6.0.0-beta.7-win-x86.msi'
  url64bit      = 'https://github.com/PowerShell/PowerShell/releases/download/v6.0.0-beta.7/PowerShell-6.0.0-beta.7-win-x64.msi'

  softwareName  = "PowerShell-6.0.0*"

  checksum      = '46237804A38F08C3F1E290C710DA6CAF22876B07C15D2C9BEF72E9DE47CFD667'
  checksumType  = 'sha256'
  checksum64    = 'B9105EF2F52EE30DB7082039BC3AED84743E2BAE883B9220F7AD6B2C76BA662F'
  checksumType64= 'sha256'

  silentArgs    = "/qn /norestart /l*v `"$($env:TEMP)\$($packageName).$($env:chocolateyPackageVersion).MsiInstall.log`"" # ALLUSERS=1 DISABLEDESKTOPSHORTCUT=1 ADDDESKTOPICON=0 ADDSTARTMENU=0
  validExitCodes= @(0, 3010, 1641)
  }

Install-ChocolateyPackage @packageArgs

Write-Output "************************************************************************************"
Write-Output "*  INSTRUCTIONS: Your system default PowerShell version has not been changed:      *"
Write-Output "*   To start PowerShell Core $version, execute:                                    *"
Write-Output "*      `"$installfolder\PowerShell.exe`"                                *"
Write-Output "*   Or start it from the desktop or start menu shortcut installed by this package. *"
Write-Output "************************************************************************************"
