## Generate random number for bucket name
resource "random_id" "ingestion_bucket_storage" {
  byte_length = 3
}

## Create GCS bucket
resource "google_storage_bucket" "ingestion_bucket" {
  project                  = var.project
  name                     = "${var.ingestion_data_bucket_name}_${lower(random_id.ingestion_bucket_storage.hex)}
  location                 = var.region
  force_destroy            = false
  public_access_prevention = "enforced"

  lifecycle_rule {
    action { type = "Delete" }
    condition { age = var.object_lifecycle_age }
  }
}