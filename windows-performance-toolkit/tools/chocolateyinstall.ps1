
$ErrorActionPreference = 'Stop';

$packageName= 'wpt'
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url        = 'https://download.microsoft.com/download/6/A/E/6AEA92B0-A412-4622-983E-5B305D2EBE56/adk/adksetup.exe'
$checksum   = '71014E253A1419F0CB784CA98B267C10FFE9D5D4A90AAB223C8A9820CE12EBA5'
$checksumtype = 'sha256'
$url64      = $url
$urlwin101511        = 'https://go.microsoft.com/fwlink/p/?LinkId=823089'
$checksumwin101511 = 'B0F5CD130D9BE84B6AF2A5F3F4BAAF0BFA261431D6F6605FF8C4F026D16D29EB'
$urlwin101607        = 'https://go.microsoft.com/fwlink/p/?LinkId=526740'
$checksumwin101607 = 'B0F5CD130D9BE84B6AF2A5F3F4BAAF0BFA261431D6F6605FF8C4F026D16D29EB'

$os = Get-WmiObject Win32_OperatingSystem
$osVersion = $os.version

$ProductName = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'ProductName').ProductName
$EditionId = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'EditionID').EditionId
$RunningOnString = "$ProductName, ($EditionId), Windows Kernel: $osVersion"
If ([version]$osversion -ge [version]"10.0") {
  $Win10ReleaseID = $(get-itemproperty "hklm:SOFTWARE\Microsoft\Windows NT\CurrentVersion" | select -expand releaseid)
  $RunningOnString += " ($Win10ReleaseID)"
}

Write-Output "Running on: $RunningOnString"

If ([version]$osversion -lt [version]"6.0") 
{
  Throw "Windows Performance Toolkit is only for Windows Vista / Server 2008 and later."
}

If ([version]$osversion -ge [version]"10.0") 
{
  If ($Win10ReleaseID -le "1511")
  {
    $url = $urlwin101511
    $url64 = $urlwin101511
    $checksum = $checksumwin101511
  }
  ElseIf ($Win10ReleaseID -gt "1607")
  {
    $url = $urlwin101607
    $url64 = $urlwin101607
    $checksum = $checksumwin101607
  }
}

$packageArgs = @{
  packageName   = $packageName
  unzipLocation = $toolsDir
  fileType      = 'EXE'
  url           = $url
  url64bit      = $url

  softwareName  = 'wpt*'

  checksum      = $checksum
  checksumType  = $checksumtype
  checksum64    = $checksum
  checksumType64= $checksumtype

  silentArgs    = "/ceip off /installpath `"C:\Program Files (x86)\Windows Kits\8.0`" /promptrestart /log `"$env:temp\adk_wpt_install.log`" /quiet /features OptionId.WindowsPerformanceToolkit"
  validExitCodes= @(0, 3010, 1641)
}

Install-ChocolateyPackage @packageArgs

Write-Output "*************************************************************************************************************************************"
Write-Output "*  INSTRUCTIONS: You can find the toolkit utilities in `"C:\Program Files (x86)\Windows Kits\8.0\Windows Performance Toolkit`".       *"
Write-Output "*************************************************************************************************************************************"