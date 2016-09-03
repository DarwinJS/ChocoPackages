﻿param($accountToAdd)
#written by Ingo Karstein, http://blog.karstein-consulting.com
#  v1.0, 01/03/2014

## <--- Configure here

if( [string]::IsNullOrEmpty($accountToAdd) ) {
	Write-Host "no account specified"
	exit
}

## ---> End of Config

$sidstr = $null
try {
	$ntprincipal = new-object System.Security.Principal.NTAccount "$accountToAdd"
	$sid = $ntprincipal.Translate([System.Security.Principal.SecurityIdentifier])
	$sidstr = $sid.Value.ToString()
} catch {
	$sidstr = $null
}

Write-Host "Account: $($accountToAdd)" -ForegroundColor DarkCyan

if( [string]::IsNullOrEmpty($sidstr) ) {
	Write-Host "Account not found!" -ForegroundColor Red
	exit -1
}

Write-Host "Account SID: $($sidstr)" -ForegroundColor DarkCyan

$tmp = [System.IO.Path]::GetTempFileName()

Write-Host "Export current Local Security Policy" -ForegroundColor DarkCyan
secedit.exe /export /cfg "$($tmp)"

$c = Get-Content -Path $tmp

$currentSetting = ""

foreach($s in $c) {
	if( $s -like "SeServiceLogonRight*") {
		$x = $s.split("=",[System.StringSplitOptions]::RemoveEmptyEntries)
		$currentSetting = $x[1].Trim()
	}
}

if( $currentSetting -notlike "*$($sidstr)*" ) {
	Write-Host "Modify Setting ""Logon as a Service""" -ForegroundColor DarkCyan

	if( [string]::IsNullOrEmpty($currentSetting) ) {
		$currentSetting = "*$($sidstr)"
	} else {
		$currentSetting = "*$($sidstr),$($currentSetting)"
	}

	Write-Host "$currentSetting"

	$outfile = @"
[Unicode]
Unicode=yes
[Version]
signature="`$CHICAGO`$"
Revision=1
[Privilege Rights]
SeServiceLogonRight = $($currentSetting)
"@

	$tmp2 = [System.IO.Path]::GetTempFileName()


	Write-Host "Import new settings to Local Security Policy" -ForegroundColor DarkCyan
	$outfile | Set-Content -Path $tmp2 -Encoding Unicode -Force

	#notepad.exe $tmp2
	Push-Location (Split-Path $tmp2)

	try {
		secedit.exe /configure /db "secedit.sdb" /cfg "$($tmp2)" /areas USER_RIGHTS
		#write-host "secedit.exe /configure /db ""secedit.sdb"" /cfg ""$($tmp2)"" /areas USER_RIGHTS "
	} finally {
		Pop-Location
	}
} else {
	Write-Host "NO ACTIONS REQUIRED! Account already in ""Logon as a Service""" -ForegroundColor DarkCyan
}

Write-Host "Done." -ForegroundColor DarkCyan
