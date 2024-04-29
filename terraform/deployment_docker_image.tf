terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }
}

provider "docker" {}

resource "docker_image" "image_handler_test" {
  name = "image_handler_test"
  build {
    context = "../cloud_functions/image_handler"
  }
  triggers = {
    dir_sha1 = sha1(join("", [for f in fileset(path.module, "src/*") : filesha1(f)]))
  }
}

resource "docker_container" "cloud_function_container" {
  image = docker_image.image_handler_test.image_id
  name  = "cloud_function_container"
  ports {
    internal = 80
    external = 8000
  }
}