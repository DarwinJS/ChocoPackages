# The Universal Openssh Installer
## Chocolatey NOT REQUIRED
Yes you read that right - although packaged as a chocolatey .nupkg, this installer and it's helper scripts can install completely without Chocolatey in situations where it can't be used (Nano) or you are not allowed to use it.

- [The Universal Openssh Installer](#the-universal-openssh-installer)
    - [Chocolatey NOT REQUIRED](#chocolatey-not-required)
    - [Tested On](#tested-on)
    - [NO RESTRICTIONS](#no-restrictions)
- [Design of this package:](#design-of-this-package)
- [Install Scenario 1: Chocolatey Already Installed](#install-scenario-1-chocolatey-already-installed)
- [Install Scenario 1b: Auto-Install Chocolatey to Install OpenSSH](#install-scenario-1b-auto-install-chocolatey-to-install-openssh)
- [Install Scenario 2: Non-Chocolatey Using PSH 5 PackageManagement](#install-scenario-2-non-chocolatey-using-psh-5-packagemanagement)
- [Install Scenario 3: Docker](#install-scenario-3-docker)
    - [Pre-made Docker Files:](#pre-made-docker-files)
- [Install Scenario 4: Complete Offline Install (w/out Chocolatey, w/out WOW64, w/out PowerShell 5, w/out Internet):](#install-scenario-4-complete-offline-install-w-out-chocolatey-w-out-wow64-w-out-powershell-5-w-out-internet)
- [Package Parameters](#package-parameters)
    - [-params '"/SSHServerFeature"' (Install and Uninstall)](#params-sshserverfeature-install-and-uninstall)
    - [-params '"/SSHAgentFeature"'](#params-sshagentfeature)
    - [-params '"/SSHServerFeature /SSHServerPort:3834"'](#params-sshserverfeature-sshserverport-3834)
    - [-params '"/OverWriteSSHDConf"'](#params-overwritesshdconf)
    - [-params '"/SSHLogLevel:VERBOSE"'](#params-sshloglevel-verbose)
    - [-params '"/SSHServerFeature /DeleteServerKeysAfterInstalled"'](#params-sshserverfeature-deleteserverkeysafterinstalled)
    - [-params '"/DeleteConfigAndServerKeys"' (during uninstall command)](#params-deleteconfigandserverkeys-during-uninstall-command)
    - [-params '"/UseNTRights"'](#params-usentrights)
- [Utility Script Set-SSHKeyPermissions.ps1](#utility-script-set-sshkeypermissions-ps1)
- [Ancient Version History](#ancient-version-history)


## Tested On
* Nano RTM (PSH 5 & PackageManagement & no 32-bit)
* Server 2012 R2 (PSH 4)
* Windows 10 Anniversary (PSH 5, Chocolatey)
* Windows 7 x64 (PSH 2, Chocolatey)

## NO RESTRICTIONS
Other installation methods may require one or more of the following that are NOT required for this universal installer
* **NOT REQUIRED: 32-bit Subsystem (WOW64)** - some installers utilize 32-bit utilities like psexec.exe or ntrights.exe
* **NOT REQUIRED: Full .NET** - some installers use CMDLets beyond those in .NET COre
* **NOT REQUIRED: Internet Access** - some installers source everything from public repositories - download everything you need to on-premises.
* **NOT REQUIRED: PowerShell Newer Than Version 2.0** - some installers use CMDlets in newer versions or using syntax that only works in 3.0 or later.
* **NOT REQUIRED: Manual Fussing for Upgrades** - most installers presume a first time  install on a clean system - this universal installer knows when it is doing an upgrade.
* **ENABLED: Docker** - Docker is supported and Dockerfiles are provided in this repo.
* **ENABLED: Detects OS bitness** (32 or 64) and installs appropriate version.
* **ENABLED: Uninstaller** - cleanly uninstalls.
* **ENABLED: Checks for Port Conflicts**
* **ENABLED: Advanced Configuration Switches** - allows changing the SSHD port, installing only client tools, changing the logging level, overwriting SSH_CONF to reset configuration.

# Design of this package:
1. Source files are internal - making it easier to curate the package into your
own private repository and to use offline.
2. It can be used to install on machines that do not (or cannot) have Chocolatey (Nano)
nor WOW64 (ServerCore w/out WOW64 installed) - see the instructions later in this
document.
3. It can be used to install when target machine being built has no internet access.
4. The scripts included can install Chocolatey in-line and then install this
openssh all in one command line - see later in this document.
5. It can be used to install SSH under docker.

# Install Scenario 1: Chocolatey Already Installed

**Steps**: [1] Fetch from Internet (Chocolatey), [2] Unpack (Chocolatey), [3] Install (Chocolatey)

If you have chocolatey installed, then just issue either of these commands to install or upgrade:
`choco install openssh -y`
`choco upgrade openssh -y`

# Install Scenario 1b: Auto-Install Chocolatey to Install OpenSSH

**Steps**: [0] Installs Chocolatey (kicker script), [1] Fetch from Internet (Chocolatey), [2] Unpack (Chocolatey), [3] Install (Chocolatey)

A oneliner pulled from the web which installs chocolatey in order to install the OpenSSH package:
`iex ((new-object net.webclient).DownloadString('https://raw.githubusercontent.com/DarwinJS/ChocoPackages/master/openssh/InstallChoco_and_openssh_with_server.ps1'))`
Include the Server Feature:
`iex ((new-object net.webclient).DownloadString('https://raw.githubusercontent.com/DarwinJS/ChocoPackages/master/openssh/InstallChoco_and_openssh_with_server.ps1'))`

1. Open an ELEVATED PowerShell Prompt
2. Paste this command into the console (get the whole line - it's long and is a single line):
```powershell
   iex ((new-object net.webclient).DownloadString('https://raw.githubusercontent.com/DarwinJS/ChocoPackages/master/openssh/InstallChoco_and_win32-openssh_with_server.ps1'))
```

# Install Scenario 2: Non-Chocolatey Using PSH 5 PackageManagement

This works for Nano and anything else that has PSH 5 where you can't install Chocolatey (Nano) or are not allowed by company policy to install chocolatey.  It also works on Nano RTM first boot (without windows update invoke-webrequest is broken)

**Steps**: [1] Fetch from Internet (PSH 5 PackageManagement), [2] Unpack (PSH 5 PackageManagement), [3] Install (run installbarebones.ps1)

**Requirements:** PowerShell 5 for the PackageManagement Provider
**Works On:** Nano

**IMPORTANT**: The "Chocolatey" Provider for PowerShell 5 PackageManagement is still not fully functional nor reliable - so all methods in this guide that rely on PackageManagement utilize the NuGet provider instead.  In addition, the NuGet provider is required for the most basic PackageManagement operations - so even if you choose not to implement the Chocolatey PackageManagement provider when it is production ready - these methods will still work.

Oneliner premade script that does the below: 
`iex ((new-object net.webclient).DownloadString('https://raw.githubusercontent.com/DarwinJS/ChocoPackages/master/openssh/InstallChoco_and_win32-openssh_with_serverPS5.ps1'))`

1. Open a command line on the target (remoting for Nano) and run:
2. Install-PackageProvider NuGet -forcebootstrap -force
3. Register-PackageSource -name chocolatey -provider nuget -location http://chocolatey.org/api/v2/ -trusted
4. Install-Package openssh -provider NuGet
5. cd ("$env:ProgramFiles\nuget\packages\openssh." + "$((dir "$env:ProgramFiles\nuget\packages\openssh*" | %{[version]$_.name.trimstart('openssh.')} | sort | select -last 1) -join '.')\tools")
6. .".\barebonesinstaller.ps1" #Client Tools only
7. .".\barebonesinstaller.ps1" -SSHServerFeature #SSH Server (& client tools)
8. .".\barebonesinstaller.ps1" -SSHServerFeature -SSHServerPort '5555' #SSH Server on port 5555 (& client tools)
9. .".\barebonesinstaller.ps1" -SSHServerFeature -Uninstall #Uninstall

# Install Scenario 3: Docker

The Dockerfile in this repository is really a variation on the immediately above scenario.  Since only Windows 2016 supports containers and it also has PSH 5 PackageMangement, we can utilize the PackageManagement scenario in a docker file for both Server 2016 Containers and Nano Containers.

**Steps**: (All done in a Dockerfile )[1] Fetch from Internet (PSH 5 PackageManagement), [2] Unpack (PSH 5 PackageManagement), [3] Install (run installbarebones.ps1)

**Requirements:** PowerShell 5 for the PackageManagement Provider
**Works On:** Nano Containers, Server 2016 Containers

## Pre-made Docker Files:

**Nano Container:**
https://raw.githubusercontent.com/DarwinJS/ChocoPackages/master/openssh/Dockerfile

**Server 2016 Core Container:**
https://raw.githubusercontent.com/DarwinJS/ChocoPackages/master/openssh/DockerServer2016Core/Dockerfile

# Install Scenario 4: Complete Offline Install (w/out Chocolatey, w/out WOW64, w/out PowerShell 5, w/out Internet):
This works for any version of Windows that OpenSSH can run on.  It also works in non-internet scenarios as well

**Requirements:** Windows 7 SP1 / Server 2008 w/ PowerShell 2
**Works On:** Anything from Windows 7 and later, PSH 2 and later

**Steps**: [1] Fetch from Internet (manual by human), [2] Unpack (unzip util - manual or automated), [3] Install (run installbarebones.ps1)

1. Expand the openssh .nupkg (rename it to .zip and use your favorite unzipper)
2. Push the ..\tools folder to the target system (use Copy-Item -ToSession for Nano)
3. CD to "..\tools"
4. To install only client tools, run '.\barebonesinstaller.ps1'
5. To install client tools and Server, run '.\barebonesinstaller.ps1 -SSHServerFeature'
6. To uninstall, run '.\barebonesinstaller.ps1 -SSHServerFeature -Uninstall'

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

## -params '"/OverWriteSSHDConf"'
Introduced in Version: 0.0.9.20170311
By default an existing sshd_conf file will not be overwritten (previous packaging versions always overwrote)
Use this switch to overwrite an existing sshd_conf with the one from the current install media

## -params '"/SSHLogLevel:VERBOSE"'
Introduced in Version: 0.0.9.20170311
Allows the setup of the SSH logging level.
Valid Options: QUIET, FATAL, ERROR, INFO, VERBOSE, DEBUG, DEBUG1, DEBUG2, DEBUG3
On a fresh install LogLevel is set to QUIET

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


# Utility Script Set-SSHKeyPermissions.ps1
Set-SSHKeyPermissions.ps1 is copied to the SSHD bin folder so that it can be called during install, at any time after install or in a scheduled task.  It sets read permissions for the SSHD service on all "authorized_keys" files found in any user profile folder.

# Ancient Version History

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