resource "google_storage_bucket" "ingestion_bucket" {
  project                  = var.project
  name                     = var.ingestion_data_bucket_name
  location                 = var.region
  force_destroy            = false
  public_access_prevention = "enforced"
}