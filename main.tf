resource "google_storage_bucket" "my_bucket" {
  name                     = "ingestion_data_bucket"
  project                  = "docai-accelerator"
  location                 = "europe-west3"
  force_destroy            = false
  public_access_prevention = "enforced"
}

data "archive_file" "zip" {
  type        = "zip"
  source_dir  = "cloud_functions/image_handler"
  output_path = "assets/function-image_handler.zip"
}

resource "google_storage_bucket_object" "sourcecode" {
  name   = "image_handler/function-source.zip"
  bucket = "gcf-v2-sources-957891796445-europe-west3"
  source = "assets/function-image_handler.zip" # Add path to the zipped function source code
  # description = data.archive_file.zip.md5 != data.google_storage_bucket_object.sourcecode.md5 ? data.archive_file.zip.md5 : null
}

resource "null_resource" "remove_zip" {
  triggers = {
    zip_path = "assets/function-image_handler.zip"
  }

  provisioner "local-exec" {
    command = "rm assets/function-image_handler.zip"
  }
  depends_on = [ google_storage_bucket_object.sourcecode ]
}

## to_pdf_converter
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
    # docker_repository                        = "projects/docai-accelerator/locations/${var.region}/repositories/${var.cloudfunctions_artifactstorage_name}"
    source {
      storage_source {
        bucket = "gcf-v2-sources-957891796445-europe-west3"
        object = "image_handler/function-source.zip"
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

  lifecycle {
    replace_triggered_by = [google_storage_bucket_object.sourcecode]
  }
}