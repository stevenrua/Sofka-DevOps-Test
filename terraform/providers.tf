terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">=5.56.0, <5.58, !=5.56.0"
    }
  }
  required_version = "~>1.9.0"
}

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = var.tags
  }
}