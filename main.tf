# AWS provider configuration for LocalStack
provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    apigateway     = "http://localhost:4566"
    cloudformation = "http://localhost:4566"
    cloudwatch     = "http://localhost:4566"
    dynamodb       = "http://localhost:4566"
    ec2            = "http://localhost:4566"
    es             = "http://localhost:4566"
    firehose       = "http://localhost:4566"
    iam            = "http://localhost:4566"
    kinesis        = "http://localhost:4566"
    lambda         = "http://localhost:4566"
    route53        = "http://localhost:4566"
    redshift       = "http://localhost:4566"
    s3             = "http://s3.localhost.localstack.cloud:4566"
    secretsmanager = "http://localhost:4566"
    ses            = "http://localhost:4566"
    sns            = "http://localhost:4566"
    sqs            = "http://localhost:4566"
    ssm            = "http://localhost:4566"
    stepfunctions  = "http://localhost:4566"
    sts            = "http://localhost:4566"
    elb            = "http://localhost:4566"
    elbv2          = "http://localhost:4566"
    rds            = "http://localhost:4566"
    autoscaling    = "http://localhost:4566"
  }
}

# SQS Queue: Decoupled message buffer
resource "aws_sqs_queue" "order_queue" {
  name                      = "order-processing-queue"
  delay_seconds             = 0
  max_message_size          = 262144 # 256 KB
  message_retention_seconds = 345600 # 4 days
  receive_wait_time_seconds = 0

  tags = {
    Name = "order-processing-queue"
  }
}

# SNS Topic: Event broadcast hub
resource "aws_sns_topic" "order_topic" {
  name = "order-events-topic"

  tags = {
    Name = "order-events-topic"
  }
}

# SNS Subscription: Connects Topic to Queue
resource "aws_sns_topic_subscription" "order_subscription" {
  topic_arn = aws_sns_topic.order_topic.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.order_queue.arn
}

# SQS Policy: Allows SNS to send messages to the queue
resource "aws_sqs_queue_policy" "order_queue_policy" {
  queue_url = aws_sqs_queue.order_queue.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "sqspolicy",
  "Statement": [
    {
      "Sid": "First",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "${aws_sqs_queue.order_queue.arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "${aws_sns_topic.order_topic.arn}"
        }
      }
    }
  ]
}
POLICY
}

# S3 Bucket: Persistent storage for order data
resource "aws_s3_bucket" "order_data" {
  bucket = "order-events-data-store"

  tags = {
    Name = "order-events-data-store"
  }
}

# IAM Role: Identity for the Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "order-processor-lambda-role"

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

# IAM Policy: Permissions for SQS, S3, and CloudWatch
resource "aws_iam_role_policy" "lambda_policy" {
  name = "order-processor-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ],
      "Resource": "${aws_sqs_queue.order_queue.arn}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject"
      ],
      "Resource": "${aws_s3_bucket.order_data.arn}/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    }
  ]
}
EOF
}

# Lambda Function: The processing logic for our order events
resource "aws_lambda_function" "order_processor" {
  filename      = "function.zip"
  function_name = "order-processor"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "python3.9"

  environment {
    variables = {
      S3_BUCKET = aws_s3_bucket.order_data.id
    }
  }

  tags = {
    Name = "order-processor"
  }
}
