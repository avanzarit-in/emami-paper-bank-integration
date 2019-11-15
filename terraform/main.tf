terraform {
  required_version = "0.12.13"
  backend "s3" {
    bucket = "emami-paper-bank-terraform-infra"
    key    = "development"
    region = "us-east-1"
  }
}

provider "null" {
  version = "~> 2.1"
}

provider "template" {
  version = "~> 2.1"
}

variable environment {

}

provider "aws" {
  version = "~> 2.7"
  max_retries = 20
  profile = "default"
}

module "core" {
  source = "./core"
}

module "notification-api"{
  source="./api"
  emami-paper-bank-api-lambda-source-bucket-id = module.core.emami-paper-bank-api-lambda-source-bucket-id
  lambda-source = "../src/notification-api/emami-paper-bank-api-notification.zip"
  lambda-s3-key = "v1.0.0/emami-paper-bank-api-notification.zip"
  handler = "notification.handler"
  runtime = "nodejs10.x"
  function-name = "NotificationApi"
}

module "validation-api"{
  source="./api"
  emami-paper-bank-api-lambda-source-bucket-id = module.core.emami-paper-bank-api-lambda-source-bucket-id
  lambda-source = "../src/validation-api/emami-paper-bank-api-validation.zip"
  lambda-s3-key = "v1.0.0/emami-paper-bank-api-validation.zip"
  handler = "validation.handler"
  runtime = "nodejs10.x"
  function-name = "ValidationApi"
}


output "notification_base_url" {
  value = "${module.notification-api.base_url}"
}

output "validation_base_url" {
  value = "${module.validation-api.base_url}"
}
