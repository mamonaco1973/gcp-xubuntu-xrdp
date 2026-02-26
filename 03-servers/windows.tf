# ==============================================================================
# SysAdmin Credentials and Windows AD Management VM with RDP Firewall
# ==============================================================================
# Provisions:
#   1. SysAdmin password stored in Secret Manager.
#   2. Firewall rule allowing inbound RDP (3389).
#   3. Windows Server 2022 VM for AD administration.
#   4. Data source for latest Windows Server 2022 image.
#
# Key Points:
#   - SysAdmin credentials stored securely in Secret Manager.
#   - Firewall rules are tag-based in GCP.
#   - RDP open to 0.0.0.0/0 is lab only.
#   - VM auto-joins AD domain via startup PowerShell.
# ==============================================================================


# ==============================================================================
# SysAdmin Credentials
# ==============================================================================
# Generates a secure password and stores it in GCP Secret Manager.
# ==============================================================================

resource "random_password" "sysadmin_password" {
  length           = 24
  special          = true
  override_special = "-_."
}

resource "google_secret_manager_secret" "sysadmin_secret" {
  secret_id = "sysadmin-ad-credentials-xubuntu"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "admin_secret_version" {
  secret = google_secret_manager_secret.sysadmin_secret.id
  secret_data = jsonencode({
    username = "sysadmin"
    password = random_password.sysadmin_password.result
  })
}


# ==============================================================================
# Firewall Rule: Allow RDP
# ==============================================================================
# Grants inbound RDP access (TCP 3389) to tagged Windows VMs.
#
# Key Points:
#   - Applies only to instances tagged "allow-rdp".
#   - Source range 0.0.0.0/0 is lab only.
# ==============================================================================

resource "google_compute_firewall" "allow_rdp" {
  name    = "xubuntu-allow-rdp"
  network = "ad-vpc"

  # Allow TCP traffic on port 3389 (RDP)
  allow {
    protocol = "tcp"
    ports    = ["3389"]
  }

  # Restrict rule to instances with this tag
  target_tags = ["xubuntu-allow-rdp"]

  # Lab only; restrict in production
  source_ranges = ["0.0.0.0/0"]
}


# ==============================================================================
# Windows AD Management VM
# ==============================================================================
# Provisions a Windows Server 2022 VM for AD administration.
#
# Key Points:
#   - Uses latest Windows 2022 image from GCP.
#   - Tagged "allow-rdp" for firewall rule.
#   - Startup script auto-joins the AD domain.
#   - Admin credentials passed via metadata.
# ==============================================================================

resource "google_compute_instance" "windows_ad_instance" {
  name         = "win-ad-${random_string.vm_suffix.result}" # Random suffix for uniqueness
  machine_type = "e2-standard-2"                            # Balanced Windows size
  zone         = "us-central1-a"

  # ---------------------------------------------------------------------------
  # Boot Disk (Windows Server 2022)
  # ---------------------------------------------------------------------------
  boot_disk {
    initialize_params {
      image = data.google_compute_image.windows_2022.self_link
    }
  }

  # ---------------------------------------------------------------------------
  # Network Interface
  # ---------------------------------------------------------------------------
  network_interface {
    network    = var.vpc
    subnetwork = var.subnet

    # Assign public IP for RDP access
    access_config {}
  }

  # ---------------------------------------------------------------------------
  # Service Account
  # ---------------------------------------------------------------------------
  # Grants VM access to GCP APIs for automation.
  service_account {
    email  = local.service_account_email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  # ---------------------------------------------------------------------------
  # Startup Script (Domain Join)
  # ---------------------------------------------------------------------------
  # Runs at first boot to join VM to AD domain.
  metadata = {
    windows-startup-script-ps1 = templatefile("./scripts/ad_join.ps1", {
      domain_fqdn = "mcloud.mikecloud.com"
      nfs_gateway = google_compute_instance.desktop_instance.network_interface[0].network_ip
    })

    admin_username = "sysadmin"
    admin_password = random_password.sysadmin_password.result
  }

  # ---------------------------------------------------------------------------
  # Firewall Tags
  # ---------------------------------------------------------------------------
  tags = ["xubuntu-allow-rdp"]
}


# ==============================================================================
# Data Source: Latest Windows Server 2022 Image
# ==============================================================================
# Fetches latest Windows Server 2022 image from windows-cloud project.
# ==============================================================================

data "google_compute_image" "windows_2022" {
  family  = "windows-2022"
  project = "windows-cloud"
}