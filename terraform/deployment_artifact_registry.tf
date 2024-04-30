# Enable Artifact Registry API
resource "google_project_service" "enable_artifact_registry_api" {
  service = "artifactregistry.googleapis.com"
  project = var.project
}


# Create an Artifact repository
resource "google_artifact_registry_repository" "cf_repository" {
  project       = var.project
  location      = var.region
  repository_id = var.cloud_functions_repository_name
  format        = "DOCKER"
  description   = "Repository for cloud functions"
}

# Grant permissions to all users to push images
resource "google_artifact_registry_repository_iam_binding" "cloud_function_iam_binding" {
  repository = google_artifact_registry_repository.cf_repository.name
  location   = var.region
  role       = "roles/artifactregistry.writer"
  project    = var.project
  members    = ["allUsers",]
  #members = ["serviceAccount:${google_cloudfunctions_function.Cloud_function.service_account_email}"]
}