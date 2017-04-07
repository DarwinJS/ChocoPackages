
# Overview
Tested On:
* Nano RTM
* Server 2012 R2
* Windows 10 Anniversary (resolvable clashes with Linux extensions are detected and noted by the installer)
* Windows 7 x64

# Design of this package:
1. Source files are internal - making it easier to curate the package into your
own private repository and to use offline.
2. It can be used to install on machines that do not have Chocolatey (Nano TP5)
nor WOW64 (ServerCore w/out WOW64 installed) - see the instructions later in this
document.
3. It can be used to install when target machine being built has no internet access.
4. The scripts included can install Chocolatey in-line and then install this
openssh all in one command line - see later in this document.
5. It can be used to install SSH under docker.

## Utility Script Set-SSHKeyPermissions.ps1
Set-SSHKeyPermissions.ps1 is copied to the SSHD bin folder so that it can be called during install, at any time after install or in a scheduled task.  It sets read permissions for the SSHD service on all "authorized_keys" files found in any user profile folder.

## ssh-lsa.dll Challenges 
Solutions tested on Win 7 w/ PSH 2.0 and Nano Server.
Works with Chocolatey Package and BareBonesInstaller (Nano and non-chocolatey)

### Challenge 1: ssh-lsa.dll requires two reboots to upgrade
ssh-lsa.dll is loaded by lsass.exe (local security account sub-system).  lsass.exe loads so early in the boot process that Windows normal "replace locked files on reboot" support is ineffective (registry key PendingFileRenameOperations).

Consequently the install process must be:
1. Deconfigure ssh-lsa.dll from loading.
2. Reboot to restart lsass.exe without ssh-lsa.dll locked.
3. Run a forced install (because the first run to release ssh-lsa looks like it was a completed install).
4. Reboot to load ssh-lsa.dll.

### Solution 1: Package Support for double reboot scenario
The chocolatey package and barebones installer support this sequence like this:
1. If [a] you run: `choco upgrade openssh -y -params '"/SSHServerFeature"'`, and [b] ssh-lsa.dll needs an upgrade, and [c] it is currently locked - you will receive an error that outlines the next steps. [or `barebones.ps1 -SSHServerFeature`] (if ssh-lsa.dll is not locked or not present, the switch is IGNORED and a regular upgrade happens)
2. Instead, run: `choco upgrade openssh -y -params '"/SSHServerFeature /ReleaseSSHLSAForUpgrade"'` - ssh-lsa.dll will be deconfigured and NOTHING ELSE will be done. [or `barebones.ps1 -SSHServerFeature -ReleaseSSHLSAForUpgrade`]
3. Restart / Reboot the computer to release the lock on ssh-lsa.dll
4. You run: `choco install -force openssh -y -params '"/SSHServerFeature"'` - now that ssh-lsa.dll is not locked (script detects this), the upgrade will proceed.  NOTE: the command has changed to `choco install` and uses the `-force` switch. [or `barebones.ps1 -SSHServerFeature`]
5. Restart / Reboot the computer to ensure ssh-lsa.dll is loaded - key based authentication will not work until you do.

IMPORTANT: /ReleaseSSHLSAForUpgrade is IGNORED if ssh-lsa is NOT actually locked.  So you could technically use it in both above install command lines and it would be safely ignored the second time through.

### Challenge 2: ssh-lsa.dll version number changes even when the code does not.
This wouldn't be a big deal if we didn't have to deal with the problems just described in Challenge 1.  

### Solution 2: Use DLL Size NOT Version number to determine when to upgrade
Due to this fact, these install scripts only try to upgrade ssh-lsa.dll if THE FILE SIZE CHANGES - indicating an actual change in the dll code.  This means you only take in the double-reboot procedure when the code changes - not everytime just because the version of the dll changes.  

As a result, over multiple upgrades using the Chocolatey package it is likely that your ssh-lsa.dll will be an older version because the size has not changed for serveral releases.

