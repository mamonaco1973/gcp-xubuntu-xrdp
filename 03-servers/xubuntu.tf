# ==============================================================================
# Random String, Firewall (SSH/SMB), and Ubuntu VM for AD/NFS Gateway
# ==============================================================================
# Provisions:
#   1. Random suffix for unique resource naming.
#   2. Firewall rules for SSH (22) and SMB (445).
#   3. Ubuntu 24.04 VM as NFS gateway and AD client.
#   4. Data source for latest Ubuntu 24.04 LTS image.
#
# Key Points:
#   - Random suffix prevents name collisions.
#   - SSH and SMB open to 0.0.0.0/0 are lab only.
#   - VM joins AD and mounts Filestore via startup script.
#   - Service account enables GCP API access.
# ==============================================================================


# ==============================================================================
# Random String Generator
# ==============================================================================
# Generates a lowercase suffix to ensure resource name uniqueness.
# ==============================================================================
resource "random_string" "vm_suffix" {
  length  = 10    # Number of characters in the generated string
  special = false # Excludes special characters (DNS-friendly)
  upper   = false # Lowercase only for consistency
}


# ==============================================================================
# Firewall Rule: Allow SSH
# ==============================================================================
# Opens TCP port 22 for VMs tagged with "allow-ssh".
#
# Key Points:
#   - Applies only to instances with this tag.
#   - Source range 0.0.0.0/0 is lab only.
# ==============================================================================
resource "google_compute_firewall" "allow_ssh" {
  name    = "xubuntu-allow-ssh"
  network = "ad-vpc"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags = ["xubuntu-allow-ssh"]

  # Lab only; restrict in production
  source_ranges = ["0.0.0.0/0"]
}


# ==============================================================================
# Firewall Rule: Allow SMB
# ==============================================================================
# Opens TCP port 445 for VMs tagged with "allow-smb".
#
# Key Points:
#   - Applies only to instances with this tag.
#   - Source range 0.0.0.0/0 is lab only.
# ==============================================================================
resource "google_compute_firewall" "allow_smb" {
  name    = "xubuntu-allow-smb"
  network = "ad-vpc"

  allow {
    protocol = "tcp"
    ports    = ["445"]
  }

  target_tags = ["xubuntu-allow-smb"]

  # Lab only; restrict in production
  source_ranges = ["0.0.0.0/0"]
}


# ==============================================================================
# Xubuntu VM: NFS Gateway and AD-Joined Desktop
# ==============================================================================
# Deploys a Xubuntu 24.04 VM that:
#   - Connects to ad-vpc and ad-subnet.
#   - Boots from custom Packer-built image.
#   - Joins AD and mounts Filestore at boot.
#   - Uses OS Login for secure SSH access.
#
# Key Points:
#   - Startup script injects AD FQDN and Filestore IP.
#   - Service account grants required API access.
# ==============================================================================
resource "google_compute_instance" "desktop_instance" {
  name         = "xubuntu-${random_string.vm_suffix.result}"
  machine_type = "n2-standard-4"
  zone         = "us-central1-a"

  # ---------------------------------------------------------------------------
  # Boot Disk
  # ---------------------------------------------------------------------------
  boot_disk {
    initialize_params {
      image = data.google_compute_image.xubuntu_packer_image.self_link
    }
  }

  # ---------------------------------------------------------------------------
  # Network Interface
  # ---------------------------------------------------------------------------
  network_interface {
    network    = var.vpc
    subnetwork = var.subnet

    # Ephemeral public IP for SSH access
    access_config {}
  }

  # ---------------------------------------------------------------------------
  # Metadata (Startup Script and Config)
  # ---------------------------------------------------------------------------
  metadata = {
    enable-oslogin = "TRUE"

    startup-script = templatefile("./scripts/nfs_gateway_init.sh", {
      domain_fqdn   = "mcloud.mikecloud.com"
      nfs_server_ip = google_filestore_instance.nfs_server.networks[0].ip_addresses[0]
      domain_fqdn   = var.dns_zone
      netbios       = var.netbios
      force_group   = "mcloud-users"
      realm         = var.realm
    })
  }

  # ---------------------------------------------------------------------------
  # Service Account
  # ---------------------------------------------------------------------------
  service_account {
    email  = local.service_account_email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  # ---------------------------------------------------------------------------
  # Firewall Tags
  # ---------------------------------------------------------------------------
  tags = ["xubuntu-allow-ssh", "xubuntu-allow-nfs", "xubuntu-allow-smb", "xubuntu-allow-rdp"]
}


# ==============================================================================
# Data Source: Latest Ubuntu 24.04 LTS Image
# ==============================================================================
# Fetches most recent Ubuntu 24.04 LTS image from ubuntu-os-cloud.
# ==============================================================================
data "google_compute_image" "ubuntu_latest" {
  family  = "ubuntu-2404-lts-amd64"
  project = "ubuntu-os-cloud"
}