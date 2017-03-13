$packageName = 'DotNETVersionDetector' # arbitrary name for the package, used in messages
$url = 'http://www.asoft-ware.com/download.php?id=11' # download url
$validExitCodes = @(0)

Install-ChocolateyZipPackage "$packageName" "$url" "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"

Write-Output "****************************************************************"
Write-Output "*  INSTRUCTIONS: Type `"dotnet.exe`" to display .NET versions. *"
Write-Output "*       More Info: http://www.asoft.be/prod_netver.html        *"
Write-Output "****************************************************************"
