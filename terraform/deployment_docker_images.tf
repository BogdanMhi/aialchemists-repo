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
}

resource "docker_registry_image" "document_handler_push" {
  provider = docker.docker_images
  name = resource.docker_image.document_handler_build.name
  keep_remotely = true
}

## image_handler
locals {
  art_reg   = "${var.region}-docker.pkg.dev/${var.project}/${var.cloud_functions_repository_name}"
  art_imag  = var.image_handler_docker_image
  image_tag = "version_1"

  img_src_path = var.image_handler_dockerfile_location
  img_src_sha256 = sha256(join("", [for f in fileset(".", "${local.img_src_path}/**") : file(f)]))

  build_cmd = <<-EOT
        gcloud run deploy ${var.image_handler_docker_image} --region=${var.region} --source=${local.img_src_path} ${local.img_src_path} 
    EOT

}

variable "force_image_rebuild" {
  type    = bool
  default = false
}

# local-exec for build and push of docker image
resource "null_resource" "build_push_image_handler" {
  triggers = {
    detect_docker_source_changes = var.force_image_rebuild == true ? timestamp() : local.img_src_sha256
  }
  provisioner "local-exec" {
    command = local.build_cmd
  }
}

output "trigged_by" {
  value = null_resource.build_push_image_handler.triggers
}

#resource "docker_image" "image_handler_build" {
#  provider = docker.docker_images
#  name = "${var.region}-docker.pkg.dev/${var.project}/${var.cloud_functions_repository_name}/${var.image_handler_docker_image}:version_1"
#  build {
#    context = var.image_handler_dockerfile_location
#    dockerfile = "Dockerfile"
#    tag = ["version_1"]
#  }

#  triggers = {always_run = timestamp()}
#}

#resource "docker_registry_image" "image_handler_push" {
#  provider = docker.docker_images
#  name = resource.docker_image.image_handler_build.name
#  keep_remotely = true
#}

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
}

resource "docker_registry_image" "video_handler_push" {
  provider = docker.docker_images
  name = resource.docker_image.video_handler_build.name
  keep_remotely = true
}