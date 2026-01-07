# VPC Module (Virtual Private Cloud)

## 🎯 What This Module Does

Creates a complete AWS network (VPC) with:
- Public subnets (for load balancers, NAT gateways)
- Private subnets (for applications, databases)
- Internet connectivity (Internet Gateway, NAT Gateway)
- Routing (so traffic knows where to go)

**Think of it as:** Building a complete network infrastructure in AWS.

---

## 📖 How It Works

### The Big Picture

```
Your VPC
├─ Public Subnets (internet-facing)
│  ├─ Load balancers
│  └─ NAT Gateways
├─ Private Subnets (internal only)
│  ├─ Application servers
│  └─ Databases
├─ Internet Gateway → Public subnets get internet
└─ NAT Gateways → Private subnets get internet (outbound only)
```

---

## 🚀 Quick Start

### Minimal Example

```hcl
module "vpc" {
  source = "./modules/vpc"
  
  vpc_name    = "my-app-vpc"
  environment = "prod"
  vpc_cidr    = "10.0.0.0/16"
}
```

**This creates:**
- VPC with 65,536 IP addresses
- 2 public subnets (across 2 availability zones)
- 2 private subnets (across 2 availability zones)
- Internet Gateway
- NAT Gateway in each AZ
- Route tables configured automatically

---

## 📋 Common Examples

### Example 1: Production (High Availability)

```hcl
module "prod_vpc" {
  source = "./modules/vpc"
  
  # Basic info
  vpc_name    = "production"
  environment = "prod"
  vpc_cidr    = "10.0.0.0/16"
  
  # Spread across 3 AZs
  azs_count = 3
  
  # NAT Gateway in each AZ (expensive but highly available)
  enable_nat_gateway = true
  single_nat_gateway = false  # One per AZ
  
  # Save money on S3/DynamoDB traffic
  enable_s3_endpoint       = true
  enable_dynamodb_endpoint = true
  
  # Security monitoring
  enable_flow_logs = true
  
  tags = {
    Project    = "MyApp"
    Team       = "Platform"
    CostCenter = "Engineering"
  }
}
```

**Cost:** ~$100/month (3 NAT Gateways)  
**High Availability:** ✅ Yes

---

### Example 2: Dev/Test (Cost-Optimized)

```hcl
module "dev_vpc" {
  source = "./modules/vpc"
  
  vpc_name    = "development"
  environment = "dev"
  vpc_cidr    = "10.1.0.0/16"
  
  # Just 2 AZs
  azs_count = 2
  
  # Single NAT Gateway (cheaper, not HA)
  enable_nat_gateway = true
  single_nat_gateway = true  # Just one for all subnets
  
  # Save costs
  enable_flow_logs = false
  
  tags = {
    Project = "MyApp"
    Env     = "development"
  }
}
```

**Cost:** ~$32/month (1 NAT Gateway)  
**High Availability:** ❌ No (but okay for dev)

---

### Example 3: Fully Isolated (No NAT)

```hcl
module "secure_vpc" {
  source = "./modules/vpc"
  
  vpc_name    = "secure-env"
  environment = "prod"
  vpc_cidr    = "10.2.0.0/16"
  
  # Private subnets have NO internet access
  enable_nat_gateway = false
  
  # But can still access S3 privately
  enable_s3_endpoint = true
  
  tags = {
    Compliance = "PCI-DSS"
  }
}
```

**Cost:** $0 (no NAT)  
**Use for:** Highly secure, compliance-required workloads

---

## 📥 Input Variables

### Basic Configuration

| Variable | Default | What It Does |
|----------|---------|--------------|
| `vpc_name` | *required* | Name of your VPC |
| `environment` | *required* | prod/dev/staging |
| `vpc_cidr` | `"10.0.0.0/16"` | IP range (65K IPs) |

### Availability Zones

| Variable | Default | What It Does |
|----------|---------|--------------|
| `azs_count` | `2` | How many AZs to use? |
| `availability_zones` | `[]` | Leave empty = auto-select |

**Example:**
- `azs_count = 2` → Uses 2 AZs
- `azs_count = 3` → Uses 3 AZs (higher availability)

### Subnets

| Variable | Default | What It Does |
|----------|---------|--------------|
| `create_public_subnets` | `true` | Create public subnets? |
| `create_private_subnets` | `true` | Create private subnets? |
| `public_subnet_cidrs` | `[]` | Auto-calculated if empty |
| `private_subnet_cidrs` | `[]` | Auto-calculated if empty |

**Auto-calculation example:**
```
VPC: 10.0.0.0/16, azs_count = 2

Auto-creates:
  Public:  10.0.0.0/24, 10.0.1.0/24
  Private: 10.0.2.0/24, 10.0.3.0/24
```

### NAT Gateway (Internet for Private Subnets)

| Variable | Default | What It Does |
|----------|---------|--------------|
| `enable_nat_gateway` | `false` | Give private subnets internet? |
| `single_nat_gateway` | `true` | One NAT (cheap) vs per-AZ (HA)? |

**Decision Matrix:**
```
Production + HA needed: single_nat_gateway = false ($$$, HA ✅)
Dev/Test: single_nat_gateway = true ($, HA ❌)
No internet needed: enable_nat_gateway = false (free)
```

