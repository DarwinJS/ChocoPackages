<#

  Copyright 2012-2012 Amazon.com, Inc. or its affiliates. All Rights Reserved.

    Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the License. A copy of the License is located at

          http://aws.amazon.com/apache2.0/  

    or in the "license" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.


.SYNOPSIS
Collects memory, and Pagefile utilization on an Amazon Windows EC2 instance and sends this data as custom metrics to Amazon CloudWatch.

.DESCRIPTION
This script is used to send custom metrics to Amazon Cloudwatch. This script pushes memory and page file utilization to cloudwatch. This script can be scheduled or run from a powershell prompt. 
When launched from shceduler you need to specify logfile and all messages will be logged to logfile. You can use whatif and verbose mode with this script.

.PARAMETER mem_util          
		Reports memory utilization in percentages.
.PARAMETER mem_used          
		Reports memory used (excluding cache and buffers).
.PARAMETER mem_avail          
		Reports available memory (including cache and buffers).
.PARAMETER memory_units          
		Specifies units for memory metrics.
.PARAMETER from_scheduler          
		Specifies that this script is running from Task Scheduler.
.PARAMETER aws_access_id          
		Specifies the AWS access key ID to use to identify the caller.
.PARAMETER aws_secret_key          
		Specifies the AWS secret key to use to sign the request.
.PARAMETER aws_credential_file          
		Specifies the location of the file with AWS credentials. Uses "AWS_CREDENTIAL_FILE" Env variable as default.
.PARAMETER page_used          
		Reports used page file space for all disks.
.PARAMETER page_avail          
		Reports available space in page file for all disks.
.PARAMETER page_util          
		Reports page file utilization in percentages for all disks.
.PARAMETER logfile          
		Logs all error messages to a log file. This is required when from_scheduler is set.

  
.NOTES
    PREREQUISITES:
    1) Download the SDK library from http://aws.amazon.com/sdkfornet/
    2) Obtain Secret and Access keys from https://aws-portal.amazon.com/gp/aws/developer/account/index.html?action=access-key

	API Reference:http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/query-apis.html
	

.EXAMPLE
	
    powershell.exe .\mon-put-metrics-mem.ps1 -EC2AccessKey ThisIsMyAccessKey -EC2SecretKey ThisIsMySecretKey -mem_util -mem_avail -memory_units kilobytes
.EXAMPLE	
	powershell.exe .\mon-put-metrics-mem.ps1 -aws_credential_file C:\awscreds.conf -mem_util -mem_used -mem_avail -memory_units kilobytes  -page_avail -page_used -page_util
.EXAMPLE	
	powershell.exe .\mon-put-metrics-mem.ps1 -aws_credential_file C:\awscreds.conf -mem_util -mem_used -memory_units gigabytes  -page_avail -page_util -from_scheduler -logfile C:\mylogfile.log

#>
[CmdletBinding(DefaultParametersetName="credsfromfile", supportsshouldprocess = $true) ]
param(
[switch]$mem_util,
[switch]$mem_used ,
[switch]$mem_avail, 
[switch]$page_used,
[switch]$page_avail,
[switch]$page_util,
[ValidateSet("bytes","kilobytes","megabytes","gigabytes" )]
[string]$memory_units = "none",
[switch]$from_scheduler,
[Parameter(Parametersetname ="credsinline",mandatory=$true)]
[string]$aws_access_id = "",
[Parameter(Parametersetname ="credsinline",mandatory=$true)]
[string]$aws_secret_key = "",
[Parameter(Parametersetname ="credsfromfile")]
[string]$aws_credential_file = [Environment]::GetEnvironmentVariable("AWS_CREDENTIAL_FILE"),
[string]$logfile = $null,
[Switch]$version
)



$ErrorActionPreference = 'Stop'

