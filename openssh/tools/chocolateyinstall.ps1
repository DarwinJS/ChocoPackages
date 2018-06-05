
<#
ATTENTION: This code is used extensively to run under PowerShell 2.0 to update 
images from RTM / SP1 source for Windows 7 and Server 2008 R2.  It is also
used under Powershell Core to add OpenSSH to Nano.  Test all enhancements and 
fixes under these two specialty cases (speciality for Chocolatey packagers who are 
likely up to the latest version on everything PowerShell).
#>


$ErrorActionPreference = 'Stop'; # stop on all errors

$ProductName = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'ProductName').ProductName
$EditionId = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'EditionID').EditionId

#This has to work for Win7 (no get-ciminstance) and Nano (no get-wmiobject) - each of which specially construct win32_operatingsystem.version to handle before and after Windows 10 version numbers (which are in different registry keys)
If ($psversiontable.psversion.major -lt 3)
{
  $OSVersionString = (Get-WMIObject Win32_OperatingSystem).version
}
Else 
{
  $OSVersionString = (Get-CIMInstance Win32_OperatingSystem).version
}


Write-Output "Running on: $ProductName, ($EditionId)"
Write-Output "Windows Version: $OSVersionString"

$RunningOnNano = $False
If ($EditionId -ilike '*Nano*')
{$RunningOnNano = $True}

If (Test-Path variable:shimgen)
{$RunningUnderChocolatey = $True}
Else
{  Write-Output "Running Without Chocolatey"}

$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$OSBits = ([System.IntPtr]::Size * 8) #Get-ProcessorBits

#On 64-bit, always favor 64-bit Program Files no matter what our execution is now (works back past XP / Server 2003)
If ($env:ProgramFiles.contains('x86'))
{
  $PF = $env:ProgramFiles.replace(' (x86)','')
}
Else
{
  $PF = $env:ProgramFiles
}

If (Test-Path "$env:windir\sysnative")
{ #We are running in a 32-bit process under 64-bit Windows
  $sys32dir = "$env:windir\sysnative"
}
Else
{ #We are on a 32-bit OS, or 64-bit proc on 64-bit OS
  $sys32dir = "$env:windir\system32"
}
$filename = "$toolsdir\OpenSSH-Win$($OSBits).zip"
#$TargetFolder = "$PF\OpenSSH"
#$TargetFolderOld = "$PF\OpenSSH-Win$($OSBits)"
$TargetFolder = "$PF\OpenSSH-Win$($OSBits)"
$ExtractFolder = "$env:temp\OpenSSHTemp"

$sshdpath = Join-Path $TargetFolder "sshd.exe"
$sshagentpath = Join-Path $TargetFolder "ssh-agent.exe"
$sshdatadir = Join-Path $env:ProgramData "\ssh"
$logsdir = Join-Path $SSHDataDir "logs"

$packageArgs = @{
  packageName   = 'openssh'
  unziplocation = "$ExtractFolder"
  fileType      = 'EXE_MSI_OR_MSU' #only one of these: exe, msi, msu

  checksum      = 'FCEA2421A472154B36F10EAC58760D49A0757A2B'
  checksumType  = 'SHA1'
  checksum64    = '0E88D2C386F4DAE21E157B0B1DE9B34E8AF1C03B'
  checksumType64= 'SHA1'
}

If ($RunningUnderChocolatey)
{
  # Default the values before reading params
  $SSHServerFeature = $false
  $KeyBasedAuthenticationFeature = $false
  $SSHServerPort = '22'

  $arguments = @{};
  $packageParameters = $env:chocolateyPackageParameters
}

$OpeningMessage = @"

************************************************************************************
************************************************************************************
This package is a Universal Installer and can ALSO install Win32-OpenSSH on 
Nano, Server Core, Docker Containers and more WITHOUT using Chocolatey.

See the following for more details:
https://github.com/DarwinJS/ChocoPackages/blob/master/openssh/readme.md
************************************************************************************
************************************************************************************

"@

Write-Output $OpeningMessage

