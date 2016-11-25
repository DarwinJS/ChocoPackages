#Handle:
#Verify auto-uninstall works.
#Check minimum OS - version and 64 bitness

$ErrorActionPreference = 'Stop'; # stop on all errors

$Version = '6.0.0.13'
$InstallFolder = "$env:ProgramFiles\$Version"

$packageName= 'powershell-core' # arbitrary name for the package, used in messages
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$urlwin10   = 'https://github.com/PowerShell/PowerShell/releases/download/v6.0.0-alpha.13/PowerShell_6.0.0.13-alpha.13-win10-x64.msi'
$checksumwin10 = '1085c8fae76a9e8984c42a58740b71cf456b48495747453c0ae3a86fb4f1bf2a'
$urlwin8      = 'https://github.com/PowerShell/PowerShell/releases/download/v6.0.0-alpha.13/PowerShell_6.0.0.13-alpha.13-win81-x64.msi'
$checksumwin8 = '486c2494e382a70bf4559a4a56655e352dc34abe83fe02646849b43961f745be'
$urlwin7      = 'https://github.com/PowerShell/PowerShell/releases/download/v6.0.0-alpha.13/PowerShell_6.0.0.13-alpha.13-win7-x64.msi'
$checksumwin7 = '1a64f92533ef50ee412390c0c88aaa4c0e570fe8be7304596901915863747133'
$urlwin732      = 'https://github.com/PowerShell/PowerShell/releases/download/v6.0.0-alpha.13/PowerShell_6.0.0.13-alpha.13-win7-x86.msi'
$checksumwin732 = '95aadecb26ac7d25659cda8960313a25152d9a0d618fae6979922d7ee27b479e'

$OSBits = ([System.IntPtr]::Size * 8)
$Net4Version = (get-itemproperty "hklm:software\microsoft\net framework setup\ndp\v4\full" -ea silentlycontinue | Select -Expand Release -ea silentlycontinue)
$osVersion = (Get-WmiObject Win32_OperatingSystem).Version

If (($OSBits -lt 64) -AND ($_ -gt [version]"6.2"))
{
  Throw "$packageName $version is only available for 64-bit editions of this version of Windows.  32-bit is available for Windows 7 / Server 2008 only."
}

switch ([version]$osVersion) {
  {($_ -ge [version]"10.0")} {
      Write-Output "64-bit Windows 10 / Server 2016 or later."
      $selectedURL = $urlwin10
      $selectedChecksum = $checksumwin10
    }
  {($_ -ge [version]"6.2") -AND ($_ -lt [version]"6.4")} {
      Write-Output "64-bit Windows 8 or Server 2012 or later."
      $selectedURL = $urlwin8
      $selectedChecksum = $checksumwin8
    }
    {($_ -ge [version]"6.0") -AND ($_ -lt [version]"6.2")} {
        If ($OSBits -eq 32)
        {
          $selectedURL = $urlwin732
          Write-Output "32-bit Windows 7 or Server 2008 or later."
          $selectedChecksum = $checksumwin732
        }
        else
        {
          Write-Output "64-bit Windows 7 or Server 2008 or later."
          $selectedURL = $urlwin7
          $selectedChecksum = $checksumwin7
        }
    }  default {
      Write-warning "PowerShell Core is not supported on this version and/or bitness of Windows, exiting..."
      Exit 0
    }
  }

If (Test-Path $InstallFolder)
{
  Write-output "$packagename version $vesion is already installed by another means."
  Exit 0
}

$packageArgs = @{
  packageName   = $packageName
  unzipLocation = $toolsDir
  fileType      = 'MSI'
  url           = $selectedURL
  url64bit      = $selectedURL

  softwareName  = "powershell_$version*"

  checksum      = $selectedChecksum
  checksumType  = 'sha256'
  checksum64    = $selectedChecksum
  checksumType64= 'sha256'

  silentArgs    = "/qn /norestart /l*v `"$($env:TEMP)\$($packageName).$($env:chocolateyPackageVersion).MsiInstall.log`"" # ALLUSERS=1 DISABLEDESKTOPSHORTCUT=1 ADDDESKTOPICON=0 ADDSTARTMENU=0
  validExitCodes= @(0, 3010, 1641)
  }

Install-ChocolateyPackage @packageArgs

Write-Output "****************************************************************"
Write-Output "*  INSTRUCTIONS: To start PowerShell Core $version, execute:   *"
Write-Output "*      `"$installfolder`"   *"
Write-Output "****************************************************************"
