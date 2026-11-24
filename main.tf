# 1. Generate the Image Factory schematic ID from human-readable extension names
resource "talos_image_factory_schematic" "longhorn" {
  schematic = yamlencode({
    customization = {
      systemExtensions = {
        officialExtensions = [
          "siderolabs/iscsi-tools",
          "siderolabs/util-linux-tools",
          "siderolabs/qemu-guest-agent",
        ]
      }
    }
  })
}

module "talos" {
  source  = "bbtechsys/talos/proxmox"
  version = "1.4.0"

  talos_cluster_name = "homelab-k8s"
  talos_version      = var.talos_version
  talos_schematic_id = talos_image_factory_schematic.longhorn.id

  proxmox_image_datastore = var.proxmox_image_datastore
  proxmox_network_bridge  = var.proxmox_network_bridge
  proxmox_vm_type         = "host"

  control_nodes = {
    "test-talos-cp-0" = var.proxmox_datacenter
    "test-talos-cp-1" = var.proxmox_datacenter
    "test-talos-cp-2" = var.proxmox_datacenter
  }

  proxmox_control_vm_cores     = var.control_plane_cores
  proxmox_control_vm_memory    = var.control_plane_memory
  proxmox_control_vm_disk_size = var.control_plane_disk_size

  worker_nodes = {
    "test-talos-worker-0" = var.proxmox_datacenter
    "test-talos-worker-1" =  var.proxmox_datacenter
    "test-talos-worker-2" = var.proxmox_datacenter
  }

  proxmox_worker_vm_cores     = var.worker_node_cores
  proxmox_worker_vm_memory    = var.worker_node_memory
  proxmox_worker_vm_disk_size = var.worker_node_disk_size

  wait_for_cluster_health = var.wait_for_cluster_health

  worker_machine_config_patches = [
    yamlencode({
      machine = {
        install = {
          disk = "/dev/vda"
        }
        kubelet = {
          extraMounts = [
            {
              destination = "/var/lib/longhorn"
              type        = "bind"
              source      = "/var/lib/longhorn"
              options     = ["bind", "rshared", "rw"]
            },
            {
              destination = "/var/lib/iscsi"
              type        = "bind"
              source      = "/var/lib/iscsi"
              options     = ["bind", "rshared", "rw"]
            }
          ]
        }
      }
    })
  ]

  control_machine_config_patches = [
    yamlencode({
      machine = {
        install = {
          disk = "/dev/vda"
        }
      }
    }),
    yamlencode({
      cluster = {
        inlineManifests = [
          {
            name = "argocd-namespace"
            contents = yamlencode({
              apiVersion = "v1"
              kind       = "Namespace"
              metadata = {
                name = "argocd"
              }
            })
          },
          {
            name = "longhorn-namespace"
            contents = yamlencode({
              apiVersion = "v1"
              kind       = "Namespace"
              metadata = {
                name = "longhorn-system"
                labels = {
                  "pod-security.kubernetes.io/enforce" = "privileged"
                  "pod-security.kubernetes.io/audit"   = "privileged"
                  "pod-security.kubernetes.io/warn"    = "privileged"
                }
              }
            })
          }
        ]
      }
    })
  ]
}

provider "helm" {
  kubernetes {
    host                   = yamldecode(module.talos.kubeconfig).clusters[0].cluster.server
    client_certificate     = base64decode(yamldecode(module.talos.kubeconfig).users[0].user["client-certificate-data"])
    client_key             = base64decode(yamldecode(module.talos.kubeconfig).users[0].user["client-key-data"])
    cluster_ca_certificate = base64decode(yamldecode(module.talos.kubeconfig).clusters[0].cluster["certificate-authority-data"])
  }
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = false
  version          = "10.18.2"
  wait             = true
  timeout          = 600

  values = [
    yamlencode({
      configs = {
        params = {
          "server.insecure" = true
        }
      }
    })
  ]

  depends_on = [module.talos]
}