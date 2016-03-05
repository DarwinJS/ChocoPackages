$packageName = 'NektraSpyStudio' # arbitrary name for the package, used in messages
$url = 'http://www.nektra.com/files/SpyStudio/SpyStudio-v2.zip' # download url
$additionalurlfor64 = 'http://www.nektra.com/files/SpyStudio/SpyStudio-v2-x64.zip' # 64bit URL here or remove - if installer decides, then use $url
$silentArgs = 'SILENT_ARGS_HERE' # "/s /S /q /Q /quiet /silent /SILENT /VERYSILENT" # try any of these to get the silent installer #msi is always /quiet
$validExitCodes = @(0) #please insert other valid exit codes here, exit codes for ms http://msdn.microsoft.com/en-us/library/aa368542(VS.85).aspx

#Install-ChocolateyPackage "$packageName" "$installerType" "$silentArgs" "$url" "$url64"  -validExitCodes $validExitCodes

If ((Test-Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5") -AND -NOT ((get-itemproperty "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5").sp -ge 1))
  {
  Throw "Spy Studio requires .NET 3.5.1 or later.  You must either: [a] manually install it after verifing it will not cause problems on this system, or [b] use procmon for your trace and analyze it using Spy Studio installed on another system that has .NET 3.5.1 or later."
  }

Install-ChocolateyZipPackage "$packageName" "$url" "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"

Write-Output "***************************************************************************"
Write-Output "*  INSTRUCTIONS: Type `"spystudio.exe`" to start SpyStudio.               *"
Write-Output "*       More Info: http://www.nektra.com/products/spystudio-api-monitor   *"
Write-Output "***************************************************************************"
