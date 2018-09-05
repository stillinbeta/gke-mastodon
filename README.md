# Mastoodon on GKE

This will set up Mastodon on GKE.

## Dependencies

The following prerequesties are necessary to set up Mastodon

### Google Cloud APIs

You need the following Google Cloud APIs enabled:

* [Cloud SQL][sql]
* [IAM Identity and Account Management][iam]
* [Cloud Resource Manager][resource]
* [DNS][dns]


[sql]: https://console.developers.google.com/apis/api/sqladmin.googleapis.com/overview
[iam]:https://console.developers.google.com/apis/api/iam.googleapis.com/overview
[resource]: https://console.developers.google.com/apis/api/cloudresourcemanager.googleapis.com/overview
[dns]: https://console.developers.google.com/apis/api/dns.googleapis.com/overview

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
kubectl create clusterrolebinding cluster-admin-binding --clusterrole cluster-admin --user ellie@stillinbeta.com
```

Then install Contour itself:

```
kubectl apply -f vendor/contour.yaml
```

### cert-manager

```
kubectl apply -f vendor/certmanager.yaml
```

### Mailgun

Sign up for a [mailgun][mailgun] account. Add your [API key][api] to the terraform variables.

[mailgun]: https://www.mailgun.com/
[api]: https://app.mailgun.com/app/account/security

## Set Up

```
terraform plan -out terraform.plan
```

If all goes well, Terraform will tell you a bunch of resources that will be created.

To actually create them, run:

```
terraform apply terraform.plan
```

Then, install Mastodon into the cluster:

```
kubectl apply -f mastodon.yaml
```

And set up the router. This file should've been created by Terraform.
```
kubectl apply -f serve.yaml
```
