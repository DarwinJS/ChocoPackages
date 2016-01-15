
Uninstall-ChocolateyPackage -PackageName 'registrymanager' -FileType 'exe' -SilentArgs "/SILENT /LOG" -File "C:\Program Files\Registrar Registry Manager\unins000.exe" -ValidExitCodes @(0,3010)
