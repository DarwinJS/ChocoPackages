$ErrorActionPreference = 'Stop'; 

$version = '2.5.5'
$packageName   = 'libressl'
$toolsDir      = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$FileFullPath = Join-Path $toolsDir 'libressl-2.5.5-windows.zip'

$OSBits = Get-ProcessorBits
If ($OSBits -eq 64)
{$SpecificFolder = "libressl-$version-windows\x64"}
Else
{$SpecificFolder = "libressl-$version-windows\x86"}


$packageArgs = @{
  packageName   = $packageName
  FileFullPath = $FileFullPath
  Destination = $toolsDir
  SpecificFolder = $SpecificFolder
  softwareName  = 'libressl*'
}

$checksum      = 'C825AE3DF24ABFC04545C0A5269884D3FAEEB1BB'
$checksumType  = 'sha1'


Write-Host "This product includes software developed by the OpenSSL Project for use in the OpenSSL Toolkit. (http://www.openssl.org/)"

$minchocoversion = '0.10.4.0'
If (($env:CHOCOLATEY_VERSION) -AND ([version]$env:CHOCOLATEY_VERSION -lt [version]$minchocoversion))
{
  # -SpecificFolder functionality of Install-ChocolateyUnzip is broken before 10.4 (https://github.com/chocolatey/choco/pull/1023)
  Throw "You must have Chocolatey `"$minchocoversion`" or later to run this package."
}

If ([bool](get-command Get-ChecksumValid -ea silentlycontinue))
{
  If (![bool](Get-ChecksumValid -File $FileFullPath -checksumType $checksumType -checksum $checksum))
  {
    Write-Output "Hashes for internal source match"
  }
  Else
  {
    throw "Checksums for internal source do not match - something is wrong."
  }
}
Else
{
  Write-Output "Source files are internal to the package, checksums are not required nor checked."
}


# Now parse the packageParameters using good old regular expression
$arguments = @{};
$packageParameters = $env:chocolateyPackageParameters
if ($packageParameters) {
    $match_pattern = "\/(?<option>([a-zA-Z]+)):(?<value>([`"'])?([a-zA-Z0-9- _\\:\.]+)([`"'])?)|\/(?<option>([a-zA-Z]+))"
    #"
    $option_name = 'option'
    $value_name = 'value'

    if ($packageParameters -match $match_pattern ){
        $results = $packageParameters | Select-String $match_pattern -AllMatches
        $results.matches | % {
          $arguments.Add(
              $_.Groups[$option_name].Value.Trim(),
              $_.Groups[$value_name].Value.Trim())
      }
    }
    else
    {
      throw "Package Parameters were found but were invalid (REGEX Failure)"
    }

    if ($arguments.ContainsKey("ProgramFilesInstall")) {

      $InstallDir = "$env:programfiles\LibreSSL"
      Write-Host "/ProgramFilesInstall was used, installing to `"$InstallDir`" and adding `"$InstallDir`" to the System path."
      Write-Host "Clean uninstall will be possible."

    }    

    if ($arguments.ContainsKey("ProgramDataInstall")) {

      $InstallDir = "$env:programdata\LibreSSL"
      Write-Host "/ProgramFilesInstall was used, installing to `"$InstallDir`" and adding `"$InstallDir`" to the System path."
      Write-Host "Clean uninstall will be possible."

    }    

    if ($arguments.ContainsKey("InstallDir")) {

      $InstallDir = $arguments.Get_Item("InstallDir")
      Write-Host "/InstallDir was used, installing to `"$InstallDir`" and adding `"$InstallDir`" to the System path."
      Write-Host "Clean Uninstall will not be possible - after uninstall, remove `"$InstallDir`" from the file system and machine path."

    }

} else {
    Write-Debug "No Package Parameters Passed in";
}

Get-ChocolateyUnZip @packageArgs

If (!$InstallDir)
{
  Move-Item "$toolsdir\$specificfolder\*" "$toolsdir" -force
}
Else
{

  Function Ensure-OnPath ($PathToAdd,$Scope,$PathVariable,$AddToStartOrEnd)
  {
    If (!$Scope) {$Scope='Machine'}
    If (!$PathVariable) {$PathVariable='PATH'}
    If (!$AddToStartOrEnd) {$AddToStartOrEnd='END'}
    If (($PathToAdd -ilike '*%*') -AND ($Scope -ieq 'Process')) {Throw 'Unexpanded environment variables do not work on the Process level path'}
    write-host "Ensuring `"$pathtoadd`" is added to the $AddToStartOrEnd of variable `"$PathVariable`" for scope `"$scope`" "
    $ExistingPathArray = @([Environment]::GetEnvironmentVariable("$PathVariable","$Scope").split(';'))
    if (($ExistingPathArray -inotcontains $PathToAdd) -AND ($ExistingPathArray -inotcontains "$PathToAdd\"))
    {
      If ($AddToStartOrEnd -ieq 'START')
      { $Newpath = @("$PathToAdd") + $ExistingPathArray }
      else 
      { $Newpath = $ExistingPathArray + @("$PathToAdd")  }
      $AssembledNewPath = ($newpath -join(';')).trimend(';')
      [Environment]::SetEnvironmentVariable("$PathVariable",$AssembledNewPath,"$Scope")
    }
  }

  If (!(Test-Path "$InstallDir"))
  {New-Item "$InstallDir" -ItemType Directory | out-null }
  
  Move-Item "$toolsdir\$specificfolder\*" "$InstallDir" -force

  Ensure-OnPath "$InstallDir" 'Machine'  
  Write-output "`"$InstallDir`" was added to Machine path - use refreshenv to make the path available in the same process where the package was installed."

}