
$ErrorActionPreference = 'Stop';

$VersionMaj = '6.0.0'
$versionMinor = '18'
$Version = "$VersionMaj.$versionMinor"
$PFSubfolder = "$VersionMaj-alpha.$versionMinor"

$InstallFolder = "$env:ProgramFiles\PowerShell\$PFSubfolder"

$packageName= 'powershell-core'
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$urlwin10   = 'https://github.com/PowerShell/PowerShell/releases/download/v6.0.0-alpha.18/PowerShell-6.0.0-alpha.18-win10-win2016-x64.msi'
$checksumwin10 = 'EAE329ED57BBC86D35C752A589C66B4F355FF75E41CB88EF1771AA79A35621F2'
$urlwin8      = 'https://github.com/PowerShell/PowerShell/releases/download/v6.0.0-alpha.18/PowerShell-6.0.0-alpha.18-win81-win2012r2-x64.msi'
$checksumwin8 = 'CE51D1BFF58ED37CA70A14369C81D5E184A4CCC7A7F2EF56AFDFCDD8430DD4D3'
$urlwin7      = 'https://github.com/PowerShell/PowerShell/releases/download/v6.0.0-alpha.18/PowerShell-6.0.0-alpha.18-win7-win2008r2-x64.msi'
$checksumwin7 = '215F05BEDD048B13198B1F8A541B257B6FC64A737F953A02F220471D128A7E4C'
$urlwin732      = 'https://github.com/PowerShell/PowerShell/releases/download/v6.0.0-alpha.18/PowerShell-6.0.0-alpha.18-win7-x86.msi'
$checksumwin732 = '414888AFD70EE9199CE7EB910072D5E5573C90AF393C90C5A2CD53FFE68D75DC'

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