### Initliaze common variables ###
$accountinfo = New-Object psobject
$wc = New-Object Net.WebClient
$time = Get-Date
[string]$aaid =""
[string]$ask =""
$invoc = (Get-Variable myinvocation -Scope 0).value
$currdirectory = Split-Path $invoc.mycommand.path
$scriptname = $invoc.mycommand.Name
$ver = '1.0.0'
$client_name = 'CloudWatch-PutInstanceDataWindows'
$useragent = "$client_name/$ver"

### Logs all messages to file or prints to console based on from_scheduler setting. ###
function report_message ([string]$message)
{
	if($from_scheduler)
	{	if ($logfile.Length -eq 0 )
		{
			$logfile = $currdirectory +"\" +$scriptname.replace('.ps1','.log')
		}
		$message | Out-File -Append -FilePath $logfile
	}
	else
	{
		Write-Host $message
	}
}

### Global trap for all exceptions for this script. All exceptions will exit the script.###
trap [Exception] {
report_message ($_.Exception.Message)
Exit
}
if ($version)
{
 report_message "$scriptname version $ver"
 exit 
}
####Test and load AWS sdk 
$ProgFilesLoc = (${env:ProgramFiles(x86)}, ${env:ProgramFiles} -ne $null)[0]
$SDKLoc = "$ProgFilesLoc\AWS SDK for .NET\bin\Net35"

if ((Test-Path -PathType Container -Path $SDKLoc) -eq $false) {
    $SDKLoc = "C:\Windows\Assembly"
}

$SDKLibraryLocation = dir $SDKLoc -Recurse -Filter "AWSSDK.dll"
if ($SDKLibraryLocation -eq $null)
{
	throw "Please Install .NET sdk for this script to work."
}
else 
{
	$SDKLibraryLocation = $SDKLibraryLocation.FullName
	Add-Type -Path $SDKLibraryLocation
	Write-Verbose "Assembly Loaded"
}

### Process parameterset for credentials and adds them to a powershell object ###
switch ($PSCmdlet.Parametersetname)
{
	"credsinline" {
					Write-Verbose "Using credentials passed as arguments"
					
					if (!($aws_access_id.Length -eq 0 )) 
						{
							$aaid = $aws_access_id
						}
					else
						{
							throw ("Value of AWS access key id is not specified.")
						}
						
						if (!($aws_secret_key.Length -eq 0 ))
							{
								$ask = $aws_secret_key
							}
						else
							{
								throw "Value of AWS secret key is not specified."
							}
					}
	"credsfromfile"{
					
					if ( Test-Path $aws_credential_file)
						{
							Write-Verbose "Using AWS credentials file $aws_credential_file"
							Get-Content $aws_credential_file | ForEach-Object { 
															if($_ -match '.*=.*'){$text = $_.split("=");
															switch ($text[0].trim())
															{
																"AWSAccessKeyId" 	{$aaid= $text[1].trim()}
																"AWSSecretKey" 		{ $ask = $text[1].trim()}
															}}}
						}
						else {throw "Failed to open AWS credentials file $aws_credential_file"}
					}	
}
if (($aaid.length -eq 0) -or ($ask.length -eq 0))
{
	throw "Provided incomplete AWS credential set"
}
else 
{
	
	Add-Member -membertype noteproperty -inputobject $accountinfo -name "AWSSecretKey" -value $ask
	Add-Member -membertype noteproperty -inputobject $accountinfo -name "AWSAccessKeyId" -value $aaid 
	Remove-Variable ask; Remove-Variable aaid
}
### Check if atleast one metric is requested to report.###
if ( !$mem_avail -and !$mem_used -and !$mem_util -and !$page_avail -and !$page_used -and !$page_util)
{
	throw "Please specify a metric to report exiting script" 
}

### Avoid a storm of calls at the beginning of a minute.###
if ($from_scheduler)
{
	$rand = new-object system.random
	start-sleep -Seconds $rand.Next(20)
}

### Functions that interact with metadata to get data required for dimenstion calculation and endpoint for cloudwatch api. ###
function get-metadata {
	$extendurl = $args
	$baseurl = "http://169.254.169.254/latest/meta-data"
	$fullurl = $baseurl + $extendurl
	return ($wc.DownloadString($fullurl))
}

