#Handle:
#Verify auto-uninstall works.
#Check minimum OS - version and 64 bitness

$ErrorActionPreference = 'Stop'; # stop on all errors

$Version = '6.0.0.15'
$InstallFolder = "$env:ProgramFiles\PowerShell\$Version"

$packageName= 'powershell-core' # arbitrary name for the package, used in messages
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$urlwin10   = 'https://github.com/PowerShell/PowerShell/releases/download/v6.0.0-alpha.15/PowerShell_6.0.0-alpha.15-win10-win2k16-x64.msi'
$checksumwin10 = 'CC52D21F3287E412B9C3B73C98BB5B06F8056D49D63201072216DF92B7F2E59B'
$urlwin8      = 'https://github.com/PowerShell/PowerShell/releases/download/v6.0.0-alpha.15/PowerShell_6.0.0-alpha.15-win81-win2k12r2-x64.msi'
$checksumwin8 = '0E691F474E3B8D7A457995667151CDB9981CEC3BC3834F957B9FAAB5DCB71D3C'
$urlwin7      = 'https://github.com/PowerShell/PowerShell/releases/download/v6.0.0-alpha.15/PowerShell_6.0.0-alpha.15-win7-win2k8r2-x64.msi'
$checksumwin7 = 'D3384B9C8C2B5152B113791193A89DFE4AB01EE94CAF8F995633906258FD14C3'
$urlwin732      = 'https://github.com/PowerShell/PowerShell/releases/download/v6.0.0-alpha.15/PowerShell_6.0.0-alpha.15-win7-x86.msi'
$checksumwin732 = '19CE135B43C8E7FCCE4EBE36000B887EC3B119D8972F6C895369A116FE8039DC'

$OSBits = ([System.IntPtr]::Size * 8)
$Net4Version = (get-itemproperty "hklm:software\microsoft\net framework setup\ndp\v4\full" -ea silentlycontinue | Select -Expand Release -ea silentlycontinue)
$osVersion = (Get-WmiObject Win32_OperatingSystem).Version

If (($OSBits -lt 64) -AND ($_ -gt [version]"6.2"))
{
  Throw "$packageName $version is only available for 64-bit editions of this version of Windows.  32-bit is available for Windows 7 / Server 2008 only."
}

If (Test-Path "$InstallFolder\powershell.exe")
{
  Write-output "$packagename version $vesion is already installed by another means."
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

  softwareName  = "powershell_$version*"

  checksum      = $selectedChecksum
  checksumType  = 'sha256'
  checksum64    = $selectedChecksum
  checksumType64= 'sha256'

  silentArgs    = "/qn /norestart /l*v `"$($env:TEMP)\$($packageName).$($env:chocolateyPackageVersion).MsiInstall.log`"" # ALLUSERS=1 DISABLEDESKTOPSHORTCUT=1 ADDDESKTOPICON=0 ADDSTARTMENU=0
  validExitCodes= @(0, 3010, 1641)
  }

Install-ChocolateyPackage @packageArgs

$codeblock = "{Write-output `'`r`nWARNING: Testing under PowerShell Core on Windows does not account for`r`nplatform differences with Linux or Mac OS.`r`n`'}"
$shortcutname = "PowerShell_$Version"
$shortcutpaths = @("$([Environment]::GetFolderPath('CommonDesktopDirectory'))", "$([Environment]::GetFolderPath('CommonStartMenu'))\Programs\PowerShell_$version")
Foreach ($SCPath in $shortcutpaths)
{
  If (Test-Path "$SCPath\$shortcutname.lnk") {Remove-Item "$SCPath\$shortcutname.lnk" -force}
  Install-ChocolateyShortcut -ShortcutFilePath "$SCPath\$shortcutname.lnk" -TargetPath "$InstallFolder\PowerShell.exe" -IconLocation "$InstallFolder\assets\Powershell_256.ico" -Arguments "-noexit & $codeblock" -WorkingDirectory "$env:home"
}

Write-Output "************************************************************************************"
Write-Output "*  INSTRUCTIONS: Your system default PowerShell version has not been changed:      *"
Write-Output "*   To start PowerShell Core $version, execute:                                    *"
Write-Output "*      `"$installfolder\PowerShell.exe`"                                *"
Write-Output "*   Or start it from the desktop or start menu shortcut installed by this package. *"
Write-Output "************************************************************************************"
