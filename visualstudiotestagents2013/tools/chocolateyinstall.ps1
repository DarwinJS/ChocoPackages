$ErrorActionPreference = 'Stop'; # stop on all errors

$packageName= 'visualstudio2013testagents'
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url        = 'https://download.microsoft.com/download/B/E/3/BE3CD572-E8B4-48C5-B2C6-D038CB6B1E93/vs2013.5_agts_enu.iso'
$url64      = 'https://download.microsoft.com/download/B/E/3/BE3CD572-E8B4-48C5-B2C6-D038CB6B1E93/vs2013.5_agts_enu.iso'
$silentArgs = "/silent /log $env:temp\vstestagentinstall.log"

$checksum      = $checksum64     ='C0D8789271E254E3B8307A78B6F5DC76532345C1'
$checksumType  = $checksumType64 = 'sha1'

$arguments = @{};
# /ControllerInsteadofTestAgent
$packageParameters = $env:chocolateyPackageParameters;

# Default the values
$ControllerInsteadofTestAgent = $false

# Now parse the packageParameters using good old regular expression
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

    if ($arguments.ContainsKey("ControllerInsteadofTestAgent")) {
        Write-Host "Installing Test Controller instead of Test Agent because /ControllerInsteadofTestAgent was used."
        $ControllerInsteadofTestAgent = $true
    }

try {
    Get-ChocolateyWebFile "$packageName" "$env:temp\VS2013_RTM_AGTS_ENU.iso" $url -checksum $checksum -checksumType $checksumType -checksum64 $checksum64 -checksumType64 $checksumType64
    imdisk -a -f "$env:temp\VS2013_RTM_AGTS_ENU.iso"  -m "q:"
    If (!ControllerInsteadofTestAgent)
    {
      Install-ChocolateyInstallPackage 'visualstudiotestagent' 'exe' $silentArgs 'q:\testagent\vstf_testagent.exe'
    }
    Else
    {
      Install-ChocolateyInstallPackage 'visualstudiotestagent' 'exe' "/silent /log $env:temp\vstestcontrollerinstall.log" 'q:\TestController\vstf_testcontroller.exe'
    }
    imdisk -d -m q:
}
catch {
    throw $_.exception
}
