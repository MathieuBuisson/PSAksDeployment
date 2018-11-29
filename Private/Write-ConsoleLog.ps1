Function Write-ConsoleLog {
<#
.SYNOPSIS
    Helper function for semi-structured console logging.
#>
    [CmdletBinding()]
    Param(
        [Parameter(Position=0, Mandatory)]
        [string]$Message
    )

    $TimeStamp = Get-Date -Format s
    $CallingCommand = (Get-PSCallStack)[1].Command
    $MessageData = '{0} [{1}] : {2}' -f $TimeStamp,$CallingCommand,$Message

    Write-Host $MessageData
}