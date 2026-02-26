# ==============================================================================
# Google Cloud Filestore (Basic NFS Server) with Firewall Rules
# ==============================================================================
# Provisions a Filestore instance for NFS storage and secures access
# with a firewall rule.
#
# Key Points:
#   - Filestore provides managed NFS storage in GCP.
#   - Minimum size is 1 TB (1024 GiB).
#   - Instance is deployed in a specific zone.
#   - Basic tiers support NFSv3 only.
#   - NFS uses port 2049 (TCP and UDP).
#   - Source range 0.0.0.0/0 is lab only; restrict in production.
# ==============================================================================

resource "google_filestore_instance" "nfs_server" {

  # ----------------------------------------------------------------------------
  # Filestore Configuration
  # ----------------------------------------------------------------------------
  # - Name must be unique within the project.
  # - Tier determines performance and pricing.
  #   BASIC_HDD, BASIC_SSD support NFSv3 only.
  #   HIGH_SCALE_SSD and ENTERPRISE support NFSv3 and NFSv4.1.
  # - Location must be a zone, not just a region.
  # - Project ID is pulled from local credentials.
  # ----------------------------------------------------------------------------
  name     = "xubuntu-nfs-server"
  tier     = "BASIC_HDD"     # Reverted to Basic HDD
  location = "us-central1-b" # Zonal, not regional
  project  = local.credentials.project_id

  # ----------------------------------------------------------------------------
  # File Share Configuration
  # ----------------------------------------------------------------------------
  # - Minimum capacity for Basic Filestore is 1024 GiB.
  # - Export options define access mode and allowed IP ranges.
  # ----------------------------------------------------------------------------
  file_shares {
    capacity_gb = 1024 # 1 TB minimum
    name        = "filestore"

    nfs_export_options {
      access_mode = "READ_WRITE"     # Allow read/write access
      squash_mode = "NO_ROOT_SQUASH" # Preserve root privileges on clients
      ip_ranges   = ["0.0.0.0/0"]    # ⚠️ Lab only; restrict in production
    }
  }

  # ----------------------------------------------------------------------------
  # Network Configuration
  # ----------------------------------------------------------------------------
  # - Attaches Filestore to the specified VPC network.
  # - MODE_IPV4 is used for lab environments.
  # ----------------------------------------------------------------------------
  networks {
    network = data.google_compute_network.ad_vpc.name
    modes   = ["MODE_IPV4"]
  }
}

# ==============================================================================
# Firewall Rule: Allow NFS Traffic
# ==============================================================================
# Grants access to NFS port 2049 over TCP and UDP.
#
# Key Points:
#   - Required for Linux clients to mount Filestore.
#   - Source range is open for lab use.
#   - Restrict to specific subnets in production.
# ==============================================================================
resource "google_compute_firewall" "allow_nfs" {
  name    = "xubuntu-allow-nfs"
  network = data.google_compute_network.ad_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["2049"]
  }

  allow {
    protocol = "udp"
    ports    = ["2049"]
  }

  source_ranges = ["0.0.0.0/0"] # ⚠️ Lab only; tighten to subnet CIDR in prod
}

# ==============================================================================
# Output: Filestore IP Address
# ==============================================================================
# Exposes the Filestore private IP for mount commands.
# Example mount path: <IP_ADDRESS>:/filestore
# ==============================================================================
# output "filestore_ip" {
#   value = google_filestore_instance.nfs_server.networks[0].ip_addresses[0]
# }