We are trying to keep an updated history of the dll size and version here (the behavior of the script is to dynamically compare current dll size to one that is in the current package): https://github.com/DarwinJS/ChocoPackages/blob/master/openssh/history-of-ssh-lsa-dll.md

## Installing on Nano Over the Wire w/out Chocolatey Nor .NET Core Installed (should work for Server 2016 as well)

**Requirements:** PowerShell 5 for the PackageManagement Provider
**Works On:** Nano TP5

1. Open a command line on the target (remoting for Nano) and run:
2. Install-PackageProvider NuGet -forcebootstrap -force
3. Register-PackageSource -name chocolatey -provider nuget -location http://chocolatey.org/api/v2/ -trusted
4. Install-Package openssh -provider NuGet
5. cd ("$env:ProgramFiles\nuget\packages\openssh." + "$((dir "$env:ProgramFiles\nuget\packages\openssh*" | %{[version]$_.name.trimstart('openssh.')} | sort | select -last 1) -join '.')\tools")
6. .".\barebonesinstaller.ps1" #Client Tools only
7. .".\barebonesinstaller.ps1" -SSHServerFeature #SSH Server (& client tools)
8. .".\barebonesinstaller.ps1" -SSHServerFeature -SSHServerPort '5555' #SSH Server on port 5555 (& client tools)
9. .".\barebonesinstaller.ps1" -SSHServerFeature -Uninstall #Uninstall

## Complete Offline Install (w/out Chocolatey, Nor WOW64, Nor PowerShell 5):
1. Expand the openssh .nupkg (rename it to .zip and use your favorite unzipper)
2. Push the ..\tools folder to the target system (use Copy-Item -ToSession for Nano)
3. CD to "..\tools"
4. To install only client tools, run '.\barebonesinstaller.ps1'
5. To install client tools and Server, run '.\barebonesinstaller.ps1 -SSHServerFeature'
6. To uninstall, run '.\barebonesinstaller.ps1 -SSHServerFeature -Uninstall'

## Automatically Installing Chocolatey and Then Win32-OpenSSH in one shot:

