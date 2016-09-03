
<#
.\Plaininstall.ps1 -SSHServerFeature -KeyBasedAuthenticationFeature
#>

Param (
  [Parameter(HelpMessage="Including SSH Server Feature.")]
  [switch]$SSHServerFeature,
  [Parameter(HelpMessage="Using ntrights.exe to set service permissions (will not work, but generate warning if WOW64 is not present on 64-bit machines)")]
  [switch]$UseNTRights,
  [Parameter(HelpMessage="Deleting server private keys after they have been secured.")]
  [switch]$DeleteServerKeysAfterInstalled,
  [Parameter(HelpMessage="Use key based authentication for SSHD, must also use -SSHServerFeature")]
  [switch]$KeyBasedAuthenticationFeature
  )

#$passedargList += $MyInvocation.BoundParameters.GetEnumerator() | foreach {$curarg = $_ ;"$(. { switch ($($curarg.Value)) {'true' { "-$($curarg.Key)" } 'false' { '' } default { "-$($curarg.Key) $($curarg.Value)" } }})"}

. ".\chocolateyinstall.ps1"
