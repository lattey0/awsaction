terraform {
  backend "s3" {
    bucket  = "adhikari-bucket1"
    key     = "ec2/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
