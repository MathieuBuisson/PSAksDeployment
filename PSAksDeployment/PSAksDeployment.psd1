@{

    # Script module or binary module file associated with this manifest.
    RootModule = './PSAksDeployment.psm1'

    # Version number of this module.
    ModuleVersion = '0.1.76'

    # ID used to uniquely identify this module
    GUID = '87acffec-ab85-4cd3-904b-9aaee7696e28'

    # Author of this module
    Author = 'Mathieu Buisson'

    # Description of the functionality provided by this module
    Description = 'This modules provides cmdlets to automate the deployment (and destruction) of Azure Kubernetes (AKS) clusters. It wraps other tools like : Terraform, Kubectl and Helm.'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules   = @('Az.Accounts', 'Az.Resources', 'Az.Aks')

    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    # ScriptsToProcess = @()

    # Functions to export from this module
    FunctionsToExport = @('Invoke-PSAksDeployment', 'New-PSAksDeploymentConfig', 'Install-PSAksPrerequisites', 'Remove-PSAksDeployment')

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{

        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = 'Azure', 'Kubernetes', 'Terraform'

            # A URL to the license for this module.
            LicenseUri = 'https://github.com/MathieuBuisson/PSAksDeployment/blob/master/LICENSE.md'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/MathieuBuisson/PSAksDeployment'
        }

    } # End of PrivateData hashtable
}
