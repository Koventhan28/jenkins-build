# Terraform block
terraform {

  backend "s3" {
    bucket  = "myterraformstatebuckettrend"
    key     = "project/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

############################
# Provider Detials
############################
provider "aws" {
  region = var.region
  alias  = "west"
}