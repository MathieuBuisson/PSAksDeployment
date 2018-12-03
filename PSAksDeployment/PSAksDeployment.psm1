#Get public and private function definition files.
$Public  = @( Get-ChildItem -Path "$PSScriptRoot/Public/*.ps1" -File -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path "$PSScriptRoot/Private" -File -Filter '*.ps1' -Recurse -ErrorAction SilentlyContinue )

Foreach ( $Import in @($Public + $Private) ) {
    Try {
        . $Import.FullName
    }
    Catch {
        Write-Error -Message "Failed to import function $($Import.FullName): $_"
    }
}
$Script:ExternalHelpCommandNames = @()

# Getting persistent data whenever the module is imported
$DataFilePath = Join-Path -Path "$Env:APPDATA" -ChildPath 'PSAksDeployment/ModuleData.psd1'
If ( Test-Path -Path $DataFilePath -PathType Leaf ) {
    $FileData = Import-PowerShellDataFile -Path $DataFilePath

    $FileInstallationFolder = ($FileData['InstallationFolder']).TrimEnd('/\')
    Write-Verbose "InstallationFolder read from module data file : $FileInstallationFolder"

    $PathArray = ($Env:Path -split ';').ForEach({ $_.TrimEnd('/\') })
    If ( $FileInstallationFolder -notin $PathArray ) {
        Add-PathEnvironmentVariable -PathToAdd $FileInstallationFolder
    }
}

Export-ModuleMember -Function $Public.Basename
