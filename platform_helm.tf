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