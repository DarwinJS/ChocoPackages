
$ErrorActionPreference = 'Stop';

$packageName = 'win32-openssh'
$zipName = 'ec2-api-tools.zip'

Uninstall-ChocolateyZipPackage $packageName $zipName

[Environment]::SetEnvironmentVariable('EC2_HOME',$null,'Machine')

#Using .NET method prevents expansion (and loss) of environment variables (whether the target of the removal or not)
#To avoid bad situations - does not use substring matching or regular expressions
#Removes duplicates of the target removal path, Cleans up double ";", Handles ending "\"

$PathToRemove = '%EC2_HOME%\bin'
foreach ($path in [Environment]::GetEnvironmentVariable("PATH","Machine").split(';'))
{
  If ($Path)
  {
    If (($path -ine "$PathToRemove") -AND ($path -ine "$PathToRemove\"))
    {
      [string[]]$Newpath += "$path"
    }
  }
}
$AssembledNewPath = ($newpath -join(';')).trimend(';')

[Environment]::SetEnvironmentVariable("PATH",$AssembledNewPath,"Machine")
