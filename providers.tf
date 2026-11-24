terraform {
  required_version = ">= 1.5.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.111.1"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.11.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.16.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.35.0"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.1.0"
    }
  }
}

provider "proxmox" {
  endpoint = "https://192.168.50.210:8006/"
  insecure = true
  username = "root@pam"
  password = var.proxmox_password
}

provider "kubernetes" {
  host                   = yamldecode(module.talos.kubeconfig).clusters[0].cluster.server
  client_certificate     = base64decode(yamldecode(module.talos.kubeconfig).users[0].user["client-certificate-data"])
  client_key             = base64decode(yamldecode(module.talos.kubeconfig).users[0].user["client-key-data"])
  cluster_ca_certificate = base64decode(yamldecode(module.talos.kubeconfig).clusters[0].cluster["certificate-authority-data"])
}

provider "kubectl" {
  host                   = yamldecode(module.talos.kubeconfig).clusters[0].cluster.server
  client_certificate     = base64decode(yamldecode(module.talos.kubeconfig).users[0].user["client-certificate-data"])
  client_key             = base64decode(yamldecode(module.talos.kubeconfig).users[0].user["client-key-data"])
  cluster_ca_certificate = base64decode(yamldecode(module.talos.kubeconfig).clusters[0].cluster["certificate-authority-data"])
  load_config_file       = false
}