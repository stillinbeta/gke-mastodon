provider "google" {
  credentials = "${file("account.json")}"
  project     = "${var.project_name}"
  region      = "${var.region}"
}

resource "google_sql_database_instance" "master" {
  database_version = "POSTGRES_9_6"
  region = "${var.region}"

  settings {
    tier = "db-f1-micro"
  }
}

resource "random_string" "otp_secret" {
  length = 64
  special = false
}

resource "random_string" "secret_key_base" {
  length = 128
  special = false
  upper = false
}

resource "kubernetes_secret" "mastodon-secrets" {
  metadata = {
    name = "mastodon-secrets"
    namespace = "mastodon"
  }

  data = {
    "OTP_SECRET" = "${random_string.otp_secret.result}"
    "SECRET_KEY_BASE" = "${random_string.secret_key_base.result}"
  }
}

resource "random_string" "database_password" {
  length = 32
}

resource "google_sql_database" "mastodon" {
  name     = "mastodon-db"
  instance = "${google_sql_database_instance.master.name}"
}

resource "google_sql_user" "mastodon_db_user" {
  instance = "${google_sql_database_instance.master.name}"
  name     = "mastodon_db_user"
  password = "${random_string.database_password.result}"
}

resource "kubernetes_secret" "mastodon-db-creds" {
  metadata = {
    name      = "mastodon-db-creds"
    namespace = "mastodon"
  }

  type = "opaque"

  data = {
    "DB_NAME" = "${google_sql_database.mastodon.name}"
    "DB_USER" = "${google_sql_user.mastodon_db_user.name}"
    "DB_PASS" = "${google_sql_user.mastodon_db_user.password}"
  }
}

resource "google_service_account" "db_proxy_user" {
  account_id = "db-proxy-user"
}

resource "google_project_iam_binding" "db_proxy_binding" {
  project = "${var.project_name}"
  role = "roles/cloudsql.client"
  members = [
    "serviceAccount:${google_service_account.db_proxy_user.email}"
  ]
}

resource "google_service_account_key" "db_proxy_key" {
  service_account_id = "${google_service_account.db_proxy_user.name}"
}

resource "kubernetes_secret" "db_proxy_secret" {
  metadata {
    name      = "db-proxy-secret"
    namespace = "mastodon"
  }

  data = {
    credentials.json = "${base64decode(google_service_account_key.db_proxy_key.private_key)}"
  }
}

resource "kubernetes_config_map" "db_proxy_connection_name" {
  metadata =
  {
    name = "db-proxy-connection-name"
    namespace = "mastodon"
  }

  data {
    "instance-name" = "${var.project_name}:${var.region}:${google_sql_database_instance.master.name}"
  }
}

data "google_container_cluster" "mastodon_prod" {
  name = "${var.cluster_name}"
  zone = "${var.cluster_zone}"
}

provider "kubernetes" {
  host = "https://${data.google_container_cluster.mastodon_prod.endpoint}/"


  # TODO(EKF): this isn't working right now
  # client_certificate     = "${base64encode(data.google_container_cluster.mastodon_prod.master_auth.0.client_certificate)}"
  # client_key             = "${base64decode(data.google_container_cluster.mastodon_prod.master_auth.0.client_key)}"
  # cluster_ca_certificate = "${base64decode(data.google_container_cluster.mastodon_prod.master_auth.0.cluster_ca_certificate)}"
}

data "template_file" "serve_yaml_template" {
  template = "${file("serve.yaml.template")}"

  vars {
    letsencrypt_email = "${var.letsencrypt_email}"
    domain = "${var.domain}"
  }
}

resource "local_file" "serve_yaml" {
  filename = "${path.module}/serve.yaml"
  content = "${data.template_file.serve_yaml_template.rendered}"
}

resource "kubernetes_secret" "smtp" {
  metadata = {
    namespace = "mastodon"
    name = "smtp-secerts"
  }

  data = {
    "SMTP_SERVER"=  "${var.smtp_server}"
    "SMTP_LOGIN" = "${var.smtp_login}"
    "SMTP_PASSWORD" = "${var.smtp_password}"
    "SMTP_PORT" = "${var.smtp_port}"
    "SMTP_FROM_ADDRESS" = "notifications@${var.domain}"
  }
}
