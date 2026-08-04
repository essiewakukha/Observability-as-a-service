terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
 # Uncomment and configure once you have an S3 bucket + DynamoDB table for
  # remote state (recommended once you move past solo experimentation):
  #
  # backend "s3" {
  #   bucket         = "your-tfstate-bucket"
  #   key            = "obs-capstone/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "your-tfstate-lock-table"
  #   encrypt        = true
  # }

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

