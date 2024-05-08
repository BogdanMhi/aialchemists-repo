resource "docker_image" "image_handler_build" {
  provider = docker.docker_images
  name = "${var.region}-docker.pkg.dev/${var.project}/${var.cloud_functions_repository_name}/${var.image_handler_docker_image}:latest"
  build {
    context = var.image_handler_dockerfile_location
    dockerfile = "Dockerfile"
    tag = ["${var.image_handler_docker_image}:V_001"]
  }
  triggers = {
    dir_sha1 = sha1(join("", [for f in fileset(path.module, "${var.image_handler_dockerfile_location}/*") : filesha1(f)]))
  }
}

resource "docker_registry_image" "image_handler_registry" {
  provider = docker.docker_images
  name = resource.docker_image.image_handler_build.name
  keep_remotely = true
}