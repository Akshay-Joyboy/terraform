terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 5.0"
    }
  }
}


#configure aws provider
provider "aws" {
  region = "ap-south-2"
}

resource "aws_instance" "one" {
  ami = var.ami_value
  instance_type = var.instance_type_value
}

