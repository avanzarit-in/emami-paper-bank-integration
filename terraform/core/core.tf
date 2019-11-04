resource "aws_s3_bucket" "emami-paper-bank-api-lambda-source-bucket" {
  bucket = "emami-paper-bank-api-lambda-source"
  acl    = "private"
}