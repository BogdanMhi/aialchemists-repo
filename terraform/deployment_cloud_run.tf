## Cloud Run
## Enable Cloud Run API
resource "google_project_service" "cloud_run_api" {
  service = "run.googleapis.com"
  project = var.project
  disable_on_destroy = false
}

## web-app FE
resource "google_cloud_run_v2_service" "web_app" {
  name     = var.cloud_run_web_app_name
  location = var.region
  project  = var.project
  ingress = "INGRESS_TRAFFIC_ALL"

  template {
    scaling {max_instance_count = 100}
    timeout = "3600s"
    containers {
      image = "${var.region}-docker.pkg.dev/${var.project}/cloud-run-source-deploy/app:latest"

      startup_probe {
        initial_delay_seconds = 0
        timeout_seconds = 240
        failure_threshold = 1
        tcp_socket {port = 8080}
      }

      resources {
        startup_cpu_boost = true
        cpu_idle = true
        limits = {
          cpu    = "4"
          memory = "8Gi"
        }
      }
    }
  }

  traffic {
    type = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

#  depends_on = [ 
#    resource.docker_image.web_app_build,
#    resource.docker_registry_image.web_app_push
#  ]
}

## Set IAM policy to be publicly accessible
data "google_iam_policy" "cloud_run_noauth" {
  binding {
    role = "roles/run.invoker"
    members = ["allUsers",]
  }
}

resource "google_cloud_run_v2_service_iam_policy" "cr_noauth_policy" {
  location    = var.region
  project     = var.project
  name        = google_cloud_run_v2_service.web_app.name
  policy_data = data.google_iam_policy.cloud_run_noauth.policy_data
}

## document_handler
resource "google_cloud_run_v2_service" "document_handler" {
  name     = var.cloud_run_document_handler_name
  location = var.region
  project  = var.project
  ingress = "INGRESS_TRAFFIC_ALL"

  template {
    scaling {max_instance_count = 100}
    timeout = "300s"
    containers {
      image = resource.docker_image.document_handler_build.name

      startup_probe {
        initial_delay_seconds = 0
        timeout_seconds = 240
        #period_seconds = 3
        failure_threshold = 1
        tcp_socket {port = 8080}
      }

      env {
        name = "PROJECT_ID"
        value = var.project
      }

      env {
        name = "TEXT_PROCESSOR_TRIGGER"
        value = google_pubsub_topic.text_processor_function.name
      }

      env {
        name = "INGESTION_DATA_BUCKET"
        value = google_storage_bucket.ingestion_bucket.name
      }

      resources {
        startup_cpu_boost = true
        cpu_idle = true
        limits = {
          cpu    = "2"
          memory = "4Gi"
        }
      }
    }
  }

  traffic {
    type = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  depends_on = [ 
    resource.docker_image.document_handler_build,
    resource.docker_registry_image.document_handler_push
  ]
}

## image_handler
resource "google_cloud_run_v2_service" "image_handler" {
  name     = var.cloud_run_image_handler_name
  location = var.region
  project  = var.project
  ingress = "INGRESS_TRAFFIC_ALL"

  template {
    scaling {max_instance_count = 100}
    timeout = "900s"
    containers {
      image = "${local.art_reg}/${local.art_imag}:${local.image_tag}"
      #resource.docker_image.image_handler_build.name

      startup_probe {
        initial_delay_seconds = 0
        timeout_seconds = 240
        #period_seconds = 3
        failure_threshold = 1
        tcp_socket {port = 8080}
      }

      env {
        name = "PROJECT_ID"
        value = var.project
      }

      env {
        name = "TEXT_PROCESSOR_TRIGGER"
        value = google_pubsub_topic.text_processor_function.name
      }

      env {
        name = "FIRESTORE_DATABASE_ID"
        value = var.firestore_database_name
      }

      env {
        name = "INGESTION_DATA_BUCKET"
        value = google_storage_bucket.ingestion_bucket.name
      }

      resources {
        startup_cpu_boost = true
        cpu_idle = true
        limits = {
          cpu    = "8"
          memory = "32Gi"
        }
      }
    }
  }

  traffic {
    type = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  depends_on = [null_resource.build_push_image_handler]
}

## video_handler
resource "google_cloud_run_v2_service" "video_handler" {
  name     = var.cloud_run_video_handler_name
  location = var.region
  project  = var.project
  ingress = "INGRESS_TRAFFIC_ALL"

  template {
    scaling {max_instance_count = 100}
    timeout = "900s"
    containers {
      image = resource.docker_image.video_handler_build.name

      startup_probe {
        initial_delay_seconds = 0
        timeout_seconds = 240
        #period_seconds = 3
        failure_threshold = 1
        tcp_socket {port = 8080}
      }

      env {
        name = "PROJECT_ID"
        value = var.project
      }

      env {
        name = "TEXT_PROCESSOR_TRIGGER"
        value = google_pubsub_topic.text_processor_function.name
      }

      env {
        name = "INGESTION_DATA_BUCKET"
        value = google_storage_bucket.ingestion_bucket.name
      }

      resources {
        startup_cpu_boost = true
        cpu_idle = true
        limits = {
          cpu    = "8"
          memory = "32Gi"
        }
      }
    }
  }

  traffic {
    type = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  depends_on = [ 
    resource.docker_image.video_handler_build,
    resource.docker_registry_image.video_handler_push
  ]
}