output "network_self_link" {
    value = google_compute_network.vpc_network.self_link
}

output "controller_ip" {
    value = google_compute_instance.controller.*.network_interface.0.access_config.0.nat_ip
}

#output "worker_ip" {
#    value = google_compute_instance.worker.*.network_interface.0.access_config.0.nat_ip
#}

output "privkey" {
  value = local.privkey
  sensitive = false
}
output "packer_image_id" {
    value = data.hcp_packer_image.controller.id
}
output "packer_image_cloud_id" {
  value = data.hcp_packer_image.controller.cloud_image_id
}