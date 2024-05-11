## Cloud Build
# web-app FE
variable web_app_source_path {default = "../frontend/"}
variable web_app_source_name {default = "web-app"}

#document_handler
variable document_handler_source_path {default = "../cloud_functions/document_handler/"}
variable document_handler_source_name {default = "document-handler"}

#image_handler
variable image_handler_source_path {default = "../cloud_functions/image_handler/"}
variable image_handler_source_name {default = "image-handler"}

#video_handler
variable video_handler_source_path {default = "../cloud_functions/video_handler/"}
variable video_handler_source_name {default = "video-handler"}