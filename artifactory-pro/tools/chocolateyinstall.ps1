#Reread Environment In Case JDK dependency just ran
Update-SessionEnvironment
$version = $env:chocolateyPackageVersion
$url = "https://jfrog.bintray.com/artifactory-pro/org/artifactory/pro/jfrog-artifactory-pro/$version/jfrog-artifactory-pro-$version.zip"
$checksum = 'E8832F6444CAA0FC8BD6F337E92E57E7C4123B44A2C31B699C098833471DC775'
$checksumtype = 'sha256'
$validExitCodes = @(0)

$packageName= 'artifactory-pro'
$versionedfolder = "artifactory-pro-$version"
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

$packageFolder = 'artifactory'
$TargetFolder = "$PF\$packageFolder"
$ExtractFolder = "$env:temp\jfrogtemp"
$servicename = 'artifactory'
#pushd and popd are for the .bat files to have the correct directory context

If ([bool](Get-Service $servicename -ErrorAction SilentlyContinue))
{
  Write-Warning "Artifactory is already present, shutting it down so that we can upgrade it."
  Stop-Service $servicename -force
  pushd "$TargetFolder\bin"
  $commandForCmd = "/c uninstallservice.bat"
  Start-ChocolateyProcessAsAdmin $commandForCmd cmd -validExitCodes $validExitCodes
  popd
}

Install-ChocolateyZipPackage -PackageName $packageName -unziplocation "$ExtractFolder" -url $url -checksum $checksum -checksumtype $checksumtype -url64 $url -checksum64 $checksum -checksumtype64 $checksumtype

Rename-Item "$ExtractFolder\$versionedfolder" "$ExtractFolder\$packageFolder"
Copy-Item "$ExtractFolder\$packageFolder" "$PF" -Force -Recurse
Remove-Item "$ExtractFolder\$packageFolder" -Force -Recurse

#remove the pause from installservice.bat
((Get-Content "$TargetFolder\bin\installservice.bat") -replace '& pause', '') -replace 'pause', ''| Set-Content "$TargetFolder\bin\installservice.bat"

pushd "$TargetFolder\bin"
$commandForCmd = "/c `"installservice.bat`""
Start-ChocolateyProcessAsAdmin $commandForCmd cmd -validExitCodes $validExitCodes
popd

Install-ChocolateyEnvironmentVariable 'ARTIFACTORY_HOME' "$TargetFolder\bin"

Start-Service $servicename

Write-Warning "`r`n"
Write-Warning "***************************************************************************"
Write-Warning "*  You can manage the repository by visiting http://localhost:8081/artifactory"
Write-Warning "*  The default user is 'admin' with password 'password'"
Write-Warning "*  Artifactory availability is controlled via the service `"$servicename`""
Write-Warning "***************************************************************************"
