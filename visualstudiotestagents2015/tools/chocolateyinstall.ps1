$ErrorActionPreference = 'Stop'; # stop on all errors

$packageName= 'visualstudio2015testagents'
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$fileType   = 'EXE'
$url        = 'https://download.microsoft.com/download/8/A/F/8AFFDD5A-53D9-46EB-98D7-B61BBCAF0DE6/vstf_testagent.exe'
$logPath    = "$env:temp\vstestagents2015install.log"
$silentArgs = "/Full /NoRestart /Q /Log $logPath"
$validExitCodes = @(0,3010,1641)

$checksum      = $checksum64     ='EB982D5B9C23DB45824DEAD444F2DB08CC3C741F'
$checksumType  = $checksumType64 = 'sha1'

Write-Output "Logs for installer is here: $logPath"

Install-ChocolateyPackage -PackageName "$packageName" -FileType $fileType -SilentArgs $SilentArgs -url $url -validExitCodes $validExitCodes -checksum $checksum -checksumType $checksumType
