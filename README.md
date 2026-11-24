# MindCircuit on EKS with Jenkins and Argo CD

This repository deploys the application to Amazon EKS using Terraform and GitOps:

1. Terraform creates a VPC, an EKS cluster with a managed node group, and installs Argo CD.
2. The Argo CD `Application` at `argocd/application.yaml` watches `deploymentfiles/` on `main`.
3. `jenkinsfile_final` builds and pushes a uniquely tagged Docker image, then commits the new tag to `deploymentfiles/deployment.yml`.
4. Argo CD detects that Git change and synchronizes the Kubernetes manifests.

## Provision AWS infrastructure

Prerequisites: Terraform 1.5+, AWS CLI v2, `kubectl`, Helm-compatible network access, and AWS credentials authorized to create VPC/EKS/IAM resources. Terraform's Helm provider uses `aws eks get-token`, so the AWS CLI must be installed and authenticated on the machine running Terraform.

In `terraform/`, create a local `terraform.tfvars` file and restrict the Kubernetes API endpoint to your trusted public IP:

```hcl
cluster_endpoint_public_access_cidrs = ["203.0.113.10/32"]
```

Replace the example address with your actual public IP in CIDR notation. Then run:

```sh
terraform init
terraform plan
terraform apply
```

The defaults use AWS region `ap-south-1`, two Availability Zones, one NAT gateway, and two `t3.medium` worker nodes. These resources incur AWS charges; review the plan before applying. `terraform destroy` removes the provisioned infrastructure and workloads.

Configure `kubectl` using the `configure_kubectl` Terraform output, or run:

```sh
aws eks update-kubeconfig --region ap-south-1 --name mindcircuit-eks
```

The AWS identity that applies Terraform receives EKS administrator access through an EKS access entry.

## Register the application with Argo CD

After Terraform finishes, apply the one-time bootstrap `Application`:

```sh
kubectl apply -f argocd/application.yaml
```

The manifest points at this repository's `main` branch and automatically syncs, prunes removed resources, and self-heals drift. For a private GitHub repository, configure repository credentials in Argo CD before applying the `Application`.

Access the Argo CD UI locally:

```sh
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Open `https://localhost:8080`. Retrieve the initial admin password with:

```sh
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

In PowerShell, decode it with:

```powershell
$encoded = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}"
[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($encoded))
```

The application Service is a Kubernetes `LoadBalancer`; AWS provisions an external load balancer for it. Check the address with:

```sh
kubectl -n mindcircuit get service mc-app-service
```

## Configure Jenkins

Use `jenkinsfile_final` in a Linux Jenkins agent with Maven configured as `maven3`, Docker installed and available to the agent, and permission to push to the Docker Hub image `devopshubg333/batch13`.

Create these Jenkins **Secret text** credentials:

| Credential ID | Value |
| --- | --- |
| `dockerhub` | Docker Hub access token for `devopshubg333` |
| `githubtoken` | GitHub token with permission to push commits to this repository's `main` branch |
| `sonar-token` | SonarQube analysis token |

The pipeline uses the configured SonarQube URL in `jenkinsfile_final`. Ensure that Jenkins can reach it. GitOps commits use a recognizable message so their webhook-triggered builds are skipped, avoiding a build/commit loop.

If the Docker Hub repository is private, create an image pull secret in the `mindcircuit` namespace and reference it from the Deployment before enabling Argo CD sync.
