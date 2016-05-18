
$validExitCodes = @(0)

$packageName= 'nexus-repository'
$installfolder = "c:\Program Files\Nexus"
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$validExitCodes = @(0)

If (Test-Path "$installfolder\bin\nexus-uninstall.exe")
{
  Stop-Service nexus -force
  Start-ChocolateyProcessAsAdmin "-q -console" "$installfolder\bin\nexus-uninstall.exe" -validExitCodes $validExitCodes
}
Else
{
  Write-warning "It appears that the uninstall may have been run outside of chocolatey, skipping..."
}
