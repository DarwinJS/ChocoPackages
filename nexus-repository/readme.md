
#Install Chocolatey and Nexus Repository With a Oneliner:

Paste one of the following ONE LINE command into an elevated powershell prompt:

#Recent OS / PowerShell (e.g. Server 2012 R2)
```
If (!(Test-Path env:chocolateyinstall)) {iwr https://chocolatey.org/install.ps1 -UseBasicParsing | iex} ; cinst -y nexus-repository
```

#Older OS / PowerShell (e.g. Server 2008 R2)
```
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {[bool]1};set-executionpolicy RemoteSigned -Force -EA 'SilentlyContinue';iex ((new-object net.webclient).DownloadString('https://raw.githubusercontent.com/DarwinJS/ChocoPackages/master/nexus-repository/InstallChoco_and_nexus-repository.ps1'))
```
