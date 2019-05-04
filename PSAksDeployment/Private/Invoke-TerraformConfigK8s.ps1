Function Invoke-TerraformConfigK8s {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]$ClusterName,

        [Parameter(Mandatory)]
        [int]$TillerReplicaCount,

        [Parameter(Mandatory)]
        [int]$IngressCtrlReplicaCount,

        [Parameter(Mandatory)]
        [int]$PrometheusServerReplicaCount,

        [Parameter(Mandatory)]
        [string]$IngressCtrlIPAddress,

        [Parameter(Mandatory)]
        [string]$LetsEncryptEmail,

        [Parameter(Mandatory)]
        [ValidateSet('staging', 'prod')]
        [string]$LetsEncryptEnvironment,

        [Parameter(Mandatory)]
        [string]$IngressCtrlFqdn,

        [Parameter(Mandatory)]
        [string]$Environment,

        [Parameter(Mandatory)]
        [string]$TerraformOutputFolder
    )

    $StateChildPath = 'TF_{0}\StateFiles\k8s.tfstate' -f $ClusterName
    $StatePath = Join-Path $TerraformOutputFolder -ChildPath $StateChildPath
    $StatePathJsonEscape = $StatePath.Replace('\', '/')
    Write-ConsoleLog "State file path (JSON escaped) : $StatePathJsonEscape"

    $PlanChildPath = 'TF_{0}\PlanFiles\k8s.tfplan' -f $ClusterName
    $PlanPath = Join-Path $TerraformOutputFolder -ChildPath $PlanChildPath
    $PlanPathJsonEscape = $PlanPath.Replace('\', '/')
    Write-ConsoleLog "Plan file path (JSON escaped) : $PlanPathJsonEscape"

    $PlanFolderPath = Split-Path $PlanPathJsonEscape -Parent
    If ( -not(Test-Path $PlanFolderPath -PathType Container) ) {
        Write-ConsoleLog "Creating plan folder : $PlanFolderPath"
        $Null = New-Item -ItemType Directory -Path $PlanFolderPath -Force
    }

    $CertYamlPath = Join-Path $TerraformOutputFolder -ChildPath "TF_$ClusterName\Ingress_Certificate.yaml"
    $CertYamlPathJsonEscape = $CertYamlPath.Replace('\', '/')

    $TillerPodCountVar = '-var tiller_replica_count={0}' -f $TillerReplicaCount.ToString()
    $IngressCtrlCountVar = 'ingressctrl_replica_count={0}' -f $IngressCtrlReplicaCount.ToString()
    $PrometheusSvrCountVar = 'prometheus_svr_replica_count={0}' -f $PrometheusServerReplicaCount.ToString()
    $IngressCtrlIpVar = 'ingressctrl_ip_address={0}' -f $IngressCtrlIPAddress
    $EmailVar = 'letsencrypt_email_address={0}' -f $LetsEncryptEmail
    $LetsEncryptEnv = 'letsencrypt_environment={0}' -f $LetsEncryptEnvironment
    $IngressFqdnVar = 'ingressctrl_fqdn={0}' -f $IngressCtrlFqdn
    $CertYamlVar = 'ingress_cert_yaml_path={0}' -f $CertYamlPathJsonEscape
    $EnvVar = 'environment={0}' -f $Environment

    $PlanCmdVars = $TillerPodCountVar, $IngressCtrlCountVar, $PrometheusSvrCountVar, $IngressCtrlIpVar, $EmailVar, $LetsEncryptEnv, $IngressFqdnVar, $CertYamlVar, $EnvVar -join ' -var '
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
