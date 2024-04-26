## Cloud Run
## Activate Cloud Run API
resource "google_project_service" "cloud_run" {
  service  = "run.googleapis.com"
  project  = var.project
  disable_on_destroy = false
}

## Declare Cloud Run service
resource "google_cloud_run_v2_service" "web_app_test" {
  name     = var.cloud_run_web_app_name
  location = var.region
  project  = var.project
  #ingress = "INGRESS_TRAFFIC_ALL"

  template {
    containers {
      image = "gcr.io/docai-accelerator/web-app"
    }
  }

  traffic {
    type = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }
}

## Set IAM policy to be publicly accessible
resource "google_cloud_run_service_iam_member" "public" {
  service     = google_cloud_run_v2_service.web_app_test.name
  location    = var.region
  project     = var.project
  role        = "roles/run.invoker"
  member      = "allUsers"
}

## Exporting the URL
output "url" {
  value = "${google_cloud_run_v2_service.web_app_test.status[0].url}"
}