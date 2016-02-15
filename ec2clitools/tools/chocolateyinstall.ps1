
$ErrorActionPreference = 'Stop'; # stop on all errors

$packageName= 'win32-openssh'
$packageVersion = '1.7.5.1'
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url        = 'http://s3.amazonaws.com/ec2-downloads/ec2-api-tools.zip'
$checksum = '51D6D7DFAFBFEDF74C743DAB6B9B58A4E48232DF'
$checksumtype = 'sha1'

Install-ChocolateyZipPackage $packageName $url $toolsDir -checksum $checksum -checksumType $checksumType

Install-ChocolateyEnvironmentVariable -variableName 'EC2_HOME' -variableValue "C:\ProgramData\chocolatey\lib\win32-openssh\tools\ec2-api-tools-$packageVersion" -variableType 'Machine'

Install-ChocolateyPath "`%EC2_HOME`%\bin" 'Machine'

Write-Warning "You must start a new prompt, or re-read the environment for the tools to be available in your command line environment."

Write-Warning "For completely automatic operation you must set the environment variables AWS_ACCESS_KEY and AWS_SECRET_KEY, for details see: http://docs.aws.amazon.com/AWSEC2/latest/CommandLineReference/set-up-ec2-cli-windows.html"
