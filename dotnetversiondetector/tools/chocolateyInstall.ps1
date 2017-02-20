
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
  checksum      = '4DA421599E5237B0005D8076D5D6880D2D018FE838EE5128447F0D38223E1F51'
  checksumType  = 'sha256' #default is md5, can also be sha1, sha256 or sha512
  checksum64    = '4DA421599E5237B0005D8076D5D6880D2D018FE838EE5128447F0D38223E1F51'
  checksumType64= 'sha256' #default is checksumType
}

Install-ChocolateyZipPackage @packageArgs # https://chocolatey.org/docs/helpers-install-chocolatey-zip-package


Write-Output ""
Write-Output "**********************************************************************************************************"
Write-Output "*  INSTRUCTIONS: At a shell prompt, type 'dotnet' to start the dot net version detector utility          *"
Write-Output "**********************************************************************************************************"
Write-Output ""
