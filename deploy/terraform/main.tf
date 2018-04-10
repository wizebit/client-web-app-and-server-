provider "google" {
  region = "${var.region}"
  project = "${var.project_name}"
  credentials = "${file(var.account_file_path)}"
}

resource "google_compute_address" "www" {
  name = "wize-www-address"
}

resource "google_compute_target_pool" "www" {
  name = "wize-www-target-pool"
  instances = ["${google_compute_instance.www.*.self_link}"]
  health_checks = ["${google_compute_http_health_check.http.name}"]
}

resource "google_compute_forwarding_rule" "http" {
  name = "wize-www-http-forwarding-rule"
  target = "${google_compute_target_pool.www.self_link}"
  ip_address = "${google_compute_address.www.address}"
  port_range = "80"
}

resource "google_compute_forwarding_rule" "https" {
  name = "wize-www-https-forwarding-rule"
  target = "${google_compute_target_pool.www.self_link}"
  ip_address = "${google_compute_address.www.address}"
  port_range = "443"
}

resource "google_compute_http_health_check" "http" {
  name = "wize-www-http-basic-check"
  request_path = "/"
  check_interval_sec = 1
  healthy_threshold = 1
  unhealthy_threshold = 10
  timeout_sec = 1
}
#########################################
# MASTER server part of the www cluster
#########################################
resource "google_compute_instance" "www" {
  count = 1
  name = "wizebit-master-${count.index}"
  machine_type = "g1-small"
  zone = "${var.region_zone}"
  tags = ["www-node"]
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "ubuntu-1604-lts"
    }
  }
  network_interface {
    network = "default"
    access_config {
      # Ephemeral
    }
  }
  service_account {
    scopes = ["https://www.googleapis.com/auth/compute.readonly"]
  }

  metadata_startup_script = <<SCRIPT

echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

SCRIPT

  # Copies the key file for bitbucket
  provisioner "file" {
    source      = "ssh/wize_web"
    destination = "~/wize_web"
    connection {
      user = "ubuntu"
      private_key = "${file("~/.ssh/id_rsa")}"
      agent = "false"
    }
  }

  provisioner "file" {
    source      = "configs"
    destination = "/home/ubuntu"
    connection {
      user = "ubuntu"
      private_key = "${file("~/.ssh/id_rsa")}"
      agent = "false"
      //      timeout = "30s"
    }
  }

//  provisioner "file" {
//    source      = "configs/db.conf"
//    destination = "/home/ubuntu/db.conf"
//    connection {
//      user = "ubuntu"
//      private_key = "${file("~/.ssh/id_rsa")}"
//      agent = "false"
//      //      timeout = "30s"
//    }
//  }

  provisioner "remote-exec" {
    script = "scripts/init.sh"
    connection {
      user = "ubuntu"
      private_key = "${file("~/.ssh/id_rsa")}"
      agent = "false"
      //      timeout = "30s"
    }
  }
  metadata {
    sshKeys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

#########################################
#SLAVE servers
#########################################


resource "google_compute_instance" "slave" {
  count = 2
  name = "wize-slave-${count.index}"
  machine_type = "f1-micro"
  zone = "${var.region_zone}"
  tags = ["slave"]

  boot_disk {
    initialize_params {
      image = "ubuntu-1604-lts"
    }
  }
  network_interface {
    network = "default"
    access_config {
      # Ephemeral
    }
  }
  service_account {
    scopes = ["https://www.googleapis.com/auth/compute.readonly"]
  }

  metadata_startup_script = <<SCRIPT

echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

SCRIPT

  # Copies the key file for bitbucket
  provisioner "file" {
    source      = "ssh/wize_web"
    destination = "~/wize_web"
    connection {
      user = "ubuntu"
      private_key = "${file("~/.ssh/id_rsa")}"
      agent = "false"
      //      timeout = "30s"
    }
  }

  provisioner "remote-exec" {
    script = "scripts/init.sh"
    connection {
      user = "ubuntu"
      private_key = "${file("~/.ssh/id_rsa")}"
      agent = "false"
      //      timeout = "30s"
    }
  }
  metadata {
    sshKeys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}
#######################################


resource "google_compute_firewall" "www" {
  name = "wize-www-firewall"
  network = "default"

  allow {
    protocol = "tcp"
    ports = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags = ["www-node"]
}

