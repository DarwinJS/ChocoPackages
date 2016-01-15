$packageName = 'systemexplorer' # arbitrary name for the package, used in messages
$url = 'http://systemexplorer.net/download-archive/6.4.2/SystemExplorerPortable_642.zip'
$url = 'http://www.softpedia.com/dyn-postdownload.php/015070120cbf7e2b4a26d0a09325cfdd/5592f250/14a8a/0/4'
$validExitCodes = @(0)
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"

Install-ChocolateyZipPackage "$packageName" "$toolsDir\SystemExplorerPortable_700.zip" "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"

Write-Output "******************************************************************************"
Write-Output "*  INSTRUCTIONS: Type `"systemexplorer.exe`" to edit file type associations. *"
Write-Output "*       More Info: http://systemexplorer.net                                 *"
Write-Output "******************************************************************************"
