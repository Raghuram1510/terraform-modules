# Compute Module (EC2 Instances)

## 🎯 What This Module Does

Creates EC2 instances (virtual servers in AWS) that can be used for:
- Kubernetes worker nodes
- Web servers
- Application servers
- Database servers
- Bastion/Jump hosts
- CI/CD runners

**Think of it as:** A template for creating virtual machines in AWS.

---

## 📖 How It Works

### Simple Flow

```
You provide:
├─ VPC and subnet (where to put it)
├─ IAM role (permissions)
├─ Security group (firewall rules)
└─ User data script (setup commands)

Module creates:
└─ EC2 instance(s) with your configuration
```

---

## 🚀 Quick Start

### Minimal Example

```hcl
module "web_servers" {
  source = "./modules/compute"
  
  cluster_name = "my-app"
  environment  = "prod"
  node_type    = "web"
  
  vpc_id    = "vpc-12345"
  subnet_id = "subnet-67890"
  
  iam_instance_profile = "my-role"
}
```

**This creates:** 1 EC2 instance named `my-app-prod-web-1`

---

## 📋 Common Examples

### Example 1: Kubernetes Worker Nodes

```hcl
module "k8s_workers" {
  source = "./modules/compute"
  
  # Naming
  cluster_name = "production-k8s"
  environment  = "prod"
  node_type    = "worker"
  
  # How many?
  instance_count = 3
  instance_type  = "t3.large"
  
  # Where?
  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.private_subnet_ids[0]
  
  # Permissions
  iam_instance_profile = module.k8s_role.instance_profile_name
  
  # Security
  create_security_group = true
  allowed_ssh_cidr_blocks = ["10.0.0.0/16"]  # SSH from VPC only
  
  allowed_ingress_rules = [
    {
      from_port   = 10250
      to_port     = 10250
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
      description = "Kubelet API"
    }
  ]
  
  # Setup script
  user_data_file = "./scripts/k8s-worker-setup.sh"
}
```

**Creates:** 3 worker nodes with Kubernetes configuration

---

### Example 2: Web Server with Custom Security

```hcl
# First, create your own security group
resource "aws_security_group" "web" {
  name   = "web-server-sg"
  vpc_id = module.vpc.vpc_id
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Then use it in the module
module "web_server" {
  source = "./modules/compute"
  
  cluster_name = "website"
  environment  = "prod"
  node_type    = "nginx"
  
  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.public_subnet_ids[0]  # Public subnet!
  
  create_security_group = false  # Use our custom SG
  security_group_ids    = [aws_security_group.web.id]
  
  iam_instance_profile = module.web_role.instance_profile_name
  user_data_file       = "./scripts/nginx-setup.sh"
}
```

---

## 📥 Input Variables

### Required

| Variable | Example | What It Does |
|----------|---------|--------------|
| `cluster_name` | `"my-app"` | Project name |
| `environment` | `"prod"` | Environment (prod/dev/staging) |
| `vpc_id` | `"vpc-123"` | Which VPC to use |
| `subnet_id` | `"subnet-456"` | Which subnet to use |
| `iam_instance_profile` | `"my-role"` | IAM role name for permissions |

### Optional (Common)

| Variable | Default | What It Does |
|----------|---------|--------------|
| `instance_count` | `1` | How many instances? |
| `instance_type` | `"t3.medium"` | Size (t3.small, t3.large, etc.) |
| `node_type` | `"worker"` | Type suffix for naming |
| `key_name` | `""` | SSH key name (for SSH access) |
| `user_data_file` | `""` | Setup script path |

### Security Groups

| Variable | Default | What It Does |
|----------|---------|--------------|
| `create_security_group` | `true` | Let module create SG? |
| `security_group_ids` | `[]` | Your own SG IDs (if not creating) |
| `allowed_ssh_cidr_blocks` | `[]` | Who can SSH? (empty = no SSH) |
| `allowed_ingress_rules` | `[]` | Custom firewall rules |
| `allow_all_egress` | `true` | Allow internet access? |

---

## 📤 Outputs

### What You Get Back

| Output | Example | Use For |
|--------|---------|---------|
| `instance_ids` | `["i-abc123", "i-def456"]` | AWS console, automation |
| `private_ips` | `["10.0.1.5", "10.0.1.6"]` | Internal communication |
| `public_ips` | `["54.1.2.3", "54.4.5.6"]` | SSH, external access |
| `security_group_id` | `"sg-789xyz"` | Allow traffic from these instances |
| `instance_names` | `["my-app-prod-web-1"]` | Identification |

### How to Use Outputs

```hcl
# Reference in other resources
resource "aws_lb_target_group_attachment" "web" {
  count = length(module.web_server.instance_ids)
  
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = module.web_server.instance_ids[count.index]
}

# Output for user
output "server_ips" {
  value = module.web_server.private_ips
}
```

---

## 🔐 Security Best Practices

### ✅ DO:
- Use private subnets for most workloads
- Limit SSH to VPC CIDR only
- Use IAM roles, not access keys
- Enable only needed ports
- Use security groups for isolation

### ❌ DON'T:
- Put databases in public subnets
- Open SSH to `0.0.0.0/0` in production
- Use `t2.micro` for production (use t3.medium+)
- Skip user data - use it to automate setup

---

## 🎓 Understanding the Code

### What Happens When You Run This?

1. **Module creates security group** (if `create_security_group = true`)
   - Opens ports you specified
   - Allows outbound internet (for updates)

2. **Module launches EC2 instances**
   - Uses latest Amazon Linux 2 AMI
   - Assigns IAM role for permissions
   - Runs your user data script on first boot
   - Places in the subnet you chose

3. **Returns outputs**
   - IPs, IDs, names for you to use

---

## ❓ Common Questions

### Q: Can I use this for Windows servers?
**A:** Currently uses Amazon Linux 2. For Windows, change the `data.aws_ami` filter in main.tf.

### Q: How do I SSH into the instances?
**A:** 
1. Set `key_name = "your-key"`
2. Add `allowed_ssh_cidr_blocks = ["your-ip/32"]`
3. SSH: `ssh -i your-key.pem ec2-user@public-ip`

### Q: Can I run multiple instance types?
**A:** No, all instances in one module call use the same `instance_type`. Create separate module calls for different sizes.

### Q: What's the difference between `user_data_file` and `user_data_script`?
**A:** Same purpose - use `user_data_file` to point to a script file.

---

## 🐛 Troubleshooting

| Problem | Solution |
|---------|----------|
| "No default VPC" error | Provide `vpc_id` and `subnet_id` |
| Can't SSH | Check security group and key name |
| Instance fails health check | Check user data script for errors |
| "Insufficient capacity" | Try different AZ or instance type |

---

## ✅ Checklist Before Using

- [ ] I have a VPC and subnet ready
- [ ] I have an IAM role created
- [ ] I know which ports to open
- [ ] I have a user data script (if needed)
- [ ] I chose the right instance type for my workload

---

**Need help? Check the examples above or ask your team lead!** 🚀
