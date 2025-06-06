data "aws_ecr_authorization_token" "token" {
}

data "aws_caller_identity" "this" {}

resource "random_string" "this" {
  length  = 4
  special = false
  lower   = true
  upper   = false
}

locals {
  source_path                                     = "${path.module}/.."
  test_function_name_and_ecr_repo_name            = "${var.environment}-${var.service_underscore}-test-${random_string.this.result}"
  path_include                                    = ["**"]
  path_exclude                                    = ["**/__pycache__/**"]
  files_include                                   = setunion([for f in local.path_include : fileset(local.source_path, f)]...)
  files_exclude                                   = setunion([for f in local.path_exclude : fileset(local.source_path, f)]...)
  files                                           = sort(setsubtract(local.files_include, local.files_exclude))
  dir_sha                                         = sha1(join("", [for f in local.files : filesha1("${local.source_path}/${f}")]))
}

provider "docker" {
  host = var.docker_host

  registry_auth {
    address  = format("%v.dkr.ecr.%v.amazonaws.com", data.aws_caller_identity.this.account_id, var.aws_region)
    username = data.aws_ecr_authorization_token.token.user_name
    password = data.aws_ecr_authorization_token.token.password
  }
}


####################################
####################################
####################################
# GET /test #######################
####################################
####################################
####################################

module "test_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "7.7.0"

  function_name  = local.test_function_name_and_ecr_repo_name
  description    = "AWS Educate Official Website ${var.service_hyphen} in ${var.environment}: GET /test"
  create_package = false
  timeout        = 30

  ##################
  # Container Image
  ##################
  package_type  = "Image"
  architectures = [var.lambda_architecture]
  image_uri = module.test_docker_image.image_uri

  publish = true # Whether to publish creation/change as new Lambda Function Version.

  environment_variables = {
    "ENVIRONMENT"                = var.environment,
    "SERVICE"                    = var.service_underscore,
  }

  tags = {
    "Terraform"   = "true",
    "Environment" = var.environment,
    "Service"     = var.service_underscore
  }
}

module "test_docker_image" {
  source  = "terraform-aws-modules/lambda/aws//modules/docker-build"
  version = "7.7.0"

  create_ecr_repo      = true
  keep_remotely        = true
  use_image_tag        = false
  image_tag_mutability = "MUTABLE"
  ecr_repo             = local.test_function_name_and_ecr_repo_name
  ecr_repo_lifecycle_policy = jsonencode({
    "rules" : [
      {
        "rulePriority" : 1,
        "description" : "Keep only the last 10 images",
        "selection" : {
          "tagStatus" : "any",
          "countType" : "imageCountMoreThan",
          "countNumber" : 10
        },
        "action" : {
          "type" : "expire"
        }
      }
    ]
  })

  source_path = "${local.source_path}/test/"
  triggers = {
    dir_sha = local.dir_sha
  }
}

