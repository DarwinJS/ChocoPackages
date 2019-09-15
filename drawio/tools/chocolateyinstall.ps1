$ErrorActionPreference = 'Stop';
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url        = 'https://github.com/jgraph/drawio-desktop/releases/download/v11.1.4/draw.io-11.1.4-windows-installer.exe'

$packageArgs = @{
  packageName   = $env:ChocolateyPackageName
  unzipLocation = $toolsDir
  fileType      = 'EXE'
  #file          = "$toolsDir/draw.io-11.1.4-windows-installer.exe"
  url           = $url
  softwareName  = 'drawio*'
  checksum      = '65E8E9D0C7BDE7BCBEAB95F953D5E05807D43422357199B94CF70D0BB299D8EE'
  checksumType  = 'sha256'
  silentArgs   = '/S'
}

#If ([bool](get-command Get-ChecksumValid -ea silentlycontinue))
#{
#  Get-ChecksumValid -File $($packageArgs.file) -checksumType $($packageArgs.checksumType) -checksum $($packageArgs.checksum)
#}

Install-ChocolateyPackage @packageArgs

#Create .ignore files so chocolatey does not shim the Exe
$files = get-childitem $toolsDir -include *.exe -recurse
foreach ($file in $files) {
  New-Item "$file.ignore" -type file -force | Out-Null
}