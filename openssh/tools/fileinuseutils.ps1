

Add-Type @'
    using System;
    using System.Text;
    using System.Runtime.InteropServices;

    public class LockedFileUtils
    {
      public enum MoveFileFlags
      {
          MOVEFILE_REPLACE_EXISTING           = 0x00000001,
          MOVEFILE_COPY_ALLOWED               = 0x00000002,
          MOVEFILE_DELAY_UNTIL_REBOOT         = 0x00000004,
          MOVEFILE_WRITE_THROUGH              = 0x00000008,
          MOVEFILE_CREATE_HARDLINK            = 0x00000010,
          MOVEFILE_FAIL_IF_NOT_TRACKABLE      = 0x00000020
      }

        [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        static extern bool MoveFileEx(string lpExistingFileName, string lpNewFileName, MoveFileFlags dwFlags);

        public static bool DeleteLockedFile (string sourcefile)
        {
            return MoveFileEx(sourcefile, null, MoveFileFlags.MOVEFILE_DELAY_UNTIL_REBOOT);
        }
        public static bool CopyLockedFile (string sourcefile, string destination)
        {
            return MoveFileEx(sourcefile, destination, MoveFileFlags.MOVEFILE_DELAY_UNTIL_REBOOT);
        }
    }
'@

Function Remove-FileEvenIfLocked
{
  param ([parameter(mandatory=$true,ValueFromPipeline=$true)][string]$Path)
  Process
  {
    $path = (Resolve-Path $path -ErrorAction Stop).Path

    try
    {
      Remove-Item $path -ErrorAction Stop
    }
    catch [System.IO.IOException]
    {
      If ($_.exception -ilike "*used by another process*")
      {
        Write-host "$path is locked by another process, attempting to setup removal at reboot..."
        $deleteResult = [LockedFileUtils]::DeleteLockedFile($path)
        if ($deleteResult -eq $false)
        {
          throw "Was not able to remove in use file $path `r`n $(New-Object System.ComponentModel.Win32Exception)"
        }
        else
        {
          write-host "(File locked.  Deleting $path at next reboot.  Reboot is required to complete operation.)"
        }
      }
    }
  }
}

Function Copy-FileEvenIfLocked
{
  param ([parameter(mandatory=$true,ValueFromPipeline=$true)][string]$Path,
         [parameter(mandatory=$true,ValueFromPipeline=$true)][string]$Destination)
  Process
  {
    $Path = (Resolve-Path $path -ErrorAction Stop).Path
    Write-output "`$path is now $path"
    If (Test-Path $Destination)
    {
      $Destination = (Resolve-Path $Destination -ErrorAction Stop).Path
    }
    Write-output "`$Destination is now $Destination"

    try
    {
      Copy-Item $Path $Destination -ErrorAction Stop
      Return "RebootNotRequired"
    }
    catch [System.IO.IOException]
    {
      If ($_.exception -ilike "*used by another process*")
      {
        Write-host "$path is locked by another process, attempting to setup copy at reboot..."
        $deleteResult = [LockedFileUtils]::CopyLockedFile($path,$Destination)
        if ($deleteResult -eq $false)
        {
          throw "Was not able to copy in use file $path to $destination `r`n $(New-Object System.ComponentModel.Win32Exception)"
        }
        else
        {
          write-host "Destination file is locked.  Copying $path to $Destination at next reboot.  Reboot is required to complete operation.)"
          Return "RebootRequired"
        }
      }
    }
  }
}
