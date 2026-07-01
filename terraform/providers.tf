terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

terraform {
  backend "s3" {
    bucket       = "yhodaf-tfstate-react-2026"
    key          = "dev/terraform.tfstate"
    region       = "eu-west-1"
    encrypt      = true
  use_lockfile = true
}

}