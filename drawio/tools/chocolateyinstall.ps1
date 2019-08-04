$ErrorActionPreference = 'Stop';
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url        = 'https://github.com/jgraph/drawio-desktop/releases/download/v9.3.1/draw.io-setup-signed-9.3.1.exe'

$packageArgs = @{
  packageName   = $env:ChocolateyPackageName
  unzipLocation = $toolsDir
  fileType      = 'EXE'
  file          = "$toolsDir/draw.io-11.1.1-windows-installer.exe"
  softwareName  = 'drawio*'
  checksum      = 'F6B701DA4FE1E6D9C64FC9DD48D7D114188FCC700D5B7DAE8C031E1D896156AC'
  checksumType  = 'sha256'
  silentArgs   = '/S'
}

If ([bool](get-command Get-ChecksumValid -ea silentlycontinue))
{
  Get-ChecksumValid -File $($packageArgs.file) -checksumType $($packageArgs.checksumType) -checksum $($packageArgs.checksum)
}

Install-ChocolateyInstallPackage @packageArgs

#Create .ignore files so chocolatey does not shim the Exe
$files = get-childitem $toolsDir -include *.exe -recurse
foreach ($file in $files) {
  New-Item "$file.ignore" -type file -force | Out-Null
}