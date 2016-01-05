$ErrorActionPreference = 'Stop'; # stop on all errors

$ISOName = 'VS2012.4_Agents_ENU.iso'
$packageName= 'visualstudio2012testagents'
$logPath    = "$env:temp\$($packageName)_$(Get-date -format 'yyyyMMddhhmm').log"
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url        = 'https://download.microsoft.com/download/0/0/1/0019CE26-F153-4A6C-95B3-FAE1BAE83066/VSU4/VS2012.4%20Agents%20ENU.iso'
$silentArgs = "/silent /log $logPath"

$checksum      = 'B408210F7AF96A6137FEDC7C236A4A0E63657428'
$checksumType  = 'sha1'

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

Write-Output "Logs for installers will be in $logPath"
Get-ChocolateyWebFile "$packageName" "$env:temp\$ISOName" $url -checksum $checksum -checksumType $checksumType

$VCDFullPath = $null
$ISOMountDrive = $null

If (([version](gwmi win32_operatingsystem).version) -ge [version]"6.3.9600")
{ #Use mount-disk for server 2012 R2  / Windows 10 - works over remoting
  $mountresult = mount-diskimage -imagepath "$env:temp\$ISOName" -passthru
  $ISOMountDrive = ($mountresult | Get-Volume).DriveLetter + ":"
}
Else
{ #Other OSes use virtualclonedrive package

  If (Test-Path 'C:\Program Files (x86)\Elaborate Bytes\VirtualCloneDrive\daemon.exe')
  {
    $VCDFullPath = 'C:\Program Files (x86)\Elaborate Bytes\VirtualCloneDrive\daemon.exe'
  }

  If (!($VCDFullPath))
  {
    Throw "Could not find virtual clone drive's `"daemon.exe`" - it is required to mount the downloaded ISO, exiting..."
  }
  Else
  {
    & $VCDFullPath -mount "$env:temp\$ISOName"
  }

  $ISOMountDrive = @(65..90 | ForEach-Object {[char]$_ + ":"}) | Where-Object {Test-Path "$_\testagent\vstf_testagent.exe"} | select -first 1
}

If (($ISOMountDrive) -AND -NOT (Test-Path $ISOMountDrive))
{
  Throw "Could not find the drive that is mapped to `"$env:temp\$ISOName`""
}

try {
    If (!$ControllerInsteadofTestAgent)
    {
      Install-ChocolateyInstallPackage 'visualstudiotestagent' 'exe' $silentArgs "$ISOMountDrive\testagent\vstf_testagent.exe"
    }
    Else
    {
      Install-ChocolateyInstallPackage 'visualstudiotestagent' 'exe' $silentArgs "$ISOMountDrive\TestController\vstf_testcontroller.exe"
    }
    start-sleep -seconds 5
    If ($VCDFullPath)
    {
      Try {start-process "$VCDFullPath" -argumentlist "-unmount" -ErrorAction SilentlyContinue}
      Catch {#swallow dismount ISO errors
      }
    }
    If (([version](gwmi win32_operatingsystem).version) -ge [version]"6.3.9600")
    {
      dismount-diskimage -imagepath "$env:temp\$ISOName"
    }
    If (test-path env:ProgramFiles`(x86`)) {$PF = ${env:ProgramFiles(x86)}} Else {$PF = $env:ProgramFiles}
    Install-ChocolateyPath "$PF\Microsoft Visual Studio 12.0\Common7\IDE\CommonExtensions\Microsoft\TestWindow" 'Machine'
    Install-ChocolateyPath "$env:windir\Microsoft.NET\Framework\v4.0.30319" 'Machine'
}
catch {
    throw $_.exception
}
