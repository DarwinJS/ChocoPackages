<#

  Copyright 2012-2012 Amazon.com, Inc. or its affiliates. All Rights Reserved.

    Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the License. A copy of the License is located at

          http://aws.amazon.com/apache2.0/  

    or in the "license" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

.SYNOPSIS
This script pushes perfmon counters to cloudwatch 

.DESCRIPTION
This script is used to send custom metrics to Amazon Cloudwatch. This script shows a way to push perfmon coutners to cloudwatch. You can select preset counters are add your own counters.This script can be scheduled or run from a powershell prompt. 
When launched from shceduler you need to specify logfile and all messages will be logged to logfile. You can use whatif and verbose mode with this script.

.PARAMETER processor_queue          
		Reports current processor queue counter.
.PARAMETER pages_input          
		Reports memory pages/input memory counter.
.PARAMETER from_scheduler          
		Specifies that this script is running from Task Scheduler.
.PARAMETER aws_access_id          
		Specifies the AWS access key ID to use to identify the caller.
.PARAMETER aws_secret_key          
		Specifies the AWS secret key to use to sign the request.
.PARAMETER aws_credential_file          
		Specifies the location of the file with AWS credentials. Uses "AWS_CREDENTIAL_FILE" Env variable as default.
.PARAMETER logfile          
		Logs all error messages to a log file. This is required when from_scheduler is set.

  
.NOTES
    PREREQUISITES:
    1) Download the SDK library from http://aws.amazon.com/sdkfornet/
    2) Obtain Secret and Access keys from https://aws-portal.amazon.com/gp/aws/developer/account/index.html?action=access-key

	API Reference:http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/query-apis.html
	

.EXAMPLE
	
    powershell.exe .\mon-put-metrics-perfmon.ps1 -EC2AccessKey ThisIsMyAccessKey -EC2SecretKey ThisIsMySecretKey -pages_input
.EXAMPLE	
	powershell.exe .\mon-put-metrics-perfmon.ps1  -pages_input -processor_queue 
.EXAMPLE	
	powershell.exe .\mon-put-metrics-perfmon.ps1 -aws_credential_file C:\awscreds.conf -pages_input -processor_queue -from_scheduler -logfile C:\mylogfile.log

