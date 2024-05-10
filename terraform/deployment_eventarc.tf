# Eventarc
# Enable Eventarc API
resource "google_project_service" "eventarc_api" {
  service = "eventarc.googleapis.com"
  project = var.project
  disable_on_destroy = false
}

# Create a dedicated service account
#resource "google_service_account" "eventarc_service_account" {
#  account_id   = "eventarc-trigger"
#  display_name = "Eventarc Trigger Service Account"
#  depends_on = [ google_project_service.eventarc_api ]
#}

# Grant permission to receive Eventarc events
#resource "google_project_iam_member" "eventreceiver" {
#  project = var.project
#  role    = "roles/eventarc.eventReceiver"
#  member  = "serviceAccount:${google_service_account.eventarc_service_account.email}"
#  depends_on = [ google_service_account.eventarc_service_account ]
#}

# Grant permission to invoke Cloud Run services
#resource "google_project_iam_member" "runinvoker" {
#  project = var.project
#  role    = "roles/run.invoker"
#  member  = "serviceAccount:${google_service_account.eventarc_service_account.email}"
#  depends_on = [ google_project_iam_member.eventreceiver ]
#}

#resource "google_project_iam_member" "bigquery_job_user" {
#  project = var.project
#  role    = "roles/bigquery.dataEditor"
#  member  = "serviceAccount:${google_service_account.eventarc_service_account.email}"
#  depends_on = [ google_project_iam_member.runinvoker ]
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

  #service_account = google_service_account.eventarc_service_account.email

  transport {
    pubsub {
      topic = "projects/${var.project}/topics/${google_pubsub_topic.document_handler_function.name}"
    }
  }
  depends_on = [
    google_project_iam_member.bigquery_job_user,
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

  #service_account = google_service_account.eventarc_service_account.email

  transport {
    pubsub {
      topic = "projects/${var.project}/topics/${google_pubsub_topic.image_handler_function.name}"
    }
  }
  depends_on = [
    google_project_iam_member.bigquery_job_user,
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

  #ervice_account = google_service_account.eventarc_service_account.email

  transport {
    pubsub {
      topic = "projects/${var.project}/topics/${google_pubsub_topic.video_handler_function.name}"
    }
  }
  depends_on = [
    google_project_iam_member.bigquery_job_user,
    null_resource.deploy_video_handler
  ]
}