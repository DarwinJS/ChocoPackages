
#Docker file for installing SSH

#Adjust line following comments to select desired edition of Server 2016
FROM microsoft/windowsservercore:latest
#FROM microsoft/nanoserver:latest

RUN powershell Install-PackageProvider NuGet -forcebootstrap -force
RUN powershell Register-PackageSource -name chocolatey -provider nuget -location http://chocolatey.org/api/v2/ -trusted
RUN powershell Install-Package openssh -provider NuGet
RUN powershell cd ("$env:ProgramFiles\nuget\packages\openssh." + "$((dir "$env:ProgramFiles\nuget\packages\openssh*" | %{[version]$_.name.trimstart('openssh.')} | sort | select -last 1) -join '.')\tools") ; . ".\barebonesinstaller.ps1" -SSHServerFeature

EXPOSE 22/tcp

#docker build . -t yourdockerid/nanoserverwithssh
#docker run -d -p 127.0.0.1:22:5000 --name nanowithsshd -t yourdockerid/nanoserverwithssh
