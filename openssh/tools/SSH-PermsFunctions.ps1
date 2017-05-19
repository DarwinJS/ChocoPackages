Try {
[void][TokenAdjuster]
} Catch {
$AdjustTokenPrivileges = @"
using System;
using System.Runtime.InteropServices;

public class TokenAdjuster
{
    [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
    internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall,
    ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr relen);
    [DllImport("kernel32.dll", ExactSpelling = true)]
    internal static extern IntPtr GetCurrentProcess();
    [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
    internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr
    phtok);
    [DllImport("advapi32.dll", SetLastError = true)]
    internal static extern bool LookupPrivilegeValue(string host, string name,
    ref long pluid);
    [StructLayout(LayoutKind.Sequential, Pack = 1)]
    internal struct TokPriv1Luid
    {
        public int Count;
        public long Luid;
        public int Attr;
    }
    internal const int SE_PRIVILEGE_DISABLED = 0x00000000;
    internal const int SE_PRIVILEGE_ENABLED = 0x00000002;
    internal const int TOKEN_QUERY = 0x00000008;
    internal const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;
    public static bool AddPrivilege(string privilege)
    {
        try
        {
            bool retVal;
            TokPriv1Luid tp;
            IntPtr hproc = GetCurrentProcess();
            IntPtr htok = IntPtr.Zero;
            retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);
            tp.Count = 1;
            tp.Luid = 0;
            tp.Attr = SE_PRIVILEGE_ENABLED;
            retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);
            retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
            return retVal;
        }
        catch (Exception ex)
        {
            throw ex;
        }
    }
    public static bool RemovePrivilege(string privilege)
        {
        try
        {
            bool retVal;
            TokPriv1Luid tp;
            IntPtr hproc = GetCurrentProcess();
            IntPtr htok = IntPtr.Zero;
            retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);
            tp.Count = 1;
            tp.Luid = 0;
            tp.Attr = SE_PRIVILEGE_DISABLED;
            retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);
            retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
            return retVal;
        }
        catch (Exception ex)
        {
            throw ex;
        }
    }
}
"@
Add-Type $AdjustTokenPrivileges
}

function Set-SecureFileACL
{
    param(
        [string]$FilePath,
        [System.Security.Principal.NTAccount]$Owner = $null
        )

    #Activate necessary admin privileges to make changes without NTFS perms
    [void][TokenAdjuster]::AddPrivilege("SeRestorePrivilege") #Necessary to set Owner Permissions
    [void][TokenAdjuster]::AddPrivilege("SeBackupPrivilege") #Necessary to bypass Traverse Checking
    [void][TokenAdjuster]::AddPrivilege("SeTakeOwnershipPrivilege") #Necessary to override FilePermissions

    $actualOwner = $null
    if($owner -eq $null)
    {
        $actualOwner = New-Object System.Security.Principal.NTAccount($($env:USERDOMAIN), $($env:USERNAME))
    }
    else
    {
        $actualOwner = New-Object System.Security.Principal.NTAccount($owner)
    }
    
    WRite-WARNING "actualOwner: $actualOwner"
    
    #$myACL = Get-ACL $FilePath
    $ExistingACL = (Get-Item $FilePath).GetAccessControl('Access')
    $objACE = New-Object System.Security.AccessControl.FileSystemAccessRule `
        ($actualOwner, "FullControl", "None", "None", "Allow")
    $ExistingACL.AddAccessRule($objACE)
    Set-Acl -Path $FilePath -AclObject $ExistingACL

    Write-Warning "Added Full Control"

    $myACL = Get-ACL -Path $FilePath
    $myACL.SetAccessRuleProtection($True, $False)
    Set-Acl -Path $FilePath -AclObject $myACL

Write-warning "removed inheritance"

    if($myACL.Access)
    {
        $myACL.Access | % {
          $IdentityToProcess = $_.IdentityReference.Value
          Try 
          {
            $result = $myACL.RemoveAccessRule($_)
          }
          Catch [System.Management.Automation.MethodInvocationException]
          {
            #Ignore "IdentityNotMappedException" for "APPLICATION PACKAGE AUTHORITY\*" identities
            If ($_.FullyQualifiedErrorId -ne 'IdentityNotMappedException')
            {
              Throw "Error trying to remove access of $IdentityToProcess"
            }
          }
          Catch 
          {
            Throw "Error trying to remove access of $IdentityToProcess"
          }
          
            <#
            if(-not ($myACL.RemoveAccessRule($_)))
            {
                throw "failed to remove access of $($_.IdentityReference.Value) rule in setup "
            }
            #>
        }
        
    }


Write-warning "removed acls"

    $myACL = Get-ACL $FilePath

    $myACL.SetOwner($actualOwner)
    
    Set-Acl -Path $FilePath -AclObject $myACL
 
    Write-Warning "Set Owner"

}

function Add-PermissionToFileACL
{
    param(
        [string]$FilePath,
        [System.Security.Principal.NTAccount] $User,
        [System.Security.AccessControl.FileSystemRights]$Perm)

    $myACL = Get-ACL $filePath
    $objACE = New-Object System.Security.AccessControl.FileSystemAccessRule `
        ($User, $perm, "None", "None", "Allow")
    $myACL.AddAccessRule($objACE)
    Set-Acl -Path $filePath -AclObject $myACL
}

