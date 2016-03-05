
#Moderator: what is the proper way to install 32 or 64 bit - whatever is currently installed?

If ((gwmi win32_processor).Addresswidth -eq 64)
  {
  Uninstall-ChocolateyZipPackage spystudio SpyStudio-v2-x64.zip
  }
Else
  {
  Uninstall-ChocolateyZipPackage spystudio SpyStudio-v2.zip
  }