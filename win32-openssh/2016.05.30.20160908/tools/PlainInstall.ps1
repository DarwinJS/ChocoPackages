<#
This script allows the SSH install to proceed even when your system does not have:
  [1] Chocolatey installed
  [2] WOW64 installed

The use cases are Server Nano and Server Core without WOW64 installed.

.\Plaininstall.ps1 -SSHServerFeature
#>

Param (
  [Parameter(HelpMessage="Including SSH Server Feature.")]
  [switch]$SSHServerFeature,
  [Parameter(HelpMessage="Deleting server private keys after they have been secured.")]
  [switch]$DeleteServerKeysAfterInstalled
  )

. ".\chocolateyinstall.ps1"
