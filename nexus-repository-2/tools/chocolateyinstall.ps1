
$url = 'http://download.sonatype.com/nexus/oss/nexus-2.12.0-01-bundle.zip'
$checksum = 'e082f4ee8fea2eb7351d522ae304bfdbe05b7efe'
$checksumtype = 'sha1'
$validExitCodes = @(0)

$packageName= 'nexus-repository'
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
  Write-Warning "Nexus web app is already present, shutting it down so that we can upgrade it."
  Stop-Service $servicename -force
  Start-ChocolateyProcessAsAdmin "/c `"$TargetFolder\bin\nexus.bat`" uninstall" "cmd.exe" -validExitCodes $validExitCodes
}

Install-ChocolateyZipPackage -PackageName $packageName -unziplocation "$ExtractFolder" -url $url -checksum $checksum -checksumtype $checksumtype -url64 $url -checksum64 $checksum -checksumtype64 $checksumtype

Copy-Item "$env:programdata\nexus\$nexusversionedfolder" "$TargetFolder" -Force -Recurse
Remove-Item "$env:programdata\nexus\$nexusversionedfolder" -Force -Recurse

Start-ChocolateyProcessAsAdmin "/c `"$TargetFolder\bin\nexus.bat`" install" "cmd.exe" -validExitCodes $validExitCodes

Install-ChocolateyEnvironmentVariable 'PLEXUS_NEXUS_WORK' "$NexusWorkFolder"

Start-Service $servicename

Write-Warning "`r`n"
Write-Warning "***************************************************************************"
Write-Warning "*  You can manage the repository by visiting http://localhost:8081/nexus"
Write-Warning "*  The default user is 'admin' with password 'admin123'"
Write-Warning "*  Nexus availability is controlled via the service `"$servicename`""
Write-Warning "***************************************************************************"
