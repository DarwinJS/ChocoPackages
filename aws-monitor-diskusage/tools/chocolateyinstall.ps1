
$ErrorActionPreference = 'Stop';

$packageName= 'aws-monitor-diskusage'
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"

Start-ChocolateyProcessAsAdmin "-noprofile -file `"$toolsDir\aws-monitor-diskusage\mon-put-metrics-disk-darwinjs.ps1`" -selfschedulewiththeseparams -disk_drive all -disk_space_util -disk_space_units gigabytes" "powershell.exe"
