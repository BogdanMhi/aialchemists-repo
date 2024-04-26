## Cloud Run
## Activate Cloud Run API
resource "google_project_service" "cloudrun" {
  service  = "run.googleapis.com"
  project  = var.project
  disable_on_destroy = false
}

## Declare Cloud Run service
resource "google_cloud_run_service" "web_app_test" {
  name     = var.cloud_run_web_app_name
  location = var.region
  project  = var.project
  template {
    spec {
      containers {
        image = "gcr.io/docai-accelerator/web-app"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
    tag             = "latest_web_app"
  }
}

## Set IAM policy to be publicly accessible
resource "google_cloud_run_service_iam_member" "public" {
  service     = google_cloud_run_service.web_app_test.name
  location    = var.region
  project     = var.project
  role        = "roles/run.invoker"
  member      = "allUsers"
}

## Exporting the URL
output "url" {
  value = "${google_cloud_run_service.web_app_test.status[0].url}"
}