## document_handler
resource "docker_image" "document_handler_build" {
  provider = docker.docker_images
  name = "${var.region}-docker.pkg.dev/${var.project}/${var.cloud_functions_repository_name}/${var.document_handler_docker_image}:version_2"
  build {
    context = var.document_handler_dockerfile_location
    dockerfile = "Dockerfile"
    tag = ["version_2"]
  }

  triggers = {always_run = timestamp()}
  keep_locally = false
  depends_on = [google_artifact_registry_repository.cf_repository]
}

resource "docker_registry_image" "document_handler_push" {
  provider = docker.docker_images
  name = resource.docker_image.document_handler_build.name
  #keep_remotely = true
  depends_on = [docker_image.document_handler_build]
}

## image_handler
resource "docker_image" "image_handler_build" {
  provider = docker.docker_images
  name = "${var.region}-docker.pkg.dev/${var.project}/${var.cloud_functions_repository_name}/${var.image_handler_docker_image}:version_1"
  build {
    context = var.image_handler_dockerfile_location
    dockerfile = "Dockerfile"
    tag = ["version_1"]
  }

  triggers = {always_run = timestamp()}
  keep_locally = false
  depends_on = [ docker_registry_image.document_handler_push ]
}

resource "docker_registry_image" "image_handler_push" {
  provider = docker.docker_images
  name = resource.docker_image.image_handler_build.name
  #keep_remotely = true
  depends_on = [ docker_image.image_handler_build ]
}

## video_handler
resource "docker_image" "video_handler_build" {
  provider = docker.docker_images
  name = "${var.region}-docker.pkg.dev/${var.project}/${var.cloud_functions_repository_name}/${var.video_handler_docker_image}:version_2"
  build {
    context = var.video_handler_dockerfile_location
    dockerfile = "Dockerfile"
    tag = ["version_2"]
  }

  triggers = {always_run = timestamp()}
  keep_locally = false
  depends_on = [ docker_registry_image.image_handler_push ]
}

resource "docker_registry_image" "video_handler_push" {
  provider = docker.docker_images
  name = resource.docker_image.video_handler_build.name
  #keep_remotely = true
  depends_on = [ docker_image.video_handler_build ]
}