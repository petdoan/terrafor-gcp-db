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

resource "google_compute_disk" "data-disk-1" {
    count = "${var.node_count}"
    name = "${var.pod_name}-data-1-${count.index}"
    type  = "pd-ssd"
    zone = "${element(data.google_compute_zones.available.names, count.index)}"
    size = "20"
}

resource "google_compute_disk" "data-disk-2" {
    count = "${var.node_count}"
    name = "${var.pod_name}-data-2-${count.index}"
    type  = "pd-ssd"
    zone = "${element(data.google_compute_zones.available.names, count.index)}"
    size = "20"
}

resource "google_compute_disk" "data-disk-3" {
    count = "${var.node_count}"
    name = "${var.pod_name}-data-3-${count.index}"
    type  = "pd-ssd"
    zone = "${element(data.google_compute_zones.available.names, count.index)}"
    size = "20"
}

resource "google_storage_bucket" "oracle-tarball" {
  name     = "oracle-tarball-bucket"
  location = "${var.region}"
}
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


  metadata {
    startup-script = <<SCRIPT
mkdir -p /tmp/tarball
cd /tmp/tarball
gsutil cp gs://oracle-tarball-bucket/* .
chmod +x /tmp/tarball/*.sh
/tmp/tarball/step0.sh >> /tmp/step0.log
/tmp/tarball/step1.sh >> /tmp/step1.log
/tmp/tarball/step2.sh >> /tmp/step2.log
su - oracle -c /tmp/tarball/step3.sh >> /tmp/step3.log
/tmp/tarball/step4.sh >> /tmp/step4.log
/tmp/tarball/step5.sh >> /tmp/step5.log
/tmp/tarball/step6.sh >> /tmp/step6.log
su - oracle -c /tmp/tarball/step7.sh >> /tmp/step7.log
/tmp/tarball/step8.sh >> /tmp/step8.log
su - oracle -c /tmp/tarball/step9.sh >> /tmp/step9.log
/tmp/tarball/step10.sh >> /tmp/step10.log
    SCRIPT
  }


  service_account {
    scopes = ["userinfo-email", "compute-rw", "storage-rw"]
  }

#  metadata {
#    sshKeys = "oracle:${file(var.ssh_public_key_filepath)}"
#  }

}
