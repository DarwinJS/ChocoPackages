<#
See http://technet.microsoft.com/en-us/library/hh847769.aspx and http://technet.microsoft.com/en-us/library/hh847837.aspx
Windows PowerShell 5.0 runs on the following versions of Windows.
	Windows 10, installed by default
	Windows Server 2012 R2, install Windows Management Framework 5.0 to run Windows PowerShell 5.0
	Windows 8.1, install Windows Management Framework 5.0 to run Windows PowerShell 5.0
	Windows 7 with Service Pack 1, install Windows Management Framework 4.0 and THEN WMF 5.0 (as of 5.0.10105)
	Windows Server 2008 R2 with Service Pack 1, install Windows Management Framework 5.0 (as of 5.0.10105)
	Previous Windows versions - 5.0 is not supported.
 
Windows PowerShell 4.0 runs on the following versions of Windows.
	Windows 8.1, installed by default
	Windows Server 2012 R2, installed by default
	Windows 7 with Service Pack 1, install Windows Management Framework 4.0 (http://go.microsoft.com/fwlink/?LinkId=293881) to run Windows PowerShell 4.0
	Windows Server 2008 R2 with Service Pack 1, install Windows Management Framework 4.0 (http://go.microsoft.com/fwlink/?LinkId=293881) to run Windows PowerShell 4.0
 
Windows PowerShell 3.0 runs on the following versions of Windows.
	Windows 8, installed by default
	Windows Server 2012, installed by default
	Windows 7 with Service Pack 1, install Windows Management Framework 3.0 to run Windows PowerShell 3.0
	Windows Server 2008 R2 with Service Pack 1, install Windows Management Framework 3.0 to run Windows PowerShell 3.0
	Windows Server 2008 with Service Pack 2, install Windows Management Framework 3.0 to run Windows PowerShell 3.0
#>

[string]$packageName="PowerShell.5.0"
[string]$installerType="msu"
[string]$ThisPackagePSHVersion = '5.0.10586'
[string]$silentArgs="/quiet /norestart /log:`"$env:TEMP\PowerShell.Install.evtx`""
																										
[string]$urlWin81x86   =                 'https://download.microsoft.com/download/2/C/6/2C6E1B4A-EBE5-48A6-B225-2D2058A9CEFB/Win8.1-KB3094174-x86.msu'
[string]$urlWin2k12R2andWin81x64 =       'https://download.microsoft.com/download/2/C/6/2C6E1B4A-EBE5-48A6-B225-2D2058A9CEFB/W2K12R2-KB3094174-x64.msu'
[string]$urlWin7x86   =                  'https://download.microsoft.com/download/2/C/6/2C6E1B4A-EBE5-48A6-B225-2D2058A9CEFB/Win7-KB3094176-x86.msu'
[string]$urlWin2k8R2andWin7x64 =         'https://download.microsoft.com/download/2/C/6/2C6E1B4A-EBE5-48A6-B225-2D2058A9CEFB/W2K8R2-KB3094176-x64.msu'
[string]$urlWin2012 =                    'https://download.microsoft.com/download/2/C/6/2C6E1B4A-EBE5-48A6-B225-2D2058A9CEFB/W2K12-KB3094175-x64.msu'
  
[string[]] $validExitCodes = @(0, 3010) # 2359302 occurs if the package is already installed


$osversionLookup = @{
"5.1.2600" = "XP";
"5.1.3790" = "2003";
"6.0.6001" = "Vista/2008";
"6.1.7600" = "Win7/2008R2";
"6.1.7601" = "Win7 SP1/2008R2 SP1"; # SP1 or later.
"6.2.9200" = "Win8/2012";
"6.3.9600" = "Win8.1/2012R2";
"10.0.*" = "Windows 10"
}


function Install-PowerShell5([string]$urlx86, [string]$urlx64 = $null) {    
    $Net4Version = (get-itemproperty "hklm:software\microsoft\net framework setup\ndp\v4\full" -ea silentlycontinue | Select -Expand Release -ea silentlycontinue) 
    if ($Net4Version -ge 378675) {
        Install-ChocolateyPackage "$packageName" "$installerType" "$silentArgs" $urlx86 $urlx64  -validExitCodes $validExitCodes
        Write-Warning "$packageName requires a reboot to complete the installation."
        #}
    }
    else {
        throw ".NET Framework 4.5.1 or later required.  Use `"Choco Install dotnet4.5.1`"."
    }
}


try
{
    if ($PSVersionTable -and ($PSVersionTable.PSVersion -ge [Version]$ThisPackagePSHVersion)) {
	    Write-Warning "PowerShell version, $($PSVersionTable.PSVersion), is already installed."
	}
    elseif ($PSVersionTable -and ($PSVersionTable.PSVersion -ge [Version]'5.0') -and ($PSVersionTable.PSVersion -lt [Version]$ThisPackagePSHVersion)) {
        Write-Warning "The existing PowerShell version, $($PSVersionTable.PSVersion), must be uninstalled, before you can install version $ThisPackagePSHVersion."
    } 
    else {
        try {
            #Consider using Get-Command with -ErrorAction of Ignore
            $osVersion = (Get-CimInstance "Win32_OperatingSystem").Version #Not supported prior to Windows 8//2012
        }
        catch {
            $osVersion = (Get-WmiObject Win32_OperatingSystem).Version
        }
        #The following should not occur as PowerShell 5 is already installed
        if( ([version]$osVersion).Major -eq "10" ) { $osVersion = "$(([version]$osVersion).Major).$(([version]$osVersion).Minor).*" }
	   
        Write-Verbose "Installing for OS: $($osversionLookup[$osVersion])"

		switch ($osversionLookup[$osVersion]) {
            "Vista/2008" {
                Write-Warning "$packageName not supported on $($osversionLookup[$osVersion]).  Attempting to install PowerShell 3.0"
                cinst -y PowerShell -version 3.0.20121027
            }
            "Win7/2008R2" {
                Write-Warning "$packageName not supported on $($osversionLookup[$osVersion]).  Attempting to install PowerShell 3.0"
                Write-Warning "Update to SP1 to install WMF/PowerShell 5"
                cinst -y PowerShell -version 3.0.20121027
            }
            "Win7 SP1/2008R2 SP1" {
                Install-PowerShell5 "$urlWin7x86" "$urlWin2k8R2andWin7x64"
            }
            "Win8/2012" {	 
                if($os.ProductType -eq 3) {
                    #Windows 2012
                    Install-PowerShell5 "$urlWin2012"
                }
                else {
                    #Windows 8
                    Write-Verbose "Windows 8 (not 8.1) is not supported"
                    throw "$packageName not supported on Windows 8. You must upgrade to Windows 8.1 to install WMF/PowerShell 5.0."
                }
            }
            "Win8.1/2012R2" {
                Install-PowerShell5 "$urlWin81x86" "$urlWin2k12R2andWin81x64"
            }
            "Windows 10" {
                #Should never be reached.
                Write-Warning "Windows 10 has WMF/PowerShell 5 pre-installed and cannot be upgraded."
            }
            default { 
                # Windows XP, Windows 2003, Windows Vista, or unknown?
                throw "$packageName is not supported on this operating system (Windows XP, Windows 2003, Windows Vista, or ?)."
            }
	    }
    }
}
catch {
  Throw $_.Exception
}