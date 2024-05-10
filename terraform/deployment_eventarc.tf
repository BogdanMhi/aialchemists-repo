# Eventarc
# Enable Eventarc API
resource "google_project_service" "eventarc_api" {
  service = "eventarc.googleapis.com"
  project = var.project
  disable_on_destroy = false
}

# Create a dedicated service account
#resource "google_service_account" "eventarc_service_account" {
#  account_id   = "eventarc-trigger-sa"
#  display_name = "Eventarc Trigger Service Account"
#}

## document_handler
resource "google_eventarc_trigger" "trigger-document-handler" {
  name     = "trigger-document-handler"
  location = var.region
  matching_criteria {
    attribute = "type"
    value     = "google.cloud.pubsub.topic.v1.messagePublished"
  }
  destination {
    cloud_run_service {
      service = var.document_handler_source_name
      region  = var.region
    }
  }

  transport {
    pubsub {
      topic = "projects/${var.project}/topics/${google_pubsub_topic.document_handler_function.name}"
    }
  }
  depends_on = [
    google_project_service.eventarc_api,
    null_resource.deploy_document_handler
  ]
}

## image_handler
resource "google_eventarc_trigger" "trigger-image-handler" {
  name     = "trigger-image-handler"
  location = var.region
  matching_criteria {
    attribute = "type"
    value     = "google.cloud.pubsub.topic.v1.messagePublished"
  }
  destination {
    cloud_run_service {
      service = var.image_handler_source_name
      region  = var.region
    }
  }

  transport {
    pubsub {
      topic = "projects/${var.project}/topics/${google_pubsub_topic.image_handler_function.name}"
    }
  }
  depends_on = [
    google_project_service.eventarc_api,
    null_resource.deploy_image_handler
  ]
}

## video_handler
resource "google_eventarc_trigger" "trigger-video-handler" {
  name     = "trigger-video-handler"
  location = var.region
  matching_criteria {
    attribute = "type"
    value     = "google.cloud.pubsub.topic.v1.messagePublished"
  }
  destination {
    cloud_run_service {
      service = var.video_handler_source_name
      region  = var.region
    }
  }

  transport {
    pubsub {
      topic = "projects/${var.project}/topics/${google_pubsub_topic.video_handler_function.name}"
    }
  }
  depends_on = [
    google_project_service.eventarc_api,
    null_resource.deploy_video_handler
  ]
}