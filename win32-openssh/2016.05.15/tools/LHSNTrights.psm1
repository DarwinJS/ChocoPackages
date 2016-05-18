<#
    Module LHSNTrights to Get, Set, Remove NT Rights Privileges

    Run the following Command to import the Module
    Import-Module "<ModulePath>\LHSNTrights.psm1" -verbose

    Exported functions:

    Get-LHSNTRights
    Set-LHSNTRights


    AUTHOR: Pasquale Lantella 
    LASTEDIT: 6.03.2014
    KEYWORDS: NT Rights privilege, Account Rights Privilege


#Requires -Version 2.0
#>


# dot-source all function files
#Get-ChildItem -Path $psScriptRoot\*.ps1 | Foreach-Object{ . $_.FullName }




$code = @'
//
// C# Code to P-invoke LSA (local security authority) functions.
// Managed via secpol.msc normally.

using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Text;

namespace LSA
{
    //
    // Provides methods the local security authority which controls user rights. Managed via secpol.msc normally.
    //
    public class LocalSecurityAuthorityController
    {
        [DllImport("advapi32.dll", PreserveSig = true)]
        private static extern UInt32 LsaOpenPolicy(
            ref LSA_UNICODE_STRING SystemName, 
            ref LSA_OBJECT_ATTRIBUTES ObjectAttributes, 
            Int32 DesiredAccess, 
            out IntPtr PolicyHandle);

        [DllImport("advapi32.dll", SetLastError = true, PreserveSig = true)]
        private static extern uint LsaAddAccountRights(
            IntPtr PolicyHandle, 
            IntPtr AccountSid, 
            LSA_UNICODE_STRING[] UserRights, 
            int CountOfRights);

        [DllImport("advapi32.dll", SetLastError = true, PreserveSig = true)]
        private static extern uint LsaRemoveAccountRights(
            IntPtr PolicyHandle,
            IntPtr AccountSid,
            bool AllRights, // true, to remove all Rights
            LSA_UNICODE_STRING[] UserRights,
            long CountOfRights);


        [DllImport("advapi32")]
        public static extern void FreeSid(IntPtr pSid);

        [DllImport("advapi32.dll", CharSet = CharSet.Auto, SetLastError = true, PreserveSig = true)]
        private static extern bool LookupAccountName(
            string lpSystemName, 
            string lpAccountName, 
            IntPtr psid, 
            ref int cbsid, 
            StringBuilder domainName, 
            ref int cbdomainLength, 
            ref int use);

        [DllImport("advapi32.dll")]
        private static extern bool IsValidSid(IntPtr pSid);

        [DllImport("advapi32.dll")]
        private static extern int LsaClose(IntPtr ObjectHandle);

        [DllImport("kernel32.dll")]
        private static extern int GetLastError();

        [DllImport("advapi32.dll")]
        private static extern int LsaNtStatusToWinError(uint status);

        [DllImport("advapi32.dll", SetLastError = true, PreserveSig = true)]
        private static extern uint LsaEnumerateAccountRights(
            IntPtr PolicyHandle, 
            IntPtr AccountSid, 
            out IntPtr UserRightsPtr, 
            out int CountOfRights);

        [StructLayout(LayoutKind.Sequential)]
        private struct LSA_UNICODE_STRING
        {
            public UInt16 Length;
            public UInt16 MaximumLength;
            public IntPtr Buffer;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct LSA_OBJECT_ATTRIBUTES
        {
            public int Length;
            public IntPtr RootDirectory;
            public LSA_UNICODE_STRING ObjectName;
            public UInt32 Attributes;
            public IntPtr SecurityDescriptor;
            public IntPtr SecurityQualityOfService;
        }

        private static LSA_OBJECT_ATTRIBUTES CreateLSAObject()
        {
            LSA_OBJECT_ATTRIBUTES newInstance = new LSA_OBJECT_ATTRIBUTES();

            newInstance.Length = 0;
            newInstance.RootDirectory = IntPtr.Zero;
            newInstance.Attributes = 0;
            newInstance.SecurityDescriptor = IntPtr.Zero;
            newInstance.SecurityQualityOfService = IntPtr.Zero;

            return newInstance;
        }

