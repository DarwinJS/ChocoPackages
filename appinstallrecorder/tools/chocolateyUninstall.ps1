$packageName = 'appinstallrecorder'

$targetfolder = "$env:programdata\$packagename"
Remove-Item "$targetfolder\AppInstallPlayback.cmd"
Remove-Item "$targetfolder\Capture-Recording.ps1"

Remove-Item -Recurse -Force "$([Environment]::GetFolderPath('CommonDesktopDirectory'))\App Install Recorder Scripts.lnk"
Remove-Item -Recurse -Force "$([Environment]::GetFolderPath('CommonStartMenu'))\App Install Recorder Scripts.lnk"



Uninstall-ChocolateyZipPackage $packageName AppInstallRecorderScripts.zip
