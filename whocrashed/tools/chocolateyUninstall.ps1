Uninstall-ChocolateyPackage -PackageName 'whocrashed' -FileType 'exe' -SilentArgs "/SILENT /LOG=`"$env:temp\CHOCO-UNINSTALL-whocrashed.log`"" -File "C:\Program Files\WhoCrashed\unins000.exe" -ValidExitCodes @(0,3010)

