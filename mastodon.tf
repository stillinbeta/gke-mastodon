provider "google" {
  credentials = "${file("account.json")}"
  project     = "${var.project_name}"
  region      = "${var.region}"
}

resource "google_sql_database_instance" "master" {
  name = "mastodon-master"
  database_version = "POSTGRES_9_6"

  settings {
    tier = "db-f1-micro"
  }
}

resource "random_string" "database_password" {
  length = 32
}

resource "google_sql_database" "mastodon" {
  name = "mastodon"
  instance = "${google_sql_database_instance.master.name}"
}

resource "google_sql_user" "mastodon_db_user"{
  instance = "${google_sql_database_instance.master.name}"
  name = "mastodon_db_user"
  password = "${random_string.database_password.result}"
}

resource "kubernetes_secret" "mastodon_db_creds" {
  metadata = {
    name = "mastodon-db"
    namespace = "mastodon"
  }

  type = "opaque"

  data = {
    "DB_NAME" = "${google_sql_database.mastodon.name}"
    "DB_USER" = "${google_sql_user.mastodon_db_user.name}"
    "DB_PASSWORD" = "${google_sql_user.mastodon_db_user.password}"
  }
}

resource "google_service_account" "db_proxy_user" {
  account_id = "db-proxy-user"
}


resource "google_service_account_key" "db_proxy_key" {
  service_account_id = "${google_service_account.db_proxy_user.name}"
}


resource "kubernetes_secret" "db_proxy_secret" {
  metadata {
    name = "db-proxy-secret"
    namespace = "mastodon"
  }

  data = {
    credentials.json = "${base64decode(google_service_account_key.db_proxy_key.private_key)}"
  }
}

data "google_container_cluster" "mastodon_prod" {
  name = "gayhorse-prod"
  zone = "${var.cluster_zone}"
}


provider "kubernetes" {
  host = "https://${data.google_container_cluster.mastodon_prod.endpoint}/"

  client_certificate = "${data.google_container_cluster.mastodon_prod.master_auth.0.client_certificate}"
  client_key = "${data.google_container_cluster.mastodon_prod.master_auth.0.client_key}"
  cluster_ca_certificate = "${data.google_container_cluster.mastodon_prod.master_auth.0.cluster_ca_certificate}"
}
