# terraform/variables.tf

###########################
# Service 名稱參數
###########################

variable "service_underscore" {
  description = "Service 名稱，用 underscore（例如 aws_educate_backend）"
  type        = string
  default     = "aws_educate_backend"
}

variable "service_hyphen" {
  description = "Service 名稱，用 hyphen（例如 aws-educate-backend）"
  type        = string
  default     = "aws-educate-backend"
}

###########################
# DynamoDB 與 Lambda 名稱
# （可留空，會在 locals 自動組字串）
###########################

variable "event_table_name" {
  description = "DynamoDB Table 名稱，用來存放 events（若留空，預設為 <service_underscore>_events）"
  type        = string
  default     = ""
}

variable "lambda_function_name" {
  description = "Lambda Function 名稱（若留空，預設為 <service_hyphen>-create-event）"
  type        = string
  default     = ""
}

###########################
# 其它必要變數
###########################

variable "aws_region" {
  description = "要部署的 AWS Region"
  type        = string
  default     = "ap-northeast-1"
}

variable "environment" {
  description = "部署環境，例如 dev、staging、prod"
  type        = string
  default     = "dev"
}

variable "docker_host" {
  description = "Docker daemon endpoint（只有使用 docker provider 時需要）"
  type        = string
  default     = ""
}

variable "lambda_architecture" {
  description = "Lambda container CPU 架構"
  type        = string
  default     = "x86_64"
}

###########################
# 動態組出預設值
###########################

locals {
  # 如果使用者有傳 event_table_name 就用它，否則預設為 "<service_underscore>_events"
  event_table_name     = length(var.event_table_name) > 0 ? var.event_table_name     : "${var.service_underscore}_events"

  # 如果使用者有傳 lambda_function_name 就用它，否則預設為 "<service_hyphen>-create-event"
  lambda_function_name = length(var.lambda_function_name) > 0 ? var.lambda_function_name : "${var.service_hyphen}-create-event"
}
