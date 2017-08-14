
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
  checksum      = 'B76345AE3B4AC1401E55149E5BE3CD81D0DAA8A2DD3E2F2318226A49E21C390A'
  checksumType  = 'sha256' #default is md5, can also be sha1, sha256 or sha512
  checksum64    = 'B76345AE3B4AC1401E55149E5BE3CD81D0DAA8A2DD3E2F2318226A49E21C390A'
  checksumType64= 'sha256' #default is checksumType
}

Install-ChocolateyZipPackage @packageArgs # https://chocolatey.org/docs/helpers-install-chocolatey-zip-package

Move-Item $toolsdir\dotnet.exe $toolsdir\dotnetversions.exe -Force


Write-Output ""
Write-Output "**********************************************************************************************************"
Write-Output "*  INSTRUCTIONS: At a shell prompt, type 'dotnetversions' to start the dot net version detector utility          *"
Write-Output "**********************************************************************************************************"
Write-Output ""
