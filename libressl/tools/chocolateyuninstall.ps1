$ErrorActionPreference = 'Stop'; 

$packageName   = 'libressl'
$toolsDir      = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$FileFullPath = Join-Path $toolsDir 'libressl-2.5.3-windows.zip'

If (Test-Path "$env:ProgramFiles\LibreSSL")
{
$DefaultInstallDir = "$env:ProgramFiles\LibreSSL"
}

If (Test-Path "$env:ProgramData\LibreSSL")
{
$DefaultInstallDir = "$env:ProgramData\LibreSSL"
}

If (("$DefaultInstallDir") -AND (Test-Path "$DefaultInstallDir"))
{
  Write-Host "Found $packagename in default program files folder `"$DefaultInstallDir`", uninstalling..."
  Remove-Item "$DefaultInstallDir" -recurse -force

  Function Ensure-RemovedFromPath ($PathToRemove,$Scope,$PathVariable)
  {
    If (!$Scope) {$Scope='Machine'}
    If (!$PathVariable) {$PathVariable='PATH'}
    $ExistingPathArray = @([Environment]::GetEnvironmentVariable("$PathVariable","$Scope").split(';'))
    write-host "Ensuring `"$PathToRemove`" is removed from variable `"$PathVariable`" for scope `"$scope`" "
    if (($ExistingPathArray -icontains $PathToRemove) -OR ($ExistingPathArray -icontains "$PathToRemove\"))
    {
      foreach ($path in $ExistingPathArray)
      {
        If ($Path)
        {
          If (($path -ine "$PathToRemove") -AND ($path -ine "$PathToRemove\"))
          {
            [string[]]$Newpath += "$path"
          }
        }
      }
      $AssembledNewPath = ($Newpath -join(';')).trimend(';')
      [Environment]::SetEnvironmentVariable("$PathVariable",$AssembledNewPath,"$Scope")
    }
  }

  Ensure-RemovedFromPath "$DefaultInstallDir" 'Machine'
}