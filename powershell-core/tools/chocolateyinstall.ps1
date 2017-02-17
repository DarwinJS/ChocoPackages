#Handle:
#Verify auto-uninstall works.
#Check minimum OS - version and 64 bitness

$ErrorActionPreference = 'Stop'; # stop on all errors

$Version = '6.0.0.16'
$InstallFolder = "$env:ProgramFiles\PowerShell\$Version"

$packageName= 'powershell-core' # arbitrary name for the package, used in messages
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$urlwin10   = 'https://github.com/PowerShell/PowerShell/releases/download/v6.0.0-alpha.16/PowerShell_6.0.0-alpha.16-win10-win2016-x64.msi'
$checksumwin10 = 'FFE54DEB7BB04269318DC6C31F6C682C7B705CBCDA8BA37A6BE2B4955BB11940'
$urlwin8      = 'https://github.com/PowerShell/PowerShell/releases/download/v6.0.0-alpha.16/PowerShell_6.0.0-alpha.16-win81-win2012r2-x64.msi'
$checksumwin8 = '58C704DF587BAAA760CA60EFB5C5A6FC9257D114CEFEBC7C824D21A876FC1434'
$urlwin7      = 'https://github.com/PowerShell/PowerShell/releases/download/v6.0.0-alpha.16/PowerShell_6.0.0-alpha.16-win7-win2008r2-x64.msi'
$checksumwin7 = '5825CE8626213E2CCD56C4071D87659C2EB6C33F38A4EA92AE9FEF357AB323A6'
$urlwin732      = 'https://github.com/PowerShell/PowerShell/releases/download/v6.0.0-alpha.16/PowerShell_6.0.0-alpha.16-win7-x86.msi'
$checksumwin732 = 'D053765B2000E3E6934E65CE43764C6A9DADF56E7848ACCF7A44895365A064BB'

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
