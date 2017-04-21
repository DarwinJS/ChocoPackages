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