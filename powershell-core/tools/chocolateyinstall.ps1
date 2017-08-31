
$ErrorActionPreference = 'Stop';

$VersionMaj = '6.0.0'
$versionMinor = '6'
$Version = "$VersionMaj.$versionMinor"
$PFSubfolder = "$VersionMaj-beta.$versionMinor"

$InstallFolder = "$env:ProgramFiles\PowerShell\$PFSubfolder"

$packageName= 'powershell-core'
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$urlwin10   = 'https://github.com/PowerShell/PowerShell/releases/download/v6.0.0-beta.6/PowerShell-6.0.0-beta.6-win10-win2016-x64.msi'
$checksumwin10 = '2F0F6F030F254590C63CD47CC3C4CD1952D002639D2F27F37E616CD2A5DDE84C'
$urlwin8      = 'https://github.com/PowerShell/PowerShell/releases/download/v6.0.0-beta.6/PowerShell-6.0.0-beta.6-win81-win2012r2-x64.msi'
$checksumwin8 = '2FCC755B89F8EEF697BBB536623FF6A4A1A2A169DD0C8F251AF916CA6C9392B7'
$urlwin7      = 'https://github.com/PowerShell/PowerShell/releases/download/v6.0.0-beta.6/PowerShell-6.0.0-beta.6-win7-win2008r2-x64.msi'
$checksumwin7 = 'D79E770D12EB0EA64BCEB30496AD81421165092BE3388230EB763660F7A726C7'
$urlwin732      = 'https://github.com/PowerShell/PowerShell/releases/download/v6.0.0-beta.6/PowerShell-6.0.0-beta.6-win7-x86.msi'
$checksumwin732 = '685F21A1C8C4F0348BBF6159C52AAC67CDE789FBEAF2F0D448551BA36A6287EC'

$OSBits = ([System.IntPtr]::Size * 8)
$Net4Version = (get-itemproperty "hklm:software\microsoft\net framework setup\ndp\v4\full" -ea silentlycontinue | Select -Expand Release -ea silentlycontinue)
$osVersion = (Get-WmiObject Win32_OperatingSystem).Version

If (($OSBits -lt 64) -AND ($_ -gt [version]"6.2"))
{
  Throw "$packageName $PFSubfolder is only available for 64-bit editions of this version of Windows.  32-bit is available for Windows 7 / Server 2008 only."
}

If (Test-Path "$InstallFolder\powershell.exe")
{
  Write-output "$packagename version $PFSubfolder is already installed by another means."
  Exit 0
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

$packageArgs = @{
  packageName   = $packageName
  unzipLocation = $toolsDir
  fileType      = 'MSI'
  url           = $selectedURL
  url64bit      = $selectedURL

  softwareName  = "PowerShell-6.0.0*"

  checksum      = $selectedChecksum
  checksumType  = 'sha256'
  checksum64    = $selectedChecksum
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
