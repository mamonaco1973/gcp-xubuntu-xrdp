# ==============================================================================
# Custom VPC, Subnet, Router, and NAT for AD Environment
# ==============================================================================
# Provisions:
#   1. Custom-mode VPC (no default subnets).
#   2. Explicit subnet for AD resources.
#   3. Cloud Router for dynamic routing.
#   4. Cloud NAT for outbound internet without public IPs.
#
# Key Points:
#   - Custom VPC avoids auto-created subnets.
#   - Subnet defined in us-central1 with CIDR 10.1.0.0/24.
#   - Cloud Router enables NAT and advanced routing.
#   - Cloud NAT provides secure outbound access for private VMs.
# ==============================================================================


# ==============================================================================
# VPC Network: Active Directory VPC
# ==============================================================================
# Creates a custom-mode VPC.
#
# Key Points:
#   - Auto subnet creation disabled.
#   - All subnets must be manually defined.
# ==============================================================================
resource "google_compute_network" "ad_vpc" {
  name                    = var.vpc
  auto_create_subnetworks = false
}


# ==============================================================================
# Subnet: Active Directory Subnet
# ==============================================================================
# Defines a subnet inside the AD VPC for directory resources.
#
# Key Points:
#   - Located in us-central1 region.
#   - CIDR 10.1.0.0/24.
#   - Explicitly attached to the VPC above.
# ==============================================================================
resource "google_compute_subnetwork" "ad_subnet" {
  name          = var.subnet
  region        = "us-central1"
  network       = google_compute_network.ad_vpc.id
  ip_cidr_range = "10.1.0.0/24"
}


# ==============================================================================
# Cloud Router
# ==============================================================================
# Creates a Cloud Router in the AD VPC.
#
# Key Points:
#   - Required for Cloud NAT.
#   - Supports dynamic route advertisement and BGP if enabled.
# ==============================================================================
resource "google_compute_router" "ad_router" {
  name    = "xubuntu-ad-router"
  network = google_compute_network.ad_vpc.id
  region  = "us-central1"
}


# ==============================================================================
# Cloud NAT
# ==============================================================================
# Provides outbound internet access for private AD subnet resources.
#
# Key Points:
#   - Instances do not require public IPs.
#   - NAT IPs allocated automatically.
#   - Flow logs enabled with filter set to ALL.
# ==============================================================================
resource "google_compute_router_nat" "ad_nat" {
  name   = "xubuntu-ad-nat"
  router = google_compute_router.ad_router.name
  region = google_compute_router.ad_router.region

  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ALL"
  }
}