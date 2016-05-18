<#


  Copyright 2012-2012 Amazon.com, Inc. or its affiliates. All Rights Reserved.

    Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the License. A copy of the License is located at

          http://aws.amazon.com/apache2.0/  

    or in the "license" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.


.SYNOPSIS
Collects memory, and Pagefile utilization on an Amazon Windows EC2 instance and sends this data as custom metrics to Amazon CloudWatch.

.DESCRIPTION
Queries Amazon CloudWatch for statistics on CPU, memory, swap, and disk space utilization within a given time interval. This data is provided for the Amazon EC2 instance on which this script is executed.
  
.PARAMETER recent_hours          
		Specifies the number of recent hours to report.
.PARAMETER aws_access_id          
		Specifies the AWS access key ID to use to identify the caller.
.PARAMETER aws_secret_key          
		Specifies the AWS secret key to use to sign the request.
.PARAMETER aws_credential_file          
		Specifies the location of the file with AWS credentials.
  
.NOTES
    PREREQUISITES:
    1) Download the SDK library from http://aws.amazon.com/sdkfornet/
    2) Obtain Secret and Access keys from https://aws-portal.amazon.com/gp/aws/developer/account/index.html?action=access-key

	API Reference:http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/query-apis.html
	

.EXAMPLE
	
    powershell.exe .\mon-get-instance-stats.ps1 -EC2AccessKey ThisIsMyAccessKey -EC2SecretKey ThisIsMySecretKey -recent_hours 6
.EXAMPLE	
	powershell.exe .\mon-get-instance-stats.ps1 -aws_credential_file C:\awscreds.conf -recent_hours 6

#>

[CmdletBinding(DefaultParametersetName="credsfromfile", supportsshouldprocess = $true) ]
param(
[Parameter(mandatory = $true)]
[validaterange(1,360 )]
[int]$recent_hours,
[Parameter(Parametersetname ="credsinline",mandatory=$true)]
[string]$aws_access_id = "",
[Parameter(Parametersetname ="credsinline",mandatory=$true)]
[string]$aws_secret_key = "",
[Parameter(Parametersetname ="credsfromfile")]
[string]$aws_credential_file = [Environment]::GetEnvironmentVariable("AWS_CREDENTIAL_FILE"),
[switch]$version
)

$ErrorActionPreference = 'Stop'

### Initliaze common variables ###
$accountinfo = New-Object psobject
$wc = New-Object Net.WebClient
$time = Get-Date
[string]$aaid =""
[string]$ask =""
$invoc = (Get-Variable myinvocation -Scope 0).value
$scriptname = $invoc.mycommand.Name
$ver = '1.0.0'

$starttime = ($time.AddHours(-$recent_hours)).ToUniversalTime()
$endtime = $time.ToUniversalTime()
$period = 300

$statistics = New-Object Collections.Generic.List[String]
$statistics.add("Average")
$statistics.add("Maximum")
$statistics.add("Minimum")

### Prints messages to console. ###
function report_message ([string]$message)
{
 Write-Host $message
}

### Global trap for all excpetions for this script. All exceptions will exit the script.###
trap [Exception] 
{
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
 report_message "Assembly Loaded"
}

