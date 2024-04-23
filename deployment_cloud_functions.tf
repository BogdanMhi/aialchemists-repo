## image_handler
data "archive_file" "zip_image_handler" {
  type        = "zip"
  source_dir  = "cloud_functions/image_handler"
  output_path = "assets/image_handler.zip"
}


resource "google_storage_bucket_object" "image_handler_sourcecode" {
  name = format(
    "%s#%s",
    "image_handler/function-source.zip",
    data.archive_file.zip_image_handler.output_md5
  )
  bucket = "gcf-v2-sources-957891796445-europe-west3"
  source = "assets/image_handler.zip" # Add path to the zipped function source code
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


## video_handler
data "archive_file" "zip_video_handler" {
  type        = "zip"
  source_dir  = "cloud_functions/video_handler"
  output_path = "assets/video_handler.zip"
}


resource "google_storage_bucket_object" "video_handler_sourcecode" {
  name = format(
    "%s#%s",
    "video_handler/function-source.zip",
    data.archive_file.zip_video_handler.output_md5
  )
  bucket = "gcf-v2-sources-957891796445-europe-west3"
  source = "assets/video_handler.zip" # Add path to the zipped function source code
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


## iot_handler
data "archive_file" "zip_IoT_handler" {
  type        = "zip"
  source_dir  = "cloud_functions/IoT_handler"
  output_path = "assets/IoT_handler.zip"
}


resource "google_storage_bucket_object" "iot_handler_sourcecode" {
  name = format(
    "%s#%s",
    "IoT_handler/function-source.zip",
    data.archive_file.zip_IoT_handler.output_md5
  )
  bucket = "gcf-v2-sources-957891796445-europe-west3"
  source = "assets/IoT_handler.zip" # Add path to the zipped function source code
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
    pubsub_topic   = "projects/${var.project}/topics/${google_pubsub_topic.iot_handler_function.name}"
    resource   = google_pubsub_topic.iot_handler_function.name
  }

  source_archive_bucket = "gcf-v2-sources-957891796445-europe-west3"
  source_archive_object = google_storage_bucket_object.iot_handler_sourcecode.name


  depends_on = [
    google_storage_bucket_object.iot_handler_sourcecode
  ]
}