        [Flags]
        private enum LSA_AccessPolicy : long
        {
            POLICY_VIEW_LOCAL_INFORMATION = 0x00000001L,
            POLICY_VIEW_AUDIT_INFORMATION = 0x00000002L,
            POLICY_GET_PRIVATE_INFORMATION = 0x00000004L,
            POLICY_TRUST_ADMIN = 0x00000008L,
            POLICY_CREATE_ACCOUNT = 0x00000010L,
            POLICY_CREATE_SECRET = 0x00000020L,
            POLICY_CREATE_PRIVILEGE = 0x00000040L,
            POLICY_SET_DEFAULT_QUOTA_LIMITS = 0x00000080L,
            POLICY_SET_AUDIT_REQUIREMENTS = 0x00000100L,
            POLICY_AUDIT_LOG_ADMIN = 0x00000200L,
            POLICY_SERVER_ADMIN = 0x00000400L,
            POLICY_LOOKUP_NAMES = 0x00000800L,
            POLICY_NOTIFICATION = 0x00001000L
        }

        //combine all policies
        private const int Access = (int)(
              LSA_AccessPolicy.POLICY_AUDIT_LOG_ADMIN |
              LSA_AccessPolicy.POLICY_CREATE_ACCOUNT |
              LSA_AccessPolicy.POLICY_CREATE_PRIVILEGE |
              LSA_AccessPolicy.POLICY_CREATE_SECRET |
              LSA_AccessPolicy.POLICY_GET_PRIVATE_INFORMATION |
              LSA_AccessPolicy.POLICY_LOOKUP_NAMES |
              LSA_AccessPolicy.POLICY_NOTIFICATION |
              LSA_AccessPolicy.POLICY_SERVER_ADMIN |
              LSA_AccessPolicy.POLICY_SET_AUDIT_REQUIREMENTS |
              LSA_AccessPolicy.POLICY_SET_DEFAULT_QUOTA_LIMITS |
              LSA_AccessPolicy.POLICY_TRUST_ADMIN |
              LSA_AccessPolicy.POLICY_VIEW_AUDIT_INFORMATION |
              LSA_AccessPolicy.POLICY_VIEW_LOCAL_INFORMATION
          );

        ///////////////////////////////////////////////////////////////////////////////////////////////////////
        // Returns the Local Security Authority rights granted to the account
        ///////////////////////////////////////////////////////////////////////////////////////////////////////
        public IList<string> GetRights(string ComputerName, string accountName)
        {
            IList<string> rights = new List<string>();
            string errorMessage = string.Empty;

            long winErrorCode = 0;
            string sysName = ComputerName;
            IntPtr sid = IntPtr.Zero;
            int sidSize = 0;
            StringBuilder domainName = new StringBuilder();
            int nameSize = 0;
            int accountType = 0;

            LookupAccountName(sysName, accountName, sid, ref sidSize, domainName, ref nameSize, ref accountType);

            domainName = new StringBuilder(nameSize);
            sid = Marshal.AllocHGlobal(sidSize);

            if (!LookupAccountName(sysName, accountName, sid, ref sidSize, domainName, ref nameSize, ref accountType))
            {
                winErrorCode = GetLastError();
                errorMessage = ("LookupAccountName failed: " + winErrorCode);
                throw new Win32Exception((int)winErrorCode, errorMessage);
            }
            else
            {
                LSA_UNICODE_STRING systemName = new LSA_UNICODE_STRING();
                systemName.Buffer = Marshal.StringToHGlobalUni(ComputerName);
                systemName.Length = (UInt16) (ComputerName.Length * UnicodeEncoding.CharSize);
                systemName.MaximumLength = (UInt16) ((ComputerName.Length + 1) * UnicodeEncoding.CharSize); 

                IntPtr policyHandle = IntPtr.Zero;
                IntPtr userRightsPtr = IntPtr.Zero;
                int countOfRights = 0;

                LSA_OBJECT_ATTRIBUTES objectAttributes = CreateLSAObject();

                uint policyStatus = LsaOpenPolicy(ref systemName, ref objectAttributes, Access, out policyHandle);
                winErrorCode = LsaNtStatusToWinError(policyStatus);

                if (winErrorCode != 0)
                {
                    errorMessage = string.Format("OpenPolicy failed: {0}.", winErrorCode);
                    throw new Win32Exception((int)winErrorCode, errorMessage);
                }
                else
                {
                    try
                    {
                        uint result = LsaEnumerateAccountRights(policyHandle, sid, out userRightsPtr, out countOfRights);
                        winErrorCode = LsaNtStatusToWinError(result);
                        if (winErrorCode != 0)
                        {
                            if (winErrorCode == 2)
                            {
                                return new List<string>();
                            }
                            errorMessage = string.Format("LsaEnumerateAccountRights failed: {0}", winErrorCode);
                            throw new Win32Exception((int)winErrorCode, errorMessage);
                        }

                        Int32 ptr = userRightsPtr.ToInt32();
                        LSA_UNICODE_STRING userRight;

                        for (int i = 0; i < countOfRights; i++)
                        {
                            userRight = (LSA_UNICODE_STRING)Marshal.PtrToStructure(new IntPtr(ptr), typeof(LSA_UNICODE_STRING));
                            string userRightStr = Marshal.PtrToStringAuto(userRight.Buffer);
                            rights.Add(userRightStr);
                            ptr += Marshal.SizeOf(userRight);
                        }
                    }
                    finally
                    {
                        LsaClose(policyHandle);
                    }
                }
                FreeSid(sid);
            }
            return rights;
        } // end GetRights()

