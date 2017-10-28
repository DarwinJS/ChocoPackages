
$ErrorActionPreference = 'Stop'; # stop on all errors
$ProductName = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'ProductName').ProductName
$EditionId = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'EditionID').EditionId

Write-Output "Running on: $ProductName, ($EditionId)"

$RunningOnNano = $False
If ($EditionId -ilike '*Nano*')
{$RunningOnNano = $True}

If (Test-Path variable:shimgen)
{$RunningUnderChocolatey = $True}
Else
{ Write-Output "Running Without Chocolatey"
$RunningUnderChocolatey = $False}

$packageName= 'openssh'
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

#$TargetFolder = "$PF\OpenSSH"
$TargetFolder = "$PF\OpenSSH-Win$($OSBits)"
$TargetFolderOld = "$PF\OpenSSH-Win$($OSBits)"

If ($RunningUnderChocolatey)
{
  # Default the values before reading params
  $SSHServerFeature = $false
  $KeyBasedAuthenticationFeature = $false
  $DeleteConfigAndServerKeys = $false

  $arguments = @{};
  $packageParameters = $env:chocolateyPackageParameters
}
# Now parse the packageParameters using good old regular expression
if ((test-path variable:packageparameters) -AND $packageParameters) {
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
    Stop-Service SSHD -Force
    Stop-Service SSH-Agent -Force
    Start-Sleep -seconds 3
    If (([bool](Get-Service SSHD | where {$_.Status -ieq 'Running'})))
    {
      Throw "Could not stop the SSHD service, please stop manually and retry this package."
    }
    Stop-Service ssh-agent -Force
    Start-Sleep -seconds 3
    If (([bool](Get-Service ssh-agent | where {$_.Status -ieq 'Running'})))
    {
      Throw "Could not stop the ssh-agent service, please stop manually and retry this package."
    }
}

$KeyBasedAuthenticationFeatureINSTALLED = $False
If ((get-item 'Registry::HKLM\System\CurrentControlSet\Control\Lsa').getvalue("authentication packages") -contains 'ssh-lsa')
{
  $KeyBasedAuthenticationFeatureINSTALLED = $True
  Write-Warning "ssh-lsa.dll will be deconfigured - but not deleted.  It must be manually deleted after a reboot."
}

#uninstall agent service if it was installed without SSHD
If ($SSHAGENTServiceInstanceExistsAndIsOurs -AND (!$SSHServiceInstanceExistsAndIsOurs))
{
  Stop-Service ssh-agent -Force
  sc.exe delete ssh-agent | out-null
}

If ($SSHServiceInstanceExistsAndIsOurs -AND ($SSHServerFeature))
{
  Stop-Service sshd -Force
  sc.exe delete sshd  | out-null
  Stop-Service ssh-agent -Force
  sc.exe delete ssh-agent | out-null
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

  $AuthpkgToRemove = 'ssh-lsa'
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
}

#Don't remove config in case they reinstall.
If (($SSHServiceInstanceExistsAndIsOurs -AND $DeleteConfigAndServerKeys) -OR (!$SSHServiceInstanceExistsAndIsOurs))
{
    Write-Warning "Removing all config and server keys as requested by /DeleteConfigAndServerKeys"
    
    #Ensure we have permissions to all keys and config files:
    #$ErrorActionPreference = 'SilentlyContinue'
    If (Test-Path "$toolsdir\OpenSSHUtils.psm1") {Import-Module "$toolsdir\OpenSSHUtils" -Force}
    $RunningUser = New-Object System.Security.Principal.NTAccount($($env:USERDOMAIN), $($env:USERNAME))
    #dir "$TargetFolder\*" | % {repair-filepermission -FilePath $_.fullname -ReadAccessOK $RunningUser -AnyAccessOK $RunningUser -ReadAccessNeeded $RunningUser -confirm:$false}
    dir "$TargetFolder\*" | % {repair-filepermission -FilePath $_.fullname -confirm:$false}

    If (Test-Path $TargetFolder) {Remove-Item "$TargetFolder" -Recurse -Force}
    #$ErrorActionPreference = 'Stop'
}
Else
{

  If (Test-Path $TargetFolder) {Get-ChildItem "$TargetFolder\*.*" -include *.exe,*.dll,*.cmd,*.ps1,*.psm1,*.psd1 | Remove-Item -Recurse -Force}
  If (Test-Path "$TargetFolder\logs") {Remove-Item "$TargetFolder\logs" -Recurse -Force}
  Write-Warning "NOT REMOVED: Config files and any keys in `"$TargetFolder`" were NOT REMOVED - you must remove them manually or use the package uninstall parameter /DeleteConfigAndServerKeys."
}
netsh advfirewall firewall delete rule name='SSHD Port OpenSSH (chocolatey package: openssh)'

$PathToRemove = "$TargetFolder"
#Code has been modified to work with Nano - do not change method of environment variable access
#foreach ($path in [Environment]::GetEnvironmentVariable("PATH","Machine").split(';'))
foreach ($path in ((Get-ItemProperty 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment').path.split(';')))
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

Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' -Name 'PATH' -Value "$AssembledNewPath"

$TermVarExists = [bool](get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' -Name 'TERM' -EA SilentlyContinue)
If ($TermVarExists)
{
  Remove-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' -Name 'TERM'
}