$ErrorActionPreference = 'Stop'; # stop on all errors

$packageName= 'visualstudio2012testagents'
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url        = 'https://download.microsoft.com/download/0/0/1/0019CE26-F153-4A6C-95B3-FAE1BAE83066/VSU4/VS2012.4%20Agents%20ENU.iso'
$url64      = 'https://download.microsoft.com/download/0/0/1/0019CE26-F153-4A6C-95B3-FAE1BAE83066/VSU4/VS2012.4%20Agents%20ENU.iso'
$silentArgs = "/silent /log $env:temp\vstestagentinstall.log"

$checksum      = $checksum64     ='B408210F7AF96A6137FEDC7C236A4A0E63657428'
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
} else {
    Write-Debug "No Package Parameters Passed in";
}

Write-Output "Logs for installers will be in $env:temp"

$AvailableDriveLetter = @(65..90 | ForEach-Object {[char]$_ + ":"}) | Where-Object {@(get-wmiobject win32_logicaldisk | select -expand deviceid) -notcontains $_} | select-object -last 1

try {
    Get-ChocolateyWebFile "$packageName" "$env:temp\VS2012.4_Agents_ENU.iso" $url -checksum $checksum -checksumType $checksumType -checksum64 $checksum64 -checksumType64 $checksumType64
    imdisk -a -f "$env:temp\VS2012.4_Agents_ENU.iso"  -m "$AvailableDriveLetter"
    If (!$ControllerInsteadofTestAgent)
    {
      Install-ChocolateyInstallPackage 'visualstudiotestagent' 'exe' $silentArgs "$AvailableDriveLetter\testagent\vstf_testagent.exe"
    }
    Else
    {
      Install-ChocolateyInstallPackage 'visualstudiotestagent' 'exe' "/silent /log $env:temp\vstestcontrollerinstall.log" "$AvailableDriveLetter\TestController\vstf_testcontroller.exe"
    }
    start-sleep -seconds 5
    Try {start-process imdisk -argumentlist "'"-d -m $AvailableDriveLetter" -ErrorAction SilentlyContinue}
    Catch {#swallow dismount ISO errors
    }
}
catch {
    throw $_.exception
}
