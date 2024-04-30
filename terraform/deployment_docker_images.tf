provider "docker" {
  registry_auth {
    address  = "europe-west3-docker.pkg.dev"
  }
}

resource "docker_registry_image" "image_handler_image" {
  name = "europe-west3-docker.pkg.dev/${var.project}/${var.cloud_functions_repository_name}/${var.image_handler_docker_image}"
  build {
    context = "${var.image_handler_dockerfile_location}"
    dockerfile = "Dockerfile"
  }
}