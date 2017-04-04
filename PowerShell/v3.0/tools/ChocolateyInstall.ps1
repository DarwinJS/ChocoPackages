try
{
  [string] $packageName="PowerShell 3.0"
  [string] $fileType="exe"
  [string] $silentArgs="/quiet /norestart /log:`"$env:TEMP\PowerShell.v3.Install.log`""
  [string] $url = "http://download.microsoft.com/download/E/7/6/E76850B8-DA6E-4FF5-8CCE-A24FC513FD16/Windows6.1-KB2506143-x86.msu"
  [string] $url64bit = "http://download.microsoft.com/download/E/7/6/E76850B8-DA6E-4FF5-8CCE-A24FC513FD16/Windows6.1-KB2506143-x64.msu"
  [string[]] $validExitCodes = @(0, 3010) # 2359302 occurs if the package is already installed.
  [string] $wusaExe="wusa.exe"

  if ($PSVersionTable -and ($PSVersionTable.PSVersion -ge [Version]'3.0'))
  {
    Write-ChocolateySuccess "$packageName already installed on your OS"
    return
  }

  $osVersion = [Environment]::OSVersion.Version
  if ($osVersion -lt [Version]'6.0')
  {
    Write-ChocolateyFailure $packageName "$packageName not supported on your OS"
    return
  }
  elseif ($osVersion -lt [Version]'6.1')
  {
    $url = 'http://download.microsoft.com/download/E/7/6/E76850B8-DA6E-4FF5-8CCE-A24FC513FD16/Windows6.0-KB2506146-x86.msu'
    $url64bit = 'http://download.microsoft.com/download/E/7/6/E76850B8-DA6E-4FF5-8CCE-A24FC513FD16/Windows6.0-KB2506146-x64.msu'
  }

  $chocTempDir = Join-Path $env:TEMP "chocolatey"
  $tempDir = Join-Path $chocTempDir "$packageName(RTM)"
  if (![System.IO.Directory]::Exists($tempDir))
  {
      [System.IO.Directory]::CreateDirectory($tempDir)
  }

  $file = Join-Path $tempDir "$($packageName) Install.$fileType"

  if(!(test-path $file))
  {
      Get-ChocolateyWebFile $packageName $file $url $url64bit
  }

  $silentArgs="`"$file`" $silentArgs"

  Install-ChocolateyInstallPackage $packageName $fileType $silentArgs $wusaExe -validExitCodes $validExitCodes

  Write-Warning "$packageName requires a reboot to complete the installation."

  Write-ChocolateySuccess $packageName
}
catch
{
  Write-ChocolateyFailure $packageName $($_.Exception.Message)
}


