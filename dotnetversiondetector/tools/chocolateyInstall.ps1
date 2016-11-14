
$ErrorActionPreference = 'Stop';

$packageName= 'dotnetversiondetector' # arbitrary name for the package, used in messages
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"

$packageArgs = @{
  packageName   = $packageName
  unzipLocation = $toolsDir
  fileType      = 'EXE_MSI_OR_MSU' #only one of these: exe, msi, msu
  url           = "$toolsDir\netver.zip"
  url64bit      = "$toolsDir\netver.zip"
  #file         = "$toolsDir\netver.zip"

  softwareName  = 'dotnetversiondetector*' #part or all of the Display Name as you see it in Programs and Features. It should be enough to be unique
  checksum      = '86AE7A7782C25E5A38CE7A6B94EAD037DD2C6ED500E76FE6D5288D4A8D582738'
  checksumType  = 'sha256' #default is md5, can also be sha1, sha256 or sha512
  checksum64    = '86AE7A7782C25E5A38CE7A6B94EAD037DD2C6ED500E76FE6D5288D4A8D582738'
  checksumType64= 'sha256' #default is checksumType
}

Install-ChocolateyZipPackage @packageArgs # https://chocolatey.org/docs/helpers-install-chocolatey-zip-package


Write-Output ""
Write-Output "**********************************************************************************************************"
Write-Output "*  INSTRUCTIONS: At a shell prompt, type 'dotnet' to start the dot net version detector utility          *"
Write-Output "**********************************************************************************************************"
Write-Output ""
