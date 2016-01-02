$packageName = 'previewconfig' # arbitrary name for the package, used in messages
$url = 'http://www.winhelponline.com/utils/previewconfig.zip' # download url
$validExitCodes = @(0)
$checksum      = '5BB3D6BD48086D604685C2C1EC06F98B6BA4BB18'
$checksumType  = 'sha1'

Install-ChocolateyZipPackage "$packageName" "$url" "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"  -checksum $checksum -checksumType $checksumType

Write-Output "*************************************************************************************************************************************"
Write-Output "*  INSTRUCTIONS: Type `"previewconfig.exe`" to edit file type associations.                                                         *"
Write-Output "*       More Info: http://www.winhelponline.com/blog/previewconfig-tool-registers-file-types-for-the-preview-pane-in-windows-vista/ *"
Write-Output "*************************************************************************************************************************************"
