<#
.SYNOPSIS
    This script sets the default shell options for openssh.  It is run during the opensssh universal installer and can be called separately to update the default shell exe after releated update (e.g. like updating PowerShell Core)
.DESCRIPTION
    This script is used during OpenSSH install if the appropriate package options were specified.

    It can also be used seperately (such as calling it after installing a new version of PowerShell Core 
    or updating another shell that should be the default for openssh)

    #It never really makes sense to search for cmd.exe as that is the default behavior and you shouldn't try to put old versions of cmd.exe on a newer version of windows 
    (I guess the exception would be configuring ssh to use 32-bit cmd.exe under 64-bit sshd.exe system - no I don't know why you would do that - but Murphy predicts someone out there will need to - hopefully not you)

    #"Windows Powershell" should always be at the end of a multi-filespec request because it will always be found

    #Environment variables are preferred for paths so that your call applies to windows not being on C: and folder redirection scenarios

    #If the list of path specs does not result in one or more valid results, then the default behavior (no registry keys) is used (graceful fall through)

    # ATTENTION - if you run this package under a 32-bit process on 64-bit Windows (e.g. SCCM "Package" objects), it will result in setting up 32-bit system exes as the shell for 64-bit sshd.exe


    Rules (For the sake of sanity, don't read these rules if you just want to do something simple like set Windows PowerShell to be your default ssh shell - use the examples)
    - the combined results will be in order that the filespecs are provided so that precedence can be specified for specific shell EXE filenames
    - the exes in each filespec can be the same (when searching multiple folder heirarchies for the same shell exe) or different (when giving preference to one shell EXE, but providing a fall through default if none are found)
    - wildcards can only be used in the pathname, not the filename  (filename wild cards will cause the filespec to be filtered out of the list)
    - each filespec must be searching for a SPECIFIC exe file (cannot search for <something>\*.exe nor <something>\* nor anything not ending in .exe) (any that don't match are filtered out of the filespec list)
    - each filespec result set is sorted by descending version number before being concatenated to the combined result list so that the newest of that shell exe will be chosen 
    - because early powershell core exe do not include versions in the PE header, they are sorted by full folder name which includes the version
    - the file list will only contain actually found EXEs
    - the file list is screened for known secure folders that require admin rights to update on windows configured with default security (the rest are filtered out)
    - the first valid hit in the overall resultant file list will be used.
    - if you do not want version autoselection, then specify the path exact location to the exact version you wish to have considered

.LINK
	http://www.lazywinadmin.com/2014/08/powershell-parse-this-netstatexe.html

.EXAMPLE
#All of these filespecs will be filtered out (dropped) because you can't wildcard the exe name, for securities sake you must know what the shell is called to use it:
-PathSpecsToProbeForShellEXEString "$env:userprofile\downloads\*.exe;c:\Program Files\PowerShell\*\P*.exe;c:\windows\system32\*"

.EXAMPLE
#PowerShell for Windows instead of default cmd.exe, if not found, default behavior (no registry key created, cmd.exe is ssh default):
-PathSpecsToProbeForShellEXEString '$env:windir\system32\windowspowershell\v1.0\powershell.exe"

.EXAMPLE
#The latest version of powershell core (including favoring the new EXE name), if not found, use windows powershell
-PathSpecsToProbeForShellEXEString "$env:programfiles\PowerShell\*\pwsh.exe;$env:programfiles\PowerShell\*\Powershell.exe;c:\windows\system32\windowspowershell\v1.0\powershell.exe"

.EXAMPLE
#The latest version of Ruby, if not found, powershell core if not found, default behavior (no registry key created, cmd.exe is ssh default)
-PathSpecsToProbeForShellEXEString "c:\tools\ruby*\bin\ruby.exe;c:\Program Files\PowerShell\*\pwsh.exe;c:\Program Files\PowerShell\*\Powershell.exe"

#I have no idea if ruby can actually be an SSH shell - just an example

.EXAMPLE
#Windows Subsystem for Linux Bash.exe, if not found, the latest version of git's bash.exe, if not found, default behavior (no registry key created, cmd.exe is ssh default)
-PathSpecsToProbeForShellEXEString "$env:windir\system32\bash.exe;$env:programfiles\Git\usr\bin\bash.exe"

#I have no idea if git's bash can actually be an SSH shell - just an example

.EXAMPLE
#Specific version of powershell core, if not found, windows powershell
-PathSpecsToProbeForShellEXEString "c:\Program Files\PowerShell\6.0.0-beta.6\Powershell.exe;c:\windows\system32\windowspowershell\v1.0\powershell.exe"

.EXAMPLE
#malware.exe filtered out because it is not in a secure folder, Specific version of powershell core, if not found, windows powershell
-PathSpecsToProbeForShellEXEString "$env:userprofile\downloads\malware.exe;c:\Program Files\PowerShell\6.0.0-beta.6\Powershell.exe;c:\windows\system32\windowspowershell\v1.0\powershell.exe"

.EXAMPLE
#malware.exe is used because of -AllowInsecureShellEXE
-AllowInsecureShellEXE -PathSpecsToProbeForShellEXEString "$env:userprofile\downloads\malware.exe;c:\Program Files\PowerShell\6.0.0-beta.6\Powershell.exe;c:\windows\system32\windowspowershell\v1.0\powershell.exe"

.NOTES
	Darwin Sanoy
	cloudywindows.io
 
#>
Param (
  [Parameter(Mandatory=$True)]
  [string]$PathSpecsToProbeForShellEXEString,
  [string]$SSHDefaultShellCommandOption=$null,
  [switch]$AllowInsecureShellEXE
  )

  $OpeningMessage = @"
  
  ************************************************************************************    
  This utility script:
  
    $($MyInvocation.MyCommand.Definition)

  can be run outside of this package in order to update the OpenSSH DefaultShell when 
  an installer runs to update the default shell.
  
  See the following for more details:
  https://github.com/DarwinJS/ChocoPackages/blob/master/openssh/readme.md
  https://cloudwindows.io
  ************************************************************************************
  
"@
  
  Write-Output $OpeningMessage

If ($AllowInsecureShellEXE)
{
Write-Warning "AllowInsecureShellEXE was used, if probing results in selecting a shell exe that is user writable, it will still be used.  Not wise!!"
}

<#
TEST string
#$PathSpecsToProbeForShellEXEString = '$env:userprofile\downloads\*.exe;$env:programfiles\powershell\*\powershell.exe;$env:windir\system32\cmd.exe;c:\windows'
#>

#Expand any literalized variable or environment variable references, also only resolves to items that exist
Write-Host "Set-SSHDefaultShell.ps1 processing request for `"$PathSpecsToProbeForShellEXEString`""
$ShellEXEToUse = $null
$PathSpecsToProbeForShellEXE = $ExecutionContext.InvokeCommand.ExpandString($PathSpecsToProbeForShellEXEString).split(';') 
#write-host "`$PathSpecsToProbeForShellEXE: $PathSpecsToProbeForShellEXE"
$ListOfSecurePaths = "$env:programfiles","${env:ProgramFiles(x86)}","$env:windir\system32","$env:windir\syswow64"
$ListOfSecurePathsRegExPrep = $ListOfSecurePaths | ForEach {[Regex]::Escape($ExecutionContext.InvokeCommand.ExpandString($_)) + ".*`|"}
$ListOfSecurePathsRegExString = ($ListOfSecurePathsRegExPrep -join '').trimend("|")
#write-host "`$ListOfSecurePathsRegExString: $ListOfSecurePathsRegExString"
If ($PathSpecsToProbeForShellEXE.count -ge 1)
{
#Special Handling of "C:\Program Files\PowerShell" for versioned subfolders and EXEs with no PE header version
$ListOfEXEObjects = @()
[array]$SubListofEXEObjects 
ForEach ($PathSpec in $PathSpecsToProbeForShellEXE)
{ write-host "processing $pathspec"
  $SubListOfEXEPaths = @(Resolve-Path $PathSpec -ErrorAction SilentlyContinue)
  write-host "`$SubListOfEXEPaths: $SubListOfEXEPaths"
  $SubListOfEXEPaths = @($SubListOfEXEPaths | where {[IO.Path]::GetExtension($_) -ieq '.exe'})
  If ($SubListOfEXEPaths.count -gt 0)
  {
    $SubListofEXEObjects = @(get-command $SubListOfEXEPaths)
  
    If ($PathSpec -ilike "$env:ProgramFiles\PowerShell\*")
    { #apply a sort to full file names
      $SubListOfEXEObjects = $SubListOfEXEObjects | sort-object -Property 'Definition' -Descending
    }
    else 
    {
      $SubListOfEXEObjects = $SubListOfEXEObjects | sort-object -Property FileVersionInfo.ProductVersion -Descending
    }
    $ListOfEXEObjects += $SubListOfEXEObjects
  }
}

If ($ListOfEXEObjects.count -lt 1)
{
  Write-warning "On this system, searching $PathSpecsToProbeForShellEXEString does not result in any paths that end in .EXE, DefaultShell will not be explicitly set and ssh will use its default shell behavior or the existing registry key value."
}
else 
{    
  $ListOfValidEXEObjects = @()
  If (!$AllowInsecureShellEXE)
  {
    Write-Host "Filtering out EXEs that are not on the secure path list: $ListOfSecurePaths.  To unwisely override this filtering use the AllowInsecureShellEXE switch."
    ForEach ($EXEObject in $ListOfEXEObjects)
    { #Validate EXEs are on Secure Paths
      If ($EXEObject.Definition -imatch "$ListOfSecurePathsRegExString")
      {
        Write-Host "     Valid: $($EXEObject.Definition)"
        $ListOfValidEXEObjects += $EXEObject
      }
      else 
      {
        Write-Warning "  Dropping: $($EXEObject.Definition)"
      }
    }
    $ListOfEXEObjects = $ListOfValidEXEObjects
  }

  If ($ListOfEXEObjects.count -ge 1)
  {
    $ShellEXEToUse = $ListOfEXEObjects | Select-Object -First 1 -Expand Definition
    Write-host "Shell to use: $ShellEXEToUse"
    If ($ShellEXEToUse)
    {
      Write-Host "Writing default shell to registry ($ShellEXEToUse)"
      $SSHRegKey = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\OpenSSH"
      If (!(Test-Path $SSHRegKey))
      {
        New-Item -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE" -Name 'OpenSSH' –Force | out-null
      }

      New-ItemProperty -Path $SSHRegKey -Name 'DefaultShell' -Value "$ShellEXEToUse" -PropertyType 'String' -Force | Out-Null
      If ($SSHDefaultShellCommandOption)
      {
        Write-Host "Writing default shell command option to registry ($SSHDefaultShellCommandOption)"    
        New-ItemProperty -Path $SSHRegKey -Name 'DefaultShellCommandOption' -Value "$SSHDefaultShellCommandOption" -PropertyType 'String' -Force  | Out-Null
      }
      else 
      {  #Revert to default behavior if not specified
        Remove-ItemProperty -Path $SSHRegKey -Name 'DefaultShellCommandOption' -ErrorAction 'SilentlyContinue'
      }
    }      
  }
  else {
    Write-Warning "After all filtering criteria was applied, there is no matching EXE for your search string: $PathSpecsToProbeForShellEXEString"
  }
}
}
