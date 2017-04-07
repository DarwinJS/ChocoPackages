
Write-Host "`r`n*****************************************"
Write-Host "https://CloudyWindows.com SSH Utility Script - Set-SSHKeyPermissions.ps1"
Write-Host "Run 'Set-SSHKeyPermissions' at a PowerShell Prompt each time you add an authorized_keys file"
Write-Host "or set it up in the task scheduler."
Write-Host "Searching for and granting read permissions to SSHD Service for all user authorized_keys files..."
$UsersFolder = split-path -parent $env:public
$AuthorizedKeyFileList = @(Get-ChildItem "$UsersFolder\*\.ssh\authorized_keys")

If (![bool](Get-Service SSHD -ErrorAction SilentlyContinue))
{
  Throw "The SSHD service must exist in order to grant permissions to the virtual user `"NT Service\SSHD`""
}

If ($AuthorizedKeyFileList.count -gt 0)
{
  ForEach ($AuthorizedKeyFile in $AuthorizedKeyFileList)
  {
    $authorizedKeyPath = $AuthorizedKeyFile.FullName
    Write-Host "    Giving read permissions to `"NT Service\SSHD`" for `"$authorizedKeyPath`""
    $ACL = get-acl $authorizedKeyPath
    $NewAccessRule = New-Object  System.Security.AccessControl.FileSystemAccessRule("NT Service\sshd", "Read", "Allow")
    $ACL.SetAccessRule($NewAccessRule)
    Set-Acl  $authorizedKeyPath $acl
  }
}
Else
{
    Write-Host "No authorized_keys files were found."
}

Write-Host "*****************************************`r`n"