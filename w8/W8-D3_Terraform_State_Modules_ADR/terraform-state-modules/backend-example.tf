terraform {
  backend "s3" {
    bucket         = "replace-with-your-tf-state-bucket"
    key            = "phase2/w8/dev/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "replace-with-your-tf-lock-table"
    encrypt        = true
  }
}

