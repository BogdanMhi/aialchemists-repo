# Eventarc
# Enable Eventarc API
resource "google_project_service" "eventarc" {
  service = "eventarc.googleapis.com"
  project = var.project
  disable_on_destroy = false
}

# Create a dedicated service account
resource "google_service_account" "eventarc_service_account" {
  account_id   = "eventarc-trigger-sa"
  display_name = "Eventarc Trigger Service Account"
}