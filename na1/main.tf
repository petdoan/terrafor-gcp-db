variable "ssh_public_key_filepath" {
  description = "Filepath for the ssh public key"
  type = "string"

  default = "tfuser.pub"
}

variable "ssh_private_key_filepath" {
  description = "Filepath for the ssh private key"
  type = "string"

  default = "tfuser"
}

variable "region" {
  default = "us-west1"
}
variable "node_count" {
  default = "1"
}
variable "image_url" {
  default = "rhel-cloud/rhel-7"
}
variable "machine_type" {
  default = "n1-standard-2"
}
variable "pod_name" {
  default = "na1"
}

data "google_compute_zones" "available" {}

resource "google_compute_instance" "database" {
  count = "${var.node_count}"
  name = "${var.pod_name}-db${count.index + 1}-1"
  machine_type = "${var.machine_type}"
  zone = "${element(data.google_compute_zones.available.names, count.index)}"
  tags = ["db"]

  boot_disk {
    initialize_params {
      image = "${var.image_url}"
      size = 100
    }
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral IP
    }
  }

  service_account {
    scopes = ["userinfo-email", "compute-rw", "storage-rw"]
  }

  metadata {
    sshKeys = "tfuser:${file(var.ssh_public_key_filepath)}"
  }
  
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "tfuser"
      timeout     = "500s"
      private_key = "${file(var.ssh_private_key_filepath)}"
    }

    inline = [
      "sudo mkdir -p /tmp/tarball",
      "cd /tmp/tarball",
      "sudo gsutil cp gs://oracle-tarball-bucket/* .",
      "sudo chmod +x /tmp/tarball/*.sh"
    ]
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "tfuser"
      timeout     = "500s"
      private_key = "${file(var.ssh_private_key_filepath)}"
    }

    inline = [
      "echo 'Run install_oracle.sh'",
      "sudo /tmp/tarball/install_oracle.sh"
    ]
  }

}
