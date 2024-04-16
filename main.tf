terraform {
  required_version = ">= 0.13"

  backend "gcs" {
    bucket = "tf_state_8d85fe"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = "docai-accelerator"
  # region  = var.region
  # zone    = var.zone
}


resource "google_storage_bucket" "my_bucket" {
  name                     = "ingestion_data_bucket"
  project                  = "docai-accelerator"
  location                 = "europe-west3"
  force_destroy            = false
  public_access_prevention = "enforced"
}

data "archive_file" "zip_image_handler" {
  type        = "zip"
  source_dir  = "cloud_functions/image_handler"
  output_path = "assets/image_handler.zip"
}

resource "google_storage_bucket_object" "sourcecode_image_handler" {
  name = format(
    "%s#%s",
    "image_handler/function-source.zip",
    data.archive_file.zip_image_handler.output_md5
  )
  bucket = "gcf-v2-sources-957891796445-europe-west3"
  source = "assets/image_handler.zip" # Add path to the zipped function source code
}

## image_handler
resource "google_cloudfunctions2_function" "image_handler" {
  location = "europe-west3"
  name     = "image_handler"
  project  = "docai-accelerator"

  timeouts {
    create = "60m"
    update = "60m"
  }

  build_config {
    runtime     = "python38"
    entry_point = "image_handler"
    source {
      storage_source {
        bucket = "gcf-v2-sources-957891796445-europe-west3"
        object = google_storage_bucket_object.sourcecode_image_handler.name
      }
    }
  }

  service_config {
    max_instance_count = 350
    available_memory   = "4G"
    available_cpu      = "4"
    timeout_seconds    = 540
  }


  event_trigger {
    trigger_region = "europe-west3"
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = "projects/docai-accelerator/topics/image_handler_topic"
    retry_policy   = "RETRY_POLICY_DO_NOT_RETRY"
  }

  depends_on = [
    google_storage_bucket_object.sourcecode_image_handler
    ]
}


data "archive_file" "zip_IoT_handler" {
  type        = "zip"
  source_dir  = "cloud_functions/IoT_handler"
  output_path = "assets/IoT_handler.zip"
}

resource "google_storage_bucket_object" "sourcecode_IoT_handler" {
  name = format(
    "%s#%s",
    "IoT_handler/function-source.zip",
    data.archive_file.zip_IoT_handler.output_md5
  )
  bucket = "gcf-v2-sources-957891796445-europe-west3"
  source = "assets/IoT_handler.zip" # Add path to the zipped function source code
}

## IoT_handler
resource "google_cloudfunctions_function" "IoT_handler" {
  timeouts {
    create = "60m"
    update = "60m"
  }

  region                        = "europe-west3"
  name                          = "IoT_handler"
  entry_point                   = "IoT_handler"
  runtime                       = "python38"
  timeout                       = 540
  max_instances                 = 500
  available_memory_mb           = 2048

  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = "iot_handler"
  }

  source_archive_bucket         = "gcf-v2-sources-957891796445-europe-west3"
  source_archive_object         = google_storage_bucket_object.sourcecode_IoT_handler.name


  depends_on = [
    google_storage_bucket_object.sourcecode_IoT_handler
  ]
}


data "archive_file" "zip_video_handler" {
  type        = "zip"
  source_dir  = "cloud_functions/video_handler"
  output_path = "assets/video_handler.zip"
}

resource "google_storage_bucket_object" "sourcecode_video_handler" {
  name = format(
    "%s#%s",
    "video_handler/function-source.zip",
    data.archive_file.zip_video_handler.output_md5
  )
  bucket = "gcf-v2-sources-957891796445-europe-west3"
  source = "assets/video_handler.zip" # Add path to the zipped function source code
}

## video_handler
resource "google_cloudfunctions2_function" "video_handler" {
  location = "europe-west3"
  name     = "video_handler"
  project  = "docai-accelerator"

  timeouts {
    create = "60m"
    update = "60m"
  }

  build_config {
    runtime     = "python38"
    entry_point = "video_handler"
    source {
      storage_source {
        bucket = "gcf-v2-sources-957891796445-europe-west3"
        object = google_storage_bucket_object.sourcecode_video_handler.name
      }
    }
  }

  service_config {
    max_instance_count = 350
    available_memory   = "8G"
    available_cpu      = "4"
    timeout_seconds    = 540
  }


  event_trigger {
    trigger_region = "europe-west3"
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = "projects/docai-accelerator/topics/video_handler"
    retry_policy   = "RETRY_POLICY_DO_NOT_RETRY"
  }

  depends_on = [
    google_storage_bucket_object.sourcecode_video_handler
    ]
}