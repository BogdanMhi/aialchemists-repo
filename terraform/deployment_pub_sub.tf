# Pub/Sub Topics
## document_handler
resource "google_pubsub_topic" "document_handler_function" {
    name = var.document_handler_topic_name

    message_storage_policy {
        allowed_persistance_regions = [var.region]
    }
}


## format_classifier
resource "google_pubsub_topic" "format_classifier_function" {
    name = var.format_classifier_topic_name

    message_storage_policy {
        allowed_persistance_regions = [var.region]
    }
}

## image_handler
resource "google_pubsub_topic" "image_handler_function" {
    name = var.image_handler_topic_name

    message_storage_policy {
        allowed_persistance_regions = [var.region]
    }
}


## iot_handler
resource "google_pubsub_topic" "iot_handler_function" {
    name = var.iot_handler_topic_name

    message_storage_policy {
        allowed_persistance_regions = [var.region]
    }
}


## text_processor
resource "google_pubsub_topic" "text_processor_function" {
    name = var.text_processor_topic_name

    message_storage_policy {
        allowed_persistance_regions = [var.region]
    }
}


## video_handler
resource "google_pubsub_topic" "video_handler_function" {
    name = var.video_handler_topic_name

    message_storage_policy {
        allowed_persistance_regions = [var.region]
    }
}