terraform {
  required_version = "0.12.9"
  backend "s3" {
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


/*resource "null_resource" "cleanup" {
  provisioner "local-exec" {
    command = "del *.zip"
  }
  provisioner "local-exec" {
    command = "npm run pack"
  } 

  triggers = {
    always_run = "${timestamp()}"
  }
}*/

resource "aws_s3_bucket" "emami-paper-bank-lambda-source" {
  bucket = "emami-paper-bank-lambda-source"
  acl    = "private"
}

resource "aws_s3_bucket_object" "emami-paper-bank-api-lambda-source" {
  bucket = "${aws_s3_bucket.emami-paper-bank-lambda-source.id}"
  key    = "v1.0.0/emami-paper-bank-api-lambda.zip"
  source = "emami-paper-bank-api.zip"

  etag = "${filemd5("emami-paper-bank-api.zip")}"
}

resource "aws_lambda_function" "emami-paper-bank-api-lambda" {
  function_name = "BankApi"

  # The bucket name as created earlier with "aws s3api create-bucket"
  s3_bucket = "${aws_s3_bucket.emami-paper-bank-lambda-source.id}"
  s3_key    = "v1.0.0/emami-paper-bank-api-lambda.zip"

  source_code_hash = "${filebase64sha256("emami-paper-bank-api.zip")}"

  # "main" is the filename within the zip file (main.js) and "handler"
  # is the name of the property under which the handler function was
  # exported in that file.
  handler = "main.handler"
  runtime = "nodejs10.x"

  role = "${aws_iam_role.lambda_exec.arn}"
 
  depends_on    = ["aws_iam_role_policy_attachment.lambda_logs", "aws_cloudwatch_log_group.emami-paper-bank-api-lambda-log-group"]
}

# IAM role which dictates what other AWS services the Lambda function
# may access.
resource "aws_iam_role" "lambda_exec" {
  name = "emami-paper-bank-api-lambda-exec-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# This is to optionally manage the CloudWatch Log Group for the Lambda Function.
# If skipping this resource configuration, also add "logs:CreateLogGroup" to the IAM policy below.
resource "aws_cloudwatch_log_group" "emami-paper-bank-api-lambda-log-group" {
  name              = "/aws/lambda/BankApi"
  retention_in_days = 14
}

# See also the following AWS managed policy: AWSLambdaBasicExecutionRole
resource "aws_iam_policy" "emami-paper-bank-api-lambda-logging-policy" {
  name = "emami-paper-bank-api-lambda-logging-policy"
  path = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role = "${aws_iam_role.lambda_exec.name}"
  policy_arn = "${aws_iam_policy.emami-paper-bank-api-lambda-logging-policy.arn}"
}

resource "aws_api_gateway_rest_api" "emami-paper-bank-rest-api" {
  name        = "emami-paper-bank-rest-api"
  description = "Terraform Serverless Application Example"
}

resource "aws_api_gateway_resource" "emami-paper-bank-rest-api-proxy-resource" {
  rest_api_id = "${aws_api_gateway_rest_api.emami-paper-bank-rest-api.id}"
  parent_id   = "${aws_api_gateway_rest_api.emami-paper-bank-rest-api.root_resource_id}"
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "emami-paper-bank-rest-api-proxy-method" {
  rest_api_id   = "${aws_api_gateway_rest_api.emami-paper-bank-rest-api.id}"
  resource_id   = "${aws_api_gateway_resource.emami-paper-bank-rest-api-proxy-resource.id}"
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = "${aws_api_gateway_rest_api.emami-paper-bank-rest-api.id}"
  resource_id = "${aws_api_gateway_method.emami-paper-bank-rest-api-proxy-method.resource_id}"
  http_method = "${aws_api_gateway_method.emami-paper-bank-rest-api-proxy-method.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.emami-paper-bank-api-lambda.invoke_arn}"
}

resource "aws_api_gateway_method" "emami-paper-bank-rest-api-proxy-method-root" {
  rest_api_id   = "${aws_api_gateway_rest_api.emami-paper-bank-rest-api.id}"
  resource_id   = "${aws_api_gateway_rest_api.emami-paper-bank-rest-api.root_resource_id}"
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = "${aws_api_gateway_rest_api.emami-paper-bank-rest-api.id}"
  resource_id = "${aws_api_gateway_method.emami-paper-bank-rest-api-proxy-method-root.resource_id}"
  http_method = "${aws_api_gateway_method.emami-paper-bank-rest-api-proxy-method-root.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.emami-paper-bank-api-lambda.invoke_arn}"
}


resource "aws_api_gateway_deployment" "emami-paper-bank-rest-api-deployment" {
  depends_on = [
    "aws_api_gateway_integration.lambda",
    "aws_api_gateway_integration.lambda_root",
  ]

  rest_api_id = "${aws_api_gateway_rest_api.emami-paper-bank-rest-api.id}"
  stage_name  = "test"
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.emami-paper-bank-api-lambda.function_name}"
  principal     = "apigateway.amazonaws.com"

  # The "/*/*" portion grants access from any method on any resource
  # within the API Gateway REST API.
  source_arn = "${aws_api_gateway_rest_api.emami-paper-bank-rest-api.execution_arn}/*/*"
}

output "base_url" {
  value = "${aws_api_gateway_deployment.emami-paper-bank-rest-api-deployment.invoke_url}"
}