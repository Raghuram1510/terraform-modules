# IAM Roles Module

## 🎯 What This Module Does

This module creates AWS IAM roles that can be used by:
- **EC2 instances** (your servers)
- **Lambda functions** (serverless code)
- **CI/CD pipelines** (GitHub Actions, GitLab CI)
- **Kubernetes pods** (containers in EKS)
- **Other AWS accounts** (cross-account access)

---

## 📖 How the main.tf File Works

### Flow Diagram

```
User calls module with role_type
         ↓
main.tf creates trust policy for that type
         ↓
Creates IAM role with that trust policy
         ↓
Attaches policies you specified
         ↓
(If EC2) Creates instance profile
         ↓
Outputs role ARN and name
```

### Step-by-Step Explanation

#### **Step 1: Get AWS Account ID**
```hcl
data "aws_caller_identity" "current" {}
```
**Why?** We need your account ID to build OIDC provider ARNs.

---

#### **Step 2: Create Trust Policies**

Trust policies define **WHO can use this role**.

**For EC2:**
```hcl
data "aws_iam_policy_document" "ec2_trust" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}
```
**Meaning:** "EC2 service can assume this role"

**For Lambda:**
```hcl
data "aws_iam_policy_document" "lambda_trust" {
  count = var.role_type == "lambda" ? 1 : 0  # Only create if needed
  
  statement {
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}
```
**Meaning:** "Lambda service can assume this role"  
**Note:** `count` means it's only created when `role_type = "lambda"`

**For GitHub Actions (OIDC):**
```hcl
data "aws_iam_policy_document" "oidc_trust" {
  statement {
    principals {
      type = "Federated"
      identifiers = ["arn:aws:iam::123456789:oidc-provider/token.actions.githubusercontent.com"]
    }
    condition {
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:YourUsername/YourRepo:*"]
    }
  }
}
```
**Meaning:** "Only GitHub repo 'YourUsername/YourRepo' can assume this role"

---

#### **Step 3: Select the Right Trust Policy**

```hcl
locals {
  trust_policy = (
    var.role_type == "ec2"    ? data.aws_iam_policy_document.ec2_trust.json :
    var.role_type == "lambda" ? data.aws_iam_policy_document.lambda_trust[0].json :
    # ... etc
  )
}
```

**This is like an if-else chain:**
- If role_type is "ec2" → use EC2 trust policy
- If role_type is "lambda" → use Lambda trust policy
- And so on...

---

#### **Step 4: Create the IAM Role**

```hcl
resource "aws_iam_role" "this" {
  name               = "my-app-prod-worker"
  assume_role_policy = local.trust_policy  # Uses the selected trust policy!
  
  tags = {
    Name        = "my-app-prod-worker"
    Environment = "prod"
  }
}
```

**This creates the actual role in AWS.**

---

#### **Step 5: Attach Policies (Permissions)**

**EKS Policies (optional):**
```hcl
resource "aws_iam_role_policy_attachment" "eks_worker" {
  count = var.attach_eks_policies ? 1 : 0
  
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}
```
**Meaning:** If `attach_eks_policies = true`, attach EKS policies

**Custom Policies:**
```hcl
resource "aws_iam_role_policy_attachment" "custom" {
  count = length(var.custom_policy_arns)
  
  role       = aws_iam_role.this.name
  policy_arn = var.custom_policy_arns[count.index]
}
```
**Meaning:** Loop through your custom policy list and attach each one

---

#### **Step 6: Create Instance Profile (EC2 only)**

```hcl
resource "aws_iam_instance_profile" "this" {
  count = var.role_type == "ec2" ? 1 : 0
  
  name = "my-app-prod-worker"
  role = aws_iam_role.this.name
}
```
**Why?** EC2 instances can't use IAM roles directly - they need an instance profile as a wrapper.

---

## 🚀 Usage Examples

### Example 1: Kubernetes Worker Node

```hcl
module "k8s_worker_role" {
  source = "./modules/iam-roles"
  
  # Naming
  cluster_name = "my-eks"
  environment  = "prod"
  role_name    = "worker"
  
  # Type
  role_type = "ec2"
  
  # Attach Kubernetes policies
  attach_eks_policies = true
}

# Use in EC2 instance
resource "aws_instance" "worker" {
  ami                  = "ami-12345"
  instance_type        = "t3.medium"
  iam_instance_profile = module.k8s_worker_role.instance_profile_name
}
```

**What happens:**
1. Creates IAM role: `my-eks-prod-worker`
2. Trust policy: EC2 can assume it
3. Attaches: EKS, CNI, ECR policies
4. Creates instance profile
5. EC2 instance can now join Kubernetes cluster!

---

### Example 2: GitHub Actions Deployment

