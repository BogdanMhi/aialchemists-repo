resource "docker_registry_image" "image_handler_registry_push" {
  provider = docker.docker_images
  name = docker_image.image_handler_build.name
  #"europe-west3-docker.pkg.dev/${var.project}/${var.cloud_functions_repository_name}/${var.image_handler_docker_image}:1.0"
  #keep_remotely = true
}

resource "docker_image" "image_handler_build" {
  provider = docker.docker_images
  name = "europe-west3-docker.pkg.dev/${var.project}/${var.cloud_functions_repository_name}/${var.image_handler_docker_image}:tag_test"
  build {
    context = var.image_handler_dockerfile_location
    dockerfile = "Dockerfile"
    tag     = ["${var.image_handler_docker_image}:tag_test"]
    }
}