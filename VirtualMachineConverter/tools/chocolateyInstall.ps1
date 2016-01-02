$packageName = 'virtualmachineconverter'
$installerType = 'MSI'
$url = 'http://download.microsoft.com/download/9/1/E/91E9F42C-3F1F-4AD9-92B7-8DD65DA3B0C2/mvmc_setup.msi'
$InstallerLogLocation = "$env:temp\virtualmachineconverter.log"
$silentArgs = "/qn /l*v $InstallerLogLocation"
$validExitCodes = @(0,3010,1614)
$checksum      = 'F67812339083376507F51A0B28853C38A3488CF7'
$checksumType  = 'sha1'

Write-Output "Installer log file is `"$InstallerLogLocation`" for more details."

Install-ChocolateyPackage "$packageName" "$installerType" "$silentArgs" "$url" -validExitCodes $validExitCodes  -checksum $checksum -checksumType $checksumType
