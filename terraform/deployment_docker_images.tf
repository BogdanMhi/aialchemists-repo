terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }
}

provider "docker" {
  registry_auth {
    address  = "europe-west3-docker.pkg.dev"
  }
}

resource "docker_image" "image_handler_build" {
  name = "europe-west3-docker.pkg.dev/${var.project}/${var.cloud_functions_repository_name}/${var.image_handler_docker_image}:1.0"
  build {
    context = "${var.image_handler_dockerfile_location}"
  }
}

resource "docker_registry_image" "image_handler_registry_push" {
  name          = "europe-west3-docker.pkg.dev/${var.project}/${var.cloud_functions_repository_name}/${var.image_handler_docker_image}:1.0"
  #keep_remotely = true
}

#resource "docker_registry_image" "image_handler_image" {
#  name = "europe-west3-docker.pkg.dev/${var.project}/${var.cloud_functions_repository_name}/${var.image_handler_docker_image}"
#  build {
#    context = "${var.image_handler_dockerfile_location}"
#    dockerfile = "Dockerfile"
#  }
#}