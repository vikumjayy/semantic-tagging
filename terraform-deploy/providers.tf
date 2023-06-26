terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"

}

provider "aws" {
  region = "ap-southeast-2"
}

# export POC_TFSTATE_REGION=
# export POC_TFSTATE_KEY=
# export POC_TFSTATE_TOKEN=

# terraform init \
# -backend-config="secret_key=${POC_TFSTATE_TOKEN}" \
# -backend-config="access_key=${POC_TFSTATE_KEY}" \
# -backend-config="region=${POC_TFSTATE_REGION}"