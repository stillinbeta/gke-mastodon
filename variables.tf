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

variable "smtp_server" {
  default = "smtp.mailgun.com"
}

variable "smtp_login" {
  default = "mastodon"
}

variable "smtp_password" {
  default = ""
}

variable "smtp_port" {
  default = 587
}
