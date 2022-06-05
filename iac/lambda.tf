data "aws_s3_bucket" "andrewslai_bucket" {
  bucket = "andrewslai"
}

# ----------------------------------------------------------------------------------------------------------------------
# AWS LAMBDA EXPECTS A DEPLOYMENT PACKAGE
# A deployment package is a ZIP archive that contains your function code and dependencies.
# ----------------------------------------------------------------------------------------------------------------------

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "src/image-processor.py"
  output_path = "out/image-processor.py.zip"
}

# Automatic processing when a new photo is uploaded.
# A new upload will trigger a Lambda fn that resizes the image
resource "aws_iam_role" "lambda_iam" {
  name = "iam_for_image_processing_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "s3_access" {
  name = "s3_access_for_image_processor"
  role = aws_iam_role.lambda_iam.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*",
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

# Creating Lambda resource
resource "aws_lambda_function" "image_processor" {
  filename         = data.archive_file.lambda.output_path
  function_name    = "image_processor_lambda"
  role             = aws_iam_role.lambda_iam.arn
  handler          = "image-processor.main"
  runtime          = "python3.8"
}

# Adding S3 bucket as trigger to my lambda and giving the permissions
resource "aws_s3_bucket_notification" "aws-lambda-trigger" {
  bucket = aws_s3_bucket.bucket.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.test_lambda.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "queued/"
  }
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.image_processer.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${aws_s3_bucket.bucket.id}"
}