### Process parameterset for credentials and adds them to a powershell object ###
switch ($PSCmdlet.Parametersetname)
{
 "credsinline" 
  {
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
 "credsfromfile"
  {
   if ( Test-Path $aws_credential_file)
	{
	 Write-Verbose "Using AWS credentials file $aws_credential_file"
	 Get-Content $aws_credential_file | ForEach-Object { if($_ -match '.*=.*'){$text = $_.split("="); switch ($text[0].trim()){"AWSAccessKeyId" {$aaid= $text[1].trim()} "AWSSecretKey" { $ask = $text[1].trim()}}}}
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

### Functions that interact with metadata to get data required for dimenstion calculation and endpoint for cloudwatch api. ###
function get-metadata 
{
 $extendurl = $args
 $baseurl = "http://169.254.169.254/latest/meta-data"
 $fullurl = $baseurl + $extendurl
 return ($wc.DownloadString($fullurl))
}

function get-region 
{
 $az = get-metadata ("/placement/availability-zone")
 return ($az.Substring(0, ($az.Length -1)))
}

function get-endpoint 
{
 $region = get-region
 return "https://monitoring." + $region + ".amazonaws.com/"
}


### Function that prints values retrived from cloudwatch. It prints min max and average of each metric reported. ###
function print-metrics
{
 param([Amazon.CloudWatch.Model.Metric] $met, [string] $tittle)
 $cwconfig = New-Object Amazon.CloudWatch.AmazonCloudWatchConfig
 $cwconfig.serviceURL = get-endpoint
 $cwclient = New-Object Amazon.Cloudwatch.AmazonCloudWatchClient($accountinfo.AWSAccessKeyId,$accountinfo.AWSSecretKey,$cwconfig)
 $mongetrequest  = new-object Amazon.Cloudwatch.Model.GetMetricStatisticsRequest
 $mongetrequest.namespace = $met.namespace ; $mongetrequest.Dimensions = $met.Dimensions 
 $mongetrequest.metricname = $met.metricname ; $mongetrequest.unit = "Percent"
 $mongetrequest.starttime = $starttime ; $mongetrequest.endtime = $endtime ; $mongetrequest.period = $period
 $mongetrequest.statistics = $statistics
 $monresp =  $cwclient.GetMetricStatistics($mongetrequest)
 $response = $monresp.GetMetricStatisticsResult
 $length = $max =0; $min = 200;
 foreach ($dp in $response.datapoints)
 {
  $length++
  $avg +=$dp.average
  if ($max -le $dp.maximum)
  {
   $max = $dp.maximum
  }
  if ($min -ge $dp.minimum )
  {
   $min = $dp.minimum
  }
 }
	
	
 if ($length -gt 0)
 {
  Write-Host $tittle
  Write-Host "Average: " ("{0:N2}" -f ($avg/$length)) "% Maximum: " ("{0:N2}" -f $max) "% Minimum: "("{0:N2}" -f $min)"%" `n
 }
}

### Function that gets cpu, memory , page utilization from cloudwatch and calls print-metrics function  for printing ###
function list-metrics
{
 Write-Host "Instance Metrics for last $recent_hours hours."
 $dimlist = New-Object Collections.Generic.List[Amazon.Cloudwatch.Model.DimensionFilter]
 $dim = New-Object Amazon.CloudWatch.Model.DimensionFilter
 $dim.name = "InstanceId"
 $dim.value = get-metadata ("/instance-id")
 $dimlist.add($dim)
 $mongetrequest  = new-object Amazon.Cloudwatch.Model.GetMetricStatisticsRequest
	
 $cwconfig = New-Object Amazon.CloudWatch.AmazonCloudWatchConfig
 $cwconfig.serviceURL = get-endpoint
 $cwclient = New-Object Amazon.Cloudwatch.AmazonCloudWatchClient($accountinfo.AWSAccessKeyId,$accountinfo.AWSSecretKey,$cwconfig)
 $listreq = New-Object Amazon.CloudWatch.Model.ListMetricsRequest
 $listreq.Namespace = "AWS/EC2"
# $listreq.Dimensions = $dimlist
 $listrest =  $cwclient.ListMetrics($listreq)
 foreach ($metric in $listrest.ListMetricsResult.Metrics)
 {
  if (($metric.Dimensions[0].value -eq (get-metadata ("/instance-id"))) -and ($metric.metricname -eq "CPUUtilization"))
  {
	print-metrics $metric "CPU Utilization"
  }
 }
  $listreq.Namespace = "System/Windows"
  $listrest =  $cwclient.ListMetrics($listreq)
  foreach ($metric in $listrest.ListMetricsResult.Metrics )
  {
   if ($metric.Dimensions[0].value -eq (get-metadata ("/instance-id")))
 {
    if ($metric.metricname -eq "MemoryUtilization")
	{
	 print-metrics $metric "Memory Utilization"
	}
	if ($metric.metricname.startswith("pagefileUtilization"))
	{
	 print-metrics $metric $metric.metricname
	}
	if ($metric.metricname -eq "VolumeUtilization")
	{
	 print-metrics $metric ("Volume Utilization " +$metric.Dimensions[1].value )
	}
  }
  }
}
list-metrics