
$packageid = "nexus-repository"
$version = '3.5.2-01'
$url = "http://download.sonatype.com/nexus/3/nexus-$version-win64.zip"
$checksum = 'e4fd555e645e6bf53aa85a113d0d3adf16c57852'
$checksumtype = 'SHA1'
$silentargs = "-q -console -dir `"$installfolder`""
$validExitCodes = @(0)

$packageName= 'nexus-repository'
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"

$OSBits = Get-ProcessorBits

If (!(Get-ProcessorBits -eq 64))
{
  Throw "Sonatype Nexus Repository 3.0 and greater only supports 64-bit Windows."
}

$nexusversionedfolder = "nexus-$version"
$TargetFolder = "$env:programdata\nexus"
$TargetDataFolder = "$env:programdata\sonatype-work"
$ExtractFolder = "$env:temp\NexusExtract"
$NexusWorkFolder = "$env:programdata\nexus\sonatype-work"
$servicename = 'nexus'

If (Test-Path "$env:ProgramFiles\nexus\bin")
{
  Throw "Previous version of Nexus 3 installed by setup.exe is present, please uninstall before running this package."
}

If ([bool](Get-Service $servicename -ErrorAction SilentlyContinue))
{
  Write-Warning "Nexus web app is already present, shutting it down so that we can upgrade it."
  Stop-Service $servicename -force
}

Install-ChocolateyZipPackage -PackageName $packageName -unziplocation "$ExtractFolder" -url $url -checksum $checksum -checksumtype $checksumtype -url64 $url -checksum64 $checksum -checksumtype64 $checksumtype

Copy-Item "$ExtractFolder\$nexusversionedfolder" "$TargetFolder" -Force -Recurse

If (!(Test-Path "$env:programdata\sonatype-work"))
{
  Move-Item "$extractfolder\sonatype-work" "$env:programdata\sonatype-work"
}
else 
{
  Write-Warning "`"$env:programdata\sonatype-work`" already exists, not overwriting, residual data from previous installs will not be reset."
}

Remove-Item "$ExtractFolder" -Force -Recurse

Start-ChocolateyProcessAsAdmin -ExeToRun "$TargetFolder\bin\nexus.exe" -Statements "/install $servicename" -validExitCodes $validExitCodes

#Install-ChocolateyEnvironmentVariable 'PLEXUS_NEXUS_WORK' "$NexusWorkFolder"

Start-Service $servicename
Write-Host "Waiting for Nexus service to be completely ready"
Start-Sleep -seconds 120


Write-Warning "`r`n"
Write-Warning "*******************************************************************************************"
Write-Warning "*"
Write-Warning "*  You MAY receive the error 'localhost refused to connect.' until Nexus is fully started."
Write-Warning "*"
Write-Warning "*  You can manage the repository by visiting http://localhost:8081"
Write-Warning "*  The default user is 'admin' with password 'admin123'"
Write-Warning "*  Nexus availability is controlled via the service `"$servicename`""
Write-Warning "*  Use the following command to open port 8081 for access from off this machine (one line):"
Write-Warning "*   netsh advfirewall firewall add rule name=`"Nexus Repository`" dir=in action=allow "
Write-Warning "*   protocol=TCP localport=8081"
Write-Warning "*******************************************************************************************"