        //////////////////////////////////////////////////////////////////////////////////////////////////////////
        // Adds or Removes a Privilege for an account
        //////////////////////////////////////////////////////////////////////////////////////////////////////////
        public void SetRight(string ComputerName, string accountName, string privilegeName, bool bRemove )
        {
            long winErrorCode = 0;
            string errorMessage = string.Empty;

            string sysName = ComputerName;
            IntPtr sid = IntPtr.Zero;
            int sidSize = 0;
            StringBuilder domainName = new StringBuilder();
            int nameSize = 0;
            int accountType = 0;

            LookupAccountName(sysName, accountName, sid, ref sidSize, domainName, ref nameSize, ref accountType);

            domainName = new StringBuilder(nameSize);
            sid = Marshal.AllocHGlobal(sidSize);

            if (!LookupAccountName(sysName, accountName, sid, ref sidSize, domainName, ref nameSize, ref accountType))
            {
                winErrorCode = GetLastError();
                errorMessage = string.Format("LookupAccountName failed: {0}", winErrorCode);
                throw new Win32Exception((int)winErrorCode, errorMessage);
            }
            else
            {
                LSA_UNICODE_STRING systemName = new LSA_UNICODE_STRING();
                systemName.Buffer = Marshal.StringToHGlobalUni(ComputerName);
                systemName.Length = (UInt16) (ComputerName.Length * UnicodeEncoding.CharSize);
                systemName.MaximumLength = (UInt16) ((ComputerName.Length + 1) * UnicodeEncoding.CharSize); 

                IntPtr policyHandle = IntPtr.Zero;
                LSA_OBJECT_ATTRIBUTES objectAttributes = CreateLSAObject();

                uint resultPolicy = LsaOpenPolicy(ref systemName, ref objectAttributes, Access, out policyHandle);
                winErrorCode = LsaNtStatusToWinError(resultPolicy);

                if (winErrorCode != 0)
                {
                    errorMessage = string.Format("OpenPolicy failed: {0} ", winErrorCode);
                    throw new Win32Exception((int)winErrorCode, errorMessage);
                }
                else
                {
                    try
                    {
                        LSA_UNICODE_STRING[] userRights = new LSA_UNICODE_STRING[1];
                        userRights[0] = new LSA_UNICODE_STRING();
                        userRights[0].Buffer = Marshal.StringToHGlobalUni(privilegeName);
                        userRights[0].Length = (UInt16)(privilegeName.Length * UnicodeEncoding.CharSize);
                        userRights[0].MaximumLength = (UInt16)((privilegeName.Length + 1) * UnicodeEncoding.CharSize);

                        if(bRemove)
                        {
                            // Removes a privilege from an account

                            uint res = LsaRemoveAccountRights(policyHandle, sid, false, userRights, 1);
                            winErrorCode = LsaNtStatusToWinError(res);
                            if (winErrorCode != 0)
                            {
                                errorMessage = string.Format("LsaRemoveAccountRights failed: {0}", winErrorCode);
                                throw new Win32Exception((int)winErrorCode, errorMessage);
                            }
                        }
                        else
                        {
                            // Adds a privilege to an account

                            uint res = LsaAddAccountRights(policyHandle, sid, userRights, 1);
                            winErrorCode = LsaNtStatusToWinError(res);
                            if (winErrorCode != 0)
                            {
                                errorMessage = string.Format("LsaAddAccountRights failed: {0}", winErrorCode);
                                throw new Win32Exception((int)winErrorCode, errorMessage);
                            }
                        }
                    }
                    finally
                    {
                        LsaClose(policyHandle);
                    }
                }
                FreeSid(sid);
            }
        } // end SetRight()

    } // end public class LocalSecurityAuthorityController


