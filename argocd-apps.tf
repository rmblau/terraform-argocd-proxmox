locals {
  metallb_first_ip = strcontains(var.metallb_ip_range, "-") ? trimspace(split("-", var.metallb_ip_range)[0]) : cidrhost(var.metallb_ip_range, 1)
  traefik_ip       = coalesce(var.traefik_ip, local.metallb_first_ip)
}

resource "kubectl_manifest" "argocd_metallb" {
  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "metallb"
      namespace = "argocd"
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://metallb.github.io/metallb"
        chart          = "metallb"
        targetRevision = "*"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "metallb-system"
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = [
          "CreateNamespace=true",
        ]
        managedNamespaceMetadata = {
          labels = {
            "pod-security.kubernetes.io/enforce" = "privileged"
            "pod-security.kubernetes.io/audit"   = "privileged"
            "pod-security.kubernetes.io/warn"    = "privileged"
          }
        }
      }
    }
  })

  depends_on = [helm_release.argocd]
}

resource "kubectl_manifest" "argocd_metallb_config" {
  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "metallb-config"
      namespace = "argocd"
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://bedag.github.io/helm-charts"
        chart          = "raw"
        targetRevision = "*"
        helm = {
          valuesObject = {
            resources = [
              {
                apiVersion = "metallb.io/v1beta1"
                kind       = "IPAddressPool"
                metadata = {
                  name      = "default-pool"
                  namespace = "metallb-system"
                }
                spec = {
                  addresses = [
                   var.metallb_ip_range,
                  ]
                }
              },
              {
                apiVersion = "metallb.io/v1beta1"
                kind       = "L2Advertisement"
                metadata = {
                  name      = "default-l2"
                  namespace = "metallb-system"
                }
                spec = {
                  ipAddressPools = [
                    "default-pool",
                  ]
                }
              },
            ]
          }
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "metallb-system"
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
      }
    }
  })

  depends_on = [kubectl_manifest.argocd_metallb]
}

resource "kubectl_manifest" "argocd_traefik" {
  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "traefik"
      namespace = "argocd"
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://traefik.github.io/charts"
        chart          = "traefik"
        targetRevision = "*"
        helm = {
          valuesObject = {
            service = {
              annotations = {
                "metallb.universe.tf/loadBalancerIPs" = local.traefik_ip
              }
            }
            providers = {
              kubernetesCRD = {
                enabled = true
              }
              kubernetesIngress = {
                enabled = true
              }
            }
          }
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "traefik"
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = [
          "CreateNamespace=true",
        ]
      }
    }
  })

  depends_on = [kubectl_manifest.argocd_metallb_config]
}

resource "kubectl_manifest" "argocd_seaweedfs" {
  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "seaweedfs"
      namespace = "argocd"
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://seaweedfs.github.io/seaweedfs/helm"
        chart          = "seaweedfs"
        targetRevision = "*"
        helm = {
          valuesObject = {
            global = {
              enableReplication    = true
              replicationPlacement = "001"
            }
            master = {
              enabled           = true
              replicas          = 3
              volumeSizeLimitMB = 1024
              data = {
                type           = "hostPath"
                hostPathPrefix = "/var/mnt/seaweedfs"
              }
              logs = {
                type = "emptyDir"
              }
            }
            volume = {
              enabled  = true
              replicas = 3
              dataDirs = [
                {
                  name           = "data1"
                  type           = "hostPath"
                  hostPathPrefix = "/var/mnt/seaweedfs"
                  maxVolumes     = 0
                },
              ]
              idx = {
                type           = "hostPath"
                hostPathPrefix = "/var/mnt/seaweedfs"
              }
              logs = {
                type = "emptyDir"
              }
            }
            filer = {
              enabled  = true
              replicas = 2
              data = {
                type           = "hostPath"
                hostPathPrefix = "/var/mnt/seaweedfs"
              }
              logs = {
                type = "emptyDir"
              }
            }
          }
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "seaweedfs"
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = [
          "CreateNamespace=true",
        ]
        managedNamespaceMetadata = {
          labels = {
            "pod-security.kubernetes.io/enforce" = "privileged"
            "pod-security.kubernetes.io/audit"   = "privileged"
            "pod-security.kubernetes.io/warn"    = "privileged"
          }
        }
      }
    }
  })

  depends_on = [helm_release.argocd]
}

resource "kubectl_manifest" "argocd_seaweedfs_csi" {
  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "seaweedfs-csi-driver"
      namespace = "argocd"
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://seaweedfs.github.io/seaweedfs-csi-driver/helm"
        chart          = "seaweedfs-csi-driver"
        targetRevision = "*"
        helm = {
          valuesObject = {
            seaweedfsFiler = "seaweedfs-filer.seaweedfs.svc.cluster.local:8888"
            storageClass = {
              create               = true
              name                 = "seaweedfs-storage"
              reclaimPolicy        = "Delete"
              allowVolumeExpansion = true
              isDefaultClass       = false
            }
          }
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "seaweedfs"
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = [
          "CreateNamespace=true",
        ]
      }
    }
  })

  depends_on = [kubectl_manifest.argocd_seaweedfs]
}