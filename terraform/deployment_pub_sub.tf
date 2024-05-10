# Pub/Sub
# Enable Pub/Sub API
resource "google_project_service" "pubsub_api" {
  service = "pubsub.googleapis.com"
  project = var.project
  disable_on_destroy = false
}

## Define Custom Role for Only Getting and Consuming Subscriptions
resource "google_project_iam_custom_role" "pubsub_subscription_reader" {
  role_id     = "pubsub.subscriptions.read"
  title       = "Get and consume Pub/Sub Subscriptions"
  permissions = ["pubsub.subscriptions.get", "pubsub.subscriptions.consume"]
}


## document_handler
resource "google_pubsub_topic" "document_handler_function" {
    name = var.document_handler_topic_name
    message_storage_policy { allowed_persistence_regions = [ var.region ] }
}

## document_handler subscription
resource "google_pubsub_subscription" "document_handler_sub" {
  name  = var.document_handler_sub_name
  topic = google_pubsub_topic.document_handler_function.name

  ack_deadline_seconds         = 600
  enable_exactly_once_delivery = true
}

## Give Granular Permissions on Pub/Sub Subscriptions
resource "google_pubsub_subscription_iam_binding" "document_handler_get_pubsub" {
  subscription = google_pubsub_subscription.document_handler_sub.name
  role    = "projects/${var.project}/roles/${google_project_iam_custom_role.pubsub_subscription_reader.role_id}"
  members = ["allUsers",]
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

## image_handler subscription
resource "google_pubsub_subscription" "image_handler_sub" {
  name  = var.image_handler_sub_name
  topic = google_pubsub_topic.image_handler_function.name

  ack_deadline_seconds         = 600
  enable_exactly_once_delivery = true
}

## Give Granular Permissions on Pub/Sub Subscriptions
resource "google_pubsub_subscription_iam_binding" "image_handler_get_pubsub" {
  subscription = google_pubsub_subscription.image_handler_sub.name
  role    = "projects/${var.project}/roles/${google_project_iam_custom_role.pubsub_subscription_reader.role_id}"
  members = ["allUsers",]
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

## video_handler subscription
resource "google_pubsub_subscription" "video_handler_sub" {
  name  = var.video_handler_sub_name
  topic = google_pubsub_topic.video_handler_function.name

  ack_deadline_seconds         = 600
  enable_exactly_once_delivery = true
}

## Give Granular Permissions on Pub/Sub Subscriptions
resource "google_pubsub_subscription_iam_binding" "video_handler_get_pubsub" {
  subscription = google_pubsub_subscription.video_handler_sub.name
  role    = "projects/${var.project}/roles/${google_project_iam_custom_role.pubsub_subscription_reader.role_id}"
  members = ["allUsers",]
}
