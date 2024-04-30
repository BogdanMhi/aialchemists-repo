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
data "google_iam_policy" "artifact_registry_editor" {
  binding {
    role = "roles/artifactregistry.admin"
    members = ["allUsers",]
  }
}

resource "google_artifact_registry_repository_iam_policy" "policy" {
  project = google_artifact_registry_repository.cf_repository.project
  location = google_artifact_registry_repository.cf_repository.location
  repository = google_artifact_registry_repository.cf_repository.name
  policy_data = data.google_iam_policy.artifact_registry_editor.policy_data
}