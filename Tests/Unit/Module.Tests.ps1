$ModuleName = 'PSAksDeployment'
Import-Module "$PSScriptRoot\..\..\$ModuleName\$($ModuleName).psd1" -Force

Describe 'General Module behaviour' {

    $ModuleInfo = Get-Module -Name $ModuleName
    $ManifestPath = Join-Path -Path $ModuleInfo.ModuleBase -ChildPath "$ModuleName.psd1"

    It 'The expected required modules are declared by the module' {

        Foreach ( $RequiredModule in $ModuleInfo.RequiredModules.Name ) {
            $RequiredModule | Should -BeIn @('Az.Profile', 'Az.Resources', 'Az.Aks')
        }
    }
    It 'Has a valid manifest' {
        { Test-ModuleManifest -Path $ManifestPath -ErrorAction Stop } |
            Should Not Throw
    }
    It 'Has a valid root module' {
        $ModuleInfo.RootModule -like '*{0}.psm1' -f $ModuleName |
            Should -Be $True
    }
    It 'Exports all functions located in the "Public" subfolder' {
        $ExpectedFunctions = (Get-ChildItem -Path "$PSScriptRoot\..\..\PSAksDeployment\Public" -File).BaseName
        $ExportedFunctions = $ModuleInfo.ExportedFunctions.Values.Name

        Foreach ( $FunctionName in $ExpectedFunctions ) {
            $FunctionName | Should -BeIn $ExportedFunctions
        }
    }
}
