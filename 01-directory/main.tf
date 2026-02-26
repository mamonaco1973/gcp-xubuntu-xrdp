# ==============================================================================
# Google Cloud Provider Configuration
# ==============================================================================
# Configures the Google provider for Terraform execution.
#
# Key Points:
#   - Uses service account credentials in ../credentials.json.
#   - Project ID and service account email are read from the JSON.
# ==============================================================================

provider "google" {
  project     = local.credentials.project_id # Project ID from decoded credentials
  credentials = file("../credentials.json")  # Path to service account JSON
}

# ==============================================================================
# Local Variables
# ==============================================================================
# Decodes the credentials file for reuse across modules.
#
# Key Points:
#   - credentials stores the full JSON as a map.
#   - service_account_email references the service account identity.
# ==============================================================================

locals {
  credentials           = jsondecode(file("../credentials.json"))
  service_account_email = local.credentials.client_email
}