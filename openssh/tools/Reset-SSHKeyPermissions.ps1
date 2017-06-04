<#
Features:
* Runs with administrator permissions and processes all users without the need to run in user's context
* Scans for authorizedkey files and only processes those that are present, rather than assuming one exists for each user profile
* Ensures that the found authorizedkeys files is associated with a valid windows profile (compares to ProfileList)
* Uses SIDS from ProfileList to identify user (do not need to know ahead of time if it is a domain account)
* Finds keys for SYSTEM, LocalService and NetworkService - whose profiles are not in the normal profile root

Uses:
* This code runs as part of the OpenSSH installer in order to correct permissions problems
* It can be run (or scheduled) at anytime (including upon creating a new user key) to correct permissions problems
* It can be run when a machine that previously only had SSH client has SSH service (SSHD) installed (in which case permissions need correction)

#>

# Specifies a path to one or more locations. Wildcards are permitted.
Param(
[string]$SSHDUser='NT Service\sshd',
[string]$PathsToCheckForSSHD="$env:programfiles\OpenSSH-Win64;$env:programfiles\OpenSSH-Win32"
)

$UsersFolder = (get-itemproperty "HKLM:software\microsoft\windows nt\currentversion\profilelist" | Select-Object -expand ProfilesDirectory)
$UserProfileList = Get-ItemProperty 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\ProfileList\*'

$banner = @"

*****************************************
https://CloudyWindows.io SSH Utility Script - Reset-SSHKeyPermissions.ps1
Run 'Reset-SSHKeyPermissions' at a PowerShell Prompt each time you add an authorized_keys file
or Install SSHD service.  It can also be set up in the task scheduler.
This script is meant to make your ssh config and keys compliant with the guidelines
published here: https://github.com/PowerShell/Win32-OpenSSH/wiki/Security-protection-of-various-files-in-win32-openssh
However, this script is not part of the OpenSSH distribution, so please report any problems with it 
at: https://github.com/DarwinJS/ChocoPackages/issues

"@

Write-Output $banner

If (![bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544"))
{ Throw 'Administrator Rights are Required to run this code.'}

. "$(Split-Path -parent $MyInvocation.MyCommand.Definition)\SSH-PermsFunctions.ps1"

$NotificationMsg = @'
ATTENTION:
Gathering the list of key files - which is filtered by valid user profiles in the 
ProfileList registry subkey - this ensures that Windows has properly created the 
user profile folder and finds all profiles regardless of storage location.

IF YOUR KEY FILE IS SKIPPED - it is likely that the profile folder was
not created by Windows and does not appear as a subkey of:
"HKLM:\Software\Microsoft\Windows NT\CurrentVersion\ProfileList"
'@

Write-Host $NotificationMsg

#If SSHD service is present, then apply Steps 1 & 2 from: https://github.com/PowerShell/Win32-OpenSSH/wiki/Security-protection-of-various-files-in-win32-openssh#transitioning-existing-keys-and-files-to-v00130
[string]$OpenSSHDPath
[string[]]$PathsToCheckForSSHD = $PathsToCheckForSSHD -split ';'
ForEach ($PathToCheck in $PathsToCheckForSSHD)
{
  Write-Host "    Probing `"$PathToCheck`" for sshd.exe"
  If (Test-Path "$PathToCheck\sshd.exe")
  {
    $OpenSSHDPath = $PathToCheck
    Break
  }
}

If (!$OpenSSHDPath)
{
  Write-Host "    SSHD Service was NOT FOUND, re-run this script (Reset-SSHKeyPermissions.ps1) if you install SSHD Service at a later time."
  Write-Host "    If you have installed SSHD in a custom location, call this script with -PathsToCheckForSSHD <custompath>"
}
Else
{
  Write-Host "    SSHD Service was found at `"$OpenSSHDPath`", ensuring permissions are setup correctly for server keys."
  $HostPublicKeysList = @(Get-ChildItem "$OpenSSHDPath\ssh_host_*.pub" -include '*.pub')
  $HostPrivateKeysList = @(Get-ChildItem "$OpenSSHDPath\ssh_host_*" -exclude '*.pub')
  
  #$SSHDUserObj = New-Object System.Security.Principal.NTAccount($SSHDUser)
  $SSHDUserObj = $SSHDUser

  ForEach ($HostPrivateKeyPath in @($HostPrivateKeysList | Select-Object -Expand FullName))
  {
    Write-Host "      Securing `"$HostPrivateKeyPath`" for user `"$SSHDUserObj`""
    Set-SecureFileACL "$HostPrivateKeyPath" -owner "$SSHDUserObj"
    Add-PermissionToFileACL -FilePath "$HostPrivateKeyPath" -User "$SSHDUserObj" -Perm "Read"
  }

  ForEach ($HostPublicKeyPath in @($HostPublicKeysList | Select-Object -Expand FullName))
  {
    Write-Host "      Securing `"$HostPublicKeyPath`" for user `"$SSHDUserObj`""
    Add-PermissionToFileACL -FilePath "$HostPublicKeyPath" -User "$SSHDUserObj" -Perm "Read"    
  }
}

Write-Host "    Securing any user authorized_keys files."

$AuthorizedKeyFileList = $null
#If any authorized_keys files are present, then apply Steps 3 & 4 from: https://github.com/PowerShell/Win32-OpenSSH/wiki/Security-protection-of-various-files-in-win32-openssh#transitioning-existing-keys-and-files-to-v00130
#Find authorized_keys files that are a part of a valid windows profile
ForEach ($ValidUserProfile in @($UserProfileList))
{
  $ValidUserProfileFolder = $ValidUserProfile.ProfileImagePath
  If (Test-Path "$ValidUserProfileFolder\.ssh\authorized_keys")
  {
    Write-Host "      Found `"$ValidUserProfileFolder\.ssh\authorized_keys`", will attempt to update permissions for this file."
    $AuthorizedKeyFile = "$ValidUserProfileFolder\.ssh\authorized_keys"
    $userprofilepath = $(split-path -parent (split-path -parent $AuthorizedKeyFile))
    
    #Find user name using SID so we don't have to know if it is a domain account:
    $objSID = New-Object System.Security.Principal.SecurityIdentifier($ValidUserProfile.PSChildName)
    $objUser = $objSID.Translate([System.Security.Principal.NTAccount])
    
    Write-Host "        Securing `"$AuthorizedKeyFile`" for user `"$objUser`""
    Set-SecureFileACL "$AuthorizedKeyFile" -owner $objUser

    If ($OpenSSHDPath)
    {
      Write-Host "        Giving read permissions to `"NT Service\SSHD`" for `"$AuthorizedKeyFile`""
      Add-PermissionToFileACL -FilePath "$AuthorizedKeyFile" -User "$SSHDUser" -Perm "Read"
    }

    $UserSSHConfigPath = "$userprofilepath\.ssh\config"
    If (Test-Path $UserSSHConfigPath)
    {
      Write-Host "      Found `"$UserSSHConfigPath`", securing..."
      Set-SecureFileACL "$UserSSHConfigPath" -owner $objUser
    }
    
  }
}

Write-Host "`r`n*****************************************`r`n"