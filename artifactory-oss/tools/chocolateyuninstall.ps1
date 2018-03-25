$validExitCodes = @(0)

$packageName= 'artifactory'

$TargetFolder = "$env:ProgramData\artifactory"
$servicename = 'artifactory'

If ([bool](Get-Service $servicename -ErrorAction SilentlyContinue))
{
  Stop-Service $servicename -force
}

If (Test-Path "$TargetFolder\bin\uninstallservice.bat")
{
  pushd "$TargetFolder\bin"
  Start-ChocolateyProcessAsAdmin "/c `"uninstallservice.bat`"" "cmd.exe" -validExitCodes $validExitCodes
  popd
}

[Environment]::SetEnvironmentVariable('ARTIFACTORY_HOME',$null,'Machine')

Remove-Item $TargetFolder -Recurse -Force
