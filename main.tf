resource "google_storage_bucket" "my_bucket" {
  name                     = "ingestion_data_bucket"
  project                  = "docai-accelerator"
  location                 = "europe-west3"
  force_destroy            = false
  public_access_prevention = "enforced"
}

# ## to_pdf_converter
# resource "google_cloudfunctions2_function" "image_handler" {
#   location = "europe-west3"
#   name     = "image_handler"



#   timeouts {
#     create = "60m"
#     update = "60m"
#   }



#   build_config {
#     runtime     = "python38"
#     entry_point = "image_handler"
#     # docker_repository                        = "projects/docai-accelerator/locations/${var.region}/repositories/${var.cloudfunctions_artifactstorage_name}"
#   }
#   service_config {
#     max_instance_count = 350
#     available_memory   = "4G"
#     available_cpu      = "4"
#     timeout_seconds    = 540
#   }


#   event_trigger {
#     trigger_region = "europe-west3"
#     event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
#     pubsub_topic   = "projects/docai-accelerator/topics/image_handler_topic"
#     retry_policy   = "RETRY_POLICY_DO_NOT_RETRY"
#   }
# }



resource "google_cloudfunctions_function_v2" "image_handler" {
  name        = "image-handler"
  description = "Handles images"
  region      = "europe-west3"

  build_environment_variables = {
    FUNCTION_SOURCE = "cloud_functions/image_handler"
  }

  timeouts {
    create = "60m"
    update = "60m"
  }

  entry_point = "image_handler"
  runtime     = "python38"

  build_config {
    entry_point = "image_handler"
    runtime     = "python38"
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
}
