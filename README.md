# Mastodon on GKE

This will set up Mastodon on GKE. It uses Contour as a load balancer / frontend, Cloud SQL Postgres for a database, and Mailgun for email.

## Dependencies

The following prerequesties are necessary to set up Mastodon

### Google Cloud APIs

You need the following Google Cloud APIs enabled:

* [Cloud SQL][sql]
* [IAM Identity and Account Management][iam]
* [Cloud Resource Manager][resource]


[sql]: https://console.developers.google.com/apis/api/sqladmin.googleapis.com/overview
[iam]:https://console.developers.google.com/apis/api/iam.googleapis.com/overview
[resource]: https://console.developers.google.com/apis/api/cloudresourcemanager.googleapis.com/overview

### Google Cloud credentials

Create a new [service account][acct] for Terraform. Give it the Project Owner role. Check "furnish a new private key," and select json. Save the resulting file as "account.json" in the gke-mastodon directory.

[acct]: https://console.cloud.google.com/iam-admin/serviceaccounts

### Google Kubernetes Engine

The template does not set up the cluster itself, as there's too many options to template. Create a cluster by the name `mastodon-prod`, or provide an alternate cluster name as a terraform variable.

You will need to set up local credentials as well.

```
gcloud auth application-default login
gcloud container clusters get-credentials mastodon-prod
```

### Terraform

First, [Install Terraform][install]

To get started with Terraform:

```
terraform init
```

You will need to provide several [variables][vars].
These can be either provided as arguments (`-var`) or as a `terraform.tfvars`, in the form of:

```
letsencrypt_email = "<email>"
project_name = "<project>"
domain = "<domain>"

```

[install]: https://www.terraform.io/downloads.html
[vars]: https://www.terraform.io/docs/configuration/variables.html


### Contour

To install contour, you'll need an admin clusterrolebind

```
kubectl create clusterrolebinding cluster-admin-binding --clusterrole cluster-admin --user <your google email address>
```

Then install Contour itself:

```
kubectl apply -f vendor/contour.yaml
```

You'll need the IP address Contour assigned to its load balancer.

```
kubectl get -n heptio-contour service contour -o wide
```

The IP address you want is listed under `external ip`.

Set it as `contour_ip` in the terraform variables.

### cert-manager

```
kubectl apply -f vendor/certmanager.yaml
```

### SMTP

An [attempt was made][mgb] to automate this with terraform, but a [bug][bug] stymied that attempt.
Instead, set up an account (Mastodon recommends [Mailgun][mg] or [SparkPost][sp]). and set the `smtp_server`, `smtp_login`, and `smtp_password` terraform variables.

[mgb]: https://github.com/stillinbeta/gke-mastodon/pull/1
[bug]: https://github.com/terraform-providers/terraform-provider-mailgun/issues/16
[mg]: https://www.mailgun.com/
[sp]: https://www.sparkpost.com/

## Set Up


### Terraform

```
terraform plan -out terraform.plan
```

If all goes well, Terraform will tell you a bunch of resources that will be created.

To actually create them, run:

```
terraform apply terraform.plan
```

This may take a while, especially creating the database instance.

### Google Cloud DNS

After the zone is created (after running Terraform), you'll need to point your name servers at it.
You can do retrieve them with:

```
gcloud dns managed-zones describe mastodon
```

### Kubernetes

Next, install Mastodon into the cluster:

```
kubectl apply -f mastodon.yaml
```

And set up the router. This file should've been created by Terraform.
```
kubectl apply -f serve.yaml
```

### Run the database migrations

Before Mastodon is up and running, you'll need to apply some database migrations.

First, get the IP address of a mastodon node:

```
kubectl get pods -n mastodon
```

look for something like `web-686d9b865b-kzqpw`. The numbers will be different, but that's okay.

Run the migrations:

```
kubectl exec -n mastodon web-686d9b865b-kzqpw bundle exec rake db:migrate:setup
```

That may take a few minutes, but once it's done:

## Conclusion

At this point you should be good to go!
Take a look at the [Mastodon administration guide][admin] for more ideas on how to proceed!

[admin]: https://github.com/tootsuite/documentation/blob/master/Running-Mastodon/Administration-guide.md
