#Handle:
# Check if already installed at "ProgramFiles64Folder\PowerShell\6.0.0.12" or "ProgramFilesFolder\PowerShell\6.0.0.12" and mark complete (already insetalled message) if so
# Handle correct MSI for Win 8 verus Win 10 MSI - including for Server osBitness
#Verify auto-uninstall works.
#Create package for alpha 11 and 12 to check side-by-side installs and
#Check minimum OS - version and 64 bitness

# Instructions messsage:
#check and warn if this version will take over default powershell processor OR if the user must manually specify the powershell path to use 6.

$ErrorActionPreference = 'Stop'; # stop on all errors

$packageName= 'powershell-core' # arbitrary name for the package, used in messages
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$urlwin10   = 'https://github.com/PowerShell/PowerShell/releases/download/v6.0.0-alpha.12/PowerShell_6.0.0.12-alpha.12-win10-x64.msi'
$checksumwin10 = 'F3C3F3276462588E24BFE197DAA8795140E37557596861126D54462561C98671'
$urlwin8      = 'https://github.com/PowerShell/PowerShell/releases/download/v6.0.0-alpha.12/PowerShell_6.0.0.12-alpha.12-win81-x64.msi'
$checksumwin8 = '5FEB757346D5ED6FA6786ACDA96D0361663EE4DCBB719D53E6C32835BFD8C670'

$OSBits = ([System.IntPtr]::Size * 8) #Nano compatible
$Net4Version = (get-itemproperty "hklm:software\microsoft\net framework setup\ndp\v4\full" -ea silentlycontinue | Select -Expand Release -ea silentlycontinue)
$osVersion = (Get-WmiObject Win32_OperatingSystem).Version

If ($OSBits -lt 64)
{
  Throw "$packageName $version is only available for 64-bit editions of Windows."
}


switch ([version]$osVersion) {
  {($_ -ge [version]"10.0")} {
      Write-Output "Windows 10 / Server 2016 or later."
      $selectedURL = $urlwin10
      $selectedChecksum = $checksumwin10
    }
  {($_ -ge [version]"6.2") -AND ($_ -lt [version]"6.4")} {
      Write-Output "Windows 8 or Server 2012 or later."
      $selectedURL = $urlwin8
      $selectedChecksum = $checksumwin8
    }
  default {
      Write-warning "PowerShell Core is only supported on Windows 8 or later, exiting..."
      Exit 0
    }
  }

$Version = '6.0.0.12'
$InstallFolder = "$env:ProgramFiles\$Version"

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