function Get-PackageParametersCustom {
  [CmdletBinding()]
  param(
     [string] $Parameters = $Env:ChocolateyPackageParameters,
     # Allows splatting with arguments that do not apply and future expansion. Do not use directly.
     [parameter(ValueFromRemainingArguments = $true)]
     [Object[]] $IgnoredArguments
  )

  $res = @{}

  $re = "\/([a-zA-Z0-9]+)(:[`"'].+?[`"']|[^ ]+)?"
  $results = $Parameters | Select-String $re -AllMatches | select -Expand Matches
  foreach ($m in $results) {
      if (!$m) { continue } # must because of posh 2.0 bug: https://github.com/chocolatey/chocolatey-coreteampackages/issues/465

      $a = $m.Value -split ':'
      $opt = $a[0].Substring(1); $val = $a[1..100] -join ':'
      if ($val -match '^(".+")|(''.+'')$') {$val = $val -replace '^.|.$'}
      $res[ $opt ] = if ($val) { $val } else { $true }
  }
  $res
}


# Now parse the packageParameters using good old regular expression
if ($packageparameters) {

  $pp = Get-PackageParametersCustom
  
    if ($pp.SSHAgentFeature) {
        Write-Host "/SSHAgentFeature was used, including SSH Agent Service."
        $SSHAgentFeature = $true
    }

    if ($pp.SSHServerFeature) {
        Write-Host "/SSHServerFeature was used, including SSH Server Feature."
        $SSHServerFeature = $true
    }

    if ($pp.OverWriteSSHDConf) {
        Write-Host "/OverWriteSSHDConf was used, will overwrite any existing sshd_conf with one from install media."
        $OverWriteSSHDConf = $true
    }

    if ($pp.SSHServerPort) {
        $SSHServerPort = $pp.Get_Item("SSHServerPort")
        Write-Host "/SSHServerPort was used, attempting to use SSHD listening port $SSHServerPort."
        If (!$SSHServerFeature)
        {
          Write-Host "You forgot to specify /SSHServerFeature with /SSHServerPort, autofixing for you, enabling /SSHServerFeature"
          $SSHServerFeature = $true
        }
    }

    if ($pp.SSHLogLevel) {

      $ValidLogSettings = @('QUIET', 'FATAL', 'ERROR', 'INFO', 'VERBOSE', 'DEBUG', 'DEBUG1', 'DEBUG2','DEBUG3')
      $SSHLogLevel = $pp.Get_Item("SSHLogLevel").toupper()
      If ($ValidLogSettings -inotcontains $SSHLogLevel)
      {Throw "$SSHLogLevel is not one of the valid values: $(($ValidLogSettings -join ' ') | out-string)"}
      Write-Host "/SSHLogLevel was used, setting LogLevel in sshd_conf to $SSHLogLevel"
    }
    Else
    {
      $SSHLogLevel = $null
    }

    if ($pp.AlsoLogToFile) {
      $AlsoLogToFile = $True
      Write-Host '/AlsoLogToFile was used, setting AlsoLogToFile to $True'
    }

    if ($pp.TERM) {
      $TERM = $pp.Get_Item("TERM")
      Write-Host "/TERM was used, setting system TERM environment variable to $TERM"
      $TERMSwitchUsed = $True
    }

    if ($pp.KeyBasedAuthenticationFeature) {
        Write-Host "Including Key based authentication."
        $KeyBasedAuthenticationFeature = $true
        If (!$SSHServerFeature)
        {
          Write-Warning "KeyBasedAuthenticationFeature was specified, but is only value when SSHServerFeature is specified, ignoring..."
        }
    }

    if ($pp.PathSpecsToProbeForShellEXEString) {
      $PathSpecsToProbeForShellEXEString = $pp.Get_Item("PathSpecsToProbeForShellEXEString")

      Write-Host "PathSpecsToProbeForShellEXEString was used, probing for suitable shell using search specs: $PathSpecsToProbeForShellEXEString"
    }

    if ($pp.AllowInsecureShellEXE) {
      $AllowInsecureShellEXE = $True
    }

    if ($pp.SSHDefaultShellCommandOption) {
      $SSHDefaultShellCommandOption = $pp.Get_Item("SSHDefaultShellCommandOption")
    }

} else {
    Write-Debug "No Package Parameters Passed in";
}

