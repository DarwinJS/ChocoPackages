
$url = 'http://download.sonatype.com/nexus/oss/nexus-2.12.0-01-bundle.zip'
$checksum = 'e082f4ee8fea2eb7351d522ae304bfdbe05b7efe'
$checksumtype = 'sha1'
$validExitCodes = @(0)

$packageName= 'nexus-repository-oss'
$nexusversionedfolder = 'nexus-2.12.0-01'
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

$TargetFolder = "$PF\nexus"
$ExtractFolder = "$env:programdata\nexus"
$NexusWorkFolder = "$env:programdata\nexus\sonatype-work"
$servicename = 'nexus-webapp'

If ([bool](Get-Service $servicename -ErrorAction SilentlyContinue))
{
  Stop-Service $servicename -force
}

Start-ChocolateyProcessAsAdmin "/c `"$TargetFolder\bin\nexus.bat`" uninstall" "cmd.exe" -validExitCodes $validExitCodes

[Environment]::SetEnvironmentVariable('PLEXUS_NEXUS_WORK',$null,'Machine')

Remove-Item $NexusWorkFolder -Recurse -Force
Remove-Item $TargetFolder -Recurse -Force
