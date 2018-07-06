
New Version:
Previews are under seperate package ids - so a given update needs to apply to either the releases packages or preview packages.
1. ChocolateyInstall.ps1 - Update all install links and checksums from MS release page.
2. ChocolateyInstall.ps1 - Update version number.
3. ChocolateyUninstall.ps1 - Update version number.
4. powershell-core.nuspec - update version number.
5. powershell-core.nuspec - update product release notes.
6. powershell-core.nuspec - update package release notes.

Testing:
1. Test that new desktop icon is installed
2. Open desktop icon and check results of $psversiontable