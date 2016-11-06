$PackageName = 'appinstallrecorder'
$url = 'https://msdnshared.blob.core.windows.net/media/MSDNBlogsFS/prod.evol.blogs.msdn.com/CommunityServer.Components.PostAttachments/00/10/55/52/66/AppInstallRecorderScripts.zip'
$validExitCodes = @(0)
$checksum      = '9C909029F8354E616185BFF964D09A0F5FAAE303'
$checksumType  = 'sha1'

Install-ChocolateyZipPackage "$packageName" "$url" "$(Split-Path -parent $MyInvocation.MyCommand.Definition)" -checksum $checksum -checksumType $checksumType

$sourcefolder = "$env:chocolateyinstall\lib\$packagename\tools"
$targetfolder = "$env:programdata\$packagename"

Write-Output "Target folder: $targetfolder"

If (!(Test-Path "$targetfolder")) {New-Item "$targetfolder" -ItemType Directory }
Copy-Item "$sourcefolder\*" "$targetfolder" -exclude "Chocolatey*install.ps1" -Force
$shortcutpaths = @("$([Environment]::GetFolderPath('CommonDesktopDirectory'))", "$([Environment]::GetFolderPath('CommonStartMenu'))")

$codeblock = "{Write-output `'Create `"packages`" from filtered procmon traces.  Launching Help...`' ;  start `'http://blogs.msdn.com/b/aaron_margosis/archive/2014/09/05/the-case-of-the-app-install-recorder.aspx`'} ; dir"

Foreach ($SCPath in $shortcutpaths)
{
  If (Test-Path $SCPath)
  {
    write-output "SCPATH: $SCPath"
    If (Test-Path "$SCPath\App Install Recorder Scripts.lnk") {Remove-Item "$SCPath\App Install Recorder Scripts.lnk" -force}
    Install-ChocolateyShortcut -ShortcutFilePath "$SCPath\App Install Recorder Scripts.lnk" -TargetPath "$env:windir\system32\windowspowershell\v1.0\PowerShell.exe" -Arguments "-noexit & $codeblock" -WorkingDirectory "$targetfolder"
  }
}


Write-Output "***********************************************************************************************************************"
Write-Output "*  INSTRUCTIONS: The scripts are available in $targetpath and shortcuts named `"App Install Recorder Scripts`"          *"
Write-Output "*    have been created on the desktop and start menu that open a PowerShell prompt to that location.                  *"
Write-Output "*    For details on use them see:                                                                                     *"
Write-Output "*      http://blogs.msdn.com/b/aaron_margosis/archive/2014/09/05/the-case-of-the-app-install-recorder.aspx            *"
Write-Output "***********************************************************************************************************************"
