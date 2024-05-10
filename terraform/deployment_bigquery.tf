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
  },
  {
    "name": "admin",
    "type": "STRING",
    "mode": "NULLABLE"
  }
]
EOF
}

## idempotency
#dataset
resource "google_bigquery_dataset" "bq_idempotency_dataset" {
  dataset_id                  = var.bigquery_idempotency_dataset
  friendly_name               = "AI Alchemists Idempotency Dataset"
  project                     = var.project
  location                    = var.region
}

#tables
resource "google_bigquery_table" "bg_idempotency_document_table" {
  dataset_id          = google_bigquery_dataset.bq_idempotency_dataset.dataset_id
  deletion_protection = true
  table_id            = var.bigquery_idempotency_document_handler
  project             = var.project
  schema              = <<EOF
[
  {
    "name": "message_id",
    "type": "STRING",
    "mode": "REQUIRED"
  }
]
EOF
}

resource "google_bigquery_table" "bg_idempotency_image_table" {
  dataset_id          = google_bigquery_dataset.bq_idempotency_dataset.dataset_id
  deletion_protection = true
  table_id            = var.bigquery_idempotency_image_handler
  project             = var.project
  schema              = <<EOF
[
  {
    "name": "message_id",
    "type": "STRING",
    "mode": "REQUIRED"
  }
]
EOF
}

resource "google_bigquery_table" "bg_idempotency_video_table" {
  dataset_id          = google_bigquery_dataset.bq_idempotency_dataset.dataset_id
  deletion_protection = true
  table_id            = var.bigquery_idempotency_video_handler
  project             = var.project
  schema              = <<EOF
[
  {
    "name": "message_id",
    "type": "STRING",
    "mode": "REQUIRED"
  }
]
EOF
}