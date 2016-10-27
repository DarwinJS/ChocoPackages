
# Overview
Tested On:
* Nano RTM
* Server 2012 R2
* Windows 10 Anniversary (resolvable clashes with Linux extensions are detected and noted by the installer)

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

## Installing on Nano Over the Wire w/out Chocolatey Nor .NET Core Installed (should work for Server 2016 as well)

**Requirements:** PowerShell 5 for the PackageManagement Provider
**Works On:** Nano TP5

1. Open a command line on the target (remoting for Nano) and run:
2. Install-PackageProvider NuGet -forcebootstrap -force
3. Register-PackageSource -name chocolatey -provider nuget -location http://chocolatey.org/api/v2/ -trusted
4. Install-Package openssh -provider NuGet
5. cd "$((dir "$env:ProgramFiles\nuget\packages\openssh*\tools" |select -last 1).fullname)"
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
