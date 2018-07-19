Uninstall-ChocolateyPackage -PackageName 'whysoslow' -FileType 'exe' -SilentArgs "/SILENT /LOG=`"$env:temp\CHOCO-UNINSTALL-whysoslow.log`"" -File "C:\Program Files\whysoslow\unins000.exe" -ValidExitCodes @(0,3010)

