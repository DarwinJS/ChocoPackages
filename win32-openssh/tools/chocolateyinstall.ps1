
$ErrorActionPreference = 'Stop'; # stop on all errors

$packageName= 'win32-openssh'
$packageVersion = '2015.12.22'
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
<#
$url        = 'https://github.com/PowerShell/Win32-OpenSSH/releases/download/latest/OpenSSH-Win32.zip'
$checksum = '06DA0A083EEE2620DF32AB01CE7B18A4'
$url64        = 'https://github.com/PowerShell/Win32-OpenSSH/releases/download/latest/OpenSSH-Win64.zip'
$checksum64 = '0DAF4EC97DC282CB51335A0A95F22DBC'
$checksumtype = 'md5'
#>

$OSBits = GetObject("winmgmts:root\cimv2:Win32_Processor='cpu0'").AddressWidth

#On 64-bit, always favor 64-bit Program Files no matter what our execution is now (works back past XP / Server 2003)
If ($env:ProgramFiles.contains('x86')
{
  $PF = $env:ProgramFiles.replace(' (x86)','')
}
Else
{
  $PF = $env:ProgramFiles
}

$filename = "$toolsdir\OpenSSH-Win$($OSBits).zip"
$TargetFolder = "$PF\OpenSSH-Win$($OSBits)"

# Default the values
$SSHServerFeature = $false
$KeyBasedAuthenticationFeature = $false

$arguments = @{};
$packageParameters = $env:chocolateyPackageParameters;

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

    if ($arguments.ContainsKey("SSHServerFeature")) {
        Write-Host "Including SSH Server Feature."
        $SSHServerFeature = $true
    }
    if ($arguments.ContainsKey("KeyBasedAuthenticationFeature")) {
        Write-Host "Including LSA DLL Feature."
        $KeyBasedAuthenticationFeature = $true
        If (!$SSHServerFeature)
        {
          Write-Warning "KeyBasedAuthenticationFeature was specified, but is only value when SSHServerFeature is specified, ignoring..."
        }
    }

} else {
    Write-Debug "No Package Parameters Passed in";
}

#Placing these security sensitive exe files in a location secure from viruses (and as per project install instructions)
#Use of internal files because project does not (yet) provide the current version at a versioned url
#Have updated an issue to request a versioned url be provided for all new releases (even if not published)
Get-ChocolateyUnzip "$filename" "$TargetFolder"

Install-ChocolateyPath "$TargetFolder" 'Machine'

If ($SSHServerFeature)
{
  Write-Warning "You have specified SSHServerFeature - this machine is being configured as an SSH Server including opening port 22."
  If ($KeyBasedAuthenticationFeature)
  {
    If (Test-Path "$env:windir\sysnative")
    { #We are running in a 32-bit process under 64-bit Windows
      $sys32dir = "$env:windir\sysnative"
    }
    Else
    { #We are on a 32-bit OS, or 64-bit proc on 64-bit OS
      $sys32dir = "$env:windir\system32"
    }
    #Don't destroy other values
    $key = get-item 'Registry::HKLM\System\CurrentControlSet\Control\Lsa'
    $values = $key.GetValue("Authentication Packages")
    $values += "msv1_0\0ssh-lsa.dll"
    Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\" "Authentication Packages" $values
  }
  cd "$TargetFolder"
  .\ssh-keygen.exe -A
  netsh advfirewall firewall add rule name='SSHD Port' dir=in action=allow protocol=TCP localport=22
  .\sshd.exe install
  Set-Service sshd -StartupType Automatic

  #Need reboot first?
  If (!$KeyBasedAuthenticationFeature)
  {
    Start-Service sshd
  }
  Else
  {
    Write-Warning "You must reboot for SSHD so that the Key based authentication can be fully installed before SSHD starts the first time."
  }
}

Write-Warning "You must start a new prompt, or re-read the environment for the tools to be available in your command line environment."
