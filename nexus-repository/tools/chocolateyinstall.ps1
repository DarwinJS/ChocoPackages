
$packageid = "nexus-repository"
$url = 'http://download.sonatype.com/nexus/3/nexus-3.0.0-03-win64.exe'
$checksum = 'E2D7E80A80039F4FBA9D859ABCBAE94A759FCCFA'
$checksumtype = 'sha1'
$installfolder = "c:\Program Files\Nexus"
$silentargs = "-q -console -dir `"$installfolder`""
$validExitCodes = @(0)

$packageName= 'nexus-repository'
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"

$downloadedfile = "$toolsDir\$($packageid)install.exe"

Write-Warning "Installation log will be at $env:temp\i4j_nlog_<SEQ#>"

If (!(Get-ProcessorBits -eq 64))
{
  Throw "Sonatype Nexus Repository 3.0 and greater only supports 64-bit Windows."
}

If (Test-Path "$installfolder\bin\nexus-uninstall.exe")
{
  Throw "Sonatype Nexus Repository 3.0 is already installed, it must be uninstalled before installing again."
}

#$env:temp\chocolatey\$packageid\3.0.0\nexus-repositoryinstall.exe
#block install to prevent firewall popup, does not affect installation completing normally
Get-ChocolateyWebFile -packageName $packageName -filefullpath $downloadedfile -url64 $url -checksum64 $checksum -checksumtype64 $checksumtype
netsh advfirewall firewall add rule name="nexus-respositoryInstall.exe" program="$downloadedfile" dir=in action=block
Install-ChocolateyInstallPackage -packageName $packageName -fileType 'EXE' -file $downloadedfile -silentargs $silentargs
netsh advfirewall firewall delete rule name="nexus-respositoryInstall.exe"
<#
If ((gwmi win32_operatingsystem).caption -ilike "*2012*")
{
  If(![bool]((gc "$installfolder\etc\custom.properties") -ilike "*felix.native.osname.alias.windowsserver2012=windows server 2012,win32*"))
  {
    Write-Warning "Fixing up `"$installfolder\etc\custom.properties`" for Server 2012"
    Add-Content "$installfolder\etc\custom.properties" 'felix.native.osname.alias.windowsserver2012=windows server 2012,win32'
    Stop-Service Nexus -force -erroraction SilentlyContinue
    Start-Service Nexus
  }
}
#>

Write-Warning "`r`n"
Write-Warning "*******************************************************************************************"
Write-Warning "*  You can manage the repository by visiting http://localhost:8081"
Write-Warning "*  The default user is 'admin' with password 'admin123'"
Write-Warning "*  Nexus availability is controlled via the service `"$servicename`""
Write-Warning "*  Use the following command to open port 8081 for access from off this machine (one line):"
Write-Warning "*   netsh advfirewall firewall add rule name=`"Nexus Repository`" dir=in action=allow "
Write-Warning "*   protocol=TCP localport=8081"
Write-Warning "*******************************************************************************************"
