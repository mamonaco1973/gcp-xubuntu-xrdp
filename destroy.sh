#!/bin/bash
# ==============================================================================
# destroy.sh
# ------------------------------------------------------------------------------
# Purpose:
#   - Tear down the GCP Xubuntu environment:
#       01) Destroy servers (Terraform)
#       02) Delete Xubuntu images (best-effort)
#       03) Destroy directory services (Terraform)
#
# Notes:
#   - Uses most recent image in family 'xubuntu-images'
#     matching '^xubuntu-image' as destroy input.
#   - Image deletion continues even if individual deletes fail.
# ==============================================================================

set -e

# ------------------------------------------------------------------------------
# Determine Latest Xubuntu Image
# ------------------------------------------------------------------------------

xubuntu_image=$(gcloud compute images list \
  --filter="name~'^xubuntu-image' AND family=xubuntu-images" \
  --sort-by="~creationTimestamp" \
  --limit=1 \
  --format="value(name)")  # Most recent image in family

if [[ -z "$xubuntu_image" ]]; then
  echo "ERROR: No latest image found for family 'xubuntu-images'."
  exit 1
fi

echo "NOTE: Xubuntu image is $xubuntu_image"

# ------------------------------------------------------------------------------
# Phase 1: Destroy Servers (Terraform)
# ------------------------------------------------------------------------------

cd 03-servers

terraform init
terraform destroy \
  -var="xubuntu_image_name=$xubuntu_image" \
  -auto-approve

cd ..

# ------------------------------------------------------------------------------
# Phase 2: Delete Xubuntu Images (Best-Effort)
# ------------------------------------------------------------------------------

image_list=$(gcloud compute images list \
  --format="value(name)" \
  --filter="name~'^(xubuntu)'")  # Names starting with 'xubuntu'

if [[ -z "$image_list" ]]; then
  echo "NOTE: No images found starting with 'xubuntu'. Continuing..."
else
  echo "NOTE: Deleting images..."
  for image in $image_list; do
    echo "NOTE: Deleting image: $image"
    gcloud compute images delete "$image" --quiet \
      || echo "WARNING: Failed to delete image: $image"
  done
fi

# ------------------------------------------------------------------------------
# Phase 3: Destroy Directory Services (Terraform)
# ------------------------------------------------------------------------------

cd 01-directory

terraform init
terraform destroy -auto-approve

cd ..