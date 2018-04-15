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
.PARAMETER SSHServerPort
The port that SSHD Server should listen on.
.PARAMETER DeleteConfigAndServerKeys
Delete server private keys and configuration upon uninstall.
.PARAMETER Uninstall
Uninstall (default is to install)
.PARAMETER DisableKeyPermissionsReset
By default the install runs a custom utility script called "Reset-SSHKeyPermissions.ps1". This switch disables that functionality.
.EXAMPLE
.\barebonesinstaller.ps1 -SSHServerFeature
.EXAMPLE
.\barebonesinstaller.ps1 -SSHServerFeature -Uninstall
#>

Param (
  [switch]$SSHServerFeature,
  [switch]$SSHAgentFeature,
  [string]$SSHServerPort='22',
  [switch]$DeleteConfigAndServerKeys,
  [switch]$Uninstall,
  [switch]$OverWriteSSHDConf,
  [string]$SSHLogLevel,
  [switch]$ReleaseSSHLSAForUpgrade,
  [string]$TERM,
  [string]$PathSpecsToProbeForShellEXEString,
  [string]$SSHDefaultShellCommandOption,
  [switch]$AllowInsecureShellEXE,
  [switch]$AlsoLogToFile
  )

Write-Output "Configuring on Port $SSHServerPort"

cd "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"

If (!$Uninstall)
{
  . ".\chocolateyinstall.ps1"
}
Else
{
  . ".\chocolateyuninstall.ps1"
}
