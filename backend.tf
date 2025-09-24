terraform {
  backend "s3" {
    bucket = "testdev-tfstate"
    key    = "vpc/terraform.tfstate"
    region = "ap-south-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}