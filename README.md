# Terraform Modules

Reusable Terraform modules for Kubernetes infrastructure.

## Modules

- **[compute](./modules/compute)** - EC2 instances for K8s worker and master nodes

## Usage

```hcl
module "workers" {
  source = "./modules/compute"
  
  cluster_name         = "my-k8s"
  environment          = "dev"
  node_type            = "worker"
  instance_count       = 3
  subnet_id            = "subnet-xxx"
  iam_instance_profile = "worker-profile"
  key_name             = "my-key"
}

CI/CD
All modules are automatically validated using GitHub Actions:

✅ Format checking with terraform fmt
✅ Validation with terraform validate


