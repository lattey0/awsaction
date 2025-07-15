terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.3.0"
}

provider "aws" {
  region = "us-east-1"
}


data "terraform_remote_state" "ec2_project" {
  backend = "s3"
  config = {
    bucket = "adhikari-bucket1"
    key    = "ec2/terraform.tfstate"
    region = "us-east-1"
  }
}

locals {
  ec2_role_arn = data.terraform_remote_state.ec2_project.outputs.ec2_role_arn
}


resource "aws_kms_key" "s3_key" {
  description             = "Customer managed KMS key for S3 bucket encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name    = "AsutoshS3KMSKey"
    Creator = "asutosh"
  }
}

resource "aws_kms_alias" "s3_key_alias" {
  name          = "alias/asutosh-s3-key"
  target_key_id = aws_kms_key.s3_key.id
}


resource "aws_s3_bucket" "secure_bucket" {
  bucket        = "asutosh-secure-bucket"
  force_destroy = true

  tags = {
    Name = "AsutoshSecureBucket"
  }
}


resource "aws_s3_bucket_server_side_encryption_configuration" "sse" {
  bucket = aws_s3_bucket.secure_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_key.arn
    }
  }
}


resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.secure_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}


resource "aws_s3_bucket_logging" "log" {
  bucket = aws_s3_bucket.secure_bucket.id

  target_bucket = aws_s3_bucket.secure_bucket.id
  target_prefix = "log/"
}


resource "aws_s3_bucket_public_access_block" "block" {
  bucket                  = aws_s3_bucket.secure_bucket.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}


resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.secure_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "AllowIAMRoleWrite",
        Effect = "Allow",
        Principal = {
          AWS = local.ec2_role_arn
        },
        Action = "s3:PutObject",
        Resource = "${aws_s3_bucket.secure_bucket.arn}/*"
      }
    ]
  })
}
