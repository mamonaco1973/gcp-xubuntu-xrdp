# ==============================================================================
# Google Cloud Provider and Local Variables
# ==============================================================================
# Configures the Google provider using credentials from a JSON file.
#
# Key Points:
#   - Provider uses project ID and credentials for authentication.
#   - Locals decode JSON for reuse (project_id, service account).
# ==============================================================================

provider "google" {
  project     = local.credentials.project_id # Project ID extracted from credentials.json
  credentials = file("../credentials.json")  # Path to service account credentials file
}

# ==============================================================================
# Local Variables
# ==============================================================================
# Decodes the credentials JSON file and extracts reusable fields.
#
# Key Points:
#   - credentials local contains full decoded JSON map.
#   - service_account_email provides identity for bindings.
# ==============================================================================

locals {
  credentials           = jsondecode(file("../credentials.json"))
  service_account_email = local.credentials.client_email
}

# ==============================================================================
# Data Sources: Network and Subnet
# ==============================================================================
# Looks up existing VPC network and subnet for resource attachment.
#
# Key Points:
#   - ad-vpc is the base VPC for AD lab resources.
#   - ad-subnet defines the subnet in us-central1.
# ==============================================================================

data "google_compute_network" "ad_vpc" {
  name = "ad-vpc"
}

data "google_compute_subnetwork" "ad_subnet" {
  name   = "ad-subnet"
  region = "us-central1"
}

# ==============================================================================
# Input Variable: Xubuntu Image Name
# ------------------------------------------------------------------------------
# Name of the custom Xubuntu image built by Packer.
# Used as the boot source for GCE instances in this module.
# ==============================================================================

variable "xubuntu_image_name" {
  description = "Name of the Packer-built Xubuntu GCP image"
  type        = string
}

# ==============================================================================
# Data Source: GCE Image Lookup
# ------------------------------------------------------------------------------
# Resolves the custom Xubuntu image by name in the current project.
# Allows resources to reference the image self_link safely.
# ==============================================================================

data "google_compute_image" "xubuntu_packer_image" {
  name    = var.xubuntu_image_name        # Image name passed in from destroy/build workflows
  project = local.credentials.project_id  # GCP project containing the custom image
}