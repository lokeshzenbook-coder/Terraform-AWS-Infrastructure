# Terraform AWS Infrastructure + 12-Stage CI/CD Pipeline

## Structure
```
.
├── bootstrap/                 # Run ONCE, locally, with local state
│   └── main.tf                # Creates the S3 bucket + DynamoDB table used as the remote backend
├── terraform/                 # Main infrastructure (uses remote backend)
│   ├── versions.tf
│   ├── backend.tf             # S3 + DynamoDB backend config
│   ├── providers.tf
│   ├── variables.tf
│   ├── vpc.tf                 # VPC, subnets, IGW, NAT, route tables
│   ├── security_groups.tf
│   ├── iam.tf                 # EC2 role + GitHub OIDC role
│   ├── ec2.tf
│   ├── outputs.tf
│   ├── .tflint.hcl
│   └── terraform.tfvars.example
├── policy/
│   └── terraform.rego         # OPA policy evaluated against the plan JSON
└── .github/workflows/
    └── terraform.yaml # 12-stage pipeline
```

## One-time setup

1. **Bootstrap the backend** (creates S3 bucket + DynamoDB lock table):
   ```bash
   cd bootstrap
   terraform init
   terraform apply -var="state_bucket_name=your-unique-bucket-name"
   ```

2. **Point `terraform/backend.tf`** at the bucket/table created above.

3. **Create the GitHub OIDC IAM role** (chicken-and-egg: apply this once manually,
   or via the bootstrap stack, before the pipeline can use it):
   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars   # edit values
   terraform init
   terraform apply
   ```
   Copy the `github_actions_role_arn` output.

4. **Add repo secrets** (Settings → Secrets and variables → Actions):
   - `AWS_GITHUB_ACTIONS_ROLE_ARN` — the role ARN from step 3
   - `INFRACOST_API_KEY` — from https://www.infracost.io

5. **Create a protected `production` environment** (Settings → Environments) and
   add required reviewers — this powers Stage 11 (Manual Approval).

## Pipeline stages
| Stage | Tool | Purpose |
|---|---|---|
| 1 | GitLeaks | Secret scanning |
| 2 | terraform fmt | Style/formatting check |
| 3 | TFLint | Linting, best practices |
| 4 | Checkov | Policy-as-code security scan |
| 5 | tfsec | Security scan |
| 6 | Terrascan | Compliance scan |
| 7 | Infracost | Cost estimate diff on PRs |
| 8 | terraform validate | Syntax/config validation |
| 9 | terraform plan | Generates execution plan |
| 10 | OPA | Custom policy checks against plan JSON |
| 11 | Manual Approval | GitHub Environment protection rule |
| 12 | terraform apply | Applies the approved plan |

## Notes / things to tighten before production use
- `iam.tf` grants the GitHub Actions role wildcard actions across EC2/IAM/S3/Route53/ELB/ASG/Logs/CloudWatch/ACM as a placeholder —
  scope this down to the specific actions/resources your pipeline needs.
- `allowed_ssh_cidrs` defaults to `0.0.0.0/0` in variable defaults; override it in
  `terraform.tfvars`.
- The OIDC trust policy's `sub` condition is scoped to `main` branch pushes and pull requests.
  Add a `repo:org/repo:ref:refs/heads/<branch>` entry if you deploy from additional branches.
