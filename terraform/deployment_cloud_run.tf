## Cloud Run
## Activate Cloud Run API
resource "google_project_service" "cloud_run" {
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
        image = "europe-west3-docker.pkg.dev/docai-accelerator/cloud-run-source-deploy/app:latest"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

## Set IAM policy to be publicly accessible
data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  location    = google_cloud_run_service.web_app_test.location
  project     = google_cloud_run_service.web_app_test.project
  service     = google_cloud_run_service.web_app_test.name
  policy_data = data.google_iam_policy.noauth.policy_data
}

## Exporting the URL
output "cloud_run_service_url" {
  value = "${google_cloud_run_service.web_app_test.status[0].url}"
}