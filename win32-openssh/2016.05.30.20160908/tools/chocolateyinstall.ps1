
If (Test-Path variable:shimgen)
{
  $RunningUnderChocolatey = $True
  Write-Output "Running under Chocolatey"
}

$ErrorActionPreference = 'Stop'; # stop on all errors
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

$filename = "$toolsdir\OpenSSH-Win$($OSBits).zip"
#$TargetFolder = "$PF\OpenSSH"
#$TargetFolderOld = "$PF\OpenSSH-Win$($OSBits)"
$TargetFolder = "$PF\OpenSSH-Win$($OSBits)"
$ExtractFolder = "$env:temp\OpenSSHTemp"

$packageArgs = @{
  packageName   = 'win32-openssh'
  unziplocation = "$ExtractFolder"
  fileType      = 'EXE_MSI_OR_MSU' #only one of these: exe, msi, msu
  url           = 'https://github.com/PowerShell/Win32-OpenSSH/releases/download/5_30_2016/OpenSSH-Win32.zip'
  url64bit      = 'https://github.com/PowerShell/Win32-OpenSSH/releases/download/5_30_2016/OpenSSH-Win64.zip'

  checksum      = 'B44CC37CCF9C3E4917440B1DFEBB8052'
  checksumType  = 'md5'
  checksum64    = '1D9574A785EB0CD45380DD33DB11D7B0'
  checksumType64= 'md5'
}

If ($RunningUnderChocolatey)
{
  # Default the values before reading params
  $SSHServerFeature = $false
  $KeyBasedAuthenticationFeature = $false
  $DeleteServerKeysAfterInstalled = $false
  $UseNTRights = $false

  $arguments = @{};
  $packageParameters = $env:chocolateyPackageParameters
}

