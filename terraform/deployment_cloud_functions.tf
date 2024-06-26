## Create Service Account for Cloud Functions
#resource "google_service_account" "cloud_functions" {
#  project = var.project
#  account_id = var.cloud_functions_sa_id
#  display_name = var.cloud_functions_sa_display
#  description = "Service Account for Cloud Functions"
#}

## format_classifier
data "archive_file" "zip_format_classifier" {
  type        = "zip"
  source_dir  = "../cloud_functions/format_classifier"
  output_path = "assets/format_classifier.zip"
}

resource "google_storage_bucket_object" "format_classifier_sourcecode" {
  name = format(
    "%s#%s",
    "format_classifier/function-source.zip",
    data.archive_file.zip_format_classifier.output_md5
  )
  bucket = "gcf-v2-sources-957891796445-europe-west3"
  source = data.archive_file.zip_format_classifier.output_path
}

resource "google_cloudfunctions_function" "format_classifier" {
  timeouts {
    create = "60m"
    update = "60m"
  }

  region              = var.region
  name                = var.format_classifier_function_name
  entry_point         = var.format_classifier_entry_point
  runtime             = var.format_classifier_python_version
  timeout             = 540
  max_instances       = 500
  available_memory_mb = var.format_classifier_function_memory

  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.format_classifier_function.name
  }

  source_archive_bucket = "gcf-v2-sources-957891796445-europe-west3"
  source_archive_object = google_storage_bucket_object.format_classifier_sourcecode.name

  environment_variables = {
    PROJECT_ID               = var.project
    DOCUMENT_HANDLER_TRIGGER = google_pubsub_topic.document_handler_function.name
    IMAGE_HANDLER_TRIGGER    = google_pubsub_topic.image_handler_function.name
    IOT_HANDLER_TRIGGER      = google_pubsub_topic.iot_handler_function.name
    INGESTION_DATA_BUCKET    = google_storage_bucket.ingestion_bucket.name
    TEXT_PROCESSOR_TRIGGER   = google_pubsub_topic.text_processor_function.name
    VIDEO_HANDLER_TRIGGER    = google_pubsub_topic.video_handler_function.name
  }

  depends_on = [
    google_storage_bucket_object.format_classifier_sourcecode
  ]
}

## iot_handler
data "archive_file" "zip_iot_handler" {
  type        = "zip"
  source_dir  = "../cloud_functions/IoT_handler"
  output_path = "assets/iot_handler.zip"
}

resource "google_storage_bucket_object" "iot_handler_sourcecode" {
  name = format(
    "%s#%s",
    "iot_handler/function-source.zip",
    data.archive_file.zip_iot_handler.output_md5
  )
  bucket = "gcf-v2-sources-957891796445-europe-west3"
  source = data.archive_file.zip_iot_handler.output_path
}

resource "google_cloudfunctions_function" "iot_handler" {
  timeouts {
    create = "60m"
    update = "60m"
  }

  region              = var.region
  name                = var.iot_handler_function_name
  entry_point         = var.iot_handler_entry_point
  runtime             = var.iot_handler_python_version
  timeout             = 540
  max_instances       = 500
  available_memory_mb = var.iot_handler_function_memory

  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.iot_handler_function.name
  }

  source_archive_bucket = "gcf-v2-sources-957891796445-europe-west3"
  source_archive_object = google_storage_bucket_object.iot_handler_sourcecode.name

  environment_variables = {
    PROJECT_ID = var.project
    TEXT_PROCESSOR_TRIGGER = google_pubsub_topic.text_processor_function.name
  }

  depends_on = [
    google_storage_bucket_object.iot_handler_sourcecode
  ]
}

## stats_generator
data "archive_file" "zip_stats_generator" {
  type        = "zip"
  source_dir  = "../cloud_functions/stats_generator"
  output_path = "assets/stats_generator.zip"
}

resource "google_storage_bucket_object" "stats_generator_sourcecode" {
  name = format(
    "%s#%s",
    "stats_generator/function-source.zip",
    data.archive_file.zip_stats_generator.output_md5
  )
  bucket = "gcf-v2-sources-957891796445-europe-west3"
  source = data.archive_file.zip_stats_generator.output_path
}

resource "google_cloudfunctions_function" "stats_generator" {
  timeouts {
    create = "60m"
    update = "60m"
  }

  region                        = var.region
  name                          = var.stats_generator_function_name
  entry_point                   = var.stats_generator_entry_point
  runtime                       = var.stats_generator_python_version
  ingress_settings              = var.ingress_selection
  vpc_connector                 = var.vpc_access_connector
  vpc_connector_egress_settings = var.vpc_egress
  timeout                       = 540
  max_instances                 = 500
  available_memory_mb           = var.stats_generator_function_memory

  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.stats_generator_function.name
  }

  source_archive_bucket = "gcf-v2-sources-957891796445-europe-west3"
  source_archive_object = google_storage_bucket_object.stats_generator_sourcecode.name

  environment_variables = {
    PROJECT_ID = var.project
    FIRESTORE_DATABASE_ID = var.firestore_database_name
    BIGQUERY_DATABASE_ID = "${var.project}.${var.bigquery_database_name}.${var.bigquery_database_table}"
    HISTORY_COLLECTION = "history"
    AZURE_OPENAI_API_KEY = var.text_processor_azure_api_key
    AZURE_OPENAI_ENDPOINT = var.text_processor_azure_endpoint
    FE_APP_NAME = var.web_app_source_name
  }

  depends_on = [
    google_storage_bucket_object.stats_generator_sourcecode
  ]
}

## text_processor
data "archive_file" "zip_text_processor" {
  type        = "zip"
  source_dir  = "../cloud_functions/text_processor"
  output_path = "assets/text_processor.zip"
}

resource "google_storage_bucket_object" "text_processor_sourcecode" {
  name = format(
    "%s#%s",
    "text_processor/function-source.zip",
    data.archive_file.zip_text_processor.output_md5
  )
  bucket = "gcf-v2-sources-957891796445-europe-west3"
  source = data.archive_file.zip_text_processor.output_path
}

resource "google_cloudfunctions_function" "text_processor" {
  timeouts {
    create = "60m"
    update = "60m"
  }

  region                        = var.region
  name                          = var.text_processor_function_name
  entry_point                   = var.text_processor_entry_point
  runtime                       = var.text_processor_python_version
  timeout                       = 540
  max_instances                 = 500
  ingress_settings              = var.ingress_selection
  vpc_connector                 = var.vpc_access_connector
  vpc_connector_egress_settings = var.vpc_egress
  available_memory_mb           = var.text_processor_function_memory

  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.text_processor_function.name
  }

  source_archive_bucket = "gcf-v2-sources-957891796445-europe-west3"
  source_archive_object = google_storage_bucket_object.text_processor_sourcecode.name

  environment_variables = {
    PROJECT_ID = var.project
    FIRESTORE_DATABASE_ID = var.firestore_database_name
    BIGQUERY_DATABASE_ID = "${var.project}.${var.bigquery_database_name}.${var.bigquery_database_table}"
    AZURE_OPENAI_API_KEY = var.text_processor_azure_api_key
    AZURE_OPENAI_ENDPOINT = var.text_processor_azure_endpoint
    FE_APP_NAME = var.web_app_source_name
  }

  depends_on = [
    google_storage_bucket_object.text_processor_sourcecode
  ]
}