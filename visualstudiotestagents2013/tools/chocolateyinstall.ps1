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
} else {
    Write-Debug "No Package Parameters Passed in";
}

Write-Output "Logs for installers will be in $env:temp"

Get-ChocolateyWebFile "$packageName" "$env:temp\vs2013.5_agts_enu.iso" $url -checksum $checksum -checksumType $checksumType -checksum64 $checksum64 -checksumType64 $checksumType64

$IMDiskFullPath = $null

If (([version](gwmi win32_operatingsystem).version) -ge [version]"6.3.9600")
{ #Use mount-disk for server 2012 R2 - works over remoting
  $mountresult = mount-diskimage -imagepath "$env:temp\vs2013.5_agts_enu.iso" -passthru
  $AvailableDriveLetter = ($mountresult | Get-Volume).DriveLetter + ":"
}
Else
{ #Other OSes use imgdisk (may not work over remoting)
  $AvailableDriveLetter = @(65..90 | ForEach-Object {[char]$_ + ":"}) | Where-Object {@(get-wmiobject win32_logicaldisk | select -expand deviceid) -notcontains $_} | select-object -last 1

  If ("$env:windir\System32\imdisk.exe")
  {
    $IMDiskFullPath = "$env:windir\System32\imdisk.exe"
  }
  ElseIf ("$env:windir\SysWOW64\imdisk.exe")
  {
    $IMDiskFullPath = "$env:windir\SysWOW64\imdisk.exe"
  }

  If (!($IMDiskFullPath))
  {
    Throw "Could not find imdisk.exe in System32 or SysWOW64 - it is required to mount the downloaded ISO, exiting..."
  }
  Else
  {
    & $IMDiskFullPath -a -f "$env:temp\vs2013.5_agts_enu.iso"  -m "$AvailableDriveLetter"
  }
}

try {
    If (!$ControllerInsteadofTestAgent)
    {
      Install-ChocolateyInstallPackage 'visualstudiotestagent' 'exe' $silentArgs "$AvailableDriveLetter\testagent\vstf_testagent.exe"
    }
    Else
    {
      Install-ChocolateyInstallPackage 'visualstudiotestagent' 'exe' "/silent /log $env:temp\vstestcontrollerinstall.log" "$AvailableDriveLetter\TestController\vstf_testcontroller.exe"
    }
    start-sleep -seconds 5
    If ($IMDiskFullPath)
    {
      Try {start-process "$IMDiskFullPath" -argumentlist "-d -m $AvailableDriveLetter" -ErrorAction SilentlyContinue}
      Catch {#swallow dismount ISO errors
      }
    }
    If (([version](gwmi win32_operatingsystem).version) -ge [version]"6.3.9600")
    {
      dismount-diskimage -imagepath "$env:temp\vs2013.5_agts_enu.iso"
    }
    If (test-path env:ProgramFiles`(x86`)) {$PF = ${env:ProgramFiles(x86)}} Else {$PF = $env:ProgramFiles}
    Install-ChocolateyPath "$PF\Microsoft Visual Studio 12.0\Common7\IDE\CommonExtensions\Microsoft\TestWindow" 'Machine'
    Install-ChocolateyPath "$env:windir\Microsoft.NET\Framework\v4.0.30319" 'Machine'
}
catch {
    throw $_.exception
}
