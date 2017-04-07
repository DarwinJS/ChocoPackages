
# Chocolatey openssh Package Approach to **UPGRADING** ssh-lsa.dll

The openssh chocolatey package takes the approach of assuming that ssh-lsa.dll is the same unless the file SIZE changes.

This is due to the following set of reasons:
1. Due to the early startup of lsass.exe it takes at least TWO reboots to upgrade the file (windows normal rename on reboot does not work with how early lsass.exe starts)
2. The version number is kept in sync with the overall product, regardless of whether the file has any code changes.

Two reboots is fine if you have one experimental machine where you manually install - however, if you have a large set of machines that you are keeping up to date, it is a significant effort to perform when the underlying code has not actually changed.

# History Of ssh-lsa.dll file changes

A size change seems to indicate an actual code change of the DLL - version numbers do not.

   SSH Version     Dll Version     DLL Size
    v0.0.9.0        0.0.0.9         84,992
    v0.0.1.0        0.0.1.0         84,992
    v0.0.2.0        0.0.2.0         84,992
    v0.0.3.0        0.0.3.0         90,624
    v0.0.4.0        0.0.4.0         84,992
    v0.0.5.0        0.0.5.0         90,624
    v0.0.6.0        0.0.6.0         84,992
    v0.0.7.0        0.0.7.0         90,624
    v0.0.8.0        0.0.8.0         90,624
    v0.0.9.0        0.0.9.0         84,992
    v0.0.10.0       0.0.10.0        84,992
    v0.0.11.0       0.0.11.0        84,992
