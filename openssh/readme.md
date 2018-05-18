# The Universal Openssh Installer
## Chocolatey NOT REQUIRED
Yes you read that right - although packaged as a chocolatey .nupkg, this installer and it's helper scripts can install completely without Chocolatey in situations where it can't be used (Nano) or you are not allowed to use it.

- [The Universal Openssh Installer](#the-universal-openssh-installer)
    - [Chocolatey NOT REQUIRED](#chocolatey-not-required)
    - [Tested On](#tested-on)
    - [NO RESTRICTIONS, ENHANCED FUNCTIONALITY](#no-restrictions-enhanced-functionality)
- [Design of this package:](#design-of-this-package)
- [Install Scenario 1: Chocolatey Already Installed](#install-scenario-1-chocolatey-already-installed)
- [Install Scenario 1b: Auto-Install Chocolatey to Install OpenSSH](#install-scenario-1b-auto-install-chocolatey-to-install-openssh)
- [Install Scenario 2: Non-Chocolatey Using PSH 5 PackageManagement](#install-scenario-2-non-chocolatey-using-psh-5-packagemanagement)
    - [Uninstall and Clean Up](#uninstall-and-clean-up)
- [Install Scenario 3: Docker](#install-scenario-3-docker)
    - [Pre-made Docker Files:](#pre-made-docker-files)
- [Install Scenario 4: Complete Offline Install / Network Based Install / SCCM Or Other ESD Install (w/out Chocolatey, w/out WOW64, w/out PowerShell 5, w/out Internet):](#install-scenario-4-complete-offline-install-network-based-install-sccm-or-other-esd-install-wout-chocolatey-wout-wow64-wout-powershell-5-wout-internet)
- [Package Parameters](#package-parameters)
    - [-params '"/SSHServerFeature"' (Install and Uninstall)](#params-sshserverfeature-install-and-uninstall)
    - [-params '"/SSHAgentFeature"'](#params-sshagentfeature)
    - [-params '"/SSHServerFeature /SSHServerPort:3834"'](#params-sshserverfeature-sshserverport3834)
    - [-params '"/OverWriteSSHDConf"'](#params-overwritesshdconf)
    - [-params '"/SSHLogLevel:VERBOSE"'](#params-sshloglevelverbose)
    - [-params '"/TERM:xterm-new"'](#params-termxterm-new)
    - [-params '"/DeleteConfigAndServerKeys"' (during uninstall command)](#params-deleteconfigandserverkeys-during-uninstall-command)
    - [-params '"/PathSpecsToProbeForShellEXEString:$env:programfiles\PowerShell\*\Powershell.exe;$env:windir\system32\windowspowershell\v1.0\powershell.exe"'](#params-pathspecstoprobeforshellexestringenvprogramfilespowershellpowershellexeenvwindirsystem32windowspowershellv10powershellexe)
    - [-params '"/SSHDefaultShellCommandOption:/c"'](#params-sshdefaultshellcommandoptionc)
    - [-params '"/AllowInsecureShellEXE"'](#params-allowinsecureshellexe)
    - [-params '"/AlsoLogToFile"'](#params-alsologtofile)
- [TroubleShooting](#troubleshooting)
    - [Chocolatey Uninstall Problems](#chocolatey-uninstall-problems)
- [Ancient Version History](#ancient-version-history)


## Tested On
* Nano RTM (PSH 5 & PackageManagement & no 32-bit)
* Server 2012 R2 (PSH 4)
* Windows 10 Anniversary (PSH 5, Chocolatey)
* Windows 7 x64 (PSH 2, Chocolatey)

## NO RESTRICTIONS, ENHANCED FUNCTIONALITY
Other installation methods may require one or more of the following that are NOT required for this universal installer
* **NOT REQUIRED: 32-bit Subsystem (WOW64)** - some installers utilize 32-bit utilities like psexec.exe or ntrights.exe
* **NOT REQUIRED: Full .NET** - some installers use CMDLets beyond those in .NET COre
* **NOT REQUIRED: Internet Access** - some installers source everything from public repositories - download everything you need to on-premises.
* **NOT REQUIRED: PowerShell Newer Than Version 2.0** - some installers use CMDlets in newer versions or using syntax that only works in 3.0 or later.
* **NOT REQUIRED: Manual Fussing for Upgrades** - most installers presume a first time  install on a clean system - this universal installer knows when it is doing an upgrade.
* **NOT REQUIRED: Chocolatey Itself** - for scenarios where it cannot or should not be installed.
* **NOT REQUIRED: PSH 5 PackageManagement** - for scenarios where PSH 5 is not currently installed.
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
3. Register-PackageSource -name chocolatey -provider nuget -location http://chocolatey.org/api/v2/ 
4. Install-Package openssh -provider NuGet -Force
5. If (Test-Path "$env:programfiles\PackageManagement\NuGet\Packages") {$NuGetPkgRoot = "$env:programfiles\PackageManagement\NuGet\Packages"} elseIf (Test-Path "$env:programfiles\NuGet\Packages") {$NuGetPkgRoot = "$env:programfiles\NuGet\Packages"}
6. cd ("$NuGetPkgRoot\openssh." + "$((dir "$NuGetPkgRoot\openssh*" | %{[version]$_.name.trimstart('openssh.')} | sort | select -last 1) -join '.')\tools")
7. & ".\barebonesinstaller.ps1" #Client Tools only
8. & ".\barebonesinstaller.ps1" -SSHServerFeature #SSH Server (& client tools)
9. & ".\barebonesinstaller.ps1" -SSHServerFeature -SSHServerPort '5555' #SSH Server on port 5555 (& client tools)
10. & ".\barebonesinstaller.ps1" -SSHServerFeature -PathSpecsToProbeForShellEXEString "$env:programfiles\PowerShell\*\pwsh.exe;$env:programfiles\PowerShell\*\Powershell.exe;c:\windows\system32\windowspowershell\v1.0\powershell.exe"
## Uninstall and Clean Up
1. & ".\barebonesinstaller.ps1" -SSHServerFeature -Uninstall 
#Uninstall
2. & ".\barebonesinstaller.ps1" -SSHServerFeature -Uninstall -DeleteConfigAndServerKeys 
 
#Uninstall leftovers (after an above command)

11. cd \
11. rd -recurse "$NuGetPkgRoot\openssh"

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

# Install Scenario 4: Complete Offline Install / Network Based Install / SCCM Or Other ESD Install (w/out Chocolatey, w/out WOW64, w/out PowerShell 5, w/out Internet):

This works for any version of Windows that OpenSSH can run on.
Use this method for:

- Installing from a network share (after step 1)
- Installing through SCCM or another automated software deployment solution (after step 1)

**Requirements:** Windows 7 SP1 / Server 2008 w/ PowerShell 2
**Works On:** Anything from Windows 7 and later, PSH 2 and later

**Steps**: [1] Fetch from Internet (manual by human), [2] Unpack (unzip util - manual or automated), [3] Install (run installbarebones.ps1)

1. Download the desired version openssh .nupkg from Chocolatey.    
    ```
    invoke-webrequest 'https://chocolatey.org/api/v2/package/openssh/0.0.22.0' -outfile "$env:public\openssh.0.0.22.0.nupkg"
    ```
2. Rename the .nupkg to .zip
    
    ```
    rename-item "$env:public\openssh.0.0.22.0.nupkg" "$env:public\openssh.0.0.22.0.zip"
    ```
3. Unzip the file (or use it directly if your software distribution method supports unzipping)
    
    **Note:** The "tools" folder in the zip contains all the installation files and can be utilized from a network location or pushed through your regular software distribution system (e.g. SCCM) or configuration management tool (e.g. Chef, Puppet, Ansible)

3. If necessary, push the ..\tools folder to the target system (use Copy-Item -ToSession for Nano)
3. CD to "..\tools"
4. To install only client tools, run '.\barebonesinstaller.ps1'
5. To install client tools and Server, run '.\barebonesinstaller.ps1 -SSHServerFeature'
6. To uninstall, run '.\barebonesinstaller.ps1 -SSHServerFeature -Uninstall'

**Note:** In general the switches used for barebonesinstaller.ps1 exactly match the below chocolatey switches, but use the standard powershell arguments formats.  You can look directly at barebonesinstaller.ps1 for a complete list: https://github.com/DarwinJS/ChocoPackages/blob/master/openssh/tools/barebonesinstaller.ps1

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
IMPORTANT: ssh-agent is no longer required for sshd after version openssh 1.0.0.0

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

## -params '"/TERM:xterm-new"'
Introduced in Version: 0.0.13.0
Allows the initial setup and subsequent update of the TERM system environment variable.
If it does not exist, TERM is defaulted to "xterm" when this switch has NOT been used.

## -params '"/DeleteConfigAndServerKeys"' (during uninstall command)
By default an uninstall does not remove config files nor server keys.

## -params '"/PathSpecsToProbeForShellEXEString:$env:programfiles\PowerShell\*\Powershell.exe;$env:windir\system32\windowspowershell\v1.0\powershell.exe"'
A set of filespecs to probe for the latest version of a given shell exe.  Wildcards can be used in the path, but not the filename.
The first filespec to result in a one or more valid hits will be choosen for the default SSH shell (newest version when there are multiple hits).
If not valid hits are located with the entire set of filespecs, the default behavior of not setting the registry key is taken (rather than an error).
Only exe's in either Program Files folder or either System32 folder (system32, syswow64) will considered safe.  If the EXE is outside of these folders
you must use the /AllowInsecureShellEXE switch to have it configured.
This is implemented as a seperate script that is left in the openssh folder so admins can call it again when they wish to reset the default shell after upgrading a shell (e.g. just installed the lastest version of PowerShell core)
Rules and Examples: https://github.com/DarwinJS/ChocoPackages/blob/master/openssh/tools/Set-SSHDefaultShell.ps1

## -params '"/SSHDefaultShellCommandOption:/c"'
Only used when /PathSpecsToProbeForShellEXEString is used and results in finding a valid shell executable.
Rules and Examples: https://github.com/DarwinJS/ChocoPackages/blob/master/openssh/tools/Set-SSHDefaultShell.ps1

## -params '"/AllowInsecureShellEXE"'
Only used when /PathSpecsToProbeForShellEXEString is used and results in finding a valid shell executable that is outside of the Programs Folders or system32.
Rules and Examples: https://github.com/DarwinJS/ChocoPackages/blob/master/openssh/tools/Set-SSHDefaultShell.ps1

## -params '"/AlsoLogToFile"'
As of version 7.6.1.0p1-Beta default logging has shifted to ETW Windows Event Logging.  Throwing this switch causes logging to also occur to the log file - now located in $env:ProgramData\ssh\logs.

# TroubleShooting

## Chocolatey Uninstall Problems
If Chocolatey Uninstall is giving errors, you can update with the latest Chocolatey Uninstall code in case there have been fixes made to uninstall.

This command will update the uninstall script with the latest:

```
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/DarwinJS/ChocoPackages/master/openssh/tools/chocolateyuninstall.ps1' -OutFile $env:ChocolateyInstall\lib\openssh\tools\ChocolateyUninstall.ps1
cuninst -y openssh -params '"/SSHServerFeature /DeleteConfigAndServerKeys"'
```
Thanks to [king6cong](https://github.com/king6cong) for the above suggested code.

# Ancient Version History

0.0.21.0
- none
0.0.20.20170913
- added possible missing command from install-sshd.ps1 (sc.exe privs sshd SeAssignPrimaryTokenPrivilege)
0.0.20.0
- handle edge case error for Azure Custom Script Extensions and DSC cChocoInstalledPackage resource 
    where GetTempFileName does not find TEMP folder when running under SYSTEM account.
0.0.19.0
- sshlsa features are removed from install package as this dll is no longer required for Openssh
0.0.18.20170730
- TERM defaults to 'xterm-256color' on windows kernel 10.x and above
0.0.18.0
- updated instructions for non-chocolatey install so that they do not add the source location as "trusted"
0.0.17.0
- fixes latest opensshutils.psm1 to work on Nano
0.0.16.0
- Fixed incomplete permissions grant when using /NTRights switch.
- Fixed uninstall implementation
- Fixed uninstall and clean uninstall for Nano
- Uses version of opensshutils shipped with openssh
0.0.15.20170613
- Fixed problem for issue #35 (error with "$RunningOnNano not found").
- /DeleteConfigAndServerKeys now works.
0.0.15.20170611
- Sets permissions for user "NT SERVICE\sshd" to write to [sshfolder]\Logs
0.0.15.0
- Calls utility script FixUserFilePermissions.ps1 (included with OpenSSH) to align setup / migrate 
    permissions to v.0.0.15.0 standard. Permissions are reasserted at every install / upgrade.
- A chocolatey uninstall that specifies "/DeleteConfigAndServerKeys" will fail.  This is only ever used
    for a completely clean uninstall - not using it means that the ssh_conf and the server key files will
    remain in the openssh install folder and will need to be removed manually after taking ownership of the files.
- New switch /DisableKeyPermissionsReset disables this capability if you are managing permissions separately.
0.0.14.0
- by default sets a machine environment variable TERM=xterm, customize with /TERM switch
- updated path setting code to not make unnecessary path alterations
0.0.12.0
- ssh-lsa.dll is no longer needed and no longer configured (switch /ReleaseSSHLSAForUpgrade is ignored)
- if ssh-lsa.dll is found during upgrade a delete attempt is made - if unsuccessful (file locked), ssh-lsa.dll 
    will be deconfigured as an authentication package and it will be delete on the next upgrade.

0.0.11.0
- /ReleaseSSHLSAForUpgrade - switch that de-configures ssh-lsa.dll in preparation for updating it after a reboot and forced reinstall (and another reboot).  See: https://github.com/DarwinJS/ChocoPackages/blob/master/openssh/readme.md
- Set-SSHKeyPermissions.ps1 - new utility for setting permissions on all existing user's authorized_keys files is placed in SSHD binaries folder (on path)
- Calls Set-SSHKeyPermissions.ps1 during install to ensure existing keys are compliant with security updates in SSH 0.0.11.0
- Fix - uninstall was not deconfiguring ssh-lsa.dll from load at startup.
- updated barebonesinstaller.ps1 to take all switches chocolatey takes
0.0.10.20170402
- fix to looking versions of installed exes for PSH 2
0.0.10.20170331
- fix to looking versions of installed exes for Nano
0.0.10.20170329
- fixed issue looking up the path of conflicting sshd service (if one exists)
- fixed problem for nano with listing of exe versions introdcued in 0.0.10.0
0.0.10.0 
- displays before and after versions of all EXES in SSH install folder and ssh-lsa.dll
- readme updates for barebonesinstaller.ps1 (due to version 0.0.10.0 not sorting properly with previous versions)
- Dockerfile updates (due to version 0.0.10.0 not sorting properly with previous versions)
- Fix for Nano for barebonesinstaller.ps1 calling 7z.exe
0.0.9.20170313 - fix for Win7/Server 2008 + PSH 2 When Installing SSHServerFeature
0.0.9.20170311
    - no longer overwrites sshd_conf if it already exists, unless /OverWriteSSHDConf is used
    - supports setting SSHD LogLevel during install or upgrade using /SSHLogLevel
    - automatically creates "logs" subfolder in install folder so that if logging is enabled 
    in the config file it starts without requiring a manual folder creation
0.0.9.20170308 - fix to fileinuseutiles.ps1 to not resolve path when target does not exist
0.0.9.20170306 - fix to ensure sshlsa.dll always gets installed when it should (thanks @felfert !)
0.0.9.20170226 - fix to allow barebones.ps1 to work on PSH 2 (e.g. Server 2008 R2)
0.0.9.20170222 - removal of stray file
0.0.9.0 - fix for problem detecting our install of sshd
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
