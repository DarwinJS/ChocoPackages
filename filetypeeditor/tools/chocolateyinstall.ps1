$ErrorActionPreference = 'Stop';

$packageName= 'filetypeeditor'
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url        = 'http://www.gunnerinc.com/files/gfte.zip'

$packageArgs = @{
  packageName   = $packageName
  unzipLocation = $toolsDir
  fileType      = 'EXE_MSI_OR_MSU'
  url           = $url
  softwareName  = 'filetypeeditor*'
  checksum      = '0ED8A83A537ECACADB53886069FEC3B80137C33F6B8533C6158E0A6B47051AA0'
  checksumType  = 'sha256'

  validExitCodes= @(0, 3010, 1641)
}

Install-ChocolateyZipPackage @packageArgs

Write-Output "********************************************************************"
Write-Output "*  INSTRUCTIONS: Type `"gfte.exe`" to edit file type associations. *"
Write-Output "*       More Info: http://www.gunnerinc.com/gfte.htm            *"
Write-Output "********************************************************************"
