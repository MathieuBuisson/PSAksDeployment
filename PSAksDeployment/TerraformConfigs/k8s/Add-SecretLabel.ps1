Param(
    [Parameter(Mandatory)]
    [string]$SecretName,

    [Parameter(Mandatory)]
    [string]$Namespace
)

$ErrorActionPreference = 'Stop'

# Approximate time for the certificate request to complete
Start-Sleep -Seconds 110

$LoopIteration = 0
Do {
    Write-Host "Waiting for the secret [$SecretName] to be created"
    Start-Sleep -Seconds 10
    $SecretIsPresent = & kubectl get secret $SecretName -n $Namespace --ignore-not-found
    $LoopIteration++
}
Until ( $SecretIsPresent -or ($LoopIteration -gt 10) )

& kubectl label secret $SecretName -n $Namespace propagate-to-ns=true
