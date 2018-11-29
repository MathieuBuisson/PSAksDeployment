Function Invoke-TerraformConfigAks {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]$SubscriptionId,

        [Parameter(Mandatory)]
        [string]$ServicePrincipalID,

        [Parameter(Mandatory)]
        [string]$ServicePrincipalSecret,

        [Parameter(Mandatory)]
        [string]$AzureTenantID,

        [Parameter(Mandatory)]
        [string]$ClusterName,

        [Parameter(Mandatory)]
        [string]$ClusterLocation,

        [Parameter(Mandatory)]
        [string]$LogAnalyticsWorkspaceLocation,

        [Parameter(Mandatory)]
        [string]$KubernetesVersion,

        [Parameter(Mandatory)]
        [int]$NodeCount,

        [Parameter(Mandatory)]
        [string]$NodeVMSize,

        [Parameter(Mandatory)]
        [int]$OSDiskSizeGB,

        [Parameter(Mandatory)]
        [int]$MaxPodsPerNode,

        [Parameter(Mandatory)]
        [string]$Environment,

        [Parameter(Mandatory)]
        [string]$TerraformOutputFolder
    )

    $StateChildPath = 'TF_{0}\StateFiles\aks.tfstate' -f $ClusterName
    $StatePath = Join-Path $TerraformOutputFolder -ChildPath $StateChildPath
    $StatePathJsonEscape = $StatePath.Replace('\','/')
    Write-ConsoleLog "State file path (JSON escaped) : $StatePathJsonEscape"

    $PlanChildPath = 'TF_{0}\PlanFiles\aks.tfplan' -f $ClusterName
    $PlanPath = Join-Path $TerraformOutputFolder -ChildPath $PlanChildPath
    $PlanPathJsonEscape = $PlanPath.Replace('\','/')
    Write-ConsoleLog "Plan file path (JSON escaped) : $PlanPathJsonEscape"

    $PlanFolderPath = Split-Path $PlanPathJsonEscape -Parent
    If ( -not(Test-Path $PlanFolderPath -PathType Container) ) {
        Write-ConsoleLog "Creating plan folder : $PlanFolderPath"
        $Null = New-Item -ItemType Directory -Path $PlanFolderPath -Force
    }

    $SubsIdVar = '-var subscription_id={0}' -f $SubscriptionId
    $SecretVar = 'client_secret={0}' -f $ServicePrincipalSecret
    $TenantVar = 'tenant_id={0}' -f $AzureTenantID
    $ClientVar = 'client_id={0}' -f $ServicePrincipalID
    $ClusterVar = 'cluster_name={0}' -f $ClusterName
    $LocationVar = 'location="{0}"' -f $ClusterLocation
    $WorkspaceVar = 'loganalytics_workspace_location="{0}"' -f $LogAnalyticsWorkspaceLocation
    $VersionVar = 'kubernetes_version={0}' -f $KubernetesVersion
    $AgentCountVar = 'agent_count={0}' -f $NodeCount.ToString()
    $AgentSizeVar = 'agent_vm_size={0}' -f $NodeVMSize
    $DiskSizeVar = 'os_disk_size_GB={0}' -f $OSDiskSizeGB.ToString()
    $MaxPodsVar = 'agent_max_pods={0}' -f $MaxPodsPerNode.ToString()
    $EnvVar = 'environment={0}' -f $Environment

    $PlanCmdVars = $SubsIdVar, $SecretVar, $TenantVar, $ClientVar, $ClusterVar, $LocationVar, $WorkspaceVar, $VersionVar, $AgentCountVar, $AgentSizeVar, $DiskSizeVar, $MaxPodsVar, $EnvVar -join ' -var '
    $PlanCmd = [scriptblock]::Create("terraform.exe plan -out=$PlanPathJsonEscape -input=false -detailed-exitcode $PlanCmdVars")
    & $PlanCmd

    If ( $LASTEXITCODE -eq 1 ) {
        Throw 'An error occurred while creating the Terraform plan. For details, please review the Terraform output above.'
    }

    $ApplyCmdString = 'terraform apply -input=false "{0}"' -f $PlanPathJsonEscape
    $ApplyCmd = [scriptblock]::Create($ApplyCmdString)
    & $ApplyCmd

    If ( $LASTEXITCODE -eq 1 ) {
        Throw 'An error occurred while applying the Terraform plan. For details, please review the Terraform output above.'
    }
}
