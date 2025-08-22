terraform {
  backend "s3" {
    bucket         = "scramble-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "scramble-terraform-locks"
    encrypt        = true
  }
}