
$ErrorActionPreference = 'Stop'; # stop on all errors

$packageName= 'win32-openssh'
$packageVersion = '2015.12.22'
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
        Write-Host "/SSHServerFeature - Uninstalling SSH Server Feature if Present."
        $SSHServerFeature = $true
    }

    if ($arguments.ContainsKey("DeleteConfigAndServerKeys")) {
        Write-Host "/DeleteConfigAndServerKeys - Removing SSH Config and Server Keys."
        $DeleteConfigAndServerKeys = $true
    }

} else {
    Write-Debug "No Package Parameters Passed in";
}

$SSHServiceInstanceExistsAndIsOurs = ([bool]((Get-WmiObject win32_service | ?{$_.Name -ilike 'sshd'} | select -expand PathName) -ilike "*$TargetFolder*"))

If ($SSHServerFeature -AND (!$SSHServiceInstanceExistsAndIsOurs) -AND (Get-Service sshd -ErrorAction SilentlyContinue))
{
  $ExistingSSHDInstancePath = (Get-WmiObject win32_service | ?{$_.Name -ilike 'sshd'} | select -expand PathName)
  Throw "You have requested that the SSHD service be uninstalled, but this system appears to have an instance of an SSHD service configured for another folder ($ExistingSSHDInstancePath).  Ignoring /SSHServerFeature"
  $SSHServerFeature = $False
}

If ((!$SSHServerFeature) -AND $SSHServiceInstanceExistsAndIsOurs)
{
  Throw "There is a configured instance of the SSHD service, please specify the /SSHServerFeature to confirm it is OK to UNINSTALL the SSHD service at this time."
}


If ([bool](get-process ssh -erroraction silentlycontinue | where {$_.Path -ilike "*$TargetPath*"}))
{
  Throw "It appears you have instances of ssh.exe (client) running from the folder this package installs to, please terminate them and try again."
}

If ($SSHServiceInstanceExistsAndIsOurs -AND ([bool](Get-Service SSHD -ErrorAction SilentlyContinue | where {$_.Status -ieq 'Running'})))
{
#Shutdown and unregister service for upgrade
    Stop-Service SSHD -Force
    If (!([bool](Get-Service SSHD | where {$_.Status -ieq 'Running'})))
    {
      Throw "Could not stop the SSHD service, please stop manually and retry this package."
    }
}

If ((get-item 'Registry::HKLM\System\CurrentControlSet\Control\Lsa').getvalue("authentication packages") -contains 'msv1_0\0ssh-lsa.dll')
{
  $KeyBasedAuthenticationFeatureINSTALLED = $True
}

If ($SSHServiceInstanceExistsAndIsOurs -AND ([bool](Get-Service SSHD | where {$_.Status -ieq 'Running'})))
{
#Shutdown and unregister service for upgrade
    Stop-Service SSHD -Force
    Start-Sleep -seconds 5
    If (!([bool](Get-Service SSHD | where {$_.Status -ieq 'Running'})))
    {
      Throw "Could not stop the SSHD service, please stop manually and retry this package."
    }
}

If ($SSHServiceInstanceExistsAndIsOurs -AND ($SSHServerFeature))
{
  start-process "$TargetFolder\sshd.exe" -ArgumentList 'uninstall' -nonewwindow -wait
}

If ($KeyBasedAuthenticationFeatureINSTALLED)
{
  If (Test-Path "$env:windir\sysnative")
  { #We are running in a 32-bit process under 64-bit Windows
    $sys32dir = "$env:windir\sysnative"
  }
  Else
  { #We are on a 32-bit OS, or 64-bit proc on 64-bit OS
    $sys32dir = "$env:windir\system32"
  }

  $AuthpkgToRemove = 'msv1_0\0ssh-lsa.dll'
  foreach ($authpackage in (get-item 'Registry::HKLM\System\CurrentControlSet\Control\Lsa').getvalue("authentication packages"))
  {
    If ($authpackage)
    {
      If ($authpackage -ine "$AuthpkgToRemove")
      {
        [string[]]$Newauthpackages += "$authpackage"
      }
    }
  }
  Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\" "Authentication Packages" $Newauthpackages
  If (test-path "$sys32dir\ssh-lsa.dll")
  {
    del "$sys32dir\ssh-lsa.dll" -force
  }
}

#Don't remove config in case they reinstall.
If ($DeleteConfigAndServerKeys)
{
    Write-Warning "Removing all config and server keys as requested by /DeleteConfigAndServerKeys"
    Remove-Item "$TargetFolder\*" -Recurse -Force
}
Else
{
  Remove-Item "$TargetFolder\*.*" -include *.exe,*.dll,*.cmd -Recurse -Force
  Write-Warning "NOT REMOVED: Config files and any keys in `"$TargetFolder`" were NOT REMOVED - you must remove them manually."
}
netsh advfirewall firewall delete rule name='SSHD Port win32-openssh'

$PathToRemove = "$TargetFolder"
foreach ($path in [Environment]::GetEnvironmentVariable("PATH","Machine").split(';'))
{
  If ($Path)
  {
    If (($path -ine "$PathToRemove") -AND ($path -ine "$PathToRemove\"))
    {
      [string[]]$Newpath += "$path"
    }
  }
}
$AssembledNewPath = ($newpath -join(';')).trimend(';')

[Environment]::SetEnvironmentVariable("PATH",$AssembledNewPath,"Machine")
