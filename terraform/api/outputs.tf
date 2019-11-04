output "base_url" {
  value = "${aws_api_gateway_deployment.emami-paper-bank-rest-api-deployment.invoke_url}"
}