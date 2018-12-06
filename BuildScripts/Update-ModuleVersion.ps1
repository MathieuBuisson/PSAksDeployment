Param (
    [Parameter(Mandatory)]
    [ValidateScript({ ($_ -as [System.Version]) -as [bool] })]
    [string]$NewVersion
)

$ErrorActionPreference = 'Stop'

$ModuleName = 'PSAksDeployment'
$ManifestPath = "./$ModuleName/$ModuleName.psd1"
$ManifestContent = Get-Content -Path $ManifestPath
$VersionRegex = "ModuleVersion\s=\s'(?<ModuleVersion>\S+)'" -as [regex]
$CurrentVersion = $VersionRegex.Match($ManifestContent).Groups['ModuleVersion'].Value
Write-Host "Current version in the manifest [$CurrentVersion]"

$ManifestContent -replace $CurrentVersion, $NewVersion | Set-Content -Path $ManifestPath -Force
Write-Host "Updated version in the manifest to [$NewVersion]"
