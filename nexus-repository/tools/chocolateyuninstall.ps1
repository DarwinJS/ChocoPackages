
$validExitCodes = @(0)

$packageName= 'nexus-repository'
$servicename = 'nexus'
$installfolder = "$env:programdata\Nexus"
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$validExitCodes = @(0)

If (Test-Path "$installfolder\bin\nexus.exe")
{
  Stop-Service nexus -force
  Start-ChocolateyProcessAsAdmin -ExeToRun "$installfolder\bin\nexus.exe" -Statements "/uninstall $servicename" -validExitCodes $validExitCodes
  Remove-item  "$installfolder" -recurse -force
}
Else
{
  Write-warning "It appears that the uninstall may have been run outside of chocolatey, skipping..."
}
