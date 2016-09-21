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
  - parse PID
  - use "get-process" to find exe name (netstat -b is not pulling it for my scenario)
  - finds a full process path name in a Nano TP5 compatible way

#>
	PROCESS
	{
		# Get the output of netstat
		$data = netstat -a -n -o -p TCP

		# Keep only the line with the data (we remove the first lines)
		$data = $data[4..$data.count]

		# Each line need to be splitted and get rid of unnecessary spaces
		foreach ($line in $data)
		{
			# Get rid of the first whitespaces, at the beginning of the line
			$line = $line -replace '^\s+', ''

			# Split each property on whitespaces block
			$line = $line -split '\s+'

      If ($line[4].length -ge 1)
      {
        $ProcessInfo = Get-Process -id $($line[4])
        #$ProcessEXEPath = wmic process where "ProcessId='$($line[4])'" get ExecutablePath | select-object -skip 1 | ?{$_ -ne ''}
        If ((wmic process where "ProcessId='$($line[4])'" get ExecutablePath) -match "[A-Z]:\\.*")
        {
          $ProcessEXEPath = $Matches[0]
        }
      }
			# Define the properties
			$properties = @{
				Protocol = $line[0]
				LocalAddressIP = ($line[1] -split ":")[0]
				LocalAddressPort = ($line[1] -split ":")[1]
        LocalAddressPID = $line[4]
        LocalAddressProcessName = $ProcessInfo.Name
        LocalAddressProcessPath = $ProcessEXEPath
				ForeignAddressIP = ($line[2] -split ":")[0]
				ForeignAddressPort = ($line[2] -split ":")[1]
				State = $line[3]
			}

			# Output the current line
			New-Object -TypeName PSObject -Property $properties
		}
	}
}