<#
If (Test-Path $TargetFolderOld)
{
  Throw "Upgrading Win32-OpenSSH over the old folder ($TargetFolderOld) will result in unpredictable results, please uninstall (with the /DeleteConfigAndServerKeys switch) and reinstall instead.)."
}
#>

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

    if ($arguments.ContainsKey("UseNTRights")) {
        Write-Host "Using ntrights.exe to set service permissions (will not work, but generate warning if WOW64 is not present on 64-bit machines)"
        $UseNTRights = $true
    }

    if ($arguments.ContainsKey("DeleteServerKeysAfterInstalled")) {
        Write-Host "Deleting server private keys after they have been secured."
        $DeleteServerKeysAfterInstalled = $true
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

Function CheckServicePath ($ServiceEXE,$FolderToCheck)
{
  #The modern way:
  #Return ([bool]((Get-WmiObject win32_service | ?{$_.Name -ilike "*$ServiceEXE*"} | select -expand PathName) -ilike "*$FolderToCheck*"))
  #The NANO TP5 Compatible Way:
  Return ([bool]((wmic service | ?{$_ -ilike "*$ServiceEXE*"}) -ilike "*$FolderToCheck*"))
}

#$SSHServiceInstanceExistsAndIsOurs = ([bool]((Get-WmiObject win32_service | ?{$_.Name -ilike 'sshd'} | select -expand PathName) -ilike "*$TargetFolder*"))
$SSHServiceInstanceExistsAndIsOurs = CheckServicePath 'sshd' "$TargetFolder"
#$SSHAGENTServiceInstanceExistsAndIsOurs = ([bool]((Get-WmiObject win32_service | ?{$_.Name -ilike 'ssh-agent'} | select -expand PathName) -ilike "*$TargetFolder*"))
$SSHAGENTServiceInstanceExistsAndIsOurs = CheckServicePath 'ssh-agent' "$TargetFolder"

If ($SSHServerFeature -AND (!$SSHServiceInstanceExistsAndIsOurs) -AND ([bool](Get-Service sshd -ErrorAction SilentlyContinue)))
{
  $ExistingSSHDInstancePath = split-path -parent (((wmic service | ?{$_ -ilike '*sshd*'}) -ilike "*$TargetFolder*").split('=')[1].trim())
  #(Get-WmiObject win32_service | ?{$_.Name -ilike 'sshd'} | select -expand PathName)
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
    stop-service sshd -Force
    If (([bool](Get-Service SSHD | where {$_.Status -ieq 'Running'})))
    {
      Throw "Could not stop the SSHD service, please stop manually and retry this package."
    }
    If ($SSHAGENTServiceInstanceExistsAndIsOurs)
    {
      stop-service ssh-agent -Force
      If (([bool](Get-Service ssh-agent | where {$_.Status -ieq 'Running'})))
      {
        Throw "Could not stop the ssh-agent service, please stop manually and retry this package."
      }
    }

}

If ($SSHServiceInstanceExistsAndIsOurs)
{
  Stop-Service sshd
  sc.exe delete sshd | out-null
}
If ($SSHAGENTServiceInstanceExistsAndIsOurs)
{
  Stop-Service ssh-agent -erroraction silentlycontinue
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
If ((Get-FileHash $filename -Algorithm $SourceZipChecksumType).Hash -eq $SourceZipChecksum)
{
  Write-Output "Hashes for internal source match"
}

If ($RunningUnderChocolatey)
{
  #Install-ChocolateyZipPackage @packageArgs
  Get-ChocolateyUnzip "$filename" $ExtractFolder
  Install-ChocolateyPath "$TargetFolder" 'Machine'
}
Else
{
  #Unzip to targetfolder
  If ([bool](Get-command expand-archive -ea SilentlyContinue))
  {
    #covers server 2016
    Expand-Archive -Path $filename -DestinationPath $ExtractFolder
  }
  Else
  If (Test-Path "$toolsdir\7z.exe")
  {
    #covers nano
    cd $toolsdir
    .\7z.exe x $filename -o"$ExtractFolder"
  }
  Else
  {
    Throw "You need a copy of 7z.exe next to this script for this operating system.  You can get a copy at 7-zip.org"
  }

  #add to path
}

Copy-Item "$ExtractFolder\*" "$PF" -Force -Recurse
Remove-Item "$ExtractFolder" -Force -Recurse

$SSHLsaVersionChanged = $true
If (Test-Path "$env:windir\system32\ssh-lsa.dll")
{
  #Using file size because open ssh files are not currently versioned.  Submitted problem report asking for versioning to be done
  If (((get-item $env:windir\system32\ssh-lsa.dll).length) -eq ((get-item $TargetFolder\ssh-lsa.dll).length))
  {$SSHLsaVersionChanged = $false}
}


If ($SSHServerFeature)
{
  Write-Warning "You have specified SSHServerFeature - this machine is being configured as an SSH Server including opening port 22."

    Write-Warning "You have specified SSHServerFeature - a new lsa provider will be installed."
    If (Test-Path "$env:windir\sysnative")
    { #We are running in a 32-bit process under 64-bit Windows
      $sys32dir = "$env:windir\sysnative"
    }
    Else
    { #We are on a 32-bit OS, or 64-bit proc on 64-bit OS
      $sys32dir = "$env:windir\system32"
    }

    If ($SSHLsaVersionChanged)
    {
      Copy-Item "$TargetFolder\ssh-lsa.dll" "$sys32dir\ssh-lsa.dll" -Force
    }

    #Don't destroy other values
    $key = get-item 'Registry::HKLM\System\CurrentControlSet\Control\Lsa'
    $values = $key.GetValue("Authentication Packages")
    $values += 'ssh-lsa'
    Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\" "Authentication Packages" $values


  If((Test-Path "$TargetFolder\sshd_config") -AND ([bool]((gc "$TargetFolder\sshd_config") -ilike "*#LogLevel INFO*")))
  {
    Write-Warning "Explicitly disabling sshd logging as it currently logs about .5 GB / hour"
    (Get-Content "$TargetFolder\sshd_config") -replace '#LogLevel INFO', 'LogLevel QUIET' | Set-Content "$TargetFolder\sshd_config"
  }

  If (!(Test-Path "$TargetFolder\KeysGenerated.flg"))
  { #Only ever generate a key the first time SSHD server is installed
      Write-Output "Generating sshd keys in `"$TargetFolder`""
      start-process "$TargetFolder\ssh-keygen.exe" -ArgumentList '-A' -WorkingDirectory "$TargetFolder" -nonewwindow -wait
      New-Item "$TargetFolder\KeysGenerated.flg" -type File | out-null
  }
  Else
  {
    Write-Warning "Found existing server ssh keys in $TargetFolder, you must delete them manually to generate new ones."
  }

  netsh advfirewall firewall add rule name='SSHD Port win32-openssh' dir=in action=allow protocol=TCP localport=22
  New-Service -Name ssh-agent -BinaryPathName "$TargetFolder\ssh-agent.exe" -Description "SSH Agent" -StartupType Automatic | Out-Null
  cmd.exe /c 'sc.exe sdset ssh-agent D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;IU)(A;;CCLCSWLOCRRC;;;SU)(A;;RP;;;AU)'

  Start-Service ssh-agent

  Start-Sleep -seconds 3

  $keylist = "ssh_host_dsa_key", "ssh_host_rsa_key", "ssh_host_ecdsa_key", "ssh_host_ed25519_key"
  $fullpathkeylist = "'$TargetFolder\ssh_host_dsa_key'", "'$TargetFolder\ssh_host_rsa_key'", "'$TargetFolder\ssh_host_ecdsa_key'", "'$TargetFolder\ssh_host_ed25519_key'"

  schtasks.exe /create /RU "NT AUTHORITY\SYSTEM" /RL HIGHEST /SC ONSTART /TN "ssh-add" /TR "'$TargetFolder\ssh-add.exe'  $fullpathkeylist" /F

  schtasks.exe /Run /I /TN "ssh-add"

  schtasks.exe /Delete /TN "ssh-add" /F

  #Start-Process "$toolsDir\psexec.exe" -ArgumentList "-accepteula -s -w `"$TargetFolder`" ssh-add.exe $keylist " -wait

  If ($DeleteServerKeysAfterInstalled)
  {
    pushd $TargetFolder
    Foreach ($keyfile in $keylist)
    {
      If (Test-Path $keyfile)
      {
        Remove-Item $keyfile -force
      }
    }
    popd
  }
  Else
  {
    Write-Warning "The following private keys should be removed from the machine: $keylist"
  }
  New-Service -Name sshd -BinaryPathName "$TargetFolder\sshd.exe" -Description "SSH Deamon" -StartupType Automatic -DependsOn ssh-agent | Out-Null
  sc.exe config sshd obj= "NT SERVICE\SSHD"

  If (!$UseNTRights)
  {
    #The code in this .PS1 has been tested on Nano - the hardest case to date for setting special privileges in script
    . "$toolsdir\AddAccountToAssignPrimaryToken.ps1" -AccountToAdd "NT SERVICE\SSHD"
  }
  Else
  {
    If (($OSBits -eq 64) -and (!(Test-Path "$env:windir\syswow64")))
    {
      Write-Warning "This 64-bit system does not have the WOW64 subsystem installed, please manually grant the right SeLogonAsAService to `"NT SERVICE\SSHD`"."
      Write-Warning "OR try again WITHOUT the /UseNTRights switch."
    }
    Else
    {
      write-output "Using ntrights.exe to grant logon as service."
      Start-Process "$TargetFolder\ntrights.exe" -ArgumentList "-u `"NT SERVICE\SSHD`" +r SeAssignPrimaryTokenPrivilege"
    }
  }

  If (!$SSHLsaVersionChanged)
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
