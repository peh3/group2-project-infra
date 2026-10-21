################################################################################
# 1. Monitoring Namespace
################################################################################
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }

  depends_on = [module.eks]
}

################################################################################
# 2. cert-manager (Automated TLS)
################################################################################
resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "v1.16.1"
  namespace        = "cert-manager"
  create_namespace = true

  timeout         = 900
  cleanup_on_fail = true

  depends_on = [module.eks]

  set {
    name  = "crds.enabled"
    value = "true"
  }
}

################################################################################
# 3. Observability: kube-prometheus-stack (Prometheus + Grafana)
################################################################################
resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "65.5.0"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  timeout         = 900
  cleanup_on_fail = true

  depends_on = [
    module.eks,
    kubernetes_namespace.monitoring
  ]

  set_sensitive {
    name  = "grafana.adminPassword"
    value = "AdminSecurePass2026!"
  }

  set {
    name  = "grafana.persistence.enabled"
    value = "true"
  }

  set {
    name  = "grafana.persistence.size"
    value = "10Gi"
  }

  set {
    name  = "prometheus.prometheusSpec.retention"
    value = "14d"
  }

  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.accessModes[0]"
    value = "ReadWriteOnce"
  }

  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage"
    value = "20Gi"
  }
}

################################################################################
# 4. NGINX Ingress Controller
################################################################################
resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.11.3"
  namespace        = "ingress-nginx"
  create_namespace = true

  timeout         = 900
  cleanup_on_fail = true

  # Must wait for kube-prometheus-stack to install the ServiceMonitor CRD
  depends_on = [
    module.eks,
    kubernetes_namespace.monitoring,
    helm_release.kube_prometheus_stack
  ]

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-scheme"
    value = "internet-facing"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
    value = "external"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-nlb-target-type"
    value = "ip"
  }

  set {
    name  = "controller.metrics.enabled"
    value = "true"
  }

  set {
    name  = "controller.metrics.serviceMonitor.enabled"
    value = "true"
  }

  set {
    name  = "controller.metrics.serviceMonitor.namespace"
    value = kubernetes_namespace.monitoring.metadata[0].name
  }
}

################################################################################
# 5. ExternalDNS (Automated Route 53 Records)
################################################################################
resource "helm_release" "external_dns" {
  name             = "external-dns"
  repository       = "https://kubernetes-sigs.github.io/external-dns/"
  chart            = "external-dns"
  version          = "1.15.0"
  namespace        = "external-dns"
  create_namespace = true

  timeout         = 600
  cleanup_on_fail = true

  depends_on = [module.eks]

  set {
    name  = "provider"
    value = "aws"
  }

  set {
    name  = "aws.zoneType"
    value = "public"
  }

  set {
    name  = "zoneIdFilters[0]"
    value = "Z00541411T1NGPV97B5C0"
  }

  set {
    name  = "domainFilters[0]"
    value = "sctp-sandbox.com"
  }

  set {
    name  = "policy"
    value = "sync"
  }

  set {
    name  = "registry"
    value = "txt"
  }

  set {
    name  = "txtOwnerId"
    value = "tk-tf-cluster"
  }
}

################################################################################
# 6. Kyverno (Policy Engine & Security Governance)
################################################################################
resource "helm_release" "kyverno" {
  name             = "kyverno"
  repository       = "https://kyverno.github.io/kyverno/"
  chart            = "kyverno"
  version          = "3.3.4"
  namespace        = "kyverno"
  create_namespace = true

  timeout         = 600
  cleanup_on_fail = true

  depends_on = [module.eks]

  set {
    name  = "admissionController.replicas"
    value = "1" # Set to 3 for multi-AZ HA production
  }
}

################################################################################
# 7. Loki (Log Storage Backend)
################################################################################
resource "kubernetes_namespace" "loki" {
  metadata {
    name = "loki"
  }

  depends_on = [module.eks]
}

resource "helm_release" "loki" {
  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  version    = "6.24.0"
  namespace  = kubernetes_namespace.loki.metadata[0].name

  timeout         = 900
  cleanup_on_fail = true

  depends_on = [
    module.eks,
    kubernetes_namespace.loki
  ]

  # Single-binary mode is recommended for demo / lightweight dev clusters
  set {
    name  = "deploymentMode"
    value = "SingleBinary"
  }

  set {
    name  = "singleBinary.replicas"
    value = "1"
  }

  set {
    name  = "singleBinary.persistence.size"
    value = "20Gi"
  }
}

################################################################################
# 8. Promtail (Node Log Shipper to Loki)
################################################################################
resource "helm_release" "promtail" {
  name       = "promtail"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "promtail"
  version    = "6.16.6"
  namespace  = kubernetes_namespace.loki.metadata[0].name

  timeout         = 600
  cleanup_on_fail = true

  depends_on = [
    module.eks,
    helm_release.loki
  ]

  # Point directly to the internal Loki cluster service
  set {
    name  = "config.clients[0].url"
    value = "http://loki.loki.svc.cluster.local:3100/loki/api/v1/push"
  }
}

################################################################################
# 9. Trivy Operator (Container Vulnerability Scanner)
################################################################################
resource "helm_release" "trivy_operator" {
  name             = "trivy-operator"
  repository       = "https://aquasecurity.github.io/helm-charts/"
  chart            = "trivy-operator"
  version          = "0.25.0"
  namespace        = "trivy-system"
  create_namespace = true

  timeout         = 600
  cleanup_on_fail = true

  depends_on = [module.eks]

  set {
    name  = "trivy.ignoreUnfixed"
    value = "true"
  }
}