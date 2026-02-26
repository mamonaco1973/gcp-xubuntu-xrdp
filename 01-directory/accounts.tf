# ==============================================================================
# Active Directory User Credentials in GCP Secret Manager
# ==============================================================================
# Provisions:
#   1. Memorable passwords for each AD user: <word>-<6digit>
#   2. Secret Manager entries for storing credentials.
#   3. IAM bindings granting the service account access to retrieve these secrets.
#
# Key Points:
#   - Users: Admin, John Smith, Emily Davis, Raj Patel, Amit Kumar.
#   - Password format: "<memorable_word>-<6digit>" (one word + one number per user).
#   - Secrets stored securely in GCP Secret Manager.
#   - Service account granted roles/secretmanager.secretAccessor on all secrets.
# ==============================================================================

# ==============================================================================
# Memorable Word List
# ==============================================================================
# Source list used to generate per-user passwords. Each user gets one randomly
# selected word from this list.
# ==============================================================================
locals {
  memorable_words = [
    "bright",
    "simple",
    "orange",
    "window",
    "little",
    "people",
    "friend",
    "yellow",
    "animal",
    "family",
    "circle",
    "moment",
    "summer",
    "button",
    "planet",
    "rocket",
    "silver",
    "forest",
    "stream",
    "butter",
    "castle",
    "wonder",
    "gentle",
    "driver",
    "coffee"
  ]
}

# ==============================================================================
# User Accounts to Generate
# ==============================================================================
# Map of AD usernames to display names. Keys are used for secret IDs and for the
# generated UPN format: <username>@<dns_zone>.
# ==============================================================================
locals {
  ad_users = {
    admin  = "Admin"
    jsmith = "John Smith"
    edavis = "Emily Davis"
    rpatel = "Raj Patel"
    akumar = "Amit Kumar"
  }
}

# ==============================================================================
# Random Word (one per user)
# ==============================================================================
# Generates one random word per user by shuffling the word list and selecting
# a single value (result_count = 1).
# ==============================================================================
resource "random_shuffle" "word" {
  for_each     = local.ad_users
  input        = local.memorable_words
  result_count = 1
}

# ==============================================================================
# Random 6-digit number (one per user)
# ==============================================================================
# Generates one 6-digit integer per user to pair with the random word.
# ==============================================================================
resource "random_integer" "num" {
  for_each = local.ad_users
  min      = 100000
  max      = 999999
}

# ==============================================================================
# Build the Password: <word>-<number>
# ==============================================================================
# Constructs the final password string for each user as:
#   "<random_word>-<6digit>"
# ==============================================================================
locals {
  passwords = {
    for user, fullname in local.ad_users :
    user => "${random_shuffle.word[user].result[0]}-${random_integer.num[user].result}"
  }
}

# ==============================================================================
# Create Secret + Version for Each User
# ==============================================================================
# Creates one Secret Manager secret per AD user, then stores a JSON payload as a
# secret version containing:
#   - username: "<user>@<dns_zone>"
#   - password: generated "<word>-<6digit>"
# ==============================================================================
resource "google_secret_manager_secret" "ad_secret" {
  for_each  = local.ad_users
  secret_id = "${each.key}-ad-credentials-xubuntu"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "ad_secret_version" {
  for_each = local.ad_users
  secret  = google_secret_manager_secret.ad_secret[each.key].id

  secret_data = jsonencode({
    username = "${each.key}@${var.dns_zone}"
    password = local.passwords[each.key]
  })
}

# ==============================================================================
# Locals: Secret List
# ==============================================================================
# Builds a list of secret_id strings used to drive IAM bindings below.
# ==============================================================================
locals {
  secrets = [
    for user, fullname in local.ad_users :
    google_secret_manager_secret.ad_secret[user].secret_id
  ]
}

# ==============================================================================
# IAM Binding: Grant Secret Access
# ==============================================================================
# Grants the service account read access to each secret via:
#   roles/secretmanager.secretAccessor
# ==============================================================================
resource "google_secret_manager_secret_iam_binding" "secret_access" {
  for_each  = toset(local.secrets)
  secret_id = each.key
  role      = "roles/secretmanager.secretAccessor"

  members = [
    "serviceAccount:${local.service_account_email}"
  ]
}