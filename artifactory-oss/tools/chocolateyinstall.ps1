
#Reread Environment In Case JDK dependency just ran
Update-SessionEnvironment

$version = '6.9.1'

$url = "https://api.bintray.com/content/jfrog/artifactory/jfrog-artifactory-oss-$version.zip;bt_package=jfrog-artifactory-oss-zip"
$checksum = '83E99303990A444AADBDA36CE5279640F17F99672917200CB1A62B13E5ECAE82'
$checksumtype = 'sha256'
$validExitCodes = @(0)

$packageName= 'artifactory'
$versionedfolder = "artifactory-oss-$version"
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"

$TargetFolder = "$env:ProgramData\artifactory"
$ExtractFolder = "$env:temp\jfrogtemp"
$servicename = 'artifactory'

If ([bool](Get-Service $servicename -ErrorAction SilentlyContinue))
{
  Write-Warning "Artifactory is already present, shutting it down so that we can upgrade it."
  Stop-Service $servicename -force
  pushd "$TargetFolder\bin"
  Start-ChocolateyProcessAsAdmin "/c `"$TargetFolder\bin\uninstallservice.bat`"" "cmd.exe" -validExitCodes $validExitCodes
  popd
}

Write-Host "Ensuring Java is Present and that JDK_HOME is setup..."
If (!(Test-Path Env:JDK_HOME))
{
  If (Test-Path "$env:ProgramW6432\Java")
  {
    $JavaPath = (dir 'C:\Program Files\Java\' | sort-object name | select -last 1).fullname
    If ($JavaPath)
    {
      Write-Host "Found JDK at $JavaPath, setting up JDK_HOME..."
      #[Environment]::SetEnvironmentVariable("JDK_HOME","$JavaPath","Machine")
      #[Environment]::SetEnvironmentVariable("JDK_HOME","$JavaPath","Process")
      Install-ChocolateyEnvironmentVariable -VariableName 'JDK_HOME' -VariableValue "$JavaPath" -VariableType 'Machine'
      Install-ChocolateyEnvironmentVariable -VariableName 'JDK_HOME' -VariableValue "$JavaPath" -VariableType 'Process'
    }
    Else
    {
      Throw "Java is not installed at `"$env:ProgramFiles\Java`", cannot find java, cannot continue"
    }
  }
  else
  {
    Throw "Cannot find variable JDK_HOME nor Java itself, cannot continue..."
  }
}

If (Test-Path "$ExtractFolder") {Remove-Item "$ExtractFolder" -Recurse -Force}

Install-ChocolateyZipPackage -PackageName $packageName -unziplocation "$ExtractFolder" -url $url -checksum $checksum -checksumtype $checksumtype -url64 $url -checksum64 $checksum -checksumtype64 $checksumtype

Rename-Item "$ExtractFolder\$versionedfolder" "$ExtractFolder\artifactory"
Copy-Item "$ExtractFolder\artifactory" "$env:programdata" -Force -Recurse
Remove-Item "$ExtractFolder\artifactory" -Force -Recurse

#remove the pause from installservice.bat
((Get-Content "$TargetFolder\bin\installservice.bat") -replace '& pause', '') -replace 'pause', ''| Set-Content "$TargetFolder\bin\installservice.bat"

pushd "$TargetFolder\bin"
$output=(& ./installservice.bat)
popd

write-host "Results from artifactory's installservice.bat:"
Write-host "$($output | out-string)"

Install-ChocolateyEnvironmentVariable 'ARTIFACTORY_HOME' "$TargetFolder\bin" -VariableType 'Machine'
Install-ChocolateyEnvironmentVariable 'ARTIFACTORY_HOME' "$TargetFolder\bin" -VariableType 'Process'

If ([bool]!($output -ilike '*has been installed*'))
{
  Write-host "Artifactory install failed with this message:"
  Throw "Artifactory installer failed."
}

$ArtifactoryServiceRegKey = 'HKLM:System\CurrentControlSet\Services\Artifactory'
If (Test-Path $ArtifactoryServiceRegKey)
{
  Write-Host "Cleaning up the invalid characters that installservice.bat puts in the Artifactory service definition registry key..."
  #$CleanedValue = (Get-ItemProperty $ArtifactoryServiceRegKey | Select -Expand ImagePath) -replace '[^\p{L}\p{Nd}///_/ /:/./\\/-]', ''
  Set-ItemProperty $ArtifactoryServiceRegKey -Name ImagePath -Value "$TargetFolder\bin\artifactory-service.exe //RS//Artifactory"
}
else
{
  Throw "Artifactory installer failed."
}

$service = Start-Service $servicename -PassThru
Write-Host "Waiting for Artifactory service to be completely ready"
$Service.WaitForStatus('Running', '00:02:00')

If ($Service.Status -ine 'Running')
{
  Write-Warning "The Artifactory service ($servicename) did not start."
}
else
{
  #Even though windows reports service is ready - web url will not respond until Artifactory is actually ready to serve content
  Start-Sleep 120
}

Write-Warning "`r`n"
Write-Warning "***************************************************************************"
Write-Warning "*  You can manage the repository by visiting http://localhost:8081/artifactory"
Write-Warning "*  The default user is 'admin' with password 'password'"
Write-Warning "*  Artifactory availability is controlled via the service `"$servicename`""
Write-Warning "*  Use the following command to open port 8081 for access from off this machine (one line):"
Write-Warning "*   netsh advfirewall firewall add rule name=`"Nexus Repository`" dir=in action=allow "
Write-Warning "*   protocol=TCP localport=8081"
Write-Warning "***************************************************************************"