### With SSH Server Install
1. Open an ELEVATED PowerShell Prompt
2. Paste this command into the console (get the whole line - it's long and is a single line):
```powershell
   [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {[bool]1};set-executionpolicy RemoteSigned -Force -EA 'SilentlyContinue';iex ((new-object net.webclient).DownloadString('https://raw.githubusercontent.com/DarwinJS/ChocoPackages/master/openssh/InstallChoco_and_win32-openssh_with_server.ps1'))
```

### Only Client Tools:
**Note**: Server EXEs are still placed on machine, but not configured

1. Open an ELEVATED PowerShell Prompt
2. Paste this command into the console (get the whole line - it's long and is a single line):
```powershell
   [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {[bool]1};set-executionpolicy RemoteSigned -Force -EA 'SilentlyContinue';iex ((new-object net.webclient).DownloadString('https://raw.githubusercontent.com/DarwinJS/ChocoPackages/master/openssh/InstallChoco_and_win32-openssh.ps1'))
```

## Installing Using Docker (Dockerfile)
A sample docker file for Server Core 2016 or NanoServer is here: https://github.com/DarwinJS/ChocoPackages/blob/master/openssh/Dockerfile

# Package Parameters

## -params '"/SSHServerFeature"' (Install and Uninstall)
Also install sshd Windows Service - including opening port 22.
If this parameter is not included on an upgrade or uninstall and
the sshd server is installed - an error is generated.  You must
use this switch to indicate you have made preparations for the
sshd service to be interrupted or removed.

## -params '"/SSHAgentFeature"'
Installs SSH Agent Service even if SSHD Server is not being installed.
Requires admin rights to configure service.
This option is automatically set when /SSHServerFeature is used.

## -params '"/SSHServerFeature /SSHServerPort:3834"'
Allows the setup of the SSH server on an alternate port - sometimes done for security or to avoid conflicts with an existing service on port 22.

## -params '"/SSHServerFeature /DeleteServerKeysAfterInstalled"'
When installing the server, server keys are deleted after added to the ssh-agent (you will not have an opportunity to copy them).

## -params '"/DeleteConfigAndServerKeys"' (during uninstall command)
By default an uninstall does not remove config files nor server keys.

## -params '"/UseNTRights"'
By default this install uses PowerShell code that works on operating systems that cannot run the 32-bit ntrights.exe (Nano, Server Core w/out WOW64).
If this code does not work for you, you can use this switch to invoke the 32-bit ntrights.exe
Please be aware that 32-bit ntrights.exe will NOT work on Windows Systems that do not have WOW64 installed - this would mainly
affect Server Core where this feature is optional and not installed by default and Server Nano where 32-bit is not supported.

**Note:** If you have tested and this switch is *absolutely required* for your deployment scenario, please file an issue so that I can enhance the code so that
this switch is not needed for your scenario.

## Ancient Version History

0.0.3.0
- NEW: If ssh-lsa.dll is locked at install time, package schedules it to be updated at reboot
        displays a "CRITICAL" message noting that a reboot is needed.

0.0.2.20161026
- FIX: "Get-FileHash" is only used if it is available

0.0.2.0
- NEW: /SSHAgentFeature - enables SSH agent for use with client tools when /SSHServerFeature is not used.
- NEW: Sample Dockerfile included for Server Core 2016 or Nano.
- FIX: Uninstall improved.
- NEW: InstallChoco_and_win32-openssh.ps1 and InstallChoco_and_win32-openssh_with_server.ps1 both refresh
        the environment after installing OpenSSH so it can be used in the same console it was installed in.
- FIX: ssh-add is only run after ssh-agent is started.
- FIX: sshd and ssh-agent are always started (if installed), however, a warning to reboot is still generated
        if key based authentication is being used.

0.0.0.9
- NEW: Chocolatey package id is now "openssh"
- NEW: Set listenting port with parameter /SSHServerPort
- NEW: Enhanced detection of possible port conflicts with requested listening port
        Specifically calls out Developer Mode SSH (Windows 10 Developer Mode)
- NEW: more complete readme: https://github.com/DarwinJS/ChocoPackages/blob/master/openssh/readme.md
- NEW: install on Nano and ServerCore w/out WOW64 (Chocolatey not needed) like this (PSH 5 required):
    1) Open a command line on the target (remoting for Nano) and run:
    2) Install-Packagerovider NuGet -forcebootstrap -force
    3) Register-PackageSource -name chocolatey -provider nuget -location http://chocolatey.org/api/v2/ -trusted
    4) Install-Package openssh -provider NuGet
    5) cd "$((dir "$env:ProgramFiles\nuget\packages\OpenSSH*\tools" |select -last 1).fullname)"
    6) .".\barebonesinstaller.ps1" -SSHServerFeature
- FIX: to prevent repeatedly adding "ssh-lsa" when already present (on forced installs, etc.)
- FIX: to uninstall to prevent leaving lsa-ssh authentication provider entries on system
- NEW: ource files are now internal (makes for easier curation and easier for above barebonesinstaller.ps1)
- FIX: crashing uninstall script
- FIX: properly add SSH folder to path on Nano

2016.05.30.20160827 (package ID: Win32-OpenSSH)
- Switch "/KeyBasedAuthenticationFeature" is retired - key based authentication always configured when using "/SSHServerFeature"
- With switch /UseNTRights Package uses ntrights.exe on 32-bit windows and on 64-bit windows - ONLY IF THE 32-bit SUBSYSTEM IS INSTALLED - otherwise it attempts to use Posh Code to grant SeAssignPrimaryTokenPrivilege.
Code used for setting rights WITHOUT /UseNTRights was tested as working on Nano, which means it should work on server core without WOW64.

Package explicity sets log level to QUIET because on some systems the current version of sshd repeatedly logs the same line at a rate of about 1 GB / 2 hours with default log settings.
Package incorporates securing of the server keys using the SSH agent as per the product release notes below.