```hcl
module "github_role" {
  source = "./modules/iam-roles"
  
  # Naming
  cluster_name = "my-app"
  environment  = "cicd"
  role_name    = "github-actions"
  
  # Type: OIDC
  role_type = "oidc"
  
  # GitHub configuration
  oidc_provider_url = "token.actions.githubusercontent.com"
  oidc_subject_claims = [
    "repo:Raghuram1510/my-app:*"
  ]
  
  # Deployment permissions
  custom_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
  ]
}
```

**GitHub Actions workflow:**
```yaml
- name: Configure AWS
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ module.github_role.role_arn }}
    aws-region: us-east-1
```

**What happens:**
1. Creates IAM role: `my-app-cicd-github-actions`
2. Trust policy: Only your GitHub repo can assume it
3. Attaches EC2 full access
4. GitHub Actions can deploy EC2 instances!

---

### Example 3: Lambda Function

```hcl
module "lambda_role" {
  source = "./modules/iam-roles"
  
  cluster_name = "data-processor"
  environment  = "prod"
  role_name    = "lambda"
  role_type    = "lambda"
  
  custom_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  ]
}

resource "aws_lambda_function" "processor" {
  function_name = "data-processor"
  role          = module.lambda_role.role_arn
  # Lambda can now read from S3!
}
```

---

## 📥 Inputs (What You Pass In)

### Required

| Variable | Example | Description |
|----------|---------|-------------|
| `cluster_name` | `"my-eks"` | Project name |
| `environment` | `"prod"` | Environment |

### Role Configuration

| Variable | Default | Options | Description |
|----------|---------|---------|-------------|
| `role_type` | `"ec2"` | `ec2`, `lambda`, `oidc`, `irsa`, `cross-account` | Type of role |
| `role_name` | `"ec2-role"` | Any string | Role suffix |

### Policies

| Variable | Default | Description |
|----------|---------|-------------|
| `attach_eks_policies` | `false` | Attach EKS worker policies? |
| `enable_cloudwatch_logs` | `false` | Attach CloudWatch policy? |
| `custom_policy_arns` | `[]` | List of policy ARNs to attach |

---

## 📤 Outputs (What You Get Back)

| Output | Example | Use For |
|--------|---------|---------|
| `role_arn` | `arn:aws:iam::123:role/my-app-prod-worker` | Lambda, references |
| `role_name` | `my-app-prod-worker` | Policy attachments |
| `instance_profile_name` | `my-app-prod-worker` | EC2 instances |
| `instance_profile_arn` | `arn:aws:iam::123:instance-profile/...` | EC2 launch templates |

---

## 🔍 Understanding the Code

### Why `count` is Used

```hcl
resource "aws_iam_role_policy_attachment" "eks_worker" {
  count = var.attach_eks_policies ? 1 : 0
}
```

**What this does:**
- If `attach_eks_policies = true` → `count = 1` → Creates 1 attachment
- If `attach_eks_policies = false` → `count = 0` → Creates nothing!

**Why?** Only create resources when needed!

---

### Why `[0]` is Used

```hcl
trust_policy = data.aws_iam_policy_document.lambda_trust[0].json
```

**Why `[0]`?**
- Because `lambda_trust` has `count` (it might not exist!)
- When `count` is used, Terraform makes it a list
- `[0]` gets the first (and only) item

---

### The Ternary Operator

```hcl
var.role_type == "ec2" ? ec2_trust.json : lambda_trust.json
```

**Reads as:** "If role_type is ec2, use ec2_trust, otherwise use lambda_trust"

**Like JavaScript:**
```javascript
roleType === "ec2" ? ec2Trust : lambdaTrust
```

---

## ❓ Common Questions

### Q: Do I need instance profile for Lambda?
**A:** No! Instance profiles are only for EC2. The module automatically skips it for other types.

### Q: Can one role be used by EC2 and Lambda?
**A:** No! Each role has ONE trust policy. Create separate roles for each use case.

### Q: How do I add S3 access?
**A:** Add to `custom_policy_arns`:
```hcl
custom_policy_arns = ["arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"]
```

### Q: What if I want my own custom policy?
**A:** Create the policy first, then pass its ARN:
```hcl
resource "aws_iam_policy" "my_policy" {
  name   = "my-custom-policy"
  policy = jsonencode({...})
}

module "role" {
  custom_policy_arns = [aws_iam_policy.my_policy.arn]
}
```

---

## 🎓 Learning Path

**Beginner:**
1. Start with EC2 role (simplest)
2. Understand trust policies
3. Add custom policies

**Intermediate:**
4. Try Lambda role
5. Understand OIDC for CI/CD
6. Use IRSA for Kubernetes

**Advanced:**
7. Cross-account roles
8. Permissions boundaries
9. Custom session durations

---

## ✅ Checklist Before Using

- [ ] I know which `role_type` I need
- [ ] I have the required variables (`cluster_name`, `environment`)
- [ ] I know which policies to attach
- [ ] For OIDC: OIDC provider exists in AWS
- [ ] For IRSA: I have the EKS OIDC provider ARN
- [ ] For cross-account: I have the account IDs

---

**Need help? Check the examples above or ask a teammate!** 🚀