### VPC Endpoints (Save Money!)

| Variable | Default | What It Does |
|----------|---------|--------------|
| `enable_s3_endpoint` | `false` | Access S3 without NAT (FREE!) |
| `enable_dynamodb_endpoint` | `false` | Access DynamoDB without NAT (FREE!) |

**Recommendation:** Always set to `true` in production!

### Flow Logs (Security Monitoring)

| Variable | Default | What It Does |
|----------|---------|--------------|
| `enable_flow_logs` | `false` | Log all network traffic? |
| `flow_log_destination` | `"cloudwatch"` | Where to send logs |

**Use when:** Security compliance required, debugging network issues

---

## 📤 Outputs

### What You Get Back

| Output | Use For |
|--------|---------|
| `vpc_id` | Reference in other modules |
| `public_subnet_ids` | Put load balancers, NAT |
| `private_subnet_ids` | Put app servers, databases |
| `nat_gateway_ids` | Whitelisting in other accounts |
| `availability_zones` | Know which AZs you're using |

### How to Use Outputs

```hcl
# Use VPC in compute module
module "app_servers" {
  source = "./modules/compute"
  
  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.private_subnet_ids[0]
}

# Use in load balancer
resource "aws_lb" "app" {
  subnets = module.vpc.public_subnet_ids  # Spread across AZs
}
```

---

## 💰 Cost Breakdown

### What Costs Money?

| Resource | Monthly Cost | Can Avoid? |
|----------|--------------|------------|
| NAT Gateway (per AZ) | ~$32/month | Set `enable_nat_gateway = false` |
| VPC itself | FREE | No |
| Subnets | FREE | No |
| Internet Gateway | FREE | No |
| Route tables | FREE | No |
| VPC Endpoints (S3/DynamoDB) | FREE | No (actually saves money!) |
| Flow Logs storage | ~$0.50/GB | Set `enable_flow_logs = false` |

**Example monthly costs:**
- **Dev (1 NAT):** $32
- **Prod (3 NATs):** $96
- **No NAT:** $0

---

## 🎓 Understanding Subnets

### Public vs Private - What's the Difference?

**Public Subnet:**
```
Has route: 0.0.0.0/0 → Internet Gateway
└─ Can receive traffic from internet
└─ Instances get public IPs
└─ Use for: Load balancers, bastion hosts
```

**Private Subnet:**
```
Has route: 0.0.0.0/0 → NAT Gateway
└─ Can send traffic to internet (through NAT)
└─ Cannot receive traffic from internet
└─ Use for: App servers, databases
```

---

## 🔐 Security Best Practices

### ✅ DO:
- Use at least 2 AZs for production
- Put databases in private subnets
- Enable S3/DynamoDB endpoints
- Use VPC Flow Logs for compliance
- Tag everything for cost tracking

### ❌ DON'T:
- Put databases in public subnets
- Disable NAT for apps that need updates
- Use only 1 AZ in production
- Forget to enable endpoints (costs you money!)

---

## ❓ Common Questions

### Q: How many IPs do I get?
**A:** 
- `/16` CIDR = 65,536 IPs
- `/20` CIDR = 4,096 IPs
- `/24` CIDR = 256 IPs

### Q: Can I add more subnets later?
**A:** Yes! Just increase `azs_count` or manually add subnet CIDRs.

### Q: Do I need NAT Gateway?
**A:**
- ✅ YES if private instances need to download updates, access AWS services
- ❌ NO if fully isolated or using VPC endpoints for everything

### Q: What's the difference between single NAT and per-AZ NAT?
**A:**
- **Single:** All subnets share one NAT. If its AZ fails, NO internet for anyone.
- **Per-AZ:** Each AZ has its own NAT. If one AZ fails, others keep working.

### Q: How do I customize the IP ranges?
**A:**
```hcl
module "vpc" {
  vpc_cidr = "10.0.0.0/16"
  
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
}
```

---

## 🐛 Troubleshooting

| Problem | Solution |
|---------|----------|
| "InvalidSubnet" error | CIDRs must be within VPC CIDR |
| Private instances can't reach internet | Enable NAT Gateway |
| NAT Gateway too expensive | Use `single_nat_gateway = true` |
| "Insufficient IPs" | Use larger CIDR (/16, /20) |

---

## 🎯 Decision Guide

### How Many AZs?

- **Dev/Test:** 2 AZs (enough)
- **Production:** 3 AZs (best practice)

### NAT Strategy?

- **Production (HA required):** `single_nat_gateway = false`
- **Dev/Test (cost matters):** `single_nat_gateway = true`
- **Fully isolated:** `enable_nat_gateway = false`

### Enable Flow Logs?

- **Compliance required:** YES
- **Debugging network:** YES
- **Cost-sensitive dev:** NO

---

## ✅ Checklist Before Using

- [ ] I chose a CIDR that doesn't overlap with other VPCs
- [ ] I know how many AZs I need
- [ ] I decided on NAT strategy (cost vs HA)
- [ ] I know if I need Flow Logs
- [ ] I've set up proper tags for cost tracking

---

**Need help? Check the examples above or consult the AWS VPC documentation!** 🚀
