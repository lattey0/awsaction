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

# Import remote state from EC2 project to get the EC2 role ARN
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

# Create secure S3 bucket
resource "aws_s3_bucket" "secure_bucket" {
  bucket        = "asutosh-secure-bucket"
  force_destroy = true

  tags = {
    Name = "AsutoshSecureBucket"
  }
}

# Enable default encryption using AWS-managed key (you can also use KMS CMK if needed)
resource "aws_s3_bucket_server_side_encryption_configuration" "sse" {
  bucket = aws_s3_bucket.secure_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256" # change to "aws:kms" if using a customer key
    }
  }
}

# Enable versioning
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.secure_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable logging (requires a target bucket, here we reuse the same — ideally use separate log bucket)
resource "aws_s3_bucket_logging" "log" {
  bucket = aws_s3_bucket.secure_bucket.id

  target_bucket = aws_s3_bucket.secure_bucket.id
  target_prefix = "log/"
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "block" {
  bucket                  = aws_s3_bucket.secure_bucket.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# Bucket policy allowing only EC2 IAM role to put objects
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
