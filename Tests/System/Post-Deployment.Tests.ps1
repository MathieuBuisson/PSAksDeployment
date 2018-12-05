$ModuleName = 'PSAksDeployment'
Import-Module "$PSScriptRoot\..\..\$ModuleName\$($ModuleName).psd1" -Force

Describe 'Kubernetes cluster' {

    It 'Testing failure' {
        $True | Should -BeFalse
    }
    It 'Has a [management] namespace' {
        & kubectl get namespace management | Select-Object -Last 1 |
            Should -Match '^management\s+Active\s+'
    }
    It 'Has a "tiller" ServiceAccount in the [kube-system] namespace' {
        & kubectl get sa tiller -n kube-system | Select-Object -Last 1 |
            Should -Match '^tiller\s+1\s+'
    }
    It 'Has a "tiller" ClusterRoleBinding' {
        & kubectl get ClusterRoleBinding tiller | Select-Object -Last 1 |
            Should -Match '^tiller\s+'
    }
    It 'Tiller ClusterRoleBinding assigns the role [cluster-admin] to service account [tiller]' {
        & kubectl get ClusterRoleBinding tiller -o=jsonpath="{.roleRef.name}" |
            Should -Be 'cluster-admin'
        & kubectl get ClusterRoleBinding tiller -o=jsonpath="{.subjects[*].name}" |
            Should -Match 'tiller'
    }
}

Describe 'Helm' {
    # Helm status code 1 means "DEPLOYED"
    # Source : https://github.com/helm/helm/blob/master/_proto/hapi/release/status.proto

    It 'Status of release [nginx-ingress] is "DEPLOYED"' {
        $NginxStatus = ConvertFrom-Json (helm status nginx-ingress -o json)
        $NginxStatus.info.status.code | Should -Be 1
    }
    It 'Status of release [cert-manager] is "DEPLOYED"' {
        $CertManagerStatus = ConvertFrom-Json (helm status cert-manager -o json)
        $CertManagerStatus.info.status.code | Should -Be 1
    }
    It 'Status of release [cluster-issuer] is "DEPLOYED"' {
        $ClusterIssuerStatus = ConvertFrom-Json (helm status cluster-issuer -o json)
        $ClusterIssuerStatus.info.status.code | Should -Be 1
    }
}

Describe 'Certificate' {

    It 'Has a certificate named [tls-secret] in the [management] namespace' {
        & kubectl get certificate tls-secret -n management | Select-Object -Last 1 |
            Should -Match '^tls-secret\s+'
    }
}

Describe 'Secret propagator' {
    
    It 'Status of release [secret-propagator] is "DEPLOYED"' {
        $PropagatorStatus = ConvertFrom-Json (helm status secret-propagator -o json)
        $PropagatorStatus.info.status.code | Should -Be 1
    }
    
    $Namespaces = & kubectl get namespace --field-selector="status.phase==Active" -o=jsonpath="{range .items[*]}{.metadata.name}{';'}{end}"
    $NamespaceArray = $Namespaces.TrimEnd(';') -split ';'

    Foreach ( $Namespace in $NamespaceArray ) {
        It "Has a secret named [tls-secret] in the [$Namespace] namespace" {
            & kubectl get secret tls-secret -n $Namespace | Select-Object -Last 1 |
                Should -Match '^tls-secret\s+kubernetes.io/tls\s+'
        }
    }
    Foreach ( $Namespace in $NamespaceArray ) {
        It "[tls-secret] has the label 'propagate-to-ns=true' in [$Namespace]" {
            & kubectl get secret tls-secret -n $Namespace -o=jsonpath="{.metadata.labels}" |
                Should -Match 'propagate-to-ns:\s*true'
        }
    }
}
