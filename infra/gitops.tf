# ---------------------------------------------------------------------------
# GitOps bootstrap. Terraform installs only ArgoCD and one "root" Application.
# Everything else in the cluster (monitoring, apps) is declared in gitops/
# and reconciled by ArgoCD, so cluster state changes go through pull requests.
# ---------------------------------------------------------------------------

resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = "argocd"
  create_namespace = true

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_chart_version

  wait    = true
  timeout = 600

  values = [file("${path.module}/values/argocd.yaml")]

  depends_on = [module.eks]
}

resource "helm_release" "root_app" {
  name      = "root-app"
  namespace = "argocd"

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version    = var.argocd_apps_chart_version

  values = [
    yamlencode({
      applications = {
        root = {
          namespace = "argocd"
          project   = "default"
          finalizers = [
            "resources-finalizer.argocd.argoproj.io",
          ]
          source = {
            repoURL        = var.gitops_repo_url
            targetRevision = var.gitops_revision
            path           = "gitops/apps"
          }
          destination = {
            server    = "https://kubernetes.default.svc"
            namespace = "argocd"
          }
          syncPolicy = {
            automated = {
              prune    = true
              selfHeal = true
            }
          }
        }
      }
    })
  ]

  depends_on = [helm_release.argocd]
}
