#############################################
# EC2 IAM Role
#############################################

resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

####################################################
# GitHub Actions OIDC Provider
####################################################

data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "github" {

  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    data.tls_certificate.github.certificates[0].sha1_fingerprint
  ]
}

####################################################
# GitHub Actions IAM Role
####################################################

resource "aws_iam_role" "github_actions" {

  name = "${var.project_name}-github-actions-role"

  assume_role_policy = jsonencode({

    Version = "2012-10-17"

    Statement = [

      {
        Effect = "Allow"

        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }

        Action = "sts:AssumeRoleWithWebIdentity"

        Condition = {

          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }

          StringLike = {

            "token.actions.githubusercontent.com:sub" = [
              "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/main",
              "repo:${var.github_org}/${var.github_repo}:pull_request",
              "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/*"
            ]
          }
        }
      }
    ]
  })
}

####################################################
# GitHub Actions Policy
####################################################

resource "aws_iam_role_policy" "github_actions" {

  name = "${var.project_name}-github-actions-policy"

  role = aws_iam_role.github_actions.id

  policy = jsonencode({

    Version = "2012-10-17"

    Statement = [

      {

        Sid = "TerraformPermissions"

        Effect = "Allow"

        Action = [

          "ec2:*",

          "iam:*",

          "s3:*",

          "route53:*",

          "elasticloadbalancing:*",

          "autoscaling:*",

          "logs:*",

          "cloudwatch:*",

          "acm:*",

          "sts:GetCallerIdentity"

        ]

        Resource = "*"
      }
    ]
  })
}
