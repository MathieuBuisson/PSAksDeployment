$ModuleName = 'PSAksDeployment'
Import-Module "$PSScriptRoot\..\..\$ModuleName\$($ModuleName).psd1" -Force

Describe 'Kubernetes cluster' {

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

Describe 'Prometheus' {

    It 'Status of release [prometheus] is "DEPLOYED"' {
        $PrometheusStatus = ConvertFrom-Json (helm status prometheus -o json)
        $PrometheusStatus.info.status.code | Should -Be 1
    }
    It 'Has pod(s) for the server component' {
        & kubectl get pods -n management -l "app=prometheus,component=server" -o jsonpath="{.items[0].metadata.name}" |
        Should -Not -BeNullOrEmpty
    }
    It 'Has a pod(s) for the pushgateway component' {
        & kubectl get pods -n management -l "app=prometheus,component=pushgateway" -o jsonpath="{.items[0].metadata.name}" |
            Should -Not -BeNullOrEmpty
    }
    It 'Has a pod(s) for the alertmanager component' {
        & kubectl get pods -n management -l "app=prometheus,component=alertmanager" -o jsonpath="{.items[0].metadata.name}" |
            Should -Not -BeNullOrEmpty
    }
    It 'Has a service for the server component' {
        & kubectl get svc -n management -l "app=prometheus,component=server" -o jsonpath="{.items[0].metadata.name}" |
            Should -Not -BeNullOrEmpty
    }
    It 'Has a service for the pushgateway component' {
        & kubectl get svc -n management -l "app=prometheus,component=pushgateway" -o jsonpath="{.items[0].metadata.name}" |
            Should -Not -BeNullOrEmpty
    }
    It 'Has a service for the alertmanager component' {
        & kubectl get svc -n management -l "app=prometheus,component=alertmanager" -o jsonpath="{.items[0].metadata.name}" |
            Should -Not -BeNullOrEmpty
    }
    It "Has a stateful set for the server component's pods" {
        (& kubectl get statefulset -n management -l "app=prometheus,component=server" -o json | ConvertFrom-Json).items |
            Where-Object kind -eq StatefulSet | Should -Not -BeNullOrEmpty
    }
    It 'Has all persistent volume claims for the server component successfully bound' {
        $ServerPvcs = (& kubectl get pvc -n management -l "app=prometheus,component=server" -o json | ConvertFrom-Json)
        Foreach ($Pvc in $ServerPvcs.items) {
            $Pvc.status.phase | Should -Be 'Bound'
        }
    }
}

Describe 'Grafana'{

    It 'Status of release [grafana] is "DEPLOYED"' {
        $GrafanaStatus = ConvertFrom-Json (helm status grafana -o json)
        $GrafanaStatus.info.status.code | Should -Be 1
    }
    It 'Has pod(s) for grafana' {
        & kubectl get pods -n management -l "app=grafana" -o jsonpath="{.items[0].metadata.name}" |
            Should -Not -BeNullOrEmpty
    }
    It 'Has a service for grafana' {
        & kubectl get svc -n management -l "app=grafana" -o jsonpath="{.items[0].metadata.name}" |
            Should -Not -BeNullOrEmpty
    }
    It 'Has all persistent volume claim for Grafana successfully bound' {
        $GrafanaPvcs = (& kubectl get pvc -n management -l "app=grafana" -o json | ConvertFrom-Json)
        Foreach ($Pvc in $GrafanaPvcs.items) {
            $Pvc.status.phase | Should -Be 'Bound'
        }
    }
}
