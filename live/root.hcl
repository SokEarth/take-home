terragrunt_version_constraint = ">= 0.78.0"
terraform_version_constraint  = ">= 1.8.0"

remote_state {
  backend = "s3"

  config = {
    bucket         = "live-terraform-state"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "live-terraform-locks"

    s3_bucket_tags = {
      Name      = "Terraform state storage"
      ManagedBy = "Terragrunt"
      Project   = "live"
    }

    dynamodb_table_tags = {
      Name      = "Terraform lock table"
      ManagedBy = "Terragrunt"
    }
  }

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.8.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"

  default_tags {
    tags = {
      ManagedBy = "Terragrunt"
      Project   = "live"
    }
  }
  assume_role {
    role_arn = "arn:aws:iam::${local.account_id}:role/TerraformRole"
  }
}
EOF
}

errors {
  retry "transient_errors" {
    retryable_errors = [
      "(?s).*Failed to load state.*tcp.*timeout.*",
      "(?s).*Failed to load backend.*TLS handshake timeout.*",
      "(?s).*Error installing provider.*TLS handshake timeout.*",
      "(?s).*Error installing provider.*tcp.*timeout.*",
      "(?s).*Error installing provider.*tcp.*connection reset by peer.*",
      "(?s).*Error configuring the backend.*TLS handshake timeout.*",
      "(?s).*Provider produced inconsistent final plan.*",
      "(?s).*app.terraform.io.*: 429 Too Many Requests.*",
      "(?s).*Client.Timeout exceeded while awaiting headers.*",
    ]
    max_attempts       = 3
    sleep_interval_sec = 5
  }
}
