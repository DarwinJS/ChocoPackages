#requires -version 5
<#
ATTENTION - DO NOT replicate and run this script, instead follow these instructions
as they work on a pristine machine no matter whether it is domain joined or not.

  1) Open an ELEVATED PowerShell Prompt
  2) Paste this command into the console (get the whole line - it's long):
     [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {[bool]1};set-executionpolicy RemoteSigned -Force -EA 'SilentlyContinue';iex ((new-object net.webclient).DownloadString('https://raw.githubusercontent.com/DarwinJS/ChocoPackages/master/openssh/InstallChoco_and_win32-openssh_with_serverPS5.ps1'))
#>

$DoNotPrompt = $true

$Description = "Win32-OpenSSH install on $env:Computername"
If ($host.name -ilike "*remote*") {$Description = "Basic chocolatey install and PSH 5 on `$env:Computername"}
$Changes = @"
  [1] Sets PowerShell Execution Policy to "RemoteSigned"
  [2] Installs chocolatey package manager
  [3] Installs the chocolatey package openssh
"@

clear-host
Write-output "****************************************************"
Write-output "Quick Config by Darwin Sanoy..."
Write-output $Description
Write-output "Changes to be made:"
Write-output $Changes
Write-output "****************************************************"

Function Test-ProcHasAdmin {Return [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")}
If (!(Test-ProcHasAdmin))
  {Throw "You must be running as an administrator, please restart as administrator"}

Function Console-Prompt {
  Param( [String[]]$choiceList,[String]$Caption = "Please make a selection",[String]$Message = "Choices are presented below",[int]$default = 0 )
$choicedesc = New-Object System.Collections.ObjectModel.Collection[System.Management.Automation.Host.ChoiceDescription]
$choiceList | foreach {
$comps = $_ -split '='
$choicedesc.Add((New-Object "System.Management.Automation.Host.ChoiceDescription" -ArgumentList $comps[0],$comps[1]))}
#$choicedesc.Add((New-Object "System.Management.Automation.Host.ChoiceDescription" -ArgumentList $_))}
$Host.ui.PromptForChoice($caption, $message, $choicedesc, $default)
}

"Getting Started..." | out-default

Set-ExecutionPolicy RemoteSigned -Force -ErrorAction SilentlyContinue

Install-PackageProvider NuGet -forcebootstrap -force

Register-PackageSource -name chocolatey -provider nuget -location http://chocolatey.org/api/v2/

Install-Package openssh -provider NuGet -Force

If (Test-Path "$env:programfiles\PackageManagement\NuGet\Packages") {$NuGetPkgRoot = "$env:programfiles\PackageManagement\NuGet\Packages"} elseIf (Test-Path "$env:programfiles\NuGet\Packages") {$NuGetPkgRoot = "$env:programfiles\NuGet\Packages"}

cd ("$NuGetPkgRoot\openssh." + "$((dir "$NuGetPkgRoot\openssh*" | %{[version]$_.name.trimstart('openssh.')} | sort | select -last 1) -join '.')\tools")

.".\barebonesinstaller.ps1" -SSHServerFeature
