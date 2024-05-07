resource "docker_image" "image_handler_build" {
  provider = docker.docker_images
  name = "europe-west3-docker.pkg.dev/${var.project}/${var.cloud_functions_repository_name}/${var.image_handler_docker_image}"
  build {
    context = var.image_handler_dockerfile_location
    dockerfile = "Dockerfile"
    tag = ["${var.image_handler_docker_image}:latest_image_handler"]
    }
}

resource "docker_registry_image" "image_handler_registry" {
  provider = docker.docker_images
  name = resource.docker_image.image_handler_build.name
  keep_remotely = true
}