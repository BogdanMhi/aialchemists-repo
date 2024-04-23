# Pub/Sub Topics
## image_handler
resource "google_pubsub_topic" "image_handler_function" {
    name = var.image_handler_topic_name

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

## iot_handler
resource "google_pubsub_topic" "iot_handler_function" {
    name = var.iot_handler_topic_name

    message_storage_policy {
        allowed_persistance_regions = [var.region]
    }
}