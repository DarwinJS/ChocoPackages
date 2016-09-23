function Get-NetStat
{
<#
.SYNOPSIS
	This function will get the output of netstat -n and parse the output
.DESCRIPTION
	This function will get the output of netstat -n and parse the output
.LINK
	http://www.lazywinadmin.com/2014/08/powershell-parse-this-netstatexe.html
.NOTES
	Francois-Xavier Cat
	www.lazywinadmin.com
	@LazyWinAdm

  2016/09/20 - Modified by DawinJS to:
  - only grab TCP ports so that parsing PID would be reliable (and is sufficient for my purposes)
  - If -GetProcessDetails
    - parse PID
    - use "get-process" to find exe name (netstat -b is not pulling it for my scenario)
    - finds a full process path name in a Nano TP5 compatible way (WMIC)
  - If -ShowProgress - show progress bar - takes a while to grab all exe paths for all processes
  - If -FilterOnPorts - filter results for these ports before grabbing process details

#>
Param (
  [switch]$ShowProgress,
  [string[]]$FilterOnPorts,
  [switch]$GetProcessDetails
  )
	PROCESS
	{
		# Get the output of netstat
		$data = netstat -a -n -o -p TCP | select -skip 4

		# Keep only the line with the data (we remove the first lines)
		#$data = $data[4..$data.count]

		# Each line need to be splitted and get rid of unnecessary spaces
		foreach ($line in $data)
		{
      If ($ShowProgress)
      {
        $ItemBeingProcessed++
        $percentdone = [math]::round(($ItemBeingProcessed/$data.count) * 100)
        Write-Progress -Activity "Probing Listening Ports" -Status "$percentdone% Complete:" -PercentComplete $percentdone
      }

      $AddInstance = $True
      # Get rid of the first whitespaces, at the beginning of the line
			$line = $line -replace '^\s+', ''

			# Split each property on whitespaces block
			$line = $line -split '\s+'

      $PortFromNetStat = (($line[1] -split ":")[1]).trim(' ')

      If ($FilterOnPorts)
      {
         If  (!($FilterOnPorts -contains $PortFromNetStat))
         {
           $AddInstance = $False
         }
      }

      If ($GetProcessDetails -AND $AddInstance)
      {
        If ($line[4].length -ge 1)
        {
        $ProcessInfo = Get-Process -id $($line[4])
        $ProcessEXEPath = $null

        If ([string](wmic process where "ProcessId='$($line[4])'" get ExecutablePath /format:list) -match "[A-Z]:\\.*exe")
        {
          #write-output "match: *$($Matches[0])*"
          $ProcessEXEPath = "$($Matches[0])"
        }
   <#
           If (Test-Path variable:matches) {write-host "got a match"}

            If ($getresult.GetType().Name -eq 'Boolean')
            {
              $ProcessEXEPath = ($Matches[0]).trimend(' ')
            }
            ElseIf ($getresult.GetType().Name -eq 'String')
            {
              $ProcessEXEPath = $getresult.trimend(' ')
            }
            Else
            {
              $ProcessEXEPath = ''
            }
            #>
        }
      }
      If ($AddInstance)
      {
			# Define the properties
  			$properties = @{
	  			Protocol = $line[0].trim(' ')
		  		LocalAddressIP = ($line[1] -split ":")[0].trim(' ')
			  	LocalAddressPort = $PortFromNetStat
          LocalAddressPID = ($line[4]).trim(' ')
          LocalAddressProcessName = $ProcessInfo.Name
          LocalAddressProcessPath = $ProcessEXEPath
		  		ForeignAddressIP = ($line[2] -split ":")[0].trim(' ')
			  	ForeignAddressPort = ($line[2] -split ":")[1].trim(' ')
				  State = $line[3]
			  }

			  # Output the current line
			  New-Object -TypeName PSObject -Property $properties
      }
		}
	}
}
