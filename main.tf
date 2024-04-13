resource "google_storage_bucket" "my_bucket" {
  name                     = "ingestion_data_bucket"
  project                  = "docai-accelerator"
  location                 = "europe-west3"
  force_destroy            = false
  public_access_prevention = "enforced"
}