$ErrorActionPreference = 'Stop'; # stop on all errors

$packageName= 'visualstudio2015testagents'
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$fileType   = 'EXE'
$url        = 'https://download.microsoft.com/download/6/0/e/60e06c19-2bfd-40da-8af8-4cd7b897a336/vstf_testagent.exe'
$logPath    = "$env:temp\$packageName_$(Get-date -format 'yyyyMMddhhmm').log"
$silentArgs = "/Full /NoRestart /Q /Log $logPath"
$validExitCodes = @(0,3010,1641)

$checksum      = $checksum64     ='94DE041C6843010EFB38791C1A9FD27B426EFBD5'
$checksumType  = $checksumType64 = 'sha1'

Write-Output "Logs for installer is here: $logPath"

Install-ChocolateyPackage -PackageName "$packageName" -FileType $fileType -SilentArgs $SilentArgs -url $url -validExitCodes $validExitCodes -checksum $checksum -checksumType $checksumType
