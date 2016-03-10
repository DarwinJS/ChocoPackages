
$ErrorActionPreference = 'Stop'; # stop on all errors

$packageName= 'win32-openssh'
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

$filename = "$toolsdir\OpenSSH-Win$($OSBits).zip"
$TargetFolder = "$PF\OpenSSH-Win$($OSBits)"
$ExtractFolder = "$PF"

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

$SSHServiceInstanceExistsAndIsOurs = ([bool]((Get-WmiObject win32_service | ?{$_.Name -ilike 'sshd'} | select -expand PathName) -ilike "*$TargetFolder*"))

If ($SSHServerFeature -AND (!$SSHServiceInstanceExistsAndIsOurs) -AND ([bool](Get-Service sshd -ErrorAction SilentlyContinue)))
{
  $ExistingSSHDInstancePath = (Get-WmiObject win32_service | ?{$_.Name -ilike 'sshd'} | select -expand PathName)
  Throw "You have requested that the SSHD service be installed, but this system appears to have an instance of an SSHD service configured for another folder ($ExistingSSHDInstancePath).  You can remove the package switch /SSHServerFeature to install just the client tools, or you will need to remove that instance of SSHD to use the one that comes with this package."
}

If ((!$SSHServerFeature) -AND $SSHServiceInstanceExistsAndIsOurs)
{
  Throw "There is a configured instance of the SSHD service, please specify the /SSHServerFeature to confirm it is OK to shutdown and upgrade the SSHD service at this time."
}

If ([bool](get-process ssh -erroraction silentlycontinue | where {$_.Path -ilike "*$TargetPath*"}))
{
  Throw "It appears you have instances of ssh.exe (client) running from the folder this package installs to, please terminate them and try again."
}

If ($SSHServiceInstanceExistsAndIsOurs -AND ([bool](Get-Service SSHD -ErrorAction SilentlyContinue | where {$_.Status -ieq 'Running'})))
{
#Shutdown and unregister service for upgrade
    Stop-Service SSHD -Force
    Start-Sleep -seconds 3
    If (!([bool](Get-Service SSHD | where {$_.Status -ieq 'Running'})))
    {
      Throw "Could not stop the SSHD service, please stop manually and retry this package."
    }
}

If ($SSHServiceInstanceExistsAndIsOurs)
{
  start-process "$TargetFolder\sshd.exe" -ArgumentList 'uninstall' -nonewwindow -wait
}

#Placing these security sensitive exe files in a location secure from viruses (and as per project install instructions)
#Use of internal files because project does not (yet) provide the current version at a versioned url
#Have updated an issue to request a versioned url be provided for all new releases (even if not published)
Get-ChocolateyUnzip "$filename" "$ExtractFolder"

Install-ChocolateyPath "$TargetFolder" 'Machine'

If ($SSHServerFeature)
{
  Write-Warning "You have specified SSHServerFeature - this machine is being configured as an SSH Server including opening port 22."
  If ($KeyBasedAuthenticationFeature)
  {
    Write-Warning "You have specified KeyBasedAuthenticationFeature - a new lsa provider will be installed."
    If (Test-Path "$env:windir\sysnative")
    { #We are running in a 32-bit process under 64-bit Windows
      $sys32dir = "$env:windir\sysnative"
    }
    Else
    { #We are on a 32-bit OS, or 64-bit proc on 64-bit OS
      $sys32dir = "$env:windir\system32"
    }

    Copy-Item "$TargetFolder\ssh-lsa.dll" "$sys32dir\ssh-lsa.dll" -Force

    #Don't destroy other values
    $key = get-item 'Registry::HKLM\System\CurrentControlSet\Control\Lsa'
    $values = $key.GetValue("Authentication Packages")
    $values += 'msv1_0\0ssh-lsa.dll'
    Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\" "Authentication Packages" $values
  }

  If (!(Test-Path "$TargetFolder\ssh_host_rsa_key"))
  { #Only ever generate a key the first time SSHD server is installed
      Write-Output "Generating sshd keys in `"$TargetFolder`""
      start-process "$TargetFolder\ssh-keygen.exe" -ArgumentList '-A' -WorkingDirectory "$TargetFolder" -nonewwindow -wait
  }
  Else
  {
    Write-Warning "Found existing server ssh keys in $TargetFolder, you must delete them manually to generate new ones."
  }

  netsh advfirewall firewall add rule name='SSHD Port win32-openssh' dir=in action=allow protocol=TCP localport=22
  start-process "$TargetFolder\sshd.exe" -ArgumentList 'install' -nonewwindow -wait
  Set-Service sshd -StartupType Automatic

  If (!$KeyBasedAuthenticationFeature)
  {
    Write-Output "Starting sshd Service"
    Start-Service sshd
  }
  Else
  {
    Write-Warning "You must reboot so that key based authentication can be fully installed for the SSHD Service."
  }
}

Write-Warning "You must start a new prompt, or re-read the environment for the tools to be available in your command line environment."
