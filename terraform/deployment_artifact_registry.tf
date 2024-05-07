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

# Grant permissions for Cloud Function to push images
data "google_iam_policy" "artifact_registry_admin" {
  binding {
    role = "roles/artifactregistry.admin"
    #members = ["allUsers",]
    members = ["serviceAccount:${google_service_account.cloud_functions.email}"]
  }
}

resource "google_artifact_registry_repository_iam_policy" "ar_admin_policy" {
  location = var.region
  project = var.project
  repository = google_artifact_registry_repository.cf_repository.name
  policy_data = data.google_iam_policy.artifact_registry_admin.policy_data
}