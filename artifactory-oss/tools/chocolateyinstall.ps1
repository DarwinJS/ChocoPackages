
#Reread Environment In Case JDK dependency just ran
Update-SessionEnvironment

$version = '5.9.1'

$url = "https://api.bintray.com/content/jfrog/artifactory/jfrog-artifactory-oss-$version.zip;bt_package=jfrog-artifactory-oss-zip"
$checksum = 'B43083674E4B8666CC9A7D4B505303555266C331'
$checksumtype = 'sha1'
$validExitCodes = @(0)

$packageName= 'artifactory'
$versionedfolder = "artifactory-oss-$version"
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

$TargetFolder = "$PF\artifactory"
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

Install-ChocolateyZipPackage -PackageName $packageName -unziplocation "$ExtractFolder" -url $url -checksum $checksum -checksumtype $checksumtype -url64 $url -checksum64 $checksum -checksumtype64 $checksumtype

Rename-Item "$ExtractFolder\$versionedfolder" "$ExtractFolder\artifactory"
Copy-Item "$ExtractFolder\artifactory" "$PF" -Force -Recurse
Remove-Item "$ExtractFolder\artifactory" -Force -Recurse

#remove the pause from installservice.bat
((Get-Content "$TargetFolder\bin\installservice.bat") -replace '& pause', '') -replace 'pause', ''| Set-Content "$TargetFolder\bin\installservice.bat"

pushd "$TargetFolder\bin"
Start-ChocolateyProcessAsAdmin "/c `"$TargetFolder\bin\installservice.bat`"" "cmd.exe" -validExitCodes $validExitCodes
popd

Install-ChocolateyEnvironmentVariable 'ARTIFACTORY_HOME' "$TargetFolder\bin"

Start-Service $servicename

Write-Warning "`r`n"
Write-Warning "***************************************************************************"
Write-Warning "*  You can manage the repository by visiting http://localhost:8081/artifactory"
Write-Warning "*  The default user is 'admin' with password 'password'"
Write-Warning "*  Artifactory availability is controlled via the service `"$servicename`""
Write-Warning "***************************************************************************"
