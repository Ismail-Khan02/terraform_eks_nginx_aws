# AWS EKS Infrastructure with Terraform & Nginx Demo

This project provisions a production-ready AWS Elastic Kubernetes Service (EKS) cluster using Terraform with a fully custom local module. It includes a VPC, a managed node group, KMS secrets encryption, CloudWatch logging, and instructions for deploying a sample Nginx application exposed via an AWS Network Load Balancer (NLB).

## Architecture Overview

- **IaC Tool:** Terraform
- **Cloud Provider:** AWS (us-east-1)
- **Network:** VPC with 3 Public and 3 Private subnets across 3 AZs
- **Cluster:** EKS v1.29 provisioned via a custom local module
- **Compute:** Managed Node Group using `t3.medium` instances (min 1, max 2)
- **Security:** KMS-encrypted secrets, public API endpoint restricted to caller's IP
- **Observability:** CloudWatch log group with 7-day retention (api, audit, authenticator logs)
- **Load Balancer:** AWS Network Load Balancer (NLB)

## Prerequisites

Ensure you have the following installed locally:

- [Terraform](https://www.terraform.io/downloads) (v1.0+)
- [AWS CLI](https://aws.amazon.com/cli/) (v2, configured with credentials)
- [kubectl](https://kubernetes.io/docs/tasks/tools/) (compatible with EKS v1.29)

## Project Structure

```
terraform_eks_nginx_aws/
├── terraform_configs/          # All Terraform configuration
│   ├── provider.tf             # Required providers (AWS ~5.80, Kubernetes ~2.30, HTTP ~3.0)
│   ├── main.tf                 # Kubernetes provider wired to EKS cluster outputs
│   ├── http.tf                 # Auto-detects caller public IP for API endpoint CIDR restriction
│   ├── eks.tf                  # Calls the local EKS module
│   ├── vpc.tf                  # VPC, subnets, NAT gateway (terraform-aws-modules/vpc ~4.0)
│   ├── variables.tf            # Region and cluster name variables
│   ├── outputs.tf              # cluster_name, vpc_id, configure_kubectl
│   ├── modules/
│   │   └── eks/                # Custom local EKS module
│   │       ├── main.tf         # IAM roles, KMS key, CloudWatch log group, EKS cluster, node group
│   │       ├── variables.tf    # Module input variables
│   │       └── outputs.tf      # cluster_name, cluster_endpoint, cluster_certificate_authority
│   └── kubernetes_app/
│       ├── deployment.yaml     # Kubernetes Deployment manifest for Nginx
│       └── service.yaml        # Kubernetes Service manifest (NLB LoadBalancer type)
```

## Key Configuration Details

### Local EKS Module (`modules/eks/`)

The project uses a custom local module instead of the public `terraform-aws-modules/eks`. The module provisions all resources directly:

- **IAM Roles:** Separate cluster role (`AmazonEKSClusterPolicy`) and node group role (`AmazonEKSWorkerNodePolicy`, `AmazonEKS_CNI_Policy`, `AmazonEC2ContainerRegistryReadOnly`)
- **KMS Encryption:** A KMS key with rotation enabled encrypts Kubernetes secrets at rest
- **CloudWatch Logging:** Log group at `/aws/eks/<cluster>/cluster` with 7-day retention
- **Cluster Admin Access:** Uses `aws_eks_access_entry` + `aws_eks_access_policy_association` to grant the caller `AmazonEKSClusterAdminPolicy`
- **Managed Node Group:** Autoscales between 1–2 `t3.medium` nodes

### IP-Restricted API Endpoint (`http.tf`)

The public Kubernetes API endpoint is automatically restricted to only your current public IP. `http.tf` queries `checkip.amazonaws.com` at plan/apply time and passes the result as a `/32` CIDR to the EKS cluster's `public_access_cidrs`.

### VPC Subnet Tags (`vpc.tf`)

Subnets are tagged so the AWS load balancer controller knows where to place load balancers:

- **Public Subnets:** `kubernetes.io/role/elb = 1`
- **Private Subnets:** `kubernetes.io/role/internal-elb = 1`

### Network Load Balancer (`kubernetes_app/service.yaml`)

The Service manifest uses the annotation below to provision a Layer 4 NLB instead of the legacy Classic Load Balancer:

```yaml
service.beta.kubernetes.io/aws-load-balancer-type: nlb
```

## Deployment Guide

### 1. Provision Infrastructure

```bash
cd terraform_configs

terraform init
terraform plan
terraform apply
```

*Type `yes` when prompted. Allow 15–20 minutes for full provisioning.*

### 2. Configure Cluster Access

Use the `configure_kubectl` output to generate your local kubeconfig:

```bash
# The exact command is printed by Terraform — it looks like:
aws eks --region us-east-1 update-kubeconfig --name my-terraform-eks-cluster
```

Verify connectivity:

```bash
kubectl get nodes
```

> **Expected:** 1–2 nodes with status `Ready`.

### 3. Deploy the Nginx Application

```bash
kubectl apply -f kubernetes_app/deployment.yaml
kubectl apply -f kubernetes_app/service.yaml
```

### 4. Access the Application

```bash
kubectl get service nginx-service
```

Copy the `EXTERNAL-IP` value and open it in a browser. You should see the **"Welcome to nginx!"** default page.

> **Note:** It may take 3–5 minutes for the NLB to fully provision and register targets.

---

## Cleanup

**Remove Kubernetes resources first** (this deletes the NLB from AWS):

```bash
kubectl delete -f kubernetes_app/service.yaml
kubectl delete -f kubernetes_app/deployment.yaml
```

*Wait until the Load Balancer disappears from the AWS console before the next step.*

**Destroy all infrastructure:**

```bash
terraform destroy
```

*Type `yes` when prompted.*
