## bigquery_database
variable bigquery_database_name {default = "ai_alchemists_user_table"}
variable bigquery_database_table {default = "users"}

## idempotency
variable bigquery_idempotency_dataset {default = "idempotency"}
variable bigquery_idempotency_document_handler {default = "document_handler_msg_ids"}
variable bigquery_idempotency_image_handler {default = "image_handler_msg_ids"}
variable bigquery_idempotency_video_handler {default = "video_handler_msg_ids"}