Function CheckServicePath ($ServiceEXE,$FolderToCheck)
{
  if ($RunningOnNano) {
    #The NANO TP5 Compatible Way:
    Return ([bool](@(wmic service | ?{$_ -ilike "*$ServiceEXE*"}) -ilike "*$FolderToCheck*"))
  }
  Else
  {
    #The modern way:
    Return ([bool]((Get-WmiObject win32_service | ?{$_.PathName -ilike "*$ServiceEXE*"} | select -expand PathName) -ilike "*$FolderToCheck*"))
  }
}

#Extract Files Early
If ($RunningUnderChocolatey)
{
  If (Test-Path $ExtractFolder)
  {
    Remove-Item $ExtractFolder -Recurse -Force
  }
  Get-ChocolateyUnzip "$filename" $ExtractFolder
}
Else
{
  If (Test-Path "$toolsdir\7z.exe")
  {
    #covers nano
    cd $toolsdir
    start-process .\7z.exe -argumentlist "x `"$filename`" -o`"$ExtractFolder`" -aoa" -nonewwindow -wait
  }
  Else
  {
    Throw "You need a copy of 7z.exe next to this script for this operating system.  You can get a copy at 7-zip.org"
  }
}

If ($SSHServerFeature -OR $SSHAgentFeature)
{
  . "$toolsdir\SetSpecialPrivileges.ps1"
}

If ($SSHServerFeature)
{  #Check if anything is already listening on port $SSHServerPort, which is not a previous version of this software.
  $AtLeastOneSSHDPortListenerIsNotUs = $False
  Write-Output "Probing for possible conflicts with SSHD server to be configured on port $SSHServerPort ..."
  . "$toolsdir\Get-NetStat.ps1"
  $procslisteningonRequestedSSHDPort = @(Get-Netstat -GetProcessDetails -FilterOnPort $SSHServerPort)
  If ((checkservicepath 'svchost.exe -k SshBrokerGroup' 'Part of Microsoft SSH Server for Windows') -AND (checkservicepath 'svchost.exe -k SshProxyGroup' 'Part of Microsoft SSH Server for Windows'))
  {
    Write-Warning "  > Detected that Developer Mode SSH is present (Probably due to enabling Windows 10 Developer Mode)"
    $DeveloperModeSSHIsPresent = $True
  }

  If ($procslisteningonRequestedSSHDPort.count -ge 1)
  {
    ForEach ($proconRequestedSSHDPort in $procslisteningonRequestedSSHDPort)
    {
      Write-output "  > Checking $($proconRequestedSSHDPort.Localaddressprocesspath) against path $TargetFolder"
      If ("$($proconRequestedSSHDPort.Localaddressprocesspath)" -ilike "*$TargetFolder*")
      {
        Write-Output "  > Found a previous version of Win32-OpenSSH installed by this package on Port $SSHServerPort."
      }
      Else
      {
        $AtLeastOneSSHDPortListenerIsNotUs = $True
        Write-Warning "  > Found something listening on Port $SSHServerPort that was not installed by this package."
        Write-Warning "      $($proconRequestedSSHDPort.LocalAddressProcessPath) is listening on Port $SSHServerPort"
        $ProcessOccupyingPort = "$($proconRequestedSSHDPort.LocalAddressProcessPath)"
      }
    }
  }

  If ($AtLeastOneSSHDPortListenerIsNotUs)
  {
  $errorMessagePort = @"
"$ProcessOccupyingPort" is listening on port $SSHServerPort and you have not specified a different listening port (list above) using the /SSHServerPort parameter.
Please either deconfigure or deinstall whatever is running on Port $SSHServerPort and try again OR specify a different port for this SSHD Server using the /SSHServerPort package parameter.
If you see the message 'Detected that Developer Mode SSH is present' above, you may be able to simply disable the services 'SSHBroker' and 'SSHProxy'
"@
  Throw $errorMessagePort
  }
}

$SSHServiceInstanceExistsAndIsOurs = CheckServicePath 'sshd.exe' "$TargetFolder"
$SSHAGENTServiceInstanceExistsAndIsOurs = CheckServicePath 'ssh-agent.exe' "$TargetFolder"

