<#
.SYNOPSIS
Enables installing SSH even when your system does not have WOW64 or Chocolatey.
.DESCRIPTION
This script enables installing  SSH even when your system does NOT have:
  [1] Chocolatey installed
  [2] WOW64 installed
  [3] .NET Core (Nano)

The use cases are Server Nano and Server Core without WOW64 installed.

To use barebonesinstaller.ps1, expand the .nupkg that this file is contained in
and then place the \tools folder on the target system.

To push tools folder to Nano use 'Copy-Item -tosession $sessionvariable tools c:\tools -recurse'
.PARAMETER SSHServerFeature
Include SSH Server Feature.
.PARAMETER DeleteServerKeysAfterInstalled
Delete server private keys after they have been secured
.PARAMETER Uninstall
Uninstall (default is to install)
.EXAMPLE
.\barebonesinstaller.ps1 -SSHServerFeature
.EXAMPLE
.\barebonesinstaller.ps1 -SSHServerFeature -Uninstall
#>

Param (
  [Parameter(HelpMessage="Include SSH Server Feature.")]
  [switch]$SSHServerFeature,
  [Parameter(HelpMessage="Delete server private keys after they have been secured.")]
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
