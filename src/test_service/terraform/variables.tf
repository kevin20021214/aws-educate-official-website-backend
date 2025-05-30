variable "aws_region" {
  description = "aws region"
}

variable "environment" {
  description = "Current environtment: prod(ap-northeast-1)/dev(us-east-1)/local-dev(us-west-2), default dev(us-east-1)"
}

variable "service_underscore" {
  description = "Current service name"
}

variable "service_hyphen" {
  description = "This variable contains the current service name, but with hyphens instead of underscores. For example: demo-service."
}

variable "docker_host" {
  description = "Docker host"
  type        = string
}

variable "lambda_architecture" {
  description = "CPU architecture for container image"
  type    = string
  default = "x86_64"
}
