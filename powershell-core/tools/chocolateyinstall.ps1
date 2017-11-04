
$ErrorActionPreference = 'Stop';

$packageName= 'powershell-core'
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$VersionMaj = '6.0.0'
$versionMinor = '8'
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
  url           = 'https://github.com/PowerShell/PowerShell/releases/download/v6.0.0-beta.8/PowerShell-6.0.0-beta.8-win-x86.msi'
  url64bit      = 'https://github.com/PowerShell/PowerShell/releases/download/v6.0.0-beta.8/PowerShell-6.0.0-beta.8-win-x64.msi'

  softwareName  = "PowerShell-6.0.0*"

  checksum      = 'DE41D8F5C0BBAD45D2F092AD415D187089B26F53159ADAC955A6FEB7CA24D94D'
  checksumType  = 'sha256'
  checksum64    = '5134A98417D5BBEF41D315603A2DABD685FEC3828F582CB2072E454E390A08FD'
  checksumType64= 'sha256'

  silentArgs    = "/qn /norestart /l*v `"$($env:TEMP)\$($packageName).$($env:chocolateyPackageVersion).MsiInstall.log`"" # ALLUSERS=1 DISABLEDESKTOPSHORTCUT=1 ADDDESKTOPICON=0 ADDSTARTMENU=0
  validExitCodes= @(0, 3010, 1641)
  }

Install-ChocolateyPackage @packageArgs

Write-Output "************************************************************************************"
Write-Output "*  INSTRUCTIONS: Your system default PowerShell version has not been changed:      *"
Write-Output "*   To start PowerShell Core $version, execute:                                     *"
Write-Output "*      `"$installfolder\PowerShell.exe`"                      *"
Write-Output "*   Or start it from the desktop or start menu shortcut installed by this package. *"
Write-Output "************************************************************************************"

Write-Output "**************************************************************************************"
Write-Output "*  As of OpenSSH 0.0.22.0 Universal Installer, a script is distributed that allows   *"
Write-Output "*  setting the default shell for openssh. You could call it with code like this:     *"
Write-Output "*    If (Test-Path `"$env:programfiles\openssh-win64\Set-SSHDEfaultShell.ps1`")         *"
Write-Output "*      {& `"$env:programfiles\openssh-win64\Set-SSHDEfaultShell.ps1`" [PARAMETERS]}     *"
Write-Output "*  Learn more with this:                                                             *"
Write-Output "*    Get-Help `"$env:programfiles\openssh-win64\Set-SSHDEfaultShell.ps1`"               *"
Write-Output "*  Or here:                                                                          *"
Write-Output "*    https://github.com/DarwinJS/ChocoPackages/blob/master/openssh/readme.md         *"
Write-Output "**************************************************************************************"
