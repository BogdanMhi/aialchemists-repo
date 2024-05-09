# Eventarc
# Enable Eventarc API
resource "google_project_service" "eventarc_api" {
  service = "eventarc.googleapis.com"
  project = var.project
  disable_on_destroy = false
}

# Create a dedicated service account
resource "google_service_account" "eventarc_service_account" {
  account_id   = "eventarc-trigger-sa"
  display_name = "Eventarc Trigger Service Account"
}

resource "google_eventarc_trigger" "trigger-document-handler" {
  name     = "trigger-document-handler"
  location = var.region
  matching_criteria {
    attribute = "type"
    value     = "google.cloud.pubsub.topic.v1.messagePublished"
  }
  destination {
    cloud_run_service {
      service = google_cloud_run_v2_service.document_handler.name
      region  = var.region
    }
  }

  depends_on = [google_project_service.eventarc_api]
}