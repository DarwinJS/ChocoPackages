
#Install Chocolatey and Nexus Repository With a Oneliner:

Paste the following ONE LINE command into an elevated powershell prompt:

```
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {[bool]1};set-executionpolicy RemoteSigned -Force -EA 'SilentlyContinue';iex ((new-object net.webclient).DownloadString('https://raw.githubusercontent.com/DarwinJS/ChocoPackages/master/nexus-repository/InstallChoco_and_nexus-repository.ps1'))
```
