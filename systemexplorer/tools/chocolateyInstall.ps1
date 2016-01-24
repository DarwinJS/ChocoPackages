$packageName = 'systemexplorer' # arbitrary name for the package, used in messages
$url = 'http://systemexplorer.net/download-archive/6.4.2/SystemExplorerPortable_642.zip'
$url = 'http://www.softpedia.com/dyn-postdownload.php/015070120cbf7e2b4a26d0a09325cfdd/5592f250/14a8a/0/4'
$validExitCodes = @(0)
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$exeName = 'systemexplorer.exe'

$AppPathKey = "Registry::HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$exeName"
If (!(Test-Path $AppPathKey)) {New-Item "$AppPathKey" | Out-Null}
Set-ItemProperty -Path $AppPathKey -Name "(Default)" -Value "$env:chocolateyinstall\lib\$packagename\tools\$exeName"
Set-ItemProperty -Path $AppPathKey -Name "Path" -Value "$env:chocolateyinstall\lib\$packagename\tools\"

Install-ChocolateyZipPackage "$packageName" "$toolsDir\SystemExplorerPortable_700.zip" "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"


#Create .ignore files so chocolatey does not shim the Exe
$files = get-childitem $toolsDir -include *.exe -recurse
foreach ($file in $files) {
  New-Item "$file.ignore" -type file -force | Out-Null
}

Move-Item "$toolsDir\systemexplorer.exe.ignore" "$toolsDir\systemexplorer.exe.gui" -force

Write-Output "******************************************************************************"
Write-Output "*  INSTRUCTIONS: In the search prompt of your start menu type `"$exeName`"   *"
Write-Output "*   or in a command line type `"$exeName`"                                   *"
Write-Output "*       More Info: http://systemexplorer.net                                 *"
Write-Output "******************************************************************************"