    /* added wrapper for PowerShell */

    public class LSAWrapper
    {
        public static IList<string> GetRights(string ComputerName, string accountName)
        {
            return new LocalSecurityAuthorityController().GetRights(ComputerName, accountName);
        }

        public static void SetRight(string ComputerName, string accountName, string privilegeName)
        {
            new LocalSecurityAuthorityController().SetRight(ComputerName, accountName, privilegeName, false);
        }

        public static void RemoveRight(string ComputerName, string accountName, string privilegeName)
        {
            new LocalSecurityAuthorityController().SetRight(ComputerName, accountName, privilegeName, true);
        }
    }
} // end namespace LSA

'@
Add-Type -TypeDefinition $code



function Get-LHSNTRights
{
<#
.SYNOPSIS
    Get Users NT-Rights(privilege) on local or remote computer

.DESCRIPTION
    Get Users NT-Rights(privilege) on local or remote computer.
    Using a custom C# LsaWrapper class. 
    Managed via secpol.msc normally.
 
.PARAMETER ComputerName
    The computer name where to Get the NT Rights for a given Account. 
    Default to local Computer

.PARAMETER $Identity
    The User/group account (domain\username or Computername\username).
    Defaults to the current Domain\User.

.EXAMPLE
    PS C:\> Get-LHSNTRights -Identity "domain\testSVC" 

    ComputerName Identity           NTRightsPrivilege        
    ------------ --------           -----------------        
    PC1          domain\testSVC     SeCreatePagefilePrivilege
    PC1          domain\testSVC     SeIncreaseQuotaPrivilege 
    PC1          domain\testSVC     SeServiceLogonRight      
    PC1          domain\testSVC     SeBatchLogonRight        

    To Get NT Rights Privilege for Account "domain\testSVC" on local Computer

.EXAMPLE
    PS C:\> Get-LHSNTRights -ComputerName Server1 -Identity "domain\testSVC" 

    ComputerName Identity           NTRightsPrivilege        
    ------------ --------           -----------------        
    Server1      domain\testSVC     SeCreatePagefilePrivilege
    Server1      domain\testSVC     SeIncreaseQuotaPrivilege 
    Server1      domain\testSVC     SeServiceLogonRight      
    Server1      domain\testSVC     SeBatchLogonRight      

    To Get NT Rights Privilege for Account "domain\testSVC" on remote Computer Server1

.INPUTS
    System.String, you can pipe input Computernames to this function.

.OUTPUTS
    Custom PSObject

.NOTES
    Possible NT-Rights:
    -------------------
    "SeBatchLogonRight", "SeDenyBatchLogonRight", 
    "SeInteractiveLogonRight", "SeDenyInteractiveLogonRight",
    "SeNetworkLogonRight", "SeDenyNetworkLogonRight", 
    "SeRemoteInteractiveLogonRight", "SeDenyRemoteInteractiveLogonRight", 
    "SeServiceLogonRight", "SeDenyServiceLogonRight"


    AUTHOR: Pasquale Lantella 
    LASTEDIT: 6.03.2014
    KEYWORDS: NT Rights privilege, Account Rights Privilege

.LINK
    Account Rights Constants
    http://msdn.microsoft.com/en-us/library/windows/desktop/bb545671%28v=vs.85%29.aspx

    Security Management Functions
    http://msdn.microsoft.com/en-us/library/windows/desktop/ms721849%28v=vs.85%29.aspx

    pinvoke.net LsaEnumerateAccountRights
    http://www.pinvoke.net/default.aspx/advapi32.LsaEnumerateAccountRights

    pinvoke.net LookupAccountName (advapi32)
    http://www.pinvoke.net/default.aspx/advapi32.LookupAccountName

#Requires -Version 2.0
#>
   
[cmdletbinding()]  

[OutputType('PSObject')]

Param(

    [Parameter(Position=0,Mandatory=$False,ValueFromPipeline=$True,
        HelpMessage='A Computer name. The default is the local computer.')]
	[alias("CN")]
    # have to be $Null for local Computer
	[string]$ComputerName = $Null,

    [Parameter(Position=1)]
    [string]$Identity = "$env:USERDOMAIN\$env:USERNAME"

   )

BEGIN {

    Set-StrictMode -Version Latest
    ${CmdletName} = $Pscmdlet.MyInvocation.MyCommand.Name

  } # end BEGIN

PROCESS {

    If ($ComputerName)
    {
        IF ( -not (Test-Connection -ComputerName $ComputerName -count 2 -quiet)) 
        {
            Write-Warning "\\$ComputerName DO NOT reply to ping"
            break; 
        }
        $Computer = $ComputerName
    }
    else
    {
        $Computer = $env:computername
    }    


    $NTrights = [LSA.LSAWrapper]::GetRights($ComputerName, $Identity)

    foreach ($right in $NTrights)
    {
        $outputObject = New-Object PSObject -Property @{
    
               ComputerName = $computer;
               Identity = $Identity
               NTRightsPrivilege = $right
    
        } | Select ComputerName, Identity, NTRightsPrivilege
    
        Write-Output $outputObject
    }   
    
} # end PROCESS

END { Write-Verbose "Function ${CmdletName} finished." }

} # end Function Get-LHSNTRights  



function Set-LHSNTRights
{
<#
.SYNOPSIS
    To Add/Remove a privilege from an account on local or remote computer.

.DESCRIPTION
    To Add/Remove a privilege from an account on local or remote computer.
    Using a custom C# LsaWrapper class.
    Managed via secpol.msc normally.

    This function will not change token privileges, only user privileges!

.PARAMETER ComputerName
    The computer name where to set the NT Rights for the given user. 
    Default to local Computer

.PARAMETER $PrivilegeName
    The NT Rights (privilege) to Add/Remove. This set is taken from
    http://msdn.microsoft.com/en-us/library/windows/desktop/bb545671%28v=vs.85%29.aspx

    Possible NT-Rights privileges:
    ------------------------------
    "SeBatchLogonRight", "SeDenyBatchLogonRight", 
    "SeInteractiveLogonRight", "SeDenyInteractiveLogonRight",
    "SeNetworkLogonRight", "SeDenyNetworkLogonRight", 
    "SeRemoteInteractiveLogonRight", "SeDenyRemoteInteractiveLogonRight", 
    "SeServiceLogonRight", "SeDenyServiceLogonRight"

.PARAMETER $Identity
    The User/group account (domain\username or Computername\username) to asign the NT Rights.
    Defaults to the current Domain\User.

.PARAMETER Remove
    Switch to remove a given NT-right privilege. 

.EXAMPLE
    Set-LHSNTRights -PrivilegeName "SeBatchLogonRight" -Identity "domain\username"

    To add the "SeBatchLogonRight" privilege for user "domain\username" on the local Computer.

.EXAMPLE
    Set-LHSNTRights -ComputerName Server1 -PrivilegeName "SeBatchLogonRight" -Identity "domain\username"

    To add the "SeBatchLogonRight" privilege for user "domain\username" on Computer 'Server1'.

.EXAMPLE
    Set-LHSNTRights -ComputerName Server1 -PrivilegeName "SeBatchLogonRight" -Identity "domain\username" -Remove

    To remove the "SeBatchLogonRight" privilege for user "domain\username" on Computer 'Server1'.

.EXAMPLE
    $Privileges = @("SeBatchLogonRight","SeServiceLogonRight","SeNetworkLogonRight")
    foreach ($priv in $Privileges)
    {
        Set-LHSNTRights -PrivilegeName $priv -Identity "domain\username"
    }

    Assigns all privileges defind in the array $Privileges to an account..    

.INPUTS
    System.String, you can pipe input Computernames to this function.

.OUTPUTS
    None.

.NOTES
    The LsaAddAccountRights function assigns one or more privileges to an account.
    If the account does not exist, LsaAddAccountRights creates it.
   
    AUTHOR: Pasquale Lantella 
    LASTEDIT: 6.03.2014
    KEYWORDS: NT Rights privilege, Account Rights Privilege

.LINK
    Account Rights Constants
    http://msdn.microsoft.com/en-us/library/windows/desktop/bb545671%28v=vs.85%29.aspx

    Security Management Functions
    http://msdn.microsoft.com/en-us/library/windows/desktop/ms721849%28v=vs.85%29.aspx

    pinvoke.net LsaEnumerateAccountRights
    http://www.pinvoke.net/default.aspx/advapi32.LsaEnumerateAccountRights

    pinvoke.net LookupAccountName (advapi32)
    http://www.pinvoke.net/default.aspx/advapi32.LookupAccountName

#Requires -Version 2.0
#>
   
[cmdletbinding()]  

[OutputType('None')]

Param(

    [Parameter(Position=0,Mandatory=$False,ValueFromPipeline=$True,
        HelpMessage='A Computer name. The default is the local computer.')]
	[alias("CN")]
    # have to be $Null for local Computer
	[string]$ComputerName = $Null,

    [Parameter(Position=1,Mandatory=$True,ValueFromPipeline=$False,HelpMessage='A NT Right to Add/Revoke.')]
    [ValidateSet(
        "SeBatchLogonRight", "SeDenyBatchLogonRight", "SeDenyInteractiveLogonRight",
        "SeDenyNetworkLogonRight", "SeDenyRemoteInteractiveLogonRight", 
        "SeDenyServiceLogonRight", "SeInteractiveLogonRight", "SeNetworkLogonRight",
        "SeRemoteInteractiveLogonRight", "SeServiceLogonRight" 
        )]
    [String]$PrivilegeName,

    [Parameter(Position=2)]
    [string]$Identity = "$env:USERDOMAIN\$env:USERNAME",

    [switch]$Remove
   )


BEGIN {

    Set-StrictMode -Version Latest
    ${CmdletName} = $Pscmdlet.MyInvocation.MyCommand.Name

} # end BEGIN

PROCESS {

    If ($ComputerName)
    {
        IF ( -not (Test-Connection -ComputerName $ComputerName -count 2 -quiet)) 
        {
            Write-Warning "\\$ComputerName DO NOT reply to ping"
            break; 
        }
    }

    if ($PSBoundParameters['Remove'])
    {
        Write-Verbose "Removing $PrivilegeName for $Identity  .." 
        [LSA.LSAWrapper]::RemoveRight($ComputerName, $Identity, $PrivilegeName )
    }
    Else
    {
        Write-Verbose "Adding $PrivilegeName for $Identity  .." 
        [LSA.LSAWrapper]::SetRight($ComputerName, $Identity, $PrivilegeName)
    }

} # end PROCESS

END { Write-Verbose "Function ${CmdletName} finished." }

} # end Function Set-LHSNTRights  



Export-ModuleMember -function Get-LHSNTRights,Set-LHSNTRights,Set-LHSTokenPrivilege -Variable external