function get-region {
	$az = get-metadata("/placement/availability-zone")
	return ($az.Substring(0, ($az.Length -1)))
}

function get-endpoint {
	$region = get-region
	return "https://monitoring." + $region + ".amazonaws.com/"
}

### Function that creates metric data which will be added to metric list that will be finally pushed to cloudwatch. ###
function append_metric   {
	$metricdata = New-Object Amazon.Cloudwatch.Model.MetricDatum
	$metricdata.metricname, $metricdata.Unit, $metricdata.value, $metricdata.Dimensions = $args
	$metricdata.Timestamp = $time.ToUniversalTime()
	return $metricdata
}

### Function that validates units passed. Default value of  Megabytes is used###
function parse-units {
	param ([string]$mem_units,
		[long]$mem_unit_div)
	$units = New-Object psobject
	switch ($memory_units.ToLower())
					{
						"bytes" 	{ 	$mem_units = "Bytes"; $mem_unit_div = 1}
						"kilobytes" { 	$mem_units = "Kilobytes"; $mem_unit_div = 1kb}
						"megabytes" { 	$mem_units = "Megabytes"; $mem_unit_div = 1mb}
						"gigabytes" {	$mem_units = "Gigabytes"; $mem_unit_div = 1gb}
						default 	{ 	$mem_units = "Megabytes"; $mem_unit_div = 1mb}
					}
	Add-Member -InputObject $units -Name "mem_units" -MemberType NoteProperty -Value $mem_units
 	Add-Member -InputObject $units -Name "mem_unit_div" -MemberType NoteProperty -Value $mem_unit_div
	return $units
}

