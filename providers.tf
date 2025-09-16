terraform {
  required_providers {
    byteplus = {
      source  = "byteplus-sdk/byteplus"
      version = "0.0.22"
    }
  }

  backend "s3" {
    bucket   = "win-terraform-bucket"                         #The name of the TOS bucket
    key      = "wp-terraform.tfstate"                            #The name of the TOS object
    region   = "ap-southeast-1"                               #The region of the TOS bucket
    endpoint = "https://tos-s3-ap-southeast-1.bytepluses.com" #The s3 endpoint of the TOS

    skip_region_validation      = true
    skip_metadata_api_check     = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
}

provider "byteplus" {
  region = "ap-southeast-3"
  endpoint   = "open.ap-southeast-1.byteplusapi.com"
}
