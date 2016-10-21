
#Docker file for installing SSH on Nano

FROM microsoft/nanoserver:latest

RUN powershell Install-PackageProvider NuGet -forcebootstrap -force
RUN powershell Register-PackageSource -name chocolatey -provider nuget -location http://chocolatey.org/api/v2/ -trusted
RUN powershell Install-Package openssh -provider NuGet
RUN powershell cd "$((dir "$env:ProgramFiles\nuget\packages\openssh*\tools" |select -last 1).fullname)" ; . ".\barebonesinstaller.ps1" -SSHServerFeature

EXPOSE 22/tcp
