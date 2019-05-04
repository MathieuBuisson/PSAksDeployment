# PSAksDeployment

## Overview

[![Build Status](https://dev.azure.com/mathieubuisson/PSAksDeployment/_apis/build/status/MathieuBuisson.PSAksDeployment)](https://dev.azure.com/mathieubuisson/PSAksDeployment/_build/latest?definitionId=12) [![PS Gallery](https://img.shields.io/powershellgallery/v/PSAksDeployment.svg?style=plastic&label=PowerShell%20Gallery&colorB=blue)](https://www.powershellgallery.com/packages/PSAksDeployment/)

**[Azure Kubernetes Service](https://azure.microsoft.com/en-us/services/kubernetes-service/)** (AKS) makes provisioning **[Kubernetes](https://kubernetes.io/)** clusters very easy, in a "Hello World!" kind of way.

But deploying a **production-ready** Kubernetes cluster requires additonal components and considerations :
  - Monitoring
  - [Kubectl](https://kubernetes.io/docs/reference/kubectl) configuration
  - How to deploy resources ([Helm](https://helm.sh/) and Tiller)
  - Routing requests from the outside world to services in the cluster (ingress controller)
  - Issuing and managing TLS certificates for ingress controller(s)

PSAksDeployment is a **PowerShell** module which facilitates all of the above by provisioning and configuring extra resources, in addition to the Azure AKS resource.

It is an opinionated implementation, in the sense that :
  - The monitoring solution is **[Azure Monitor](https://azure.microsoft.com/en-us/services/monitor/)** (with Log Analytics)
  - The ingress controller is **[NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)**
  - Management Kubernetes resources are deployed into a "management" namespace
  - The solution to manage TLS certificates is **[cert-manager](https://github.com/jetstack/cert-manager)** (with Let's Encrypt)
  - The ingress controller TLS certificate is propagated to other namespaces (including namespaces created at a later point), to allow ingresses in any namespace to use it, using a custom tool : **[secret-propagator](https://github.com/MathieuBuisson/PSAksDeployment/tree/master/PSAksDeployment/Assets/secret-propagator)**


## Requirements

To use PSAksDeployment, you need :
  - Windows PowerShell 5.1
  - [.Net Framework 4.7.2](https://dotnet.microsoft.com/download/dotnet-framework-runtime) (required by the "Az" PowerShell modules)

All other prerequisites can be installed by running `Install-PSAksPrerequisites`, for example :

```powershell
Install-PSAksPrerequisites -InstallationFolder 'C:\Tools'
```

This installs the following (if they are not already installed) :
  - [Az PowerShell modules](https://docs.microsoft.com/en-us/powershell/azure/install-az-ps) (PSAksDeployment is not compatible with the legacy AzureRM modules)
  - [Terraform](https://www.terraform.io/)
  - [Kubectl](https://kubernetes.io/docs/reference/kubectl)
  - [Helm](https://helm.sh/)

It also adds the specified installation folder to your `PATH` environment variable (if not already in the `PATH`).

## Installation

### From the PowerShell Gallery

The easiest and preferred way to install PSAksDeployment is via the [PowerShell Gallery](https://www.powershellgallery.com/).

Run the following command to install PSAksDeployment and its dependencies ("Az" PowerShell modules) :

```powershell
Install-Module -Name 'PSAksDeployment' -Repository 'PSGallery'
```

### From Github

As an alternative, you can clone this repository to a location on your system and copy the `PSAksDeployment` subfolder into :
`C:\Program Files\WindowsPowerShell\Modules\`.

**NOTE :** In this case, you need to install the Azure PowerShell modules yourself, like so :
```powershell
Install-Module -Name 'Az.Profile', 'Az.Resources', 'Az.Aks' -Repository 'PSGallery'
```

## Getting Started

### Deploying a new AKS cluster

This is the purpose of `Invoke-PSAksDeployment`.

It deploys the following :
  - an **[Azure Kubernetes Service](https://azure.microsoft.com/en-us/services/kubernetes-service/)** (AKS) instance
  - an Azure Log Analytics workspace with the ContainerInsights solution
  - a Public IP address for the ingress controller
  - a "management" namespace
  - Tiller
  - **[NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)**
  - **[cert-manager](https://github.com/jetstack/cert-manager)**
  - a TLS certificate (to support HTTPS ingresses)
  - **[secret-propagator](https://github.com/MathieuBuisson/PSAksDeployment/tree/master/PSAksDeployment/Assets/secret-propagator)**

It primarily acts as an input validation and orchestration layer. Under the hood, most of the work is done by applying **[Terraform](https://www.terraform.io/)** configurations.

Due to the nature of what it does, `Invoke-PSAksDeployment` takes a large number of parameters :

```powershell
PS C:\> Import-Module -Name 'PSAksDeployment'
PS C:\> (Get-Command -Name 'Invoke-PSAksDeployment').Parameters.Keys
ServicePrincipalID
ServicePrincipalSecret
AzureTenantID
Subscription
ClusterName
ClusterLocation
LogAnalyticsWorkspaceLocation
KubernetesVersion
NodeCount
NodeSize
OSDiskSizeGB
MaxPodsPerNode
Environment
LetsEncryptEmail
TerraformOutputFolder
ConfigPath
```

You may be wondering :
> What are these for ?  
Which ones are mandatory ?  
What is the default value ?  
What are the possible values ?  

You can get this information via the cmdlet help, for example :

```powershell
PS C:\> Get-Help 'Invoke-PSAksDeployment' -Parameter 'ServicePrincipalID'

-ServicePrincipalID <String>
    The application ID of the Service Principal used by Terraform (and the AKS cluster) to access Azure.

    Required?                    true
    Position?                    1
    Default value
    Accept pipeline input?       false
    Accept wildcard characters?  false
```

Doing this for each parameter can be tedious, so there is another way to specify all inputs to `Invoke-PSAksDeployment` : a configuration file.

`New-PSAksDeploymentConfig` scaffolds this configuration file, with helpful information for each parameter :
  - a description
  - the data type
  - valid values
  - the default value

Here is an example :

```powershell
PS C:\> $ScaffoldParams = @{
>>     ServicePrincipalID     = '29x1ecd3-190f-42c9-8660-088f69d121zn'
>>     ServicePrincipalSecret = 'tsWpRr6/YCxNyh8efMvjWbe5JoOiOw03xR1o9S5CLhZ='
>>     AzureTenantID          = '96v3b174-9c1p-4a5e-9177-18c3bccc87cb'
>>     Subscription           = 'DevOps'
>>     ClusterLocation        = 'North Europe'
>>     Path                   = '.\TestScaffold.psd1'
>> }
PS C:\> New-PSAksDeploymentConfig @ScaffoldParams
```

Here is what the generated file looks like :

```powershell
PS C:\> Get-Content .\TestScaffold.psd1
@{
    <#
    The name of the Azure subscription where the AKS instance (and other Azure resources) will be deployed.
    Type : String
    Valid values : "DevOps", "ANY OTHER SUBSCRIPTION WHICH CAN BE ACCESSED BY THE SERVICE PRINCIPAL"
    #>
    Subscription = ""

    <#
    The Azure region where the AKS cluster (and other Azure resources) will be deployed.
    Type : String
    Valid values : "East US", "West Europe", "Central US", "Canada Central", "Canada East", "UK South", "West US", "West US 2", "Australia East", "North Europe", "Japan East", "East US 2", "Southeast Asia", "UK West", "South India", "East Asia"
    #>
    ClusterLocation = ""

    <#
    The Azure region where the Log Analytics workspace will be deployed.
    This might not be possible to provision the Log Analytics workspace in the same region as the AKS cluster, because Log Analytics is available in a limited set of regions.
    Type : String
    Valid values : "East US", "West Europe", "Southeast Asia", "Australia Southeast", "West Central US", "Japan East", "UK South", "Central India", "Canada Central"
    #>
    LogAnalyticsWorkspaceLocation = ""

    <#
    The application ID of the Service Principal used by Terraform (and the AKS cluster) to access Azure.
    Type : String
    Valid values :
    #>
    ServicePrincipalID = ""

    <#
    The password of the Service Principal used by Terraform (and the AKS cluster) to access Azure.
    Type : String
    Valid values :
    #>
    ServicePrincipalSecret = ""

    <#
    The ID of the Azure AD tenant where the Terraform Service Principal (and the target subscription) live.
    Type : String
    Valid values :
    #>
    AzureTenantID = ""

    <#
    The name of the AKS cluster.
    The name of the resource group and the cluster DNS prefix are derived from this value.
    Type : String
    Valid values : The name can contain only letters, numbers, and hyphens. The name must start with a letter and must end with a letter or a number.
    #>
    ClusterName = ""

    <#
    The version of Kubernetes software running in the AKS Cluster.
    Type : String
    Valid values : "1.9.11", "1.10.12", "1.10.13", "1.11.8", "1.11.9", "1.12.6", "1.12.7", "1.13.5"
    #>
    KubernetesVersion = "1.13.5"

    <#
    The number of worker nodes in the AKS cluster.
    Type : Int32
    Valid values : Between 1 and 100.
    #>
    NodeCount = 3
  ...

}
```
(Output cut for brevity)

Now, you can populate/adjust values in the file to your needs and feed it to `Invoke-PSAksDeployment`, like so :

```powershell
PS C:\> Invoke-PSAksDeployment -ConfigPath '.\TestScaffold.psd1'
```

Sit back and relax, the overall deployment takes around 20-25 minutes.

When it completes, **Kubernetes** management tools are ready to work with your new cluster.  
For example, you can list the deployments in the "management" namespace :

```powershell
PS C:\> kubectl get deployment -n management
NAMESPACE     NAME                            DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
management    cert-manager                    1         1         1            1           5m
management    nginx-ingress-controller        2         2         2            2           11m
management    nginx-ingress-default-backend   1         1         1            1           11m
management    secret-propagator               1         1         1            1           3m
```

Or list all Helm releases :

```powershell
PS C:\> helm ls
NAME                 REVISION    UPDATED                       STATUS         CHART                   APP VERSION   NAMESPACE
cert-manager         1           Sun Dec  9 18:49:40 2018      DEPLOYED       cert-manager-v0.5.2     v0.5.2        management
cluster-issuer       1           Sun Dec  9 18:49:51 2018      DEPLOYED       cluster-issuer-0.1.0    1.0           default
nginx-ingress        1           Sun Dec  9 18:43:16 2018      DEPLOYED       nginx-ingress-1.0.1     0.21.0        management
secret-propagator    1           Sun Dec  9 18:51:40 2018      DEPLOYED       secret-propagator-0.1.0 1.0           management
```

### Deleting the AKS cluster (and all associated resources)

An AKS cluster deployed with `Invoke-PSAksDeployment` may need to be later deprovisioned.

In this case, the cmdlet `Remove-PSAksDeployment` automates tearing down the Azure Kubernetes Service instance and all associated resources, to stop incurring any Azure charges.

Here is an example usage :

```powershell
PS C:\> $DestroyParams = @{
>>     ServicePrincipalID     = '29x1ecd3-190f-42c9-8660-088f69d121zn'
>>     ServicePrincipalSecret = 'tsWpRr6/YCxNyh8efMvjWbe5JoOiOw03xR1o9S5CLhZ='
>>     AzureTenantID          = '96v3b174-9c1p-4a5e-9177-18c3bccc87cb'
>>     Subscription           = 'DevOps'
>>     ClusterName            = 'docs-cluster'
>> }
PS C:\> Remove-PSAksDeployment @DestroyParams
```

## Contributing to PSAksDeployment

You are welcome to contribute to this project. There are many ways you can contribute :

1. Submit a **[bug report](https://github.com/MathieuBuisson/PSAksDeployment/issues/new?template=Bug_report.md)**.
2. Submit a fix for an issue.
3. Submit a **[feature request](https://github.com/MathieuBuisson/PSAksDeployment/issues/new?template=Feature_request.md)**.
4. Submit test cases.
5. Tell others about the project.
6. Tell the developers how much you appreciate the project !

For more information on how to contribute to PSAksDeployment, please refer to the **[contributing guidelines](https://github.com/MathieuBuisson/PSAksDeployment/blob/master/.github/CONTRIBUTING.md)** document.
