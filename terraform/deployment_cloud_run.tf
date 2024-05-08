## Cloud Run
## Activate Cloud Run API
resource "google_project_service" "cloud_run" {
  service  = "run.googleapis.com"
  project  = var.project
  disable_on_destroy = false
}

## Declare Cloud Run service
#resource "google_cloud_run_service" "web_app_test" {
#  name     = var.cloud_run_web_app_name
#  location = var.region
#  project  = var.project

#  template {
#    spec {
#      containers {
#        image = "europe-west3-docker.pkg.dev/docai-accelerator/cloud-run-source-deploy/app:latest"
#      }
#    }
#  }

#  traffic {
#    percent         = 100
#    latest_revision = true
#  }
#}

## Set IAM policy to be publicly accessible
#data "google_iam_policy" "cloud_run_noauth" {
#  binding {
#    role = "roles/run.invoker"
#    members = ["allUsers",]
#  }
#}

#resource "google_cloud_run_service_iam_policy" "cr_noauth_policy" {
#  location    = var.region
#  project     = var.project
#  service     = google_cloud_run_service.web_app_test.name
#  policy_data = data.google_iam_policy.cloud_run_noauth.policy_data
#}

## Exporting the URL
#output "cloud_run_service_url" {
#  value = "${google_cloud_run_service.web_app_test.status[0].url}"
#}


## image_handler
resource "google_cloud_run_service_iam_member" "image_handler_member" {
  location = google_cloudfunctions2_function.image_handler.location
  service  = google_cloudfunctions2_function.image_handler.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_run_service" "image_handler_test" {
  name     = var.cloud_run_image_handler_name
  location = var.region
  project  = var.project

  template {
    spec {
      containers {
        image = resource.docker_image.image_handler_build.name
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [ 
    resource.docker_registry_image.image_handler_registry,
    google_cloudfunctions2_function.image_handler
  ]
}
