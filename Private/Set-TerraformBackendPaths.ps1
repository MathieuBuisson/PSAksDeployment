Function Set-TerraformBackendPaths {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, Position=0)]
        [string]$RootFolder,

        [Parameter(Mandatory, Position=1)]
        [string]$ClusterName
    )

    $TerraformConfigsPath = Join-Path "$($MyInvocation.MyCommand.Module.ModuleBase)" -ChildPath 'TerraformConfigs'
    $TerraformConfigFolders = Get-ChildItem -Path $TerraformConfigsPath -Directory

    Foreach ( $Folder in $TerraformConfigFolders ) {
        Write-ConsoleLog "Configuring Terraform backend for config : $($Folder.Name)"

        $BackendChildPath = 'TF_{0}\StateFiles\{1}.tfstate' -f $ClusterName, $Folder.Name
        $BackendPath = Join-Path $RootFolder -ChildPath $BackendChildPath
        $BackendPathJsonEscape = $BackendPath.Replace('\','/')
        Write-ConsoleLog "Backend Path (JSON escaped) : $BackendPathJsonEscape"

        $ProvidersConfigFile = Join-Path $Folder.FullName 'providers.tf'
        $ProvidersConfig = Get-Content -Path $ProvidersConfigFile
        [regex]$BackendRegex = 'path\s=\s"(?<Backend>.+\.tfstate)"'
        $OldBackendString = $BackendRegex.Match($ProvidersConfig).Groups['Backend'].Value
        Write-ConsoleLog "Backend regex match in file [$ProvidersConfigFile]: [$OldBackendString]"

        $ProvidersConfig -replace [regex]::Escape($OldBackendString),$BackendPathJsonEscape | Set-Content $ProvidersConfigFile -Force
    }
}
