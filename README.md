# Terraform AWS Infrastructure + GitOps CI/CD Pipeline

## Structure
```
.
├── bootstrap/                    # Run ONCE, locally, with local state
│   └── main.tf                   # Creates the S3 bucket + DynamoDB table for the remote backend
├── modules/                      # Reusable Terraform modules
│   ├── vpc/                      # VPC, subnets, IGW, NAT, route tables, flow logs
│   ├── compute/                  # EC2 instance, EIP, instance profile
│   ├── iam/                      # EC2 role, GitHub OIDC provider, Actions role
│   └── security-groups/          # Web security group
├── environments/                 # Per-environment configurations
│   ├── dev/                      # Development environment
│   │   ├── backend.tf            # state key: envs/dev/terraform.tfstate
│   │   ├── main.tf               # Calls modules with dev values
│   │   ├── variables.tf
│   │   ├── terraform.tfvars      # Dev-specific values (t3.nano)
│   │   ├── outputs.tf
│   │   └── versions.tf
│   ├── staging/                  # Staging environment
│   │   ├── backend.tf            # state key: envs/staging/terraform.tfstate
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars      # Staging-specific values (t3.small)
│   │   ├── outputs.tf
│   │   └── versions.tf
│   └── prod/                     # Production environment
│       ├── backend.tf            # state key: envs/prod/terraform.tfstate
│       ├── main.tf
│       ├── variables.tf
│       ├── terraform.tfvars      # Prod-specific values (t3.micro)
│       ├── outputs.tf
│       └── versions.tf
├── policy/
│   └── terraform.rego            # OPA policy evaluated against the plan JSON
├── .tflint.hcl                   # TFLint configuration
└── .github/workflows/
    ├── terraform-plan.yaml       # PR workflow: security scans + plan + Infracost + OPA
    └── terraform-apply.yaml      # Push workflow: plan + approval + apply per environment
```

## One-time setup

1. **Bootstrap the backend** (creates S3 bucket + DynamoDB lock table):
   ```bash
   cd bootstrap
   terraform init
   terraform apply -var="state_bucket_name=your-unique-bucket-name"
   ```

2. **Point each environment's `backend.tf`** at the bucket/table created above.
   Replace `REPLACE-WITH-YOUR-STATE-BUCKET` in `environments/*/backend.tf`.

3. **Create the GitHub OIDC IAM role** (apply once manually before the pipeline can use it):
   ```bash
   cd environments/dev
   terraform init -backend=false
   terraform apply
   ```
   Copy the `github_actions_role_arn` output.

4. **Add repo secrets** (Settings → Secrets and variables → Actions):
   - `AWS_GITHUB_ACTIONS_ROLE_ARN` — the role ARN from step 3
   - `INFRACOST_API_KEY` — from https://www.infracost.io

5. **Create GitHub Environments** (Settings → Environments):
   | Environment | Protection Rules |
   |-------------|-----------------|
   | `dev`       | None (auto-apply) |
   | `staging`   | 1 required reviewer |
   | `prod`      | 2 required reviewers + wait timer |

## Environments

| Environment | VPC CIDR | Instance Type | State Key |
|-------------|----------|---------------|-----------|
| dev | 10.0.0.0/16 | t3.nano | envs/dev/terraform.tfstate |
| staging | 10.1.0.0/16 | t3.small | envs/staging/terraform.tfstate |
| prod | 10.2.0.0/16 | t3.micro | envs/prod/terraform.tfstate |

Each environment is fully isolated with its own state file, VPC, and resource naming.

## CI/CD Pipelines

### PR Workflow (`terraform-plan.yaml`)
Triggered on pull requests to `main` when `environments/` or `modules/` change.

| Stage | Tool | Purpose |
|-------|------|---------|
| 1 | GitLeaks | Secret scanning |
| 2 | terraform fmt | Style/formatting check (auto-fixes) |
| 3 | TFLint | Linting, best practices |
| 4 | Checkov | Policy-as-code security scan |
| 5 | tfsec | Security scan |
| 6 | Terrascan | Compliance scan |
| 7 | terraform validate | Syntax/config validation |
| 8 | terraform plan | Generates execution plan (per changed env) |
| 9 | Infracost | Cost estimate diff on PRs (per changed env) |
| 10 | OPA | Custom policy checks against plan JSON (per changed env) |

### Apply Workflow (`terraform-apply.yaml`)
Triggered on push to `main` when `environments/` or `modules/` change.

Uses `dorny/paths-filter` to detect which environment directories changed, then plans and applies only those environments. Each environment uses a GitHub Environment with its own approval gate.

## Notes
- `iam.tf` grants the GitHub Actions role wildcard actions across EC2/IAM/S3/Route53/ELB/ASG/Logs/CloudWatch/ACM — scope this down to specific actions/resources your pipeline needs.
- `allowed_ssh_cidrs` must be set explicitly per environment in `terraform.tfvars`.
- The OIDC trust policy's `sub` condition is scoped to `main` branch pushes and pull requests.
