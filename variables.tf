variable "proxmox_datacenter" {
  description = "Proxmox datacenter to create Talos VMs in"
  type        = string
  default     = "pve"
}
variable "proxmox_password" {
  description = "Proxmox password for the root user"
  type        = string
  sensitive   = true
}
variable "proxmox_network_bridge" {
  description = "Proxmox network bridge to attach Talos VM network interfaces to"
  type        = string
  default     = "vmbr2"
}

variable "proxmox_image_datastore" {
  description = "Proxmox datastore to store Talos VM images"
  type        = string
  default     = "brom"
}
variable "talos_version" {
  description = "Talos version to deploy"
  type        = string
  default     = "1.14.6"
}
variable "control_plane_cores" {
  description = "Number of CPU cores for each Talos VM"
  type        = number
  default     = 4
}
variable "control_plane_memory" {
  description = "Amount of RAM (in MiB) for each Talos VM"
  type        = number
  default     = 16384
}

variable "control_plane_disk_size" {
  description = "Disk size (in GiB) for each Talos VM"
  type        = number
  default     = 32
}

variable "worker_node_cores" {
  description = "Number of CPU cores for each Talos VM"
  type        = number
  default     = 4
}
variable "worker_node_memory" {
  description = "Amount of RAM (in MiB) for each Talos VM"
  type        = number
  default     = 32768
}
variable "worker_node_disk_size" {
  description = "Disk size (in GiB) for each Talos VM"
  type        = number
  default     = 32
}

variable "wait_for_cluster_health" {
  description = "Wait for the Talos cluster to become healthy after provisioning"
  type        = bool
  default     = true
}

variable "metallb_ip_range" {
  description = "IP range for MetalLB to allocate from"
  type        = string
  default     =  "192.168.50.220-192.168.50.240"
}

variable "traefik_ip" {
  description = "Optional static IP for Traefik LoadBalancer (defaults to the first IP in metallb_ip_range)"
  type        = string
  default     = null
}