$packageName = 'virtualmachineconverter'
$installerType = 'MSI'
$url = 'http://download.microsoft.com/download/9/1/E/91E9F42C-3F1F-4AD9-92B7-8DD65DA3B0C2/mvmc_setup.msi'
$validExitCodes = @(0,3010)
$silentArgs = "{332C1E78-1D2F-4A64-B718-68095DC6254B} /qn /l*v `"$env:temp\uninstallvirtualmachineconverter.log`""

Uninstall-ChocolateyPackage -PackageName $packageName `
                                -FileType $installerType `
                                -SilentArgs "$silentArgs" `
                                -ValidExitCodes $validExitCodes
