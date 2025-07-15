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



resource "aws_iam_role" "ec2_s3_writer_role" {
  name = "ec2-s3-writer-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Creator = "asutosh"
  }
}


resource "aws_iam_policy" "write_to_s3_policy" {
  name = "WriteToS3Policy-v2"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::asutosh-secure-bucket",
          "arn:aws:s3:::asutosh-secure-bucket/*"
        ]
      },
      {
        Effect = "Allow",
        Action = ["s3:ListBucket", "s3:GetObject"],
        Resource = [
          "arn:aws:s3:::adhikari-bucket1",
          "arn:aws:s3:::adhikari-bucket1/*"
        ]
      }
    ]
  })

  tags = {
    Creator = "asutosh"
  }
}


resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = aws_iam_role.ec2_s3_writer_role.name
  policy_arn = aws_iam_policy.write_to_s3_policy.arn
}


resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-s3-profile-v2"
  role = aws_iam_role.ec2_s3_writer_role.name
}


resource "aws_instance" "asutosh_ec2" {
  ami                         = "ami-05ffe3c48a9991133"
  instance_type               = "t2.micro"
  subnet_id                   = "subnet-092775186223b72ed"
  vpc_security_group_ids      = ["sg-029d099bf09a3033f"]
  key_name                    = "asutosh-key"
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name


  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }


  root_block_device {
    encrypted = true
  }

  tags = {
    Name    = "asutosh-ec2"
    Creator = "asutosh"
  }
}


output "ec2_instance_arn" {
  value = aws_instance.asutosh_ec2.arn
}

output "ec2_role_arn" {
  value = aws_iam_role.ec2_s3_writer_role.arn
}
