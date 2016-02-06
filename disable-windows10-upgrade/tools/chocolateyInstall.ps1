$packageName = 'disable-windows10-upgrade'
$url7 = 'https://download.microsoft.com/download/C/5/3/C530B84C-857A-4296-BB9E-3BB59EEDF555/Windows6.1-KB3065987-v2-x86.msu'
$checksum7 = '52B432A85AEA3F6CF1BB047D4118A6D4BE9BF5E5'
$url764 = 'https://download.microsoft.com/download/F/6/7/F678BB18-7D81-4BBA-8FED-6388FF7968AD/Windows6.1-KB3065987-v2-x64.msu'
$checksum764 = '9CA3A0214B16471E950221F1B0FA83909547144F'
$url81 = 'https://download.microsoft.com/download/C/4/3/C43C4D83-A249-4026-9A36-1EB796957FA0/Windows8.1-KB3065988-v2-x86.msu'
$checksum81 = '255083866D636E607B5E9B0B4933B9F0E1D65C1E'
$url8164 = 'https://download.microsoft.com/download/F/3/D/F3D9A5A4-75A3-47C8-971E-9D0D09AAF9DC/Windows8.1-KB3065988-v2-x64.msu'
$checksum8164 = 'D6A040EAFF83CC1909C55473C8E208C882AFBF6A'
$validExitCodes = @(0,3010)
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$silentargs = "/quiet /norestart"

#Is It a target verion number (7 thorugh 8.1) and a desktop OS
$os = (Get-WmiObject "Win32_OperatingSystem")
If (([version]$os.version -ge [version]"6.3") -AND ([version]$os.version -lt [version]"10.0") -AND ($os.producttype -eq 1))
{
  $win81 = $True
}
If (([version]$os.version -ge [version]"6.1") -AND ([version]$os.version -lt [version]"6.2") -AND ($os.producttype -eq 1))
{
  $win7 = $True
}

If (!$win7 -AND !$Win81)
{
  Write-Warning "Windows 10 Upgrade Through Windows Update is Not Automatically Offered On This Operating System, Nothing to do."
}
Else
{
  If ($Win7)
  {
    If (-not([bool](get-hotfix | where {$_.hotfixId -eq 'KB3065987'})))
    {
      Write-Output "Applying required hotfix KB3065987"
      Install-ChocolateyPackage "$packageName" 'MSU' "$SilentArgs /log:$env:temp\KB3065987.evtx" -url $url7 -url64 $url764 -checksum $checksum7 -checksumtype 'sha1' -checksum64 $checksum764 -checksumtype64 'sha1' -validExitCodes $validExitCodes
      Write-Warning "This update will require a restart before it becomes active..."
    }
  }
  If ($Win81)
  {
    If (-not([bool](get-hotfix | where {$_.hotfixId -eq 'KB3065988'})))
    {
      Write-Output "Applying required hotfix KB3065988"
      Install-ChocolateyPackage "$packageName" 'MSU' "$SilentArgs /log:$env:temp\KB3065987.evtx" -url $url81 -url64 $url8164 -checksum $checksum81 -checksumtype 'sha1' -checksum64 $checksum8164 -checksumtype64 'sha1' -validExitCodes $validExitCodes
      Write-Warning "This update will require a restart before it becomes active..."
    }
  }

  $REGKey1 = 'Registry::HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
  If (!(Test-Path $REGKey1)) {New-Item "$REGKey1" | Out-Null}
  Set-ItemProperty -Path $REGKey1 -Name "DisableOSUpgrade" -Type DWord -Value 1

  $REGKey2 = 'Registry::HKLM\Software\Policies\Microsoft\Windows\Gwx'
  If (!(Test-Path $REGKey2)) {New-Item "$REGKey2" | Out-Null}
  Set-ItemProperty -Path $REGKey2 -Name "DisableGwx" -Type DWord -Value 1

  Write-Warning "Please check messages above to see if a restart is required."

  Write-Output "************************************************************************************"
  Write-Output "*  To reenable Windows 10 Upgrade Through Windows Update, Uninstall This Package   *"
  Write-Output "************************************************************************************"
}
