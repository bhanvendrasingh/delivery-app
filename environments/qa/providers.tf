provider "aws" {
  region = "ap-south-2"
  # profile = "aws_gobharat"
  
  default_tags {
    tags = {
      Project     = "go-bharat"
      Environment = "qa"
      ManagedBy   = "terraform"
    }
  }
}

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}