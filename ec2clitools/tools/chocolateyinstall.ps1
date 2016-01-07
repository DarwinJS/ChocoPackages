
$ErrorActionPreference = 'Stop'; # stop on all errors

$packageName= 'ec2clitools'
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url        = 'http://s3.amazonaws.com/ec2-downloads/ec2-api-tools.zip'

Install-ChocolateyZipPackage $packageName $url $toolsDir

Install-ChocolateyEnvironmentVariable -variableName "EC2_HOME" -variableValue "value" -variableType = 'Machine'

Install-ChocolateyPath 'LOCATION_TO_ADD_TO_PATH' 'Machine'
