$ErrorActionPreference = 'Stop'; # stop on all errors

$packageName= 'visualstudio2013testagents'
$ISOName = 'vs2013.5_agts_enu.iso'
$logPath    = "$env:temp\$($packageName)_$(Get-date -format 'yyyyMMddhhmm').log"
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url        = "https://download.microsoft.com/download/B/E/3/BE3CD572-E8B4-48C5-B2C6-D038CB6B1E93/$ISOName"
$silentArgs = "/silent /log $logPath"

$checksum      ='C0D8789271E254E3B8307A78B6F5DC76532345C1'
$checksumType  = 'sha1'

$arguments = @{};
# /ControllerInsteadofTestAgent
$packageParameters = $env:chocolateyPackageParameters;

# Default the values
$ControllerInsteadofTestAgent = $false
If (test-path env:ProgramFiles`(x86`)) {$PF = ${env:ProgramFiles(x86)}} Else {$PF = $env:ProgramFiles}

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


If ((Test-Path "$PF\Microsoft Visual Studio 12.0\Common7\IDE\QTAgentProcessUI.exe") -AND !$ControllerInsteadofTestAgent)
{
  Write-Output "Visual Studio 2013 Test Agent is already Installed"
}
ElseIf ((Test-Path "$PF\Microsoft Visual Studio 12.0\Common7\IDE\TestControllerConfigUI.exe") -AND $ControllerInsteadofTestAgent)
{
  Write-Output "Visual Studio 2013 Test Controller is already Installed"
}
Else
{ #Perform install
  Write-Output "Logs for installers will be in $logPath"
  Get-ChocolateyWebFile "$packageName" "$env:temp\$ISOName" $url -checksum $checksum -checksumType $checksumType

  $VCDFullPath = $null
  $ISOMountDrive = $null

  If (([version](gwmi win32_operatingsystem).version) -ge [version]"6.3.9600")
  { #Use mount-disk for server 2012 R2 - works over remoting
    $mountresult = mount-diskimage -imagepath "$env:temp\$ISOName" -passthru
    $ISOMountDrive = ($mountresult | Get-Volume).DriveLetter + ":"
  }
  Else
  {
    #Other OSes use virtualclonedrive package
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
      Install-ChocolateyPath "$PF\Microsoft Visual Studio 12.0\Common7\IDE\CommonExtensions\Microsoft\TestWindow" 'Machine'
      Install-ChocolateyPath "$env:windir\Microsoft.NET\Framework\v4.0.30319" 'Machine'
    }
    catch {
        throw $_.exception
    }
}
