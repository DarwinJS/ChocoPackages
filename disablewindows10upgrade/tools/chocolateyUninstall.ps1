
$REGKey1 = 'Registry::HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
If (!(Test-Path $REGKey1)) {New-Item "$REGKey1" | Out-Null}
Set-ItemProperty -Path $REGKey1 -Name "DisableOSUpgrade" -Type DWord -Value 0

$REGKey2 = 'Registry::HKLM\Software\Policies\Microsoft\Windows\Gwx'
If (!(Test-Path $REGKey2)) {New-Item "$REGKey2" | Out-Null}
Set-ItemProperty -Path $REGKey2 -Name "DisableGwx" -Type DWord -Value 0

Write-Warning 'Windows 10 upgrade through Windodws Update is now re-enabled.'
