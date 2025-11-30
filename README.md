# AWS EKS Infrastructure with Terraform & Nginx Demo

This project provisions a production-ready AWS Elastic Kubernetes Service (EKS) cluster using Terraform. It includes a VPC configuration, a managed node group, and instructions for deploying a sample Nginx application exposed via an AWS Network Load Balancer (NLB).

## 🏗 Architecture Overview

* **IaC Tool:** Terraform
* **Cloud Provider:** AWS (us-east-1)
* **Network:** VPC with 3 Public and 3 Private subnets.
* **Cluster:** EKS Version 1.29 (Module v20.0).
* **Compute:** Managed Node Group using `t3.medium` instances.
* **Load Balancer:** AWS Network Load Balancer (NLB) for high performance.

## 📋 Prerequisites

Ensure you have the following installed locally:

* [Terraform](https://www.terraform.io/downloads) (v1.0+)
* [AWS CLI](https://aws.amazon.com/cli/) (v2, configured with credentials)
* [kubectl](https://kubernetes.io/docs/tasks/tools/) (compatible with v1.29)

## 📂 Project Structure

| File | Description |
| :--- | :--- |
| `main.tf` | Kubernetes provider and data source configuration. |
| `eks.tf` | EKS Cluster and Node Group definitions (Module v20.0). |
| `vpc.tf` | VPC, Subnets, and NAT Gateway configuration. |
| `variables.tf` | Project variables (Region, Cluster Name). |
| `outputs.tf` | Outputs including the `kubectl` config command. |
| `deployment.yaml` | Kubernetes Deployment manifest for Nginx. |
| `service.yaml` | Kubernetes Service manifest (LoadBalancer type). |

## ⚙️ Key Configuration Details

This project uses specific configurations to ensure compatibility with modern EKS standards:

1.  **Cluster Access:** `enable_cluster_creator_admin_permissions = true` is set in `eks.tf` to allow the creator to access the cluster (Required for EKS Module v20+).
2.  **Load Balancer:** The `service.yaml` uses the annotation `service.beta.kubernetes.io/aws-load-balancer-type: nlb` to provision a Network Load Balancer.
3.  **VPC Tags:** Subnets in `vpc.tf` are tagged with `kubernetes.io/role/elb` (public) and `kubernetes.io/role/internal-elb` (private) so AWS knows where to place load balancers.

## 🚀 Deployment Guide


### 1. Provision Infrastructure

Initialize Terraform to download specific provider versions:

```bash
terraform init
````

Review the deployment plan:

```bash
terraform plan
```

Apply the configuration (Approx. 15-20 minutes):

```bash
terraform apply
```

*Type `yes` when prompted.*

### 2\. Configure Cluster Access

EKS Module v20 changes how authentication works. You must generate the local kubeconfig using the AWS CLI command output by Terraform:

```bash
# Run the command shown in the "configure_kubectl" output, for example:
aws eks --region us-east-1 update-kubeconfig --name my-terraform-eks-cluster
```

Verify connectivity:

```bash
kubectl get nodes
```

> **Expected Output:** You should see 1 or 2 nodes with status `Ready`.

### 3\. Deploy Application

Deploy the Nginx workloads to your new cluster:

```bash
# 1. Create the Deployment (Pods)
kubectl apply -f deployment.yaml

# 2. Create the Service (Network Load Balancer)
kubectl apply -f service.yaml
```

### 4\. Access the Application

Retrieve the external URL of your Load Balancer:

```bash
kubectl get service nginx-service
```

Copy the value under **EXTERNAL-IP** (e.g., `k8s-default-nginxser-xxx.elb.us-east-1.amazonaws.com`).

Paste this URL into your browser. You should see the **"Welcome to nginx\!"** default page.

> **Note:** It may take 3-5 minutes for the AWS Load Balancer to fully provision and register the targets.

-----

## ⚙️ Configuration details

### Why Network Load Balancer (NLB)?

The `service.yaml` includes this annotation:

```yaml
service.beta.kubernetes.io/aws-load-balancer-type: nlb
```

This instructs AWS to provision a high-performance **Network Load Balancer (Layer 4)** instead of the legacy Classic Load Balancer.

### Why specific VPC Tags?

In `vpc.tf`, we added specific tags to the subnets. Without these, the Load Balancer cannot determine where to provision:

  * **Public Subnets:** `kubernetes.io/role/elb = 1`
  * **Private Subnets:** `kubernetes.io/role/internal-elb = 1`

-----

## 🧹 Cleanup

To avoid unexpected cloud costs, destroy resources when finished:

**Remove Kubernetes Services:**

```bash
kubectl delete -f service.yaml
kubectl delete -f deployment.yaml
```

*Wait for the Load Balancer to be deleted from the AWS console.*

**Destroy Infrastructure:**

```bash
terraform destroy
```

*Type `yes` when prompted.*


