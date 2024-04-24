resource "google_bigquery_dataset" "bigquery_database" {
  dataset_id                  = var.bigquery_database_name
  friendly_name               = "AI Alchemists Dataset"
  project                     = var.project
  location                    = var.region
}

resource "google_bigquery_table" "bigquery_table" {
  dataset_id          = google_bigquery_dataset.bigquery_database.dataset_id
  deletion_protection = true
  table_id            = var.bigquery_database_table
  project             = var.project
  schema              = <<EOF
[
  {
    "name": "user_id",
    "type": "STRING",
    "mode": "REQUIRED"
  },
  {
    "name": "password",
    "type": "STRING",
    "mode": "REQUIRED"
  },
  {
    "name": "uuid",
    "type": "STRING",
    "mode": "REQUIRED"
  }
]
EOF
}
