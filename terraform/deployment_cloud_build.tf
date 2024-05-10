module "gcloud" {
  source  = "terraform-google-modules/gcloud/google"
  version = "~> 3.4"

  platform = "linux"
  additional_components = ["kubectl", "beta"]

  create_cmd_entrypoint  = "gcloud"
  create_cmd_body        = "version"
  #destroy_cmd_entrypoint = "gcloud"
  #destroy_cmd_body       = "version"
}

resource "null_resource" "deploy_web_app" {
  # Define triggers based on a frequently changing attribute of an existing Azure resource
  triggers = {
    dir_sha1 = sha1(join("", [for f in fileset(path.module, var.web_app_source_path) : filesha1(f)]))
  }

  # Define provisioner or other configuration as needed
  provisioner "local-exec" {
    command = "gcloud run deploy web-app-tg --region=${var.region} --source=${var.web_app_source_path} --concurrency=80 --ingress=all --max-instances=100 --timeout=3600s --cpu=4 --memory=8Gi"
  }
}