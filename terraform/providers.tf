terraform {
  required_version = ">= 0.13"

  backend "gcs" {
    bucket = "tf_state_8d85fe"
    prefix = "terraform/state"
  }

  required_providers {
    google = {source = "hashicorp/google"}
    random = {source = "hashicorp/random"}
    docker = {source = "kreuzwerker/docker"}
  }
}

provider "google" {
  project = var.project
  region  = var.region
  # zone    = var.zone
}

provider "docker" {
  registry_auth {
    address  = "europe-west3-docker.pkg.dev"
  }
  project = var.project
  region  = var.region
}