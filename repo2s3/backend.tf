terraform {
  backend "s3" {
    bucket  = "adhikari-bucket1"
    key     = "s3/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}


