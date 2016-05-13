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

.EXAMPLE
    powershell.exe .\mon-put-metrics-disk.ps1  -EC2AccessKey ThisIsMyAccessKey -EC2SecretKey ThisIsMySecretKey -disk_space_util -disk_space_avail -disk_space_units kilobytes

.EXAMPLE
	powershell.exe .\mon-put-metrics-disk.ps1  -aws_credential_file C:\awscreds.conf -disk_drive C:, d -disk_space_util -disk_space_used -disk_space_avail -disk_space_units gigabytes

.EXAMPLE
	powershell.exe .\mon-put-metrics-disk.ps1  -aws_credential_file C:\awscreds.conf -disk_drive C:,D: -disk_space_util -disk_space_units gigabytes  -from_scheduler -logfile C:\mylogfile.log


.NOTES
    PREREQUISITES:
    1) Download the SDK library from http://aws.amazon.com/sdkfornet/
    2) Obtain Secret and Access keys from https://aws-portal.amazon.com/gp/aws/developer/account/index.html?action=access-key

	API Reference:http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/query-apis.html

UPDATE LOG:

2016-05-13 DJS
   - Fixed to find .NET 3.5 with newer installs of AWS SDK on Amazon AMIs.
   - allows -disk_drive 'all' to simple upload stats on all local disks - whatever they are for that instance.  
     Will also dynamically adjust if disks are added to or removed from instance in the future.
   - drops any non-existent disks from the list given in -disk_drive, rather than generating an error.
   - removed assumption of credentials being provided so that code can rely on the much better practice of using instance roles.
   - replaced all "write-host" lines with better practice "write-output".
   - updated parameters and defaults so that if the script is used with no parameters it reports disk utilization for 
     all installed disks and relies on instance roles for permission to post to cloudwatch.

#>

[CmdletBinding(DefaultParametersetName="credsfromfile", supportsshouldprocess = $true) ]
param(
[switch]$disk_space_util=$True, #Set -disk_space_util:$False to disable from command line
[switch]$disk_space_used ,
[switch]$disk_space_avail ,
[string[]]$disk_drive='all',
[ValidateSet("bytes","kilobytes","megabytes","gigabytes" )]
[string]$disk_space_units = "gigabytes",
[switch]$from_scheduler,
[Parameter(Parametersetname ="credsinline")]
[string]$aws_access_id = "",
[Parameter(Parametersetname ="credsfromfile")]
[string]$aws_credential_file = [Environment]::GetEnvironmentVariable("AWS_CREDENTIAL_FILE"),
[Parameter(Parametersetname ="credsinline")]
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
$client_name = 'CloudWatch-PutInstanceDataWindows'
$useragent = "$client_name/$ver"

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
		write-output $message
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
$SDKLoc = "$ProgFilesLoc\AWS SDK for .NET\past-releases\version-2\Net35"

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
                                $usingEncodedCredentials_VERYBAD = $true
							}
						else
							{
								throw "Value of AWS secret key is not specified."
							}
					}
	"credsfromfile"{
					if ( (test-path variable:aws_credential_file) -AND ($aws_credential_file) -AND (Test-Path $aws_credential_file))
						{
							Write-Verbose "Using AWS credentials file $aws_credential_file"
							Get-Content $aws_credential_file | ForEach-Object {
															if($_ -match '.*=.*'){$text = $_.split("=");
															switch ($text[0].trim())
															{
																"AWSAccessKeyId" 	{$aaid= $text[1].trim()}
																"AWSSecretKey" 		{ $ask = $text[1].trim()}
															}}}
                        $usingEncodedCredentials_VERYBAD = $true
						}
						else {write-output "Not configured to use aws_credential_file"}
					}
     default {
              #no credentials provided - must be using an instance role to get access
              }
}
if (($aaid.length -gt 0) -or ($ask.length -gt 0))
{

	Add-Member -membertype noteproperty -inputobject $accountinfo -name "AWSSecretKey" -value $ask
	Add-Member -membertype noteproperty -inputobject $accountinfo -name "AWSAccessKeyId" -value $aaid
	Remove-Variable ask; Remove-Variable aaid
}

### Check if atleast one metric is requested to report.###
if ( !$disk_space_avail -and !$disk_space_used -and !$disk_space_util )
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
	$az = get-metadata ("/placement/availability-zone")
	return ($az.Substring(0, ($az.Length -1)))
}
function get-endpoint {
	$region = get-region
	return "https://monitoring." + $region + ".amazonaws.com/"
}

### Function that creates metric data which will be added to metric list that will be finally pushed to cloudwatch. ###
function append_metric   {

	$metricdata = New-Object Amazon.Cloudwatch.Model.MetricDatum
	$dimensions = New-Object Collections.Generic.List[Amazon.Cloudwatch.Model.Dimension]
	$metricdata.metricname, $metricdata.Unit, $metricdata.value, $dimensions  = $args
	$metricdata.Dimensions = $dimensions
	$metricdata.Timestamp = $time.ToUniversalTime()
	return $metricdata
}

### Function that validates units passed. Default value of  Gigabytes is used###
function parse-units {
	param ([string]$disk_units,
		[long]$disk_unit_div)
	$units = New-Object psobject
	switch ($disk_space_units.ToLower())
					{
						"bytes" 	{ 	$disk_units = "Bytes" ; $disk_unit_div = 1}
						"kilobytes" { 	$disk_units = "Kilobytes" ;$disk_unit_div = 1kb}
						"megabytes" { 	$disk_units = "Megabytes" ;$disk_unit_div = 1mb}
						"gigabytes" {	$disk_units = "Gigabytes" ;$disk_unit_div = 1gb}
						default 	{ 	$disk_units = "Gigabytes" ; $disk_unit_div = 1gb }
					}
	Add-Member -MemberType NoteProperty -InputObject $units -Name "disk_units" -Value $disk_units
	Add-Member -MemberType NoteProperty -InputObject $units -Name "disk_unit_div" -Value $disk_unit_div
	return $units
}

