$packageName = 'previewconfig' # arbitrary name for the package, used in messages
$url = 'http://www.winhelponline.com/utils/previewconfig.zip' # download url
$validExitCodes = @(0)

Install-ChocolateyZipPackage "$packageName" "$url" "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"

Write-Output "*************************************************************************************************************************************"
Write-Output "*  INSTRUCTIONS: Type `"previewconfig.exe`" to edit file type associations.                                                         *"
Write-Output "*       More Info: http://www.winhelponline.com/blog/previewconfig-tool-registers-file-types-for-the-preview-pane-in-windows-vista/ *"
Write-Output "*************************************************************************************************************************************"
