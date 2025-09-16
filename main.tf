locals {
  project_name = "wp-tf-demo"
}

# Data source for Ubuntu 22.04 images
data "byteplus_images" "ubuntu22" {
  name_regex = "Ubuntu 22.04 64 bit"
}

# Data source for availability zones
data "byteplus_zones" "available" {
}