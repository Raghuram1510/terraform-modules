# AWS Terraform Modules

Production-ready AWS infrastructure modules with built-in **HIPAA**, **SOC2**, and **CIS** compliance.

---

## 📦 Available Modules

### [IAM Roles](./iam-roles/)
Create IAM roles for EC2, Lambda, CI/CD (OIDC), Kubernetes pods (IRSA), and cross-account access.

**Quick Example:**
```hcl
module "worker_role" {
  source = "../../modules/aws/iam-roles"
  
  cluster_name        = "my-eks"
  environment         = "prod"
  role_name           = "worker"
  role_type           = "ec2"
  attach_eks_policies = true
}
```

---

### [Compute](./compute/)
Launch EC2 instances with optional user data scripts and compliance-ready configurations.

**Quick Example:**
```hcl
module "workers" {
  source = "../../modules/aws/compute"
  
  cluster_name         = "my-k8s"
  environment          = "dev"
  node_type            = "worker"
  instance_count       = 3
  subnet_id            = module.vpc.private_subnet_ids[0]
  iam_instance_profile = module.worker_role.instance_profile_name
  user_data_file       = "./scripts/k8s-worker.sh"
}
```

---

### [VPC](./vpc/)
VPC networking with public/private subnets, NAT gateways, route tables, and VPC Flow Logs.

**Quick Example:**
```hcl
module "vpc" {
  source = "../../modules/aws/vpc"
  
  cluster_name = "my-cluster"
  environment  = "prod"
  vpc_cidr     = "10.0.0.0/16"
  
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
  availability_zones   = ["us-east-1a", "us-east-1b"]
  
  enable_nat_gateway = true
  single_nat_gateway = false  # HA setup
}
```

---

## � Compliance Features

All AWS modules include built-in compliance controls validated by Checkov and tfsec:

| Feature | HIPAA | SOC2 | CIS |
|---------|-------|------|-----|
| Encryption at rest | ✅ | ✅ | ✅ |
| Encryption in transit | ✅ | ✅ | ✅ |
| Audit logging (CloudTrail) | ✅ | ✅ | ✅ |
| VPC Flow Logs | ✅ | ✅ | ✅ |
| Least privilege IAM | ✅ | ✅ | ✅ |
| Private networking | ✅ | ✅ | ✅ |
| Resource tagging | ✅ | ✅ | ✅ |

**Validation:**
```bash
# Scan for compliance
checkov -d modules/aws/ --framework terraform --check hipaa,soc2,cis
tfsec modules/aws/
```

---

## � Getting Started

```bash
# Clone the repository
git clone https://github.com/Raghuram1510/terraform-modules.git
cd terraform-modules/modules/aws

# Use in your Terraform code
module "my_vpc" {
  source = "../../modules/aws/vpc"
  # ... configuration
}
```

---

## � Module Standards

All AWS modules follow:
- ✅ **Terraform >= 1.5.0**
- ✅ **AWS Provider >= 5.0**
- ✅ **Input validation** - Variable constraints
- ✅ **Complete outputs** - All resource IDs and ARNs
- ✅ **Consistent tagging** - `Environment`, `ManagedBy`, `Compliance`
- ✅ **Documentation** - Usage examples in each README

---

## 🔐 Security Best Practices

- **No hardcoded values** - All sensitive data via variables
- **Encryption by default** - KMS for data at rest
- **Network isolation** - Private subnets for compute resources
- **IAM least privilege** - Minimal required permissions
- **Audit logging** - CloudTrail and VPC Flow Logs enabled

---

## 📚 Resources

- [Back to Main Documentation](../../README.md)
- [Compliance Mappings](../../docs/compliance-mappings/)
- [AWS Examples](../../examples/aws/)

---

**Cloud Provider:** AWS  
**Compliance:** HIPAA, SOC2, CIS AWS Foundations Benchmark  
**Maintained By:** Raghuram 
