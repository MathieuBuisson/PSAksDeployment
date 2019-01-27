#Requires -RunAsAdministrator

Function Install-PSAksPrerequisites {
<#
.SYNOPSIS
    Installs the prerequisites to deploy and manage an Azure Kubernetes (AKS) cluster.

.DESCRIPTION
    Installs the prerequisites to deploy and manage an Azure Kubernetes (AKS) cluster.
    This prerequisites include :
      - Az PowerShell modules (PSAksDeployment is not compatible with the legacy AzureRM modules)
      - Terraform (https://www.terraform.io/)
      - Kubectl (https://kubernetes.io/docs/reference/kubectl)
      - Helm (https://helm.sh/)

    If the specified installation folder is not in the PATH environment variable, it takes care of adding it to the user-scoped environment.

.PARAMETER InstallationFolder
    Directory where the prerequisites will be stored/installed.
    If the directory does not exist, it will be created.

    Also, if the directory is not in the PATH environment variable, it will be added to the user-scoped environment.

.PARAMETER TerraformVersion
    To install a specific version of Terraform.

.PARAMETER KubectlVersion
    To install a specific version of Kubectl.

.PARAMETER HelmVersion
    To install a specific version of Helm.

.EXAMPLE
    PS C:\> Install-PSAksPrerequisites -InstallationFolder 'C:\Tools'

#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, Position=0)]
        [string]$InstallationFolder,

        [Parameter(Mandatory=$False, Position=1)]
        [ValidateScript({ ($_ -as [System.Version]) -as [bool] })]
        [string]$TerraformVersion = '0.11.10',

        [Parameter(Mandatory=$False, Position=2)]
        [ValidateScript({ ($_ -as [System.Version]) -as [bool] })]
        [string]$KubectlVersion = '1.12.3',

        [Parameter(Mandatory=$False, Position=3)]
        [ValidateScript({ ($_ -as [System.Version]) -as [bool] })]
        [string]$HelmVersion = '2.11.0'
    )

    If ( -not(Test-Path -Path $InstallationFolder -PathType Container) ) {
        $Null = New-Item -Path $InstallationFolder -ItemType Directory -Force
    }

    $RequiredPSModules = 'Az.Accounts', 'Az.Resources', 'Az.Aks'
    $PSPackageProvider = Get-PackageProvider -Name 'NuGet' -Force | Where-Object Version -gt ('2.8' -as [System.Version])
    If ( -not($PSPackageProvider) ) {
        Install-PackageProvider -Name NuGet -Force
    }

    Foreach ( $RequiredModule in $RequiredPSModules ) {
        $IsInstalled = (Get-Module -Name $RequiredModule -ListAvailable) -as [bool]
        If ( $IsInstalled ) {
            Write-ConsoleLog "Module $RequiredModule is already installed, skipping installation."
        }
        Else {
            Write-ConsoleLog "Module $RequiredModule is not installed, installing it."
            Install-Module -Name $RequiredModule -Repository PSGallery -Force -Confirm:$False
        }
    }

    Try {
        & terraform *> $Null
    }
    Catch [Management.Automation.CommandNotFoundException] {
        Write-ConsoleLog 'Terraform is not installed, installing it.'
        $TerraformUrl = 'https://releases.hashicorp.com/terraform/{0}/terraform_{0}_windows_amd64.zip' -f $TerraformVersion
        Save-PSAksPrerequisite -Uri $TerraformUrl -Path $InstallationFolder
    }

    Try {
        & kubectl *> $Null
    }
    Catch [Management.Automation.CommandNotFoundException] {
        Write-ConsoleLog 'Kubectl is not installed, installing it.'
        $KubectlUrl = 'https://storage.googleapis.com/kubernetes-release/release/v{0}/bin/windows/amd64/kubectl.exe' -f $KubectlVersion
        Save-PSAksPrerequisite -Uri $KubectlUrl -Path $InstallationFolder
    }

    Try {
        & helm *> $Null
    }
    Catch [Management.Automation.CommandNotFoundException] {
        Write-ConsoleLog 'Helm is not installed, installing it.'
        $HelmUrl = 'https://storage.googleapis.com/kubernetes-helm/helm-v{0}-windows-amd64.zip' -f $HelmVersion
        Save-PSAksPrerequisite -Uri $HelmUrl -Path $InstallationFolder
    }

    $PathArray = ($Env:Path -split ';').ForEach({ $_.TrimEnd('/\') })
    If ( $InstallationFolder.TrimEnd('/\') -notin $PathArray ) {
        Add-PathEnvironmentVariable -PathToAdd $InstallationFolder

        # Persisting the value of $InstallationFolder for subsequent module imports
        $DataFilePath = Join-Path -Path "$Env:APPDATA" -ChildPath 'PSAksDeployment/ModuleData.psd1'
        Write-ConsoleLog "Persisting `$InstallationFolder to [$DataFilePath]"
        $DataFileContent = "@{`n`tInstallationFolder = '$InstallationFolder'`n}"
        $Null = New-Item -Path $DataFilePath -ItemType File -Value $DataFileContent -Force
    }
}