### Function that gets memory stats using WMI###
function get-memory {

begin {}
process {
			$mem = New-Object psobject
			$units = parse-units
 			[long]$mem_avail_wmi = (get-WmiObject Win32_OperatingSystem | select -expandproperty FreePhysicalMemory) * 1kb
 			[long]$total_phy_mem_wmi = get-WmiObject Win32_ComputerSystem |  select -expandproperty TotalPhysicalMemory
 			[long]$mem_used_wmi = $total_phy_mem_wmi - $mem_avail_wmi
 			Add-Member -InputObject $mem -Name "mem_avail_wmi" -MemberType NoteProperty -Value $mem_avail_wmi
 			Add-Member -InputObject $mem -Name "total_phy_mem_wmi" -MemberType NoteProperty -Value $total_phy_mem_wmi
 			Add-Member -InputObject $mem -Name "mem_used_wmi" -MemberType NoteProperty -Value $mem_used_wmi
 			Add-Member -InputObject $mem -Name "mem_units" -MemberType NoteProperty -Value $units.mem_units
 			Add-Member -InputObject $mem -Name "mem_unit_div" -MemberType NoteProperty -Value $units.mem_unit_div
 			write $mem
 		}
 end{}
 }

 ### Function that writes metrics to be piped to next fucntion to push to cloudwatch.###
 function create-metriclist {
  param (
  		[parameter(Valuefrompipeline=$true)] $mem_info)
 begin{
 			$dims = New-Object Amazon.Cloudwatch.Model.Dimension
			$dims.Name = "InstanceId"
			$dims.value = get-metadata("/instance-id")
			$dimlist = New-Object Collections.Generic.List[Amazon.Cloudwatch.Model.Dimension]
			$dimlist.Add($dims)
			$pagefilessize = @{}
			$pagefileusage = @{}

			gwmi Win32_PageFileSetting | ForEach-Object{$pagefilessize[$_.name]=$_.MaximumSize *1mb}
			gwmi Win32_PageFileUsage | ForEach-Object{$pagefileusage[$_.name]=$_.currentusage *1mb}
			[string[]]$pagefiles = $pagefilessize.keys

		}
 process{
 			if ($mem_util)
						{
							$percent_mem_util= 0
							if ( [long]$mem_info.total_phy_mem_wmi -gt 0 ) { $percent_mem_util = 100 * ([long]$mem_info.mem_used_wmi/[long]$mem_info.total_phy_mem_wmi)}
							write (append_metric "MemoryUtilization" "Percent"  ("{0:N2}" -f $percent_mem_util) $dimlist)
						}
			if ($mem_used)
						{
							write (append_metric "MemoryUsed" $mem_info.mem_units ("{0:N2}" -f ([long]($mem_info.mem_used_wmi/$mem_info.mem_unit_div))) $dimlist)
						}
 			if ( $mem_avail) 
						{
							write (append_metric "MemoryAvailable" $mem_info.mem_units ("{0:N2}" -f ([long]($mem_info.mem_avail_wmi/$mem_info.mem_unit_div))) $dimlist)
						}
			if ($page_avail)
				{
					for ($i=0; $i -le ($pagefiles.count - 1);$i++)
						{	
							write (append_metric ("pagefileAvailable("+$pagefiles[$i]+")") $mem_info.mem_units ("{0:N2}" -f ((($pagefilessize[$pagefiles[$i]]- ($pagefileusage[$pagefiles[$i]]))/$mem_info.mem_unit_div))) $dimlist)		
						}
				}
				if ($page_used)
				{
					for ($i = 0; $i -le ($pagefiles.count -1); $i++)
					{
						write (append_metric ("pagefileUsed("+$pagefiles[$i]+")") $mem_info.mem_units ("{0:N2}" -f (($pagefileusage[$pagefiles[$i]])/$mem_info.mem_unit_div)) $dimlist)
					}
				}
				if ($page_util)
				{
					for ($i=0; $i -le ($pagefiles.count -1);$i++)
					{
						if($pagefilessize[$pagefiles[$i]] -gt 0 )
						{
							write (append_metric ("pagefileUtilization("+$pagefiles[$i]+")") "Percent" ("{0:N2}" -f((($pagefileusage[$pagefiles[$i]])*100)/$pagefilessize[$pagefiles[$i]])) $dimlist)
						}
					}
				}
 		}
 end{}
 
 }
 ### Uses AWS sdk to push metrics to cloudwathc. This finally prints a requestid.###
 function put-instancemem {
 param (
  		[parameter(Valuefrompipeline=$true)] $metlist)
 begin{
 		$cwconfig = New-Object Amazon.CloudWatch.AmazonCloudWatchConfig
		$cwconfig.serviceURL = get-endpoint
		$cwconfig.UserAgent = $useragent
		$monputrequest  = new-object Amazon.Cloudwatch.Model.PutMetricDataRequest
		$response = New-Object psobject
		$metricdatalist = New-Object Collections.Generic.List[Amazon.Cloudwatch.Model.MetricDatum]
		
	}
 process{
 			if ($PSCmdlet.shouldprocess($metlist.metricname,"The metric data "+$metlist.value.tostring() +" "+ $metlist.unit.tostring()+" will be pushed to cloudwatch")){
			$metricdatalist.add($metlist)
			Write-Verbose ("Metricname= " +$metlist.metricname+" Metric Value= "+ $metlist.value.tostring()+" Metric Units= "+$metlist.unit.tostring())
			}
			
 		}
 end{
 		$monputrequest.namespace = "System/Windows" 
		if ($metricdatalist.count -gt 0 ) {
				$cwclient = New-Object Amazon.Cloudwatch.AmazonCloudWatchClient($accountinfo.AWSAccessKeyId,$accountinfo.AWSSecretKey,$cwconfig)
				$monputrequest.metricdata = $metricdatalist
				$monresp =  $cwclient.PutMetricData($monputrequest)
				Add-Member -Name "RequestId" -MemberType NoteProperty -Value $monresp.ResponseMetadata.RequestId -InputObject $response
				
			}
			else {throw "No metric data to push to CloudWatch exiting script" }
		Write-Verbose ("RequestID: " +  $response.RequestId)
 	}
 }
 
 ### Pipelined call of fucntions that pushs metrics to cloudwatch.
 get-memory | create-metriclist |put-instancemem
 