#>
[CmdletBinding(DefaultParametersetName="credsfromfile", supportsshouldprocess = $true) ]
param(
[switch]$processor_queue ,
[switch]$pages_input ,
[switch]$from_scheduler,
[Parameter(Parametersetname ="credsinline",mandatory=$true)]
[string]$aws_access_id = "",
[Parameter(Parametersetname ="credsfromfile")]
[string]$aws_credential_file = [Environment]::GetEnvironmentVariable("AWS_CREDENTIAL_FILE"),
[Parameter(Parametersetname ="credsinline",position=8,mandatory=$true)]
[string]$aws_secret_key = "",
[string]$logfile,
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
$Counters = @{}
$client_name = 'CloudWatch-PutInstanceDataWindows'
$useragent = "$client_name/$ver"

### Add More counters here. 
#$Counters.Add('\Memory\Cache Bytes','Bytes')
#$Counters.Add('\\localhost\physicaldisk(0 c:)\% disk time','Percent')

### Logs all messages to file or prints to console based on from_scheduler setting. ###
function report_message ([string]$message)
{
	if($from_scheduler)
	{	if ($logfile.Length -eq 0)
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

### Global trap for all excpetions for this script. All exceptions will exit the script.###
trap [Exception] {
report_message ($_.Exception.Message)
Exit
}
if ($version)
{
 report_message "$scriptname version $ver"
 exit 
}

####Test and load AWS sdk ###
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
	$az = get-metadata ("/placement/availability-zone")
	return ($az.Substring(0, ($az.Length -1)))
}
function get-endpoint {
	$region = get-region
	return "https://monitoring." + $region + ".amazonaws.com/"
}

### Function that creates metric data which will be added to metric list that will be finally pushed to cloudwatch. ###
function append-metric   {

	$metricdata = New-Object Amazon.Cloudwatch.Model.MetricDatum
	$dimensions = New-Object Collections.Generic.List[Amazon.Cloudwatch.Model.Dimension]
	$metricdata.metricname, $metricdata.Unit, $metricdata.value, $dimensions  = $args
	$metricdata.Dimensions = $dimensions
	$metricdata.Timestamp = $time.ToUniversalTime()
	return $metricdata
}

function get-counters {
	if ($processor_queue){
		$Counters.Add('\System\Processor Queue Length','Count')
	}
	if ($pages_input){
		$Counters.Add('\Memory\Pages Input/sec','Count')
	}
	if ($Counters.Count -gt 0){
 		foreach ($key in $Counters.Keys){
   			$counterset = (Get-Counter -Counter $key).countersamples
   			if ($counterset.count -gt 0){
    			$counterobj = New-Object psobject
				Add-Member -InputObject $counterobj -Name "Counter" -Value $key -MemberType NoteProperty
				Add-Member -InputObject $counterobj -Name "Countervalue" -Value $counterset[0].cookedvalue -MemberType NoteProperty
				Add-Member -InputObject $counterobj -Name "Units" -Value $Counters[$key] -MemberType NoteProperty
				write $counterobj
   			}
		}
 	}
 	else {
  		throw " Please select a counter or add custom counters to report"
   	}
 }
function create-metriclist{
	param ([parameter(valuefrompipeline =$true)] $counterobj)
 	begin {
				$dims = New-Object Amazon.Cloudwatch.Model.Dimension
				$dims.Name = "InstanceId"
				$dims.value = get-metadata("/instance-id")
	}
	process {
				$dimlist = New-Object Collections.Generic.List[Amazon.Cloudwatch.Model.Dimension]
				$dimlist.Add($dims)
				$counterdim = New-Object Amazon.Cloudwatch.Model.Dimension
				$counterdim.name = "Perfmon Counter"
				$counterdim.value = $counterobj.counter
				$dimlist.add($counterdim)
			
				write ( append-metric (split-Path -leaf $counterobj.counter) $counterobj.units $counterobj.Countervalue $dimlist)
			}

}
function put-instancecounters
{
 param ([parameter(Valuefrompipeline=$true)] $metlist)
 begin{
 		$cwconfig = New-Object Amazon.CloudWatch.AmazonCloudWatchConfig
		$cwconfig.serviceURL = get-endpoint
		$cwconfig.UserAgent = $useragent
		$monputrequest  = new-object Amazon.Cloudwatch.Model.PutMetricDataRequest
		$monputrequest.namespace = "System/Windows" 
		$response = New-Object psobject
		$metricdatalist = New-Object Collections.Generic.List[Amazon.Cloudwatch.Model.MetricDatum]
		$cwclient = New-Object Amazon.Cloudwatch.AmazonCloudWatchClient($accountinfo.AWSAccessKeyId,$accountinfo.AWSSecretKey,$cwconfig)
		
	}
process{
 		if ($PSCmdlet.shouldprocess($metlist.metricname,"The metric data "+$metlist.value.tostring() +" "+ $metlist.unit.tostring()+" will be pushed to cloudwatch")){
		$metricdatalist.add($metlist)
		Write-Verbose ("Metricname= " +$metlist.metricname+" Metric Value= "+ $metlist.value.tostring()+" Metric Units= "+$metlist.unit.tostring())
		}
 		}
end{
	if ($metricdatalist.count -gt 0) {
	$monputrequest.metricdata = $metricdatalist
	$monresp =  $cwclient.PutMetricData($monputrequest)
	Add-Member -Name "RequestId" -MemberType NoteProperty -Value $monresp.ResponseMetadata.RequestId -InputObject $response -Force
	}
	else {throw "No metric data to push to CloudWatch exiting script" }
	Write-Verbose ("RequestID: " +  $response.RequestId)
 	}
}
get-counters | create-metriclist | put-instancecounters