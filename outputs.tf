output "network_self_link" {
    value = google_compute_network.vpc_network.self_link
}

output "controller_ip" {
    value = google_compute_instance.controller.*.network_interface.0.access_config.0.nat_ip
}

output "worker_ip" {
    value = google_compute_instance.worker.*.network_interface.0.access_config.0.nat_ip
}
