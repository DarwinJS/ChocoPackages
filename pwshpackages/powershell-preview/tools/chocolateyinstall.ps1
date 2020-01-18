
$ErrorActionPreference = 'Stop';

$packageName= 'powershell-preview'
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$Version = "7.0.0-rc.2"
$InstallFolder = "$env:ProgramFiles\PowerShell\7-preview"

$packageArgs = @{
  packageName   = $packageName
  unzipLocation = $toolsDir
  fileType      = 'MSI'
  url           = "https://github.com/PowerShell/PowerShell/releases/download/v$version/PowerShell-$version-win-x86.msi"
  url64bit      = "https://github.com/PowerShell/PowerShell/releases/download/v$version/PowerShell-$version-win-x64.msi"

  softwareName  = "PowerShell-7.0.*"

  checksum      = 'CA90F07DD63B369BCD8B7AC20402AF58FE812E782021B95396996EE280B9DAD9'
  checksumType  = 'sha256'
  checksum64    = 'A903B63F27882B726E81E7A6EE3E52CE3979036A372DDF4F4D62DF8CE5523345'
  checksumType64= 'sha256'

  silentArgs    = "/qn /norestart /l*v `"$($env:TEMP)\$($packageName).$($env:chocolateyPackageVersion).MsiInstall.log`"" # ALLUSERS=1 DISABLEDESKTOPSHORTCUT=1 ADDDESKTOPICON=0 ADDSTARTMENU=0
  validExitCodes= @(0, 3010, 1641)
  }

$pp = Get-PackageParameters

Write-Host "Installing PowerShell Version $Version"

if ($pp.CleanUpPath) {
  Write-Host "/CleanUpSystemPath was used, removing all PowerShell Core path entries before installing"
  & "$toolsDir\Reset-PWSHSystemPath.ps1" -PathScope Machine, User -RemoveAllOccurances
}

If ($PSVersionTable.PSVersion -ilike '7*-preview*')
{
  Write-Warning "You are running this package under PowerShell core preview, replacing an in-use version may be unpredictable or require multiple attempts."
}

Install-ChocolateyPackage @packageArgs

Write-Output "************************************************************************************"
Write-Output "*  INSTRUCTIONS: Your system default PowerShell version has not been changed."
Write-Output "*   PowerShell Core $version, was installed to: `"$installfolder`""
Write-Output "*   To start PowerShell Core $version, at a prompt or the start menu execute:"
Write-Output "*      `"pwsh-preview`""
Write-Output "*   Or start it from the desktop or start menu shortcut installed by this package."
Write-Output "************************************************************************************"

Write-Output "**************************************************************************************"
Write-Output "*  As of OpenSSH 0.0.22.0 Universal Installer, a script is distributed that allows   *"
Write-Output "*  setting the default shell for openssh. You could call it with code like this:     *"
Write-Output "*    If (Test-Path `"$env:programfiles\openssh-win64\Set-SSHDefaultShell.ps1`")         *"
Write-Output "*      {& `"$env:programfiles\openssh-win64\Set-SSHDefaultShell.ps1`" [PARAMETERS]}     *"
Write-Output "*  Learn more with this:                                                             *"
Write-Output "*    Get-Help `"$env:programfiles\openssh-win64\Set-SSHDefaultShell.ps1`"               *"
Write-Output "*  Or here:                                                                          *"
Write-Output "*    https://github.com/DarwinJS/ChocoPackages/blob/master/openssh/readme.md         *"
Write-Output "**************************************************************************************"
