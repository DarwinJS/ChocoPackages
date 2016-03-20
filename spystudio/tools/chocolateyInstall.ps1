
$ErrorActionPreference = 'Stop';
$packageName = 'SpyStudio'
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"

$packageArgs = @{
  packageName   = $packageName
  unzipLocation = $toolsDir
  url           = 'http://www.nektra.com/files/SpyStudio/SpyStudio-v2.zip'
  url64         = 'http://www.nektra.com/files/SpyStudio/SpyStudio-v2-x64.zip'
  validExitCodes= @(0, 3010, 1641)
}

#Find whether there is a qualifying version of .NET installed
If (((Test-Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5") -AND (!((get-itemproperty "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5").sp -ge 1))) -OR (![bool]((gci 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP') | select-string -pattern @('v4','v4.0') -simplematch)))
  {
  Throw "Spy Studio requires .NET 3.5.1 or later.  You must either: [a] manually install a qualifying version of .NET after verifing it will not cause problems on this system, or [b] use procmon for your trace and analyze it using Spy Studio installed on another system that has .NET 3.5.1 or later.  FYI: You can install it using the package 'dotnet3.5'"
  }

Install-ChocolateyZipPackage @packageArgs

Write-Output "***************************************************************************"
Write-Output "*  INSTRUCTIONS: Type `"spystudio.exe`" to start SpyStudio.               *"
Write-Output "*       More Info: http://www.nektra.com/products/spystudio-api-monitor   *"
Write-Output "***************************************************************************"
