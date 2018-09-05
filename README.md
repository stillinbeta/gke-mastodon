You need the following APIs enabled:

* Cloud SQL
* IAM Identity and Account Management
* [Cloud Resource Manager](https://console.developers.google.com/apis/api/cloudresourcemanager.googleapis.com/overview)

To get started with Terraform

```
terraform init
```

To install contour, you'll need an admin clusterrolebind

```
kubectl create clusterrolebinding cluster-admin-binding --clusterrole cluster-admin --user ellie@stillinbeta.com
```
