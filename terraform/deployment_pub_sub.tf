# Pub/Sub
# Enable Pub/Sub API
resource "google_project_service" "pubsub_api" {
  service = "pubsub.googleapis.com"
  project = var.project
  disable_on_destroy = false
}

## document_handler
resource "google_pubsub_topic" "document_handler_function" {
    name = var.document_handler_topic_name
    message_storage_policy { allowed_persistence_regions = [ var.region ] }
}

## format_classifier
resource "google_pubsub_topic" "format_classifier_function" {
    name = var.format_classifier_topic_name
    message_storage_policy { allowed_persistence_regions = [ var.region ] }
}

## image_handler
resource "google_pubsub_topic" "image_handler_function" {
    name = var.image_handler_topic_name
    message_storage_policy { allowed_persistence_regions = [ var.region ] }
}

## iot_handler
resource "google_pubsub_topic" "iot_handler_function" {
    name = var.iot_handler_topic_name
    message_storage_policy { allowed_persistence_regions = [ var.region ] }
}

## stats_generator
resource "google_pubsub_topic" "stats_generator_function" {
    name = var.stats_generator_topic_name
    message_storage_policy { allowed_persistence_regions = [ var.region ] }
}

## text_processor
resource "google_pubsub_topic" "text_processor_function" {
    name = var.text_processor_topic_name
    message_storage_policy { allowed_persistence_regions = [ var.region ] }
}

## video_handler
resource "google_pubsub_topic" "video_handler_function" {
    name = var.video_handler_topic_name
    message_storage_policy { allowed_persistence_regions = [ var.region ] }
}