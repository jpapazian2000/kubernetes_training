terraform {
    required_providers {
      google = {
          source = "hashicorp/google"
          version = "~>3.5"
      }
      hcp = {
      source  = "hashicorp/hcp"
      version = "0.43.0"
      }
    }
}

provider "google" {
  project = var.google_project
  region = var.google_region
  zone = var.google_zone
}
provider "hcp" {
}

resource "tls_private_key" "controller_priv_key" {
  algorithm = "RSA"
  rsa_bits = 4096
}
data "hcp_packer_iteration" "gold" {
    bucket_name = "k8s-controller-images"
    channel = "prod"
}
data "hcp_packer_image" "controller" {
    bucket_name = "k8s-controller-images"
    iteration_id = data.hcp_packer_iteration.gold.id
    cloud_provider = "gce"
    region = "europe-west9-a"
}

data "tls_public_key" "controller" {
  private_key_openssh = tls_private_key.controller_priv_key.private_key_openssh
}
locals {
  privkey = nonsensitive(tls_private_key.controller_priv_key.private_key_openssh)
  pubkey = tls_private_key.controller_priv_key.public_key_openssh
  }

resource "google_compute_network" "vpc_network" {
    name = "${var.prefix}-vpc"
    auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "vpc_subnetwork" {
    name = "${var.prefix}-subnet"
    region = var.google_region
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

#resource "google_compute_firewall" "https_access" {
#  name = "${var.prefix}-allow-https"
#  network = google_compute_network.vpc_network.self_link
#
#  allow {
#    protocol = "tcp"
#    ports = ["443"]
#  }
#
#  source_ranges = [var.allowed_ip]
#  source_tags = ["https-access"]
#}
#
#resource "google_compute_firewall" "controller_access" {
#  name = "${var.prefix}-allow-controller"
#  network = google_compute_network.vpc_network.self_link
#
#  allow {
#    protocol = "tcp"
#    ports = ["2379", "2380", "10250", "10259", "10257", "6443"]
#  }
#
#  source_ranges = [var.allowed_ip]
#  source_tags = ["controller-access"]
#}
#
#resource "google_compute_firewall" "worker_access" {
#  name = "${var.prefix}-allow-worker"
#  network = google_compute_network.vpc_network.self_link
#
#  allow {
#    protocol = "tcp"
#    ports = ["10250"]
#  }
#
#  source_tags = ["worker-access"]
#}
#
#resource "google_compute_firewall" "ext-worker_access" {
#  name = "${var.prefix}-allow-ext-worker"
#  network = google_compute_network.vpc_network.self_link
#
#  allow {
#    protocol = "tcp"
#    ports = ["30000-32767"]
#  }
#
#  source_ranges = [var.allowed_ip]
#  source_tags = ["worker-access"]
#}
#
#resource "google_compute_firewall" "api-serverr_access" {
#  name = "${var.prefix}-allow-api-server"
#  network = google_compute_network.vpc_network.self_link
#
#  allow {
#    protocol = "tcp"
#    ports = ["6443"]
#  }
#
#  source_ranges = [var.allowed_ip]
#  source_tags = ["api-server-access"]
#}
resource "google_compute_firewall" "allow_all" {
  name = "${var.prefix}-allow-all"
  network = google_compute_network.vpc_network.self_link

  allow {
    protocol = "tcp"
    #ports = ["6443"]
  }

  source_ranges = ["0.0.0.0/0"]
  source_tags = ["allow-all"]
}

resource "google_compute_instance" "controller" {
    count = 1
    #name = "${var.prefix}-controller-${count.index + 1}"
    name = "k8scp"
    zone = "${var.google_region}-a"
    machine_type = var.machine_type
    #hostname = "controller-${count.index +1}"

    boot_disk {
        initialize_params {
            #image = "ubuntu-2004-lts"
            image = data.hcp_packer_image.controller.cloud_image_id
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
    #tags = ["worker-access", "https-access", "ssh-access", "api-server-access"]
    tags = ["ssh-access", "allow-all"]


    metadata = {
        sshKeys = "${var.ssh_user}:${local.pubkey}"
    }
    connection {
        type = "ssh"
        user = var.ssh_user
        host = google_compute_subnetwork.vpc_subnetwork.self_link
        timeout = "300s"
        private_key = local.privkey
    }

    provisioner "file" {
        source = "script.sh"
        destination = "/tmp/script.sh"
    }

    provisioner "remote-exec" {
        inline = [
            "sudo chmod +x /tmp/script.sh",
            "sudo /tmp/script.sh",
            "sudo kubeadm init --config=/root/kubeadm-config.yaml --upload-certs | sudo tee /root/kubeadm init.out",
            "mkdir -p $HOME/.kube",
            "sudo cp -i /etc/kubernetes.admin.conf $HOME/.kube/config",
            "sudo chown $(id -u):$(id -g) $HOME/.kube/config",
            "sudo cp /root/calico.yaml .",
            "#kubectl apply -f calico.yaml"
            ]
        }  
}
#resource "google_compute_instance" "worker" {
    #count = 1
    ##name = "${var.prefix}-worker-${count.index + 1}"
    #name ="worker"
    #zone = "${var.google_region}-a"
    #machine_type = var.machine_type
    ##hostname = "worker-${count.index +1}"
#
    #boot_disk {
        #initialize_params {
            #image = "ubuntu-2004-lts"
        #}
    #}
#
    #labels = {
        #owner = var.owner
        #se-region = var.se-region
        #purpose = var.purpose
        #ttl = var.ttl
        #terraform = var.terraform
        #hc-internet-facing = var.hc-internet-facing
#
    #}
    #network_interface {
        #subnetwork = google_compute_subnetwork.vpc_subnetwork.self_link
        #access_config {
        #}
    #}
    ##tags = ["controller-access", "https-access", "ssh-access", "api-server-access"]
    #tags = ["ssh-access", "allow-all"]
#
    #metadata = {
        #sshKeys = "${var.ssh_user}:${var.ssh_keys}"
    #}
#    
#}



