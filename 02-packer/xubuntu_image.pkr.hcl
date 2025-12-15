# ==============================================================================
# Packer Build: Xubuntu Image for Azure (Ubuntu 24.04 LTS)
#------------------------------------------------------------------------------
# Purpose:
#   - Builds a custom Azure Managed Image with Xubuntu and XRDP
#   - Starts from Canonical Ubuntu 24.04 LTS
#   - Installs desktop env, tools, browsers, and dev utilities
#   - Produces a timestamped image for VM or VMSS deployments
# ==============================================================================

packer {
  required_plugins {
    googlecompute = {
      source  = "github.com/hashicorp/googlecompute"
      version = "~> 1.1.6"
    }
  }
}

############################################
# LOCALS: TIMESTAMP UTILITY
############################################

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "") # Generate compact timestamp (YYYYMMDDHHMMSS)
                                                       # Used for unique image names
}

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "us-central1-a"
}

variable "source_image_family" {
  description = "Source image family to base the build on (e.g., ubuntu-2404-lts-amd64)"
  type        = string
  default     = "ubuntu-2404-lts-amd64"
}

source "googlecompute" "xubuntu_image" {
  project_id            = var.project_id
  zone                  = var.zone
  source_image_family   = var.source_image_family # Specifies the base image family
  ssh_username          = "ubuntu"                # Specify the SSH username
  machine_type          = "e2-standard-2"         # Machine type for the build VM

  image_name            = "xubuntu-image-${local.timestamp}" # Use local.timestamp directly
  image_family          = "xubuntu-images"          # Image family to group related images
  disk_size             = 64                        # Disk size in GB
}

# ------------------------------------------------------------------------------
# Build Block: Provisioning Scripts
# - Executes each setup script inside the build VM
# ------------------------------------------------------------------------------
build {
  sources = ["source.googlecompute.xubuntu_image"]

  # Base packages
  provisioner "shell" {
    script          = "./packages.sh"
    execute_command = "sudo -E bash '{{.Path}}'"
  }

  # Xubuntu desktop
  provisioner "shell" {
    script          = "./xubuntu.sh"
    execute_command = "sudo -E bash '{{.Path}}'"
  }

  # XRDP
  provisioner "shell" {
    script          = "./xrdp.sh"
    execute_command = "sudo -E bash '{{.Path}}'"
  }

  # Chrome
  provisioner "shell" {
    script          = "./chrome.sh"
    execute_command = "sudo -E bash '{{.Path}}'"
  }

  # Firefox
  provisioner "shell" {
    script          = "./firefox.sh"
    execute_command = "sudo -E bash '{{.Path}}'"
  }

  # VS Code
  provisioner "shell" {
    script          = "./vscode.sh"
    execute_command = "sudo -E bash '{{.Path}}'"
  }

  # HashiCorp tools
  provisioner "shell" {
    script          = "./hashicorp.sh"
    execute_command = "sudo -E bash '{{.Path}}'"
  }

  # AWS CLI
  provisioner "shell" {
    script          = "./awscli.sh"
    execute_command = "sudo -E bash '{{.Path}}'"
  }

  # Azure CLI
  provisioner "shell" {
    script          = "./azcli.sh"
    execute_command = "sudo -E bash '{{.Path}}'"
  }

  # Google Cloud CLI
  provisioner "shell" {
    script          = "./gcloudcli.sh"
    execute_command = "sudo -E bash '{{.Path}}'"
  }

  # Docker
  provisioner "shell" {
    script          = "./docker.sh"
    execute_command = "sudo -E bash '{{.Path}}'"
  }

  # Postman
  provisioner "shell" {
    script          = "./postman.sh"
    execute_command = "sudo -E bash '{{.Path}}'"
  }

  # KRDC
  provisioner "shell" {
    script          = "./krdc.sh"
    execute_command = "sudo -E bash '{{.Path}}'"
  }

  # OnlyOffice
  provisioner "shell" {
    script          = "./onlyoffice.sh"
    execute_command = "sudo -E bash '{{.Path}}'"
  }

  # Desktop icons
  provisioner "shell" {
    script          = "./desktop.sh"
    execute_command = "sudo -E bash '{{.Path}}'"
  }
}
