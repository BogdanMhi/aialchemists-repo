## document_handler
data "archive_file" "zip_document_handler" {
  type        = "zip"
  source_dir  = "../cloud_functions/document_handler"
  output_path = "assets/document_handler.zip"
}

resource "google_storage_bucket_object" "document_handler_sourcecode" {
  name = format(
    "%s#%s",
    "document_handler/function-source.zip",
    data.archive_file.zip_document_handler.output_md5
  )
  bucket = "gcf-v2-sources-957891796445-europe-west3"
  source = data.archive_file.zip_document_handler.output_path
}

resource "google_cloudfunctions2_function" "document_handler" {
  location = var.region
  name     = var.document_handler_function_name
  project  = var.project

  timeouts {
    create = "60m"
    update = "60m"
  }

  build_config {
    runtime     = var.document_handler_python_version
    entry_point = var.document_handler_entry_point
    source {
      storage_source {
        bucket = "gcf-v2-sources-957891796445-europe-west3"
        object = google_storage_bucket_object.document_handler_sourcecode.name
      }
    }
  }

  service_config {
    environment_variables = {
      PROJECT_ID = var.project
      TEXT_PROCESSOR_TRIGGER = google_pubsub_topic.text_processor_function.name
    }
    max_instance_count = 350
    available_memory   = var.document_handler_function_memory
    available_cpu      = "4"
    timeout_seconds    = 540
  }

  event_trigger {
    trigger_region = var.region
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = "projects/${var.project}/topics/${google_pubsub_topic.document_handler_function.name}"
    retry_policy   = "RETRY_POLICY_DO_NOT_RETRY"
  }

  depends_on = [
    google_storage_bucket_object.document_handler_sourcecode
  ]
}

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

## image_handler
data "archive_file" "zip_image_handler" {
  type        = "zip"
  source_dir  = "../cloud_functions/image_handler"
  output_path = "assets/image_handler.zip"
}

resource "google_storage_bucket_object" "image_handler_sourcecode" {
  name = format(
    "%s#%s",
    "image_handler/function-source.zip",
    data.archive_file.zip_image_handler.output_md5
  )
  bucket = "gcf-v2-sources-957891796445-europe-west3"
  source = data.archive_file.zip_image_handler.output_path
}

resource "google_cloudfunctions2_function" "image_handler" {
  location = var.region
  name     = var.image_handler_function_name
  project  = var.project

  timeouts {
    create = "60m"
    update = "60m"
  }

  build_config {
    runtime     = var.image_handler_python_version
    entry_point = var.image_handler_entry_point
    source {
      storage_source {
        bucket = "gcf-v2-sources-957891796445-europe-west3"
        object = google_storage_bucket_object.image_handler_sourcecode.name
      }
    }
  }

  service_config {
    environment_variables = {
      PROJECT_ID = var.project
      TEXT_PROCESSOR_TRIGGER = google_pubsub_topic.text_processor_function.name
    }
    max_instance_count = 350
    available_memory   = var.image_handler_function_memory
    available_cpu      = "4"
    timeout_seconds    = 540
  }

  event_trigger {
    trigger_region = var.region
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = "projects/${var.project}/topics/${google_pubsub_topic.image_handler_function.name}"
    retry_policy   = "RETRY_POLICY_DO_NOT_RETRY"
  }

  depends_on = [
    google_storage_bucket_object.image_handler_sourcecode
  ]
}

## iot_handler
data "archive_file" "zip_IoT_handler" {
  type        = "zip"
  source_dir  = "../cloud_functions/IoT_handler"
  output_path = "assets/IoT_handler.zip"
}

resource "google_storage_bucket_object" "iot_handler_sourcecode" {
  name = format(
    "%s#%s",
    "IoT_handler/function-source.zip",
    data.archive_file.zip_IoT_handler.output_md5
  )
  bucket = "gcf-v2-sources-957891796445-europe-west3"
  source = data.archive_file.zip_IoT_handler.output_path
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

  region              = var.region
  name                = var.text_processor_function_name
  entry_point         = var.text_processor_entry_point
  runtime             = var.text_processor_python_version
  timeout             = 540
  max_instances       = 500
  available_memory_mb = var.text_processor_function_memory

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
  }

  depends_on = [
    google_storage_bucket_object.text_processor_sourcecode
  ]
}

## video_handler
data "archive_file" "zip_video_handler" {
  type        = "zip"
  source_dir  = "../cloud_functions/video_handler"
  output_path = "assets/video_handler.zip"
}

resource "google_storage_bucket_object" "video_handler_sourcecode" {
  name = format(
    "%s#%s",
    "video_handler/function-source.zip",
    data.archive_file.zip_video_handler.output_md5
  )
  bucket = "gcf-v2-sources-957891796445-europe-west3"
  source = data.archive_file.zip_video_handler.output_path
}

resource "google_cloudfunctions2_function" "video_handler" {
  location = var.region
  name     = var.video_handler_function_name
  project  = var.project

  timeouts {
    create = "60m"
    update = "60m"
  }

  build_config {
    runtime     = var.video_handler_python_version
    entry_point = var.video_handler_entry_point
    source {
      storage_source {
        bucket = "gcf-v2-sources-957891796445-europe-west3"
        object = google_storage_bucket_object.video_handler_sourcecode.name
      }
    }
  }

  service_config {
    environment_variables = {
      PROJECT_ID = var.project
      TEXT_PROCESSOR_TRIGGER = google_pubsub_topic.text_processor_function.name
    }
    max_instance_count = 350
    available_memory   = var.video_handler_function_memory
    available_cpu      = "4"
    timeout_seconds    = 540
  }

  event_trigger {
    trigger_region = var.region
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = "projects/${var.project}/topics/${google_pubsub_topic.video_handler_function.name}"
    retry_policy   = "RETRY_POLICY_DO_NOT_RETRY"
  }

  depends_on = [
    google_storage_bucket_object.video_handler_sourcecode
  ]
}