terraform {
  required_version = ">= 0.13"

  backend "gcs" {
    bucket = "tf_state_8d85fe"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = var.project
  # region  = var.region
  # zone    = var.zone
}