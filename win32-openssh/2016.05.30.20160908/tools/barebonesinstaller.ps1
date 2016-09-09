<#
This script allows the SSH install to proceed even when your system does not have:
  [1] Chocolatey installed
  [2] WOW64 installed

The use cases are Server Nano and Server Core without WOW64 installed.

To use barebonesinstaller.ps1, expand the .nupkg that this file is contained in
and then place the \tools folder on the target system.

To push tools folder to Nano use 'Copy-Item -tosession $sessionvariable tools c:\tools -recurse'

.\barebonesinstaller.ps1 -SSHServerFeature

.\barebonesinstaller.ps1 -SSHServerFeature -Uninstall
#>

Param (
  [Parameter(HelpMessage="Including SSH Server Feature.")]
  [switch]$SSHServerFeature,
  [Parameter(HelpMessage="Deleting server private keys after they have been secured.")]
  [switch]$DeleteServerKeysAfterInstalled,
  [Parameter(HelpMessage="Uninstall instead of Install (install is the default).")]
  [switch]$Uninstall
  )

If (!$Uninstall)
{
  . ".\chocolateyinstall.ps1"
}
Else
{
  . ".\chocolateyuninstall.ps1"
}
