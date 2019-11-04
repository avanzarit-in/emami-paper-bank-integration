resource "aws_s3_bucket_object" "emami-paper-bank-api-notification-lambda-source" {
  bucket = var.emami-paper-bank-api-lambda-source-bucket-id
  key    = var.lambda-s3-key
  source = var.lambda-source
  etag = "${filemd5(var.lambda-source)}"
}

data "template_file" "lambda-exec-policy" {
  template = "${file("${path.module}/policies/lambda-exec-policy.tpl")}"
}

# IAM role which dictates what other AWS services the Lambda function
# may access.
resource "aws_iam_role" "lambda_exec" {
  name = "emami-paper-bank-api-lambda-${var.function-name}-exec-role"
  assume_role_policy = data.template_file.lambda-exec-policy.rendered
}

resource "aws_lambda_function" "emami-paper-bank-api-lambda" {
  function_name = var.function-name
  s3_bucket = var.emami-paper-bank-api-lambda-source-bucket-id
  s3_key    = var.lambda-s3-key
  source_code_hash = "${filebase64sha256(var.lambda-source)}"
  handler = var.handler
  runtime = var.runtime

  role = "${aws_iam_role.lambda_exec.arn}"

  depends_on    = ["aws_iam_role_policy_attachment.lambda_logs", "aws_cloudwatch_log_group.emami-paper-bank-api-lambda-log-group"]
}



resource "aws_cloudwatch_log_group" "emami-paper-bank-api-lambda-log-group" {
  name              = "/aws/lambda/${var.function-name}"
  retention_in_days = 14
}

resource "aws_iam_policy" "emami-paper-bank-api-lambda-logging-policy" {
  name = "emami-paper-bank-api-lambda-${var.function-name}-logging-policy"
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
  name        = "emami-paper-bank-rest-${var.function-name}-api"
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

