module "gcloud" {
  source  = "terraform-google-modules/gcloud/google"
  version = "~> 3.4"
  #skip_download = "true"
  platform = "linux"
  additional_components = ["kubectl", "beta"]

  create_cmd_entrypoint  = "gcloud"
  create_cmd_body        = "version"
  #destroy_cmd_entrypoint = "gcloud"
  #destroy_cmd_body       = "version"
  #depends_on = [ google_project_service.enable_artifact_registry_api ]
}

# web-app
resource "null_resource" "deploy_web_app" {
  # Define triggers based on a frequently changing attribute of an existing Azure resource
  #triggers = {
  #  dir_sha1 = sha1(join("", [for f in fileset(path.module, var.web_app_source_path) : filesha1(f)]))
  #}
  triggers = {always_run = timestamp()}

  # Define provisioner or other configuration as needed
  provisioner "local-exec" {
    command = "gcloud run deploy ${var.web_app_source_name} --region=${var.region} --source=${var.web_app_source_path} --concurrency=80 --ingress=all --max-instances=100 --timeout=3600s --cpu=4 --memory=8Gi --allow-unauthenticated"
  }
}

# document_handler
resource "null_resource" "deploy_document_handler" {
  # Define triggers based on a frequently changing attribute of an existing Azure resource
  #triggers = {
  #  dir_sha1 = sha1(join("", [for f in fileset(path.module, var.document_handler_source_path) : filesha1(f)]))
  #}
  triggers = {always_run = timestamp()}

  # Define provisioner or other configuration as needed
  provisioner "local-exec" {
    command = "gcloud run deploy ${var.document_handler_source_name} --region=${var.region} --source=${var.document_handler_source_path} --concurrency=80 --ingress=all --max-instances=100 --timeout=300s --cpu=2 --memory=4Gi --set-env-vars=[PROJECT_ID=${var.project},TEXT_PROCESSOR_TRIGGER=${google_pubsub_topic.text_processor_function.name},INGESTION_DATA_BUCKET=${google_storage_bucket.ingestion_bucket.name}]"
  }
}

# image_handler
resource "null_resource" "deploy_image_handler" {
  # Define triggers based on a frequently changing attribute of an existing Azure resource
  #triggers = {
  #  dir_sha1 = sha1(join("", [for f in fileset(path.module, var.image_handler_source_path) : filesha1(f)]))
  #}
  triggers = {always_run = timestamp()}

  # Define provisioner or other configuration as needed
  provisioner "local-exec" {
    command = "gcloud run deploy ${var.image_handler_source_name} --region=${var.region} --source=${var.image_handler_source_path} --concurrency=80 --ingress=all --max-instances=100 --timeout=900s --cpu=8 --memory=32Gi --set-env-vars=[PROJECT_ID=${var.project},TEXT_PROCESSOR_TRIGGER=${google_pubsub_topic.text_processor_function.name},INGESTION_DATA_BUCKET=${google_storage_bucket.ingestion_bucket.name},FIRESTORE_DATABASE_ID=${var.firestore_database_name}]"
  }
}

# video_handler
resource "null_resource" "video_image_handler" {
  # Define triggers based on a frequently changing attribute of an existing Azure resource
  #triggers = {
  #  dir_sha1 = sha1(join("", [for f in fileset(path.module, var.video_handler_source_path) : filesha1(f)]))
  #}
  triggers = {always_run = timestamp()}

  # Define provisioner or other configuration as needed
  provisioner "local-exec" {
    command = "gcloud run deploy ${var.video_handler_source_name} --region=${var.region} --source=${var.video_handler_source_path} --concurrency=80 --ingress=all --max-instances=100 --timeout=900s --cpu=8 --memory=32Gi --set-env-vars=[PROJECT_ID=${var.project},TEXT_PROCESSOR_TRIGGER=${google_pubsub_topic.text_processor_function.name},INGESTION_DATA_BUCKET=${google_storage_bucket.ingestion_bucket.name}]"
  }
}