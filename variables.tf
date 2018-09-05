variable "project_name" {}

variable "cluster_name" {
  default = "mastodon-prod"
}

variable "region" {
  default = "us-central1"
}

variable "cluster_zone" {
  default = "us-central1-a"
}

variable "letsencrypt_email" {}

variable "domain" {}

variable "mailgun_api_key" {}
