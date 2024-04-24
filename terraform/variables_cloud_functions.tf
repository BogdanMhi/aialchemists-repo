## document_handler
variable document_handler_function_name {default = "document_handler"}
variable document_handler_function_memory {default = "4G"}
variable document_handler_entry_point {default = "document_handler"}
variable document_handler_python_version {default = "python312"}

## format_classifier
variable format_classifier_function_name {default = "format_classifier"}
variable format_classifier_function_memory {default = 2048}
variable format_classifier_entry_point {default = "format_classifier"}
variable format_classifier_python_version {default = "python38"}

## image_handler
variable image_handler_function_name {default = "image_handler"}
variable image_handler_function_memory {default = "4G"}
variable image_handler_entry_point {default = "image_handler"}
variable image_handler_python_version {default = "python38"}

## iot_handler
variable iot_handler_function_name {default = "IoT_handler"}
variable iot_handler_function_memory {default = 2048}
variable iot_handler_entry_point {default = "IoT_handler"}
variable iot_handler_python_version {default = "python310"}

## text_processor
variable text_processor_function_name {default = "text_processor_tf"}
variable text_processor_function_memory {default = 4096}
variable text_processor_entry_point {default = "text_processor"}
variable text_processor_python_version {default = "python310"}
variable text_processor_azure_api_key {default = "8a78487f81da4dd8867c72e07bb31387"}
variable text_processor_azure_endpoint {default = "https://ceerdcopenai.openai.azure.com/"}

## video_handler
variable video_handler_function_name {default = "video_handler"}
variable video_handler_function_memory {default = "8G"}
variable video_handler_entry_point {default = "video_handler"}
variable video_handler_python_version {default = "python310"}