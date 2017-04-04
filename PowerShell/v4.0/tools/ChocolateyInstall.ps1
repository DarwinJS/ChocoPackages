

<#
See http://technet.microsoft.com/en-us/library/hh847769.aspx and http://technet.microsoft.com/en-us/library/hh847837.aspx
Windows PowerShell 4.0 runs on the following versions of Windows.
    Windows 8.1, installed by default
    Windows Server 2012 R2, installed by default
    Windows® 7 with Service Pack 1, install Windows Management Framework 4.0 (http://go.microsoft.com/fwlink/?LinkId=293881) to run Windows PowerShell 4.0
    Windows Server® 2008 R2 with Service Pack 1, install Windows Management Framework 4.0 (http://go.microsoft.com/fwlink/?LinkId=293881) to run Windows PowerShell 4.0

Windows PowerShell 3.0 runs on the following versions of Windows.
    Windows 8, installed by default
    Windows Server 2012, installed by default
    Windows® 7 with Service Pack 1, install Windows Management Framework 3.0 to run Windows PowerShell 3.0
    Windows Server® 2008 R2 with Service Pack 1, install Windows Management Framework 3.0 to run Windows PowerShell 3.0
    Windows Server 2008 with Service Pack 2, install Windows Management Framework 3.0 to run Windows PowerShell 3.0
#>

try
{
  [string]$packageName="PowerShell.4.0"
  [string]$installerType="msu"
  [string]$silentArgs="/quiet /norestart /log:`"$env:TEMP\PowerShell.v4.Install.log`""
  [string]$url   = 'http://download.microsoft.com/download/3/D/6/3D61D262-8549-4769-A660-230B67E15B25/Windows6.1-KB2819745-x86-MultiPkg.msu' 
  [string]$url64 = 'http://download.microsoft.com/download/3/D/6/3D61D262-8549-4769-A660-230B67E15B25/Windows6.1-KB2819745-x64-MultiPkg.msu' 
  [string]$urlWin2012 = 'http://download.microsoft.com/download/3/D/6/3D61D262-8549-4769-A660-230B67E15B25/Windows8-RT-KB2799888-x64.msu' 
  [string[]] $validExitCodes = @(0, 3010) # 2359302 occurs if the package is already installed.

  if ($PSVersionTable -and ($PSVersionTable.PSVersion -ge [Version]'4.0'))
  {
    Write-Warning "$packageName or newer is already installed"
  }
    else {
        $osversionLookup = @{
        "5.1.2600" = "XP";
        "5.1.3790" = "2003";
        "6.0.6001" = "Vista/2008";
        "6.1.7601" = "Win7/2008R2";
        "6.2.9200" = "Win8/2012";
        "6.3.9600" = "Win8.1/2012R2";
        }

        try {
            #Consider using Get-Command with -ErrorAction of Ignore
            $osVersion = (Get-CimInstance "Win32_OperatingSystem").Version #Not supported prior to Windows 8//2012
        }
        catch {
            $osVersion = (Get-WmiObject Win32_OperatingSystem).Version
        }
    
        switch ($osversionLookup[$osVersion]) {
            "Vista/2008" {
                Write-Warning "$packageName not supported on your OS.  Attempting to install PowerShell 3.0"
                cinst PowerShell -version 3.0.20121027
            }
            "Win7/2008R2" {
                Install-ChocolateyPackage "$packageName" "$installerType" "$silentArgs" "$url" "$url64"  -validExitCodes $validExitCodes
                Write-Warning "$packageName requires a reboot to complete the installation."
                Write-ChocolateySuccess $packageName
            }
            "Win8/2012" {
                $os = (Get-CimInstance "Win32_OperatingSystem")
                if($os.ProductType -eq 3) {
                    Install-ChocolateyPackage "$packageName" "$installerType" "$silentArgs" $urlWin2012  -validExitCodes $validExitCodes
                    Write-Warning "$packageName requires a reboot to complete the installation."
                }
                else {
                    throw "$packageName not supported on Windows 8. You must upgrade to Windows 8.1 to get WMF 4.0."
                }
            }
            "Win8.1/2012R2" {
                throw "Should not get here because we already checked `$PSVersionTable.PSVersion, '$($PSVersionTable.PSVersion)', -ge $([Version]'4.0')"
            }
            default { 
                # Windows XP, Windows 2003, Windows Vista, or unknown?
                throw "$packageName is not supported on this operating system (Windows XP, Windows 2003, Windows Vista, or ?)."
            }
        }
    }
}
catch {
  Write-ChocolateyFailure $packageName $($_.Exception.Message)
}


