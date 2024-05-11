# Enable Artifact Registry API
resource "google_project_service" "enable_artifact_registry_api" {
  service = "artifactregistry.googleapis.com"
  project = var.project
}

/*
# Create an Artifact repository 
resource "google_artifact_registry_repository" "cloud_run_repository" {
  project       = var.project
  location      = var.region
  repository_id = var.cloud_run_repository_name
  format        = "DOCKER"
  description   = "Repository for cloud run"
  depends_on = [google_project_service.enable_artifact_registry_api]
}
*/
