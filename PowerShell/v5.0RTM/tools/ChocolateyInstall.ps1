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

[string]$urlWin81x86   =                 'https://download.microsoft.com/download/2/C/6/2C6E1B4A-EBE5-48A6-B225-2D2058A9CEFB/Win8.1-KB3134758-x86.msu'
[string]$urlWin81x86checksum   =         'F9EE4BF2D826827BC56CD58FABD0529CB4B49082B2740F212851CC0CC4ACBA06'
[string]$urlWin2k12R2andWin81x64 =       'https://download.microsoft.com/download/2/C/6/2C6E1B4A-EBE5-48A6-B225-2D2058A9CEFB/Win8.1AndW2K12R2-KB3134758-x64.msu'
[string]$urlWin2k12R2andWin81x64checksum = 'BB6AF4547545B5D10D8EF239F47D59DE76DAFF06F05D0ED08C73EFF30B213BF2'
[string]$urlWin7x86   =                  'https://download.microsoft.com/download/2/C/6/2C6E1B4A-EBE5-48A6-B225-2D2058A9CEFB/Win7-KB3134760-x86.msu'
[string]$urlWin7x86checksum   =          '0486901B4FD9C41A70644E3A427FE06DD23765F1AD8B45C14BE3321203695464'
[string]$urlWin2k8R2andWin7x64 =         'https://download.microsoft.com/download/2/C/6/2C6E1B4A-EBE5-48A6-B225-2D2058A9CEFB/Win7AndW2K8R2-KB3134760-x64.msu'
[string]$urlWin2k8R2andWin7x64checksum = '077E864CC83739AC53750C97A506E1211F637C3CD6DA320C53BB01ED1EF7A98B'
[string]$urlWin2012 =                    'https://download.microsoft.com/download/2/C/6/2C6E1B4A-EBE5-48A6-B225-2D2058A9CEFB/W2K12-KB3134759-x64.msu'
[string]$urlWin2012checksum =            '6E59CEC4BD30C505F426A319673A13C4A9AA8D8FF69FD0582BFA89F522F5FF00'
[string]$ChecksumType       =            'sha256'

[string[]] $validExitCodes = @(0, 3010) # 2359302 occurs if the package is already installed

$osversionLookup = @{
"5.1.2600" = "XP";
"5.1.3790" = "2003";
"6.0.6001" = "Vista/2008";
"6.1.7600" = "Win7/2008R2";
"6.1.7601" = "Win7 SP1/2008R2 SP1"; # SP1 or later.
"6.2.9200" = "Win8/2012";
"6.3.9600" = "Win8.1/2012R2";
"10.0.*" = "Windows 10/Server 2016"
}

function Install-PowerShell5([string]$urlx86, [string]$urlx64 = $null, [string]$checksumx86 = $null,[string]$checksumx64 = $null) {
    $Net4Version = (get-itemproperty "hklm:software\microsoft\net framework setup\ndp\v4\full" -ea silentlycontinue | Select -Expand Release -ea silentlycontinue)
    if ($Net4Version -ge 378675) {
        Install-ChocolateyPackage "$packageName" "$installerType" "$silentArgs" -url $urlx86 -url64 $urlx64 -checksum $checksumx86 -ChecksumType $ChecksumType -checksum64 $checksumx64 -ChecksumType64 $ChecksumType -validExitCodes $validExitCodes
        Write-Warning "$packageName requires a reboot to complete the installation."
        #}
    }
    else {
        throw ".NET Framework 4.5.1 or later required.  Use package named `"dotnet4.5.1`"."
    }
}

try {
  # Get-CimInstance was completely crashing on win7 psh 2 even with try / catch
  $osVersion = (Get-WmiObject Win32_OperatingSystem).Version
}
catch {
    $osVersion = (Get-WmiObject Win32_OperatingSystem).Version
}

$ProductName = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'ProductName').ProductName
$EditionId = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'EditionID').EditionId

#This will show us if we are running on Nano Server (Kernel version alone won't show this)
Write-Output "Running on: $ProductName, ($EditionId), Windows Kernel: $osVersion"

If ((get-service wuauserv).starttype -ieq 'Disabled')
{
  Throw "Windows Update Service is disabled - PowerShell updates are distributed as windows updates and so require the service.  Consider temporarily enabling it before calling this package and disabling again afterward."
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
        #The following should not occur as PowerShell 5 is already installed
        if( ([version]$osVersion).Major -eq "10" ) {
            $osVersion = "$(([version]$osVersion).Major).$(([version]$osVersion).Minor).*"
        }

        Write-Output "Installing for OS: $($osversionLookup[$osVersion])"

		    switch ($osversionLookup[$osVersion]) {
            "Vista/2008" {
                Write-Warning "PowerShell 3 is the highest supported on Windows $($osversionLookup[$osVersion])."
                Write-Output "You can install PowerShell 3 using these parameters: 'PowerShell -version 3.0.20121027'"
            }
            "Win7/2008R2" {
                Write-Warning "PowerShell $ThisPackagePSHVersion Requires SP1 for Windows $($osversionLookup[$osVersion])."
                Write-Warning "Update to SP1 and re-run this package to install WMF/PowerShell 5"
                Write-Output "You can install PowerShell 3 using these parameters: 'PowerShell -version 3.0.20121027'"
            }
            "Win7 SP1/2008R2 SP1" {
                Install-PowerShell5 -urlx86 "$urlWin7x86" -checksumx86 $urlWin7x86checksum -urlx64 "$urlWin2k8R2andWin7x64" -checksumx64 $urlWin2k8R2andWin7x64checksum
            }
            "Win8/2012" {
                if($os.ProductType -gt 1) {
                    #Windows 2012
                    Install-PowerShell5 -urlx86 "$urlWin2012" -checksumx86 $urlWin2012checksum
                }
                else {
                    #Windows 8
                    Write-Verbose "Windows 8 (not 8.1) is not supported"
                    throw "$packageName not supported on Windows 8. You must upgrade to Windows 8.1 to install WMF/PowerShell 5.0."
                }
            }
            "Win8.1/2012R2" {
              Install-PowerShell5 -urlx86 "$urlWin81x86" -checksumx86 $urlWin81x86checksum -urlx64 "$urlWin2k12R2andWin81x64" -checksumx64 $urlWin2k12R2andWin81x64checksum
            }
            "Windows 10/Server 2016" {
                #Should never be reached.
                Write-Warning "Windows 10 / Server 2016 has WMF/PowerShell 5 pre-installed which is maintained by Windows Update."
            }
            default {
                # Windows XP, Windows 2003, Windows Vista, or unknown?
                throw "$packageName $ThisPackagePSHVersion is not supported on $ProductName, ($EditionId), Windows Kernel: $osVersion"
            }
	    }
    }
}
catch {
  Throw $_.Exception
}
