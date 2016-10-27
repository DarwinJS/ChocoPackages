
<#
ATTENTION - DO NOT replicate and run this script, instead follow these instructions
as they work on a pristine machine no matter whether it is domain joined or not.

  1) Open an ELEVATED PowerShell Prompt
  2) Paste this command into the console (get the whole line - it's long):
     [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {[bool]1};set-executionpolicy RemoteSigned -Force -EA 'SilentlyContinue';iex ((new-object net.webclient).DownloadString('https://raw.githubusercontent.com/DarwinJS/ChocoPackages/master/openssh/InstallChoco_and_openssh.ps1'))
#>

$DoNotPrompt = $true

$Description = "Win32-OpenSSH install on $env:Computername"
If ($host.name -ilike "*remote*") {$Description = "Basic chocolatey install on `$env:Computername"}
$Changes = @"
  [1] Sets PowerShell Execution Policy to "RemoteSigned"
  [2] Installs chocolatey package manager
  [3] Installs the chocolatey package aws-monitor-diskusage (which autoschedules the script)
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

If (!($DoNotPrompt))
{
  Switch (Console-Prompt -Caption "Proceed?" -Message "Running this script will make the above changes, proceed?" -choice "&Yes=Yes", "&No=No" -default -1)
    {
    1 {
      Write-Warning "Installation was exited by user."
      Exit
      }
    }
}

"Getting Started..." | out-default

Set-ExecutionPolicy RemoteSigned -Force -ErrorAction SilentlyContinue

$os = (Get-WmiObject "Win32_OperatingSystem")

If (!(Test-Path env:ChocolateyInstall))
  {
  "Installing Chocolatey Package Manager on $env:computername" | out-default
  iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))
  $env:path = "$($env:ALLUSERSPROFILE)\chocolatey\bin;$($env:Path)"
  }

Write-Output "Chocolatey is installed and enabled for use in this session..."

choco install openssh -confirm

refreshenv
Write-Output "Environment refreshed, you should be able to use SSH in this console."
