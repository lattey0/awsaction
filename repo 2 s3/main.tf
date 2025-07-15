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

data "terraform_remote_state" "ec2" {
  backend = "s3"
  config = {
    bucket = "asutosh-project-a-tf-state"
    key    = "ec2/terraform.tfstate"
    region = "us-east-1"
  }
}

resource "aws_s3_bucket" "secure_bucket" {
  bucket        = "asutosh-secure-bucket"
  force_destroy = true

  tags = {
    Name = "AsutoshSecureBucket"
  }
}

resource "aws_s3_bucket_policy" "allow_ec2_write" {
  bucket = aws_s3_bucket.secure_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid    = "AllowEC2Write",
      Effect = "Allow",
      Principal = {
        AWS = data.terraform_remote_state.ec2.outputs.ec2_role_arn
      },
      Action   = "s3:PutObject",
      Resource = "${aws_s3_bucket.secure_bucket.arn}/*"
    }]
  })
}
