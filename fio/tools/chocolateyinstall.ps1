
$Version = '3.13'

$ErrorActionPreference = 'Stop';
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url        = "$toolsDir\fio-$Version-x86.zip"
$url64      = "$toolsDir\fio-$Version-x64.zip"

$packageArgs = @{
  packageName   = $env:ChocolateyPackageName
  unzipLocation = $toolsDir
  fileType      = 'EXE'
  url           = $url
  url64bit      = $url64
  softwareName  = 'fio*'
  checksum      = '4AAA39C4E11C531B56A28C78E41DA587E6D9083F475C4482D632F4727D269DC8'
  checksumType  = 'sha256'
  checksum64    = 'A187F9F456FE86A93A69BB8C470F248CF7AD23BED15D431ACCBBD4D68FA7AE6B'
  checksumType64= 'sha256'
}

#Parse switches with new support
$pp = Get-PackageParameters

If ($pp['PhysicalDeviceIDsToInitialize']) {
  $PhysicalDeviceIDsToInitialize = $pp['PhysicalDeviceIDsToInitialize']
  Write-Host "/PhysicalDeviceIDsToInitialize was used: $PhysicalDeviceIDsToInitialize"
}

$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
Install-ChocolateyZipPackage @packageArgs

#May not work on Newest Nano due to no "Get-CimInstance" CMDLEt
#Foreach ($PhysicalDrive in ((Get-CimInstance Win32_DiskDrive) | Select -ExpandProperty DeviceID))
#{
#  fio.exe --filename=$PhysicalDrive --rw=randread --bs=128k --iodepth=32 --ioengine=windowsaio --direct=1 --name=volume-initialize
#}

#Parm PhysicalDevicesToInitialize = All | string of positive integers seperated by ';'
If (Test-Path variable:PhysicalDeviceIDsToInitialize)
{
  If ($PhysicalDeviceIDsToInitialize -ieq 'All')
  {
    $PhysicalDriveEnumList = 1..$((get-itemproperty HKLM:SYSTEM\CurrentControlSet\Services\disk\Enum | Select -ExpandProperty Count))
  }
  Elseif ($PhysicalDeviceIDsToInitialize -ne '')
  {
    $PhysicalDriveEnumList = [int[]]($PhysicalDeviceIDsToInitialize -split ';')
  }
}
#Only process if we were actually given a value for PhysicalDriveEnumList
If (Test-Path variable:PhysicalDriveEnumList)
{
  Write-Host "Devices that will be initialized: $($PhysicalDriveEnumList -join ',')"
  Foreach ($DriveEnum in $PhysicalDriveEnumList)
  {
    Write-output "Initializing \\.\PHYSICALDRIVE$DriveEnum"
    fio.exe --filename=\\.\PHYSICALDRIVE$DriveEnum --rw=randread --bs=128k --iodepth=32 --ioengine=windowsaio --direct=1 --name=volume-initialize
  }
}

Write-Output ""
Write-Output "**********************************************************************"
Write-Output "*  INSTRUCTIONS: At a shell prompt, type 'fio' to start fio          *"
Write-Output "**********************************************************************"
Write-Output ""

If (!(Test-Path variable:PhysicalDeviceIDsToInitialize))
{
  Write-Output @"
  **********************************************************************************************
  *  This package can run fio to initialize disks as part of an install by using the parameter: 
    
     -params '"/PhysicalDeviceIDsToInitialize:all"'
     -params '"/PhysicalDeviceIDsToInitialize:0"'
     -params '"/PhysicalDeviceIDsToInitialize:0;3"'
     
  **********************************************************************************************
"@
}