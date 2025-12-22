# Terraform Modules

Reusable, production-ready Terraform modules for AWS infrastructure.

## 📦 Available Modules

### 1. **[IAM Roles](./modules/iam-roles/)**
Create IAM roles for EC2, Lambda, CI/CD (OIDC), Kubernetes pods (IRSA), and cross-account access.

**Quick Example:**
```hcl
module "worker_role" {
  source = "./modules/iam-roles"
  
  cluster_name        = "my-eks"
  environment         = "prod"
  role_name           = "worker"
  role_type           = "ec2"
  attach_eks_policies = true
}
```

**[Full Documentation →](./modules/iam-roles/README.md)**

---

### 2. **[Compute](./modules/compute/)**
Launch EC2 instances with optional user data scripts.

**Quick Example:**
```hcl
module "workers" {
  source = "./modules/compute"
  
  cluster_name         = "my-k8s"
  environment          = "dev"
  node_type            = "worker"
  instance_count       = 3
  subnet_id            = "subnet-xxx"
  iam_instance_profile = module.worker_role.instance_profile_name
  user_data_file       = "./scripts/k8s-worker.sh"
}
```

---

## 🚀 Getting Started

### 1. Clone This Repository

```bash
git clone https://github.com/Raghuram1510/terraform-modules.git
cd terraform-modules
```

### 2. Reference Modules in Your Infrastructure Project

**Using local path:**
```hcl
module "my_role" {
  source = "./modules/iam-roles"
  # ...
}
```

**Using GitHub:**
```hcl
module "my_role" {
  source = "github.com/Raghuram1510/terraform-modules//modules/iam-roles"
  # ...
}
```

**Using GitHub with version tag:**
```hcl
module "my_role" {
  source = "github.com/Raghuram1510/terraform-modules//modules/iam-roles?ref=v1.0.0"
  # ...
}
```

---

## 📁 Repository Structure

```
terraform-modules/
├── modules/
│   ├── iam-roles/        # IAM role creation
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── compute/          # EC2 instances
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── vpc/              # (Coming soon)
│   └── storage/          # (Coming soon)
├── .github/
│   └── workflows/
│       └── ci.yml        # Automated validation
├── .gitignore
└── README.md
```

---

## 🔄 CI/CD Pipeline

This repository uses GitHub Actions to automatically validate all modules on every push:

- ✅ **Format Check** - Ensures consistent Terraform formatting
- ✅ **Validation** - Checks syntax and configuration correctness
- ✅ **Matrix Testing** - Tests only changed modules

**Shared workflows from:** [github-actions-library](https://github.com/Raghuram1510/github-actions-library)

---

## 💡 Usage Patterns

### Pattern 1: Single Environment

```
my-project/
├── main.tf              # Uses modules
├── variables.tf
├── outputs.tf
└── terraform.tfvars
```

```hcl
# main.tf
module "roles" {
  source = "github.com/Raghuram1510/terraform-modules//modules/iam-roles"
  
  cluster_name = var.cluster_name
  environment  = var.environment
  # ...
}
```

---

### Pattern 2: Multi-Environment

```
my-project/
├── environments/
│   ├── dev/
│   │   └── main.tf
│   ├── staging/
│   │   └── main.tf
│   └── prod/
│       └── main.tf
└── modules/  # Your shared modules repo
```

```hcl
# environments/prod/main.tf
module "prod_roles" {
  source = "../../modules/iam-roles"
  
  cluster_name = "my-app"
  environment = "prod"
  # ...
}
```

---

## 🛠️ Development

### Running Validation Locally

```bash
# Format all files
terraform fmt -recursive

# Validate a specific module
cd modules/iam-roles
terraform init -backend=false
terraform validate
```

### Testing Changes

1. Make changes to a module
2. Update the module version in your infrastructure project
3. Run `terraform plan` to see the changes
4. Apply if everything looks good

---

## 📋 Module Standards

All modules in this repository follow these standards:

- ✅ **Generic & Reusable** - No hardcoded values
- ✅ **Well Documented** - Every module has a README
- ✅ **Flexible** - Support multiple use cases
- ✅ **Tested** - Auto-validated on every push
- ✅ **Production Ready** - Used in real environments

---

## 🔐 Security Best Practices

1. **Use IAM Roles, not keys** - All modules support IAM roles
2. **Least privilege** - Only attach policies you need
3. **Enable CloudWatch** - Monitor your resources
4. **Use tags** - All resources are tagged for tracking
5. **Permissions boundaries** - Limit maximum permissions

---

## 📚 Additional Resources

- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Terraform Module Registry](https://registry.terraform.io/)

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Ensure `terraform fmt` and `terraform validate` pass
5. Submit a pull request

---

## 📞 Support

For issues or questions:
- Open a GitHub issue
- Check module READMEs for detailed documentation
- Review examples in each module directory

---

**Happy Terraforming!** 🚀