If ($SSHServerFeature -AND (!$SSHServiceInstanceExistsAndIsOurs) -AND ([bool](Get-Service sshd -ErrorAction SilentlyContinue)))
{
  $ExistingSSHDInstancePath = get-itemproperty hklm:\system\currentcontrolset\services\* | where {($_.ImagePath -ilike '*sshd.exe*')} | Select -expand ImagePath
  Throw "You have requested that the SSHD service be installed, but this system appears to have an instance of an SSHD service configured for another folder ($ExistingSSHDInstancePath).  You can remove the package switch /SSHServerFeature to install just the client tools, or you will need to remove that instance of SSHD to use the one that comes with this package."
}

If ((!$SSHServerFeature) -AND $SSHServiceInstanceExistsAndIsOurs)
{
  Throw "There is a configured instance of the SSHD service, please specify the /SSHServerFeature to confirm it is OK to shutdown and upgrade the SSHD service at this time."
}

If ([bool](get-process ssh -erroraction silentlycontinue | where {$_.Path -ilike "*$TargetFolder*"}))
{
  Throw "It appears you have instances of ssh.exe (client) running from the folder this package installs to, please terminate them and try again."
}

If ((Test-Path $TargetFolder) -AND (@(dir "$TargetFolder\*.exe").count -gt 0)) 
{
  Write-Output "`r`nCURRENT VERSIONS OF SSH EXES:"
    Write-Output "$(dir "$TargetFolder\*.exe"| select -expand fullname | get-command | select -expand fileversioninfo | ft filename, fileversion -auto | out-string)"
}

If ($SSHServiceInstanceExistsAndIsOurs -AND ([bool](Get-Service SSHD -ErrorAction SilentlyContinue | where {$_.Status -ieq 'Running'})))
{
    #Shutdown and unregister service for upgrade
    stop-service sshd -Force
    Start-Sleep -seconds 3
    If (([bool](Get-Service SSHD | where {$_.Status -ieq 'Running'})))
    {
      Throw "Could not stop the SSHD service, please stop manually and retry this package."
    }

}

If ($SSHServiceInstanceExistsAndIsOurs)
{
  Write-output "Stopping SSHD Service for upgrade..."
  Stop-Service sshd
  sc.exe delete sshd | out-null
}
If ($SSHAGENTServiceInstanceExistsAndIsOurs)
{
  Stop-Service SSH-Agent -Force
  Start-Sleep -seconds 3
  If (([bool](Get-Service ssh-agent | where {$_.Status -ieq 'Running'})))
  {
    Throw "Could not stop the ssh-agent service, please stop manually and retry this package."
  }
  sc.exe delete ssh-agent | out-null
}

If ($OSBits -eq 64)
{
  $SourceZipChecksum = $packageargs.checksum64
  $SourceZipChecksumType = $packageargs.checksumType64
}
Else
{
  $SourceZipChecksum = $packageargs.checksum
  $SourceZipChecksumType = $packageargs.checksumType
}

