terraform {
    required_providers {
      google = {
          source = "hashicorp/google"
          version = "~>3.5"
      }
    }
}

provider "google" {
  project = var.project
  region = var.region
  zone = var.zone
}

resource "google_compute_network" "vpc_network" {
    name = "${var.prefix}-vpc"
    auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "vpc_subnetwork" {
    name = "${var.prefix}-subnet"
    region = var.region
    network = google_compute_network.vpc_network.self_link
    ip_cidr_range = var.subnet_prefix
}

resource "google_compute_firewall" "ssh_access" {
  name = "${var.prefix}-allow-ssh"
  network = google_compute_network.vpc_network.self_link

  allow {
    protocol = "tcp"
    ports = ["22"]
  }

  source_ranges = [var.allowed_ip]
  source_tags = ["ssh-access"]
}

resource "google_compute_firewall" "https_access" {
  name = "${var.prefix}-allow-https"
  network = google_compute_network.vpc_network.self_link

  allow {
    protocol = "tcp"
    ports = ["443"]
  }

  source_ranges = [var.allowed_ip]
  source_tags = ["https-access"]
}

resource "google_compute_firewall" "controller_access" {
  name = "${var.prefix}-allow-controller"
  network = google_compute_network.vpc_network.self_link

  allow {
    protocol = "tcp"
    ports = ["2379", "2380", "10250", "10259", "10257", "6443"]
  }

  source_ranges = [var.allowed_ip]
  source_tags = ["controller-access"]
}

resource "google_compute_firewall" "worker_access" {
  name = "${var.prefix}-allow-worker"
  network = google_compute_network.vpc_network.self_link

  allow {
    protocol = "tcp"
    ports = ["10250"]
  }

  source_tags = ["worker-access"]
}

resource "google_compute_firewall" "ext-worker_access" {
  name = "${var.prefix}-allow-ext-worker"
  network = google_compute_network.vpc_network.self_link

  allow {
    protocol = "tcp"
    ports = ["30000-32767"]
  }

  source_ranges = [var.allowed_ip]
  source_tags = ["worker-access"]
}

resource "google_compute_firewall" "api-serverr_access" {
  name = "${var.prefix}-allow-api-server"
  network = google_compute_network.vpc_network.self_link

  allow {
    protocol = "tcp"
    ports = ["6443"]
  }

  source_ranges = [var.allowed_ip]
  source_tags = ["api-server-access"]
}

resource "google_compute_instance" "controller" {
    count = 1
    #name = "${var.prefix}-controller-${count.index + 1}"
    name = "cp"
    zone = "${var.region}-a"
    machine_type = var.machine_type
    #hostname = "controller-${count.index +1}"

    boot_disk {
        initialize_params {
            image = "ubuntu-2004-lts"
        }
    }

    labels = {
        owner = var.owner
        se-region = var.se-region
        purpose = var.purpose
        ttl = var.ttl
        terraform = var.terraform
        hc-internet-facing = var.hc-internet-facing

    }
    network_interface {
        subnetwork = google_compute_subnetwork.vpc_subnetwork.self_link
        access_config {
        }
    }
    tags = ["worker-access", "https-access", "ssh-access", "api-server-access"]

    metadata = {
        sshKeys = "${var.ssh_user}:${var.ssh_keys}"
    }
}

resource "google_compute_instance" "worker" {
    count = 1
    #name = "${var.prefix}-worker-${count.index + 1}"
    name ="worker"
    zone = "${var.region}-a"
    machine_type = var.machine_type
    #hostname = "worker-${count.index +1}"

    boot_disk {
        initialize_params {
            image = "ubuntu-2004-lts"
        }
    }

    labels = {
        owner = var.owner
        se-region = var.se-region
        purpose = var.purpose
        ttl = var.ttl
        terraform = var.terraform
        hc-internet-facing = var.hc-internet-facing

    }
    network_interface {
        subnetwork = google_compute_subnetwork.vpc_subnetwork.self_link
        access_config {
        }
    }
    tags = ["controller-access", "https-access", "ssh-access", "api-server-access"]

    metadata = {
        sshKeys = "${var.ssh_user}:${var.ssh_keys}"
    }
}



