Function Set-AksKubeConfig {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]$ClusterName,

        [Parameter(Mandatory)]
        [string]$ClusterId
    )

    Import-AzAksCredential -Id $ClusterId -Force
    $KubectlMessage = & kubectl config use-context $ClusterName
    Write-ConsoleLog "Kubectl $KubectlMessage"
}