If ([bool](get-command get-filehash -ea silentlycontinue))
{
  If ((Get-FileHash $filename -Algorithm $SourceZipChecksumType).Hash -eq $SourceZipChecksum)
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

Copy-Item "$ExtractFolder\*" "$PF" -Force -Recurse -Passthru -ErrorAction Stop
Copy-Item "$toolsdir\Set-SSHDefaultShell.ps1" "$TargetFolder" -Force -PassThru -ErrorAction Stop

Remove-Item "$ExtractFolder" -Force -Recurse

If ($RunningUnderChocolatey)
{
  Install-ChocolateyPath "$TargetFolder" 'Machine'
}
Else
{
  $PathToAdd = $TargetFolder
  $ExistingPathArray = @(((Get-ItemProperty 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' | select -expand path).split(';')))
  if (($ExistingPathArray -inotcontains $PathToAdd) -AND ($ExistingPathArray -inotcontains "$PathToAdd\"))
  {
    $Newpath = $ExistingPathArray + @("$PathToAdd")
    $AssembledNewPath = ($newpath -join(';')).trimend(';')
    Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' -Name 'PATH' -Value "$AssembledNewPath"
  }
}
If ($env:Path -inotlike "*$TargetFolder*")
{
  $env:path += ";$TargetFolder"
}

$ExistingTermValue = $null
$ExistingTermValue = (get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' -EA SilentlyContinue | Select -Expand TERM -EA SilentlyContinue)

If ((!$ExistingTermValue) -OR ($ExistingTermValue -ine $TERM))
{ 
  Write-Host "Updating machine environment variable TERM from `"$ExistingTermValue`" to `"$TERM`""
  Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' -Name 'TERM' -Value "$TERM"
}

If ($SSHAgentFeature)
{
  New-Service -Name ssh-agent -BinaryPathName "$TargetFolder\ssh-agent.exe" -Description "SSH Agent" -StartupType Automatic | Out-Null
  cmd.exe /c 'sc.exe sdset ssh-agent D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;IU)(A;;CCLCSWLOCRRC;;;SU)(A;;RP;;;AU)'

  Start-Service ssh-agent

  Start-Sleep -seconds 3
}

If ($SSHServerFeature)
{
  Write-Warning "You have specified SSHServerFeature - this machine is being configured as an SSH Server including opening port $SSHServerPort."
  
  
  #create the ssh config folder and set its permissions
  if(-not (test-path $sshdatadir -PathType Container))
  {
    $null = New-Item $sshdatadir -ItemType Directory -Force -ErrorAction Stop
  }
  $acl = Get-Acl -Path $sshdatadir
  # following SDDL implies 
  # - owner - built in Administrators
  # - disabled inheritance
  # - Full access to System
  # - Full access to built in Administrators
  $acl.SetSecurityDescriptorSddlForm("O:BAD:PAI(A;OICI;FA;;;SY)(A;OICI;FA;;;BA)(A;OICI;0x1200a9;;;AU)")
  Set-Acl -Path $sshdatadir -AclObject $acl

  # create logs folder and set its permissions
  if(-not (test-path $logsdir -PathType Container))
  {
    $null = New-Item $logsdir -ItemType Directory -Force -ErrorAction Stop
  }
  $acl = Get-Acl -Path $logsdir
  # following SDDL implies 
  # - owner - built in Administrators
  # - disabled inheritance
  # - Full access to System
  # - Full access to built in Administrators
  $acl.SetSecurityDescriptorSddlForm("O:BAD:PAI(A;OICI;FA;;;SY)(A;OICI;FA;;;BA)")
  Set-Acl -Path $logsdir -AclObject $acl
  
  If((Test-Path "$TargetFolder\sshd_config"))
  {
    Write-Host "Migrating existing sshd_config to new location `"$sshdatadir`""
    Move-Item "$TargetFolder\sshd_config" $sshdatadir -force
  }

  #for clean config copy sshd_config_default to $sshdatadir\sshd_config
  $sshdconfigpath = Join-Path $sshdatadir "sshd_config"
  $sshddefaultconfigpath = Join-Path $TargetFolder "sshd_config_default"
  if(-not (test-path $sshdconfigpath -PathType Leaf))
  {
    $null = Copy-Item $sshddefaultconfigpath -Destination $sshdconfigpath  -ErrorAction Stop
  }

  If((Test-Path "$TargetFolder\ssh_host_*"))
  {
    Write-Host "Migrating existing ssh host keys to new location `"$sshdatadir`""
    Move-Item "$TargetFolder\ssh_host_*" $sshdatadir -force
  }

  If ($RunningOnNano)
  {
    Write-Warning "Forcing on"
    $AlsoLogToFile = $True
  }

  If((Test-Path "$sshdconfigpath"))
  {
    $CurrentLogLevelConfig = ((gc "$sshdconfigpath") -imatch "^#*LogLevel\s\w*\b.*$")
    Write-Output 'Setting up SSH Logging'
    If ($SSHLogLevel)
    { #command line specified a log level - override whatever is there
      If ([bool]($CurrentLogLevelConfig -inotmatch "^LogLevel\s$SSHLogLevel\s*$"))
      {
        Write-Output "Current LogLevel setting in `"$sshdconfigpath`" is `"$CurrentLogLevelConfig`", setting it to `"LogLevel $SSHLogLevel`""
        (Get-Content "$sshdconfigpath") -replace "^#*LogLevel\s\w*\b.*$", "LogLevel $SSHLogLevel" | Set-Content "$sshdconfigpath"
      }
    }

     $CurrentPortConfig = ((gc "$sshdconfigpath") -match "^#*Port\s\d*\s*$")
     If ([bool]($CurrentPortConfig -notmatch "^Port $SSHServerPort"))
     {
       Write-Output "Current port setting in `"$sshdconfigpath`" is `"$CurrentPortConfig`", setting it to `"Port $SSHServerPort`""
       (Get-Content "$sshdconfigpath") -replace "^#*Port\s\d*\s*$", "Port $SSHServerPort" | Set-Content "$sshdconfigpath"
     }
     Else
     {
       Write-Output "Current port setting in `"$sshdconfigpath`" already matches `"Port $SSHServerPort`", no action necessary."
     }

     If ($AlsoLogToFile)
     { 
       If ((Get-Content "$sshdconfigpath") -notmatch "^Subsystem\ssftp\ssftp-server\.exe.*LOCAL0.*$")
       {
         (Get-Content "$sshdconfigpath") -replace "^Subsystem\ssftp\ssftp-server\.exe.*$", "SyslogFacility LOCAL0" | Set-Content "$sshdconfigpath"
       }
     }
  }

  If ($PathSpecsToProbeForShellEXEString)
  {
    $ParamsSSHDefaultShell = @{}
    $ParamsSSHDefaultShell.add('PathSpecsToProbeForShellEXEString',"$PathSpecsToProbeForShellEXEString")
    If ($AllowInsecureShellEXE) {$ParamsSSHDefaultShell += @{'AllowInsecureShellEXE'=$AllowInsecureShellEXE}}
    If ($SSHDefaultShellCommandOption) {$ParamsSSHDefaultShell += @{'SSHDefaultShellCommandOption'="$SSHDefaultShellCommandOption"}}
    
    Write-Host "$ParamsSSHDefaultShell"
  
    . $TargetFolder\Set-SSHDefaultShell.ps1 @ParamsSSHDefaultShell
  }

  netsh advfirewall firewall add rule name='SSHD Port OpenSSH (chocolatey package: openssh)' dir=in action=allow protocol=TCP localport=$SSHServerPort

  If (!$RunningOnNano)
  {
    $etwman = Join-Path $TargetFolder "openssh-events.man"
  
    # unregister etw provider
    wevtutil um `"$etwman`"

    # adjust provider resource path in instrumentation manifest
    [XML]$xml = Get-Content $etwman
    $xml.instrumentationManifest.instrumentation.events.provider.resourceFileName = $sshagentpath.ToString()
    $xml.instrumentationManifest.instrumentation.events.provider.messageFileName = $sshagentpath.ToString()
    $xml.Save($etwman)

    #register etw provider
    wevtutil im `"$etwman`"
  }

  New-Service -Name sshd -BinaryPathName "$TargetFolder\sshd.exe" -Description "SSH Daemon" -StartupType Automatic | Out-Null

  Write-Host "Ensuring all ssh key and configuration files have correct permissions for all users"
  . "$TargetFolder\FixHostFilePermissions.ps1" -Confirm:$false
}

If (CheckServicePath 'sshd.exe' "$TargetFolder")
{
  write-output "Starting SSHD..."
  Start-Service SSHD
}
If (CheckServicePath 'ssh-agent.exe' "$TargetFolder")
{
  write-output "Starting SSH-Agent..."
  Start-Service SSH-Agent
}

$fullpathkeylist = "'$sshdatadir\ssh_host_dsa_key'", "'$sshdatadir\ssh_host_rsa_key'", "'$sshdatadir\ssh_host_ecdsa_key'", "'$sshdatadir\ssh_host_ed25519_key'"

If (Test-Path "$TargetFolder\ssh.exe") 
{
  Write-Output "`r`nNEW VERSIONS OF SSH EXES:"
  Write-Output "$(dir "$TargetFolder\*.exe" | select -expand fullname | get-command | select -expand fileversioninfo | ft filename, fileversion -auto | out-string)"
}

write-output ""
Write-Warning "You must start a new prompt, or use the command 'refreshenv' (provided by your chocolatey install) to re-read the environment for the tools to be available in this shell session."
