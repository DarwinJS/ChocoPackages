
$validExitCodes = @(0)

$packageName= 'nexus-repository'
$installfolder = "$env:programdata\Nexus"
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$validExitCodes = @(0)

If (Test-Path "$installfolder\bin\nexus.exe")
{
  Stop-Service nexus -force
  Remove-item  "$installfolder" -recurse -force
}
Else
{
  Write-warning "It appears that the uninstall may have been run outside of chocolatey, skipping..."
}
