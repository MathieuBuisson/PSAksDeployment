@{
    <#
    The name of the Azure subscription where the AKS instance (and other Azure resources) will be deployed.
    Type : String
    Valid values : {SubscriptionValidValues}
    #>
    Subscription = {SubscriptionDefaultValue}

    <#
    The Azure region where the AKS cluster (and other Azure resources) will be deployed.
    Type : String
    Valid values : {ClusterLocationValidValues}
    #>
    ClusterLocation = {ClusterLocationDefaultValue}

    <#
    The Azure region where the Log Analytics workspace will be deployed.
    This might not be possible to provision the Log Analytics workspace in the same region as the AKS cluster, because Log Analytics is available in a limited set of regions.
    Type : String
    Valid values : {LogAnalyticsWorkspaceLocationValidValues}
    #>
    LogAnalyticsWorkspaceLocation = {LogAnalyticsWorkspaceLocationDefaultValue}

    <#
    {ServicePrincipalIDDescription}
    Type : {ServicePrincipalIDValueType}
    Valid values : {ServicePrincipalIDValidValues}
    #>
    ServicePrincipalID = {ServicePrincipalIDDefaultValue}

    <#
    {ServicePrincipalSecretDescription}
    Type : {ServicePrincipalSecretValueType}
    Valid values : {ServicePrincipalSecretValidValues}
    #>
    ServicePrincipalSecret = {ServicePrincipalSecretDefaultValue}

    <#
    {AzureTenantIDDescription}
    Type : {AzureTenantIDValueType}
    Valid values : {AzureTenantIDValidValues}
    #>
    AzureTenantID = {AzureTenantIDDefaultValue}

    <#
    {ClusterNameDescription}
    Type : {ClusterNameValueType}
    Valid values : {ClusterNameValidValues}
    #>
    ClusterName = {ClusterNameDefaultValue}

    <#
    {KubernetesVersionDescription}
    Type : {KubernetesVersionValueType}
    Valid values : {KubernetesVersionValidValues}
    #>
    KubernetesVersion = {KubernetesVersionDefaultValue}

    <#
    {NodeCountDescription}
    Type : {NodeCountValueType}
    Valid values : {NodeCountValidValues}
    #>
    NodeCount = {NodeCountDefaultValue}

    <#
    {NodeSizeDescription}
    Type : {NodeSizeValueType}
    Valid values : {NodeSizeValidValues}
    #>
    NodeSize = {NodeSizeDefaultValue}

    <#
    {OSDiskSizeGBDescription}
    Type : {OSDiskSizeGBValueType}
    Valid values : {OSDiskSizeGBValidValues}
    #>
    OSDiskSizeGB = {OSDiskSizeGBDefaultValue}

    <#
    {MaxPodsPerNodeDescription}
    Type : {MaxPodsPerNodeValueType}
    Valid values : {MaxPodsPerNodeValidValues}
    #>
    MaxPodsPerNode = {MaxPodsPerNodeDefaultValue}

    <#
    {EnvironmentDescription}
    Type : {EnvironmentValueType}
    Valid values : {EnvironmentValidValues}
    #>
    Environment = {EnvironmentDefaultValue}

    <#
    {LetsEncryptEmailDescription}
    Type : {LetsEncryptEmailValueType}
    Valid values : {LetsEncryptEmailValidValues}
    #>
    LetsEncryptEmail = {LetsEncryptEmailDefaultValue}

    <#
    {TerraformOutputFolderDescription}
    Type : {TerraformOutputFolderValueType}
    Valid values : {TerraformOutputFolderValidValues}
    #>
    TerraformOutputFolder = {TerraformOutputFolderDefaultValue}
}