### Verifes the array of drive letters passed###
function check-disks {
	$drive_list_parsed = @() #New-Object System.Collections.ArrayList

    $LocalDrivesOnThisMachine = @(Get-WMIObject Win32_LogicalDisk -filter "DriveType=3" | select -expand deviceid)

    If ($disk_drive -icontains 'all')
    {
      $drive_list_parsed = $LocalDrivesOnThisMachine
      Write-Output "'all' option found in the drives list, including all local drives: $LocalDrivesOnThisMachine, ('all' overrides any specific drives you may have also specified)"
    }
    Else
    {

      $INVALIDValuesPresent = @(($disk_drive | select-string -pattern $LocalDrivesOnThisMachine -simplematch -notmatch).line)
      $VALIDValuesPresent = @(($LocalDrivesOnThisMachine | select-string -pattern $INVALIDValuesPresent -simplematch -notmatch).line)
      
      $drive_list_parsed = $VALIDValuesPresent

      If ($INVALIDValuesPresent.count -gt 0)
      {
        Write-Output "Opps, these drives: $INVALIDValuesPresent are not present, only including drives that exist locally - these ones: $VALIDValuesPresent"
      }


	}
	return $drive_list_parsed
}

### Function that gets disk stats using WMI###
function get-diskmetrics {

	begin{}
	process {
			$drive_list_parsed = New-Object System.Collections.ArrayList
			$drive_list_parsed = check-disks
			$disksinfo = Get-WMIObject Win32_LogicalDisk -filter "DriveType=3"

			foreach ($diskinfo in $disksinfo){
				foreach ($drivelist in $drive_list_parsed){
					if ($diskinfo.DeviceID -eq $drivelist){
					$diskobj = New-Object psobject
					add-member -InputObject $diskobj -MemberType NoteProperty -Name "deviceid" -Value $diskinfo.DeviceID
					add-member -InputObject $diskobj -MemberType NoteProperty -Name "Freespace" -Value $diskinfo.Freespace
					add-member -InputObject $diskobj -MemberType NoteProperty -Name "size" -Value $diskinfo.size
					Add-Member -InputObject $diskobj -MemberType NoteProperty -Name "UsedSpace" -Value ($diskinfo.size - $diskinfo.Freespace)
					Write-Output $diskobj
					}
					}
				}

}
	end{}
}

### Function that writes metrics to be piped to next fucntion to push to cloudwatch.###
function create-diskmetriclist {
		param ([parameter(valuefrompipeline =$true)] $diskobj)
		begin{
				$units = parse-units
				$dims = New-Object Amazon.Cloudwatch.Model.Dimension
				$dims.Name = "InstanceId"
				$dims.value = get-metadata("/instance-id")
			}
		process{
			$dimlist = New-Object Collections.Generic.List[Amazon.Cloudwatch.Model.Dimension]
			$dimlist.Add($dims)
			$dim_drive_letter = New-Object Amazon.Cloudwatch.Model.Dimension
			$dim_drive_letter.Name = "Drive-Letter"
			$dim_drive_letter.value = $diskobj.Deviceid
			$dimlist.Add($dim_drive_letter)
			if ($disk_space_util)
						{
							$percent_disk_util= 0
							if ( [long]$diskobj.size -gt 0 ) { $percent_disk_util = 100 * ([long]$diskobj.UsedSpace/[long]$diskobj.size)}
							write (append_metric "VolumeUtilization" "Percent"  ("{0:N2}" -f $percent_disk_util) $dimlist)
						}
			if ($disk_space_used)
						{
							write (append_metric "VolumeUsed" $units.disk_units ("{0:N2}" -f ([long]($diskobj.UsedSpace/$units.disk_unit_div))) $dimlist)
						}
 			if ( $disk_space_avail)
						{
							write (append_metric "VolumeAvailable" $units.disk_units ("{0:N2}" -f([long]($diskobj.Freespace/$units.disk_unit_div))) $dimlist)
						}
			}
		end{}
}

 ### Uses AWS sdk to push metrics to cloudwatch. This finally prints a requestid.###
function put-instancemem {
 param ([parameter(Valuefrompipeline=$true)] $metlist)
 begin{
 		$cwconfig = New-Object Amazon.CloudWatch.AmazonCloudWatchConfig
		$cwconfig.serviceURL = get-endpoint
		$cwconfig.UserAgent = $useragent
		$monputrequest  = new-object Amazon.Cloudwatch.Model.PutMetricDataRequest
		$monputrequest.namespace = "System/Windows"
		$response = New-Object psobject
		$metricdatalist = New-Object Collections.Generic.List[Amazon.Cloudwatch.Model.MetricDatum]
		
        If ($usingEncodedCredentials_VERYBAD)
        {
          $cwclient = New-Object Amazon.Cloudwatch.AmazonCloudWatchClient($accountinfo.AWSAccessKeyId,$accountinfo.AWSSecretKey,$cwconfig)
        }
        Else
        {
          $cwclient = New-Object Amazon.Cloudwatch.AmazonCloudWatchClient($cwconfig)
        }

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
 ### Pipelined call of fucntions that pushs metrics to cloudwatch.
get-diskmetrics | create-diskmetriclist | put-instancemem
