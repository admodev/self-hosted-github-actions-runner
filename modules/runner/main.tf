resource "kubernetes_namespace" "github-runner" {
  metadata {
    name = "github-runner"
  }
}

resource "kubernetes_secret" "gh-pat" {
  metadata {
    name = "gh-pat"
  }

  data = {
    "pat" = var.ghapat
  }

  type = "generic"
}

resource "kubernetes_service_account_v1" "gr-sa" {
  metadata {
    name      = "gr-sa"
    namespace = "gr-sa"
  }
}

resource "kubernetes_cluster_role_v1" "pod-handler" {
  metadata {
    name = "pod-handler"
  }

  rule {
    api_groups = ["apps"]
    resources  = ["pods", "deployments"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }
}

resource "kubernetes_cluster_role_binding_v1" "pod-handler-binding" {
  metadata {
    name = "pod-handler-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "pod-handler"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "gr-sa"
    namespace = kubernetes_namespace.github-runner.metadata.0.name
  }
}

resource "kubernetes_deployment" "github-runner" {
  metadata {
    name      = "github-runner"
    namespace = kubernetes_namespace.github-runner.metadata.0.name
    labels = {
      test = "GitHubRunner"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        test = "GitHubRunner"
      }
    }

    template {
      metadata {
        labels = {
          test = "GitHubRunner"
        }
      }

      spec {
        container {
          image = "sanderknape/github-runner:latest"
          name  = "github-runner"

          env {
            name  = "GITHUB_OWNER"
            value = "admodev"
          }

          env {
            name  = "GITHUB_REPOSITORY"
            value = "github-actions-series"
          }

          env {
            name  = "RUNNER_LABELS"
            value = "self-hosted-runner"
          }

          env {
            name = "GITHUB_PAT"
            value_from {
              secret_key_ref {
                name = "gh-pat"
                key  = "pat"
              }
            }
          }

          resources {
            limits = {
              cpu    = "2"
              memory = "800Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
        }
      }
    }
  }
}
