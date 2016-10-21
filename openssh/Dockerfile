
#Docker file for installing SSH on Nano

FROM microsoft/nanoserver:latest

RUN powershell Install-PackageProvider NuGet -forcebootstrap -force
RUN powershell Register-PackageSource -name chocolatey -provider nuget -location http://chocolatey.org/api/v2/ -trusted
RUN powershell Install-Package openssh -provider NuGet
RUN powershell cd "$((dir "$env:ProgramFiles\nuget\packages\openssh*\tools" |select -last 1).fullname)" ; . ".\barebonesinstaller.ps1" -SSHServerFeature

EXPOSE 22/tcp

#docker build . -t darwinjs/nanoserverwithssh
#docker run -d -p 127.0.0.1:22:5000 --name nanowithsshd -t darwinjs/nanoserverwithssh
