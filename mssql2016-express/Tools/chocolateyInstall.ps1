
$packageID = 'mssql2016-express'
$url = 'https://download.microsoft.com/download/9/A/E/9AE09369-C53D-4FB7-985B-5CF0D547AE9F/SQLServer2016-SSEI-Expr.exe'
$checksum = '80D30768BC47A4771555E892B4C9FB1855F6A707'
$checksumtype = 'sha1'
$url64 = 'https://download.microsoft.com/download/9/A/E/9AE09369-C53D-4FB7-985B-5CF0D547AE9F/SQLServer2016-SSEI-Expr.exe'
$checksum64 = 'B15155AC621C50F1A84BA4924F46828D4F562CD9'
$checksumtype64 = 'sha1'
$validExitCodes = @(0,3010)

$adminsGroupName = (New-Object Security.Principal.SecurityIdentifier 'S-1-5-32-544').Translate([Security.Principal.NTAccount]).Value

$SQL_WhatIf = $False
$SQL_QuietSwitch = "Q"
$SQL_InstanceName = 'SQLEXPRESS'
$SQL_Features = 'SQLENGINE,FULLTEXT,CONN,IS,BC,SDK,SSMS,ADV_SSMS'
$SQL_SecurityMode = $null
$SQL_SAPwd = 'ComplexEnough2Count!' #Password must meet operating system configured complexity requirements or install will fail.
$SQL_BROWSERSVCSTARTUPTYPE = 'Automatic'
$SQL_SQLSVCSTARTUPTYPE = 'Automatic'

$arguments = @{};
$packageParameters = $env:chocolateyPackageParameters;

# Now parse the packageParameters using good old regular expression
if ($packageParameters) {
    $match_pattern = "\/(?<option>([a-zA-Z_]+)):(?<value>([`"'])?([a-zA-Z0-9- _\\:\.!]+)([`"'])?)|\/(?<option>([a-zA-Z]+))"
    #"
    $option_name = 'option'
    $value_name = 'value'

    if ($packageParameters -match $match_pattern ){
        $results = $packageParameters | Select-String $match_pattern -AllMatches
        $results.matches | % {
          $arguments.Add(
              $_.Groups[$option_name].Value.Trim(),
              $_.Groups[$value_name].Value.Trim())
      }
    }
    else
    {
      throw "Package Parameters were found but were invalid (REGEX Failure)"
    }

    if ($arguments.ContainsKey("SQL_WhatIf")) {
        $SQL_WhatIf = $True
        "Found SQL_WhatIf"
    }
    if ($arguments.ContainsKey("SQL_QuietSwitch")) {
        $SQL_QuietSwitch = $arguments.Get_Item("SQL_QuietSwitch")
    }
    if ($arguments.ContainsKey("SQL_SecurityMode")) {
        $SQL_SecurityMode = $arguments.Get_Item("SQL_SecurityMode")
    }
    if ($arguments.ContainsKey("SQL_SAPwd")) {
        $SQL_SAPwd = $arguments.Get_Item("SQL_SAPwd")
    }
    if ($arguments.ContainsKey("SQL_Features")) {
        $SQL_Features = $arguments.Get_Item("SQL_Features")
    }
    if ($arguments.ContainsKey("SQL_InstanceName")) {
        $SQL_InstanceName = $arguments.Get_Item("SQL_InstanceName")
    }
    if ($arguments.ContainsKey("SQL_BROWSERSVCSTARTUPTYPE")) {
        $SQL_BROWSERSVCSTARTUPTYPE = $arguments.Get_Item("SQL_BROWSERSVCSTARTUPTYPE")
    }
    if ($arguments.ContainsKey("SQL_BROWSERSVCSTARTUPTYPE")) {
        $SQL_BROWSERSVCSTARTUPTYPE = $arguments.Get_Item("SQL_BROWSERSVCSTARTUPTYPE")
    }
    if ($arguments.ContainsKey("SQL_SQLSVCSTARTUPTYPE")) {
        $SQL_SQLSVCSTARTUPTYPE = $arguments.Get_Item("SQL_SQLSVCSTARTUPTYPE")
    }

    if ($arguments.ContainsKey("OverrideSQLCMDLineFile")) {
        $SQLSetupParameters = Get-content $($arguments.Get_Item("OverrideSQLCMDLineFile"))
        $FullSQLCommandOverride = $True
        Write-Output "A full override of the SQL command has been configured - all other arguments will be ignored and we will use:"
        Write-Output "$SQLSetupParameters"
    }
} else {
    Write-Debug "No Package Parameters Passed in";
}

If (!$FullSQLCommandOverride)
{
  $SQLSetupParameters = "/ACTION=Install /$($SQL_QuietSwitch) /INDICATEPROGRESS /IACCEPTSQLSERVERLICENSETERMS /FEATURES=$SQL_Features /TCPENABLED=1 /INSTANCENAME=$SQL_InstanceName /BROWSERSVCSTARTUPTYPE=$SQL_BROWSERSVCSTARTUPTYPE /SQLSVCSTARTUPTYPE=$SQL_SQLSVCSTARTUPTYPE /SQLSVCACCOUNT=`"NT AUTHORITY\Network Service`" /SQLSYSADMINACCOUNTS=`"$adminsGroupName`" /AGTSVCACCOUNT=`"NT AUTHORITY\Network Service`""
  If ($SQL_SecurityMode -ieq 'SQL')
  {
    If (!$SQL_SAPwd)
    {
      Throw 'You must specify SQL_SAPwd if SQL_SecurityMode is set to "SQL"'
    }
    Else
    {
      $SQLSetupParameters += " /SECURITYMODE=$SQL_SecurityMode /SAPWD=`"$SQL_SAPwd`""
    }
  }
}

Write-Output "********************************************************"
Write-Output "$SQLSetupParameters"
Write-Output "********************************************************"

If ($SQL_WhatIf)
{
  Write-Warning "/SQL_Whatif was used, not running the install command.  Use '-Force' to keep running command line tests."
}
Else
{
  Install-ChocolateyPackage $packageID 'exe' $SQLSetupParameters -validExitCodes $validExitCodes -url $url -checksum $checksum -checksumtype $checksumtype -url64 $url64 -checksum64 $checksum64 -checksumtype64 $checksumtype64
}

Write-Warning "SA password is `"$SQL_SAPwd`""
Write-Warning "SQL Server Install Always Requires a Restart Before Setup Will Be Complete"
