
$ErrorActionPreference = 'Stop';

$packageName= 'powershell-core'
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$VersionMaj = '6.0.0'
$versionMinor = '9'
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
  url           = 'https://github.com/PowerShell/PowerShell/releases/download/v6.0.0-beta.9/PowerShell-6.0.0-beta.9-win-x86.msi'
  url64bit      = 'https://github.com/PowerShell/PowerShell/releases/download/v6.0.0-beta.9/PowerShell-6.0.0-beta.9-win-x64.msi'

  softwareName  = "PowerShell-6.0.0*"

  checksum      = '9457D98ABF6821D0DDA5BB27CE1B3C0083AB7344B45E6F2345E0BDA7B2BE5DD6'
  checksumType  = 'sha256'
  checksum64    = 'D8A194C8944C4680F27406AC5B341971C546C04279A47C927FAB10D6F5CBFF2A'
  checksumType64= 'sha256'

  silentArgs    = "/qn /norestart /l*v `"$($env:TEMP)\$($packageName).$($env:chocolateyPackageVersion).MsiInstall.log`"" # ALLUSERS=1 DISABLEDESKTOPSHORTCUT=1 ADDDESKTOPICON=0 ADDSTARTMENU=0
  validExitCodes= @(0, 3010, 1641)
  }

Install-ChocolateyPackage @packageArgs

Write-Output "************************************************************************************"
Write-Output "*  INSTRUCTIONS: Your system default PowerShell version has not been changed:      *"
Write-Output "*   To start PowerShell Core $version, execute:                                     *"
Write-Output "*      `"$installfolder\PowerShell.exe`"                   *"
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
