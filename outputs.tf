output "kubeconfig" {
  description = "Kubernetes client configuration"
  value       = module.talos.kubeconfig
  sensitive   = true
}

output "talos_config" {
  description = "Talos client configuration"
  value       = module.talos.talos_config
  sensitive   = true
}

output "traefik_ip" {
  description = "Assigned MetalLB IP address for the Traefik ingress controller"
  value       = local.traefik_ip
}