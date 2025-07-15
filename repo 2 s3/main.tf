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

# Import EC2 IAM role ARN from repo 1
data "terraform_remote_state" "ec2_project" {
  backend = "s3"
  config = {
    bucket = "adhikari-bucket0"
    key    = "terraform.tfstate"
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

# Bucket policy - only IAM role from EC2 project can PUT objects
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
