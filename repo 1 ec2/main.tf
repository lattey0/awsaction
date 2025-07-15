terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.3.0"

  backend "s3" {
    bucket = "asutosh-project-a-tf-state"
    key    = "ec2/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "ec2_s3_writer_role" {
  name = "asutoshrole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "s3_write_policy" {
  name = "s3-write-policy"
  role = aws_iam_role.ec2_s3_writer_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = ["s3:PutObject"],
      Resource = "arn:aws:s3:::asutosh-secure-bucket/*"
    }]
  })
}

resource "aws_iam_instance_profile" "profile" {
  name = "asutosh-profile"
  role = aws_iam_role.ec2_s3_writer_role.name
}

resource "aws_instance" "ec2_instance" {
  ami                         = "ami-05ffe3c48a9991133"
  instance_type               = "t2.micro"
  subnet_id                   = "subnet-092775186223b72ed"
  vpc_security_group_ids      = ["sg-029d099bf09a3033f"]
  key_name                    = "asutosh-key"
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.profile.name

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    encrypted = true
  }

  tags = {
    Name = "terminus-ec2"
  }
}

output "ec2_role_arn" {
  value = aws_iam_role.ec2_s3_writer_role.arn
}
