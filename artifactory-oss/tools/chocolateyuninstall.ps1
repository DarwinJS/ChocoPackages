$validExitCodes = @(0)

$packageName= 'artifactory-oss'
$versionedfolder = 'artifactory-oss-4.5.1'
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"

$OSBits = Get-ProcessorBits

#On 64-bit, always favor 64-bit Program Files no matter what our execution is now (works back past XP / Server 2003)
If ($env:ProgramFiles.contains('x86'))
{
  $PF = $env:ProgramFiles.replace(' (x86)','')
}
Else
{
  $PF = $env:ProgramFiles
}

$TargetFolder = "$PF\artifactory-oss"
$ExtractFolder = "$env:temp\jfrog"
$servicename = 'artifactory'

If ([bool](Get-Service $servicename -ErrorAction SilentlyContinue))
{
  Stop-Service $servicename -force
}

Start-ChocolateyProcessAsAdmin "/c `"$TargetFolder\bin\uninstallservice.bat`"" "cmd.exe" -validExitCodes $validExitCodes

[Environment]::SetEnvironmentVariable('ARTIFACTORY_HOME',$null,'Machine')

Remove-Item $TargetFolder -Recurse -Force
