terraform {
  required_version = "> 0.8.0"

  backend "s3" {
    bucket = "probeaufgabe-terraform-state"
    key    = "terraform.tfstate"
    region = "eu-west-1"
  }
}

provider "aws" {
  region = "${var.aws_region}"
}
